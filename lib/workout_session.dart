import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity.dart';
import 'api_client.dart';
import 'models.dart';
import 'providers.dart';
import 'router.dart';
import 'toast.dart';

class WorkoutSessionPage extends ConsumerWidget {
  const WorkoutSessionPage({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));

    return Scaffold(
      backgroundColor: _SessionColors.black,
      body: SafeArea(
        top: false,
        child: switch (exerciseAsync) {
          AsyncData(value: final exercise?) => _SessionView(exercise: exercise),
          AsyncData() => _SessionMessage(
            message: 'This exercise is no longer available.',
            exerciseId: exerciseId,
          ),
          AsyncError(:final error) => _SessionMessage(
            message: error.toString(),
            exerciseId: exerciseId,
          ),
          _ => const Center(
            child: CircularProgressIndicator(color: _SessionColors.softGold),
          ),
        },
      ),
    );
  }
}

class _SessionMessage extends StatelessWidget {
  const _SessionMessage({required this.message, required this.exerciseId});

  final String message;
  final String exerciseId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _SessionColors.muted, fontSize: 16),
            ),
            TextButton(
              onPressed: () => popOrGo(context, AurexRoutes.home),
              child: const Text(
                'Go back',
                style: TextStyle(color: _SessionColors.softGold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionView extends ConsumerWidget {
  const _SessionView({required this.exercise});

  final MobileExercise exercise;

  WorkoutSessionPlan get _plan => (
    exerciseId: exercise.id,
    sets: exercise.setCount,
    reps: exercise.targetReps,
    restSeconds: exercise.restSeconds,
  );

  Future<void> _save(WidgetRef ref, WorkoutSessionState session) async {
    final now = DateTime.now();
    await ref
        .read(workoutHistoryProvider.notifier)
        .add(
          WorkoutLogEntry(
            id: session.id,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            bodyPart: exercise.bodyPart,
            completedAt: now,
            durationSeconds: session.elapsedSeconds,
            sets: [
              for (final set in session.sets.where((set) => set.done))
                LoggedSet(reps: set.reps, weightKg: set.weightKg),
            ],
          ),
        );
  }

  Future<void> _end(BuildContext context, WidgetRef ref) async {
    final session = ref.read(workoutSessionProvider(_plan));
    final toaster = AurexToaster.of(context);

    if (session.completedCount == 0) {
      popOrGo(context, AurexRoutes.exercise(exercise.id));
      return;
    }

    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: Text(session.finished ? 'Workout complete!' : 'End workout?'),
        content: Text(
          'You completed ${session.completedCount} of ${session.sets.length} '
          'sets in ${_clock(session.elapsedSeconds)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Save to Progress',
              style: TextStyle(color: _SessionColors.softGold),
            ),
          ),
        ],
      ),
    );

    if (save == null || !context.mounted) {
      return;
    }

    if (save) {
      try {
        await _save(ref, session);
      } on AurexApiException catch (error) {
        // Stay on the page so the member can try saving again.
        toaster.error('Workout not saved', error.message);
        return;
      }
      toaster.success('Workout saved', 'It now counts toward your progress.');
    }

    if (context.mounted) {
      popOrGo(context, AurexRoutes.exercise(exercise.id));
    }
  }

  Future<void> _adjustSet(BuildContext context, WidgetRef ref) async {
    final session = ref.read(workoutSessionProvider(_plan));
    final index = session.currentIndex;
    if (index >= session.sets.length) {
      return;
    }

    final result = await showDialog<(double, int)>(
      context: context,
      builder: (context) => _AdjustSetDialog(set: session.sets[index]),
    );

    if (result != null) {
      final controller = ref.read(workoutSessionProvider(_plan).notifier);
      controller.setWeight(result.$1);
      controller.setReps(result.$2);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(workoutSessionProvider(_plan));
    final controller = ref.read(workoutSessionProvider(_plan).notifier);

    ref.listen(workoutSessionProvider(_plan).select((s) => s.finished), (
      wasFinished,
      finished,
    ) {
      if (finished && wasFinished == false) {
        _end(context, ref);
      }
    });

    final tip = exercise.instructions.isNotEmpty
        ? exercise.instructions.first
        : exercise.description;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 126),
      children: [
        _SessionHeader(exercise: exercise, onBack: () => _end(context, ref)),
        const SizedBox(height: 20),
        _ProgressPanel(session: session, onTogglePause: controller.togglePause),
        const SizedBox(height: 22),
        _CurrentSetPanel(session: session, onSkipRest: controller.skipRest),
        const SizedBox(height: 26),
        _WorkoutSets(session: session),
        if (tip.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          _TipsCard(tip: tip.trim()),
        ],
        const SizedBox(height: 24),
        _ActionButtons(
          session: session,
          onAdjust: () => _adjustSet(context, ref),
          onComplete: controller.completeSet,
          onEnd: () => _end(context, ref),
        ),
      ],
    );
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.exercise, required this.onBack});

  final MobileExercise exercise;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final badge = exercise.equipment.isNotEmpty
        ? exercise.equipment
        : exercise.category;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'End workout',
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 26,
              ),
            ),
            const Spacer(),
            Image.asset(
              'assets/images/placeholder.png',
              width: 176,
              fit: BoxFit.contain,
            ),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 112,
              height: 136,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: exercise.imageUrl.isEmpty
                  ? Image.asset(
                      'assets/images/session_machine_thumb.png',
                      fit: BoxFit.cover,
                    )
                  : Image.network(
                      exercise.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/session_machine_thumb.png',
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge.isNotEmpty)
                    Text(
                      badge.toUpperCase(),
                      style: const TextStyle(
                        color: _SessionColors.softGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    exercise.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (exercise.bodyPart.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.accessibility_new_rounded,
                          color: _SessionColors.gold,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            exercise.bodyPart,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _InfoPill(Icons.schedule, 'Rest ${exercise.restTime}'),
            _InfoPill(
              Icons.bar_chart_rounded,
              exercise.level,
              highlighted: true,
            ),
            _InfoPill(Icons.repeat_rounded, exercise.reps),
          ],
        ),
      ],
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel({required this.session, required this.onTogglePause});

  final WorkoutSessionState session;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 18, 22),
      decoration: _panelDecoration(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SET PROGRESS',
                  style: TextStyle(color: _SessionColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    text: '${session.completedCount}',
                    style: const TextStyle(
                      color: _SessionColors.softGold,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                    children: [
                      TextSpan(
                        text: ' / ${session.sets.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: session.completedCount / session.sets.length,
                    minHeight: 9,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(
                      _SessionColors.softGold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TIME',
                style: TextStyle(color: _SessionColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 14),
              Text(
                _clock(session.elapsedSeconds),
                style: const TextStyle(
                  color: _SessionColors.softGold,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: session.finished ? null : onTogglePause,
            style: OutlinedButton.styleFrom(
              foregroundColor: _SessionColors.softGold,
              side: const BorderSide(color: _SessionColors.gold),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: Icon(
              session.paused ? Icons.play_arrow : Icons.pause,
              size: 28,
              semanticLabel: session.paused ? 'Resume' : 'Pause',
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentSetPanel extends StatelessWidget {
  const _CurrentSetPanel({required this.session, required this.onSkipRest});

  final WorkoutSessionState session;
  final VoidCallback onSkipRest;

  @override
  Widget build(BuildContext context) {
    if (session.finished) {
      return Container(
        padding: const EdgeInsets.all(26),
        decoration: _panelDecoration(20),
        child: const Row(
          children: [
            Icon(Icons.emoji_events, color: _SessionColors.softGold, size: 44),
            SizedBox(width: 18),
            Expanded(
              child: Text(
                'All sets complete. Great work!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final index = session.currentIndex;
    final current = session.sets[index];
    final next = index + 1 < session.sets.length
        ? session.sets[index + 1]
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;
        final summary = session.resting
            ? _RestTimer(
                size: isNarrow ? 200 : 240,
                remaining: session.restRemaining,
                total: session.restSeconds,
                onSkip: onSkipRest,
              )
            : _CurrentSetSummary(
                number: index + 1,
                set: current,
                compact: isNarrow,
              );
        final upNext = _UpNextCard(
          width: isNarrow ? 128 : 168,
          number: next == null ? null : index + 2,
          set: next,
          compact: isNarrow,
        );

        return Container(
          padding: EdgeInsets.all(isNarrow ? 22 : 30),
          decoration: _panelDecoration(20),
          child: isNarrow && session.resting
              ? Column(children: [summary, const SizedBox(height: 18), upNext])
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Center(child: summary)),
                    const SizedBox(width: 16),
                    upNext,
                  ],
                ),
        );
      },
    );
  }
}

class _CurrentSetSummary extends StatelessWidget {
  const _CurrentSetSummary({
    required this.number,
    required this.set,
    this.compact = false,
  });

  final int number;
  final SessionSet set;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'CURRENT SET',
          style: TextStyle(
            color: _SessionColors.softGold,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: compact ? 12 : 22),
        Text(
          '$number',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 48 : 58,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          '${set.reps} REPS',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 24 : 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 18 : 32),
        Text(
          _weight(set.weightKg),
          style: TextStyle(
            color: _SessionColors.softGold,
            fontSize: compact ? 22 : 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'WEIGHT',
          style: TextStyle(color: _SessionColors.muted, fontSize: 16),
        ),
      ],
    );
  }
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard({
    required this.width,
    required this.number,
    required this.set,
    this.compact = false,
  });

  final double width;
  final int? number;
  final SessionSet? set;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UP NEXT',
            style: TextStyle(color: _SessionColors.muted, fontSize: 16),
          ),
          SizedBox(height: compact ? 14 : 22),
          if (set == null)
            Text(
              'Last set',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w800,
              ),
            )
          else ...[
            Text(
              'Set $number',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: compact ? 14 : 22),
            Text(
              '${set!.reps} REPS',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 19 : 23,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: compact ? 14 : 22),
            Text(
              _weight(set!.weightKg),
              style: TextStyle(
                color: _SessionColors.softGold,
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RestTimer extends StatelessWidget {
  const _RestTimer({
    required this.size,
    required this.remaining,
    required this.total,
    required this.onSkip,
  });

  final double size;
  final int remaining;
  final int total;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: total == 0 ? 0 : remaining / total,
              strokeWidth: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(_SessionColors.gold),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'REST TIME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _clock(remaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: onSkip,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _SessionColors.softGold,
                  side: const BorderSide(color: _SessionColors.gold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text(
                  'SKIP REST',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkoutSets extends StatelessWidget {
  const _WorkoutSets({required this.session});

  final WorkoutSessionState session;

  @override
  Widget build(BuildContext context) {
    final current = session.currentIndex;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('WORKOUT SETS')),
            Text(
              'Rest: ${_clock(session.restSeconds)}',
              style: const TextStyle(
                color: _SessionColors.softGold,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: _panelDecoration(16),
          child: Column(
            children: [
              const _SetRow(
                values: ['SET', 'WEIGHT', 'REPS', 'STATUS'],
                header: true,
              ),
              for (var i = 0; i < session.sets.length; i++)
                _SetRow(
                  values: [
                    '${i + 1}',
                    _weight(session.sets[i].weightKg),
                    '${session.sets[i].reps}',
                    session.sets[i].done
                        ? 'Completed'
                        : i == current
                        ? (session.resting ? 'Resting' : 'In Progress')
                        : 'Upcoming',
                  ],
                  icon: session.sets[i].done
                      ? Icons.check_circle_outline
                      : i == current
                      ? Icons.play_arrow
                      : Icons.radio_button_unchecked,
                  active: i == current,
                  complete: session.sets[i].done,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.tip});

  final String tip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 20, 20),
      decoration: _panelDecoration(16),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: _SessionColors.softGold,
            size: 44,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIPS',
                  style: TextStyle(
                    color: _SessionColors.softGold,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.session,
    required this.onAdjust,
    required this.onComplete,
    required this.onEnd,
  });

  final WorkoutSessionState session;
  final VoidCallback onAdjust;
  final VoidCallback onComplete;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final current = session.finished
        ? null
        : session.sets[session.currentIndex];

    return Row(
      children: [
        Expanded(
          child: _SecondaryButton(
            icon: Icons.tune,
            label: current == null
                ? 'ADJUST SET'
                : 'ADJUST SET\n${_weight(current.weightKg)}',
            color: _SessionColors.softGold,
            onPressed: current == null ? null : onAdjust,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 82,
            child: ElevatedButton.icon(
              onPressed: session.finished || session.resting || session.paused
                  ? null
                  : onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: _SessionColors.softGold,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white12,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 26),
              label: const Text(
                'COMPLETE SET',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SecondaryButton(
            icon: Icons.stop_circle_outlined,
            label: 'END\nWORKOUT',
            color: const Color(0xFFFF5A4F),
            onPressed: onEnd,
          ),
        ),
      ],
    );
  }
}

class _AdjustSetDialog extends StatefulWidget {
  const _AdjustSetDialog({required this.set});

  final SessionSet set;

  @override
  State<_AdjustSetDialog> createState() => _AdjustSetDialogState();
}

class _AdjustSetDialogState extends State<_AdjustSetDialog> {
  late final _weightField = TextEditingController(
    text: widget.set.weightKg == 0 ? '' : _trim(widget.set.weightKg),
  );
  late final _reps = TextEditingController(text: '${widget.set.reps}');

  @override
  void dispose() {
    _weightField.dispose();
    _reps.dispose();
    super.dispose();
  }

  void _submit() {
    final weight = double.tryParse(
      _weightField.text.trim().replaceAll(',', '.'),
    );
    final reps = int.tryParse(_reps.text.trim());
    Navigator.pop(context, (
      (weight ?? 0).clamp(0, 999).toDouble(),
      (reps ?? widget.set.reps).clamp(1, 200),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141414),
      title: const Text('Adjust set'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _weightField,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              helperText: 'Applies to this set and the ones after it',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reps,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Reps'),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text(
            'Save',
            style: TextStyle(color: _SessionColors.softGold),
          ),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: onPressed == null ? Colors.white38 : color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.values,
    this.header = false,
    this.active = false,
    this.complete = false,
    this.icon,
  });

  final List<String> values;
  final bool header;
  final bool active;
  final bool complete;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? _SessionColors.softGold
        : header
        ? _SessionColors.muted
        : Colors.white;
    final statusIndex = values.length - 1;

    return Container(
      height: header ? 54 : 60,
      decoration: BoxDecoration(
        border: active
            ? Border.all(color: _SessionColors.gold)
            : Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
        borderRadius: active ? BorderRadius.circular(7) : null,
      ),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              flex: i == statusIndex ? 2 : 1,
              child: i == statusIndex && !header
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: complete
                              ? Colors.lightGreenAccent
                              : active
                              ? _SessionColors.softGold
                              : _SessionColors.muted,
                          size: 20,
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            values[i],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: color, fontSize: 15),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      values[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: header ? 13 : 16,
                        fontWeight: header ? FontWeight.w800 : FontWeight.w400,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.icon, this.label, {this.highlighted = false});

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: highlighted ? _SessionColors.softGold : _SessionColors.muted,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: highlighted ? _SessionColors.softGold : Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

String _clock(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
}

String _trim(double value) =>
    value == value.roundToDouble() ? '${value.round()}' : '$value';

String _weight(double kg) => kg == 0 ? 'Bodyweight' : '${_trim(kg)} kg';

BoxDecoration _panelDecoration(double radius) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.035),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
  );
}

class _SessionColors {
  const _SessionColors._();

  static const black = Color(0xFF030303);
  static const gold = Color(0xFFCBA436);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFA6A6A6);
}
