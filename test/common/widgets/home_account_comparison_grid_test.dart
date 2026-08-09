import 'package:clashkingapp/common/widgets/home_account_comparison_grid.dart';
import 'package:flutter/gestures.dart';
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

  testWidgets('caps a regular desktop row at summary plus two accounts', (
    tester,
  ) async {
    configureView(tester);
    await tester.pumpWidget(
      buildGrid(width: 1120, itemCount: 4, hasSummaryItem: true),
    );
    await tester.pumpAndSettle();

    final summary = tester.getRect(
      find.byKey(const ValueKey('comparison-item-0')),
    );
    final first = tester.getRect(
      find.byKey(const ValueKey('comparison-item-1')),
    );
    final second = tester.getRect(
      find.byKey(const ValueKey('comparison-item-2')),
    );
    expect(first.left, greaterThan(summary.right));
    expect(first.top, summary.top);
    expect(second.top, summary.top);
    expect(first.width, summary.width);
    expect(second.width, summary.width);
    expect(find.byKey(const ValueKey('home-comparison-next')), findsOneWidget);
  });

  testWidgets('uses the wider canvas to show every account', (tester) async {
    configureView(tester);
    tester.view.physicalSize = const Size(1800, 900);
    await tester.pumpWidget(
      buildGrid(width: 1560, itemCount: 4, hasSummaryItem: true),
    );
    await tester.pump();

    final summary = tester.getRect(
      find.byKey(const ValueKey('comparison-item-0')),
    );
    for (var index = 1; index < 4; index++) {
      final card = tester.getRect(
        find.byKey(ValueKey('comparison-item-$index')),
      );
      expect(card.width, summary.width);
      expect(card.top, summary.top);
    }
    expect(summary.width, 360);
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
      greaterThanOrEqualTo(summaryBefore.right),
    );
    expect(tester.getRect(previous).right, lessThanOrEqualTo(firstBefore.left));
    expect(tester.getRect(next).left, greaterThanOrEqualTo(secondBefore.right));
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

  testWidgets('claims wheel scrolling from the surrounding page', (
    tester,
  ) async {
    configureView(tester);
    final pageController = ScrollController();
    addTearDown(pageController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: pageController,
            child: Column(
              children: [
                SizedBox(
                  width: 920,
                  child: HomeAccountComparisonGrid(
                    itemCount: 5,
                    hasSummaryItem: true,
                    itemHeight: 100,
                    itemBuilder: (_, index) => ColoredBox(
                      key: ValueKey('comparison-item-$index'),
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final firstBefore = tester.getRect(
      find.byKey(const ValueKey('comparison-item-1')),
    );
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: firstBefore.center,
        scrollDelta: const Offset(0, 100),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();

    final firstAfter = tester.getRect(
      find.byKey(const ValueKey('comparison-item-1')),
    );
    expect(firstAfter.left, lessThan(firstBefore.left));
    expect(pageController.offset, 0);
  });

  testWidgets('lets the surrounding page scroll at both rail edges', (
    tester,
  ) async {
    configureView(tester);
    final pageController = ScrollController();
    addTearDown(pageController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            controller: pageController,
            child: Column(
              children: [
                const SizedBox(height: 200),
                SizedBox(
                  width: 920,
                  child: HomeAccountComparisonGrid(
                    itemCount: 5,
                    hasSummaryItem: true,
                    itemHeight: 100,
                    itemBuilder: (_, index) => ColoredBox(
                      key: ValueKey('comparison-item-$index'),
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    pageController.jumpTo(100);
    await tester.pump();
    var railCenter = tester.getCenter(
      find.byKey(const ValueKey('home-comparison-account-rail')),
    );
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: railCenter,
        scrollDelta: const Offset(0, -50),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();
    expect(pageController.offset, lessThan(100));

    pageController.jumpTo(0);
    await tester.pump();
    railCenter = tester.getCenter(
      find.byKey(const ValueKey('home-comparison-account-rail')),
    );
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: railCenter,
        scrollDelta: const Offset(0, 10000),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();
    expect(pageController.offset, 0);

    railCenter = tester.getCenter(
      find.byKey(const ValueKey('home-comparison-account-rail')),
    );
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: railCenter,
        scrollDelta: const Offset(0, 100),
        kind: PointerDeviceKind.mouse,
      ),
    );
    await tester.pump();
    expect(pageController.offset, greaterThan(0));
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
