import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aurex/main.dart';
import 'package:aurex/login.dart';

void main() {
  testWidgets('verification validates code and enables resend after cooldown', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AurexEmailVerificationScreen(
          email: 'member@example.test',
          retryAfter: 2,
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
    await tester.pumpWidget(const AurexApp());
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
}
