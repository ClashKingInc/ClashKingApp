import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_details.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_header.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_members.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_raid.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Capital detail screen: hero header + tabs for Raids / Members, mirroring
/// the clan and CWL detail screens' hero-header-plus-tabs pattern instead of
/// the page's old plain header + single stacked column.
class ClanCapitalScreen extends StatefulWidget {
  final Clan clanInfo;

  const ClanCapitalScreen({super.key, required this.clanInfo});

  @override
  State<ClanCapitalScreen> createState() => _ClanCapitalScreenState();
}

class _ClanCapitalScreenState extends State<ClanCapitalScreen> {
  static const int _tabCount = 4;
  int selectedTab = 0;
  int week = 0;

  void _selectTab(int index) {
    final bounded = index.clamp(0, _tabCount - 1);
    if (bounded == selectedTab) return;
    setState(() => selectedTab = bounded);
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

  void _setWeek(int value, int maxIndex) {
    setState(() => week = value.clamp(0, maxIndex));
  }

  @override
  Widget build(BuildContext context) {
    final raidItems = widget.clanInfo.clanCapitalRaid?.items ?? const [];
    final hasData = raidItems.isNotEmpty;
    final maxWeekIndex = hasData ? raidItems.length - 1 : 0;
    final boundedWeek = week.clamp(0, maxWeekIndex);
    final selectedRaid = hasData ? raidItems[boundedWeek] : null;

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: hasData ? _handleTabSwipe : null,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              ClanCapitalHeaderCard(clanInfo: widget.clanInfo),
              const SizedBox(height: 10),
              if (!hasData)
                const _CapitalEmptyState()
              else ...[
                _CapitalProfileTabs(
                  selectedIndex: selectedTab,
                  onTabSelected: _selectTab,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _WeekNavigator(
                    raid: selectedRaid!,
                    onOlder: boundedWeek < maxWeekIndex
                        ? () => _setWeek(boundedWeek + 1, maxWeekIndex)
                        : null,
                    onNewer: boundedWeek > 0
                        ? () => _setWeek(boundedWeek - 1, maxWeekIndex)
                        : null,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: KeyedSubtree(
                    key: ValueKey(selectedTab),
                    child: switch (selectedTab) {
                      0 => CapitalRaidsTab(
                        raid: selectedRaid,
                        clanCapitalPoints: widget.clanInfo.clanCapitalPoints,
                      ),
                      1 => CapitalMembersTab(
                        clanInfo: widget.clanInfo,
                        raid: selectedRaid,
                        allRaids: raidItems,
                      ),
                      2 => Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: CapitalRaidBreakdown(raid: selectedRaid),
                      ),
                      _ => Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: CapitalHistorySummary(
                          allRaids: raidItems,
                          clanCapitalPoints: widget.clanInfo.clanCapitalPoints,
                          clanMembers: widget.clanInfo.memberList,
                        ),
                      ),
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Same clean tab strip recipe as War/Player: surface background, underline
/// indicator, icon+label tabs, external TabController driven by the parent's
/// selectedTab so content can crossfade via AnimatedSwitcher.
class _CapitalProfileTabs extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _CapitalProfileTabs({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_CapitalProfileTabs> createState() => _CapitalProfileTabsState();
}

class _CapitalProfileTabsState extends State<_CapitalProfileTabs>
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
  void didUpdateWidget(covariant _CapitalProfileTabs oldWidget) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(color: colorScheme.surface),
      child: SizedBox(
        height: 50,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          labelColor: colorScheme.onSurface,
          unselectedLabelColor: colorScheme.onSurface,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: colorScheme.outlineVariant.withValues(alpha: 0.35),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          onTap: widget.onTabSelected,
          tabs: [
            _CapitalTab(
              label: 'Summary',
              icon: Icons.dashboard_rounded,
              selected: widget.selectedIndex == 0,
            ),
            _CapitalTab(
              label: loc.clanMembers,
              icon: Icons.groups_rounded,
              selected: widget.selectedIndex == 1,
            ),
            _CapitalTab(
              label: 'Breakdown',
              imageUrl: ImageAssets.raidAttacks,
              selected: widget.selectedIndex == 2,
            ),
            _CapitalTab(
              label: loc.generalHistory,
              icon: Icons.bar_chart_rounded,
              selected: widget.selectedIndex == 3,
            ),
          ],
        ),
      ),
    );
  }
}

class _CapitalTab extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final IconData? icon;
  final bool selected;

  const _CapitalTab({
    required this.label,
    this.imageUrl,
    this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = selected
        ? colorScheme.onSurface
        : colorScheme.onSurface.withValues(alpha: 0.58);

    return Tab(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          imageUrl != null
              ? MobileWebImage(imageUrl: imageUrl!, width: 18, height: 18)
              : Icon(icon, size: 18, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Prev/next week switcher shared by both tabs (Raids and Members both
/// read from the same selected week), with a status pill mirroring the
/// CWL round badge language instead of a plain arrow-and-date row.
class _WeekNavigator extends StatelessWidget {
  final CapitalHistoryItem raid;
  final VoidCallback? onOlder;
  final VoidCallback? onNewer;

  const _WeekNavigator({required this.raid, this.onOlder, this.onNewer});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final isOngoing = raid.state == 'ongoing';

    return Row(
      children: [
        _WeekArrowButton(
          icon: Icons.chevron_left_rounded,
          tooltip: AppLocalizations.of(context)!.capitalRaidPreviousWeek,
          onTap: onOlder,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                '${DateFormat.yMMMd(locale).format(raid.startTime)} – ${DateFormat.yMMMd(locale).format(raid.endTime)}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              _StatusBadge(isOngoing: isOngoing),
            ],
          ),
        ),
        _WeekArrowButton(
          icon: Icons.chevron_right_rounded,
          tooltip: AppLocalizations.of(context)!.capitalRaidNextWeek,
          onTap: onNewer,
        ),
      ],
    );
  }
}

class _WeekArrowButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _WeekArrowButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          child: Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: AppOpacity.borderStrong,
                ),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOngoing;

  const _StatusBadge({required this.isOngoing});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final color = isOngoing ? StatColors.tie : StatColors.win;
    final label = isOngoing
        ? loc.capitalRaidStatusOngoing
        : loc.capitalRaidStatusEnded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: AppOpacity.border)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOngoing)
            MobileWebImage(
              imageUrl: ImageAssets.swordGif,
              width: 13,
              height: 13,
            )
          else
            Icon(Icons.check_rounded, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CapitalEmptyState extends StatelessWidget {
  const _CapitalEmptyState();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: AppOpacity.borderStrong,
                ),
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
                  child: Icon(
                    Icons.location_city_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.capitalRaidEmptyTitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        loc.capitalRaidEmptyBody,
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
          const SizedBox(height: 24),
          MobileWebImage(
            imageUrl: ImageAssets.villager,
            height: 200,
            width: 160,
          ),
        ],
      ),
    );
  }
}
