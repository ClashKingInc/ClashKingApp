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

  testWidgets('segmented control remains interactive without native views', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: LiquidGlassSegmentedControl<int>(
              values: const [0, 1],
              labels: const ['One', 'Two'],
              selected: selected,
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Two'));
    expect(selected, 1);
  });

  testWidgets('segmented control keeps readable labels on non-iOS platforms', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: LiquidGlassSegmentedControl<int>(
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

    expect(style.fontSize, 14);
  });
}
