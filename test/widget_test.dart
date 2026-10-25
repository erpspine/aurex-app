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
    if (request.url.path == '/api/login') {
      return http.Response(
        jsonEncode({
          'message': 'The provided credentials are incorrect.',
          'errors': {
            'email': ['The provided credentials are incorrect.'],
          },
        }),
        422,
      );
    }

    final body = switch (request.url.path) {
      '/api/me' || '/api/profile' => {
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

  testWidgets('a failed login shows an error toast that closes itself', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'member@example.test');
    await tester.enterText(fields.at(1), 'wrong-password');
    await tester.ensureVisible(find.text('LOGIN'));
    await tester.tap(find.text('LOGIN'));
    await tester.pumpAndSettle();

    expect(find.text('Login failed'), findsOneWidget);
    expect(
      find.text('The provided credentials are incorrect.'),
      findsOneWidget,
    );
    // The toast's icon, not the password field's.
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Login failed'),
          matching: find.byType(Row),
        ),
        matching: find.byIcon(Icons.lock_outline_rounded),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Login failed'), findsNothing);
  });

  testWidgets('edit profile sheet scrolls above the tab bar and saves', (
    tester,
  ) async {
    // Phone-sized screen (about 393 x 873 logical pixels).
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
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
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit Profile'));
    await tester.pumpAndSettle();
    expect(find.text('SAVE PROFILE'), findsOneWidget);

    final save = find.text('SAVE PROFILE');
    final sheetScroll = find
        .ancestor(of: save, matching: find.byType(Scrollable))
        .first;
    await tester.scrollUntilVisible(save, 300, scrollable: sheetScroll);
    await tester.pumpAndSettle();

    // The sheet sits above the tab bar, so the last fields and the button
    // are not covered and can be tapped.
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(tester.getBottomLeft(save).dy, lessThan(screenHeight));
    expect(find.text('Emergency Contact Phone'), findsOneWidget);
    await tester.tap(save); // warns (and the test fails) if covered
    await tester.pumpAndSettle();

    // The account has no phone yet: saving explains why and scrolls up.
    expect(find.text('Check your details'), findsOneWidget);
    expect(find.text('Phone is required'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone'),
      '0712 345 678',
    );
    await tester.scrollUntilVisible(save, 300, scrollable: sheetScroll);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('SAVE PROFILE'), findsNothing);
    expect(find.text('Profile updated'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
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
    expect(find.text('Enter your phone number'), findsOneWidget);
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(find.text('Confirm your password'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Test Member');
    await tester.enterText(fields.at(1), 'invalid');
    await tester.enterText(fields.at(2), '12ab');
    await tester.enterText(fields.at(3), 'password123');
    await tester.enterText(fields.at(4), 'different123');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(
      find.text('Enter a valid phone number, e.g. 0712 345 678'),
      findsOneWidget,
    );
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
