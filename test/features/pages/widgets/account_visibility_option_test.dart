import 'package:clashkingapp/features/pages/widgets/account_visibility_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget subject({
    required bool hidden,
    required bool verified,
    required VoidCallback onPressed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: AccountVisibilityOption(
          hidden: hidden,
          verified: verified,
          updating: false,
          onPressed: onPressed,
        ),
      ),
    );
  }

  testWidgets('shows an off toggle state for a visible verified link', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      subject(hidden: false, verified: true, onPressed: () => pressed = true),
    );

    expect(find.text('Hide account'), findsOneWidget);
    expect(
      find.text('This account is visible in public lookups.'),
      findsOneWidget,
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.byType(Switch));
    expect(pressed, isTrue);
  });

  testWidgets('shows an enabled toggle state for a hidden verified link', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(hidden: true, verified: true, onPressed: () {}),
    );

    expect(find.text('Hide account'), findsOneWidget);
    expect(
      find.text('This account is hidden from public lookups.'),
      findsOneWidget,
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('disables visibility changes for an unverified link', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(
      subject(hidden: false, verified: false, onPressed: () => pressed = true),
    );

    expect(
      find.text('Verify this account to change visibility.'),
      findsOneWidget,
    );
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    await tester.tap(find.text('Hide account'));
    expect(pressed, isFalse);
  });
}
