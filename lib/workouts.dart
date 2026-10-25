import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models.dart';
import 'providers.dart';
import 'router.dart';
import 'sheet.dart';

class WorkoutsPage extends ConsumerStatefulWidget {
  const WorkoutsPage({super.key, this.initialLevel});

  /// Level filter requested by the URL, e.g. from the home screen tiles.
  final String? initialLevel;

  @override
  ConsumerState<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends ConsumerState<WorkoutsPage> {
  static const _categories = [
    (Icons.grid_view_rounded, 'All'),
    (Icons.fitness_center_rounded, 'Strength'),
    (Icons.sports_gymnastics_rounded, 'Hypertrophy'),
    (Icons.favorite_rounded, 'Endurance'),
    (Icons.flash_on_rounded, 'Power'),
    (Icons.accessibility_new_rounded, 'Full Body'),
  ];

  static const _goals = [
    (Icons.sports_gymnastics_rounded, 'Muscle Gain'),
    (Icons.fitness_center_rounded, 'Strength'),
    (Icons.local_fire_department_rounded, 'Weight Loss'),
    (Icons.directions_run_rounded, 'Athletic Performance'),
  ];

  static const _defaultLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Elite',
  ];

  final _search = TextEditingController();
  int _selectedCategory = 0;
  String? _goal;
  String? _level;

