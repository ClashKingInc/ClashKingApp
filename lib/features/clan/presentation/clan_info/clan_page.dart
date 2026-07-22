import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/info_profile_tabs.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/responsive_card_grid.dart';
import 'package:clashkingapp/common/widgets/search_sort_bar.dart';
import 'package:clashkingapp/common/widgets/summary_chips.dart';
import 'package:flutter/foundation.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';
import 'package:clashkingapp/features/clan/models/clan_war_stats_filter.dart';
import 'package:clashkingapp/features/clan/models/cwl_ranking_history.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_header.dart';
import 'package:clashkingapp/features/clan/presentation/clan_info/clan_members.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/clan_war_log.dart';
import 'package:clashkingapp/features/war_cwl/presentation/war_stats/war_stats_players.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/config/app_feature_flags.dart';

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
    selectedTab = widget.initialTab.clamp(0, 5);
  }

  void _selectTab(int index, int tabCount) {
    final bounded = index.clamp(0, tabCount - 1);
    if (bounded == selectedTab) return;
    setState(() => selectedTab = bounded);
  }

  void _handleTabSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 240) return;
    final tabCount = _visibleTabs(context).length;
    if (velocity < 0) {
      _selectTab(selectedTab + 1, tabCount);
    } else {
      _selectTab(selectedTab - 1, tabCount);
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
    final visibleTabs = _visibleTabs(context);
    final activeIndex = selectedTab.clamp(0, visibleTabs.length - 1);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _handleTabSwipe,
        child: NestedScrollView(
          physics: _NoImplicitScrollPhysics(
            parent: ScrollConfiguration.of(context).getScrollPhysics(context),
          ),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: ClanInfoHeaderCard(clanInfo: widget.clanInfo),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  InfoProfileTabs(
                    selectedIndex: activeIndex,
                    onTabSelected: (index) =>
                        _selectTab(index, visibleTabs.length),
                    alwaysScrollable: true,
                    tabs: visibleTabs
                        .map((tab) => tab.data(AppLocalizations.of(context)!))
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ],
          body: KeyedSubtree(
            key: ValueKey(visibleTabs[activeIndex]),
            child: _buildSelectedTab(context, visibleTabs[activeIndex]),
          ),
        ),
      ),
    );
  }

  List<_ClanInfoTab> _visibleTabs(BuildContext context) {
    final appState = context.watch<MyAppState>();
    return [
      _ClanInfoTab.members,
      _ClanInfoTab.warLog,
      _ClanInfoTab.joinLeave,
      _ClanInfoTab.statistics,
      if (appState.isFeatureEnabled(AppFeatureFlags.clanRankingsPreview))
        _ClanInfoTab.rankings,
      if (appState.isFeatureEnabled(AppFeatureFlags.cwlHistoryPreview))
        _ClanInfoTab.cwlHistory,
    ];
  }

  Widget _buildSelectedTab(BuildContext context, _ClanInfoTab tab) {
    if (tab == _ClanInfoTab.members) {
      return ClanMembers(clanInfo: widget.clanInfo);
    }

    final content = switch (tab) {
      _ClanInfoTab.warLog => _ClanWarLogTab(
        clan: widget.clanInfo,
        isCWLChecked: isCWLChecked,
        isRandomChecked: isRandomChecked,
        isFriendlyChecked: isFriendlyChecked,
        selectedTypes: _selectedWarTypes,
        onCWLChanged: () => setState(() => isCWLChecked = !isCWLChecked),
        onRandomChanged: () =>
            setState(() => isRandomChecked = !isRandomChecked),
        onFriendlyChanged: () =>
            setState(() => isFriendlyChecked = !isFriendlyChecked),
      ),
      _ClanInfoTab.joinLeave => _ClanJoinLeaveTab(
        joinLeave: widget.clanInfo.joinLeave,
      ),
      _ClanInfoTab.statistics => _ClanStatisticsTab(
        clan: widget.clanInfo,
        isCWLChecked: isCWLChecked,
        isRandomChecked: isRandomChecked,
        isFriendlyChecked: isFriendlyChecked,
        selectedTypes: _selectedWarTypes,
        onCWLChanged: () => setState(() => isCWLChecked = !isCWLChecked),
        onRandomChanged: () =>
            setState(() => isRandomChecked = !isRandomChecked),
        onFriendlyChanged: () =>
            setState(() => isFriendlyChecked = !isFriendlyChecked),
        onResetWarTypes: _resetWarTypeFilters,
      ),
      _ClanInfoTab.rankings => _ClanRankingsTab(clanInfo: widget.clanInfo),
      _ClanInfoTab.cwlHistory => _ClanCwlHistoryTab(clan: widget.clanInfo),
      _ClanInfoTab.members => const SizedBox.shrink(),
    };

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: 16 + MediaQuery.paddingOf(context).bottom,
      ),
      child: content,
    );
  }
}

