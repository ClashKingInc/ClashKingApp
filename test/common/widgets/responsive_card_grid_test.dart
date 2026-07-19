import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpGrid(WidgetTester tester, double width) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResponsiveCardGrid(
            itemCount: 4,
            itemBuilder: (context, index) =>
                SizedBox(key: ValueKey('card-$index'), height: 100),
          ),
        ),
      ),
    );
  }

  testWidgets('uses two columns on a standard desktop width', (tester) async {
    await pumpGrid(tester, 1000);

    final first = tester.getRect(find.byKey(const ValueKey('card-0')));
    final second = tester.getRect(find.byKey(const ValueKey('card-1')));
    final third = tester.getRect(find.byKey(const ValueKey('card-2')));

    expect(second.top, first.top);
    expect(second.left, greaterThan(first.left));
    expect(third.left, first.left);
    expect(third.top, greaterThan(first.top));
  });

  testWidgets('uses three columns when cards keep their minimum width', (
    tester,
  ) async {
    await pumpGrid(tester, 1400);

    final first = tester.getRect(find.byKey(const ValueKey('card-0')));
    final third = tester.getRect(find.byKey(const ValueKey('card-2')));
    final fourth = tester.getRect(find.byKey(const ValueKey('card-3')));

    expect(third.top, first.top);
    expect(third.left, greaterThan(first.left));
    expect(fourth.left, first.left);
    expect(fourth.top, greaterThan(first.top));
  });
}
