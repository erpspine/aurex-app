import 'package:flutter/material.dart';

import 'bottom_nav.dart';
import 'workout_session.dart';

class WorkoutDetailPage extends StatelessWidget {
  const WorkoutDetailPage({
    super.key,
    required this.title,
    required this.muscle,
    required this.level,
    required this.reps,
  });

  final String title;
  final String muscle;
  final String level;
  final String reps;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _WorkoutColors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 124),
              children: [
                _HeroHeader(
                  title: title,
                  muscle: muscle,
                  level: level,
                  reps: reps,
                ),
                const SizedBox(height: 18),
                const _StatsPanel(),
                const SizedBox(height: 28),
                const _SectionTitle('MUSCLES WORKED'),
                const SizedBox(height: 14),
                const _MusclesWorkedCard(),
                const SizedBox(height: 28),
                const _HowToPerform(),
                const SizedBox(height: 22),
                Divider(color: Colors.white.withValues(alpha: 0.24)),
                const SizedBox(height: 22),
                const _WorkoutSets(),
                const SizedBox(height: 24),
                SizedBox(
                  height: 66,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkoutSessionPage(
                            title: title,
                            muscle: muscle,
                            level: level,
                            reps: reps,
                          ),
                        ),
                      );
                    },
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.muscle,
    required this.level,
    required this.reps,
  });

  final String title;
  final String muscle;
  final String level;
  final String reps;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Stack(
        children: [
          Positioned(
            top: 116,
            right: -28,
            bottom: 0,
            width: 450,
            child: Image.asset(
              'assets/images/workout_detail_hero.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const Spacer(),
                Image.asset(
                  'assets/images/aurex_logo_app.png',
                  width: 176,
                  fit: BoxFit.contain,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.ios_share,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.bookmark_border,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 140,
            width: 410,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _WorkoutColors.gold.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'MACHINE',
                    style: TextStyle(
                      color: _WorkoutColors.softGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.accessibility_new_rounded,
                      color: _WorkoutColors.gold,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      muscle,
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Build strong, capped shoulders by pressing weight overhead in a controlled movement.',
                  style: TextStyle(
                    color: _WorkoutColors.muted,
                    fontSize: 17,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const _Meta(Icons.schedule, '45 sec'),
                    const _DividerMark(),
                    _Meta(Icons.bar_chart_rounded, level),
                    const _DividerMark(),
                    _Meta(Icons.restaurant_rounded, reps),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel();

  @override
  Widget build(BuildContext context) {
    const stats = [
      (Icons.accessibility_new_rounded, 'Primary Muscle', 'Shoulders'),
      (Icons.track_changes_rounded, 'Type', 'Strength'),
      (Icons.fitness_center_rounded, 'Equipment', 'Machine'),
      (Icons.local_fire_department_rounded, 'Calories', '120-150'),
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
              child: Column(
                children: [
                  Icon(stats[i].$1, color: _WorkoutColors.gold, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    stats[i].$2,
                    style: const TextStyle(
                      color: _WorkoutColors.muted,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stats[i].$3,
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

class _MusclesWorkedCard extends StatelessWidget {
  const _MusclesWorkedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 236,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Image.asset(
              'assets/images/workout_muscles_shoulders.png',
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 14, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _Legend(
                    color: _WorkoutColors.softGold,
                    title: 'Primary',
                    subtitle: 'Anterior Deltoid',
                  ),
                  SizedBox(height: 24),
                  _Legend(
                    color: Color(0xFFFF8B1A),
                    title: 'Secondary',
                    subtitle: 'Lateral Deltoid',
                  ),
                  SizedBox(height: 24),
                  _Legend(
                    color: Color(0xFF8F8F8F),
                    title: 'Stabilizer',
                    subtitle: 'Triceps',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HowToPerform extends StatelessWidget {
  const _HowToPerform();

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Sit on the machine with your back firmly against the pad.',
      'Grip the handles at shoulder height with palms facing forward.',
      'Press the handles upward until your arms are fully extended.',
      'Slowly lower the handles back to the starting position.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Expanded(child: _SectionTitle('HOW TO PERFORM')),
            Text(
              'View Animation',
              style: TextStyle(
                color: _WorkoutColors.softGold,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.play_circle_outline,
              color: _WorkoutColors.softGold,
              size: 27,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < steps.length; i++) ...[
                    _StepLine(number: i + 1, text: steps[i]),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/workout_animation_thumb.png',
                    width: 230,
                    height: 186,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: _WorkoutColors.softGold,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WorkoutSets extends StatelessWidget {
  const _WorkoutSets();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('1', '20 kg', '12', '60 sec', 'Completed', Icons.check_circle_outline),
      ('2', '25 kg', '10', '60 sec', 'Completed', Icons.check_circle_outline),
      ('3', '30 kg', '10', '60 sec', 'In Progress', Icons.radio_button_checked),
      ('4', '30 kg', '8', '60 sec', 'Upcoming', Icons.radio_button_unchecked),
    ];

    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: _SectionTitle('WORKOUT SETS')),
            Text(
              'Rest Timer: 60 sec',
              style: TextStyle(
                color: _WorkoutColors.softGold,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.schedule, color: _WorkoutColors.softGold, size: 22),
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
              const _SetRow(
                values: ['SET', 'WEIGHT', 'REPS', 'REST', 'STATUS'],
                header: true,
              ),
              for (final row in rows)
                _SetRow(
                  values: [row.$1, row.$2, row.$3, row.$4, row.$5],
                  icon: row.$6,
                  active: row.$5 == 'In Progress',
                  complete: row.$5 == 'Completed',
                ),
            ],
          ),
        ),
      ],
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
        ? _WorkoutColors.softGold
        : header
        ? _WorkoutColors.muted
        : Colors.white;

    return Container(
      height: header ? 46 : 50,
      margin: active ? const EdgeInsets.symmetric(horizontal: 10) : null,
      decoration: BoxDecoration(
        border: active
            ? Border.all(color: _WorkoutColors.gold)
            : Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
        borderRadius: active ? BorderRadius.circular(7) : null,
      ),
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: i == 4 && !header
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: complete
                              ? Colors.greenAccent
                              : active
                              ? _WorkoutColors.softGold
                              : _WorkoutColors.muted,
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

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 15,
          height: 15,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            '$title\n$subtitle',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
      ],
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

class _WorkoutColors {
  const _WorkoutColors._();

  static const black = Color(0xFF030303);
  static const gold = Color(0xFFCBA436);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFA6A6A6);
}
