import 'dart:convert';

import 'aurex_http.dart';
import 'login.dart';

class AurexApiException implements Exception {
  const AurexApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AurexApiClient {
  const AurexApiClient._();

  static Future<List<MobileWorkout>>? _workoutsCache;
  static Future<List<MobileExercise>>? _exercisesCache;
  static Future<List<MobileEquipment>>? _equipmentCache;
  static Future<List<MobileWorkoutLevel>>? _workoutLevelsCache;
  static Future<List<MobileAppBanner>>? _homeBannersCache;

  static Future<List<MobileWorkout>> fetchWorkouts({
    bool forceRefresh = false,
  }) {
    if (forceRefresh || _workoutsCache == null) {
      _workoutsCache = _fetchWorkouts().catchError((Object error) {
        _workoutsCache = null;
        throw error;
      });
    }

    return _workoutsCache!;
  }

  static Future<List<MobileExercise>> fetchExercises({
    bool forceRefresh = false,
  }) {
    if (forceRefresh || _exercisesCache == null) {
      _exercisesCache = _fetchExercises().catchError((Object error) {
        _exercisesCache = null;
        throw error;
      });
    }

    return _exercisesCache!;
  }

  static Future<List<MobileEquipment>> fetchEquipment({
    bool forceRefresh = false,
  }) {
    if (forceRefresh || _equipmentCache == null) {
      _equipmentCache = _fetchEquipment().catchError((Object error) {
        _equipmentCache = null;
        throw error;
      });
    }

    return _equipmentCache!;
  }

  static Future<List<MobileWorkoutLevel>> fetchWorkoutLevels({
    bool forceRefresh = false,
  }) {
    if (forceRefresh || _workoutLevelsCache == null) {
      _workoutLevelsCache = _fetchWorkoutLevels().catchError((Object error) {
        _workoutLevelsCache = null;
        throw error;
      });
    }

    return _workoutLevelsCache!;
  }

  static Future<List<MobileAppBanner>> fetchHomeBanners({
    bool forceRefresh = false,
  }) {
    if (forceRefresh || _homeBannersCache == null) {
      _homeBannersCache = _fetchHomeBanners().catchError((Object error) {
        _homeBannersCache = null;
        throw error;
      });
    }

    return _homeBannersCache!;
  }

  static Future<MobileProfile> fetchProfile() async {
    final payload = await _get('/me');
    return MobileProfile.fromPayload(payload);
  }

  static Future<MobileProfile> updateProfile(
    Map<String, dynamic> values,
  ) async {
    final payload = await _put('/profile', values);
    return MobileProfile.fromPayload(payload);
  }

  static Future<MobileProfile> uploadProfilePhoto(String filePath) async {
    try {
      final uri = Uri.parse('$aurexApiBaseUrl/profile/photo');
      final headers = <String, String>{'Accept': 'application/json'};

      final token = AurexSession.current?.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await aurexUploadFile(
        uri,
        headers: headers,
        fieldName: 'profile_photo',
        filePath: filePath,
      );
      final payload = _payloadFrom(response);

      if (response.statusCode == 401) {
        throw const AurexApiException('Your session has expired. Login again.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AurexApiException(
          _messageFrom(payload) ?? 'Unable to update profile photo.',
        );
      }

      return MobileProfile.fromPayload(payload);
    } on AurexNetworkException {
      throw const AurexApiException(
        'Unable to reach the AUREX server. Check your connection.',
      );
    } on FormatException {
      throw const AurexApiException('The server returned an invalid response.');
    }
  }

  static Future<List<Map<String, dynamic>>> _getList(
    String path,
    String listKey,
  ) async {
    final payload = await _get(path);
    final value = payload[listKey];

    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw const AurexApiException('The server returned an invalid response.');
  }

  static Future<List<MobileWorkout>> _fetchWorkouts() async {
    final items = await _getList('/workouts', 'workouts');
    return items.map(MobileWorkout.fromJson).toList();
  }

  static Future<List<MobileExercise>> _fetchExercises() async {
    final items = await _getList('/exercises', 'exercises');
    return items.map(MobileExercise.fromJson).toList();
  }

  static Future<List<MobileEquipment>> _fetchEquipment() async {
    final items = await _getList('/equipment', 'equipment');
    return items.map(MobileEquipment.fromJson).toList();
  }

  static Future<List<MobileWorkoutLevel>> _fetchWorkoutLevels() async {
    final items = await _getList('/workout-levels', 'workout_levels');
    return items.map(MobileWorkoutLevel.fromJson).toList();
  }

  static Future<List<MobileAppBanner>> _fetchHomeBanners() async {
    final items = await _getList('/mobile-app', 'banners');
    final now = DateTime.now();
    return items
        .map(MobileAppBanner.fromJson)
        .where((banner) => banner.isVisibleHomeBanner(now))
        .toList();
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    try {
      final uri = Uri.parse('$aurexApiBaseUrl$path');
      final headers = <String, String>{'Accept': 'application/json'};

      final token = AurexSession.current?.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await aurexGet(uri, headers: headers);
      final responseBody = response.body;
      final payload = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 401) {
        throw const AurexApiException('Your session has expired. Login again.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AurexApiException(
          payload['message']?.toString() ?? 'Unable to load data.',
        );
      }

      return payload;
    } on AurexNetworkException {
      throw const AurexApiException(
        'Unable to reach the AUREX server. Check your connection.',
      );
    } on FormatException {
      throw const AurexApiException('The server returned an invalid response.');
    }
  }

  static Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> values,
  ) async {
    try {
      final uri = Uri.parse('$aurexApiBaseUrl$path');
      final headers = <String, String>{'Accept': 'application/json'};

      final token = AurexSession.current?.token;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await aurexPutJson(
        uri,
        headers: headers,
        body: jsonEncode(values),
      );
      final payload = _payloadFrom(response);

      if (response.statusCode == 401) {
        throw const AurexApiException('Your session has expired. Login again.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AurexApiException(
          _messageFrom(payload) ?? 'Unable to save profile.',
        );
      }

      return payload;
    } on AurexNetworkException {
      throw const AurexApiException(
        'Unable to reach the AUREX server. Check your connection.',
      );
    } on FormatException {
      throw const AurexApiException('The server returned an invalid response.');
    }
  }

  static Map<String, dynamic> _payloadFrom(AurexHttpResponse response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      throw const FormatException();
    }

    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw const FormatException();
  }

  static String? _messageFrom(Map<String, dynamic> payload) {
    final errors = payload['errors'];

    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;

      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }

    return payload['message']?.toString();
  }

  static String mediaUrl(String? value) {
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
  String get profilePhotoUrl =>
      AurexApiClient.mediaUrl(_string(user['profile_photo_path']));

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
  final List<Map<String, dynamic>> exercises;
  final String publishStatus;
  final bool showInMobileApp;

  int get exerciseCount => exercises.length;
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
      exercises: _mapList(json['exercises']),
      publishStatus: _string(json['publish_status']),
      showInMobileApp: _bool(json['show_in_mobile_app']),
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

String _date(Object? value) {
  final text = _string(value);
  if (text.length >= 10) {
    return text.substring(0, 10);
  }

  return text;
}

String _versionedMediaUrl(Object? value, Object? updatedAt) {
  final url = AurexApiClient.mediaUrl(_string(value));
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

DateTime? _parseDate(Object? value) {
  final text = _string(value);
  if (text.isEmpty) {
    return null;
  }

  final normalized = text.length >= 10 ? text.substring(0, 10) : text;
  return DateTime.tryParse(normalized);
}
