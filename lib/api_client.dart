import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'activity.dart';
import 'config.dart';
import 'models.dart';

class AurexApiException implements Exception {
  const AurexApiException(
    this.message, {
    this.statusCode = 0,
    this.verificationRequired = false,
    this.retryAfter = 0,
  });

  final String message;
  final int statusCode;
  final bool verificationRequired;
  final int retryAfter;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin wrapper over the AUREX REST API. Works on mobile, desktop and web
/// because it only uses `package:http`.
class AurexApiClient {
  AurexApiClient({
    required http.Client httpClient,
    this.token,
    this.cookieAuth = false,
    this.onUnauthorized,
    this.baseUrl = aurexApiBaseUrl,
  }) : _http = httpClient;

  final http.Client _http;
  final String? token;
  final String baseUrl;

  /// Browser mode: the server keeps the token in an HttpOnly cookie, so the
  /// app never sees or stores it. Requires an `httpClient` that sends
  /// credentials (see `http_client_web.dart`).
  final bool cookieAuth;

  /// Called when an authenticated request is rejected with 401.
  final void Function()? onUnauthorized;

  static const _timeout = Duration(seconds: 30);

  // ---------------------------------------------------------------- auth

  Future<AurexSession> login({
    required String email,
    required String password,
  }) async {
    final payload = await _send(
      'POST',
      '/login',
      body: {'email': email, 'password': password},
    );

    final session = AurexSession.fromJson(payload);
    if (session == null || (!cookieAuth && session.token == null)) {
      throw const AurexApiException(
        'The server returned an incomplete login response.',
      );
    }

    return session;
  }

  /// The signed-in user, used on the web to check whether the auth cookie is
  /// still valid when the app starts.
  Future<AurexSession> fetchSession() async {
    final payload = await _send('GET', '/me');
    final session = AurexSession.fromJson(payload);
    if (session == null) {
      throw const AurexApiException('The server returned an invalid response.');
    }

    return AurexSession(
      token: token,
      user: session.user,
      member: session.member,
    );
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) => _send(
    'POST',
    '/register',
    body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': confirmation,
    },
  );

  Future<Map<String, dynamic>> verifyEmail(String email, String code) =>
      _send('POST', '/email/verify', body: {'email': email, 'code': code});

  Future<Map<String, dynamic>> resendCode(String email) =>
      _send('POST', '/email/resend', body: {'email': email});

  Future<Map<String, dynamic>> forgotPassword(String email) =>
      _send('POST', '/password/forgot', body: {'email': email});

