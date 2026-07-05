import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_header.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_members.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_history/component/war_log_history_tab.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

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
    final clampedIndex = index > 5 ? 5 : index;
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
      2 => _ClanJoinLeaveTab(joinLeave: clanInfo.joinLeave),
      3 => _ClanRankingsTab(clanInfo: clanInfo),
      4 => const _ClanEmptyTab(
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
      length: 6,
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
        height: 48,
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
              label: 'Join/Leave',
              selected: widget.selectedIndex == 2,
            ),
            _ClanProfileTab(
              label: 'Rankings',
              selected: widget.selectedIndex == 3,
            ),
            _ClanProfileTab(
              label: loc?.warStats ?? 'War stats',
              selected: widget.selectedIndex == 4,
            ),
            _ClanProfileTab(label: 'CWL', selected: widget.selectedIndex == 5),
          ],
        ),
      ),
    );
  }
}

class _ClanJoinLeaveTab extends StatelessWidget {
  final ClanJoinLeave? joinLeave;

  const _ClanJoinLeaveTab({required this.joinLeave});

  @override
  Widget build(BuildContext context) {
    final data = joinLeave;
    if (data == null || data.stats.totalEvents == 0) {
      return const _ClanEmptyTab(
        title: 'No join/leave data',
        body:
            'Recent roster movement appears here when tracking data is loaded.',
        icon: Icons.swap_horiz_rounded,
      );
    }

    final stats = data.stats;
    final events = data.joinLeaveList.take(30).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniMetricChip(
                icon: Icons.login_rounded,
                value: stats.totalJoins.toString(),
                label: 'Joined',
                color: Colors.green,
              ),
              _MiniMetricChip(
                icon: Icons.logout_rounded,
                value: stats.totalLeaves.toString(),
                label: 'Left',
                color: Colors.redAccent,
              ),
              _MiniMetricChip(
                icon: Icons.person_search_rounded,
                value: stats.uniquePlayers.toString(),
                label: 'Unique',
              ),
              _MiniMetricChip(
                icon: Icons.repeat_rounded,
                value: stats.rejoinedPlayers.toString(),
                label: 'Rejoined',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const _ClanEmptyTab(
              title: 'No recent movement',
              body: 'The summary is loaded, but the event list is empty.',
              icon: Icons.history_toggle_off_rounded,
            )
          else
            ...events.map((event) => _JoinLeaveEventCard(event: event)),
        ],
      ),
    );
  }
}

class _JoinLeaveEventCard extends StatelessWidget {
  final JoinLeaveEvent event;

