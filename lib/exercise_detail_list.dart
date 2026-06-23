import 'package:flutter/material.dart';

import 'api_client.dart';
import 'bottom_nav.dart';
import 'workout_detail.dart';

class ExerciseDetailListPage extends StatefulWidget {
  const ExerciseDetailListPage({
    super.key,
    required this.groupType,
    required this.title,
    required this.count,
    required this.image,
  });

  final String groupType;
  final String title;
  final int count;
  final String image;

  @override
  State<ExerciseDetailListPage> createState() => _ExerciseDetailListPageState();
}

class _ExerciseDetailListPageState extends State<ExerciseDetailListPage> {
  static const _levelFilters = [
    'All Levels',
    'Beginner',
    'Intermediate',
    'Advanced',
    'Elite',
  ];
  static const _muscles = [
    (Icons.accessibility_new_rounded, 'All'),
    (Icons.fitness_center_rounded, 'Chest'),
    (Icons.accessibility_new_rounded, 'Back'),
    (Icons.sports_gymnastics_rounded, 'Shoulders'),
    (Icons.sports_martial_arts_rounded, 'Arms'),
    (Icons.directions_run_rounded, 'Legs'),
    (Icons.self_improvement_rounded, 'Abs'),
  ];

  int _levelIndex = 0;
  int _muscleIndex = 0;
  bool _isLoading = true;
  String? _error;
  List<MobileExercise> _exercises = const [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final exercises = await AurexApiClient.fetchExercises();
      if (!mounted) return;

      setState(() {
        _exercises = exercises;
        _isLoading = false;
      });
    } on AurexApiException catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.message;
        _isLoading = false;
      });
    }
  }

  List<MobileExercise> get _filteredExercises {
    final groupTitle = _normalize(widget.title);
    final level = _levelFilters[_levelIndex];
    final muscle = _muscles[_muscleIndex].$2;

    return _exercises.where((exercise) {
      final equipment = _normalize(exercise.equipment);
      final matchesGroup = widget.groupType == 'Body Part'
          ? _normalize(exercise.bodyPart) == groupTitle
          : equipment.isNotEmpty &&
              (equipment.contains(groupTitle) || groupTitle.contains(equipment));

      final matchesLevel =
          level == 'All Levels' || _normalize(exercise.level) == _normalize(level);

      final matchesMuscle =
          muscle == 'All' || _normalize(exercise.bodyPart) == _normalize(muscle);

      return matchesGroup && matchesLevel && matchesMuscle;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredExercises = _filteredExercises;

    return Scaffold(
      backgroundColor: _DetailColors.black,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              color: _DetailColors.gold,
              backgroundColor: _DetailColors.black,
              onRefresh: _loadExercises,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 122),
                children: [
                  const _TopBar(),
                  const SizedBox(height: 28),
                  _Header(
                    groupType: widget.groupType,
                    title: widget.title,
                    count: _isLoading ? widget.count : filteredExercises.length,
                    image: widget.image,
                  ),
                  const SizedBox(height: 24),
                  _SearchAndFilter(title: widget.title),
                  const SizedBox(height: 24),
                  _LevelFilters(
                    filters: _levelFilters,
                    selectedIndex: _levelIndex,
                    onSelected: (index) {
                      setState(() {
                        _levelIndex = index;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'TARGET MUSCLE',
                    style: TextStyle(
                      color: _DetailColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MuscleFilters(
                    selectedIndex: _muscleIndex,
                    onSelected: (index) {
                      setState(() {
                        _muscleIndex = index;
                      });
                    },
                  ),
                  const SizedBox(height: 28),
                  _ResultSortRow(count: filteredExercises.length),
                  const SizedBox(height: 14),
                  _ExerciseContentState(
                    isLoading: _isLoading,
                    error: _error,
                    onRetry: _loadExercises,
                    child: _ExerciseRows(
                      exercises: filteredExercises,
                      groupImage: widget.image,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: AurexBottomNavigation(),
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
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
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
            Icons.bookmark_border,
            color: Colors.white,
            size: 31,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.groupType,
    required this.title,
    required this.count,
    required this.image,
  });

  final String groupType;
  final String title;
  final int count;
  final String image;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 104,
          height: 104,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Image.asset(image, fit: BoxFit.cover),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                groupType.toUpperCase(),
                style: const TextStyle(
                  color: _DetailColors.gold,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  height: 1.04,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: '$count ',
                  style: const TextStyle(
                    color: _DetailColors.gold,
                    fontWeight: FontWeight.w700,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Exercises - Build Strength & Power',
                      style: TextStyle(
                        color: _DetailColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchAndFilter extends StatelessWidget {
  const _SearchAndFilter({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: const TextStyle(color: Colors.white),
            cursorColor: _DetailColors.gold,
            decoration: InputDecoration(
              hintText: 'Search exercises in $title',
              hintStyle: const TextStyle(
                color: _DetailColors.muted,
                fontSize: 16,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: _DetailColors.muted,
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
                borderSide: const BorderSide(color: _DetailColors.gold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        SizedBox(
          height: 64,
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _DetailColors.gold,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            icon: const Icon(Icons.filter_alt_outlined, size: 27),
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

class _LevelFilters extends StatelessWidget {
  const _LevelFilters({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final selected = selectedIndex == index;
          return ChoiceChip(
            selected: selected,
            label: Text(filters[index]),
            onSelected: (_) => onSelected(index),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? _DetailColors.gold : _DetailColors.muted,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.04),
            selectedColor: Colors.black,
            side: BorderSide(
              color: selected
                  ? _DetailColors.gold
                  : Colors.white.withValues(alpha: 0.14),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          );
        },
      ),
    );
  }
}

class _MuscleFilters extends StatelessWidget {
  const _MuscleFilters({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _ExerciseDetailListPageState._muscles.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _ExerciseDetailListPageState._muscles[index];
          final selected = selectedIndex == index;
          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 96,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected
                      ? _DetailColors.gold
                      : Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item.$1,
                    color: selected ? _DetailColors.gold : _DetailColors.muted,
                    size: 30,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.$2,
                    style: TextStyle(
                      color: selected ? _DetailColors.gold : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

class _ResultSortRow extends StatelessWidget {
  const _ResultSortRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text.rich(
          TextSpan(
            text: '$count ',
            style: const TextStyle(
              color: _DetailColors.gold,
              fontWeight: FontWeight.w800,
            ),
            children: const [
              TextSpan(
                text: 'Exercises',
                style: TextStyle(
                  color: _DetailColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          style: const TextStyle(fontSize: 17),
        ),
        const Spacer(),
        const Text(
          'Sort by',
          style: TextStyle(color: _DetailColors.muted, fontSize: 16),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: const Row(
            children: [
              Text(
                'Popularity',
                style: TextStyle(color: _DetailColors.gold, fontSize: 16),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down,
                color: _DetailColors.gold,
                size: 22,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseContentState extends StatelessWidget {
  const _ExerciseContentState({
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
        height: 180,
        child: Center(child: CircularProgressIndicator(color: _DetailColors.gold)),
      );
    }

    if (error != null) {
      return _MessagePanel(message: error!, actionLabel: 'Retry', onTap: onRetry);
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _DetailColors.muted, fontSize: 15),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onTap,
              child: Text(
                actionLabel!,
                style: const TextStyle(color: _DetailColors.gold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseRows extends StatelessWidget {
  const _ExerciseRows({required this.exercises, required this.groupImage});

  final List<MobileExercise> exercises;
  final String groupImage;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const _MessagePanel(
        message: 'No exercises match this selection yet.',
      );
    }

    return Column(
      children: [
        for (final exercise in exercises) ...[
          _ExerciseRow(exercise, fallbackImage: groupImage),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow(this.exercise, {required this.fallbackImage});

  final MobileExercise exercise;
  final String fallbackImage;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WorkoutDetailPage(
              title: exercise.name,
              muscle: exercise.bodyPart,
              level: exercise.level,
              reps: exercise.reps,
            ),
          ),
        );
      },
      child: Container(
        height: 188,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 178,
                height: double.infinity,
                child: _ExerciseImage(
                  imageUrl: exercise.imageUrl,
                  fallbackImage: fallbackImage,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.bookmark_border,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.accessibility_new_rounded,
                        color: _DetailColors.gold,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        exercise.bodyPart.isEmpty
                            ? exercise.category
                            : exercise.bodyPart,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Meta(Icons.schedule, exercise.restTime),
                      const _Separator(),
                      _Meta(Icons.view_comfy_alt_rounded, exercise.sets),
                      const _Separator(),
                      _Meta(Icons.restaurant_rounded, exercise.reps),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              color: exercise.level == 'Beginner'
                                  ? Colors.greenAccent
                                  : _DetailColors.muted,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              exercise.level,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right,
                        color: _DetailColors.gold,
                        size: 34,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseImage extends StatelessWidget {
  const _ExerciseImage({required this.imageUrl, required this.fallbackImage});

  final String imageUrl;
  final String fallbackImage;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Image.asset(fallbackImage, fit: BoxFit.cover);
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(fallbackImage, fit: BoxFit.cover);
      },
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
        Icon(icon, color: _DetailColors.muted, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: _DetailColors.muted, fontSize: 14),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 16,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

class _DetailColors {
  const _DetailColors._();

  static const black = Color(0xFF030303);
  static const gold = Color(0xFFCBA436);
  static const muted = Color(0xFFA6A6A6);
}
