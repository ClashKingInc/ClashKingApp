import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_header.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_members.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_history/component/war_log_history_tab.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class ClanInfoScreen extends StatefulWidget {
  final Clan clanInfo;

  const ClanInfoScreen({super.key, required this.clanInfo});

  @override
  State<ClanInfoScreen> createState() => _ClanInfoScreenState();
}

class _ClanInfoScreenState extends State<ClanInfoScreen> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = 16 + MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleTabSwipe,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            children: [
              ClanInfoHeaderCard(clanInfo: widget.clanInfo),
              _ClanInfoTabs(
                selectedIndex: selectedTab,
                onTabSelected: _selectTab,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: KeyedSubtree(
                  key: ValueKey(selectedTab),
                  child: _buildTabContent(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) {
    final clampedIndex = index > 3 ? 3 : index;
    final boundedIndex = index < 0 ? 0 : clampedIndex;
    if (boundedIndex == selectedTab) return;
    setState(() => selectedTab = boundedIndex);
  }

  void _handleTabSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 240) return;
    if (velocity < 0) {
      _selectTab(selectedTab + 1);
    } else {
      _selectTab(selectedTab - 1);
    }
  }

  Widget _buildTabContent(BuildContext context) {
    final clanInfo = widget.clanInfo;
    final warLogLoaded = clanInfo.clanWarLog != null;

    return switch (selectedTab) {
      0 => ClanMembers(clanInfo: clanInfo),
      1 =>
        warLogLoaded
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: WarLogHistoryTab(clan: clanInfo),
              )
            : const _ClanEmptyTab(
                title: 'No war log loaded',
                body:
                    'War history appears here when the clan payload includes it.',
                icon: Icons.history_rounded,
              ),
      2 => const _ClanEmptyTab(
        title: 'War stats',
        body:
            'This view is intentionally empty until the new stats layout is ready.',
        icon: Icons.query_stats_rounded,
      ),
      _ => const _ClanEmptyTab(
        title: 'CWL',
        body:
            'This view is intentionally empty until the CWL history layout is ready.',
        icon: Icons.military_tech_rounded,
      ),
    };
  }
}

class _ClanInfoTabs extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _ClanInfoTabs({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_ClanInfoTabs> createState() => _ClanInfoTabsState();
}

class _ClanInfoTabsState extends State<_ClanInfoTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.selectedIndex,
    );
  }

  @override
  void didUpdateWidget(covariant _ClanInfoTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        _tabController.index != widget.selectedIndex) {
      _tabController.animateTo(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.42),
          ),
        ),
      ),
      child: SizedBox(
        height: 42,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
          dividerColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          onTap: widget.onTabSelected,
          tabs: [
            _ClanProfileTab(
              label: loc?.clanMembers ?? 'Members',
              selected: widget.selectedIndex == 0,
            ),
            _ClanProfileTab(
              label: loc?.warLog ?? 'War log',
              selected: widget.selectedIndex == 1,
            ),
            _ClanProfileTab(
              label: loc?.warStats ?? 'War stats',
              selected: widget.selectedIndex == 2,
            ),
            _ClanProfileTab(label: 'CWL', selected: widget.selectedIndex == 3),
          ],
        ),
      ),
    );
  }
}

class _ClanProfileTab extends StatelessWidget {
  final String label;
  final bool selected;

  const _ClanProfileTab({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.58);

    return Tab(
      height: 42,
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _ClanEmptyTab extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _ClanEmptyTab({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.45,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
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
