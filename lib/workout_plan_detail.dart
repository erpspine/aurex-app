import 'package:flutter/material.dart';

import 'api_client.dart';
import 'bottom_nav.dart';

class WorkoutPlanDetailPage extends StatelessWidget {
  const WorkoutPlanDetailPage({super.key, required this.workout});

  final MobileWorkout workout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _PlanColors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 124),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const Spacer(),
                    Image.asset(
                      'assets/images/placeholder.png',
                      width: 156,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 230,
                    child: workout.coverImageUrl.isEmpty
                        ? Image.asset(
                            'assets/images/workouts_program_push.png',
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            workout.coverImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/images/workouts_program_push.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  workout.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  workout.description.isEmpty
                      ? '${workout.goal} • ${workout.level}'
                      : workout.description,
                  style: const TextStyle(
                    color: _PlanColors.muted,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _Pill(Icons.calendar_month, '${workout.dayCount} Days'),
                    _Pill(
                      Icons.format_list_bulleted,
                      '${workout.exerciseCount} Exercises',
                    ),
                    _Pill(Icons.schedule, workout.duration),
                    _Pill(Icons.bar_chart, workout.level, highlighted: true),
                  ],
                ),
                const SizedBox(height: 30),
                const Text(
                  'WORKOUT PLAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                if (workout.workoutDays.isEmpty)
                  const _EmptyPlan()
                else
                  for (final day in workout.workoutDays) ...[
                    _DayCard(day: day),
                    const SizedBox(height: 16),
                  ],
              ],
            ),
            const Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: AurexBottomNavigation(currentIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final MobileWorkoutDay day;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: _PlanColors.softGold,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.dayNumber}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (day.notes.isNotEmpty)
                      Text(
                        day.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _PlanColors.muted,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (day.exercises.isEmpty)
            const Text(
              'No exercises added for this day.',
              style: TextStyle(color: _PlanColors.muted),
            )
          else
            for (var index = 0; index < day.exercises.length; index++) ...[
              _ExerciseRow(
                number: index + 1,
                exercise: day.exercises[index],
              ),
              if (index < day.exercises.length - 1)
                Divider(color: Colors.white.withValues(alpha: 0.1)),
            ],
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.number, required this.exercise});

  final int number;
  final Map<String, dynamic> exercise;

  @override
  Widget build(BuildContext context) {
    final name = _text(exercise['name'], fallback: 'Exercise');
    final bodyPart = _text(exercise['body_part'], fallback: 'Body part not set');
    final sets = _text(exercise['sets'], fallback: '-');
    final reps = _text(exercise['reps'], fallback: '-');
    final rest = _text(exercise['rest'], fallback: '-');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            '$number.',
            style: const TextStyle(
              color: _PlanColors.softGold,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$bodyPart • $sets sets • $reps reps • Rest $rest',
                  style: const TextStyle(
                    color: _PlanColors.muted,
                    fontSize: 13,
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

class _Pill extends StatelessWidget {
  const _Pill(this.icon, this.label, {this.highlighted = false});

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: highlighted ? _PlanColors.softGold : _PlanColors.muted,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: highlighted ? _PlanColors.softGold : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlan extends StatelessWidget {
  const _EmptyPlan();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: const Text(
        'No days or exercises have been added to this workout yet.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _PlanColors.muted),
      ),
    );
  }
}

String _text(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;

  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

class _PlanColors {
  const _PlanColors._();

  static const black = Color(0xFF030303);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFA6A6A6);
}
