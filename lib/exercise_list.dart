import 'package:flutter/material.dart';

import 'bottom_nav.dart';
import 'exercise_detail_list.dart';

class ExerciseListPage extends StatefulWidget {
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
      image: 'assets/images/body_chest.png',
      icon: Icons.fitness_center_rounded,
      groupType: 'Body Part',
    ),
    _ExerciseCategory(
      title: 'Back',
      count: 98,
      image: 'assets/images/body_back.png',
      icon: Icons.accessibility_new_rounded,
      groupType: 'Body Part',
    ),
    _ExerciseCategory(
      title: 'Shoulders',
      count: 56,
      image: 'assets/images/body_shoulders.png',
      icon: Icons.sports_gymnastics_rounded,
      groupType: 'Body Part',
    ),
    _ExerciseCategory(
      title: 'Arms',
      count: 48,
      image: 'assets/images/body_arms.png',
      icon: Icons.sports_martial_arts_rounded,
      groupType: 'Body Part',
    ),
    _ExerciseCategory(
      title: 'Legs',
      count: 72,
      image: 'assets/images/body_legs.png',
      icon: Icons.directions_run_rounded,
      groupType: 'Body Part',
    ),
    _ExerciseCategory(
      title: 'Abs',
      count: 180,
      image: 'assets/images/body_abs.png',
      icon: Icons.self_improvement_rounded,
      groupType: 'Body Part',
    ),
  ];

  static const _equipmentItems = [
    _ExerciseCategory(
      title: 'Dumbbell',
      count: 124,
      image: 'assets/images/equip_dumbbell.png',
      icon: Icons.fitness_center_rounded,
      groupType: 'Equipment',
    ),
    _ExerciseCategory(
      title: 'Barbell',
      count: 98,
      image: 'assets/images/equip_barbell.png',
      icon: Icons.linear_scale_rounded,
      groupType: 'Equipment',
    ),
    _ExerciseCategory(
      title: 'Kettlebell',
      count: 56,
      image: 'assets/images/equip_kettlebell.png',
      icon: Icons.lock_outline_rounded,
      groupType: 'Equipment',
    ),
    _ExerciseCategory(
      title: 'Resistance\nBands',
      count: 48,
      image: 'assets/images/equip_band.png',
      icon: Icons.link_rounded,
      groupType: 'Equipment',
    ),
    _ExerciseCategory(
      title: 'Machines',
      count: 210,
      image: 'assets/images/equip_machine.png',
      icon: Icons.precision_manufacturing_rounded,
      groupType: 'Equipment',
    ),
    _ExerciseCategory(
      title: 'No Equipment',
      count: 180,
      image: 'assets/images/level_beginner.png',
      icon: Icons.block_rounded,
      groupType: 'Equipment',
    ),
  ];

  @override
  State<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  static const _filters = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
    'Elite',
  ];
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ListColors.black,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
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
                  style: const TextStyle(
                    color: _ListColors.muted,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 30),
                _SearchField(hint: widget.searchHint),
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
                _CategoryGrid(items: widget._items),
                const SizedBox(height: 20),
                _HelpCard(
                  title: widget.helpTitle,
                  subtitle: widget.helpSubtitle,
                ),
              ],
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
        const SizedBox(width: 48),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
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
              SizedBox(width: width, height: 214, child: _CategoryCard(item)),
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
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExerciseDetailListPage(
              groupType: item.groupType,
              title: item.title.replaceAll('\n', ' '),
              count: item.count,
              image: item.image,
            ),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                item.image,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.86),
                      Colors.black.withValues(alpha: 0.24),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 20,
              child: CircleAvatar(
                radius: 27,
                backgroundColor: _ListColors.gold.withValues(alpha: 0.18),
                child: Icon(item.icon, color: _ListColors.gold, size: 26),
              ),
            ),
            Positioned(
              left: 18,
              right: 14,
              bottom: 50,
              child: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
            Positioned(
              left: 18,
              bottom: 24,
              child: Text.rich(
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
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Positioned(
              right: 16,
              bottom: 28,
              child: Icon(
                Icons.chevron_right,
                color: _ListColors.gold,
                size: 32,
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
    return Container(
      height: 108,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes, color: _ListColors.gold, size: 50),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ListColors.gold,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _ListColors.muted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _ListColors.softGold,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            child: const Row(
              children: [
                Text(
                  'Find Now',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCategory {
  const _ExerciseCategory({
    required this.title,
    required this.count,
    required this.image,
    required this.icon,
    this.groupType = 'Exercise',
  });

  final String title;
  final int count;
  final String image;
  final IconData icon;
  final String groupType;
}

class _ListColors {
  const _ListColors._();

  static const black = Color(0xFF030303);
  static const gold = Color(0xFFCBA436);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFA6A6A6);
}
