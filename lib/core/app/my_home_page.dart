import 'package:clashkingapp/common/widgets/icons/custom_icons_icons.dart';
import 'package:clashkingapp/core/utils/deep_link_handler.dart';
import 'package:clashkingapp/features/pages/presentation/dashboard_page.dart';
import 'package:clashkingapp/features/pages/presentation/search_page.dart';
import 'package:clashkingapp/features/pages/presentation/war_cwl_page.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/app_bar/app_bar.dart';

import '../../features/pages/presentation/clan_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DeepLinkHandler.tryHandlePendingDeepLink(context);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onItemTapped(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: CustomAppBar(),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          DashboardPage(),
          ClanPage(),
          WarCwlPage(),
          SearchPage(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        child: SizedBox(
          height: 62,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final colorScheme = Theme.of(context).colorScheme;
              const searchButtonSize = 62.0;
              const gap = 10.0;
              final mainWidth = constraints.maxWidth - searchButtonSize - gap;
              final isSearchSelected = _selectedIndex == 3;

              return Row(
                children: [
                  SizedBox(
                    width: mainWidth,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        NativeLiquidGlassTabBar(
                          height: 62,
                          itemCount: 3,
                          selectedIndex: isSearchSelected ? -1 : _selectedIndex,
                          cornerRadius: 28,
                          selectedCornerRadius: 20,
                          inset: 7,
                          borderOpacity:
                              Theme.of(context).brightness == Brightness.dark
                              ? 0.22
                              : 0.34,
                          shadowOpacity:
                              Theme.of(context).brightness == Brightness.dark
                              ? 0.5
                              : 0.18,
                        ),
                        Row(
                          children: [
                            _GlassNavItem(
                              icon: Icons.dashboard,
                              label:
                                  AppLocalizations.of(
                                    context,
                                  )?.dashboardTitle ??
                                  'Dashboard',
                              selected: _selectedIndex == 0,
                              selectedColor: colorScheme.primary,
                              unselectedColor: colorScheme.onSurfaceVariant,
                              onTap: () => _onItemTapped(0),
                            ),
                            _GlassNavItem(
                              icon: Icons.shield,
                              label:
                                  AppLocalizations.of(context)?.clanTitle ??
                                  'Clan',
                              selected: _selectedIndex == 1,
                              selectedColor: colorScheme.primary,
                              unselectedColor: colorScheme.onSurfaceVariant,
                              onTap: () => _onItemTapped(1),
                            ),
                            _GlassNavItem(
                              icon: CustomIcons.swordCross,
                              label:
                                  AppLocalizations.of(context)?.warLeague ??
                                  'War/League',
                              selected: _selectedIndex == 2,
                              selectedColor: colorScheme.primary,
                              unselectedColor: colorScheme.onSurfaceVariant,
                              onTap: () => _onItemTapped(2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: gap),
                  SizedBox(
                    width: searchButtonSize,
                    height: searchButtonSize,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        NativeLiquidGlassBar(
                          height: searchButtonSize,
                          cornerRadius: 31,
                          interactive: true,
                          selected: isSearchSelected,
                          borderOpacity: isSearchSelected ? 0.44 : null,
                          shadowOpacity:
                              Theme.of(context).brightness == Brightness.dark
                              ? 0.42
                              : 0.16,
                        ),
                        Material(
                          color: Colors.transparent,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              splashFactory: NoSplash.splashFactory,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),
                            child: Semantics(
                              label: 'Search',
                              button: true,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _onItemTapped(3),
                                child: Icon(
                                  Icons.search,
                                  size: 30,
                                  color: isSearchSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? selectedColor : unselectedColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(
            splashFactory: NoSplash.splashFactory,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 25),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
