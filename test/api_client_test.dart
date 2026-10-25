import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:aurex/api_client.dart';

AurexApiClient _client(
  MockClientHandler handler, {
  String? token,
  void Function()? onUnauthorized,
}) {
  return AurexApiClient(
    httpClient: MockClient(handler),
    token: token,
    onUnauthorized: onUnauthorized,
    baseUrl: 'https://api.test/api',
  );
}

void main() {
  test('login returns a session from the token payload', () async {
    final api = _client((request) async {
      expect(request.url.toString(), 'https://api.test/api/login');
      expect(jsonDecode(request.body), {
        'email': 'member@example.test',
        'password': 'secret',
      });
      return http.Response(
        jsonEncode({
          'token': 'abc',
          'user': {'id': 7, 'role': 'Member'},
          'member': {'full_name': 'Ama'},
        }),
        200,
      );
    });

    final session = await api.login(
      email: 'member@example.test',
      password: 'secret',
    );

    expect(session.token, 'abc');
    expect(session.isMember, isTrue);
    expect(session.member?['full_name'], 'Ama');
  });

  test('validation errors surface the first field message', () async {
    final api = _client(
      (request) async => http.Response(
        jsonEncode({
          'message': 'The given data was invalid.',
          'errors': {
            'email': ['These credentials do not match our records.'],
          },
        }),
        422,
      ),
    );

    await expectLater(
      api.login(email: 'a@b.c', password: 'x'),
      throwsA(
        isA<AurexApiException>().having(
          (e) => e.message,
          'message',
          'These credentials do not match our records.',
        ),
      ),
    );
  });

  test('unverified login reports verification details', () async {
    final api = _client(
      (request) async => http.Response(
        jsonEncode({
          'message': 'Verify your email before logging in.',
          'verification_required': true,
          'retry_after': 42,
        }),
        403,
      ),
    );

    await expectLater(
      api.login(email: 'a@b.c', password: 'x'),
      throwsA(
        isA<AurexApiException>()
            .having((e) => e.verificationRequired, 'verification', isTrue)
            .having((e) => e.retryAfter, 'retryAfter', 42),
      ),
    );
  });

  test('authenticated 401 expires the session', () async {
    var expired = false;
    final api = _client(
      (request) async {
        expect(request.headers['Authorization'], 'Bearer old-token');
        return http.Response('{"message":"Session expired."}', 401);
      },
      token: 'old-token',
      onUnauthorized: () => expired = true,
    );

    await expectLater(
      api.fetchProfile(),
      throwsA(
        isA<AurexApiException>().having((e) => e.isUnauthorized, '401', isTrue),
      ),
    );
    expect(expired, isTrue);
  });

  test('server errors without JSON get a readable message', () async {
    final api = _client(
      (request) async => http.Response('<html>Bad gateway</html>', 502),
    );

    await expectLater(
      api.fetchWorkouts(),
      throwsA(
        isA<AurexApiException>().having(
          (e) => e.message,
          'message',
          'Server error 502. Please contact support.',
        ),
      ),
    );
  });

  test('network failures map to a connection message', () async {
    final api = _client(
      (request) async => throw http.ClientException('XMLHttpRequest error.'),
    );

    await expectLater(
      api.fetchExercises(),
      throwsA(
        isA<AurexApiException>().having(
          (e) => e.message,
          'message',
          contains('Unable to reach the AUREX server'),
        ),
      ),
    );
  });

  test('home banners come from /app-banners and are filtered', () async {
    final api = _client((request) async {
      expect(request.url.path, '/api/app-banners');
      return http.Response(
        jsonEncode({
          'app_banners': [
            {
              'title': 'Visible',
              'banner_type': 'Home Banner',
              'publish_status': 'Published',
              'show_in_mobile_app': true,
            },
            {
              'title': 'Draft',
              'banner_type': 'Home Banner',
              'publish_status': 'Draft',
              'show_in_mobile_app': true,
            },
            {
              'title': 'Expired',
              'banner_type': 'Home Banner',
              'publish_status': 'Published',
              'show_in_mobile_app': 1,
              'end_date': '2001-01-01',
            },
          ],
        }),
        200,
      );
    });

    final banners = await api.fetchHomeBanners();
    expect(banners.map((b) => b.title), ['Visible']);
  });

  test('profile photo uploads raw bytes as multipart (works on web)', () async {
    final api = _client((request) async {
      expect(request.url.path, '/api/profile/photo');
      expect(
        request.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      expect(request.headers['Authorization'], 'Bearer t');
      final body = utf8.decode(request.bodyBytes, allowMalformed: true);
      expect(body, contains('name="profile_photo"; filename="me.png"'));
      return http.Response(
        jsonEncode({
          'user': {'profile_photo_path': '/storage/me.png'},
          'member': {'full_name': 'Ama'},
        }),
        200,
      );
    }, token: 't');

    final profile = await api.uploadProfilePhoto(
      bytes: Uint8List.fromList([1, 2, 3]),
      fileName: 'me.png',
    );

    expect(profile.fullName, 'Ama');
    expect(profile.profilePhotoUrl, endsWith('/storage/me.png'));
  });
}
