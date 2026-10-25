import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'models.dart';
import 'providers.dart';
import 'router.dart';

class ExerciseListPage extends ConsumerStatefulWidget {
  const ExerciseListPage.bodyParts({super.key})
    : titlePrefix = 'Body Part',
      titleHighlight = 'Exercises',
      subtitle = 'Choose your target muscle and start training',
      searchHint = 'Search Body Part',
      sectionLabel = 'CHOOSE BODY PART',
      helpTitle = 'Not sure what to train?',
      helpSubtitle = 'Let us help you find the best workout',
      _items = _bodyPartItems;

  const ExerciseListPage.equipment({super.key})
    : titlePrefix = 'Equipment Based',
      titleHighlight = 'Exercises',
      subtitle = 'Choose your equipment and start training',
      searchHint = 'Search Equipment',
      sectionLabel = 'CHOOSE EQUIPMENT',
      helpTitle = 'Not sure what to choose?',
      helpSubtitle = 'Let us help you find the best equipment',
      _items = _equipmentItems;

  final String titlePrefix;
  final String titleHighlight;
  final String subtitle;
  final String searchHint;
  final String sectionLabel;
  final String helpTitle;
  final String helpSubtitle;
  final List<_ExerciseCategory> _items;

  static const _bodyPartItems = [
    _ExerciseCategory(
      title: 'Chest',
      count: 124,
      image: 'assets/images/placeholder.png',
      icon: Icons.fitness_center_rounded,
      groupType: 'Body Part',
    ),
    _ExerciseCategory(
      title: 'Back',
      count: 98,
      image: 'assets/images/placeholder.png',
      icon: Icons.accessibility_new_rounded,
      groupType: 'Body Part',
    ),
    _ExerciseCategory(
      title: 'Shoulders',
      count: 56,
      image: 'assets/images/placeholder.png',
      icon: Icons.sports_gymnastics_rounded,
      groupType: 'Body Part',
    ),
    _ExerciseCategory(
      title: 'Arms',
      count: 48,
      image: 'assets/images/placeholder.png',
      icon: Icons.sports_martial_arts_rounded,
      groupType: 'Body Part',
    ),
    _ExerciseCategory(
      title: 'Legs',
      count: 72,
      image: 'assets/images/placeholder.png',
      icon: Icons.directions_run_rounded,
      groupType: 'Body Part',
    ),
    _ExerciseCategory(
      title: 'Abs',
      count: 180,
      image: 'assets/images/placeholder.png',
      icon: Icons.self_improvement_rounded,
      groupType: 'Body Part',
    ),
  ];

  static const _equipmentItems = [
    _ExerciseCategory(
      title: 'Dumbbell',
      count: 124,
      image: 'assets/images/placeholder.png',
      icon: Icons.fitness_center_rounded,
      groupType: 'Equipment',
    ),
    _ExerciseCategory(
      title: 'Barbell',
      count: 98,
      image: 'assets/images/placeholder.png',
      icon: Icons.linear_scale_rounded,
      groupType: 'Equipment',
    ),
    _ExerciseCategory(
      title: 'Kettlebell',
      count: 56,
      image: 'assets/images/placeholder.png',
      icon: Icons.lock_outline_rounded,
      groupType: 'Equipment',
    ),
    _ExerciseCategory(
      title: 'Resistance\nBands',
      count: 48,
      image: 'assets/images/placeholder.png',
      icon: Icons.link_rounded,
      groupType: 'Equipment',
    ),
    _ExerciseCategory(
      title: 'Machines',
      count: 210,
      image: 'assets/images/placeholder.png',
      icon: Icons.precision_manufacturing_rounded,
      groupType: 'Equipment',
    ),
    _ExerciseCategory(
      title: 'No Equipment',
      count: 180,
      image: 'assets/images/placeholder.png',
      icon: Icons.block_rounded,
      groupType: 'Equipment',
    ),
  ];

  @override
  ConsumerState<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends ConsumerState<ExerciseListPage> {
  static const _filters = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
    'Elite',
  ];
  final _search = TextEditingController();
  int _selectedFilter = 0;

