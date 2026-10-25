import 'config.dart';

class AurexSession {
  const AurexSession({this.token, required this.user, this.member});

  /// Bearer token. Null on the web, where an HttpOnly cookie carries it.
  final String? token;
  final Map<String, dynamic> user;
  final Map<String, dynamic>? member;

  bool get isMember {
    final role = '${user['role'] ?? ''}'.trim().toLowerCase();
    final userType = '${user['user_type'] ?? ''}'.trim().toLowerCase();

    return role == 'member' || userType == 'member';
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user,
    'member': member,
  };

  static AurexSession? fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final user = json['user'];
    if (user is! Map) {
      return null;
    }

    return AurexSession(
      token: token is String && token.isNotEmpty ? token : null,
      user: Map<String, dynamic>.from(user),
      member: json['member'] is Map
          ? Map<String, dynamic>.from(json['member'] as Map)
          : null,
    );
  }
}

class MobileProfile {
  const MobileProfile({required this.user, required this.member});

  final Map<String, dynamic> user;
  final Map<String, dynamic> member;

  factory MobileProfile.fromPayload(Map<String, dynamic> payload) {
    return MobileProfile(
      user: payload['user'] is Map
          ? Map<String, dynamic>.from(payload['user'] as Map)
          : const {},
      member: payload['member'] is Map
          ? Map<String, dynamic>.from(payload['member'] as Map)
          : const {},
    );
  }

  String get fullName => _string(
    member['full_name'],
    fallback: _string(user['name'], fallback: 'Member'),
  );
  String get email =>
      _string(member['email'], fallback: _string(user['email']));
  String get phone =>
      _string(member['phone'], fallback: _string(user['phone']));
  String get gender => _string(member['gender']);
  String get dateOfBirth => _date(member['date_of_birth']);
  String get address => _string(member['address']);
  String get heightCm => _string(member['height_cm']);
  String get weightKg => _string(member['weight_kg']);
  String get fitnessGoal =>
      _string(member['fitness_goal'], fallback: 'General Fitness');
  String get workoutLevel =>
      _string(member['workout_level'], fallback: 'Beginner');
  String get emergencyName => _string(member['emergency_contact_name']);
  String get emergencyRelationship =>
      _string(member['emergency_contact_relationship']);
  String get emergencyPhone => _string(member['emergency_contact_phone']);
  String get memberSince => _date(member['start_date']);
  String get membershipStatus => _string(member['membership_status']);
  String get membershipPlanName {
    final plan = member['membership_plan'];
    if (plan is Map) {
      return _string(plan['name']);
    }

    return '';
  }

  String get cardNumber {
    final card = member['card_details'];
    if (card is Map) {
      return _string(card['card_number']);
    }

    return _string(member['access_code']);
  }

  String get cardStatus {
    final card = member['card_details'];
    if (card is Map) {
      return _string(
        card['status'],
        fallback: cardNumber.isEmpty ? 'Not linked' : 'Linked',
      );
    }

    return cardNumber.isEmpty ? 'Not linked' : 'Linked';
  }

  String get renewalDate =>
      _date(member['renewal_date'] ?? member['expiry_date']);
  int? get daysBeforeExpiry {
    final value = member['days_before_expiry'];
    if (value is int) return value;
    return int.tryParse(_string(value));
  }

  String get amountPaid => _currency(
    member['amount_paid'],
    _string(member['currency'], fallback: 'TZS'),
  );
  String get paymentMethod => _string(member['payment_method']);
  String get paymentStatus => _string(member['payment_status']);
  Map<String, dynamic> get latestPayment => member['latest_payment'] is Map
      ? Map<String, dynamic>.from(member['latest_payment'] as Map)
      : const {};