enum _ClanInfoTab {
  members,
  warLog,
  joinLeave,
  statistics,
  rankings,
  cwlHistory,
}

extension on _ClanInfoTab {
  InfoProfileTabData data(AppLocalizations l10n) => switch (this) {
    _ClanInfoTab.members => InfoProfileTabData(
      label: l10n.clanMembers,
      icon: Icons.groups_rounded,
    ),
    _ClanInfoTab.warLog => InfoProfileTabData(
      label: l10n.warLog,
      imageUrl: ImageAssets.war,
    ),
    _ClanInfoTab.joinLeave => InfoProfileTabData(
      label: l10n.clanJoinLeaveTab,
      icon: Icons.swap_horiz_rounded,
    ),
    _ClanInfoTab.statistics => InfoProfileTabData(
      label: l10n.warStats,
      icon: Icons.bar_chart_rounded,
    ),
    _ClanInfoTab.rankings => InfoProfileTabData(
      label: l10n.clanRankingsTab,
      icon: Icons.leaderboard_rounded,
    ),
    _ClanInfoTab.cwlHistory => InfoProfileTabData(
      label: l10n.cwlHistoryTitle,
      icon: Icons.emoji_events_rounded,
    ),
  };
}

class _NoImplicitScrollPhysics extends ScrollPhysics {
  const _NoImplicitScrollPhysics({super.parent});

  @override
  _NoImplicitScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _NoImplicitScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool get allowImplicitScrolling => false;
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
  String _selectedSort = 'newest';
  String _selectedMovement = 'all';

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

    switch (_selectedMovement) {
      case 'joined':
        filtered = filtered
            .where((event) => event.type.toLowerCase().contains('join'))
            .toList(growable: false);
        break;
      case 'left':
        filtered = filtered
            .where((event) => !event.type.toLowerCase().contains('join'))
            .toList(growable: false);
        break;
    }

    switch (_selectedSort) {
      case 'oldest':
        return filtered.reversed.toList(growable: false);
      default:
        return filtered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final data = widget.joinLeave ?? ClanJoinLeave.empty();
    final stats = data.stats;
    final events = _filteredEvents(
      data.joinLeaveList.take(30).toList(growable: false),
    );
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          ClanTabSearchSortBar(
            controller: _searchController,
            query: _searchQuery,
            hintText: loc?.clanMembersSearchPlaceholder ?? 'Search members',
            sortBy: _selectedSort,
            updateSortBy: (value) => setState(() => _selectedSort = value),
            maxSortWidth: 130,
            padding: EdgeInsets.zero,
            sortByOptions: {
              loc?.warEventsNewest ?? 'Newest': 'newest',
              loc?.warEventsOldest ?? 'Oldest': 'oldest',
            },
          ),
          const SizedBox(height: 8),
          _FilterBar(
            trailing: const SizedBox.shrink(),
            padding: EdgeInsets.zero,
            middle: ClanSummaryChips(
              padding: EdgeInsets.zero,
              children: [
                ClanSummaryChip(
                  icon: Icons.login_rounded,
                  value: stats.totalJoins.toString(),
                  label: loc?.joinLeaveJoins ?? 'Joins',
                  color: Colors.green,
                ),
                ClanSummaryChip(
                  icon: Icons.logout_rounded,
                  value: stats.totalLeaves.toString(),
                  label: loc?.joinLeaveLeaves ?? 'Leaves',
                  color: Colors.redAccent,
                ),
                ClanSummaryChip(
                  icon: Icons.person_search_rounded,
                  value: stats.uniquePlayers.toString(),
                  label: loc?.joinLeaveUniquePlayers ?? 'Unique Players',
                ),
                ClanSummaryChip(
                  icon: Icons.repeat_rounded,
                  value: stats.rejoinedPlayers.toString(),
                  label: loc?.joinLeaveRejoinedPlayers ?? 'Rejoined Players',
                ),
              ],
            ),
            chips: [
              _FilterPill(
                icon: Icons.all_inclusive_rounded,
                label: loc?.generalAll ?? 'All',
                selected: _selectedMovement == 'all',
                onTap: () => setState(() => _selectedMovement = 'all'),
              ),
              _FilterPill(
                icon: Icons.login_rounded,
                label: loc?.joinLeaveJoin ?? 'Join',
                selected: _selectedMovement == 'joined',
                color: Colors.green,
                onTap: () => setState(() => _selectedMovement = 'joined'),
              ),
              _FilterPill(
                icon: Icons.logout_rounded,
                label: loc?.joinLeaveLeave ?? 'Leave',
                selected: _selectedMovement == 'left',
                color: Colors.redAccent,
                onTap: () => setState(() => _selectedMovement = 'left'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            _ClanEmptyTab(
              title: _searchQuery.isNotEmpty || _selectedMovement != 'all'
                  ? (loc?.generalNoFilteredResults ??
                        'No results match your filters')
                  : stats.totalEvents == 0
                  ? loc!.clanJoinLeaveNoDataTitle
                  : loc!.clanJoinLeaveNoRecentMovementTitle,
              body: _searchQuery.isNotEmpty || _selectedMovement != 'all'
                  ? ''
                  : stats.totalEvents == 0
                  ? loc!.clanJoinLeaveNoDataBody
                  : loc!.clanJoinLeaveNoRecentMovementBody,
              icon: Icons.history_toggle_off_rounded,
            )
          else
            isDesktopWeb
                ? ResponsiveCardGrid(
                    itemCount: events.length,
                    minItemWidth: 340,
                    maxColumns: 3,
                    spacing: 10,
                    itemBuilder: (_, index) => _JoinLeaveEventCard(
                      event: events[index],
                      margin: EdgeInsets.zero,
                    ),
                  )
                : Column(
                    children: events
                        .map((event) => _JoinLeaveEventCard(event: event))
                        .toList(growable: false),
                  ),
        ],
      ),
    );
  }
}

class _JoinLeaveEventCard extends StatelessWidget {
  final JoinLeaveEvent event;
  final EdgeInsetsGeometry margin;

