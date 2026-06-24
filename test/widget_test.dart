import 'package:flutter_test/flutter_test.dart';

import 'package:aurex/main.dart';

void main() {
  testWidgets('shows Aurex login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AurexApp());

    expect(find.text('Login to continue your fitness journey'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('demo@aurex.com'), findsOneWidget);
    expect(find.text('password123'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
  });
}
