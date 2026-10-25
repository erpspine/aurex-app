/// Member activity saved through the `/activity` API: completed workout
/// sessions and the food diary.
library;

class LoggedSet {
  const LoggedSet({required this.reps, required this.weightKg});

  final int reps;
  final double weightKg;

  Map<String, dynamic> toJson() => {'reps': reps, 'weight_kg': weightKg};

  factory LoggedSet.fromJson(Map<String, dynamic> json) {
    return LoggedSet(
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0,
    );
  }
}

class WorkoutLogEntry {
  const WorkoutLogEntry({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.bodyPart,
    required this.completedAt,
    required this.durationSeconds,
    required this.sets,
  });

  final String id;
  final String exerciseId;
  final String exerciseName;
  final String bodyPart;
  final DateTime completedAt;
  final int durationSeconds;
  final List<LoggedSet> sets;

  double get topWeightKg => sets.fold<double>(
    0,
    (best, set) => set.weightKg > best ? set.weightKg : best,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'exercise_id': exerciseId,
    'exercise_name': exerciseName,
    'body_part': bodyPart,
    'completed_at': completedAt.toIso8601String(),
    'duration_seconds': durationSeconds,
    'sets': [for (final set in sets) set.toJson()],
  };

  static WorkoutLogEntry? fromJson(Map<String, dynamic> json) {
    // The API returns an offset timestamp; show it in the device's time zone.
    final completedAt = DateTime.tryParse('${json['completed_at']}')?.toLocal();
    if (completedAt == null) {
      return null;
    }

    return WorkoutLogEntry(
      id: '${json['id'] ?? completedAt.microsecondsSinceEpoch}',
      exerciseId: '${json['exercise_id'] ?? ''}',
      exerciseName: '${json['exercise_name'] ?? 'Workout'}',
      bodyPart: '${json['body_part'] ?? ''}',
      completedAt: completedAt,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      sets: [
        for (final set in (json['sets'] as List? ?? const []).whereType<Map>())
          LoggedSet.fromJson(Map<String, dynamic>.from(set)),
      ],
    );
  }
}

const mealTypes = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];

class FoodEntry {
  const FoodEntry({
    required this.id,
    required this.date,
    required this.mealType,
    required this.time,
    required this.name,
    required this.servings,
    required this.amountGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final String id;

  /// Calendar day as `yyyy-mm-dd`.
  final String date;
  final String mealType;

  /// Time of day as `HH:mm`.
  final String time;
  final String name;
  final double servings;
  final double amountGrams;

  /// Totals for the whole entry (already multiplied by [servings]).
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'meal_type': mealType,
    'time': time,
    'name': name,
    'servings': servings,
    'amount_grams': amountGrams,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;

    return FoodEntry(
      id: '${json['id'] ?? ''}',
      date: '${json['date'] ?? ''}',
      mealType: '${json['meal_type'] ?? 'Snack'}',
      time: '${json['time'] ?? ''}',
      name: '${json['name'] ?? 'Food'}',
      servings: number('servings'),
      amountGrams: number('amount_grams'),
      calories: number('calories'),
      protein: number('protein'),
      carbs: number('carbs'),
      fat: number('fat'),
    );
  }
}

String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Number of consecutive days, ending today or yesterday, with a workout.
int workoutStreak(List<WorkoutLogEntry> history, DateTime now) {
  final days = history.map((entry) => dateKey(entry.completedAt)).toSet();
  var cursor = dateOnly(now);

  if (!days.contains(dateKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }

  var streak = 0;
  while (days.contains(dateKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streak;
}
