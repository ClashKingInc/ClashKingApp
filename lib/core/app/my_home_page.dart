import 'dart:math' as math;

import 'package:clashking_design_system/clashking_design_system.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/icons/custom_icons_icons.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/utils/deep_link_handler.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/config/app_feature_flags.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/features/pages/presentation/dashboard_page.dart';
import 'package:clashkingapp/features/pages/data/announcement_presentation_service.dart';
import 'package:clashkingapp/features/pages/data/announcement_service.dart';
import 'package:clashkingapp/features/pages/models/app_announcement.dart';
import 'package:clashkingapp/features/pages/presentation/announcement_story_dialog.dart';
import 'package:clashkingapp/features/pages/presentation/players_page.dart';
import 'package:clashkingapp/features/pages/presentation/posts_page.dart';
import 'package:clashkingapp/features/pages/presentation/search_page.dart';
import 'package:clashkingapp/features/pages/presentation/side_tabs_pages.dart';
import 'package:clashkingapp/features/upgrade_tracker/presentation/upgrade_tracker_page.dart';
import 'package:clashkingapp/features/pages/presentation/war_cwl_page.dart';
import 'package:clashkingapp/features/settings/presentation/settings_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/app_bar/app_bar.dart';
import 'package:provider/provider.dart';

import '../../features/pages/presentation/clan_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  static const _mainPages = <Widget>[
    DashboardPage(),
    PlayersPage(),
    ClanPage(),
    WarCwlPage(),
  ];

  int _selectedIndex = 0;
  late PageController _pageController;
  late final AnnouncementService _announcementService;
  late final AnnouncementPresentationService _announcementPresentationService;
  late final Future<AppAnnouncement?> _openingAnnouncement;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _desktopContentNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _announcementService = AnnouncementService();
    _announcementPresentationService = AnnouncementPresentationService();
    _openingAnnouncement = _announcementService.getActiveAnnouncement();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DeepLinkHandler.tryHandlePendingDeepLink(context);
      await _showOpeningAnnouncement();
    });
  }

  Future<void> _showOpeningAnnouncement() async {
    if (!mounted ||
        !supportsEmbeddedAnnouncementStories(isWeb: kIsWeb) ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    if (!context.read<MyAppState>().isFeatureEnabled(
      AppFeatureFlags.homeAnnouncements,
    )) {
      return;
    }

    final openingAnnouncement = await _openingAnnouncement;
    if (openingAnnouncement == null ||
        !await _announcementPresentationService.shouldPresent(
          openingAnnouncement,
        )) {
      return;
    }
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    final displayed = await openAnnouncementStory(
      context,
      announcement: openingAnnouncement,
      canDisplay: () => mounted && ModalRoute.of(context)?.isCurrent == true,
    );
    if (!displayed) return;
    await _announcementPresentationService.markDismissed(openingAnnouncement);
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
    _desktopContentNavigatorKey.currentState?.popUntil(
      (route) => route.isFirst,
    );
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }

    if (_pageController.hasClients) {
      if (CKMotion.animationsDisabled(context)) {
        _pageController.jumpToPage(index);
        return;
      }
      _pageController.animateToPage(
        index,
        duration: CKMotion.standard,
        curve: CKMotion.standardCurve,
      );
    }
  }

  void _schedulePageControllerSync() {
    final expectedIndex = _selectedIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final currentIndex = _pageController.page?.round();
      if (currentIndex != expectedIndex) {
        _pageController.jumpToPage(expectedIndex);
      }
    });
  }

  void _openSearchOverlay() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: CKMotion.durationOf(context, CKMotion.standard),
        reverseTransitionDuration: CKMotion.durationOf(context, CKMotion.fast),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const SearchPage(overlay: true, autofocus: true);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (CKMotion.animationsDisabled(context)) return child;
          final curved = CurvedAnimation(
            parent: animation,
            curve: CKMotion.standardCurve,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _schedulePageControllerSync();
    if (_usesDesktopWebLayout(context)) {
      return _DesktopWebHomeShell(
        selectedIndex: _selectedIndex,
        pageController: _pageController,
        contentNavigatorKey: _desktopContentNavigatorKey,
        onItemTapped: _onItemTapped,
        onPageChanged: _onPageChanged,
        onSearchTap: _openSearchOverlay,
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawer: const _AccountMenuDrawer(),
      // Widen the edge-drag zone so the account drawer can be pulled open from
      // further inside the screen. The default (~20px) sits exactly on top of
      // the Android/Samsung system "back" gesture edge, which made the swipe
      // close the app instead of opening the menu.
      drawerEdgeDragWidth: MediaQuery.of(context).padding.left + 80,
      appBar: CustomAppBar(
        title: 'ClashKing',
        searchHint: AppLocalizations.of(context)!.searchGlobalHint,
        onSearchTap: _openSearchOverlay,
        onProfileTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: kIsWeb
          ? IndexedStack(index: _selectedIndex, children: _mainPages)
          : PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: _mainPages,
            ),
      bottomNavigationBar: usesNativeGlassPlatform
          ? _NativeIOSTabBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : _AndroidFloatingTabBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
    );
  }
}