  List<Map<String, dynamic>> get recentPayments =>
      member['recent_payments'] is List
      ? (member['recent_payments'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : const [];

  String get latestPaymentAmount => latestPayment.isEmpty
      ? ''
      : _currency(
          latestPayment['amount'],
          _string(latestPayment['currency'], fallback: 'TZS'),
        );
  String get latestPaymentDate => _date(latestPayment['payment_date']);
  String get latestPaymentFor => _string(latestPayment['payment_for']);
  String get latestPaymentStatus => _string(latestPayment['payment_status']);
  String get profilePhotoUrl =>
      aurexMediaUrl(_string(user['profile_photo_path']));

  double? get heightValue => double.tryParse(heightCm);
  double? get weightValue => double.tryParse(weightKg);

  double? get bmi {
    final height = heightValue;
    final weight = weightValue;
    if (height == null || weight == null || height <= 0) {
      return null;
    }

    final meters = height / 100;
    return weight / (meters * meters);
  }

  int get completionPercent {
    final fields = [
      fullName,
      email,
      phone,
      gender,
      dateOfBirth,
      address,
      heightCm,
      weightKg,
      fitnessGoal,
      workoutLevel,
      emergencyName,
      emergencyPhone,
    ];
    final completed = fields.where((value) => value.trim().isNotEmpty).length;
    return ((completed / fields.length) * 100).round().clamp(0, 100);
  }
}

class MobileWorkout {
  const MobileWorkout({
    required this.id,
    required this.name,
    required this.goal,
    required this.level,
    required this.type,
    required this.duration,
    required this.caloriesBurn,
    required this.description,
    required this.coverImageUrl,
    required this.workoutDays,
    required this.exercises,
    required this.publishStatus,
    required this.showInMobileApp,
  });

  final String id;
  final String name;
  final String goal;
  final String level;
  final String type;
  final String duration;
  final String caloriesBurn;
  final String description;
  final String coverImageUrl;
  final List<MobileWorkoutDay> workoutDays;
  final List<Map<String, dynamic>> exercises;
  final String publishStatus;
  final bool showInMobileApp;

  int get dayCount => workoutDays.length;
  int get exerciseCount =>
      workoutDays.fold<int>(0, (total, day) => total + day.exercises.length);
  bool get isPublishedMobile => publishStatus == 'Published' && showInMobileApp;

  factory MobileWorkout.fromJson(Map<String, dynamic> json) {
    return MobileWorkout(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Workout'),
      goal: _string(json['goal'], fallback: 'General Fitness'),
      level: _string(json['workout_level'], fallback: 'All Levels'),
      type: _string(json['workout_type'], fallback: 'Workout'),
      duration: _duration(json['duration']),
      caloriesBurn: _string(json['calories_burn']),
      description: _string(json['description']),
      coverImageUrl: _versionedMediaUrl(
        json['cover_image_url'],
        json['updated_at'],
      ),
      workoutDays: _workoutDays(json['workout_days'], json['exercises']),
      exercises: _mapList(json['exercises']),
      publishStatus: _string(json['publish_status']),
      showInMobileApp: _bool(json['show_in_mobile_app']),
    );
  }
}

class MobileWorkoutDay {
  const MobileWorkoutDay({
    required this.dayNumber,
    required this.title,
    required this.notes,
    required this.exercises,
  });

  final int dayNumber;
  final String title;
  final String notes;
  final List<Map<String, dynamic>> exercises;

  factory MobileWorkoutDay.fromJson(
    Map<String, dynamic> json,
    int fallbackDay,
  ) {
    return MobileWorkoutDay(
      dayNumber: _int(json['day_number'], fallback: fallbackDay),
      title: _string(json['title'], fallback: 'Day $fallbackDay'),
      notes: _string(json['notes']),
      exercises: _mapList(json['exercises']),
    );
  }
}

class MobileExercise {
  const MobileExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.bodyPart,
    required this.equipment,
    required this.level,
    required this.duration,
    required this.sets,
    required this.reps,
    required this.restTime,
    required this.description,
    required this.imageUrl,
    required this.videoUrl,
    required this.instructions,
    required this.muscleTags,
    required this.publishStatus,
    required this.showInMobileApp,
  });

  final String id;
  final String name;
  final String category;
  final String bodyPart;
  final String equipment;
  final String level;
  final String duration;
  final String sets;
  final String reps;
  final String restTime;
  final String description;
  final String imageUrl;
  final String videoUrl;
  final List<String> instructions;
  final List<String> muscleTags;
  final String publishStatus;
  final bool showInMobileApp;

  bool get isPublishedMobile => publishStatus == 'Published' && showInMobileApp;

  int get setCount => _firstNumber(sets)?.round().clamp(1, 12) ?? 3;

  int get restSeconds {
    final value = _firstNumber(restTime);
    if (value == null) {
      return 45;
    }

    return restTime.toLowerCase().contains('min')
        ? (value * 60).round()
        : value.round();
  }

  int get targetReps => _firstNumber(reps)?.round() ?? 10;

  factory MobileExercise.fromJson(Map<String, dynamic> json) {
    return MobileExercise(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Exercise'),
      category: _string(json['category']),
      bodyPart: _string(json['body_part']),
      equipment: _string(json['equipment']),
      level: _string(json['workout_level'], fallback: 'All Levels'),
      duration: _duration(json['duration']),
      sets: _string(json['sets'], fallback: '3 Sets'),
      reps: _string(json['reps'], fallback: '8-12 Reps'),
      restTime: _duration(json['rest_time'], fallback: '45 sec'),
      description: _string(json['description']),
      imageUrl: _versionedMediaUrl(json['image_url'], json['updated_at']),
      videoUrl: _versionedMediaUrl(json['video_url'], json['updated_at']),
      instructions: _stringList(json['instructions']),
      muscleTags: _stringList(json['muscle_tags']),
      publishStatus: _string(json['publish_status']),
      showInMobileApp: _bool(json['show_in_mobile_app']),
    );
  }
}

