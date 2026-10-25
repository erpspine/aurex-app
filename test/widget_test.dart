import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aurex/login.dart';
import 'package:aurex/main.dart';
import 'package:aurex/profile.dart';
import 'package:aurex/providers.dart';

/// Fake API: an empty catalogue plus a member profile.
http.Client _fakeApi() {
  return MockClient((request) async {
    final body = switch (request.url.path) {
      '/api/me' => {
        'user': {
          'id': 1,
          'name': 'Test Member',
          'email': 'member@example.test',
        },
        'member': {
          'full_name': 'Test Member',
          'email': 'member@example.test',
          'workout_level': 'Intermediate',
          'height_cm': 180,
          'weight_kg': 81,
        },
      },
      '/api/logout' => {'message': 'Logged out successfully.'},
      '/api/workouts' => {'workouts': []},
      '/api/exercises' => {'exercises': []},
      '/api/equipment' => {'equipment': []},
      '/api/workout-levels' => {'workout_levels': []},
      '/api/app-banners' => {'app_banners': []},
      '/api/diet-plans' => {'diet_plans': []},
      '/api/activity/workouts' => {'workout_logs': []},
      '/api/activity/food' => {'food_entries': []},
      '/api/activity/water' => {'water_logs': []},
      '/api/activity/diet-preferences' => {
        'diet_preferences': {'calorie_goal': null, 'diet_plan_id': null},
      },
      _ => null,
    };

    return body == null
        ? http.Response('{"message":"Not found"}', 404)
        : http.Response(jsonEncode(body), 200);
  });
}

Widget _app({Map<String, String> secureStorage = const {}}) {
  FlutterSecureStorage.setMockInitialValues({...secureStorage});

  return ProviderScope(
    overrides: [
      cookieAuthProvider.overrideWithValue(false),
      httpClientProvider.overrideWithValue(_fakeApi()),
    ],
    retry: (retryCount, error) => null,
    child: const AurexApp(),
  );
}

void main() {
  test('legacy localStorage token and activity are deleted', () async {
    SharedPreferences.setMockInitialValues({
      'aurex.session': '{"token":"leaked"}',
      'aurex.food_log.1': '[]',
      'unrelated': 'kept',
    });

    await removeLegacyLocalData();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), {'unrelated'});
  });

  testWidgets('verification validates code and enables resend after cooldown', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AurexEmailVerificationScreen(
            email: 'member@example.test',
            retryAfter: 2,
          ),
        ),
      ),
    );
    expect(find.textContaining('member@example.test'), findsOneWidget);
    final resend = find.widgetWithText(TextButton, 'Resend code in 2s');
    expect(tester.widget<TextButton>(resend).onPressed, isNull);
    await tester.tap(find.text('VERIFY EMAIL'));
    await tester.pump();
    expect(find.text('Enter the six-digit code'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'ab123');
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      '123',
    );
    await tester.pump(const Duration(seconds: 2));
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Resend code'))
          .onPressed,
      isNotNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('opens signup without social providers and validates fields', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
    for (final provider in [
      'Google',
      'Apple',
      'Facebook',
      'OR CONTINUE WITH',
    ]) {
      expect(find.text(provider), findsNothing);
    }
    final signup = find.textContaining(
      "Don't have an account?",
      findRichText: true,
    );
    await tester.ensureVisible(signup);
    await tester.tap(signup);
    await tester.pumpAndSettle();
    expect(find.text('Create Account'), findsOneWidget);
    final submit = find.text('SIGN UP');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter your email address'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('Confirm your password'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Test Member');
    await tester.enterText(fields.at(1), 'invalid');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'different123');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    final login = find.text('Already have an account? Login');
    await tester.ensureVisible(login);
    await tester.tap(login);
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('restores a saved session, shows the profile and logs out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        secureStorage: {
          'aurex.session': jsonEncode({
            'token': 'saved-token',
            'user': {'id': 1, 'name': 'Test Member', 'role': 'Member'},
          }),
        },
      ),
    );
    await tester.pumpAndSettle();

    // Signed in: the home tab and the five-tab navigation are shown.
    expect(find.text('LOGIN'), findsNothing);
    expect(find.text('BODY PART EXERCISES'), findsOneWidget);
    for (final tab in ['Home', 'Workouts', 'Diet', 'Progress', 'Profile']) {
      expect(find.text(tab), findsOneWidget);
    }

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Test Member'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);

    final logout = find.text('Log Out');
    final scrollable = find
        .descendant(
          of: find.byType(ProfilePage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(logout, 300, scrollable: scrollable);
    // Scroll it clear of the floating navigation bar.
    await tester.drag(scrollable, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(logout);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Log Out'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget);
    expect(
      await const FlutterSecureStorage().read(key: 'aurex.session'),
      isNull,
    );
  });
}
