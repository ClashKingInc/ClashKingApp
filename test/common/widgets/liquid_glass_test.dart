import 'package:clashkingapp/common/widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as glass;

void main() {
  testWidgets('glass bar always uses the Flutter compositor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            height: 56,
            child: LiquidGlassBar(height: 56),
          ),
        ),
      ),
    );

    expect(find.byType(glass.GlassContainer), findsOneWidget);
  });

  testWidgets('tab bar always uses liquid_glass_widgets', (tester) async {
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LiquidGlassTabBar(
            height: 64,
            itemCount: 2,
            selectedIndex: 0,
            onTabSelected: (index) => selected = index,
            items: const [
              LiquidGlassTabItem(icon: Icons.home, label: 'Home'),
              LiquidGlassTabItem(icon: Icons.person, label: 'Player'),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(glass.GlassTabBar), findsOneWidget);
    final tabBarBounds = tester.getRect(find.byType(glass.GlassTabBar));
    await tester.tapAt(
      Offset(
        tabBarBounds.left + tabBarBounds.width * 0.75,
        tabBarBounds.center.dy,
      ),
    );
    expect(selected, 1);
  });

  testWidgets('icon button always uses liquid_glass_widgets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiquidGlassIconButton(icon: Icons.person, onPressed: () {}),
        ),
      ),
    );

    expect(find.byType(glass.GlassIconButton), findsOneWidget);
  });

  testWidgets('app glass segmented control maps selections to values', (
    tester,
  ) async {
    var selected = 0;
    var callbackCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: AppGlassSegmentedControl<int>(
              values: const [0, 1],
              labels: const ['One', 'Two'],
              selected: selected,
              onChanged: (value) {
                selected = value;
                callbackCount++;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Two'));
    expect(selected, 1);
    expect(callbackCount, 1);
  });

  testWidgets('app glass segmented control keeps readable labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: AppGlassSegmentedControl<int>(
              values: const [0, 1],
              labels: const ['Linked', 'Bookmarked'],
              selected: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final style = tester
        .widget<AnimatedDefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Linked'),
                matching: find.byType(AnimatedDefaultTextStyle),
              )
              .first,
        )
        .style;

    expect(style.fontSize, 13);
  });

  testWidgets('app glass segmented control exposes stable semantic buttons', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: AppGlassSegmentedControl<int>(
                values: const [0, 1],
                labels: const ['Discord', 'Email'],
                selected: 0,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Discord'), findsOneWidget);
      expect(find.bySemanticsLabel('Email'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
  testWidgets('segmented control uses thin CK-style translucent capsules', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: AppGlassSegmentedControl<int>(
              values: const [0, 1],
              labels: const ['Players', 'Clans'],
              selected: 0,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(glass.GlassContainer), findsNothing);

    final trackFinder = find.byKey(const Key('app-glass-segmented-track'));
    final trackSize = tester.getSize(trackFinder);
    expect(trackSize.width, 328);
    expect(trackSize.height, 32);

    final track = tester.widget<DecoratedBox>(trackFinder);
    final decoration = track.decoration as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.top.width, 0.8);
    expect(border.top.color.a, greaterThan(0));
    expect(border.top.color.a, lessThan(0.4));
    expect(decoration.color!.a, closeTo(0.45, 0.01));

    final indicator = tester.widget<DecoratedBox>(
      find.byKey(const Key('app-glass-segmented-indicator')),
    );
    final indicatorDecoration = indicator.decoration as BoxDecoration;
    expect(indicatorDecoration.color!.a, closeTo(0.74, 0.01));
    expect(indicatorDecoration.border, isNull);
  });

  testWidgets('selection indicator slides through intermediate positions', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: StatefulBuilder(
              builder: (context, setState) => AppGlassSegmentedControl<int>(
                values: const [0, 1],
                labels: const ['Linked', 'Bookmarked'],
                selected: selected,
                onChanged: (value) {
                  setState(() => selected = value);
                },
              ),
            ),
          ),
        ),
      ),
    );

    final indicatorFinder = find.byKey(
      const Key('app-glass-segmented-indicator'),
    );
    final start = tester.getTopLeft(indicatorFinder).dx;

    await tester.tap(find.text('Bookmarked'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final middle = tester.getTopLeft(indicatorFinder).dx;

    await tester.pumpAndSettle();
    final end = tester.getTopLeft(indicatorFinder).dx;

    expect(middle, greaterThan(start + 1));
    expect(middle, lessThan(end - 1));
  });
}
