import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clashkingapp/common/widgets/icons/custom_icons_icons.dart';
import 'package:clashkingapp/core/utils/deep_link_handler.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:clashkingapp/features/pages/presentation/dashboard_page.dart';
import 'package:clashkingapp/features/pages/presentation/players_page.dart';
import 'package:clashkingapp/features/pages/presentation/search_page.dart';
import 'package:clashkingapp/features/pages/presentation/side_tabs_pages.dart';
import 'package:clashkingapp/features/pages/presentation/war_cwl_page.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/features/settings/presentation/settings_page.dart';
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
  int _selectedIndex = 0;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openSearchOverlay() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 240),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const SearchPage(overlay: true, autofocus: true);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
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
        searchHint: 'Search players or clans',
        onSearchTap: _openSearchOverlay,
        onProfileTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          DashboardPage(),
          PlayersPage(),
          ClanPage(),
          WarCwlPage(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: supportsNativeLiquidGlass
            ? const EdgeInsets.fromLTRB(8, 0, 8, 4)
            : const EdgeInsets.fromLTRB(24, 0, 24, 18),
        child: SizedBox(
          height: supportsNativeLiquidGlass ? 78 : 62,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final colorScheme = Theme.of(context).colorScheme;
              final tabItems = [
                NativeLiquidGlassTabItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Home',
                  selectedItemColor: colorScheme.primary,
                ),
                NativeLiquidGlassTabItem(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: 'Players',
                  selectedItemColor: colorScheme.primary,
                ),
                NativeLiquidGlassTabItem(
                  icon: Icons.groups_outlined,
                  selectedIcon: Icons.groups,
                  label: AppLocalizations.of(context)?.clanTitle ?? 'Clan',
                  selectedItemColor: colorScheme.primary,
                ),
                NativeLiquidGlassTabItem(
                  icon: CustomIcons.swordCross,
                  selectedIcon: CustomIcons.swordCross,
                  label: 'War',
                  selectedItemColor: colorScheme.primary,
                ),
              ];

              return Stack(
                fit: StackFit.expand,
                children: [
                  NativeLiquidGlassTabBar(
                    height: 62,
                    itemCount: 4,
                    selectedIndex: _selectedIndex,
                    onTabSelected: _onItemTapped,
                    items: tabItems,
                    cornerRadius: 31,
                    selectedCornerRadius: 25,
                    inset: 6,
                    borderOpacity:
                        Theme.of(context).brightness == Brightness.dark
                        ? 0.22
                        : 0.34,
                    shadowOpacity:
                        Theme.of(context).brightness == Brightness.dark
                        ? 0.5
                        : 0.18,
                    iconSize: 22,
                  ),
                  supportsNativeLiquidGlass
                      ? Row(
                          children: [
                            _NavHitTarget(
                              label: 'Home',
                              onTap: () => _onItemTapped(0),
                            ),
                            _NavHitTarget(
                              label: 'Players',
                              onTap: () => _onItemTapped(1),
                            ),
                            _NavHitTarget(
                              label:
                                  AppLocalizations.of(context)?.clanTitle ??
                                  'Clan',
                              onTap: () => _onItemTapped(2),
                            ),
                            _NavHitTarget(
                              label: 'War',
                              onTap: () => _onItemTapped(3),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            _GlassNavItem(
                              icon: Icons.home_outlined,
                              label: 'Home',
                              selected: _selectedIndex == 0,
                              selectedColor: colorScheme.primary,
                              unselectedColor: colorScheme.onSurfaceVariant,
                              onTap: () => _onItemTapped(0),
                            ),
                            _GlassNavItem(
                              icon: Icons.person_outline_rounded,
                              label: 'Players',
                              selected: _selectedIndex == 1,
                              selectedColor: colorScheme.primary,
                              unselectedColor: colorScheme.onSurfaceVariant,
                              onTap: () => _onItemTapped(1),
                            ),
                            _GlassNavItem(
                              icon: Icons.groups_outlined,
                              label:
                                  AppLocalizations.of(context)?.clanTitle ??
                                  'Clan',
                              selected: _selectedIndex == 2,
                              selectedColor: colorScheme.primary,
                              unselectedColor: colorScheme.onSurfaceVariant,
                              onTap: () => _onItemTapped(2),
                            ),
                            _GlassNavItem(
                              icon: CustomIcons.swordCross,
                              label: 'War',
                              selected: _selectedIndex == 3,
                              selectedColor: colorScheme.primary,
                              unselectedColor: colorScheme.onSurfaceVariant,
                              onTap: () => _onItemTapped(3),
                            ),
                          ],
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

class _AccountMenuDrawer extends StatelessWidget {
  const _AccountMenuDrawer();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authService = context.watch<AuthService>();
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
              child: Padding(
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
                          tooltip: 'Add account',
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
                        _DrawerCount(value: followerCount, label: 'Followers'),
                        const SizedBox(width: 2),
                        Tooltip(
                          triggerMode: TooltipTriggerMode.tap,
                          showDuration: const Duration(seconds: 4),
                          message:
                              'People who bookmarked one of your verified linked accounts.',
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
                    _DrawerMenuItem(
                      icon: Icons.trending_up_rounded,
                      label: 'Popular',
                      onTap: () => _pushAndClose(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PopularPage(),
                        ),
                      ),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.leaderboard_outlined,
                      label: 'Rankings',
                      onTap: () => _pushAndClose(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RankingsPage(),
                        ),
                      ),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Stats',
                      onTap: () => _pushAndClose(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StatsPage(),
                        ),
                      ),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.calculate_outlined,
                      label: 'Calculators',
                      onTap: () => _pushAndClose(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CalculatorsPage(),
                        ),
                      ),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Subscription',
                      onTap: () => _pushAndClose(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const _SubscriptionPage(),
                        ),
                      ),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.construction_rounded,
                      label: 'Upgrade Tracker',
                      onTap: () => _pushAndClose(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UpgradeTrackerTeasePage(),
                        ),
                      ),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Bases & Armies',
                      onTap: () => _pushAndClose(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BasesArmiesPage(),
                        ),
                      ),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.inventory_2_outlined,
                      label: 'Game Assets',
                      onTap: () => _pushAndClose(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GameAssetsPage(),
                        ),
                      ),
                    ),
                    _DrawerMenuItem(
                      icon: Icons.manage_accounts_outlined,
                      label: 'Manage Accounts',
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
                    label: 'Settings',
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
        child: CachedNetworkImage(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
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
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      height: 1.0,
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
