import 'package:flutter/material.dart';

import 'bottom_nav.dart';
import 'diet_form.dart';

class DietPage extends StatelessWidget {
  const DietPage({super.key});

  static const _macros = [
    _MacroData('PROTEIN', '142 g', '/ 160 g', 0.89, _DietColors.protein),
    _MacroData('CARBS', '186 g', '/ 250 g', 0.74, _DietColors.gold),
    _MacroData('FATS', '62 g', '/ 80 g', 0.78, _DietColors.fat),
  ];

  static const _meals = [
    _MealData(
      icon: Icons.wb_sunny_outlined,
      meal: 'Breakfast',
      time: '7:30 AM',
      title: 'Oats with Whey Protein, Banana, Almonds',
      calories: '520 kcal',
      protein: 'P 32g',
      carbs: 'C 58g',
      fats: 'F 12g',
      color: _DietColors.gold,
    ),
    _MealData(
      icon: Icons.wb_sunny,
      meal: 'Lunch',
      time: '12:30 PM',
      title: 'Grilled Chicken, Brown Rice, Steamed Vegetables',
      calories: '620 kcal',
      protein: 'P 45g',
      carbs: 'C 62g',
      fats: 'F 15g',
      color: Color(0xFF73C94E),
    ),
    _MealData(
      icon: Icons.local_drink_outlined,
      meal: 'Snack',
      time: '4:00 PM',
      title: 'Greek Yogurt, Berries, Honey',
      calories: '230 kcal',
      protein: 'P 20g',
      carbs: 'C 28g',
      fats: 'F 4g',
      color: Color(0xFFEDEDED),
    ),
    _MealData(
      icon: Icons.nightlight_round,
      meal: 'Dinner',
      time: '7:00 PM',
      title: 'Grilled Salmon, Sweet Potato, Asparagus',
      calories: '472 kcal',
      protein: 'P 45g',
      carbs: 'C 38g',
      fats: 'F 16g',
      color: Color(0xFFFF8D3A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DietColors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(30, 52, 30, 126),
              children: const [
                _TopBar(),
                SizedBox(height: 24),
                _Header(),
                SizedBox(height: 24),
                _DateSelector(),
                SizedBox(height: 24),
                _CalorieSummary(macros: _macros),
                SizedBox(height: 16),
                _MealsPanel(meals: _meals),
                SizedBox(height: 16),
                _WaterPanel(),
                SizedBox(height: 16),
                _BottomCards(),
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
        const Spacer(),
        Image.asset(
          'assets/images/aurex_logo_app.png',
          width: 176,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        _IconBox(icon: Icons.calendar_month_outlined),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Diet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Fuel your body. Achieve your goals.',
          style: TextStyle(color: _DietColors.muted, fontSize: 19),
        ),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chevron_left, color: Colors.white, size: 34),
        SizedBox(width: 24),
        Icon(Icons.calendar_month_outlined, color: _DietColors.gold, size: 24),
        SizedBox(width: 10),
        Text(
          'Today, May 30',
          style: TextStyle(
            color: _DietColors.softGold,
            fontSize: 23,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(width: 24),
        Icon(Icons.chevron_right, color: Colors.white, size: 34),
      ],
    );
  }
}

class _CalorieSummary extends StatelessWidget {
  const _CalorieSummary({required this.macros});

  final List<_MacroData> macros;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: 'CALORIE SUMMARY', action: 'Edit Goal'),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;

              if (compact) {
                return Column(
                  children: [
                    const _CalorieRing(),
                    const SizedBox(height: 22),
                    for (final macro in macros) ...[
                      _MacroTile(data: macro),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  const _CalorieRing(),
                  const SizedBox(width: 22),
                  for (var i = 0; i < macros.length; i++) ...[
                    Expanded(child: _MacroTile(data: macros[i])),
                    if (i < macros.length - 1)
                      Container(
                        width: 1,
                        height: 112,
                        margin: const EdgeInsets.symmetric(horizontal: 18),
                        color: Colors.white.withValues(alpha: 0.13),
                      ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 16),
          const _PanelHeader(
            title: 'NUTRITION BREAKDOWN',
            action: 'View Details',
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const Row(
              children: [
                Expanded(
                  flex: 31,
                  child: ColoredBox(
                    color: _DietColors.protein,
                    child: SizedBox(height: 16),
                  ),
                ),
                Expanded(
                  flex: 40,
                  child: ColoredBox(
                    color: _DietColors.gold,
                    child: SizedBox(height: 16),
                  ),
                ),
                Expanded(
                  flex: 29,
                  child: ColoredBox(
                    color: _DietColors.fat,
                    child: SizedBox(height: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _Legend(color: _DietColors.protein, label: 'Protein 31% (142g)'),
              _Legend(color: _DietColors.gold, label: 'Carbs 40% (186g)'),
              _Legend(color: _DietColors.fat, label: 'Fats 29% (62g)'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Column(
        children: [
          SizedBox(
            width: 162,
            height: 162,
            child: CustomPaint(
              painter: _RingPainter(),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '1,842',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Consumed',
                    style: TextStyle(color: _DietColors.muted, fontSize: 17),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '/ 2,400 kcal',
            style: TextStyle(color: _DietColors.softGold, fontSize: 17),
          ),
        ],
      ),
    );
  }
}

class _MacroTile extends StatelessWidget {
  const _MacroTile({required this.data});

  final _MacroData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_macroIcon(data.label), color: data.color, size: 23),
            const SizedBox(width: 8),
            Text(
              data.label,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          data.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(data.goal, style: TextStyle(color: data.color, fontSize: 16)),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: LinearProgressIndicator(
            value: data.progress,
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            valueColor: AlwaysStoppedAnimation(data.color),
          ),
        ),
      ],
    );
  }

  static IconData _macroIcon(String label) {
    if (label == 'PROTEIN') {
      return Icons.sports_gymnastics_rounded;
    }
    if (label == 'CARBS') {
      return Icons.water_drop_rounded;
    }
    return Icons.opacity_rounded;
  }
}

class _MealsPanel extends StatelessWidget {
  const _MealsPanel({required this.meals});

  final List<_MealData> meals;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          const _PanelHeader(title: 'MEALS', action: '1,842 kcal'),
          const SizedBox(height: 14),
          for (final meal in meals) _MealRow(meal: meal),
          const SizedBox(height: 14),
          SizedBox(
            height: 58,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddDietFormPage()),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _DietColors.softGold,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_circle_outline, size: 24),
              label: const Text(
                'Add Food',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({required this.meal});

  final _MealData meal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.11)),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            child: Icon(meal.icon, color: _DietColors.gold, size: 30),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 86,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.meal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meal.time,
                  style: const TextStyle(
                    color: _DietColors.muted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _MealThumb(color: meal.color, icon: meal.icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _MacroText(meal.protein, _DietColors.protein),
                    _MacroText(meal.carbs, _DietColors.gold),
                    _MacroText(meal.fats, _DietColors.fat),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            meal.calories,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: _DietColors.softGold,
            size: 30,
          ),
        ],
      ),
    );
  }
}

class _MealThumb extends StatelessWidget {
  const _MealThumb({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.35),
          ],
        ),
      ),
      child: Icon(icon, color: Colors.black.withValues(alpha: 0.72), size: 34),
    );
  }
}

