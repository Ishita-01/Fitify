// Smoke test: the app builds and shows the main shell (onboarding skipped).

import 'package:flutter_test/flutter_test.dart';

import 'package:fitify/main.dart';

void main() {
  testWidgets('App launches into the main shell', (WidgetTester tester) async {
    await tester.pumpWidget(const FitifyApp());
    await tester.pump();

    // Bottom-nav labels are present.
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.text('Analyze'), findsWidgets);
  });
}