class MobileEquipment {
  const MobileEquipment({
    required this.id,
    required this.name,
    required this.category,
    required this.primaryMuscleGroup,
    required this.supportedLevel,
    required this.publishStatus,
    required this.showInMobileApp,
  });

  final String id;
  final String name;
  final String category;
  final String primaryMuscleGroup;
  final String supportedLevel;
  final String publishStatus;
  final bool showInMobileApp;

  bool get isPublishedMobile => publishStatus == 'Published' && showInMobileApp;

  factory MobileEquipment.fromJson(Map<String, dynamic> json) {
    return MobileEquipment(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Equipment'),
      category: _string(json['category']),
      primaryMuscleGroup: _string(json['primary_muscle_group']),
      supportedLevel: _string(json['supported_level']),
      publishStatus: _string(json['publish_status']),
      showInMobileApp: _bool(json['show_in_mobile_app']),
    );
  }
}

class MobileWorkoutLevel {
  const MobileWorkoutLevel({
    required this.id,
    required this.name,
    required this.difficultyRank,
    required this.intensity,
    required this.coverImageUrl,
    required this.publishStatus,
    required this.showInMobileApp,
  });

  final String id;
  final String name;
  final int difficultyRank;
  final String intensity;
  final String coverImageUrl;
  final String publishStatus;
  final bool showInMobileApp;

  bool get isPublishedMobile => publishStatus == 'Published' && showInMobileApp;

  factory MobileWorkoutLevel.fromJson(Map<String, dynamic> json) {
    return MobileWorkoutLevel(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Level'),
      difficultyRank: int.tryParse(_string(json['difficulty_rank'])) ?? 0,
      intensity: _string(json['intensity']),
      coverImageUrl: _versionedMediaUrl(
        json['cover_image_url'],
        json['updated_at'],
      ),
      publishStatus: _string(json['publish_status']),
      showInMobileApp: _bool(json['show_in_mobile_app']),
    );
  }
}

class MobileAppBanner {
  const MobileAppBanner({
    required this.title,
    required this.subtitle,
    required this.bannerType,
    required this.publishStatus,
    required this.showInMobileApp,
    required this.imageUrl,
    required this.backgroundStyle,
    required this.backgroundColor,
    required this.accentColor,
    required this.startDate,
    required this.endDate,
  });

  final String title;
  final String subtitle;
  final String bannerType;
  final String publishStatus;
  final bool showInMobileApp;
  final String imageUrl;
  final String backgroundStyle;
  final String backgroundColor;
  final String accentColor;
  final DateTime? startDate;
  final DateTime? endDate;

  factory MobileAppBanner.fromJson(Map<String, dynamic> json) {
    return MobileAppBanner(
      title: _string(json['title']),
      subtitle: _string(json['subtitle']),
      bannerType: _string(json['banner_type']),
      publishStatus: _string(json['publish_status']),
      showInMobileApp: _bool(json['show_in_mobile_app']),
      imageUrl: _versionedMediaUrl(json['image_url'], json['updated_at']),
      backgroundStyle: _string(json['background_style']),
      backgroundColor: _string(json['background_color'], fallback: '#050505'),
      accentColor: _string(json['accent_color'], fallback: '#C8A13A'),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
    );
  }

  bool isVisibleHomeBanner(DateTime now) {
    if (bannerType != 'Home Banner' ||
        publishStatus != 'Published' ||
        !showInMobileApp) {
      return false;
    }

    final today = DateTime(now.year, now.month, now.day);
    if (startDate != null && startDate!.isAfter(today)) {
      return false;
    }

    if (endDate != null && endDate!.isBefore(today)) {
      return false;
    }

    return true;
  }
}

class MobileDietPlan {
  const MobileDietPlan({
    required this.id,
    required this.name,
    required this.goal,
    required this.level,
    required this.dietType,
    required this.dailyCalories,
    required this.duration,
    required this.description,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.meals,
    required this.mealInstructions,
    required this.nutritionistNotes,
    required this.coverImageUrl,
    required this.publishStatus,
    required this.showInMobileApp,
  });

  final String id;
  final String name;
  final String goal;
  final String level;
  final String dietType;
  final String dailyCalories;
  final String duration;
  final String description;
  final String protein;
  final String carbs;
  final String fat;
  final List<MobileDietMeal> meals;
  final String mealInstructions;
  final String nutritionistNotes;
  final String coverImageUrl;
  final String publishStatus;
  final bool showInMobileApp;

