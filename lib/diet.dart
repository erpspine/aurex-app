import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'activity.dart';
import 'api_client.dart';
import 'models.dart';
import 'providers.dart';
import 'router.dart';
import 'toast.dart';
import 'sheet.dart';

/// Daily calorie and macro targets for the diary.
class _Targets {
  const _Targets({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  /// The member's own goal wins, then the diet plan, then a 2,000 kcal
  /// default split 30% protein / 40% carbs / 30% fat.
  factory _Targets.resolve(DietPreferences preferences, MobileDietPlan? plan) {
    final calories =
        preferences.calorieGoal ?? plan?.calorieTarget ?? _defaultCalories;
    final usePlanMacros =
        preferences.calorieGoal == null && plan?.calorieTarget != null;

    return _Targets(
      calories: calories,
      protein:
          (usePlanMacros ? plan?.proteinTarget : null) ??
          (calories * 0.30 / 4).round(),
      carbs:
          (usePlanMacros ? plan?.carbsTarget : null) ??
          (calories * 0.40 / 4).round(),
      fat:
          (usePlanMacros ? plan?.fatTarget : null) ??
          (calories * 0.30 / 9).round(),
    );
  }

  static const _defaultCalories = 2000;
}

class DietPage extends ConsumerWidget {
  const DietPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDietDayProvider);
    final foodAsync = ref.watch(foodLogProvider);
    final entries = (foodAsync.value ?? const <FoodEntry>[])
        .where((entry) => entry.date == dateKey(day))
        .toList();
    final planAsync = ref.watch(activeDietPlanProvider);
    final targets = _Targets.resolve(
      ref.watch(dietPreferencesProvider).value ?? const DietPreferences(),
      planAsync.value,
    );

    Future<void> refresh() async {
      // Each section shows its own state, so failures are ignored here.
      Future<void> settle(Future<Object?> future) =>
          future.then((_) {}, onError: (_) {});

      await Future.wait([
        settle(ref.refresh(dietPlansProvider.future)),
        settle(ref.refresh(foodLogProvider.future)),
        settle(ref.refresh(waterLogProvider.future)),
        settle(ref.refresh(dietPreferencesProvider.future)),
      ]);
    }

    return Scaffold(
      backgroundColor: _DietColors.black,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: _DietColors.gold,
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 126),
            children: [
              const _TopBar(),
              const SizedBox(height: 24),
              const _Header(),
              const SizedBox(height: 24),
              const _DateSelector(),
              if (foodAsync.hasError && !foodAsync.hasValue) ...[
                const SizedBox(height: 16),
                _LoadError(
                  message:
                      'Could not load your food diary. '
                      '${foodAsync.error}',
                  onRetry: () => ref.invalidate(foodLogProvider),
                ),
              ] else if (foodAsync.isLoading && !foodAsync.hasValue) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(color: _DietColors.gold),
              ],
              const SizedBox(height: 24),
              _CalorieSummary(entries: entries, targets: targets),
              const SizedBox(height: 16),
              _MealsPanel(entries: entries),
              const SizedBox(height: 16),
              _WaterPanel(day: day),
              const SizedBox(height: 16),
              _MealPlanCard(planAsync: planAsync),
            ],
          ),
        ),
      ),
    );
  }
}

/// Runs a save and reports API failures in a snackbar.
Future<void> _guard(
  BuildContext context,
  Future<void> Function() action,
) async {
  final toaster = AurexToaster.of(context);
  try {
    await action();
  } on AurexApiException catch (error) {
    toaster.error('Not saved', error.message);
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: _DietColors.gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _DietColors.muted),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(color: _DietColors.softGold),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const SizedBox(width: 58),
        const Spacer(),
        Image.asset(
          'assets/images/placeholder.png',
          width: 176,
          fit: BoxFit.contain,
        ),
        const Spacer(),
        _IconBox(
          icon: Icons.calendar_month_outlined,
          tooltip: 'Pick a day',
          onTap: () async {
            final notifier = ref.read(selectedDietDayProvider.notifier);
            final picked = await showDatePicker(
              context: context,
              initialDate: ref.read(selectedDietDayProvider),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              notifier.select(picked);
            }
          },
        ),
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

class _DateSelector extends ConsumerWidget {
  const _DateSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDietDayProvider);
    final notifier = ref.read(selectedDietDayProvider.notifier);
    final isToday = dateKey(day) == dateKey(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Previous day',
          onPressed: () => notifier.shift(-1),
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 34),
        ),
        const SizedBox(width: 12),
        const Icon(
          Icons.calendar_month_outlined,
          color: _DietColors.gold,
          size: 24,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            dayLabel(day),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _DietColors.softGold,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Next day',
          onPressed: isToday ? null : () => notifier.shift(1),
          icon: Icon(
            Icons.chevron_right,
            color: isToday ? Colors.white24 : Colors.white,
            size: 34,
          ),
        ),
      ],
    );
  }
}

