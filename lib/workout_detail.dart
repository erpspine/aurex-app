import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'providers.dart';
import 'router.dart';

/// Details of a single exercise and the entry point to a workout session.
class WorkoutDetailPage extends ConsumerWidget {
  const WorkoutDetailPage({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdProvider(exerciseId));

    return Scaffold(
      backgroundColor: _WorkoutColors.black,
      body: SafeArea(
        top: false,
        child: switch (exerciseAsync) {
          AsyncData(value: final exercise?) => _ExerciseBody(
            exercise: exercise,
          ),
          AsyncData() => const _DetailMessage(
            message: 'This exercise is no longer available.',
          ),
          AsyncError(:final error) => _DetailMessage(
            message: error.toString(),
            onRetry: () => ref.invalidate(exercisesProvider),
          ),
          _ => const Center(
            child: CircularProgressIndicator(color: _WorkoutColors.softGold),
          ),
        },
      ),
    );
  }
}

class _ExerciseBody extends StatelessWidget {
  const _ExerciseBody({required this.exercise});

  final MobileExercise exercise;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 124),
      children: [
        const _TopBar(),
        const SizedBox(height: 18),
        _HeroHeader(exercise: exercise),
        const SizedBox(height: 18),
        _StatsPanel(exercise: exercise),
        if (exercise.muscleTags.isNotEmpty) ...[
          const SizedBox(height: 28),
          const _SectionTitle('MUSCLES WORKED'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final tag in exercise.muscleTags) _MuscleChip(label: tag),
            ],
          ),
        ],
        const SizedBox(height: 28),
        _HowToPerform(exercise: exercise),
        const SizedBox(height: 22),
        Divider(color: Colors.white.withValues(alpha: 0.24)),
        const SizedBox(height: 22),
        _PlannedSets(exercise: exercise),
        const SizedBox(height: 24),
        SizedBox(
          height: 66,
          child: ElevatedButton.icon(
            onPressed: () => context.push(AurexRoutes.session(exercise.id)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _WorkoutColors.softGold,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 28),
            label: const Text(
              'START WORKOUT',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => popOrGo(context, AurexRoutes.home),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
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
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 124),
      children: [
        const _TopBar(),
        const SizedBox(height: 60),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _WorkoutColors.muted, fontSize: 16),
        ),
        if (onRetry != null)
          Center(
            child: TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: _WorkoutColors.softGold),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.exercise});

  final MobileExercise exercise;

  @override
  Widget build(BuildContext context) {
    final badge = exercise.equipment.isNotEmpty
        ? exercise.equipment
        : exercise.category;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: _ExerciseImage(url: exercise.imageUrl),
          ),
        ),
        const SizedBox(height: 22),
        if (badge.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _WorkoutColors.gold.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge.toUpperCase(),
              style: const TextStyle(
                color: _WorkoutColors.softGold,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          exercise.name.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        if (exercise.bodyPart.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.accessibility_new_rounded,
                color: _WorkoutColors.gold,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                exercise.bodyPart,
                style: const TextStyle(color: Colors.white, fontSize: 17),
              ),
            ],
          ),
        ],
        if (exercise.description.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            exercise.description,
            style: const TextStyle(
              color: _WorkoutColors.muted,
              fontSize: 17,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Meta(Icons.schedule, 'Rest ${exercise.restTime}'),
            const _DividerMark(),
            _Meta(Icons.bar_chart_rounded, exercise.level),
            const _DividerMark(),
            _Meta(Icons.repeat_rounded, exercise.reps),
          ],
        ),
      ],
    );
  }
}

class _ExerciseImage extends StatelessWidget {
  const _ExerciseImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const fallback = 'assets/images/workout_detail_hero.png';

    if (url.isEmpty) {
      return Image.asset(fallback, fit: BoxFit.cover);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Image.asset(fallback, fit: BoxFit.cover),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.exercise});

  final MobileExercise exercise;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        Icons.accessibility_new_rounded,
        'Primary Muscle',
        _orDash(exercise.bodyPart),
      ),
      (Icons.track_changes_rounded, 'Type', _orDash(exercise.category)),
      (
        Icons.fitness_center_rounded,
        'Equipment',
        exercise.equipment.isEmpty ? 'None' : exercise.equipment,
      ),
      (Icons.view_comfy_alt_rounded, 'Sets', '${exercise.setCount}'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Icon(stats[i].$1, color: _WorkoutColors.gold, size: 30),
                    const SizedBox(height: 10),
                    Text(
                      stats[i].$2,
                      style: const TextStyle(
                        color: _WorkoutColors.muted,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stats[i].$3,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _WorkoutColors.softGold,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            if (i < stats.length - 1)
              Container(
                width: 1,
                height: 78,
                color: Colors.white.withValues(alpha: 0.16),
              ),
          ],
        ],
      ),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _WorkoutColors.gold.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}

class _HowToPerform extends StatelessWidget {
  const _HowToPerform({required this.exercise});

  final MobileExercise exercise;

  Future<void> _openVideo(BuildContext context) async {
    final uri = Uri.tryParse(exercise.videoUrl);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the exercise video.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = exercise.instructions
        .expand((step) => step.split('\n'))
        .map((step) => step.trim())
        .where((step) => step.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('HOW TO PERFORM')),
            if (exercise.videoUrl.isNotEmpty)
              TextButton.icon(
                onPressed: () => _openVideo(context),
                style: TextButton.styleFrom(
                  foregroundColor: _WorkoutColors.softGold,
                ),
                icon: const Icon(Icons.play_circle_outline, size: 26),
                label: const Text(
                  'Watch Video',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (steps.isEmpty)
          const Text(
            'Step-by-step instructions have not been added for this exercise '
            'yet. Ask a trainer at the front desk for a demonstration.',
            style: TextStyle(
              color: _WorkoutColors.muted,
              fontSize: 15,
              height: 1.35,
            ),
          )
        else
          for (var i = 0; i < steps.length; i++) ...[
            _StepLine(number: i + 1, text: steps[i]),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _PlannedSets extends StatelessWidget {
  const _PlannedSets({required this.exercise});

  final MobileExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('WORKOUT SETS')),
            Text(
              'Rest: ${exercise.restTime}',
              style: const TextStyle(
                color: _WorkoutColors.softGold,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.schedule,
              color: _WorkoutColors.softGold,
              size: 22,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Column(
            children: [
              const _SetRow(values: ['SET', 'REPS', 'REST'], header: true),
              for (var set = 1; set <= exercise.setCount; set++)
                _SetRow(values: ['$set', exercise.reps, exercise.restTime]),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.values, this.header = false});

  final List<String> values;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final color = header ? _WorkoutColors.muted : Colors.white;

    return Container(
      height: header ? 46 : 50,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          for (final value in values)
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: header ? 13 : 15,
                  fontWeight: header ? FontWeight.w800 : FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _WorkoutColors.gold),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: _WorkoutColors.softGold,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _WorkoutColors.muted,
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ),
      ],
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

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _WorkoutColors.muted, size: 17),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: _WorkoutColors.muted, fontSize: 15),
        ),
      ],
    );
  }
}

class _DividerMark extends StatelessWidget {
  const _DividerMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

String _orDash(String value) => value.trim().isEmpty ? '-' : value;

class _WorkoutColors {
  const _WorkoutColors._();

  static const black = Color(0xFF030303);
  static const gold = Color(0xFFCBA436);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFA6A6A6);
}