  bool get isPublishedMobile => publishStatus == 'Published' && showInMobileApp;

  int? get calorieTarget => _firstNumber(dailyCalories)?.round();
  int? get proteinTarget => _firstNumber(protein)?.round();
  int? get carbsTarget => _firstNumber(carbs)?.round();
  int? get fatTarget => _firstNumber(fat)?.round();

  factory MobileDietPlan.fromJson(Map<String, dynamic> json) {
    return MobileDietPlan(
      id: _string(json['id']),
      name: _string(json['name'], fallback: 'Diet Plan'),
      goal: _string(json['goal'], fallback: 'General Fitness'),
      level: _string(json['workout_level'], fallback: 'All Levels'),
      dietType: _string(json['diet_type']),
      dailyCalories: _string(json['daily_calories']),
      duration: _string(json['duration']),
      description: _string(json['description']),
      protein: _string(json['protein']),
      carbs: _string(json['carbs']),
      fat: _string(json['fat']),
      meals: _mapList(json['meals']).map(MobileDietMeal.fromJson).toList(),
      mealInstructions: _string(json['meal_instructions']),
      nutritionistNotes: _string(json['nutritionist_notes']),
      coverImageUrl: _versionedMediaUrl(
        json['cover_image_url'],
        json['updated_at'],
      ),
      publishStatus: _string(json['publish_status']),
      showInMobileApp: _bool(json['show_in_mobile_app']),
    );
  }
}

class MobileDietMeal {
  const MobileDietMeal({
    required this.name,
    required this.food,
    required this.calories,
  });

  final String name;
  final String food;
  final String calories;

  int? get calorieValue => _firstNumber(calories)?.round();

  factory MobileDietMeal.fromJson(Map<String, dynamic> json) {
    return MobileDietMeal(
      name: _string(json['name'], fallback: 'Meal'),
      food: _string(json['food']),
      calories: _string(json['calories']),
    );
  }
}

/// Resolves a media path from the API against the public site root.
String aurexMediaUrl(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) {
    return '';
  }

  final publicBase = aurexApiBaseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  if (raw.startsWith('/')) {
    return '$publicBase$raw';
  }

  final uri = Uri.tryParse(raw);
  if (uri == null || !uri.hasScheme) {
    return '$publicBase/$raw';
  }

  if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
    return '$publicBase${uri.path}';
  }

  return raw;
}

double? _firstNumber(String value) {
  final match = RegExp(r'\d+(\.\d+)?').firstMatch(value.replaceAll(',', ''));
  return match == null ? null : double.tryParse(match.group(0)!);
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String _duration(Object? value, {String fallback = ''}) {
  final text = _string(value);
  if (text.isEmpty) {
    return fallback;
  }

  return RegExp(r'[a-zA-Z]').hasMatch(text) ? text : '$text min';
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  return int.tryParse(_string(value)) ?? fallback;
}

String _date(Object? value) {
  final text = _string(value);
  if (text.length >= 10) {
    return text.substring(0, 10);
  }

  return text;
}

String _currency(Object? value, String currency) {
  final amount = _int(value);
  return '$currency ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
}

String _versionedMediaUrl(Object? value, Object? updatedAt) {
  final url = aurexMediaUrl(_string(value));
  final version = _string(updatedAt).replaceAll(RegExp(r'[^A-Za-z0-9]'), '');

  if (url.isEmpty || version.isEmpty) {
    return url;
  }

  final uri = Uri.tryParse(url);
  if (uri == null) {
    return url;
  }

  return uri
      .replace(queryParameters: {...uri.queryParameters, 'v': version})
      .toString();
}

bool _bool(Object? value) {
  return value == true || value == 1 || value == '1';
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }

  if (value is String && value.trim().isNotEmpty) {
    return [value.trim()];
  }

  return const [];
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  return const [];
}

List<MobileWorkoutDay> _workoutDays(Object? value, Object? legacyExercises) {
  final days = _mapList(value);
  if (days.isNotEmpty) {
    return [
      for (var index = 0; index < days.length; index++)
        MobileWorkoutDay.fromJson(days[index], index + 1),
    ];
  }

  final exercises = _mapList(legacyExercises);
  if (exercises.isEmpty) {
    return const [];
  }

  return [
    MobileWorkoutDay(
      dayNumber: 1,
      title: 'Day 1',
      notes: '',
      exercises: exercises,
    ),
  ];
}

DateTime? _parseDate(Object? value) {
  final text = _string(value);
  if (text.isEmpty) {
    return null;
  }

  final normalized = text.length >= 10 ? text.substring(0, 10) : text;
  return DateTime.tryParse(normalized);
}