  @override
  void initState() {
    super.initState();
    _level = widget.initialLevel;
    _search.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant WorkoutsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialLevel != oldWidget.initialLevel) {
      _level = widget.initialLevel;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<MobileWorkout> _filter(List<MobileWorkout> workouts) {
    final category = _selectedCategory == 0
        ? null
        : _categories[_selectedCategory].$2.toLowerCase();
    final query = _search.text.trim().toLowerCase();

    return workouts.where((workout) {
      final text =
          '${workout.name} ${workout.goal} ${workout.type} ${workout.level} '
                  '${workout.description}'
              .toLowerCase();

      return (category == null || text.contains(category)) &&
          (query.isEmpty || text.contains(query)) &&
          (_goal == null || _same(workout.goal, _goal!)) &&
          (_level == null || _same(workout.level, _level!));
    }).toList();
  }

  Future<void> _openFilter() async {
    final levels = (ref.read(workoutLevelsProvider).value ?? const [])
        .map((level) => level.name)
        .toList();

    final selected = await showAurexSheet<String>(
      context,
      _LevelSheet(
        levels: levels.isEmpty ? _defaultLevels : levels,
        selected: _level,
      ),
    );

    if (selected != null) {
      setState(() => _level = selected.isEmpty ? null : selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutsAsync = ref.watch(workoutsProvider);
    final workouts = workoutsAsync.value ?? const <MobileWorkout>[];
    final filteredWorkouts = _filter(workouts);
    // Errors are rendered by the sections below.
    Future<void> retry() =>
        ref.refresh(workoutsProvider.future).then((_) {}, onError: (_) {});

    return Scaffold(
      backgroundColor: _WorkoutColors.black,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: _WorkoutColors.gold,
          backgroundColor: _WorkoutColors.black,
          onRefresh: retry,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(32, 52, 32, 126),
            children: [
              const _TopBar(),
              const SizedBox(height: 22),
              const Text(
                'Workouts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Train smart. Stay consistent. See results.',
                style: TextStyle(color: _WorkoutColors.muted, fontSize: 19),
              ),
              const SizedBox(height: 26),
              _SearchAndFilter(
                controller: _search,
                filterActive: _level != null,
                onFilter: _openFilter,
              ),
              if (_level != null || _goal != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    if (_level != null)
                      _ActiveFilterChip(
                        label: _level!,
                        onClear: () => setState(() => _level = null),
                      ),
                    if (_goal != null)
                      _ActiveFilterChip(
                        label: _goal!,
                        onClear: () => setState(() => _goal = null),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              _CategoryTabs(
                categories: _categories,
                selectedIndex: _selectedCategory,
                onSelected: (index) {
                  setState(() {
                    _selectedCategory = index;
                  });
                },
              ),
              const SizedBox(height: 34),
              const _SectionHeader(title: 'WORKOUT PROGRAMS'),
              const SizedBox(height: 16),
              _WorkoutContentState(
                isLoading: workoutsAsync.isLoading && !workoutsAsync.hasValue,
                error: workoutsAsync.hasValue
                    ? null
                    : workoutsAsync.error?.toString(),
                onRetry: retry,
                child: _ProgramCarousel(workouts: workouts.take(6).toList()),
              ),
              const SizedBox(height: 36),
              const _SectionHeader(title: 'WORKOUT BY GOAL'),
              const SizedBox(height: 16),
              _GoalGrid(
                goals: [
                  for (final goal in _goals)
                    (
                      goal.$1,
                      goal.$2,
                      workouts.where((w) => _same(w.goal, goal.$2)).length,
                    ),
                ],
                selected: _goal,
                onSelected: (goal) =>
                    setState(() => _goal = _goal == goal ? null : goal),
              ),
              const SizedBox(height: 36),
              _SectionHeader(
                title: _goal == null && _level == null && _selectedCategory == 0
                    ? 'ALL WORKOUTS'
                    : 'MATCHING WORKOUTS',
              ),
              const SizedBox(height: 16),
              _WorkoutContentState(
                isLoading: workoutsAsync.isLoading && !workoutsAsync.hasValue,
                error: workoutsAsync.hasValue
                    ? null
                    : workoutsAsync.error?.toString(),
                onRetry: retry,
                child: _PopularWorkoutList(items: filteredWorkouts),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _same(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/images/placeholder.png',
        width: 176,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onClear});

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onClear,
      labelStyle: const TextStyle(color: _WorkoutColors.softGold),
      deleteIconColor: _WorkoutColors.softGold,
      backgroundColor: Colors.white.withValues(alpha: 0.04),
      side: const BorderSide(color: _WorkoutColors.gold),
    );
  }
}

class _LevelSheet extends StatelessWidget {
  const _LevelSheet({required this.levels, required this.selected});

  final List<String> levels;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by level',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (final option in ['', ...levels])
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  option.isEmpty ? 'All levels' : option,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: (selected ?? '') == option
                    ? const Icon(Icons.check, color: _WorkoutColors.softGold)
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({
    required this.controller,
    required this.filterActive,
    required this.onFilter,
  });

  final TextEditingController controller;
  final bool filterActive;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            cursorColor: _WorkoutColors.gold,
            decoration: InputDecoration(
              hintText: 'Search workouts, muscle groups...',
              hintStyle: const TextStyle(
                color: _WorkoutColors.muted,
                fontSize: 17,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: _WorkoutColors.muted,
                size: 31,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.035),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.16),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _WorkoutColors.gold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          height: 64,
          child: OutlinedButton.icon(
            onPressed: onFilter,
            style: OutlinedButton.styleFrom(
              foregroundColor: _WorkoutColors.softGold,
              side: BorderSide(
                color: filterActive
                    ? _WorkoutColors.gold
                    : Colors.white.withValues(alpha: 0.16),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            icon: const Icon(Icons.filter_list_rounded, size: 28),
            label: const Text(
              'Filter',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<(IconData, String)> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final item = categories[index];
          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 104,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.025),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? _WorkoutColors.gold
                      : Colors.white.withValues(alpha: 0.11),
                  width: selected ? 1.4 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.$1,
                    color: selected
                        ? _WorkoutColors.softGold
                        : _WorkoutColors.muted,
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? _WorkoutColors.softGold : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 21,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _WorkoutContentState extends StatelessWidget {
  const _WorkoutContentState({
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.child,
  });

  final bool isLoading;
  final String? error;
  final Future<void> Function() onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(color: _WorkoutColors.gold),
        ),
      );
    }

    if (error != null) {
      return _MessagePanel(
        message: error!,
        actionLabel: 'Retry',
        onTap: onRetry,
      );
    }

    return child;
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.message, this.actionLabel, this.onTap});

  final String message;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _WorkoutColors.muted, fontSize: 15),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onTap,
              child: Text(
                actionLabel!,
                style: const TextStyle(color: _WorkoutColors.softGold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgramCarousel extends StatelessWidget {
  const _ProgramCarousel({required this.workouts});

  final List<MobileWorkout> workouts;

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return const _MessagePanel(message: 'No workout programs available yet.');
    }

    return SizedBox(
      height: 304,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: workouts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return SizedBox(
            width: 246,
            child: InkWell(
              onTap: () => _openWorkout(context, workout),
              borderRadius: BorderRadius.circular(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _WorkoutImage(
                      imageUrl: workout.coverImageUrl,
                      asset: _fallbackImage(index),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.82),
                          ],
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        left: 14,
                        top: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _WorkoutColors.softGold,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workout.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${workout.goal} - ${workout.level}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Divider(color: Colors.white.withValues(alpha: 0.18)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.format_list_bulleted,
                                color: _WorkoutColors.muted,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${workout.exerciseCount} Exercises',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.schedule,
                                color: _WorkoutColors.muted,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                workout.duration,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GoalGrid extends StatelessWidget {
  const _GoalGrid({
    required this.goals,
    required this.selected,
    required this.onSelected,
  });

  /// Icon, goal name and number of workouts for it.
  final List<(IconData, String, int)> goals;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 620
            ? (constraints.maxWidth - 18) / 2
            : (constraints.maxWidth - 54) / 4;

        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (final goal in goals)
              SizedBox(
                width: width,
                height: 188,
                child: InkWell(
                  onTap: () => onSelected(goal.$2),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(
                      highlighted: selected == goal.$2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(goal.$1, color: _WorkoutColors.gold, size: 38),
                        const SizedBox(height: 14),
                        Text(
                          goal.$2,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${goal.$3} Workout${goal.$3 == 1 ? '' : 's'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _WorkoutColors.muted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PopularWorkoutList extends StatelessWidget {
  const _PopularWorkoutList({required this.items});

  final List<MobileWorkout> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _MessagePanel(message: 'No workouts match these filters.');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _PopularWorkoutRow(items[index], index: index),
            if (index < items.length - 1)
              Divider(color: Colors.white.withValues(alpha: 0.12), height: 22),
          ],
        ],
      ),
    );
  }
}

class _PopularWorkoutRow extends StatelessWidget {
  const _PopularWorkoutRow(this.item, {required this.index});

  final MobileWorkout item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openWorkout(context, item),
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 126,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 172,
                height: 112,
                child: _WorkoutImage(
                  imageUrl: item.coverImageUrl,
                  asset: _fallbackImage(index),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description.isEmpty ? item.goal : item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _WorkoutColors.muted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _Meta(
                        Icons.format_list_bulleted,
                        '${item.exerciseCount} Exercises',
                      ),
                      _Meta(Icons.schedule, item.duration),
                      _Meta(
                        Icons.bar_chart_rounded,
                        item.level,
                        color: _levelColor(item.level),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right,
              color: _WorkoutColors.softGold,
              size: 36,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutImage extends StatelessWidget {
  const _WorkoutImage({required this.imageUrl, required this.asset});

  final String imageUrl;
  final String asset;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Image.asset(asset, fit: BoxFit.cover);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(asset, fit: BoxFit.cover);
      },
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.label, {this.color = _WorkoutColors.muted});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}

String _fallbackImage(int index) {
  const images = [
    'assets/images/workouts_program_push.png',
    'assets/images/workouts_program_pull.png',
    'assets/images/workouts_program_leg.png',
    'assets/images/workouts_popular_upper.png',
    'assets/images/workouts_popular_full.png',
    'assets/images/workouts_popular_core.png',
    'assets/images/workouts_popular_hiit.png',
  ];

  return images[index % images.length];
}

Color _levelColor(String level) {
  return level.toLowerCase().contains('beginner')
      ? Colors.lightGreenAccent
      : _WorkoutColors.softGold;
}

BoxDecoration _cardDecoration({bool highlighted = false}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.035),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
      color: highlighted
          ? _WorkoutColors.gold
          : Colors.white.withValues(alpha: 0.14),
      width: highlighted ? 1.4 : 1,
    ),
  );
}

void _openWorkout(BuildContext context, MobileWorkout workout) {
  context.push(AurexRoutes.workout(workout.id));
}

class _WorkoutColors {
  const _WorkoutColors._();

  static const black = Color(0xFF030303);
  static const gold = Color(0xFFCBA436);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFA6A6A6);
}
