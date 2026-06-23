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

  static Future<List<MobileWorkout>> fetchWorkouts() async {
    final items = await _getList('/workouts', 'workouts');
    return items.map(MobileWorkout.fromJson).toList();
  }

  static Future<List<MobileExercise>> fetchExercises() async {
    final items = await _getList('/exercises', 'exercises');
    return items.map(MobileExercise.fromJson).toList();
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

  int get exerciseCount => exercises.length;

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
      coverImageUrl: AurexApiClient.mediaUrl(_string(json['cover_image_url'])),
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
      imageUrl: AurexApiClient.mediaUrl(_string(json['image_url'])),
      videoUrl: AurexApiClient.mediaUrl(_string(json['video_url'])),
      instructions: _stringList(json['instructions']),
      muscleTags: _stringList(json['muscle_tags']),
    );
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
