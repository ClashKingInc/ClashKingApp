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

  testWidgets('shared controller keeps the indicator tied to a page swipe', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _SharedTabsHarness()));

    final state = tester.state<_SharedTabsHarnessState>(
      find.byType(_SharedTabsHarness),
    );
    expect(state.controller.animation!.value, 0);

    await tester.fling(find.byType(TabBarView), const Offset(-600, 0), 1200);
    await tester.pumpAndSettle();

    expect(state.controller.index, 1);
    expect(state.controller.animation!.value, 1);
    expect(find.text('Second page'), findsOneWidget);
  });

  testWidgets('nested profile pages stay rendered while swiping', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _NestedTabsHarness()));

    await tester.fling(find.byType(TabBarView), const Offset(-600, 0), 1200);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Second nested page'), findsOneWidget);
  });

  testWidgets(
    'pinned profile tabs stay hidden before reaching the scroll edge',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PinnedInfoProfileTabs(
              selectedIndex: 0,
              onTabSelected: _ignoreSelection,
              progress: 0,
              tabs: [
                InfoProfileTabData(label: 'Home', icon: Icons.home_rounded),
                InfoProfileTabData(
                  label: 'History',
                  icon: Icons.history_rounded,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
    },
  );

  testWidgets(
    'pinned profile tabs honor the safe area and remain interactive',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(top: 47),
            ),
            child: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: PinnedInfoProfileTabs(
                  selectedIndex: selected,
                  onTabSelected: (value) => selected = value,
                  progress: 1,
                  tabs: const [
                    InfoProfileTabData(label: 'Home', icon: Icons.home_rounded),
                    InfoProfileTabData(
                      label: 'History',
                      icon: Icons.history_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final overlay = tester.getSize(find.byType(PinnedInfoProfileTabs));
      expect(overlay.height, 47 + PinnedInfoProfileTabs.tabHeight);
      expect(find.byType(BackdropFilter), findsOneWidget);

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(selected, 1);
    },
  );
}

void _ignoreSelection(int _) {}

class _SharedTabsHarness extends StatefulWidget {
  const _SharedTabsHarness();

  @override
  State<_SharedTabsHarness> createState() => _SharedTabsHarnessState();
}

class _SharedTabsHarnessState extends State<_SharedTabsHarness>
    with SingleTickerProviderStateMixin {
  late final TabController controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this)
      ..addListener(_rebuildAtRest);
  }

  void _rebuildAtRest() {
    if (!controller.indexIsChanging && mounted) setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(_rebuildAtRest);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          InfoProfileTabs(
            tabs: const [
              InfoProfileTabData(label: 'First', icon: Icons.looks_one),
              InfoProfileTabData(label: 'Second', icon: Icons.looks_two),
            ],
            selectedIndex: controller.index,
            onTabSelected: (_) {},
            controller: controller,
          ),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: const [
                Center(child: Text('First page')),
                Center(child: Text('Second page')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NestedTabsHarness extends StatefulWidget {
  const _NestedTabsHarness();

  @override
  State<_NestedTabsHarness> createState() => _NestedTabsHarnessState();
}

class _NestedTabsHarnessState extends State<_NestedTabsHarness>
    with SingleTickerProviderStateMixin {
  late final TabController controller;
  final inactiveControllers = List.generate(2, (_) => ScrollController());
  var selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (controller.index != selectedIndex) {
      setState(() => selectedIndex = controller.index);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_handleTabChange);
    controller.dispose();
    for (final scrollController in inactiveControllers) {
      scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => const [
          SliverToBoxAdapter(child: SizedBox(height: 300)),
        ],
        body: TabBarView(
          controller: controller,
          children: [
            _page(0, 'First nested page'),
            _page(1, 'Second nested page'),
          ],
        ),
      ),
    );
  }

  Widget _page(int index, String label) {
    return Builder(
      builder: (pageContext) {
        final nestedController = PrimaryScrollController.maybeOf(pageContext);
        return PrimaryScrollController(
          controller: index == selectedIndex && nestedController != null
              ? nestedController
              : inactiveControllers[index],
          child: CustomScrollView(
            key: ValueKey(
              'nested-page-$index-${index == selectedIndex ? 'nested' : 'standalone'}',
            ),
            primary: true,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: 1000, child: Text(label)),
              ),
            ],
          ),
        );
      },
    );
  }
}