class _WaterPanel extends StatelessWidget {
  const _WaterPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          const _PanelHeader(title: 'WATER INTAKE', action: '8 / 10 cups'),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 10; i++)
                Icon(
                  i < 8 ? Icons.local_drink : Icons.local_drink_outlined,
                  color: i < 8 ? const Color(0xFF58AFFF) : Colors.white38,
                  size: 35,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomCards extends StatelessWidget {
  const _BottomCards();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        final cards = [
          const _ActionCard(
            icon: Icons.calendar_month_outlined,
            title: 'MEAL PLAN',
            value: 'High Protein Plan',
            subtitle: '2,400 kcal • 5 meals',
            color: _DietColors.protein,
          ),
          const _ActionCard(
            icon: Icons.shopping_cart_outlined,
            title: 'GROCERY LIST',
            value: '12 items',
            subtitle: 'View your grocery list',
            color: _DietColors.gold,
          ),
        ];

        if (compact) {
          return Column(
            children: [cards[0], const SizedBox(height: 14), cards[1]],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _DietColors.muted,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: _DietColors.softGold,
            size: 30,
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
            color: _DietColors.softGold,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right, color: _DietColors.softGold, size: 24),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(22)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: _DietColors.gold, size: 28),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 6, backgroundColor: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: _DietColors.muted, fontSize: 14),
        ),
      ],
    );
  }
}

class _MacroText extends StatelessWidget {
  const _MacroText(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
    );
  }
}

class _RingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final base = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final active = Paint()
      ..shader = const LinearGradient(
        colors: [_DietColors.gold, _DietColors.softGold],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.45,
      4.85,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MacroData {
  const _MacroData(
    this.label,
    this.value,
    this.goal,
    this.progress,
    this.color,
  );

  final String label;
  final String value;
  final String goal;
  final double progress;
  final Color color;
}

class _MealData {
  const _MealData({
    required this.icon,
    required this.meal,
    required this.time,
    required this.title,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.color,
  });

  final IconData icon;
  final String meal;
  final String time;
  final String title;
  final String calories;
  final String protein;
  final String carbs;
  final String fats;
  final Color color;
}

class _DietColors {
  const _DietColors._();

  static const black = Color(0xFF020202);
  static const gold = Color(0xFFD5A928);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFAAA9AD);
  static const protein = Color(0xFF69C94B);
  static const fat = Color(0xFF8059D9);
}