  const _JoinLeaveEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final joined = event.type.toLowerCase().contains('join');
    final accent = joined ? Colors.green : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          if (event.th > 0)
            MobileWebImage(
              imageUrl: ImageAssets.townHall(event.th),
              width: 42,
              height: 42,
            )
          else
            Icon(Icons.person_rounded, size: 34, color: colorScheme.onSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  event.tag,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    joined ? Icons.login_rounded : Icons.logout_rounded,
                    color: accent,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    joined ? 'Joined' : 'Left',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _relativeTime(event.time),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClanRankingsTab extends StatelessWidget {
  final Clan clanInfo;

  const _ClanRankingsTab({required this.clanInfo});

  @override
  Widget build(BuildContext context) {
    final totalDonated = clanInfo.memberList.fold<int>(
      0,
      (total, member) => total + member.donations,
    );
    final totalReceived = clanInfo.memberList.fold<int>(
      0,
      (total, member) => total + member.donationsReceived,
    );
    final rankings = [
      _RankingPreview(
        title: 'Donations',
        value: totalDonated,
        icon: Icons.arrow_upward_rounded,
        color: Colors.green,
        globalRank: 42,
        localRank: 3,
      ),
      _RankingPreview(
        title: 'Received',
        value: totalReceived,
        icon: Icons.arrow_downward_rounded,
        color: Colors.redAccent,
        globalRank: 98,
        localRank: 8,
      ),
      _RankingPreview(
        title: 'War wins',
        value: clanInfo.warWins,
        imageUrl: ImageAssets.sword,
        globalRank: 118,
        localRank: 7,
      ),
      _RankingPreview(
        title: 'Win streak',
        value: clanInfo.warWinStreak,
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFE35D4F),
        globalRank: 210,
        localRank: 12,
      ),
      _RankingPreview(
        title: 'Clan points',
        value: clanInfo.clanPoints,
        imageUrl: ImageAssets.trophies,
        plainValue: true,
        globalRank: 164,
        localRank: 16,
      ),
      _RankingPreview(
        title: 'Builder points',
        value: clanInfo.clanBuilderBasePoints,
        imageUrl: ImageAssets.builderBaseTrophy,
        plainValue: true,
        globalRank: 187,
        localRank: 18,
      ),
      _RankingPreview(
        title: 'Capital points',
        value: clanInfo.clanCapitalPoints,
        imageUrl: ImageAssets.capitalTrophy,
        plainValue: true,
        globalRank: 73,
        localRank: 6,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          ...rankings.map(
            (ranking) => _RankingPreviewCard(
              ranking: ranking,
              countryCode: clanInfo.location?.countryCode,
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingPreview {
  final String title;
  final int value;
  final IconData? icon;
  final String? imageUrl;
  final Color? color;
  final int globalRank;
  final int localRank;
  final bool plainValue;

  const _RankingPreview({
    required this.title,
    required this.value,
    this.icon,
    this.imageUrl,
    this.color,
    required this.globalRank,
    required this.localRank,
    this.plainValue = false,
  });
}

class _RankingPreviewCard extends StatelessWidget {
  final _RankingPreview ranking;
  final String? countryCode;

  const _RankingPreviewCard({required this.ranking, required this.countryCode});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localeName = Localizations.localeOf(context).toString();
    final decimalFormat = NumberFormat.decimalPattern(localeName);
    final value = ranking.plainValue
        ? ranking.value.toString()
        : decimalFormat.format(ranking.value);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          _RankingIcon(ranking: ranking, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _RankMetric(icon: Icons.public_rounded, rank: ranking.globalRank),
          const SizedBox(width: 12),
          _RankMetric(countryCode: countryCode, rank: ranking.localRank),
        ],
      ),
    );
  }
}

class _RankingIcon extends StatelessWidget {
  final _RankingPreview ranking;
  final double size;

  const _RankingIcon({required this.ranking, required this.size});

  @override
  Widget build(BuildContext context) {
    if (ranking.imageUrl != null) {
      return MobileWebImage(
        imageUrl: ranking.imageUrl!,
        width: size,
        height: size,
      );
    }
    return Icon(
      ranking.icon ?? Icons.leaderboard_rounded,
      size: size,
      color: ranking.color ?? Theme.of(context).colorScheme.onSurface,
    );
  }
}

class _RankMetric extends StatelessWidget {
  final IconData? icon;
  final String? countryCode;
  final int rank;

  const _RankMetric({this.icon, this.countryCode, required this.rank});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final flagUrl = countryCode == null ? null : ImageAssets.flag(countryCode!);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (flagUrl != null)
          MobileWebImage(imageUrl: flagUrl, width: 17, height: 17)
        else
          Icon(
            icon ?? Icons.flag_rounded,
            size: 17,
            color: colorScheme.onSurfaceVariant,
          ),
        const SizedBox(width: 4),
        Text(
          '#$rank',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _MiniMetricChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;

  const _MiniMetricChip({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = color ?? colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime.toLocal());
  if (difference.inDays >= 30) return '${difference.inDays ~/ 30}mo ago';
  if (difference.inDays >= 1) return '${difference.inDays}d ago';
  if (difference.inHours >= 1) return '${difference.inHours}h ago';
  if (difference.inMinutes >= 1) return '${difference.inMinutes}m ago';
  return 'now';
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
      height: 48,
      child: Center(
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