  bool get _isBodyParts => widget.titlePrefix == 'Body Part';

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_ExerciseCategory> _items(List<MobileExercise>? exercises) {
    final List<_ExerciseCategory> items;
    if (exercises == null) {
      items = widget._items;
    } else {
      final filtered = _filteredExercises(exercises);
      items = _isBodyParts
          ? _categoriesFromExercises(
              fallbackItems: widget._items,
              exercises: filtered
                  .where((exercise) => exercise.bodyPart.isNotEmpty)
                  .toList(),
              groupType: 'Body Part',
              groupValue: (exercise) => exercise.bodyPart,
            )
          : _categoriesFromExercises(
              fallbackItems: widget._items,
              exercises: filtered
                  .where((exercise) => exercise.equipment.isNotEmpty)
                  .toList(),
              groupType: 'Equipment',
              groupValue: (exercise) => exercise.equipment,
            );
    }

    final query = _normalize(_search.text);
    if (query.isEmpty) {
      return items;
    }

    return items
        .where((item) => _normalize(item.title).contains(query))
        .toList();
  }

  List<MobileExercise> _filteredExercises(List<MobileExercise> exercises) {
    final selected = _filters[_selectedFilter];
    if (selected == 'All') {
      return exercises;
    }

    return exercises
        .where((exercise) => _normalize(exercise.level) == _normalize(selected))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final items = _items(exercisesAsync.value);
    final isLoading = exercisesAsync.isLoading;
    final error = exercisesAsync.hasValue ? null : exercisesAsync.error;
    Future<void> refresh() =>
        ref.refresh(exercisesProvider.future).then((_) {}, onError: (_) {});

    return Scaffold(
      backgroundColor: _ListColors.black,
      body: SafeArea(
        child: RefreshIndicator(
          color: _ListColors.gold,
          backgroundColor: _ListColors.black,
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 122),
            children: [
              const _TopBar(),
              const SizedBox(height: 38),
              Text.rich(
                TextSpan(
                  text: '${widget.titlePrefix} ',
                  children: [
                    TextSpan(
                      text: widget.titleHighlight,
                      style: const TextStyle(color: _ListColors.gold),
                    ),
                  ],
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.subtitle,
                style: const TextStyle(color: _ListColors.muted, fontSize: 17),
              ),
              const SizedBox(height: 30),
              _SearchField(hint: widget.searchHint, controller: _search),
              const SizedBox(height: 24),
              _FilterRow(
                filters: _filters,
                selectedIndex: _selectedFilter,
                onSelected: (index) {
                  setState(() {
                    _selectedFilter = index;
                  });
                },
              ),
              const SizedBox(height: 34),
              Text(
                widget.sectionLabel,
                style: const TextStyle(
                  color: _ListColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 16),
              if (error != null)
                _InlineError(message: error.toString(), onRetry: refresh)
              else ...[
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Nothing matches your search.',
                      style: TextStyle(color: _ListColors.muted),
                    ),
                  )
                else
                  _CategoryGrid(items: items),
                if (isLoading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(
                    color: _ListColors.gold,
                    backgroundColor: Colors.transparent,
                  ),
                ],
              ],
              const SizedBox(height: 20),
              _HelpCard(title: widget.helpTitle, subtitle: widget.helpSubtitle),
            ],
          ),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.controller});

  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      cursorColor: _ListColors.gold,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _ListColors.muted, fontSize: 17),
        prefixIcon: const Icon(
          Icons.search,
          color: _ListColors.muted,
          size: 32,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.035),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _ListColors.gold),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
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
              color: selected ? _ListColors.gold : _ListColors.muted,
              fontSize: 16,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.04),
            selectedColor: Colors.black,
            side: BorderSide(
              color: selected
                  ? _ListColors.gold
                  : Colors.white.withValues(alpha: 0.14),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          );
        },
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.items});

  final List<_ExerciseCategory> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth < 420 ? 12.0 : 14.0;
        final width = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(width: width, height: 230, child: _CategoryCard(item)),
          ],
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard(this.item);

  final _ExerciseCategory item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        AurexRoutes.exerciseGroup(
          item.groupType,
          item.title.replaceAll('\n', ' '),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _CategoryImage(item: item)),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: _ListColors.gold.withValues(alpha: 0.18),
                      child: Icon(item.icon, color: _ListColors.gold, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 72,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title.replaceAll('\n', ' '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text.rich(
                            TextSpan(
                              text: '${item.count} ',
                              style: const TextStyle(
                                color: _ListColors.gold,
                                fontWeight: FontWeight.w900,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Exercises',
                                  style: TextStyle(
                                    color: _ListColors.muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: _ListColors.gold,
                      size: 30,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Container(
          height: 108,
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.track_changes,
                color: _ListColors.gold,
                size: compact ? 38 : 50,
              ),
              SizedBox(width: compact ? 10 : 18),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ListColors.gold,
                        fontSize: compact ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ListColors.muted,
                        fontSize: compact ? 12 : 14,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              ElevatedButton(
                // Guided workout programs answer "what should I train?".
                onPressed: () => context.go(AurexRoutes.workouts),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ListColors.softGold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  minimumSize: Size(compact ? 76 : 0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 18,
                    vertical: 14,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      compact ? 'Find' : 'Find Now',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 22),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: _ListColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _ListColors.muted, fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(color: _ListColors.gold),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.item});

  final _ExerciseCategory item;

  @override
  Widget build(BuildContext context) {
    if (item.imageUrl.isNotEmpty) {
      return Image.network(
        item.imageUrl,
        fit: BoxFit.cover,
        alignment: Alignment.centerRight,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            item.image,
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          );
        },
      );
    }

    return Image.asset(
      item.image,
      fit: BoxFit.cover,
      alignment: Alignment.centerRight,
    );
  }
}

class _ExerciseCategory {
  const _ExerciseCategory({
    required this.title,
    required this.count,
    required this.image,
    required this.icon,
    this.imageUrl = '',
    this.groupType = 'Exercise',
  });

  final String title;
  final int count;
  final String image;
  final IconData icon;
  final String imageUrl;
  final String groupType;
}

List<_ExerciseCategory> _categoriesFromExercises({
  required List<_ExerciseCategory> fallbackItems,
  required List<MobileExercise> exercises,
  required String groupType,
  required String Function(MobileExercise exercise) groupValue,
}) {
  if (exercises.isEmpty) {
    return fallbackItems
        .map((item) => item.copyWith(count: 0, groupType: groupType))
        .toList();
  }

  final groups = <String, List<MobileExercise>>{};
  for (final exercise in exercises) {
    final value = groupValue(exercise).trim();
    if (value.isEmpty) {
      continue;
    }

    groups.putIfAbsent(_normalize(value), () => []).add(exercise);
  }

  final fallbackKeys = fallbackItems
      .map((item) => _normalize(item.title.replaceAll('\n', ' ')))
      .toSet();
  final items = fallbackItems.map((item) {
    final key = _normalize(item.title.replaceAll('\n', ' '));
    final matches = groups.entries
        .where((entry) => _groupKeysMatch(key, entry.key))
        .expand((entry) => entry.value)
        .toList();
    return item.copyWith(
      count: matches.length,
      imageUrl: _firstImageUrl(matches),
      groupType: groupType,
    );
  }).toList();

  for (final entry in groups.entries) {
    if (fallbackKeys.any((key) => _groupKeysMatch(key, entry.key))) {
      continue;
    }

    final title = _titleCase(entry.key);
    items.add(
      _ExerciseCategory(
        title: title,
        count: entry.value.length,
        image: 'assets/images/placeholder.png',
        imageUrl: _firstImageUrl(entry.value),
        icon: groupType == 'Body Part'
            ? Icons.fitness_center_rounded
            : Icons.precision_manufacturing_rounded,
        groupType: groupType,
      ),
    );
  }

  return items;
}

String _firstImageUrl(List<MobileExercise> exercises) {
  for (final exercise in exercises) {
    if (exercise.imageUrl.isNotEmpty) {
      return exercise.imageUrl;
    }
  }

  return '';
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _groupKeysMatch(String fallbackKey, String backendKey) {
  return fallbackKey == backendKey ||
      fallbackKey.contains(backendKey) ||
      backendKey.contains(fallbackKey);
}

String _titleCase(String value) {
  return value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

extension on _ExerciseCategory {
  _ExerciseCategory copyWith({
    int? count,
    String? imageUrl,
    String? groupType,
  }) {
    return _ExerciseCategory(
      title: title,
      count: count ?? this.count,
      image: image,
      icon: icon,
      imageUrl: imageUrl ?? this.imageUrl,
      groupType: groupType ?? this.groupType,
    );
  }
}

class _ListColors {
  const _ListColors._();

  static const black = Color(0xFF030303);
  static const gold = Color(0xFFCBA436);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFA6A6A6);
}
