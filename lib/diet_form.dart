import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'activity.dart';
import 'api_client.dart';
import 'diet.dart' show dayLabel;
import 'models.dart';
import 'providers.dart';
import 'router.dart';

class AddDietFormPage extends ConsumerStatefulWidget {
  const AddDietFormPage({super.key});

  @override
  ConsumerState<AddDietFormPage> createState() => _AddDietFormPageState();
}

enum _FoodSource { plan, custom }

class _AddDietFormPageState extends ConsumerState<AddDietFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController(text: '100');
  final _servings = TextEditingController(text: '1');
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _search = TextEditingController();

  late String _mealType = _mealForTime(TimeOfDay.now());
  late DateTime _date = ref.read(selectedDietDayProvider);
  TimeOfDay _time = TimeOfDay.now();
  _FoodSource _source = _FoodSource.plan;
  bool _saving = false;

  /// Sent with the entry so a retry after a network error is not duplicated.
  final _clientId = '${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _servings,
      _calories,
      _protein,
      _carbs,
      _fat,
      _search,
    ]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _amount,
      _servings,
      _calories,
      _protein,
      _carbs,
      _fat,
      _search,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static String _mealForTime(TimeOfDay time) {
    if (time.hour < 11) return 'Breakfast';
    if (time.hour < 15) return 'Lunch';
    if (time.hour < 18) return 'Snack';
    return 'Dinner';
  }

  double get _servingCount => _number(_servings) ?? 1;

  double _total(TextEditingController controller) =>
      (_number(controller) ?? 0) * _servingCount;

  static double? _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  void _usePlanMeal(MobileDietMeal meal) {
    setState(() {
      _name.text = meal.food.isEmpty ? meal.name : meal.food;
      _calories.text = meal.calorieValue?.toString() ?? '';
      final type = mealTypes
          .where((type) => meal.name.toLowerCase().contains(type.toLowerCase()))
          .firstOrNull;
      if (type != null) {
        _mealType = type;
      }
      _source = _FoodSource.custom;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = dateOnly(picked));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      if (_source == _FoodSource.plan) {
        setState(() => _source = _FoodSource.custom);
      }
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref
          .read(foodLogProvider.notifier)
          .add(
            FoodEntry(
              id: _clientId,
              date: dateKey(_date),
              mealType: _mealType,
              time:
                  '${_time.hour.toString().padLeft(2, '0')}:'
                  '${_time.minute.toString().padLeft(2, '0')}',
              name: _name.text.trim(),
              servings: _servingCount,
              amountGrams: (_number(_amount) ?? 0) * _servingCount,
              calories: _total(_calories),
              protein: _total(_protein),
              carbs: _total(_carbs),
              fat: _total(_fat),
            ),
          );
    } on AurexApiException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      if (mounted) setState(() => _saving = false);
      return;
    }

    ref.read(selectedDietDayProvider.notifier).select(_date);
    messenger.showSnackBar(
      SnackBar(content: Text('${_name.text.trim()} added to $_mealType.')),
    );

    if (mounted) {
      popOrGo(context, AurexRoutes.diet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(activeDietPlanProvider).value;
    final query = _search.text.trim().toLowerCase();
    final planMeals = (plan?.meals ?? const <MobileDietMeal>[])
        .where(
          (meal) =>
              query.isEmpty ||
              '${meal.name} ${meal.food}'.toLowerCase().contains(query),
        )
        .toList();

    return Scaffold(
      backgroundColor: _FormColors.black,
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 126),
            children: [
              const _TopBar(),
              const SizedBox(height: 22),
              const _TitleBlock(),
              const SizedBox(height: 28),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('MEAL INFORMATION'),
                    const SizedBox(height: 14),
                    _InfoRow(
                      label: 'Meal Type',
                      child: DropdownButton<String>(
                        value: _mealType,
                        dropdownColor: const Color(0xFF141414),
                        underline: const SizedBox.shrink(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        items: [
                          for (final type in mealTypes)
                            DropdownMenuItem(value: type, child: Text(type)),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _mealType = value);
                        },
                      ),
                    ),
                    _InfoRow(
                      label: 'Time',
                      child: _SelectBox(
                        icon: Icons.schedule,
                        value: _time.format(context),
                        onTap: _pickTime,
                      ),
                    ),
                    _InfoRow(
                      label: 'Date',
                      showDivider: false,
                      child: _SelectBox(
                        icon: Icons.calendar_month_outlined,
                        value: dayLabel(_date),
                        onTap: _pickDate,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle('FOOD DETAILS'),
                    const SizedBox(height: 20),
                    SegmentedButton<_FoodSource>(
                      segments: const [
                        ButtonSegment(
                          value: _FoodSource.plan,
                          icon: Icon(Icons.menu_book_outlined),
                          label: Text('From Meal Plan'),
                        ),
                        ButtonSegment(
                          value: _FoodSource.custom,
                          icon: Icon(Icons.fastfood_outlined),
                          label: Text('Custom Food'),
                        ),
                      ],
                      selected: {_source},
                      onSelectionChanged: (selection) =>
                          setState(() => _source = selection.first),
                      style: SegmentedButton.styleFrom(
                        selectedForegroundColor: _FormColors.softGold,
                        foregroundColor: _FormColors.muted,
                        selectedBackgroundColor: Colors.black,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_source == _FoodSource.plan) ...[
                      _TextField(
                        controller: _search,
                        label: 'Search your meal plan',
                        icon: Icons.search,
                        validate: false,
                      ),
                      const SizedBox(height: 10),
                      if (plan == null || plan.meals.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Your diet plan has no meals listed. Use Custom '
                            'Food to log anything you ate.',
                            style: TextStyle(color: _FormColors.muted),
                          ),
                        )
                      else
                        for (final meal in planMeals)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.restaurant_rounded,
                              color: _FormColors.gold,
                            ),
                            title: Text(
                              meal.food.isEmpty ? meal.name : meal.food,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              meal.name,
                              style: const TextStyle(color: _FormColors.muted),
                            ),
                            trailing: Text(
                              meal.calories,
                              style: const TextStyle(
                                color: _FormColors.softGold,
                              ),
                            ),
                            onTap: () => _usePlanMeal(meal),
                          ),
                    ],
                    // Kept in the tree so validation still runs while the
                    // meal plan list is showing.
                    Offstage(
                      offstage: _source == _FoodSource.plan,
                      child: Column(
                        children: [
                          _TextField(
                            controller: _name,
                            label: 'Food name',
                            icon: Icons.fastfood_outlined,
                            numeric: false,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _TextField(
                                  controller: _amount,
                                  label: 'Amount',
                                  suffix: 'g',
                                  validate: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TextField(
                                  controller: _servings,
                                  label: 'Servings',
                                  suffix: 'serving',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _TextField(
                                  controller: _calories,
                                  label: 'Calories / serving',
                                  suffix: 'kcal',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TextField(
                                  controller: _protein,
                                  label: 'Protein',
                                  suffix: 'g',
                                  validate: false,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _TextField(
                                  controller: _carbs,
                                  label: 'Carbs',
                                  suffix: 'g',
                                  validate: false,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _TextField(
                                  controller: _fat,
                                  label: 'Fat',
                                  suffix: 'g',
                                  validate: false,
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
              const SizedBox(height: 18),
              _NutritionSummary(
                protein: _total(_protein),
                carbs: _total(_carbs),
                fat: _total(_fat),
                calories: _total(_calories),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 66,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _FormColors.softGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _saving ? 'Adding...' : 'Add Food',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
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
          onPressed: () => popOrGo(context, AurexRoutes.diet),
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 38),
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

class _NutritionSummary extends StatelessWidget {
  const _NutritionSummary({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.calories,
  });

  final double protein;
  final double carbs;
  final double fat;
  final double calories;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.sports_gymnastics_rounded,
        'Protein',
        '${_round(protein)} g',
        _FormColors.protein,
      ),
      (
        Icons.water_drop_rounded,
        'Carbs',
        '${_round(carbs)} g',
        _FormColors.gold,
      ),
      (Icons.opacity_rounded, 'Fats', '${_round(fat)} g', _FormColors.fat),
      (
        Icons.local_fire_department,
        'Calories',
        '${calories.round()} kcal',
        _FormColors.calorie,
      ),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 8,
            children: [
              Text(
                'NUTRITION SUMMARY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
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

  static String _round(double value) => value == value.roundToDouble()
      ? '${value.round()}'
      : value.toStringAsFixed(1);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.child,
    this.showDivider = true,
  });

  final String label;
  final Widget child;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
          child,
        ],
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _inputDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _FormColors.muted, size: 22),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.icon,
    this.suffix,
    this.numeric = true,
    this.validate = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? suffix;
  final bool numeric;

  /// Whether the field is required (and, when [numeric], must be above zero).
  final bool validate;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 17),
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: numeric
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
          : null,
      validator: (value) {
        final text = value?.trim() ?? '';
        if (!validate) return null;
        if (text.isEmpty) return '$label is required';
        if (numeric && (double.tryParse(text.replaceAll(',', '.')) ?? 0) <= 0) {
          return 'Enter a number above 0';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _FormColors.muted),
        prefixIcon: icon == null ? null : Icon(icon, color: _FormColors.muted),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: _FormColors.muted),
        errorStyle: const TextStyle(color: Color(0xFFFFB4AB)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.025),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _FormColors.gold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
        ),
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