  const _JoinLeaveEventCard({
    required this.event,
    this.margin = const EdgeInsets.only(bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final joined = event.type.toLowerCase().contains('join');
    final accent = joined ? Colors.green : Colors.redAccent;

    return Container(
      margin: margin,
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
                    joined
                        ? (AppLocalizations.of(context)?.joinLeaveJoin ??
                              'Join')
                        : (AppLocalizations.of(context)?.joinLeaveLeave ??
                              'Leave'),
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

class _ClanRankingsTab extends StatefulWidget {
  final Clan clanInfo;

  const _ClanRankingsTab({required this.clanInfo});

  @override
  State<_ClanRankingsTab> createState() => _ClanRankingsTabState();
}

class _ClanRankingsTabState extends State<_ClanRankingsTab> {
  static final DateTime _mockCurrentSeason = DateTime(2026, 7);

  DateTime _selectedSeason = _mockCurrentSeason;
  String _selectedRankingFilter = 'all';

  Future<void> _pickSeason() async {
    final now = DateTime.now();
    final latestDate = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedSeason.isAfter(latestDate)
          ? latestDate
          : _selectedSeason,
      firstDate: DateTime(2020),
      lastDate: latestDate,
      initialDatePickerMode: DatePickerMode.year,
      helpText:
          AppLocalizations.of(context)?.clanRankingsSelectSeason ??
          'Select ranking season',
    );

    if (picked == null) return;
    setState(() => _selectedSeason = DateTime(picked.year, picked.month));
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final seasonLabel = DateFormat.yMMMM(localeName).format(_selectedSeason);
    final totalDonated = widget.clanInfo.memberList.fold<int>(
      0,
      (total, member) => total + member.donations,
    );
    final totalReceived = widget.clanInfo.memberList.fold<int>(
      0,
      (total, member) => total + member.donationsReceived,
    );
    final rawSeasonOffset =
        (_mockCurrentSeason.year - _selectedSeason.year) * 12 +
        _mockCurrentSeason.month -
        _selectedSeason.month;
    final seasonOffset = rawSeasonOffset < 0
        ? 0
        : rawSeasonOffset > 24
        ? 24
        : rawSeasonOffset;
    final rankShift = seasonOffset * 7;

    // TODO: Replace these preview ranks with real ranking data when the
    // backend exposes clan ranking endpoints for the app.
    // TODO: Replace the mock calendar month with API-backed ranking seasons.
    final rankings = [
      _RankingPreview(
        title: loc.gameDonations,
        value: totalDonated,
        icon: Icons.arrow_upward_rounded,
        color: Colors.green,
        category: 'activity',
        globalRank: 42 + rankShift,
        localRank: 3 + seasonOffset,
      ),
      _RankingPreview(
        title: loc.gameDonationsReceived,
        value: totalReceived,
        icon: Icons.arrow_downward_rounded,
        color: Colors.redAccent,
        category: 'activity',
        globalRank: 98 + rankShift,
        localRank: 8 + seasonOffset,
      ),
      _RankingPreview(
        title: loc.warWinsTitle,
        value: widget.clanInfo.warWins,
        imageUrl: ImageAssets.sword,
        category: 'war',
        globalRank: 118 + rankShift,
        localRank: 7 + seasonOffset,
      ),
      _RankingPreview(
        title: loc.clanWinStreakTitle,
        value: widget.clanInfo.warWinStreak,
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFE35D4F),
        category: 'war',
        globalRank: 210 + rankShift,
        localRank: 12 + seasonOffset,
      ),
      _RankingPreview(
        title: loc.clanPointsTitle,
        value: widget.clanInfo.clanPoints,
        imageUrl: ImageAssets.trophies,
        plainValue: true,
        category: 'points',
        globalRank: 164 + rankShift,
        localRank: 16 + seasonOffset,
      ),
      _RankingPreview(
        title: loc.clanBuilderBasePoints,
        value: widget.clanInfo.clanBuilderBasePoints,
        imageUrl: ImageAssets.builderBaseTrophy,
        plainValue: true,
        category: 'points',
        globalRank: 187 + rankShift,
        localRank: 18 + seasonOffset,
      ),
      _RankingPreview(
        title: loc.clanCapitalPoints,
        value: widget.clanInfo.clanCapitalPoints,
        imageUrl: ImageAssets.capitalTrophy,
        plainValue: true,
        category: 'points',
        globalRank: 73 + rankShift,
        localRank: 6 + seasonOffset,
      ),
    ];
    final visibleRankings = _selectedRankingFilter == 'all'
        ? rankings
        : rankings
              .where((ranking) => ranking.category == _selectedRankingFilter)
              .toList(growable: false);
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          _FilterBar(
            padding: EdgeInsets.zero,
            trailing: const SizedBox.shrink(),
            actions: [
              _FilterActionButton(
                tooltip:
                    AppLocalizations.of(context)?.clanRankingsSelectSeason ??
                    'Select ranking season',
                icon: Icons.calendar_month_rounded,
                onTap: _pickSeason,
              ),
            ],
            middle: ClanSummaryChips(
              padding: EdgeInsets.zero,
              children: [
                ClanSummaryChip(
                  icon: Icons.calendar_month_rounded,
                  value: seasonLabel,
                  label:
                      AppLocalizations.of(context)?.clanRankingsSeason ??
                      'Season',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            chips: [
              _FilterPill(
                label: AppLocalizations.of(context)?.generalAll ?? 'All',
                icon: Icons.all_inclusive_rounded,
                selected: _selectedRankingFilter == 'all',
                onTap: () => setState(() => _selectedRankingFilter = 'all'),
              ),
              _FilterPill(
                label:
                    AppLocalizations.of(context)?.clanRankingsFilterActivity ??
                    'Activity',
                icon: Icons.swap_vert_rounded,
                selected: _selectedRankingFilter == 'activity',
                onTap: () =>
                    setState(() => _selectedRankingFilter = 'activity'),
              ),
              _FilterPill(
                label:
                    AppLocalizations.of(context)?.clanRankingsFilterWar ??
                    'War',
                imageUrl: ImageAssets.sword,
                selected: _selectedRankingFilter == 'war',
                onTap: () => setState(() => _selectedRankingFilter = 'war'),
              ),
              _FilterPill(
                label:
                    AppLocalizations.of(context)?.clanRankingsFilterPoints ??
                    'Points',
                imageUrl: ImageAssets.trophies,
                selected: _selectedRankingFilter == 'points',
                onTap: () => setState(() => _selectedRankingFilter = 'points'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          isDesktopWeb
              ? ResponsiveCardGrid(
                  itemCount: visibleRankings.length,
                  minItemWidth: 340,
                  maxColumns: 3,
                  spacing: 10,
                  itemBuilder: (_, index) => _RankingPreviewCard(
                    ranking: visibleRankings[index],
                    countryCode: widget.clanInfo.location?.countryCode,
                    margin: EdgeInsets.zero,
                  ),
                )
              : Column(
                  children: visibleRankings
                      .map(
                        (ranking) => _RankingPreviewCard(
                          ranking: ranking,
                          countryCode: widget.clanInfo.location?.countryCode,
                        ),
                      )
                      .toList(growable: false),
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
  final String category;
  final int globalRank;
  final int localRank;
  final bool plainValue;

  const _RankingPreview({
    required this.title,
    required this.value,
    this.icon,
    this.imageUrl,
    this.color,
    required this.category,
    required this.globalRank,
    required this.localRank,
    this.plainValue = false,
  });
}

class _RankingPreviewCard extends StatelessWidget {
  final _RankingPreview ranking;
  final String? countryCode;
  final EdgeInsetsGeometry margin;

  const _RankingPreviewCard({
    required this.ranking,
    required this.countryCode,
    this.margin = const EdgeInsets.only(bottom: 8),
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
      margin: margin,
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
    return AppEmptyState(
      title: title,
      body: body,
      icon: icon,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;

  const _FilterBar({
    required this.chips,
    required this.trailing,
    this.middle,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: widget.padding,
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
                      Icons.filter_list_rounded,
                      size: 18,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              for (final action in widget.actions) ...[
                const SizedBox(width: 8),
                action,
              ],
              const SizedBox(width: 8),
              Expanded(
                child: widget.middle == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.centerLeft,
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

class _FilterActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterActionButton({
    required this.tooltip,
    required this.icon,
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
  final Color? color;

  const _FilterPill({
    required this.label,
    this.icon,
    this.imageUrl,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = color ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        splashFactory: NoSplash.splashFactory,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.16)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.42)
                  : colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imageUrl != null) ...[
                MobileWebImage(imageUrl: imageUrl!, height: 15, width: 15),
                const SizedBox(width: 5),
              ] else if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? accent : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  height: 1,
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      children: [
        ClanTabSearchSortBar(
          controller: _searchController,
          query: _searchQuery,
          hintText: loc.warLogSearchPlaceholder,
          sortBy: _selectedFilter ?? 'newest',
          updateSortBy: (value) => setState(() => _selectedFilter = value),
          maxSortWidth: 130,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
              icon: Icons.shuffle_rounded,
              selected: widget.isRandomChecked,
              onTap: widget.onRandomChanged,
            ),
            _FilterPill(
              label: loc.warFiltersFriendly,
              icon: Icons.handshake_rounded,
              selected: widget.isFriendlyChecked,
              onTap: widget.onFriendlyChanged,
            ),
          ],
          trailing: const SizedBox.shrink(),
          middle: WarLogSummary(clan: widget.clan),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ClanWarLog(
            clan: widget.clan,
            selectedTypes: widget.selectedTypes,
            selectedFilter: _selectedFilter,
            searchQuery: _searchQuery,
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
  DateTime? _selectedStatsSeason;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<PlayerWarStats> _periodPlayers;
  late List<PlayerWarStats> filteredPlayers;

  @override
  void initState() {
    super.initState();
    _periodPlayers = widget.clan.clanWarStats?.players ?? [];
    filteredPlayers = _periodPlayers;
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
    if (widget.clan.clanWarStats == null) {
      _loadDefaultStats();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadDefaultStats() async {
    setState(() => _isLoadingStats = true);
    List<PlayerWarStats>? loadedPlayers;
    try {
      final clanService = context.read<ClanService>();
      final statsList = await clanService.loadClanWarStatsData([
        widget.clan.tag,
      ]);
      for (final stats in statsList) {
        if (stats.clanTag == widget.clan.tag) {
          widget.clan.clanWarStats = stats;
          loadedPlayers = stats.players;
          break;
        }
      }
      loadedPlayers ??= widget.clan.clanWarStats?.players ?? [];
    } catch (_) {
      // Keep showing the (possibly empty) stats we already have.
    } finally {
      if (mounted) {
        setState(() {
          if (loadedPlayers != null) {
            _periodPlayers = loadedPlayers;
            filteredPlayers = _periodPlayers;
            _sortMembers();
          }
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadStatsForSelectedSeason() async {
    setState(() => _isLoadingStats = true);
    List<PlayerWarStats>? loadedPlayers;
    try {
      final clanService = context.read<ClanService>();
      final stats = await clanService.loadClanWarStatsWithFilter(
        widget.clan.tag,
        ClanWarStatsFilter(
          startDate: _statsSeasonStart,
          endDate: _statsSeasonEnd,
          limit: 200,
        ),
      );
      loadedPlayers = stats?.players ?? [];
    } catch (_) {
      // Keep showing the (possibly empty) stats we already have.
    } finally {
      if (mounted) {
        setState(() {
          if (loadedPlayers != null) {
            _periodPlayers = loadedPlayers;
            filteredPlayers = _periodPlayers;
            _sortMembers();
          }
          _isLoadingStats = false;
        });
      }
    }
  }

  DateTime get _statsSeasonStart =>
      DateTime(_selectedStatsSeason!.year, _selectedStatsSeason!.month);

  DateTime get _statsSeasonEnd => DateTime(
    _selectedStatsSeason!.year,
    _selectedStatsSeason!.month + 1,
    1,
  ).subtract(const Duration(seconds: 1));

  Future<void> _pickStatsSeason() async {
    final now = DateTime.now();
    final latestDate = DateTime(now.year, now.month, now.day);
    final initialSeason = _selectedStatsSeason ?? DateTime(now.year, now.month);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialSeason.isAfter(latestDate)
          ? latestDate
          : initialSeason,
      firstDate: DateTime(2020),
      lastDate: latestDate,
      initialDatePickerMode: DatePickerMode.year,
      helpText:
          AppLocalizations.of(context)?.warStatsSelectSeason ??
          'Select war stats season',
    );

    if (!mounted || picked == null) return;

    final selectedMonth = DateTime(picked.year, picked.month);
    if (selectedMonth == _selectedStatsSeason) return;

    setState(() => _selectedStatsSeason = selectedMonth);
    await _loadStatsForSelectedSeason();
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
    _searchController.clear();
    setState(() {
      _selectedStatsSeason = null;
      showUppedTownHall = true;
      _periodPlayers = widget.clan.clanWarStats?.players ?? _periodPlayers;
      filteredPlayers = _periodPlayers;
    });
  }

  void _sortMembers() {
    final selectedTypes = widget.selectedTypes;
    final allPlayers = _periodPlayers;
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

  List<PlayerWarStats> _displayedPlayers() {
    if (_searchQuery.isEmpty) return filteredPlayers;
    return filteredPlayers
        .where(
          (player) =>
              player.name.toLowerCase().contains(_searchQuery) ||
              player.tag.toLowerCase().contains(_searchQuery),
        )
        .toList(growable: false);
  }

  _WarStatsOverview _overviewFor(List<PlayerWarStats> players) {
    var activePlayers = 0;
    var totalAttacks = 0;
    var totalStars = 0;
    var missedAttacks = 0;
    var weightedDestruction = 0.0;

    for (final player in players) {
      final stats = player.getStatsForTypes(widget.selectedTypes);
      final starsCount = showUppedTownHall
          ? stats.starsCount
          : stats.getStarsCountAgainstTh(player.townhallLevel);
      final attacks = starsCount.values.fold<int>(
        0,
        (total, count) => total + count,
      );
      if (attacks == 0) continue;

      activePlayers += 1;
      totalAttacks += attacks;
      missedAttacks += stats.missedAttacks;
      weightedDestruction += stats.averageDestruction * attacks;
      for (final entry in starsCount.entries) {
        totalStars += (int.tryParse(entry.key) ?? 0) * entry.value;
      }
    }

    return _WarStatsOverview(
      activePlayers: activePlayers,
      totalAttacks: totalAttacks,
      missedAttacks: missedAttacks,
      averageStars: totalAttacks == 0 ? 0 : totalStars / totalAttacks,
      averageDestruction: totalAttacks == 0
          ? 0
          : weightedDestruction / totalAttacks,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toString();
    final statsPeriodValue = _selectedStatsSeason == null
        ? loc.warStatsLast50
        : DateFormat.yMMM(localeName).format(_selectedStatsSeason!);
    final statsPeriodLabel = _selectedStatsSeason == null
        ? loc.warStatsWars
        : loc.clanRankingsSeason;
    final displayedPlayers = _displayedPlayers();
    final overview = _overviewFor(displayedPlayers);

    return Column(
      children: [
        ClanTabSearchSortBar(
          controller: _searchController,
          query: _searchQuery,
          hintText: loc.warStatsSearchPlaceholder,
          sortBy: _sortBy,
          updateSortBy: _updateSortBy,
          maxSortWidth: 130,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
        const SizedBox(height: 8),
        _FilterBar(
          trailing: const SizedBox.shrink(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          actions: [
            _FilterActionButton(
              tooltip: loc.warStatsSelectSeason,
              icon: Icons.calendar_month_rounded,
              onTap: _pickStatsSeason,
            ),
          ],
          middle: ClanSummaryChips(
            padding: EdgeInsets.zero,
            children: [
              ClanSummaryChip(
                icon: Icons.calendar_month_rounded,
                value: statsPeriodValue,
                label: statsPeriodLabel,
                color: Theme.of(context).colorScheme.primary,
              ),
              ClanSummaryChip(
                icon: Icons.groups_rounded,
                value: overview.activePlayers.toString(),
                label: loc.clanMembers,
              ),
              ClanSummaryChip(
                icon: Icons.bolt_rounded,
                value: overview.totalAttacks.toString(),
                label: loc.warAttacksTitle,
                color: Colors.blueAccent,
              ),
              ClanSummaryChip(
                icon: Icons.star_rounded,
                value: overview.averageStars.toStringAsFixed(2),
                label: loc.warStarsAverage,
                color: Colors.amber.shade700,
              ),
              ClanSummaryChip(
                icon: Icons.percent_rounded,
                value: '${overview.averageDestruction.toStringAsFixed(1)}%',
                label: loc.warDestructionAverage,
                color: Colors.teal,
              ),
              ClanSummaryChip(
                icon: Icons.warning_amber_rounded,
                value: overview.missedAttacks.toString(),
                label: loc.warAttacksMissedShort,
                color: Colors.redAccent,
              ),
            ],
          ),
          chips: [
            _FilterPill(
              label: loc.cwlTitle,
              imageUrl: ImageAssets.cwlSwordsNoBorder,
              selected: widget.isCWLChecked,
              color: Theme.of(context).colorScheme.primary,
              onTap: widget.onCWLChanged,
            ),
            _FilterPill(
              label: loc.warFiltersRandom,
              icon: Icons.shuffle_rounded,
              selected: widget.isRandomChecked,
              onTap: widget.onRandomChanged,
            ),
            _FilterPill(
              label: loc.warFiltersFriendly,
              icon: Icons.handshake_rounded,
              selected: widget.isFriendlyChecked,
              onTap: widget.onFriendlyChanged,
            ),
            _FilterPill(
              label: loc.warStatsCurrentTownHall,
              icon: Icons.home_work_rounded,
              selected: !showUppedTownHall,
              color: Theme.of(context).colorScheme.tertiary,
              onTap: _toggleTownHallVisibility,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingStats)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ClanWarStatsPlayers(
              clan: widget.clan,
              showUppedTownHall: showUppedTownHall,
              sortBy: _sortBy,
              selectedTypes: widget.selectedTypes,
              filteredPlayers: displayedPlayers,
              allPlayers: _periodPlayers.map((player) => player.tag).toList(),
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

class _WarStatsOverview {
  final int activePlayers;
  final int totalAttacks;
  final int missedAttacks;
  final double averageStars;
  final double averageDestruction;

  const _WarStatsOverview({
    required this.activePlayers,
    required this.totalAttacks,
    required this.missedAttacks,
    required this.averageStars,
    required this.averageDestruction,
  });
}

class _ClanCwlHistoryTab extends StatefulWidget {
  final Clan clan;

  const _ClanCwlHistoryTab({required this.clan});

  @override
  State<_ClanCwlHistoryTab> createState() => _ClanCwlHistoryTabState();
}

class _ClanCwlHistoryTabState extends State<_ClanCwlHistoryTab> {
  static const _mockEntries = [
    CwlRankingHistoryEntry(
      season: 'July 2026',
      league: 'Legend League',
      rank: 3,
      stars: 287,
      destruction: 93.4,
      roundsWon: 5,
      roundsTied: 0,
      roundsLost: 2,
    ),
    CwlRankingHistoryEntry(
      season: 'June 2026',
      league: 'Champion League I',
      rank: 1,
      stars: 301,
      destruction: 95.1,
      roundsWon: 7,
      roundsTied: 0,
      roundsLost: 0,
    ),
    CwlRankingHistoryEntry(
      season: 'May 2026',
      league: 'Master League I',
      rank: 2,
      stars: 276,
      destruction: 91.8,
      roundsWon: 5,
      roundsTied: 1,
      roundsLost: 1,
    ),
    CwlRankingHistoryEntry(
      season: 'April 2026',
      league: 'Crystal League I',
      rank: 1,
      stars: 244,
      destruction: 89.6,
      roundsWon: 6,
      roundsTied: 0,
      roundsLost: 1,
    ),
    CwlRankingHistoryEntry(
      season: 'March 2026',
      league: 'Gold League I',
      rank: 2,
      stars: 218,
      destruction: 86.2,
      roundsWon: 5,
      roundsTied: 0,
      roundsLost: 2,
    ),
    CwlRankingHistoryEntry(
      season: 'February 2026',
      league: 'Silver League I',
      rank: 4,
      stars: 182,
      destruction: 81.9,
      roundsWon: 3,
      roundsTied: 1,
      roundsLost: 3,
    ),
    CwlRankingHistoryEntry(
      season: 'January 2026',
      league: 'Bronze League I',
      rank: 1,
      stars: 156,
      destruction: 78.4,
      roundsWon: 6,
      roundsTied: 0,
      roundsLost: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 900;

    // TODO: Replace this mockup with getCwlRankingHistory(widget.clan.tag)
    // once the CWL history endpoint is fixed.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          _CwlHistoryPreviewNotice(clan: widget.clan),
          const SizedBox(height: 10),
          isDesktopWeb
              ? ResponsiveCardGrid(
                  itemCount: _mockEntries.length,
                  minItemWidth: 420,
                  maxColumns: 2,
                  spacing: 10,
                  itemBuilder: (_, index) => _CwlSeasonMockupCard(
                    entry: _mockEntries[index],
                    padding: EdgeInsets.zero,
                  ),
                )
              : Column(
                  children: _mockEntries
                      .map((entry) => _CwlSeasonMockupCard(entry: entry))
                      .toList(growable: false),
                ),
        ],
      ),
    );
  }
}

class _CwlHistoryPreviewNotice extends StatelessWidget {
  final Clan clan;

  const _CwlHistoryPreviewNotice({required this.clan});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 15,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)?.cwlHistoryPreviewBadge ??
                    'Preview',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            AppLocalizations.of(
                  context,
                )?.cwlHistoryPreviewSubtitle(clan.name) ??
                '${clan.name} mockup until CWL endpoint is fixed',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CwlSeasonMockupCard extends StatelessWidget {
  final CwlRankingHistoryEntry entry;
  final EdgeInsetsGeometry padding;

  const _CwlSeasonMockupCard({
    required this.entry,
    this.padding = const EdgeInsets.only(bottom: 10),
  });

  @override
  Widget build(BuildContext context) {
    final leagueName = entry.league ?? 'Unranked';
    final leagueIcon = ImageAssets.getWarLeagueImage(leagueName);
    final accent = _CwlLeagueAccent.forLeague(leagueName);

    return Padding(
      padding: padding,
      child: GlassPanel(
        width: double.infinity,
        height: 74,
        borderRadius: 16,
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
        tint: accent,
        borderOpacity: 0.22,
        shadowOpacity: 0.16,
        child: Builder(
          builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;

            return Row(
              children: [
                SizedBox.square(
                  dimension: 52,
                  child: MobileWebImage(
                    imageUrl: leagueIcon,
                    width: 52,
                    height: 52,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CwlSeasonMainInfo(
                    leagueName: leagueName,
                    rank: entry.rank,
                    roundsWon: entry.roundsWon,
                    roundsTied: entry.roundsTied,
                    roundsLost: entry.roundsLost,
                    accent: accent,
                  ),
                ),
                const SizedBox(width: 10),
                _CwlSeasonSideInfo(
                  season: entry.season,
                  stars: entry.stars,
                  destruction: entry.destruction,
                  color: colorScheme.onSurface.withValues(alpha: 0.74),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CwlLeagueAccent {
  static Color forLeague(String leagueName) {
    final name = leagueName.toLowerCase();
    if (name.contains('legend')) return const Color(0xFF8C63FF);
    if (name.contains('champion')) return const Color(0xFFFF8A2B);
    if (name.contains('master')) {
      return const Color(0xFF1B1D23);
    }
    if (name.contains('crystal')) {
      return const Color(0xFF8C63FF);
    }
    if (name.contains('gold')) {
      return const Color(0xFFFFC83D);
    }
    if (name.contains('silver')) {
      return const Color(0xFFC9D1DA);
    }
    if (name.contains('bronze')) {
      return const Color(0xFFC9793E);
    }
    return const Color(0xFF8C63FF);
  }
}

class _CwlSeasonMainInfo extends StatelessWidget {
  final String leagueName;
  final int rank;
  final int roundsWon;
  final int roundsTied;
  final int roundsLost;
  final Color accent;

  const _CwlSeasonMainInfo({
    required this.leagueName,
    required this.rank,
    required this.roundsWon,
    required this.roundsTied,
    required this.roundsLost,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leagueName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.70),
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                '#$rank',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: _CwlRecordPill(
                won: roundsWon,
                tied: roundsTied,
                lost: roundsLost,
                color: accent,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CwlSeasonSideInfo extends StatelessWidget {
  final String season;
  final int stars;
  final double destruction;
  final Color color;

  const _CwlSeasonSideInfo({
    required this.season,
    required this.stars,
    required this.destruction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              season,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.50),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CwlImageStat(
              imageUrl: ImageAssets.builderBaseStar,
              value: '$stars',
            ),
            const SizedBox(width: 9),
            _CwlIconStat(
              icon: Icons.percent_rounded,
              value: destruction.toStringAsFixed(1),
            ),
          ],
        ),
      ],
    );
  }
}

class _CwlRecordPill extends StatelessWidget {
  final int won;
  final int tied;
  final int lost;
  final Color color;

  const _CwlRecordPill({
    required this.won,
    required this.tied,
    required this.lost,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final readableColor = color.computeLuminance() < 0.18
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.86)
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: readableColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: readableColor.withValues(alpha: 0.38)),
      ),
      child: Text(
        '${won}W ${tied}D ${lost}L',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: readableColor,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _CwlIconStat extends StatelessWidget {
  final IconData icon;
  final String value;

  const _CwlIconStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.64),
        ),
        const SizedBox(width: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.78),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CwlImageStat extends StatelessWidget {
  final String imageUrl;
  final String value;

  const _CwlImageStat({required this.imageUrl, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MobileWebImage(imageUrl: imageUrl, width: 14, height: 14),
        const SizedBox(width: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.78),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
