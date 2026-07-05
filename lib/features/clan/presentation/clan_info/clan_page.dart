import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/inputs/filter_dropdown.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:flutter/foundation.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';
import 'package:clashkingapp/features/clan/models/cwl_ranking_history.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_header.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_members.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/clan_war_log.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/war_stats_players.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Clan detail screen: hero header + tabs for Members / War Log /
/// Join-Leave / Statistics / CWL History — content that used to live
/// behind a separate pushed screen (`ClanWarStatsScreen`) is now
/// embedded here, mirroring the player profile's tab pattern.
class ClanInfoScreen extends StatefulWidget {
  final Clan clanInfo;
  final int initialTab;

  const ClanInfoScreen({
    super.key,
    required this.clanInfo,
    this.initialTab = 0,
  });

  @override
  State<ClanInfoScreen> createState() => _ClanInfoScreenState();
}

class _ClanInfoScreenState extends State<ClanInfoScreen> {
  static const int _tabCount = 6;
  late int selectedTab;

  // Shared between the War Log and Statistics tabs so toggling a war
  // type in one is reflected in the other instead of each tab keeping
  // its own independent copy.
  bool isCWLChecked = true;
  bool isRandomChecked = true;
  bool isFriendlyChecked = true;

  List<String> get _selectedWarTypes => [
    if (isCWLChecked) 'cwl',
    if (isRandomChecked) 'random',
    if (isFriendlyChecked) 'friendly',
  ];

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab.clamp(0, _tabCount - 1);
  }

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

  void _resetWarTypeFilters() {
    setState(() {
      isCWLChecked = true;
      isRandomChecked = true;
      isFriendlyChecked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleTabSwipe,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            children: [
              ClanInfoHeaderCard(clanInfo: widget.clanInfo),
              const SizedBox(height: 10),
              _ClanProfileTabs(
                selectedIndex: selectedTab,
                onTabSelected: _selectTab,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                child: KeyedSubtree(
                  key: ValueKey(selectedTab),
                  child: switch (selectedTab) {
                    0 => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClanMembers(clanInfo: widget.clanInfo),
                    ),
                    1 => _ClanWarLogTab(
                      clan: widget.clanInfo,
                      isCWLChecked: isCWLChecked,
                      isRandomChecked: isRandomChecked,
                      isFriendlyChecked: isFriendlyChecked,
                      selectedTypes: _selectedWarTypes,
                      onCWLChanged: () =>
                          setState(() => isCWLChecked = !isCWLChecked),
                      onRandomChanged: () =>
                          setState(() => isRandomChecked = !isRandomChecked),
                      onFriendlyChanged: () => setState(
                        () => isFriendlyChecked = !isFriendlyChecked,
                      ),
                    ),
                    2 => _ClanJoinLeaveTab(
                      joinLeave: widget.clanInfo.joinLeave,
                    ),
                    3 => _ClanStatisticsTab(
                      clan: widget.clanInfo,
                      isCWLChecked: isCWLChecked,
                      isRandomChecked: isRandomChecked,
                      isFriendlyChecked: isFriendlyChecked,
                      selectedTypes: _selectedWarTypes,
                      onCWLChanged: () =>
                          setState(() => isCWLChecked = !isCWLChecked),
                      onRandomChanged: () =>
                          setState(() => isRandomChecked = !isRandomChecked),
                      onFriendlyChanged: () => setState(
                        () => isFriendlyChecked = !isFriendlyChecked,
                      ),
                      onResetWarTypes: _resetWarTypeFilters,
                    ),
                    4 => _ClanRankingsTab(clanInfo: widget.clanInfo),
                    _ => _ClanCwlHistoryTab(clan: widget.clanInfo),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClanProfileTabs extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const _ClanProfileTabs({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  State<_ClanProfileTabs> createState() => _ClanProfileTabsState();
}

class _ClanProfileTabsState extends State<_ClanProfileTabs>
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
  void didUpdateWidget(covariant _ClanProfileTabs oldWidget) {
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

    return SizedBox(
      height: 48,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const NativeLiquidGlassBar(
            height: 48,
            cornerRadius: 0,
            opacity: 0.85,
          ),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
              _ClanTab(
                label: loc.clanMembers,
                icon: Icons.groups_rounded,
                selected: widget.selectedIndex == 0,
              ),
              _ClanTab(
                label: loc.warLog,
                imageUrl: ImageAssets.war,
                selected: widget.selectedIndex == 1,
              ),
              _ClanTab(
                label: loc.clanJoinLeaveTab,
                icon: Icons.swap_horiz_rounded,
                selected: widget.selectedIndex == 2,
              ),
              _ClanTab(
                label: loc.warStats,
                icon: Icons.bar_chart_rounded,
                selected: widget.selectedIndex == 3,
              ),
              _ClanTab(
                label: loc.clanRankingsTab,
                icon: Icons.leaderboard_rounded,
                selected: widget.selectedIndex == 4,
              ),
              _ClanTab(
                label: loc.cwlHistoryTitle,
                icon: Icons.emoji_events_rounded,
                selected: widget.selectedIndex == 5,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClanTab extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final IconData? icon;
  final bool selected;

  const _ClanTab({
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

class _ClanJoinLeaveTab extends StatefulWidget {
  final ClanJoinLeave? joinLeave;

  const _ClanJoinLeaveTab({required this.joinLeave});

  @override
  State<_ClanJoinLeaveTab> createState() => _ClanJoinLeaveTabState();
}

class _ClanJoinLeaveTabState extends State<_ClanJoinLeaveTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'newest';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<JoinLeaveEvent> _filteredEvents(List<JoinLeaveEvent> events) {
    var filtered = _searchQuery.isEmpty
        ? events
        : events
              .where((event) => event.name.toLowerCase().contains(_searchQuery))
              .toList(growable: false);

    switch (_selectedFilter) {
      case 'joined':
        return filtered
            .where((event) => event.type.toLowerCase().contains('join'))
            .toList(growable: false);
      case 'left':
        return filtered
            .where((event) => !event.type.toLowerCase().contains('join'))
            .toList(growable: false);
      case 'oldest':
        return filtered.reversed.toList(growable: false);
      default:
        return filtered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final data = widget.joinLeave;
    if (data == null || data.stats.totalEvents == 0) {
      return const _ClanEmptyTab(
        title: 'No join/leave data',
        body:
            'Recent roster movement appears here when tracking data is loaded.',
        icon: Icons.swap_horiz_rounded,
      );
    }

    final stats = data.stats;
    final events = _filteredEvents(
      data.joinLeaveList.take(30).toList(growable: false),
    );

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
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NativeLiquidGlassBar(
                        height: 44,
                        cornerRadius: 22,
                        borderOpacity:
                            Theme.of(context).brightness == Brightness.dark
                            ? 0.22
                            : 0.30,
                        shadowOpacity:
                            Theme.of(context).brightness == Brightness.dark
                            ? 0.22
                            : 0.08,
                      ),
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText:
                              loc?.clanMembersSearchPlaceholder ??
                              'Search members',
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                          isDense: true,
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 44,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilterDropdown(
                sortBy: _selectedFilter,
                updateSortBy: (value) =>
                    setState(() => _selectedFilter = value),
                maxWidth: 130,
                sortByOptions: {
                  loc?.warEventsNewest ?? 'Newest': 'newest',
                  loc?.warEventsOldest ?? 'Oldest': 'oldest',
                  'Joined': 'joined',
                  'Left': 'left',
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            _ClanEmptyTab(
              title: _searchQuery.isNotEmpty
                  ? (loc?.generalNoFilteredResults ??
                        'No results match your filters')
                  : 'No recent movement',
              body: _searchQuery.isNotEmpty
                  ? ''
                  : 'The summary is loaded, but the event list is empty.',
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

  const _RankingPreviewCard({
    required this.ranking,
    required this.countryCode,
  });

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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
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
    final flagUrl = countryCode == null
        ? null
        : ImageAssets.flag(countryCode!);

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

String _relativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime.toLocal());
  if (difference.inDays >= 30) return '${difference.inDays ~/ 30}mo ago';
  if (difference.inDays >= 1) return '${difference.inDays}d ago';
  if (difference.inHours >= 1) return '${difference.inHours}h ago';
  if (difference.inMinutes >= 1) return '${difference.inMinutes}m ago';
  return 'now';
}

/// Compact CWL/Random/Friendly war-type filter, shared visual recipe
/// used by both the War Log and Statistics tabs (each owns its own
/// copy of this small state independently).
/// Single-row filter bar: chips scroll horizontally on the left, a
/// fixed trailing control (sort dropdown, optionally + overflow menu)
/// stays pinned on the right — replaces two stacked rows with
/// different alignment/density.
/// Filter bar: a toggle button reveals the war-type chips on demand
/// instead of always taking row space, leaving room for the trailing
/// controls (sort, plus per-tab actions) to stay as visible icons
/// instead of hiding behind an overflow menu.
class _FilterBar extends StatefulWidget {
  final List<Widget> chips;
  final Widget trailing;
  final Widget? middle;

  const _FilterBar({required this.chips, required this.trailing, this.middle});

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.chip),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Container(
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _expanded
                          ? colorScheme.primary.withValues(alpha: 0.14)
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.45,
                            ),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(
                        color: _expanded
                            ? colorScheme.primary.withValues(alpha: 0.4)
                            : colorScheme.outlineVariant.withValues(
                                alpha: 0.32,
                              ),
                      ),
                    ),
                    // Always onSurface, never the tint, for the same
                    // contrast reason as the chip labels below.
                    child: Icon(
                      LucideIcons.listFilter,
                      size: 18,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: widget.middle == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.center,
                        child: widget.middle,
                      ),
              ),
              widget.trailing,
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topLeft,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.chips,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Small bordered icon pill matching the filter bar's visual language,
/// for secondary per-tab actions (TH visibility, reset) that now have
/// room to stay visible instead of hiding in an overflow menu.
class _IconPillButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconPillButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          child: Container(
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            child: Icon(icon, size: 18, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// Small glass toggle pill — icon-in-circle + label, same visual family
/// as MetricChip/the reskinned chip.dart, tinted with the theme primary
/// when selected instead of Material's default checkmark FilterChip.
class _FilterPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.icon,
    this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tint = selected ? colorScheme.primary : null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.chip),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
          decoration: BoxDecoration(
            color: tint != null
                ? tint.withValues(alpha: 0.14)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color:
                  tint?.withValues(alpha: 0.4) ??
                  colorScheme.outlineVariant.withValues(alpha: 0.32),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  // Solid tint fill (not translucent) so a white icon on
                  // top always clears contrast — unlike coloring small
                  // text/icons with the tint directly, which this app's
                  // dark-red primary fails against a dark surface.
                  color: tint ?? colorScheme.surface.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: imageUrl != null
                        ? MobileWebImage(imageUrl: imageUrl!)
                        : Icon(
                            icon,
                            size: 14,
                            color: tint != null
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  // Always onSurface — never the tint — so selected
                  // labels stay readable regardless of theme contrast.
                  color: colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClanWarLogTab extends StatefulWidget {
  final Clan clan;
  final bool isCWLChecked;
  final bool isRandomChecked;
  final bool isFriendlyChecked;
  final List<String> selectedTypes;
  final VoidCallback onCWLChanged;
  final VoidCallback onRandomChanged;
  final VoidCallback onFriendlyChanged;

  const _ClanWarLogTab({
    required this.clan,
    required this.isCWLChecked,
    required this.isRandomChecked,
    required this.isFriendlyChecked,
    required this.selectedTypes,
    required this.onCWLChanged,
    required this.onRandomChanged,
    required this.onFriendlyChanged,
  });

  @override
  State<_ClanWarLogTab> createState() => _ClanWarLogTabState();
}

class _ClanWarLogTabState extends State<_ClanWarLogTab> {
  String? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        _FilterBar(
          chips: [
            _FilterPill(
              label: loc.cwlTitle,
              imageUrl: ImageAssets.cwlSwordsNoBorder,
              selected: widget.isCWLChecked,
              onTap: widget.onCWLChanged,
            ),
            _FilterPill(
              label: loc.warFiltersRandom,
              icon: LucideIcons.shuffle,
              selected: widget.isRandomChecked,
              onTap: widget.onRandomChanged,
            ),
            _FilterPill(
              label: loc.warFiltersFriendly,
              icon: LucideIcons.handshake,
              selected: widget.isFriendlyChecked,
              onTap: widget.onFriendlyChanged,
            ),
          ],
          trailing: FilterDropdown(
            sortBy: _selectedFilter ?? 'newest',
            updateSortBy: (value) => setState(() => _selectedFilter = value),
            maxWidth: 130,
            sortByOptions: {
              loc.warEventsNewest: 'newest',
              loc.warEventsOldest: 'oldest',
              loc.warVictory: 'victory',
              loc.warDefeat: 'defeat',
              loc.warDraw: 'draw',
              loc.warPerfectWar: 'perfectWar',
              '5v5': '5',
              '10v10': '10',
              '15v15': '15',
              '20v20': '20',
              '25v25': '25',
              '30v30': '30',
              '40v40': '40',
              '50v50': '50',
            },
          ),
          middle: WarLogSummary(clan: widget.clan),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: ClanWarLog(
            clan: widget.clan,
            selectedTypes: widget.selectedTypes,
            selectedFilter: _selectedFilter,
          ),
        ),
      ],
    );
  }
}

class _ClanStatisticsTab extends StatefulWidget {
  final Clan clan;
  final bool isCWLChecked;
  final bool isRandomChecked;
  final bool isFriendlyChecked;
  final List<String> selectedTypes;
  final VoidCallback onCWLChanged;
  final VoidCallback onRandomChanged;
  final VoidCallback onFriendlyChanged;
  final VoidCallback onResetWarTypes;

  const _ClanStatisticsTab({
    required this.clan,
    required this.isCWLChecked,
    required this.isRandomChecked,
    required this.isFriendlyChecked,
    required this.selectedTypes,
    required this.onCWLChanged,
    required this.onRandomChanged,
    required this.onFriendlyChanged,
    required this.onResetWarTypes,
  });

  @override
  State<_ClanStatisticsTab> createState() => _ClanStatisticsTabState();
}

class _ClanStatisticsTabState extends State<_ClanStatisticsTab> {
  String _sortBy = 'Three Stars Attacks';
  bool showUppedTownHall = true;
  bool _isLoadingStats = false;
  late List<PlayerWarStats> filteredPlayers;

  @override
  void initState() {
    super.initState();
    filteredPlayers = widget.clan.clanWarStats?.players ?? [];
    if (widget.clan.clanWarStats == null) {
      _loadStats();
    }
  }

  @override
  void didUpdateWidget(covariant _ClanStatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The war-type filter lives in the parent (shared with the War Log
    // tab); react to it changing instead of assuming setState above
    // synchronously updates our own widget.selectedTypes.
    if (!listEquals(oldWidget.selectedTypes, widget.selectedTypes)) {
      setState(_sortMembers);
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final clanService = context.read<ClanService>();
      await clanService.loadClanWarStatsData([widget.clan.tag]);
      clanService.linkWarStatsToClans();
    } catch (_) {
      // Keep showing the (possibly empty) stats we already have.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
          filteredPlayers = widget.clan.clanWarStats?.players ?? [];
        });
      }
    }
  }

  void _toggleTownHallVisibility() {
    setState(() => showUppedTownHall = !showUppedTownHall);
  }

  void _updateSortBy(String newValue) {
    setState(() {
      _sortBy = newValue;
      _sortMembers();
    });
  }

  void _resetFilters() {
    widget.onResetWarTypes();
    setState(() {
      showUppedTownHall = true;
      filteredPlayers = widget.clan.clanWarStats?.players ?? [];
    });
  }

  void _sortMembers() {
    final selectedTypes = widget.selectedTypes;
    final allPlayers = widget.clan.clanWarStats?.players ?? [];
    final playersByTag = {
      for (var player in filteredPlayers) player.tag: player,
    };

    filteredPlayers = allPlayers
        .where((member) => playersByTag.containsKey(member.tag))
        .toList();

    double statFor(PlayerWarStats player) {
      final stats = player.getStatsForTypes(selectedTypes);
      return switch (_sortBy) {
        'Average Destruction' => stats.averageDestruction,
        'Average Stars' => stats.averageStars,
        'No Star Attacks' => (stats.starsCount['0'] ?? 0).toDouble(),
        'One Star Attacks' => (stats.starsCount['1'] ?? 0).toDouble(),
        'Two Stars Attacks' => (stats.starsCount['2'] ?? 0).toDouble(),
        'Three Stars Attacks' => (stats.starsCount['3'] ?? 0).toDouble(),
        'War Participation' => stats.warsCounts.toDouble(),
        'Missed Attacks' => stats.missedAttacks.toDouble(),
        _ => 0.0,
      };
    }

    filteredPlayers.sort((a, b) => statFor(b).compareTo(statFor(a)));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        _FilterBar(
          chips: [
            _FilterPill(
              label: loc.cwlTitle,
              imageUrl: ImageAssets.cwlSwordsNoBorder,
              selected: widget.isCWLChecked,
              onTap: widget.onCWLChanged,
            ),
            _FilterPill(
              label: loc.warFiltersRandom,
              icon: LucideIcons.shuffle,
              selected: widget.isRandomChecked,
              onTap: widget.onRandomChanged,
            ),
            _FilterPill(
              label: loc.warFiltersFriendly,
              icon: LucideIcons.handshake,
              selected: widget.isFriendlyChecked,
              onTap: widget.onFriendlyChanged,
            ),
          ],
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilterDropdown(
                sortBy: _sortBy,
                updateSortBy: _updateSortBy,
                maxWidth: 130,
                sortByOptions: {
                  loc.warStarsThree: "Three Stars Attacks",
                  loc.warStarsTwo: "Two Stars Attacks",
                  loc.warStarsOne: "One Star Attacks",
                  loc.warStarsZero: "No Star Attacks",
                  loc.warDestructionAverage: "Average Destruction",
                  loc.warStarsAverage: "Average Stars",
                  loc.warParticipation: "War Participation",
                  loc.warAttacksMissed: "Missed Attacks",
                },
              ),
              const SizedBox(width: 8),
              _IconPillButton(
                icon: showUppedTownHall ? LucideIcons.eyeOff : LucideIcons.eye,
                tooltip: loc.warVisibilityToggleTownHall,
                onTap: _toggleTownHallVisibility,
              ),
              const SizedBox(width: 8),
              _IconPillButton(
                icon: LucideIcons.listRestart,
                tooltip: loc.generalReset,
                onTap: _resetFilters,
              ),
            ],
          ),
        ),
        if (_isLoadingStats)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Padding(
            padding: const EdgeInsets.all(8),
            child: ClanWarStatsPlayers(
              clan: widget.clan,
              showUppedTownHall: showUppedTownHall,
              sortBy: _sortBy,
              selectedTypes: widget.selectedTypes,
              filteredPlayers: filteredPlayers,
              allPlayers: (widget.clan.clanWarStats?.players ?? [])
                  .map((player) => player.tag)
                  .toList(),
              resetFilters: _resetFilters,
              attackerThFilter: const [],
              defenderThFilter: const [],
              equalThSelected: false,
            ),
          ),
      ],
    );
  }
}

/// Compact overflow menu for the two secondary Statistics-tab actions
/// (TH visibility toggle, reset) so the filter bar's trailing slot
/// stays to one control (sort) instead of three floating icon pills.
class _ClanCwlHistoryTab extends StatefulWidget {
  final Clan clan;

  const _ClanCwlHistoryTab({required this.clan});

  @override
  State<_ClanCwlHistoryTab> createState() => _ClanCwlHistoryTabState();
}

class _ClanCwlHistoryTabState extends State<_ClanCwlHistoryTab> {
  late final Future<List<CwlRankingHistoryEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ClanService>().getCwlRankingHistory(widget.clan.tag);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: FutureBuilder<List<CwlRankingHistoryEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return _EmptyCwlHistory();
          }

          return Column(
            children: entries
                .map((entry) => _CwlHistoryCard(entry: entry))
                .toList(),
          );
        },
      ),
    );
  }
}

class _EmptyCwlHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            loc.cwlHistoryEmptyTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            loc.cwlHistoryEmptyBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CwlHistoryCard extends StatelessWidget {
  final CwlRankingHistoryEntry entry;

  const _CwlHistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#${entry.rank}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.season,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (entry.league != null && entry.league!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    entry.league!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.roundsWon}W · ${entry.roundsTied}T · ${entry.roundsLost}L',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${entry.stars}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${entry.destruction.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
