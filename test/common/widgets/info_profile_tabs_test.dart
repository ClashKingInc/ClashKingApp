import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shared profile tabs report selection and keep icon labels', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InfoProfileTabs(
            selectedIndex: selected,
            onTabSelected: (value) => selected = value,
            tabs: const [
              InfoProfileTabData(label: 'Home', icon: Icons.home_rounded),
              InfoProfileTabData(label: 'Builder', icon: Icons.build_rounded),
              InfoProfileTabData(
                label: 'Collection',
                icon: Icons.collections_rounded,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Builder'), findsOneWidget);
    expect(find.text('Collection'), findsOneWidget);

    await tester.tap(find.text('Collection'));
    await tester.pumpAndSettle();
    expect(selected, 2);
  });
}