class _CalorieSummary extends ConsumerWidget {
  const _CalorieSummary({required this.entries, required this.targets});

  final List<FoodEntry> entries;
  final _Targets targets;

  Future<void> _editGoal(BuildContext context, WidgetRef ref) async {
    final goal = await showDialog<int?>(
      context: context,
      builder: (context) => _CalorieGoalDialog(current: targets.calories),
    );

    if (goal != null && context.mounted) {
      await _guard(
        context,
        () => ref
            .read(dietPreferencesProvider.notifier)
            .setCalorieGoal(goal <= 0 ? null : goal),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double sum(double Function(FoodEntry) pick) =>
        entries.fold(0, (total, entry) => total + pick(entry));

    final calories = sum((e) => e.calories);
    final protein = sum((e) => e.protein);
    final carbs = sum((e) => e.carbs);
    final fat = sum((e) => e.fat);

    final macros = [
      _MacroData('PROTEIN', protein, targets.protein, _DietColors.protein),
      _MacroData('CARBS', carbs, targets.carbs, _DietColors.gold),
      _MacroData('FATS', fat, targets.fat, _DietColors.fat),
    ];

    final proteinKcal = protein * 4;
    final carbsKcal = carbs * 4;
    final fatKcal = fat * 9;
    final macroKcal = proteinKcal + carbsKcal + fatKcal;
    int share(double kcal) =>
        macroKcal == 0 ? 0 : (kcal / macroKcal * 100).round();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(
            title: 'CALORIE SUMMARY',
            action: 'Edit Goal',
            onTap: () => _editGoal(context, ref),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final ring = _CalorieRing(
                consumed: calories,
                goal: targets.calories,
              );

              if (constraints.maxWidth < 520) {
                return Column(
                  children: [
                    ring,
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
                  ring,
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
          const _PanelHeader(title: 'NUTRITION BREAKDOWN'),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: macroKcal == 0
                ? ColoredBox(
                    color: Colors.white.withValues(alpha: 0.12),
                    child: const SizedBox(height: 16, width: double.infinity),
                  )
                : Row(
                    children: [
                      for (final (kcal, color) in [
                        (proteinKcal, _DietColors.protein),
                        (carbsKcal, _DietColors.gold),
                        (fatKcal, _DietColors.fat),
                      ])
                        if (kcal > 0)
                          Expanded(
                            flex: math.max(1, kcal.round()),
                            child: ColoredBox(
                              color: color,
                              child: const SizedBox(height: 16),
                            ),
                          ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 10,
            children: [
              _Legend(
                color: _DietColors.protein,
                label: 'Protein ${share(proteinKcal)}% (${protein.round()}g)',
              ),
              _Legend(
                color: _DietColors.gold,
                label: 'Carbs ${share(carbsKcal)}% (${carbs.round()}g)',
              ),
              _Legend(
                color: _DietColors.fat,
                label: 'Fats ${share(fatKcal)}% (${fat.round()}g)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalorieGoalDialog extends StatefulWidget {
  const _CalorieGoalDialog({required this.current});

  final int current;

  @override
  State<_CalorieGoalDialog> createState() => _CalorieGoalDialogState();
}

class _CalorieGoalDialogState extends State<_CalorieGoalDialog> {
  late final _controller = TextEditingController(text: '${widget.current}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 800 || value > 10000) {
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF141414),
      title: const Text('Daily calorie goal'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          suffixText: 'kcal',
          helperText: 'Between 800 and 10,000',
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          // Zero clears the personal goal and falls back to the diet plan.
          onPressed: () => Navigator.pop(context, 0),
          child: const Text('Use plan goal'),
        ),
        TextButton(
          onPressed: _save,
          child: const Text(
            'Save',
            style: TextStyle(color: _DietColors.softGold),
          ),
        ),
      ],
    );
  }
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({required this.consumed, required this.goal});

  final double consumed;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final progress = goal == 0 ? 0.0 : (consumed / goal).clamp(0.0, 1.0);

    return SizedBox(
      width: 180,
      child: Column(
        children: [
          SizedBox(
            width: 162,
            height: 162,
            child: CustomPaint(
              painter: _RingPainter(progress),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _thousands(consumed.round()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Consumed',
                    style: TextStyle(color: _DietColors.muted, fontSize: 17),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '/ ${_thousands(goal)} kcal',
            style: const TextStyle(color: _DietColors.softGold, fontSize: 17),
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
          '${data.value.round()} g',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '/ ${data.goal} g',
          style: TextStyle(color: data.color, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: LinearProgressIndicator(
            value: data.goal == 0 ? 0 : (data.value / data.goal).clamp(0, 1),
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

class _MealsPanel extends ConsumerWidget {
  const _MealsPanel({required this.entries});

  final List<FoodEntry> entries;

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    FoodEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Remove food?'),
        content: Text('Remove ${entry.name} from ${entry.mealType}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFFF5A4F)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _guard(
        context,
        () => ref.read(foodLogProvider.notifier).remove(entry.id),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = entries.fold<double>(0, (sum, e) => sum + e.calories);
    final sorted = [...entries]
      ..sort((a, b) {
        final byMeal = mealTypes
            .indexOf(a.mealType)
            .compareTo(mealTypes.indexOf(b.mealType));
        return byMeal != 0 ? byMeal : a.time.compareTo(b.time);
      });

    return _Panel(
      child: Column(
        children: [
          _PanelHeader(
            title: 'MEALS',
            action: '${_thousands(total.round())} kcal',
          ),
          const SizedBox(height: 14),
          if (sorted.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No food logged for this day yet.',
                style: TextStyle(color: _DietColors.muted, fontSize: 15),
              ),
            )
          else
            for (final entry in sorted)
              _MealRow(
                entry: entry,
                onRemove: () => _remove(context, ref, entry),
              ),
          const SizedBox(height: 14),
          SizedBox(
            height: 58,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push(AurexRoutes.addFood),
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
  const _MealRow({required this.entry, required this.onRemove});

  final FoodEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final style = _mealStyle(entry.mealType);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.11)),
        ),
      ),
      child: Row(
        children: [
          _MealThumb(color: style.$2, icon: style.$1),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.mealType} • ${entry.time}',
                  style: const TextStyle(
                    color: _DietColors.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.name,
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
                    _MacroText(
                      'P ${entry.protein.round()}g',
                      _DietColors.protein,
                    ),
                    _MacroText('C ${entry.carbs.round()}g', _DietColors.gold),
                    _MacroText('F ${entry.fat.round()}g', _DietColors.fat),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${entry.calories.round()} kcal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: _DietColors.muted),
          ),
        ],
      ),
    );
  }
}

(IconData, Color) _mealStyle(String mealType) => switch (mealType) {
  'Breakfast' => (Icons.wb_sunny_outlined, _DietColors.gold),
  'Lunch' => (Icons.wb_sunny, const Color(0xFF73C94E)),
  'Dinner' => (Icons.nightlight_round, const Color(0xFFFF8D3A)),
  _ => (Icons.local_drink_outlined, const Color(0xFFEDEDED)),
};

class _MealThumb extends StatelessWidget {
  const _MealThumb({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
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
      child: Icon(icon, color: Colors.black.withValues(alpha: 0.72), size: 30),
    );
  }
}

class _WaterPanel extends ConsumerWidget {
  const _WaterPanel({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const total = WaterLogNotifier.dailyCups;
    final key = dateKey(day);
    final cups = ref.watch(waterLogProvider).value?[key] ?? 0;

    return _Panel(
      child: Column(
        children: [
          _PanelHeader(title: 'WATER INTAKE', action: '$cups / $total cups'),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < total; i++)
                Flexible(
                  child: IconButton(
                    tooltip: 'Set water to ${i + 1} cups',
                    padding: EdgeInsets.zero,
                    // Tapping the last filled cup empties it again.
                    onPressed: () => _guard(
                      context,
                      () => ref
                          .read(waterLogProvider.notifier)
                          .setCups(key, i + 1 == cups ? i : i + 1),
                    ),
                    icon: Icon(
                      i < cups ? Icons.local_drink : Icons.local_drink_outlined,
                      color: i < cups
                          ? const Color(0xFF58AFFF)
                          : Colors.white38,
                      size: 32,
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

class _MealPlanCard extends ConsumerWidget {
  const _MealPlanCard({required this.planAsync});

  final AsyncValue<MobileDietPlan?> planAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = planAsync.value;

    final (String value, String subtitle) = switch (planAsync) {
      _ when plan != null => (
        plan.name,
        [
          if (plan.dailyCalories.isNotEmpty) '${plan.dailyCalories} kcal',
          if (plan.meals.isNotEmpty) '${plan.meals.length} meals',
          if (plan.dietType.isNotEmpty) plan.dietType,
        ].join(' • '),
      ),
      AsyncError(:final error) => ('Unavailable', error.toString()),
      AsyncLoading() => ('Loading...', 'Fetching your diet plan'),
      _ => ('No plan yet', 'No diet plans have been published'),
    };

    return _Panel(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: plan == null
            ? (planAsync.hasError
                  ? () => ref.invalidate(dietPlansProvider)
                  : null)
            : () => showAurexSheet<void>(context, _MealPlanSheet(plan: plan)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: _DietColors.protein.withValues(alpha: 0.12),
              child: const Icon(
                Icons.calendar_month_outlined,
                color: _DietColors.protein,
                size: 34,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MEAL PLAN',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _DietColors.protein,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _DietColors.muted,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              planAsync.hasError ? Icons.refresh : Icons.chevron_right,
              color: _DietColors.softGold,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _MealPlanSheet extends ConsumerWidget {
  const _MealPlanSheet({required this.plan});

  final MobileDietPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(dietPlansProvider).value ?? const [];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        children: [
          Text(
            plan.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              plan.goal,
              plan.level,
              plan.duration,
            ].where((value) => value.isNotEmpty).join(' • '),
            style: const TextStyle(color: _DietColors.softGold, fontSize: 15),
          ),
          if (plan.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              plan.description,
              style: const TextStyle(
                color: _DietColors.muted,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (label, value) in [
                ('Calories', plan.dailyCalories),
                ('Protein', plan.protein),
                ('Carbs', plan.carbs),
                ('Fat', plan.fat),
              ])
                if (value.isNotEmpty)
                  Chip(
                    label: Text('$label: $value'),
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                  ),
            ],
          ),
          if (plan.meals.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text(
              'MEALS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            for (final meal in plan.meals)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  meal.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  meal.food,
                  style: const TextStyle(color: _DietColors.muted),
                ),
                trailing: meal.calories.isEmpty
                    ? null
                    : Text(
                        meal.calories,
                        style: const TextStyle(color: _DietColors.softGold),
                      ),
              ),
          ],
          for (final (title, text) in [
            ('INSTRUCTIONS', plan.mealInstructions),
            ('NUTRITIONIST NOTES', plan.nutritionistNotes),
          ])
            if (text.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: const TextStyle(
                  color: _DietColors.muted,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          if (plans.length > 1) ...[
            const SizedBox(height: 24),
            const Text(
              'SWITCH PLAN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            for (final option in plans)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  option.name,
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  option.goal,
                  style: const TextStyle(color: _DietColors.muted),
                ),
                trailing: option.id == plan.id
                    ? const Icon(Icons.check, color: _DietColors.softGold)
                    : null,
                onTap: () {
                  final toaster = AurexToaster.of(context);
                  Navigator.pop(context);
                  ref
                      .read(dietPreferencesProvider.notifier)
                      .selectPlan(option.id)
                      .catchError((Object error) {
                        toaster.error('Plan not changed', error.toString());
                      });
                },
              ),
          ],
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
    final label = action == null
        ? null
        : Text(
            action!,
            style: const TextStyle(
              color: _DietColors.softGold,
              fontSize: 17,
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
        if (label != null)
          onTap == null
              ? label
              : TextButton.icon(
                  onPressed: onTap,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(
                    Icons.chevron_right,
                    color: _DietColors.softGold,
                  ),
                  label: label,
                ),
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
  const _IconBox({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, color: _DietColors.gold, size: 28),
        ),
      ),
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
  _RingPainter(this.progress);

  final double progress;

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
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        active,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _MacroData {
  const _MacroData(this.label, this.value, this.goal, this.color);

  final String label;
  final double value;
  final int goal;
  final Color color;
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

/// `Today, May 30`, `Yesterday, May 29` or `Mon, May 27`.
String dayLabel(DateTime day) {
  final today = dateOnly(DateTime.now());
  final date = '${_months[day.month - 1]} ${day.day}';
  final difference = today.difference(dateOnly(day)).inDays;

  return switch (difference) {
    0 => 'Today, $date',
    1 => 'Yesterday, $date',
    _ => '${_weekdays[day.weekday - 1]}, $date',
  };
}

String _thousands(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (match) => ',',
);

class _DietColors {
  const _DietColors._();

  static const black = Color(0xFF020202);
  static const gold = Color(0xFFD5A928);
  static const softGold = Color(0xFFE9C460);
  static const muted = Color(0xFFAAA9AD);
  static const protein = Color(0xFF69C94B);
  static const fat = Color(0xFF8059D9);
}
