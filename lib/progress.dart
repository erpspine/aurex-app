import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'activity.dart';
import 'models.dart';
import 'providers.dart';
import 'router.dart';

/// Monthly training summary built from the member profile and the workout
/// sessions completed in the app.
class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final historyAsync = ref.watch(workoutHistoryProvider);
    final history = historyAsync.value ?? const <WorkoutLogEntry>[];
    final stats = _ProgressStats.from(history, DateTime.now());

    Future<void> refresh() async {
      // Each section shows its own state, so failures are ignored here.
      Future<void> settle(Future<Object?> future) =>
          future.then((_) {}, onError: (_) {});

      await Future.wait([
        settle(ref.refresh(profileProvider.future)),
        settle(ref.refresh(workoutHistoryProvider.future)),
      ]);
    }

    return Scaffold(
      backgroundColor: _ProfileColors.black,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: _ProfileColors.gold,
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 126),
            children: [
              const _TopBar(),
              const SizedBox(height: 10),
              _ProfileHeader(profile: profile),
              const SizedBox(height: 24),
              if (profile != null) ...[
                _UserMetaRow(profile: profile),
                const SizedBox(height: 26),
              ],
              if (historyAsync.hasError && !historyAsync.hasValue) ...[
                _Panel(
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: _ProfileColors.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Could not load your workout history. '
                          '${historyAsync.error}',
                          style: const TextStyle(color: _ProfileColors.muted),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(workoutHistoryProvider),
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: _ProfileColors.softGold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ] else if (!historyAsync.hasValue) ...[
                const LinearProgressIndicator(color: _ProfileColors.gold),
                const SizedBox(height: 14),
              ] else if (history.isEmpty) ...[
                const _GetStartedCard(),
                const SizedBox(height: 14),
              ],
              _ProgressOverview(stats: stats),
              const SizedBox(height: 14),
              if (profile != null) ...[
                _BodyStats(profile: profile),
                const SizedBox(height: 14),
              ],
              if (history.isNotEmpty) ...[
                _RecentWorkouts(entries: history.take(5).toList()),
                const SizedBox(height: 14),
              ],
              _Achievements(stats: stats),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressStats {
  const _ProgressStats({
    required this.monthWorkouts,
    required this.lastMonthWorkouts,
    required this.monthSeconds,
    required this.lastMonthSeconds,
    required this.monthSets,
    required this.totalWorkouts,
    required this.streak,
    required this.bestStreakDays,
    required this.dailyMinutes,
    required this.topBodyPart,
    required this.topBodyPartCount,
  });

  final int monthWorkouts;
  final int lastMonthWorkouts;
  final int monthSeconds;
  final int lastMonthSeconds;
  final int monthSets;
  final int totalWorkouts;
  final int streak;
  final int bestStreakDays;

  /// Minutes trained on each of the last seven days, oldest first.
  final List<(DateTime, double)> dailyMinutes;
  final String topBodyPart;
  final int topBodyPartCount;

  factory _ProgressStats.from(List<WorkoutLogEntry> history, DateTime now) {
    bool inMonth(DateTime date, int year, int month) =>
        date.year == year && date.month == month;

    final lastMonth = DateTime(now.year, now.month - 1);
    final thisMonth = history
        .where((e) => inMonth(e.completedAt, now.year, now.month))
        .toList();
    final previous = history
        .where((e) => inMonth(e.completedAt, lastMonth.year, lastMonth.month))
        .toList();

    final today = dateOnly(now);
    final dailyMinutes = [
      for (var offset = 6; offset >= 0; offset--)
        () {
          final day = today.subtract(Duration(days: offset));
          final seconds = history
              .where((e) => dateKey(e.completedAt) == dateKey(day))
              .fold<int>(0, (sum, e) => sum + e.durationSeconds);
          return (day, seconds / 60);
        }(),
    ];

    final bodyParts = <String, int>{};
    for (final entry in thisMonth.isEmpty ? history : thisMonth) {
      if (entry.bodyPart.isNotEmpty) {
        bodyParts.update(entry.bodyPart, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    final top = bodyParts.entries.isEmpty
        ? null
        : bodyParts.entries.reduce((a, b) => a.value >= b.value ? a : b);

    return _ProgressStats(
      monthWorkouts: thisMonth.length,
      lastMonthWorkouts: previous.length,
      monthSeconds: thisMonth.fold(0, (sum, e) => sum + e.durationSeconds),
      lastMonthSeconds: previous.fold(0, (sum, e) => sum + e.durationSeconds),
      monthSets: thisMonth.fold(0, (sum, e) => sum + e.sets.length),
      totalWorkouts: history.length,
      streak: workoutStreak(history, now),
      bestStreakDays: _bestStreak(history),
      dailyMinutes: dailyMinutes,
      topBodyPart: top?.key ?? '',
      topBodyPartCount: top?.value ?? 0,
    );
  }

  static int _bestStreak(List<WorkoutLogEntry> history) {
    final days = history.map((e) => dateOnly(e.completedAt)).toSet().toList()
      ..sort();
    var best = 0;
    var run = 0;
    DateTime? previous;
    for (final day in days) {
      run = previous != null && day.difference(previous).inDays == 1
          ? run + 1
          : 1;
      best = run > best ? run : best;
      previous = day;
    }
    return best;
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
          tooltip: 'Profile settings',
          onPressed: () => context.go(AurexRoutes.profile),
          icon: const Icon(Icons.settings, color: Colors.white, size: 29),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final MobileProfile? profile;

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile?.profilePhotoUrl ?? '';

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
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 116,
              height: 116,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _ProfileColors.gold,
              ),
              child: ClipOval(
                child: photoUrl.isEmpty
                    ? const _AvatarFallback()
                    : Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _AvatarFallback(),
                      ),
              ),
            ),
            const SizedBox(width: 26),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.fullName ?? 'Loading...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (profile != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bar_chart_rounded,
                            color: _ProfileColors.gold,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            profile!.workoutLevel,
                            style: const TextStyle(
                              color: _ProfileColors.softGold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.08),
      child: const Icon(Icons.person, color: _ProfileColors.gold, size: 64),
    );
  }
}

class _UserMetaRow extends StatelessWidget {
  const _UserMetaRow({required this.profile});

  final MobileProfile profile;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.calendar_month, 'Member Since', _monthYear(profile.memberSince)),
      (Icons.height, 'Height', _unit(profile.heightCm, 'cm')),
      (Icons.monitor_weight_outlined, 'Weight', _unit(profile.weightKg, 'kg')),
      (Icons.track_changes_rounded, 'Goal', profile.fitnessGoal),
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

class _GetStartedCard extends StatelessWidget {
  const _GetStartedCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_outline,
            color: _ProfileColors.softGold,
            size: 44,
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Finish a workout session and save it to start tracking your '
              'progress here.',
              style: TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => context.go(AurexRoutes.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: _ProfileColors.softGold,
              foregroundColor: Colors.black,
            ),
            child: const Text('Train'),
          ),
        ],
      ),
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  const _ProgressOverview({required this.stats});

  final _ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: 'PROGRESS OVERVIEW', action: 'This Month'),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 176,
                  child: _MetricCard(
                    icon: Icons.fitness_center,
                    title: 'Workouts',
                    value: '${stats.monthWorkouts}',
                    subtitle: 'Completed',
                    change: _change(
                      stats.monthWorkouts,
                      stats.lastMonthWorkouts,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 176,
                  child: _MetricCard(
                    icon: Icons.schedule,
                    title: 'Workout Time',
                    value: _duration(stats.monthSeconds),
                    subtitle: 'Total',
                    change: _change(stats.monthSeconds, stats.lastMonthSeconds),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 176,
                  child: _MetricCard(
                    icon: Icons.view_comfy_alt_rounded,
                    title: 'Sets',
                    value: '${stats.monthSets}',
                    subtitle: 'Completed',
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 176,
                  child: _MetricCard(
                    icon: Icons.flash_on,
                    title: 'Streak',
                    value: '${stats.streak}',
                    subtitle: stats.streak == 1 ? 'Day' : 'Days',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final chart = _ChartCard(dailyMinutes: stats.dailyMinutes);
              final topPart = _TopBodyPart(
                name: stats.topBodyPart,
                count: stats.topBodyPartCount,
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  children: [chart, const SizedBox(height: 10), topPart],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 3, child: chart),
                  const SizedBox(width: 10),
                  Expanded(child: topPart),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopBodyPart extends StatelessWidget {
  const _TopBodyPart({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 278,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _innerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Body Part',
            style: TextStyle(color: _ProfileColors.muted, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            name.isEmpty ? 'None yet' : name,
            style: const TextStyle(
              color: _ProfileColors.softGold,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            count == 0
                ? 'Start training to see it'
                : 'Trained $count time${count == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
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
    );
  }
}

class _BodyStats extends StatelessWidget {
  const _BodyStats({required this.profile});

  final MobileProfile profile;

  @override
  Widget build(BuildContext context) {
    final bmi = profile.bmi;
    final days = profile.daysBeforeExpiry;
    final items = [
      (
        Icons.monitor_weight_outlined,
        'Weight',
        _unit(profile.weightKg, 'kg'),
        '',
      ),
      (Icons.height, 'Height', _unit(profile.heightCm, 'cm'), ''),
      (
        Icons.radar_rounded,
        'BMI',
        bmi == null ? 'Not set' : bmi.toStringAsFixed(1),
        bmi == null ? 'Add height & weight' : _bmiCategory(bmi),
      ),
      (
        Icons.card_membership,
        'Membership',
        profile.membershipStatus.isEmpty ? 'Not set' : profile.membershipStatus,
        days == null
            ? ''
            : days < 0
            ? 'Expired'
            : '$days day${days == 1 ? '' : 's'} left',
      ),
    ];

    return _Panel(
      child: Column(
        children: [
          _PanelHeader(
            title: 'BODY STATS',
            action: 'Update',
            onTap: () => context.go(AurexRoutes.profile),
          ),
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
                            radius: 26,
                            backgroundColor: _ProfileColors.gold.withValues(
                              alpha: 0.13,
                            ),
                            child: Icon(
                              item.$1,
                              color: _ProfileColors.gold,
                              size: 26,
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
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (item.$4.isNotEmpty) ...[
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
  const _RecentWorkouts({required this.entries});

  final List<WorkoutLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          const _PanelHeader(title: 'RECENT WORKOUTS'),
          const SizedBox(height: 14),
          for (final entry in entries)
            InkWell(
              onTap: entry.exerciseId.isEmpty
                  ? null
                  : () => context.push(AurexRoutes.exercise(entry.exerciseId)),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(minHeight: 80),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: _innerDecoration(),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0x22CBA436),
                      child: Icon(
                        Icons.fitness_center,
                        color: _ProfileColors.gold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.exerciseName,
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
                            [
                              if (entry.bodyPart.isNotEmpty) entry.bodyPart,
                              '${entry.sets.length} Sets',
                              if (entry.topWeightKg > 0)
                                '${_trim(entry.topWeightKg)} kg',
                              _duration(entry.durationSeconds),
                            ].join(' • '),
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
                    const SizedBox(width: 10),
                    Text(
                      _shortDate(entry.completedAt),
                      style: const TextStyle(
                        color: _ProfileColors.muted,
                        fontSize: 13,
                      ),
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

class _Achievements extends StatelessWidget {
  const _Achievements({required this.stats});

  final _ProgressStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.emoji_events, 'First Workout', stats.totalWorkouts >= 1),
      (Icons.fitness_center, '10 Workouts', stats.totalWorkouts >= 10),
      (Icons.local_fire_department, '7 Day Streak', stats.bestStreakDays >= 7),
      (Icons.military_tech, '25 Workouts', stats.totalWorkouts >= 25),
      (Icons.workspace_premium, '50 Workouts', stats.totalWorkouts >= 50),
    ];

    return _Panel(
      child: Column(
        children: [
          _PanelHeader(
            title: 'ACHIEVEMENTS',
            action:
                '${items.where((item) => item.$3).length} / ${items.length}',
          ),
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
                final color = item.$3 ? _ProfileColors.gold : Colors.white24;

                return Semantics(
                  label: '${item.$2}, ${item.$3 ? 'unlocked' : 'locked'}',
                  child: SizedBox(
                    width: 104,
                    child: Column(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(color: color),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            item.$3 ? item.$1 : Icons.lock_outline,
                            color: color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.$2,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: item.$3 ? Colors.white : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
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
    this.change,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  /// Change against last month, e.g. `+20%`; hidden when unknown.
  final String? change;

  @override
  Widget build(BuildContext context) {
    final increase = change != null && !change!.startsWith('-');

    return Container(
      height: 180,
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
          if (change != null) ...[
            const Spacer(),
            Text(
              '${increase ? '▲' : '▼'} $change vs last month',
              style: TextStyle(
                color: increase ? Colors.lightGreen : const Color(0xFFFF8A80),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.dailyMinutes});

  final List<(DateTime, double)> dailyMinutes;

  @override
  Widget build(BuildContext context) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final total = dailyMinutes.fold<double>(0, (sum, day) => sum + day.$2);

    return Container(
      height: 278,
      padding: const EdgeInsets.all(20),
      decoration: _innerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 days • ${total.round()} min',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Semantics(
              label:
                  'Minutes trained per day: '
                  '${dailyMinutes.map((d) => '${weekdays[d.$1.weekday - 1]} ${d.$2.round()}').join(', ')}',
              child: CustomPaint(
                painter: _ChartPainter([
                  for (final day in dailyMinutes) day.$2,
                ]),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final day in dailyMinutes)
                Expanded(
                  child: Text(
                    weekdays[day.$1.weekday - 1],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ProfileColors.muted,
                      fontSize: 12,
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

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, this.action, this.onTap});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final actionText = action == null
        ? null
        : Text(
            action!,
            style: const TextStyle(
              color: _ProfileColors.softGold,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          );

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
        if (actionText != null)
          onTap == null
              ? actionText
              : TextButton(onPressed: onTap, child: actionText),
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

/// Area chart of [values], scaled to the largest value.
class _ChartPainter extends CustomPainter {
  _ChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty) {
      return;
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final step = values.length == 1 ? 0.0 : size.width / (values.length - 1);
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          i * step,
          size.height -
              (maxValue == 0 ? 0 : values[i] / maxValue) * size.height * 0.85 -
              4,
        ),
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
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.values.toString() != values.toString();
}

String? _change(int current, int previous) {
  if (previous == 0) {
    return null;
  }

  final percent = ((current - previous) / previous * 100).round();
  return '${percent >= 0 ? '+' : ''}$percent%';
}

String _duration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return minutes > 0 ? '${minutes}m' : '${seconds}s';
}

String _unit(String value, String unit) {
  final text = value.trim();
  return text.isEmpty ? 'Not set' : '$text $unit';
}

String _trim(double value) =>
    value == value.roundToDouble() ? '${value.round()}' : '$value';

String _bmiCategory(double bmi) {
  if (bmi < 18.5) return 'Underweight';
  if (bmi < 25) return 'Normal';
  if (bmi < 30) return 'Overweight';
  return 'Obese';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _monthYear(String isoDate) {
  final date = DateTime.tryParse(isoDate);
  return date == null ? 'Not set' : '${_months[date.month - 1]} ${date.year}';
}

String _shortDate(DateTime date) => '${_months[date.month - 1]} ${date.day}';

class _ProfileColors {
  const _ProfileColors._();

  static const black = Color(0xFF030303);
  static const gold = Color(0xFFCBA436);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFA6A6A6);
}
