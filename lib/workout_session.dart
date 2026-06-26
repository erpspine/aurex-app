import 'package:flutter/material.dart';

import 'bottom_nav.dart';

class WorkoutSessionPage extends StatelessWidget {
  const WorkoutSessionPage({
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
      backgroundColor: _SessionColors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 126),
              children: [
                _SessionHeader(
                  title: title,
                  muscle: muscle,
                  level: level,
                  reps: reps,
                ),
                const SizedBox(height: 20),
                const _ProgressPanel(),
                const SizedBox(height: 26),
                const _CurrentSetPanel(),
                const SizedBox(height: 28),
                const _WorkoutSets(),
                const SizedBox(height: 20),
                const _TipsCard(),
                const SizedBox(height: 24),
                const _ActionButtons(),
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

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
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
      height: 408,
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: 0,
            width: 325,
            height: 300,
            child: Image.asset(
              'assets/images/session_hero.png',
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
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Image.asset(
                  'assets/images/placeholder.png',
                  width: 176,
                  fit: BoxFit.contain,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 138,
            child: Container(
              width: 132,
              height: 164,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
              ),
              child: Image.asset(
                'assets/images/session_machine_thumb.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            left: 156,
            top: 142,
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MACHINE',
                  style: TextStyle(
                    color: _SessionColors.softGold,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.accessibility_new_rounded,
                      color: _SessionColors.gold,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      muscle,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Wrap(
              spacing: 12,
              children: [
                const _InfoPill(Icons.schedule, '45 sec'),
                _InfoPill(Icons.bar_chart_rounded, level, highlighted: true),
                _InfoPill(Icons.restaurant_rounded, reps),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPanel extends StatelessWidget {
  const _ProgressPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 24),
      decoration: _panelDecoration(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SET PROGRESS',
                  style: TextStyle(color: _SessionColors.muted, fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text.rich(
                  TextSpan(
                    text: '2',
                    style: TextStyle(
                      color: _SessionColors.softGold,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                    children: [
                      TextSpan(
                        text: ' / 4',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.58,
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
          const SizedBox(width: 48),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WORKOUT TIME',
                style: TextStyle(color: _SessionColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 18),
              const Text(
                '06:45',
                style: TextStyle(
                  color: _SessionColors.softGold,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 28),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _SessionColors.softGold,
              side: const BorderSide(color: _SessionColors.gold),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(20),
            ),
            child: const Icon(Icons.pause, size: 32),
          ),
        ],
      ),
    );
  }
}

class _CurrentSetPanel extends StatelessWidget {
  const _CurrentSetPanel();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 620;

        return Container(
          padding: EdgeInsets.all(isNarrow ? 22 : 30),
          decoration: _panelDecoration(20),
          child: isNarrow
              ? Column(
                  children: const [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _CurrentSetSummary(compact: true)),
                        SizedBox(width: 16),
                        _UpNextCard(width: 128, compact: true),
                      ],
                    ),
                    SizedBox(height: 24),
                    _RestTimer(size: 218),
                  ],
                )
              : const Row(
                  children: [
                    Expanded(child: _CurrentSetSummary()),
                    _RestTimer(size: 250),
                    SizedBox(width: 28),
                    _UpNextCard(width: 168),
                  ],
                ),
        );
      },
    );
  }
}

class _CurrentSetSummary extends StatelessWidget {
  const _CurrentSetSummary({this.compact = false});

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
          '3',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 48 : 58,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          '10 REPS',
          style: TextStyle(
            color: Colors.white,
            fontSize: compact ? 24 : 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: compact ? 18 : 32),
        Text(
          '30 kg',
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
  const _UpNextCard({required this.width, this.compact = false});

  final double width;
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
          Text(
            'Set 4',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 20 : 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: compact ? 14 : 22),
          Text(
            '8 REPS',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 19 : 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 14 : 22),
          Text(
            '30 kg',
            style: TextStyle(
              color: _SessionColors.softGold,
              fontSize: compact ? 20 : 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestTimer extends StatelessWidget {
  const _RestTimer({required this.size});

  final double size;

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
              value: 0.83,
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
              const SizedBox(height: 16),
              const Text(
                '00:45',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () {},
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
  const _WorkoutSets();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('1', '20 kg', '12', '60 sec', 'Completed', Icons.check_circle_outline),
      ('2', '25 kg', '10', '60 sec', 'Completed', Icons.check_circle_outline),
      ('3', '30 kg', '10', '60 sec', 'In Progress', Icons.play_arrow),
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
                color: _SessionColors.softGold,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.edit, color: _SessionColors.softGold, size: 22),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: _panelDecoration(16),
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

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 162,
      padding: const EdgeInsets.fromLTRB(24, 22, 20, 20),
      decoration: _panelDecoration(16),
      child: Row(
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: _SessionColors.softGold,
            size: 48,
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TIPS',
                  style: TextStyle(
                    color: _SessionColors.softGold,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Keep your back against the pad and avoid locking your elbows at the top of the movement.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/session_tips_muscles.png',
            width: 175,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SecondaryButton(
            icon: Icons.sync,
            label: 'CHANGE WEIGHT\n30 kg',
            color: _SessionColors.softGold,
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 82,
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: _SessionColors.softGold,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 28),
              label: const Text(
                'COMPLETE SET',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _SecondaryButton(
            icon: Icons.check_circle_outline,
            label: 'END WORKOUT',
            color: Color(0xFFFF5A4F),
            onPressed: () => Navigator.of(context).pop(),
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
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
              child: i == 4 && !header
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
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
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
            size: 22,
          ),
          const SizedBox(width: 9),
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
