import 'package:flutter/material.dart';

import 'bottom_nav.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileColors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(28, 48, 28, 126),
              children: const [
                _TopBar(),
                SizedBox(height: 22),
                _ProfileHeader(),
                SizedBox(height: 24),
                _UserMetaRow(),
                SizedBox(height: 26),
                _ProgressOverview(),
                SizedBox(height: 14),
                _BodyStats(),
                SizedBox(height: 14),
                _RecentWorkouts(),
                SizedBox(height: 14),
                _Achievements(),
              ],
            ),
            const Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: AurexBottomNavigation(currentIndex: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_none,
            color: Colors.white,
            size: 31,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings, color: Colors.white, size: 29),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text.rich(
          TextSpan(
            text: 'My ',
            children: [
              TextSpan(
                text: 'Progress',
                style: TextStyle(color: _ProfileColors.gold),
              ),
            ],
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track your progress and stay consistent.',
          style: TextStyle(color: _ProfileColors.muted, fontSize: 17),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 150,
                  height: 150,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _ProfileColors.gold,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/profile_avatar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withValues(alpha: 0.08),
                          child: const Icon(
                            Icons.person,
                            color: _ProfileColors.gold,
                            size: 80,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 8,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: _ProfileColors.softGold,
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.edit,
                        color: Colors.black,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 38),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'John Doe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        color: _ProfileColors.gold,
                        size: 23,
                      ),
                      SizedBox(width: 9),
                      Text(
                        'Intermediate',
                        style: TextStyle(
                          color: _ProfileColors.softGold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _UserMetaRow extends StatelessWidget {
  const _UserMetaRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.calendar_month, 'Member Since', 'Jan 2024'),
      (Icons.accessibility_new_rounded, 'Height', '178 cm'),
      (Icons.work_rounded, 'Weight', '72 kg'),
      (Icons.track_changes_rounded, 'Goal', 'Muscle Gain'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 620
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 18,
          children: [
            for (final item in items)
              SizedBox(
                width: itemWidth,
                child: Row(
                  children: [
                    Icon(item.$1, color: _ProfileColors.gold, size: 34),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ProfileColors.muted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: 'PROGRESS OVERVIEW', action: 'This Month'),
          const SizedBox(height: 16),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 176,
                  child: _MetricCard(
                    icon: Icons.fitness_center,
                    title: 'Workouts',
                    value: '18',
                    subtitle: 'Completed',
                    change: '20%',
                  ),
                ),
                SizedBox(
                  width: 176,
                  child: _MetricCard(
                    icon: Icons.schedule,
                    title: 'Workout Time',
                    value: '12h 45m',
                    subtitle: 'Total',
                    change: '15%',
                  ),
                ),
                SizedBox(
                  width: 176,
                  child: _MetricCard(
                    icon: Icons.local_fire_department,
                    title: 'Calories Burned',
                    value: '5,642',
                    subtitle: 'Total kcal',
                    change: '18%',
                  ),
                ),
                SizedBox(
                  width: 176,
                  child: _MetricCard(
                    icon: Icons.flash_on,
                    title: 'Streak',
                    value: '12',
                    subtitle: 'Days',
                    change: '9%',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(flex: 3, child: _ChartCard()),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 278,
                  padding: const EdgeInsets.all(18),
                  decoration: _innerDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Top Body Part',
                        style: TextStyle(
                          color: _ProfileColors.muted,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Shoulders',
                        style: TextStyle(
                          color: _ProfileColors.softGold,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Trained 6 times',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Spacer(),
                      Center(
                        child: Image.asset(
                          'assets/images/profile_body_part.png',
                          height: 142,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.accessibility_new_rounded,
                              color: _ProfileColors.gold,
                              size: 96,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyStats extends StatelessWidget {
  const _BodyStats();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.work_rounded, 'Weight', '72 kg', '▼ 1.5 kg'),
      (Icons.groups_rounded, 'Body Fat', '14 %', '▼ 2%'),
      (Icons.fitness_center_rounded, 'Muscle Mass', '31.2 kg', '▲ 1.8 kg'),
      (Icons.radar_rounded, 'BMI', '22.7', 'Normal'),
    ];

    return _Panel(
      child: Column(
        children: [
          const _PanelHeader(title: 'BODY STATS', action: 'View All'),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth < 620
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 36) / 4;

              return Wrap(
                spacing: 12,
                runSpacing: 18,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: itemWidth,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: _ProfileColors.gold.withValues(
                              alpha: 0.13,
                            ),
                            child: Icon(
                              item.$1,
                              color: _ProfileColors.gold,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _ProfileColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.$3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.$4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.lightGreenAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecentWorkouts extends StatelessWidget {
  const _RecentWorkouts();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (
        'Shoulder Press Machine',
        'Shoulders',
        'May 30, 2024',
        '4 Sets • 10 Reps • 30 kg',
        'assets/images/profile_recent_1.png',
      ),
      (
        'Lat Pulldown Machine',
        'Back',
        'May 29, 2024',
        '4 Sets • 12 Reps • 40 kg',
        'assets/images/profile_recent_2.png',
      ),
      (
        'Dumbbell Bench Press',
        'Chest',
        'May 28, 2024',
        '4 Sets • 10 Reps • 25 kg',
        'assets/images/profile_recent_3.png',
      ),
    ];

    return _Panel(
      child: Column(
        children: [
          const _PanelHeader(title: 'RECENT WORKOUTS', action: 'View All ›'),
          const SizedBox(height: 14),
          for (final row in rows)
            Container(
              constraints: const BoxConstraints(minHeight: 92),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: _innerDecoration(),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      row.$5,
                      width: 110,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 110,
                          height: 68,
                          color: Colors.white.withValues(alpha: 0.06),
                          child: const Icon(
                            Icons.fitness_center,
                            color: _ProfileColors.gold,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          row.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          row.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ProfileColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          row.$3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ProfileColors.muted,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          row.$4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ProfileColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Icon(
                    Icons.chevron_right,
                    color: _ProfileColors.softGold,
                    size: 30,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Achievements extends StatelessWidget {
  const _Achievements();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.local_fire_department, '7 Day Streak', '7'),
      (Icons.fitness_center, '10 Workouts', '10'),
      (Icons.emoji_events, 'First Milestone', ''),
      (Icons.track_changes, 'Consistency', ''),
      (Icons.sports_gymnastics, 'Strong Start', ''),
    ];

    return _Panel(
      child: Column(
        children: [
          const _PanelHeader(title: 'ACHIEVEMENTS', action: 'View All ›'),
          const SizedBox(height: 18),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (context, index) => Container(
                width: 1,
                height: 96,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.white.withValues(alpha: 0.12),
              ),
              itemBuilder: (context, index) {
                final item = items[index];

                return SizedBox(
                  width: 104,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: _ProfileColors.gold),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: item.$3.isEmpty
                            ? Icon(
                                item.$1,
                                color: _ProfileColors.gold,
                                size: 28,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item.$1,
                                    color: _ProfileColors.gold,
                                    size: 24,
                                  ),
                                  Text(
                                    item.$3,
                                    style: const TextStyle(
                                      color: _ProfileColors.gold,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.$2,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.change,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final String change;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 208,
      padding: const EdgeInsets.all(18),
      decoration: _innerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _ProfileColors.gold, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _ProfileColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Text(
            '▲ $change',
            style: const TextStyle(color: Colors.lightGreen, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 278,
      padding: const EdgeInsets.all(20),
      decoration: _innerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workout Performance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CustomPaint(
              painter: _ChartPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: _ProfileColors.softGold,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: child,
    );
  }
}

BoxDecoration _innerDecoration() {
  return BoxDecoration(
    color: Colors.black.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
  );
}

class _ChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [
      Offset(0, size.height * .82),
      Offset(size.width * .16, size.height * .74),
      Offset(size.width * .31, size.height * .62),
      Offset(size.width * .47, size.height * .50),
      Offset(size.width * .62, size.height * .28),
      Offset(size.width * .78, size.height * .18),
      Offset(size.width, size.height * .30),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x66E9C460), Color(0x00111111)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = _ProfileColors.gold
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = _ProfileColors.gold;
    for (final point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 2.5, Paint()..color = _ProfileColors.black);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileColors {
  const _ProfileColors._();

  static const black = Color(0xFF030303);
  static const gold = Color(0xFFCBA436);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFA6A6A6);
}
