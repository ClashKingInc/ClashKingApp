import 'package:clashkingapp/common/widgets/home_account_comparison_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildGrid({
    required double width,
    required int itemCount,
    required bool hasSummaryItem,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: HomeAccountComparisonGrid(
              itemCount: itemCount,
              hasSummaryItem: hasSummaryItem,
              itemHeight: 100,
              itemBuilder: (_, index) => ColoredBox(
                key: ValueKey('comparison-item-$index'),
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void configureView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('keeps the summary beside same-sized account cards', (
    tester,
  ) async {
    configureView(tester);
    await tester.pumpWidget(
      buildGrid(width: 1120, itemCount: 4, hasSummaryItem: true),
    );
    await tester.pump();

    final summary = tester.getRect(
      find.byKey(const ValueKey('comparison-item-0')),
    );
    final first = tester.getRect(
      find.byKey(const ValueKey('comparison-item-1')),
    );
    final second = tester.getRect(
      find.byKey(const ValueKey('comparison-item-2')),
    );
    final third = tester.getRect(
      find.byKey(const ValueKey('comparison-item-3')),
    );

    expect(first.left, greaterThan(summary.right));
    expect(first.top, summary.top);
    expect(second.top, summary.top);
    expect(third.top, summary.top);
    expect(first.width, summary.width);
    expect(second.width, summary.width);
    expect(third.width, summary.width);
    expect(find.byKey(const ValueKey('home-comparison-next')), findsNothing);
  });

  testWidgets('pins the summary while account arrows move the rail', (
    tester,
  ) async {
    configureView(tester);
    await tester.pumpWidget(
      buildGrid(width: 920, itemCount: 5, hasSummaryItem: true),
    );
    await tester.pump();

    final summaryBefore = tester.getRect(
      find.byKey(const ValueKey('comparison-item-0')),
    );
    final firstBefore = tester.getRect(
      find.byKey(const ValueKey('comparison-item-1')),
    );
    final secondBefore = tester.getRect(
      find.byKey(const ValueKey('comparison-item-2')),
    );
    final next = find.byKey(const ValueKey('home-comparison-next'));
    final previous = find.byKey(const ValueKey('home-comparison-previous'));

    expect(next, findsOneWidget);
    expect(previous, findsOneWidget);
    expect(firstBefore.width, summaryBefore.width);
    expect(
      tester.getRect(previous).left,
      greaterThanOrEqualTo(secondBefore.right),
    );
    expect(tester.getRect(next).left, greaterThanOrEqualTo(secondBefore.right));
    expect(
      tester.getRect(previous).right,
      lessThanOrEqualTo(tester.getRect(next).left),
    );
    expect(
      tester
          .widget<IconButton>(
            find.descendant(of: previous, matching: find.byType(IconButton)),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(next);
    await tester.pumpAndSettle();

    final summaryAfter = tester.getRect(
      find.byKey(const ValueKey('comparison-item-0')),
    );
    final firstAfter = tester.getRect(
      find.byKey(const ValueKey('comparison-item-1')),
    );
    expect(summaryAfter, summaryBefore);
    expect(firstAfter.left, lessThan(firstBefore.left));
    expect(
      tester
          .widget<IconButton>(
            find.descendant(of: previous, matching: find.byType(IconButton)),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('bounds a lone account card instead of stretching it', (
    tester,
  ) async {
    configureView(tester);
    await tester.pumpWidget(
      buildGrid(width: 1120, itemCount: 1, hasSummaryItem: false),
    );

    final card = tester.getRect(
      find.byKey(const ValueKey('comparison-item-0')),
    );
    expect(card.left, 0);
    expect(card.width, 552);
  });
}
