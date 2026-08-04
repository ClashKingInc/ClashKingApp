import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_details.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_header.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_members.dart';
import 'package:clashkingapp/features/clan/presentation/clan_capital/clan_capital_raid.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
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

    if (!hasData) {
      return Scaffold(
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              ClanCapitalHeaderCard(clanInfo: widget.clanInfo),
              const SizedBox(height: 10),
              const _CapitalEmptyState(),
            ],
          ),
        ),
      );
    }

    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      body: InfoProfileTabScaffold(
        header: ClanCapitalHeaderCard(clanInfo: widget.clanInfo),
        selectedIndex: selectedTab,
        onTabSelected: _selectTab,
        alwaysScrollable: true,
        tabsTopSpacing: 10,
        tabs: [
          InfoProfileTabData(
            label: loc.generalSummary,
            icon: Icons.dashboard_rounded,
          ),
          InfoProfileTabData(
            label: loc.clanMembers,
            icon: Icons.groups_rounded,
          ),
          InfoProfileTabData(
            label: loc.generalBreakdown,
            imageUrl: ImageAssets.raidAttacks,
          ),
          InfoProfileTabData(
            label: loc.generalHistory,
            icon: Icons.bar_chart_rounded,
          ),
        ],
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
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
              KeyedSubtree(
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
            ],
          ),
        ),
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

    return AppEmptyState(
      title: loc.capitalRaidEmptyTitle,
      body: loc.capitalRaidEmptyBody,
      icon: Icons.location_city_rounded,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      stickerHeight: 200,
      stickerWidth: 160,
    );
  }
}
