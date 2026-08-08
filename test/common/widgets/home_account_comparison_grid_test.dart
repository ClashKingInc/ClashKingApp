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

  testWidgets('shows a full-width summary above three account columns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      buildGrid(width: 1120, itemCount: 4, hasSummaryItem: true),
    );

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

    expect(summary.width, 1120);
    expect(first.top, greaterThan(summary.bottom));
    expect(first.top, second.top);
    expect(second.top, third.top);
    expect(first.width, closeTo((1120 - 24) / 3, 0.01));
  });

  testWidgets('bounds a lone account card instead of stretching it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