  Future<Map<String, dynamic>> verifyPasswordCode(String email, String code) =>
      _send('POST', '/password/verify', body: {'email': email, 'code': code});

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String resetToken,
    String password,
    String confirmation,
  ) => _send(
    'POST',
    '/password/reset',
    body: {
      'email': email,
      'reset_token': resetToken,
      'password': password,
      'password_confirmation': confirmation,
    },
  );

  Future<void> logout() async {
    await _send('POST', '/logout', body: const {});
  }

  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String confirmation,
  }) async {
    await _send(
      'POST',
      '/change-password',
      body: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': confirmation,
      },
      fallbackMessage: 'Unable to change password.',
    );
  }

  // ------------------------------------------------------------- profile

  Future<MobileProfile> fetchProfile() async {
    return MobileProfile.fromPayload(await _send('GET', '/me'));
  }

  Future<MobileProfile> updateProfile(Map<String, dynamic> values) async {
    final payload = await _send(
      'PUT',
      '/profile',
      body: values,
      fallbackMessage: 'Unable to save profile.',
    );
    return MobileProfile.fromPayload(payload);
  }

  Future<MobileProfile> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/profile/photo'))
      ..headers.addAll(_headers())
      ..files.add(
        http.MultipartFile.fromBytes(
          'profile_photo',
          bytes,
          filename: fileName.isEmpty ? 'profile-photo.jpg' : fileName,
        ),
      );

    final payload = await _guard(() async {
      final streamed = await _http.send(request).timeout(_timeout);
      return http.Response.fromStream(streamed);
    }, fallbackMessage: 'Unable to update profile photo.');

    return MobileProfile.fromPayload(payload);
  }

  // ------------------------------------------------------------- catalogue

  Future<List<MobileWorkout>> fetchWorkouts() async {
    final items = await _getList('/workouts', 'workouts');
    return items.map(MobileWorkout.fromJson).toList();
  }

  Future<List<MobileExercise>> fetchExercises() async {
    final items = await _getList('/exercises', 'exercises');
    return items.map(MobileExercise.fromJson).toList();
  }

  Future<List<MobileEquipment>> fetchEquipment() async {
    final items = await _getList('/equipment', 'equipment');
    return items.map(MobileEquipment.fromJson).toList();
  }

  Future<List<MobileWorkoutLevel>> fetchWorkoutLevels() async {
    final items = await _getList('/workout-levels', 'workout_levels');
    return items.map(MobileWorkoutLevel.fromJson).toList();
  }

  Future<List<MobileAppBanner>> fetchHomeBanners() async {
    final items = await _getList('/app-banners', 'app_banners');
    final now = DateTime.now();
    return items
        .map(MobileAppBanner.fromJson)
        .where((banner) => banner.isVisibleHomeBanner(now))
        .toList();
  }

  Future<List<MobileDietPlan>> fetchDietPlans() async {
    final items = await _getList('/diet-plans', 'diet_plans');
    return items.map(MobileDietPlan.fromJson).toList();
  }

  // -------------------------------------------------------------- activity

  Future<List<WorkoutLogEntry>> fetchWorkoutLogs() async {
    final items = await _getList('/activity/workouts', 'workout_logs');
    return items
        .map(WorkoutLogEntry.fromJson)
        .whereType<WorkoutLogEntry>()
        .toList();
  }

  /// Saves a finished session. [entry]'s id is sent as the client id so a
  /// retried request does not create a duplicate.
  Future<WorkoutLogEntry> createWorkoutLog(WorkoutLogEntry entry) async {
    final payload = await _send(
      'POST',
      '/activity/workouts',
      body: {
        ...entry.toJson()..remove('id'),
        'client_id': entry.id,
        'completed_at': entry.completedAt.toUtc().toIso8601String(),
      },
      fallbackMessage: 'Unable to save the workout.',
    );
    return _required(WorkoutLogEntry.fromJson(_map(payload['workout_log'])));
  }

  Future<List<FoodEntry>> fetchFoodEntries() async {
    final items = await _getList('/activity/food', 'food_entries');
    return items.map(FoodEntry.fromJson).toList();
  }

  Future<FoodEntry> createFoodEntry(FoodEntry entry) async {
    final payload = await _send(
      'POST',
      '/activity/food',
      body: {...entry.toJson()..remove('id'), 'client_id': entry.id},
      fallbackMessage: 'Unable to add the food.',
    );
    return FoodEntry.fromJson(_map(payload['food_entry']));
  }

  Future<void> deleteFoodEntry(String id) async {
    await _send(
      'DELETE',
      '/activity/food/${Uri.encodeComponent(id)}',
      fallbackMessage: 'Unable to remove the food.',
    );
  }

  /// Cups of water per `yyyy-mm-dd` day.
  Future<Map<String, int>> fetchWaterLogs() async {
    final items = await _getList('/activity/water', 'water_logs');
    return {
      for (final item in items)
        '${item['date']}': (item['cups'] as num?)?.toInt() ?? 0,
    };
  }

  Future<void> saveWater(String day, int cups) async {
    await _send(
      'PUT',
      '/activity/water/$day',
      body: {'cups': cups},
      fallbackMessage: 'Unable to save water intake.',
    );
  }

  Future<({int? calorieGoal, String? planId})> fetchDietPreferences() async {
    final payload = await _send('GET', '/activity/diet-preferences');
    return _preferences(payload);
  }

  Future<({int? calorieGoal, String? planId})> saveDietPreferences({
    int? calorieGoal,
    String? planId,
  }) async {
    final payload = await _send(
      'PUT',
      '/activity/diet-preferences',
      body: {'calorie_goal': calorieGoal, 'diet_plan_id': planId},
      fallbackMessage: 'Unable to save diet preferences.',
    );
    return _preferences(payload);
  }

  static ({int? calorieGoal, String? planId}) _preferences(
    Map<String, dynamic> payload,
  ) {
    final data = _map(payload['diet_preferences']);
    return (
      calorieGoal: (data['calorie_goal'] as num?)?.toInt(),
      planId: data['diet_plan_id'] as String?,
    );
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw const AurexApiException('The server returned an invalid response.');
  }

  static T _required<T>(T? value) {
    if (value == null) {
      throw const AurexApiException('The server returned an invalid response.');
    }
    return value;
  }

  // ------------------------------------------------------------- plumbing

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({bool json = false}) {
    return {
      'Accept': 'application/json',
      if (json) 'Content-Type': 'application/json',
      if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      if (cookieAuth) ...{
        'X-Aurex-Auth': 'cookie',
        // Required by the API for cookie-authenticated requests (CSRF guard).
        'X-Requested-With': 'XMLHttpRequest',
      },
    };
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path,
    String listKey,
  ) async {
    final payload = await _send('GET', path);
    final value = payload[listKey];

    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw const AurexApiException('The server returned an invalid response.');
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String fallbackMessage = 'Unable to complete the request.',
  }) {
    return _guard(() {
      final uri = _uri(path);
      final headers = _headers(json: body != null);
      final encoded = body == null ? null : jsonEncode(body);

      final future = switch (method) {
        'POST' => _http.post(uri, headers: headers, body: encoded),
        'PUT' => _http.put(uri, headers: headers, body: encoded),
        'DELETE' => _http.delete(uri, headers: headers),
        _ => _http.get(uri, headers: headers),
      };
      return future.timeout(_timeout);
    }, fallbackMessage: fallbackMessage);
  }

  Future<Map<String, dynamic>> _guard(
    Future<http.Response> Function() request, {
    required String fallbackMessage,
  }) async {
    final http.Response response;
    try {
      response = await request();
    } on TimeoutException {
      throw const AurexApiException('The request timed out. Please try again.');
    } on http.ClientException {
      throw const AurexApiException(
        'Unable to reach the AUREX server. Check your connection.',
      );
    }

    final status = response.statusCode;
    final payload = _decode(response);

    if (status >= 200 && status < 300) {
      if (payload == null) {
        throw const AurexApiException(
          'The server returned an invalid response.',
        );
      }
      return payload;
    }

    if (status == 401 && (token != null || cookieAuth)) {
      onUnauthorized?.call();
      throw const AurexApiException(
        'Your session has expired. Please log in again.',
        statusCode: 401,
      );
    }

    if (payload == null) {
      throw AurexApiException(
        status >= 500
            ? 'Server error $status. Please contact support.'
            : fallbackMessage,
        statusCode: status,
      );
    }

    throw AurexApiException(
      _messageFrom(payload) ?? fallbackMessage,
      statusCode: status,
      verificationRequired: payload['verification_required'] == true,
      retryAfter: payload['retry_after'] is int
          ? payload['retry_after'] as int
          : 0,
    );
  }

  static Map<String, dynamic>? _decode(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(body);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
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
}
