import 'package:flutter/material.dart';

import 'bottom_nav.dart';

class AddDietFormPage extends StatelessWidget {
  const AddDietFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FormColors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(30, 52, 30, 126),
              children: const [
                _TopBar(),
                SizedBox(height: 22),
                _TitleBlock(),
                SizedBox(height: 28),
                _MealInformation(),
                SizedBox(height: 18),
                _FoodDetails(),
                SizedBox(height: 18),
                _ServingSize(),
                SizedBox(height: 18),
                _NutritionSummary(),
                SizedBox(height: 18),
                _AddToPanel(),
                SizedBox(height: 18),
                _SubmitButton(),
              ],
            ),
            const Positioned(
              left: 10,
              right: 10,
              bottom: 12,
              child: AurexBottomNavigation(currentIndex: 3),
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
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 38),
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

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Add Food',
          style: TextStyle(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Add your meal to track calories and macros.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _FormColors.muted, fontSize: 18),
        ),
      ],
    );
  }
}

class _MealInformation extends StatelessWidget {
  const _MealInformation();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('MEAL INFORMATION'),
          const SizedBox(height: 14),
          _InfoRow(
            label: 'Meal Type',
            value: 'Breakfast',
            icon: Icons.wb_sunny_outlined,
            iconColor: _FormColors.gold,
          ),
          _InfoRow(
            label: 'Time',
            value: '7:30 AM',
            icon: Icons.schedule,
            iconColor: _FormColors.muted,
          ),
          _InfoRow(
            label: 'Date',
            value: 'May 30, 2024',
            icon: Icons.calendar_month_outlined,
            iconColor: _FormColors.muted,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _FoodDetails extends StatelessWidget {
  const _FoodDetails();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('FOOD DETAILS'),
          const SizedBox(height: 20),
          const _SegmentedChoice(),
          const SizedBox(height: 18),
          const _SearchField(),
          const SizedBox(height: 24),
          const Text(
            'Selected Food',
            style: TextStyle(color: _FormColors.muted, fontSize: 16),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: _inputDecoration(),
            child: Row(
              children: [
                const _FoodThumb(),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grilled Chicken Breast',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '100 g',
                        style: TextStyle(
                          color: _FormColors.muted,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  '165 kcal',
                  style: TextStyle(
                    color: _FormColors.softGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 14),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.close, color: _FormColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServingSize extends StatelessWidget {
  const _ServingSize();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('SERVING SIZE'),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              final fields = [
                const _ServingField(label: 'Amount', value: '100', unit: 'g'),
                const _ServingField(
                  label: 'Servings',
                  value: '1.0',
                  unit: 'serving',
                ),
              ];

              if (compact) {
                return Column(
                  children: [fields[0], const SizedBox(height: 12), fields[1]],
                );
              }

              return Row(
                children: [
                  Expanded(child: fields[0]),
                  const SizedBox(width: 16),
                  Expanded(child: fields[1]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NutritionSummary extends StatelessWidget {
  const _NutritionSummary();

  static const items = [
    (Icons.sports_gymnastics_rounded, 'Protein', '31 g', _FormColors.protein),
    (Icons.water_drop_rounded, 'Carbs', '0 g', _FormColors.gold),
    (Icons.opacity_rounded, 'Fats', '3.6 g', _FormColors.fat),
    (Icons.local_fire_department, 'Calories', '165 kcal', _FormColors.calorie),
  ];

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'NUTRITION SUMMARY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8),
              Text(
                '(for this item)',
                style: TextStyle(color: _FormColors.muted, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 520
                  ? (constraints.maxWidth - 14) / 2
                  : (constraints.maxWidth - 3) / 4;

              return Wrap(
                spacing: constraints.maxWidth < 520 ? 14 : 0,
                runSpacing: 18,
                children: [
                  for (var i = 0; i < items.length; i++)
                    SizedBox(
                      width: width,
                      child: _NutritionItem(
                        icon: items[i].$1,
                        label: items[i].$2,
                        value: items[i].$3,
                        color: items[i].$4,
                        showBorder: constraints.maxWidth >= 520 && i > 0,
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

class _AddToPanel extends StatelessWidget {
  const _AddToPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('ADD TO'),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: _AddToChoice(
                    icon: Icons.today_outlined,
                    label: 'Add to Today',
                    selected: true,
                  ),
                ),
                Expanded(
                  child: _AddToChoice(
                    icon: Icons.event_outlined,
                    label: 'Add to Another Day',
                    selected: false,
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

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: ElevatedButton(
        onPressed: () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _FormColors.softGold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Add Food',
          style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          _SelectBox(icon: icon, iconColor: iconColor, value: value),
        ],
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.icon,
    required this.iconColor,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 206),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: _inputDecoration(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

class _SegmentedChoice extends StatelessWidget {
  const _SegmentedChoice();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: const [
          Expanded(
            child: _SegmentItem(
              icon: Icons.search,
              label: 'Search Food',
              selected: true,
            ),
          ),
          Expanded(
            child: _SegmentItem(
              icon: Icons.fastfood_outlined,
              label: 'Custom Food',
              selected: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: selected ? Border.all(color: _FormColors.gold) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? _FormColors.gold : _FormColors.muted,
            size: 24,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? _FormColors.softGold : _FormColors.muted,
                fontSize: 18,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: _inputDecoration(),
      child: const Row(
        children: [
          Icon(Icons.search, color: _FormColors.muted, size: 30),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Search for a food...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _FormColors.muted, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodThumb extends StatelessWidget {
  const _FoodThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8D3A), Color(0xFF73C94E)],
        ),
      ),
      child: const Icon(
        Icons.restaurant_rounded,
        color: Colors.black87,
        size: 36,
      ),
    );
  }
}

class _ServingField extends StatelessWidget {
  const _ServingField({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _inputDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _FormColors.muted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
              ],
            ),
          ),
          Text(
            unit,
            style: const TextStyle(color: _FormColors.muted, fontSize: 18),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.keyboard_arrow_down, color: _FormColors.muted),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  const _NutritionItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.showBorder,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: showBorder ? 22 : 0),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(
                left: BorderSide(color: Colors.white.withValues(alpha: 0.13)),
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 38),
          const SizedBox(width: 14),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _FormColors.muted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
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

class _AddToChoice extends StatelessWidget {
  const _AddToChoice({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        border: selected ? Border.all(color: _FormColors.gold) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: selected ? _FormColors.gold : _FormColors.muted,
            size: 23,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? _FormColors.softGold : _FormColors.muted,
                fontSize: 16,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
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
        fontSize: 19,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

BoxDecoration _inputDecoration() {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.025),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
  );
}

class _FormColors {
  const _FormColors._();

  static const black = Color(0xFF020202);
  static const gold = Color(0xFFD5A928);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFAAA9AD);
  static const protein = Color(0xFF69C94B);
  static const fat = Color(0xFF8059D9);
  static const calorie = Color(0xFFFF7048);
}