bool _usesDesktopWebLayout(BuildContext context) =>
    kIsWeb && MediaQuery.sizeOf(context).width >= 900;

Route<void> _instantDesktopRoute(WidgetBuilder builder) {
  return PageRouteBuilder<void>(
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
  );
}

class _DesktopWebHomeShell extends StatelessWidget {
  const _DesktopWebHomeShell({
    required this.selectedIndex,
    required this.pageController,
    required this.contentNavigatorKey,
    required this.onItemTapped,
    required this.onPageChanged,
    required this.onSearchTap,
  });

  final int selectedIndex;
  final PageController pageController;
  final GlobalKey<NavigatorState> contentNavigatorKey;
  final ValueChanged<int> onItemTapped;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final pageTitles = [
      l10n.navigationHome,
      l10n.searchTabPlayers,
      l10n.searchTabClans,
      l10n.warTitle,
    ];

    void openDesktopPage(String label, WidgetBuilder builder) {
      Navigator.of(context).push(
        _instantDesktopRoute(
          (_) => _DesktopSecondaryShell(
            selectedUtility: label,
            pageBuilder: builder,
            onItemTapped: onItemTapped,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Row(
          children: [
            _DesktopSidebar(
              selectedIndex: selectedIndex,
              onItemTapped: onItemTapped,
            ),
            VerticalDivider(
              width: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
            Expanded(
              child: Column(
                children: [
                  _DesktopHeader(
                    title: pageTitles[selectedIndex],
                    searchHint: l10n.searchGlobalHint,
                    onSearchTap: onSearchTap,
                    manageAccountsTooltip: l10n.drawerManageAccounts,
                    onManageAccountsTap: () => openDesktopPage(
                      l10n.drawerManageAccounts,
                      (_) => const AddCocAccountPage(refreshOnExit: false),
                    ),
                  ),
                  Expanded(
                    child: Navigator(
                      key: contentNavigatorKey,
                      onGenerateRoute: (_) => _instantDesktopRoute(
                        (_) => PageView(
                          controller: pageController,
                          onPageChanged: onPageChanged,
                          physics: const NeverScrollableScrollPhysics(),
                          children: const [
                            DashboardPage(),
                            PlayersPage(),
                            ClanPage(),
                            WarCwlPage(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopSecondaryShell extends StatelessWidget {
  const _DesktopSecondaryShell({
    required this.selectedUtility,
    required this.pageBuilder,
    required this.onItemTapped,
  });

  final String selectedUtility;
  final WidgetBuilder pageBuilder;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Row(
          children: [
            _DesktopSidebar(
              selectedIndex: -1,
              selectedUtility: selectedUtility,
              replaceUtilityRoute: true,
              onItemTapped: (index) {
                Navigator.of(context).pop();
                onItemTapped(index);
              },
            ),
            VerticalDivider(
              width: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
            Expanded(child: Builder(builder: pageBuilder)),
          ],
        ),
      ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader({
    required this.title,
    required this.searchHint,
    required this.onSearchTap,
    required this.manageAccountsTooltip,
    required this.onManageAccountsTap,
  });

  final String title;
  final String searchHint;
  final VoidCallback onSearchTap;
  final String manageAccountsTooltip;
  final VoidCallback onManageAccountsTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget actions() => Row(
      children: [
        Expanded(
          child: _DesktopSearchButton(hint: searchHint, onTap: onSearchTap),
        ),
        const SizedBox(width: 12),
        _DesktopQuickAction(
          tooltip: manageAccountsTooltip,
          icon: Icons.person_add_alt_1_outlined,
          onTap: onManageAccountsTap,
        ),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 15),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final titleWidget = Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            );

            if (constraints.maxWidth < 820) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [titleWidget, const SizedBox(height: 12), actions()],
              );
            }

            return Row(
              children: [
                Expanded(child: titleWidget),
                const SizedBox(width: 24),
                SizedBox(width: 520, child: actions()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onItemTapped,
    this.selectedUtility,
    this.replaceUtilityRoute = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;
  final String? selectedUtility;
  final bool replaceUtilityRoute;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final appState = context.watch<MyAppState>();
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final user = authService.currentUser;

    void openUtility(String label, WidgetBuilder builder) {
      final route = _instantDesktopRoute(
        (_) => _DesktopSecondaryShell(
          selectedUtility: label,
          pageBuilder: builder,
          onItemTapped: onItemTapped,
        ),
      );
      if (replaceUtilityRoute) {
        Navigator.of(context).pushReplacement(route);
      } else {
        Navigator.of(context).push(route);
      }
    }

    final navItems = [
      _DesktopNavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: l10n.navigationHome,
      ),
      _DesktopNavItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: l10n.searchTabPlayers,
      ),
      _DesktopNavItem(
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        label: l10n.searchTabClans,
      ),
      _DesktopNavItem(
        icon: CustomIcons.swordCross,
        selectedIcon: CustomIcons.swordCross,
        label: l10n.warTitle,
      ),
    ];

    return SizedBox(
      width: 264,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.58),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _DrawerAvatar(imageUrl: user?.avatarUrl ?? ''),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? 'ClashKing',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'ClashKing web',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              for (var index = 0; index < navItems.length; index++)
                _DesktopNavButton(
                  item: navItems[index],
                  selected: selectedIndex == index,
                  onTap: () => onItemTapped(index),
                ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.34,
                        ),
                      ),
                      if (appState.isFeatureEnabled(AppFeatureFlags.posts))
                        _DesktopUtilityButton(
                          icon: Icons.article_outlined,
                          label: l10n.postsTitle,
                          selected: selectedUtility == l10n.postsTitle,
                          onTap: () => openUtility(
                            l10n.postsTitle,
                            (_) => const PostsPage(),
                          ),
                        ),
                      if (appState.isFeatureEnabled(
                        AppFeatureFlags.leaderboards,
                      ))
                        _DesktopUtilityButton(
                          icon: Icons.leaderboard_outlined,
                          label: l10n.clanRankingsTab,
                          selected: selectedUtility == l10n.clanRankingsTab,
                          onTap: () => openUtility(
                            l10n.clanRankingsTab,
                            (_) => const RankingsPage(),
                          ),
                        ),
                      if (appState.isFeatureEnabled(
                        AppFeatureFlags.globalStats,
                      ))
                        _DesktopUtilityButton(
                          icon: Icons.bar_chart_rounded,
                          label: l10n.generalStats,
                          selected: selectedUtility == l10n.generalStats,
                          onTap: () => openUtility(
                            l10n.generalStats,
                            (_) => const StatsPage(),
                          ),
                        ),
                      if (appState.isFeatureEnabled(
                        AppFeatureFlags.calculators,
                      ))
                        _DesktopUtilityButton(
                          icon: Icons.calculate_outlined,
                          label: l10n.drawerCalculators,
                          selected: selectedUtility == l10n.drawerCalculators,
                          onTap: () => openUtility(
                            l10n.drawerCalculators,
                            (_) => const CalculatorsPage(),
                          ),
                        ),
                      if (appState.isFeatureEnabled(
                        AppFeatureFlags.upgradeTracker,
                      ))
                        _DesktopUtilityButton(
                          icon: Icons.construction_rounded,
                          label: l10n.drawerUpgradeTracker,
                          selected:
                              selectedUtility == l10n.drawerUpgradeTracker,
                          onTap: () => openUtility(
                            l10n.drawerUpgradeTracker,
                            (_) => const UpgradeTrackerPage(),
                          ),
                        ),
                      if (appState.isFeatureEnabled(AppFeatureFlags.gameAssets))
                        _DesktopUtilityButton(
                          icon: Icons.inventory_2_outlined,
                          label: l10n.drawerGameAssets,
                          selected: selectedUtility == l10n.drawerGameAssets,
                          onTap: () => openUtility(
                            l10n.drawerGameAssets,
                            (_) => const GameAssetsPage(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.34),
              ),
              _DesktopUtilityButton(
                icon: Icons.manage_accounts_outlined,
                label: l10n.drawerManageAccounts,
                selected: selectedUtility == l10n.drawerManageAccounts,
                onTap: () => openUtility(
                  l10n.drawerManageAccounts,
                  (_) => const AddCocAccountPage(refreshOnExit: false),
                ),
              ),
              _DesktopUtilityButton(
                icon: Icons.settings_outlined,
                label: l10n.generalSettings,
                selected: selectedUtility == l10n.generalSettings,
                onTap: user == null
                    ? null
                    : () => openUtility(
                        l10n.generalSettings,
                        (_) => SettingsInfoScreen(user: user),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopNavItem {
  const _DesktopNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _DesktopNavButton extends StatelessWidget {
  const _DesktopNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _DesktopNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected ? colorScheme.primary : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Material(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.22)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(
                    selected ? item.selectedIcon : item.icon,
                    color: foreground,
                    size: 21,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w700,
                      ),
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

class _DesktopUtilityButton extends StatelessWidget {
  const _DesktopUtilityButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final foreground = selected ? colorScheme.primary : colorScheme.onSurface;
    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.22)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: onTap == null
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.44)
                    : selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onTap == null
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.44)
                        : foreground,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopSearchButton extends StatelessWidget {
  const _DesktopSearchButton({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Material(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.34),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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

class _DesktopQuickAction extends StatelessWidget {
  const _DesktopQuickAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.34),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 50,
            child: Icon(icon, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Android fallback for the app-level floating tab bar.
///
/// Keep this custom instead of using the liquid glass background on Android:
/// the native/glass border reads too bright on black gesture-bar backgrounds.
class _AndroidFloatingTabBar extends StatelessWidget {
  const _AndroidFloatingTabBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      _AndroidTabItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: l10n.navigationHome,
      ),
      _AndroidTabItem(
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: l10n.searchTabPlayers,
      ),
      _AndroidTabItem(
        icon: Icons.groups_outlined,
        selectedIcon: Icons.groups,
        label: l10n.searchTabClans,
      ),
      _AndroidTabItem(
        icon: CustomIcons.swordCross,
        selectedIcon: CustomIcons.swordCross,
        label: l10n.warTitle,
      ),
    ];

    return SafeArea(
      top: false,
      minimum: EdgeInsets.fromLTRB(14, 0, 14, bottomPadding > 0 ? 2 : 10),
      child: SizedBox(
        height: 68,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.90)
                : colorScheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var index = 0; index < tabs.length; index++)
                Expanded(
                  child: _AndroidTabButton(
                    item: tabs[index],
                    selected: selectedIndex == index,
                    onTap: () => onItemTapped(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AndroidTabItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _AndroidTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _AndroidTabButton extends StatelessWidget {
  const _AndroidTabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _AndroidTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = colorScheme.primary;
    final unselectedColor = colorScheme.onSurface.withValues(alpha: 0.92);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Material(
          color: selected
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.58)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(29),
          child: InkWell(
            borderRadius: BorderRadius.circular(29),
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 25,
                  color: selected ? selectedColor : unselectedColor,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? selectedColor : unselectedColor,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Apple's real native Liquid Glass bottom tab bar, sized/positioned by the
/// caller (unlike liquid_glass_widgets' `GlassTabBar.bottom`, which wants to
/// own the whole `bottomNavigationBar` slot directly).
class _NativeIOSTabBar extends StatelessWidget {
  const _NativeIOSTabBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: SizedBox(
        height: 78,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final colorScheme = Theme.of(context).colorScheme;
            final l10n = AppLocalizations.of(context)!;
            final tabItems = [
              NativeLiquidGlassTabItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                label: l10n.navigationHome,
                selectedItemColor: colorScheme.primary,
              ),
              NativeLiquidGlassTabItem(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: l10n.searchTabPlayers,
                selectedItemColor: colorScheme.primary,
              ),
              NativeLiquidGlassTabItem(
                icon: Icons.groups_outlined,
                selectedIcon: Icons.groups,
                label: l10n.searchTabClans,
                selectedItemColor: colorScheme.primary,
              ),
              NativeLiquidGlassTabItem(
                icon: CustomIcons.swordCross,
                selectedIcon: CustomIcons.swordCross,
                label: l10n.warTitle,
                selectedItemColor: colorScheme.primary,
              ),
            ];

            return Stack(
              fit: StackFit.expand,
              children: [
                NativeLiquidGlassTabBar(
                  height: 62,
                  itemCount: 4,
                  selectedIndex: selectedIndex,
                  onTabSelected: onItemTapped,
                  items: tabItems,
                  cornerRadius: 31,
                  selectedCornerRadius: 25,
                  inset: 6,
                  borderOpacity: Theme.of(context).brightness == Brightness.dark
                      ? 0.22
                      : 0.34,
                  shadowOpacity: Theme.of(context).brightness == Brightness.dark
                      ? 0.5
                      : 0.18,
                  iconSize: 22,
                ),
                Row(
                  children: [
                    _NavHitTarget(
                      label: l10n.navigationHome,
                      onTap: () => onItemTapped(0),
                    ),
                    _NavHitTarget(
                      label: l10n.searchTabPlayers,
                      onTap: () => onItemTapped(1),
                    ),
                    _NavHitTarget(
                      label: l10n.searchTabClans,
                      onTap: () => onItemTapped(2),
                    ),
                    _NavHitTarget(
                      label: l10n.warTitle,
                      onTap: () => onItemTapped(3),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavHitTarget extends StatelessWidget {
  const _NavHitTarget({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _AccountMenuDrawer extends StatelessWidget {
  const _AccountMenuDrawer();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authService = context.watch<AuthService>();
    final appState = context.watch<MyAppState>();
    final l10n = AppLocalizations.of(context)!;
    final user = authService.currentUser;
    final displayName = user?.username ?? 'ClashKing';
    final followerCount = user == null ? 0 : 49;

    return Drawer(
      width: math.min(MediaQuery.sizeOf(context).width * 0.82, 330),
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DrawerAvatar(imageUrl: user?.avatarUrl ?? ''),
                        const Spacer(),
                        IconButton(
                          tooltip: l10n.accountsAdd,
                          onPressed: () => _pushAndClose(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AddCocAccountPage(refreshOnExit: false),
                            ),
                          ),
                          icon: const Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _DrawerCount(
                          value: followerCount,
                          label: l10n.drawerFollowers,
                        ),
                        const SizedBox(width: 2),
                        Tooltip(
                          triggerMode: TooltipTriggerMode.tap,
                          showDuration: const Duration(seconds: 4),
                          message: l10n.drawerFollowersHelp,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.help_outline_rounded,
                              size: 15,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (appState.isFeatureEnabled(AppFeatureFlags.posts))
                      _DrawerMenuItem(
                        icon: Icons.article_outlined,
                        label: l10n.postsTitle,
                        onTap: () => _pushAndClose(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PostsPage(),
                          ),
                        ),
                      ),
                    if (appState.isFeatureEnabled(AppFeatureFlags.leaderboards))
                      _DrawerMenuItem(
                        icon: Icons.leaderboard_outlined,
                        label: l10n.clanRankingsTab,
                        onTap: () => _pushAndClose(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RankingsPage(),
                          ),
                        ),
                      ),
                    if (appState.isFeatureEnabled(AppFeatureFlags.globalStats))
                      _DrawerMenuItem(
                        icon: Icons.bar_chart_rounded,
                        label: l10n.generalStats,
                        onTap: () => _pushAndClose(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatsPage(),
                          ),
                        ),
                      ),
                    if (appState.isFeatureEnabled(AppFeatureFlags.calculators))
                      _DrawerMenuItem(
                        icon: Icons.calculate_outlined,
                        label: l10n.drawerCalculators,
                        onTap: () => _pushAndClose(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalculatorsPage(),
                          ),
                        ),
                      ),
                    if (appState.isFeatureEnabled(
                      AppFeatureFlags.subscriptionSupport,
                    ))
                      _DrawerMenuItem(
                        icon: Icons.workspace_premium_outlined,
                        label: l10n.drawerSubscription,
                        onTap: () => _pushAndClose(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const _SubscriptionPage(),
                          ),
                        ),
                      ),
                    if (appState.isFeatureEnabled(
                      AppFeatureFlags.upgradeTracker,
                    ))
                      _DrawerMenuItem(
                        icon: Icons.construction_rounded,
                        label: l10n.drawerUpgradeTracker,
                        onTap: () => _pushAndClose(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpgradeTrackerPage(),
                          ),
                        ),
                      ),
                    if (appState.isFeatureEnabled(AppFeatureFlags.basesArmies))
                      _DrawerMenuItem(
                        icon: Icons.grid_view_rounded,
                        label: l10n.drawerBasesArmies,
                        onTap: () => _pushAndClose(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BasesArmiesPage(),
                          ),
                        ),
                      ),
                    if (appState.isFeatureEnabled(AppFeatureFlags.gameAssets))
                      _DrawerMenuItem(
                        icon: Icons.inventory_2_outlined,
                        label: l10n.drawerGameAssets,
                        onTap: () => _pushAndClose(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GameAssetsPage(),
                          ),
                        ),
                      ),
                    _DrawerMenuItem(
                      icon: Icons.manage_accounts_outlined,
                      label: l10n.drawerManageAccounts,
                      onTap: () => _pushAndClose(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const AddCocAccountPage(refreshOnExit: false),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
              child: Column(
                children: [
                  Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                  _DrawerMenuItem(
                    icon: Icons.settings_outlined,
                    label: l10n.generalSettings,
                    dense: true,
                    onTap: user == null
                        ? null
                        : () => _pushAndClose(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SettingsInfoScreen(user: user),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pushAndClose(BuildContext context, Route<void> route) {
    Navigator.of(context).pop();
    Navigator.of(context).push(route);
  }
}

class _DrawerAvatar extends StatelessWidget {
  const _DrawerAvatar({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox.square(
        dimension: 48,
        child: MobileWebImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) => DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 26),
          ),
        ),
      ),
    );
  }
}

class _DrawerCount extends StatelessWidget {
  const _DrawerCount({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return RichText(
      text: TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
        children: [
          TextSpan(
            text: value.toString(),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: ' $label'),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: dense ? 8 : 9.5),
          child: Row(
            children: [
              Icon(
                icon,
                size: dense ? 18 : 19,
                color: onTap == null
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
                    : colorScheme.onSurface,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style:
                      (dense
                              ? Theme.of(context).textTheme.bodyLarge
                              : Theme.of(context).textTheme.titleMedium)
                          ?.copyWith(
                            color: onTap == null
                                ? colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.45,
                                  )
                                : colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionPage extends StatelessWidget {
  const _SubscriptionPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.drawerSubscription),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$1.99/month',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You help keep ClashKing free.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: colorScheme.onSurface,
                                height: 1.25,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
