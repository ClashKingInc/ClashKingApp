import 'dart:convert';
import 'dart:math' as math;

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/common/widgets/native_liquid_glass.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/config/app_feature_flags.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/player/data/player_item_utils.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const _pagePadding = EdgeInsets.fromLTRB(16, 12, 16, 28);
const _sidePageDesktopBreakpoint = 900.0;

bool _isSidePageDesktop(BuildContext context) =>
    kIsWeb && MediaQuery.sizeOf(context).width >= _sidePageDesktopBreakpoint;

class PopularPage extends StatelessWidget {
  const PopularPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final bookmarks = context.watch<BookmarkService>();
    final players = context.watch<PlayerService>().profiles;
    final clans = context.watch<ClanService>().clans.values.toList();
    final wars = context.watch<WarCwlService>().summaries.values.toList();

    final popularPlayers = _popularPlayers(players, bookmarks.players, loc);
    final popularClans = _popularClans(clans, bookmarks.clans, loc);
    final popularWars = _popularWars(wars, bookmarks.clans);
    final hasPopular =
        popularPlayers.isNotEmpty ||
        popularClans.isNotEmpty ||
        popularWars.isNotEmpty;

    final sections = <Widget>[
      if (popularPlayers.isNotEmpty)
        _PopularSection(
          icon: Icons.person_rounded,
          title: loc.popularPlayersTitle,
          count: popularPlayers.length,
          children: popularPlayers.map(_PopularRow.player).toList(),
        ),
      if (popularClans.isNotEmpty)
        _PopularSection(
          icon: Icons.shield_rounded,
          title: loc.popularClansTitle,
          count: popularClans.length,
          children: popularClans.map(_PopularRow.clan).toList(),
        ),
      if (popularWars.isNotEmpty)
        _PopularSection(
          icon: Icons.sports_martial_arts_rounded,
          title: loc.popularWarsCwlTitle,
          count: popularWars.length,
          children: popularWars.map(_PopularRow.war).toList(),
        ),
    ];

    return _SidePageScaffold(
      title: loc.popularTitle,
      subtitle: loc.popularSubtitle,
      child: ListView(
        padding: _pagePadding,
        children: [
          _PopularSummaryChips(
            playerCount: popularPlayers.length,
            clanCount: popularClans.length,
            warCount: popularWars.length,
          ),
          const SizedBox(height: 16),
          if (hasPopular)
            for (var index = 0; index < sections.length; index++) ...[
              sections[index],
              if (index < sections.length - 1) const SizedBox(height: 14),
            ]
          else
            _EmptyState(
              icon: Icons.trending_up_rounded,
              title: loc.popularEmptyTitle,
              body: loc.popularEmptyBody,
            ),
        ],
      ),
    );
  }

  List<_PopularItem> _popularPlayers(
    List<Player> players,
    List<BookmarkedPlayer> bookmarks,
    AppLocalizations loc,
  ) {
    final byTag = <String, _PopularItem>{};
    for (final player in players) {
      byTag[player.tag] = _PopularItem(
        title: player.name,
        subtitle:
            '${player.tag} · ${loc.gameTownHallShortLevel(player.townHallLevel)}',
        metric: player.trophies,
        displayMetric: player.trophies,
        metricLabel: 'trophies',
        metricImageUrl: player.leagueUrl.isNotEmpty
            ? player.leagueUrl
            : ImageAssets.trophies,
        imageUrl: ImageAssets.townHall(player.townHallLevel),
      );
    }
    for (final bookmark in bookmarks) {
      final existing = byTag[bookmark.tag];
      byTag[bookmark.tag] = _PopularItem(
        title: bookmark.name,
        subtitle: [bookmark.tag, loc.generalBookmarked].join(' · '),
        metric: (existing?.metric ?? bookmark.trophies) + 500,
        displayMetric: existing?.displayMetric ?? bookmark.trophies,
        metricLabel: 'trophies',
        metricImageUrl: bookmark.leagueUrl.isNotEmpty
            ? bookmark.leagueUrl
            : ImageAssets.trophies,
        imageUrl: ImageAssets.townHall(bookmark.townHallLevel),
      );
    }
    return byTag.values.toList()..sort((a, b) => b.metric.compareTo(a.metric));
  }

  List<_PopularItem> _popularClans(
    List<Clan> clans,
    List<BookmarkedClan> bookmarks,
    AppLocalizations loc,
  ) {
    final byTag = <String, _PopularItem>{};
    for (final clan in clans) {
      byTag[clan.tag] = _PopularItem(
        title: clan.name,
        subtitle: [clan.tag, loc.clanLevelValue(clan.clanLevel)].join(' · '),
        metric: clan.clanPoints,
        metricLabel: 'points',
        metricImageUrl: ImageAssets.trophies,
        imageUrl: clan.badgeUrls.medium,
      );
    }
    for (final bookmark in bookmarks) {
      final existing = byTag[bookmark.tag];
      byTag[bookmark.tag] = _PopularItem(
        title: bookmark.name,
        subtitle:
            '${bookmark.tag} · ${loc.generalMembersCount(bookmark.memberCount)}',
        metric: (existing?.metric ?? bookmark.clanLevel * 100) + 500,
        metricLabel: 'interest',
        metricIcon: Icons.bookmark_rounded,
        imageUrl: bookmark.badgeUrl,
      );
    }
    return byTag.values.toList()..sort((a, b) => b.metric.compareTo(a.metric));
  }

  List<_PopularItem> _popularWars(
    Iterable<WarCwl> wars,
    List<BookmarkedClan> bookmarks,
  ) {
    final bookmarkedTags = bookmarks.map((clan) => clan.tag).toSet();
    final items = wars.map((war) {
      final active = war.isInWar || war.isInCwl;
      final score = (active ? 1000 : 0) + war.teamSize;
      return _PopularItem(
        title: war.tag,
        subtitle: war.isInCwl
            ? 'CWL · ${war.teamSize}v${war.teamSize}'
            : active
            ? 'War · ${war.teamSize}v${war.teamSize}'
            : 'No active war',
        metric: bookmarkedTags.contains(war.tag) ? score + 500 : score,
        metricLabel: active ? 'active' : 'tracked',
        metricIcon: active
            ? Icons.local_fire_department_rounded
            : Icons.visibility_rounded,
        imageUrl: war.isInCwl ? ImageAssets.cwlSwordsNoBorder : ImageAssets.war,
      );
    }).toList();
    return items..sort((a, b) => b.metric.compareTo(a.metric));
  }
}

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  final ApiService _apiService = ApiService();
  _OfficialRankingType _type = _OfficialRankingType.playerTrophies;
  _LocationOption _location = _locations.first;
  int _townHall = 0;
  late Future<List<_RankingEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_RankingEntry>> _load() async {
    final response = await _apiService.proxyGet(
      '/locations/${_location.apiPath}/rankings/${_type.path}?limit=200',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load rankings (${response.statusCode})');
    }

    final decoded = jsonDecode(ApiService.decodeResponseBody(response));
    final items = decoded is Map ? decoded['items'] : null;
    if (items is! List) return [];
    final entries = items
        .whereType<Map<String, dynamic>>()
        .map((item) => _RankingEntry.fromJson(item, _type))
        .toList();
    if (!_type.supportsTownHallFilter || _townHall == 0) {
      return entries;
    }
    return entries.where((entry) => entry.townHallLevel == _townHall).toList();
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final showPreviews = context.watch<MyAppState>().isFeatureEnabled(
      AppFeatureFlags.leaderboardPreviews,
    );
    return _SidePageScaffold(
      title: loc.sideRankingsTitle,
      subtitle: loc.sideRankingsSubtitle,
      child: ListView(
        padding: _pagePadding,
        children: [
          _RankingTitle(type: _type),
          const SizedBox(height: 14),
          _RankingControlRow(
            location: _location,
            townHall: _townHall,
            townHallEnabled: _type.supportsTownHallFilter,
            onLocationChanged: (value) {
              setState(() => _location = value);
              _reload();
            },
            onTownHallChanged: (value) {
              setState(() => _townHall = value);
              _reload();
            },
          ),
          const SizedBox(height: 16),
          _HorizontalSelector<_OfficialRankingType>(
            values: _OfficialRankingType.values,
            selected: _type,
            labelBuilder: (type) => type.labelOf(loc),
            onSelected: (value) {
              setState(() {
                _type = value;
                if (!value.supportsTownHallFilter) {
                  _townHall = 0;
                }
              });
              _reload();
            },
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<_RankingEntry>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingRows();
              }
              if (snapshot.hasError) {
                return _ErrorPanel(
                  message: loc.sideRankingsLoadError,
                  detail: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }
              final entries = snapshot.data ?? [];
              if (entries.isEmpty) {
                return _EmptyState(
                  icon: Icons.leaderboard_outlined,
                  title: loc.sideRankingsEmptyTitle,
                  body: loc.sideRankingsEmptyBody,
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LeaderboardMeta(
                    count: entries.length,
                    type: _type,
                    location: _location,
                    townHall: _townHall,
                    onRefresh: _reload,
                  ),
                  const SizedBox(height: 14),
                  ...entries
                      .take(200)
                      .map((entry) => _RankingRow(entry: entry)),
                ],
              );
            },
          ),
          if (showPreviews) ...[
            const SizedBox(height: 24),
            _SectionHeader(title: loc.sideRankingsMockups),
            const _EndpointMockupSummary(),
            const SizedBox(height: 8),
            ..._clashKingLeaderboardOptions.map(
              (option) => _EndpointPreview(option: option),
            ),
          ],
        ],
      ),
    );
  }
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final ApiService _apiService = ApiService();
  _OfficialRankingType _type = _OfficialRankingType.playerTrophies;
  _LocationOption _location = _locations.first;
  late Future<List<_RankingEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_RankingEntry>> _load() async {
    final response = await _apiService.proxyGet(
      '/locations/${_location.apiPath}/rankings/${_type.path}?limit=200',
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load official stats (${response.statusCode})');
    }
    final decoded = jsonDecode(ApiService.decodeResponseBody(response));
    final items = decoded is Map ? decoded['items'] : null;
    if (items is! List) return [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((item) => _RankingEntry.fromJson(item, _type))
        .toList();
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _SidePageScaffold(
      title: loc.sideStatsTitle,
      subtitle: loc.sideStatsSubtitle,
      child: ListView(
        padding: _pagePadding,
        children: [
          _HorizontalSelector<_OfficialRankingType>(
            values: _OfficialRankingType.values,
            selected: _type,
            labelBuilder: (type) => type.labelOf(loc),
            onSelected: (value) {
              setState(() => _type = value);
              _reload();
            },
          ),
          const SizedBox(height: 10),
          _HorizontalSelector<_LocationOption>(
            values: _locations,
            selected: _location,
            labelBuilder: (location) => location.name,
            onSelected: (value) {
              setState(() => _location = value);
              _reload();
            },
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<_RankingEntry>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingRows();
              }
              if (snapshot.hasError) {
                return _ErrorPanel(
                  message: loc.sideStatsLoadError,
                  detail: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }
              final entries = snapshot.data ?? [];
              final topScore = entries.isEmpty ? 0 : entries.first.score;
              final average = entries.isEmpty
                  ? 0
                  : entries
                            .map((entry) => entry.score)
                            .reduce((a, b) => a + b) /
                        entries.length;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MetricPanel(
                          label: loc.sideTopScore,
                          value: _formatInt(topScore),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricPanel(
                          label: loc.sideTop200Avg,
                          value: _formatInt(average.round()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...entries.take(25).map((entry) => _RankingRow(entry: entry)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class CalculatorsPage extends StatefulWidget {
  const CalculatorsPage({super.key});

  @override
  State<CalculatorsPage> createState() => _CalculatorsPageState();
}

class _CalculatorsPageState extends State<CalculatorsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted && _selectedTab != _tabController.index) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return _SidePageScaffold(
      title: loc.calculatorsTitle,
      subtitle: loc.calculatorsSubtitle,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: NativeLiquidGlassSegmentedControl<int>(
            values: const [0, 1, 2],
            labels: [
              loc.calculatorOre,
              loc.calculatorZapQuake,
              loc.calculatorFireball,
            ],
            selected: _selectedTab,
            height: 44,
            onChanged: (index) {
              setState(() => _selectedTab = index);
              _tabController.animateTo(index);
            },
          ),
        ),
      ),
      child: TabBarView(
        controller: _tabController,
        children: const [
          _OreCalculator(),
          _ZapQuakeCalculator(),
          _FireballQuakeCalculator(),
        ],
      ),
    );
  }
}

class UpgradeTrackerTeasePage extends StatefulWidget {
  const UpgradeTrackerTeasePage({super.key});

  @override
  State<UpgradeTrackerTeasePage> createState() =>
      _UpgradeTrackerTeasePageState();
}

class _UpgradeTrackerTeasePageState extends State<UpgradeTrackerTeasePage> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final players = context.watch<PlayerService>().profiles;
    final selected = _selectedPlayer(players);
    final summary = selected == null
        ? null
        : _UpgradeAccountSummary(selected, loc);

    return _SidePageScaffold(
      title: loc.upgradeTrackerTitle,
      subtitle: selected == null
          ? loc.upgradeTrackerSubtitle
          : '${selected.name} · TH${selected.townHallLevel}',
      child: ListView(
        padding: _pagePadding,
        children: [
          if (players.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: selected?.tag,
              decoration: InputDecoration(labelText: loc.linkedAccountLabel),
              items: players
                  .map(
                    (player) => DropdownMenuItem(
                      value: player.tag,
                      child: Text(
                        '${player.name} · ${loc.gameTownHallShortLevel(player.townHallLevel)}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedTag = value),
            )
          else
            _EmptyState(
              icon: Icons.construction_rounded,
              title: loc.noLinkedPlayersLoadedTitle,
              body: loc.noLinkedPlayersLoadedBody,
            ),
          if (summary != null) ...[
            const SizedBox(height: 16),
            _UpgradeSummaryPanel(summary: summary),
            const SizedBox(height: 18),
            for (final section in summary.sections) ...[
              _UpgradeTrackerSection(section: section),
              const SizedBox(height: 14),
            ],
          ],
        ],
      ),
    );
  }

  Player? _selectedPlayer(List<Player> players) {
    if (players.isEmpty) return null;
    if (_selectedTag == null) return players.first;
    return players.firstWhere(
      (player) => player.tag == _selectedTag,
      orElse: () => players.first,
    );
  }
}

class _UpgradeAccountSummary {
  final Player player;
  late final List<_UpgradeSectionSummary> sections;

  _UpgradeAccountSummary(this.player, AppLocalizations loc) {
    sections = [
      _UpgradeSectionSummary(
        title: loc.upgradeSectionHeroes,
        icon: Icons.person_rounded,
        items: player.heroes,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: loc.upgradeSectionTroops,
        icon: Icons.groups_rounded,
        items: player.troops,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: loc.upgradeSectionSpells,
        icon: Icons.auto_fix_high_rounded,
        items: player.spells,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: loc.upgradeSectionPets,
        icon: Icons.pets_rounded,
        items: player.pets,
        townHallLevel: player.townHallLevel,
      ),
      _UpgradeSectionSummary(
        title: loc.upgradeSectionEquipment,
        icon: Icons.diamond_rounded,
        items: player.equipments,
        townHallLevel: player.townHallLevel,
      ),
    ];
  }

  int get totalLevels =>
      sections.fold(0, (total, section) => total + section.levelsRemaining);

  int get totalSeconds =>
      sections.fold(0, (total, section) => total + section.seconds);

  List<UpgradeResourceAmount> get totalResources {
    final totals = <String, num>{};
    for (final section in sections) {
      for (final resource in section.resources) {
        totals[resource.key] = (totals[resource.key] ?? 0) + resource.amount;
      }
    }
    return totals.entries
        .map((entry) => UpgradeResourceAmount(entry.key, entry.value))
        .toList()
      ..sort(
        (a, b) =>
            resourceSortWeight(a.key).compareTo(resourceSortWeight(b.key)),
      );
  }
}

class _UpgradeSectionSummary {
  final String title;
  final IconData icon;
  final List<PlayerItem> items;
  final int townHallLevel;
  late final List<_UpgradeItemSummary> itemSummaries;

  _UpgradeSectionSummary({
    required this.title,
    required this.icon,
    required this.items,
    required this.townHallLevel,
  }) {
    itemSummaries =
        items
            .where((item) => item.isUnlocked && item.meta != null)
            .map((item) {
              final thMax = maxLevelForItemAtTH(item, townHallLevel);
              final targetLevel = thMax > 0 ? thMax : item.maxLevel;
              return _UpgradeItemSummary(
                item: item,
                summary: calculateRemainingUpgradeSummary(
                  item,
                  targetLevel: targetLevel,
                ),
              );
            })
            .where((entry) => entry.summary.levelsRemaining > 0)
            .toList()
          ..sort((a, b) {
            final timeCompare = b.summary.seconds.compareTo(a.summary.seconds);
            if (timeCompare != 0) return timeCompare;
            return b.summary.levelsRemaining.compareTo(
              a.summary.levelsRemaining,
            );
          });
  }

  int get levelsRemaining => itemSummaries.fold(
    0,
    (total, item) => total + item.summary.levelsRemaining,
  );

  int get seconds =>
      itemSummaries.fold(0, (total, item) => total + item.summary.seconds);

  List<UpgradeResourceAmount> get resources {
    final totals = <String, num>{};
    for (final item in itemSummaries) {
      for (final resource in item.summary.resources) {
        totals[resource.key] = (totals[resource.key] ?? 0) + resource.amount;
      }
    }
    return totals.entries
        .map((entry) => UpgradeResourceAmount(entry.key, entry.value))
        .toList()
      ..sort(
        (a, b) =>
            resourceSortWeight(a.key).compareTo(resourceSortWeight(b.key)),
      );
  }
}

class _UpgradeItemSummary {
  final PlayerItem item;
  final UpgradeRemainingSummary summary;

  const _UpgradeItemSummary({required this.item, required this.summary});
}

class _UpgradeSummaryPanel extends StatelessWidget {
  final _UpgradeAccountSummary summary;

  const _UpgradeSummaryPanel({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.totalLevels == 0
                  ? 'TH${summary.player.townHallLevel} maxed'
                  : '${summary.totalLevels} levels left',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              summary.totalSeconds == 0
                  ? 'No tracked upgrades remaining for this Town Hall.'
                  : '${_formatUpgradeDuration(summary.totalSeconds)} remaining upgrade time',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (summary.totalResources.isNotEmpty) ...[
              const SizedBox(height: 12),
              _UpgradeResourceWrap(resources: summary.totalResources),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpgradeTrackerSection extends StatelessWidget {
  final _UpgradeSectionSummary section;

  const _UpgradeTrackerSection({required this.section});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(section.icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _UpgradeTextPill(
                  text: section.levelsRemaining == 0
                      ? 'Maxed'
                      : '${section.levelsRemaining} levels',
                  color: section.levelsRemaining == 0
                      ? StatColors.win
                      : StatColors.warStarGold,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (section.levelsRemaining == 0)
              Text(
                'Nothing left to upgrade for this Town Hall.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              )
            else ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _UpgradeTextPill(
                    text: _formatUpgradeDuration(section.seconds),
                    color: colorScheme.primary,
                    icon: Icons.schedule_rounded,
                  ),
                  ...section.resources.map(
                    (resource) => _UpgradeResourcePill(resource: resource),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final item in section.itemSummaries.take(4)) ...[
                _UpgradeItemLine(item: item),
                if (item != section.itemSummaries.take(4).last)
                  const SizedBox(height: 8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _UpgradeItemLine extends StatelessWidget {
  final _UpgradeItemSummary item;

  const _UpgradeItemLine({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        MobileWebImage(imageUrl: item.item.imageUrl, width: 34, height: 34),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameDataService.localizedNameForItem(item.item.meta),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Lvl ${item.item.level} → ${item.summary.targetLevel}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _UpgradeTextPill(
          text: _formatUpgradeDuration(item.summary.seconds),
          color: colorScheme.secondary,
        ),
      ],
    );
  }
}

class _UpgradeResourceWrap extends StatelessWidget {
  final List<UpgradeResourceAmount> resources;

  const _UpgradeResourceWrap({required this.resources});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: resources
          .map((resource) => _UpgradeResourcePill(resource: resource))
          .toList(),
    );
  }
}

class _UpgradeResourcePill extends StatelessWidget {
  final UpgradeResourceAmount resource;

  const _UpgradeResourcePill({required this.resource});

  @override
  Widget build(BuildContext context) {
    final visual = _UpgradeResourceVisual.forKey(resource.key);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MobileWebImage(imageUrl: visual.imageUrl, width: 18, height: 18),
          const SizedBox(width: 5),
          Text(
            _formatCompactNumber(resource.amount),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _UpgradeTextPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _UpgradeTextPill({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class BasesArmiesPage extends StatelessWidget {
  const BasesArmiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return _SidePageScaffold(
      title: loc.sideBasesArmiesTitle,
      subtitle: loc.sideBasesArmiesSubtitle,
      child: ListView(
        padding: _pagePadding,
        children: [
          _TeasePanel(
            icon: Icons.grid_view_rounded,
            title: loc.sideBotSyncTarget,
            body: loc.sideBotSyncTargetBody,
          ),
          const SizedBox(height: 18),
          _SectionHeader(title: loc.sideSavedBases),
          _SavedLinkPlaceholder(
            title: loc.sideWarBaseSlots,
            body: loc.sideWarBaseSlotsBody,
          ),
          _SavedLinkPlaceholder(
            title: loc.sideLegendBaseSlots,
            body: loc.sideLegendBaseSlotsBody,
          ),
          const SizedBox(height: 18),
          _SectionHeader(title: loc.sideSavedArmies),
          _SavedLinkPlaceholder(
            title: loc.sideArmyLinks,
            body: loc.sideArmyLinksBody,
          ),
        ],
      ),
    );
  }
}

class GameAssetsPage extends StatefulWidget {
  const GameAssetsPage({super.key});

  @override
  State<GameAssetsPage> createState() => _GameAssetsPageState();
}

class _GameAssetsPageState extends State<GameAssetsPage> {
  String _folder = 'troops';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final entries = _assetEntriesFor(_folder);
    return _SidePageScaffold(
      title: loc.sideGameAssetsTitle,
      subtitle: loc.sideGameAssetsSubtitle,
      child: ListView(
        padding: _pagePadding,
        children: [
          _HorizontalSelector<String>(
            values: _assetFolders,
            selected: _folder,
            labelBuilder: (folder) => _assetFolderLabel(folder, loc),
            onSelected: (value) => setState(() => _folder = value),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width > 1080
                  ? 6
                  : width > 880
                  ? 5
                  : width > 680
                  ? 4
                  : width > 480
                  ? 3
                  : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.86,
                ),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  return _AssetTile(entry: entries[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  List<_AssetEntry> _assetEntriesFor(String folder) {
    switch (folder) {
      case 'troops':
        return _entriesFromBundle(
          GameDataService.troopsData['troops'],
          'troops',
          (name) => ImageAssets.getTroopImage(name),
        );
      case 'spells':
        return _entriesFromBundle(
          GameDataService.spellsData['spells'],
          'spells',
          (name) => ImageAssets.getSpellImage(name),
        );
      case 'heroes':
        return _entriesFromBundle(
          GameDataService.heroesData['heroes'],
          'heroes',
          (name) => ImageAssets.getHeroImage(name),
        );
      case 'equipment':
        return _entriesFromBundle(
          GameDataService.gearsData['gears'],
          'equipment',
          _equipmentUrl,
        );
      case 'leagues':
        return _leagueEntries();
      case 'resources':
        return const [
          _AssetEntry(
            name: 'Shiny Ore',
            folder: 'resources',
            url: '${ImageAssets.baseUrl}/resources/shiny_ore.webp',
          ),
          _AssetEntry(
            name: 'Glowy Ore',
            folder: 'resources',
            url: '${ImageAssets.baseUrl}/resources/glowy_ore.webp',
          ),
          _AssetEntry(
            name: 'Starry Ore',
            folder: 'resources',
            url: '${ImageAssets.baseUrl}/resources/starry_ore.webp',
          ),
          _AssetEntry(
            name: 'Capital Gold',
            folder: 'resources',
            url: '${ImageAssets.baseUrl}/resources/capital_gold.webp',
          ),
          _AssetEntry(
            name: 'Raid Medals',
            folder: 'resources',
            url: '${ImageAssets.baseUrl}/resources/raid_medals.webp',
          ),
        ];
      default:
        return _staticAssetCatalog
            .where((entry) => entry.folder == folder)
            .toList();
    }
  }

  List<_AssetEntry> _entriesFromBundle(
    dynamic raw,
    String folder,
    String Function(String name) urlBuilder,
  ) {
    if (raw is! Map || raw.isEmpty) {
      return _staticAssetCatalog
          .where((entry) => entry.folder == folder)
          .toList();
    }
    return raw.keys
        .map((key) => key.toString())
        .where((name) => name.trim().isNotEmpty)
        .map(
          (name) =>
              _AssetEntry(name: name, folder: folder, url: urlBuilder(name)),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<_AssetEntry> _leagueEntries() {
    final entries = <_AssetEntry>[];
    final playerLeagues = GameDataService.playerLeagueData['leagues'];
    if (playerLeagues is Map) {
      entries.addAll(
        playerLeagues.keys.map(
          (key) => _AssetEntry(
            name: key.toString(),
            folder: 'leagues',
            url: ImageAssets.getLeagueImage(key.toString()),
          ),
        ),
      );
    }
    if (entries.isEmpty) {
      return _staticAssetCatalog
          .where((entry) => entry.folder == 'leagues')
          .toList();
    }
    return entries..sort((a, b) => a.name.compareTo(b.name));
  }

  String _equipmentUrl(String name) {
    final gears = GameDataService.gearsData['gears'];
    if (gears is Map) {
      final gear = gears[name];
      if (gear is Map && gear['url'] is String) {
        return gear['url'] as String;
      }
    }
    return ImageAssets.defaultImage;
  }
}

class _OreCalculator extends StatefulWidget {
  const _OreCalculator();

  @override
  State<_OreCalculator> createState() => _OreCalculatorState();
}

class _OreCalculatorState extends State<_OreCalculator> {
  String? _selectedTag;
  int _shinyOwned = 0;
  int _glowyOwned = 0;
  int _starryOwned = 0;
  int _shinyTarget = 5600;
  int _glowyTarget = 600;
  int _starryTarget = 60;
  int _extraDailyShiny = 0;
  int _extraDailyGlowy = 0;
  int _extraDailyStarry = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final players = context.watch<PlayerService>().profiles;
    final selected = _selectedPlayer(players);
    final bonus = _OreBonus.forLeague(selected?.league ?? 'Crystal League');
    final dailyShiny = bonus.shiny + _extraDailyShiny;
    final dailyGlowy = bonus.glowy + _extraDailyGlowy;
    final dailyStarry = bonus.starry + _extraDailyStarry;
    final days = [
      _daysLeft(_shinyTarget - _shinyOwned, dailyShiny),
      _daysLeft(_glowyTarget - _glowyOwned, dailyGlowy),
      _daysLeft(_starryTarget - _starryOwned, dailyStarry),
    ].reduce(math.max);

    return _CalculatorResponsiveLayout(
      lead: [
        if (players.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: selected?.tag,
            decoration: InputDecoration(labelText: loc.linkedAccountLabel),
            items: players
                .map(
                  (player) => DropdownMenuItem(
                    value: player.tag,
                    child: Text('${player.name} · ${player.league}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedTag = value),
          )
        else
          _EmptyState(
            icon: Icons.person_outline_rounded,
            title: loc.sideNoLinkedPlayersTitle,
            body: loc.sideNoLinkedPlayersBody,
          ),
        const SizedBox(height: 16),
        _CalculatorResult(
          title: days == 0 ? loc.sideReadyNow : loc.sideDays(days),
          subtitle: loc.sideOreLeft(
            _formatInt(math.max(0, _shinyTarget - _shinyOwned)),
            _formatInt(math.max(0, _glowyTarget - _glowyOwned)),
            _formatInt(math.max(0, _starryTarget - _starryOwned)),
          ),
        ),
      ],
      controls: [
        const SizedBox(height: 18),
        _NumberRow(
          label: loc.sideShinyOre,
          owned: _shinyOwned,
          target: _shinyTarget,
          daily: dailyShiny,
          onOwnedChanged: (value) => setState(() => _shinyOwned = value),
          onTargetChanged: (value) => setState(() => _shinyTarget = value),
        ),
        _NumberRow(
          label: loc.sideGlowyOre,
          owned: _glowyOwned,
          target: _glowyTarget,
          daily: dailyGlowy,
          onOwnedChanged: (value) => setState(() => _glowyOwned = value),
          onTargetChanged: (value) => setState(() => _glowyTarget = value),
        ),
        _NumberRow(
          label: loc.sideStarryOre,
          owned: _starryOwned,
          target: _starryTarget,
          daily: dailyStarry,
          onOwnedChanged: (value) => setState(() => _starryOwned = value),
          onTargetChanged: (value) => setState(() => _starryTarget = value),
        ),
        const SizedBox(height: 12),
        _SectionHeader(title: loc.sideDailyBonusAdjustment),
        _CompactStepper(
          label: loc.sideExtraShiny,
          value: _extraDailyShiny,
          step: 50,
          onChanged: (value) => setState(() => _extraDailyShiny = value),
        ),
        _CompactStepper(
          label: loc.sideExtraGlowy,
          value: _extraDailyGlowy,
          step: 5,
          onChanged: (value) => setState(() => _extraDailyGlowy = value),
        ),
        _CompactStepper(
          label: loc.sideExtraStarry,
          value: _extraDailyStarry,
          step: 1,
          onChanged: (value) => setState(() => _extraDailyStarry = value),
        ),
      ],
    );
  }

  Player? _selectedPlayer(List<Player> players) {
    if (players.isEmpty) return null;
    if (_selectedTag == null) return players.first;
    return players.firstWhere(
      (player) => player.tag == _selectedTag,
      orElse: () => players.first,
    );
  }

  int _daysLeft(int remaining, int daily) {
    if (remaining <= 0) return 0;
    if (daily <= 0) return 999;
    return (remaining / daily).ceil();
  }
}

class _ZapQuakeCalculator extends StatefulWidget {
  const _ZapQuakeCalculator();

  @override
  State<_ZapQuakeCalculator> createState() => _ZapQuakeCalculatorState();
}

class _ZapQuakeCalculatorState extends State<_ZapQuakeCalculator> {
  int _buildingHp = 4200;
  int _lightningLevel = 11;
  int _quakeLevel = 5;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lightning = _lightningDamage[_lightningLevel] ?? 600;
    final quake = (_buildingHp * ((_quakePercent[_quakeLevel] ?? 29) / 100))
        .floor();
    final afterQuake = math.max(0, _buildingHp - quake);
    final zaps = (afterQuake / lightning).ceil();
    final noQuakeZaps = (_buildingHp / lightning).ceil();

    return _CalculatorResponsiveLayout(
      lead: [
        _CalculatorResult(
          title: loc.sideZapQuakeTitle(zaps),
          subtitle: loc.sideZapQuakeSubtitle(
            _formatInt(quake),
            _formatInt(lightning),
          ),
        ),
        const SizedBox(height: 12),
        _MetricPanel(
          label: loc.sideWithoutEarthquake,
          value: loc.sideLightningCount(noQuakeZaps),
        ),
      ],
      controls: [
        const SizedBox(height: 16),
        _CompactStepper(
          label: loc.sideBuildingHp,
          value: _buildingHp,
          step: 100,
          min: 100,
          onChanged: (value) => setState(() => _buildingHp = value),
        ),
        _LevelSelector(
          label: loc.sideLightningLevel,
          value: _lightningLevel,
          min: 1,
          max: 12,
          onChanged: (value) => setState(() => _lightningLevel = value),
        ),
        _LevelSelector(
          label: loc.sideEarthquakeLevel,
          value: _quakeLevel,
          min: 1,
          max: 5,
          onChanged: (value) => setState(() => _quakeLevel = value),
        ),
      ],
    );
  }
}

class _FireballQuakeCalculator extends StatefulWidget {
  const _FireballQuakeCalculator();

  @override
  State<_FireballQuakeCalculator> createState() =>
      _FireballQuakeCalculatorState();
}

class _FireballQuakeCalculatorState extends State<_FireballQuakeCalculator> {
  int _buildingHp = 5200;
  int _fireballLevel = 18;
  int _quakeLevel = 5;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final fireball = _fireballDamage(_fireballLevel);
    final afterFireball = math.max(0, _buildingHp - fireball);
    final quakeDamage =
        (_buildingHp * ((_quakePercent[_quakeLevel] ?? 29) / 100)).floor();
    final remaining = math.max(0, afterFireball - quakeDamage);
    final quakesNeeded = remaining == 0
        ? 1
        : math.min(4, (remaining / math.max(1, quakeDamage)).ceil() + 1);

    return _CalculatorResponsiveLayout(
      lead: [
        _CalculatorResult(
          title: remaining == 0
              ? loc.sideFireballQuakeTitle
              : loc.sideAddSupportDamage,
          subtitle: loc.sideFireballQuakeSubtitle(
            _formatInt(fireball),
            _formatInt(math.max(0, remaining)),
          ),
        ),
        const SizedBox(height: 12),
        _MetricPanel(
          label: loc.sideQuakePressure,
          value: loc.sideQuakeSpellCount(quakesNeeded),
        ),
      ],
      controls: [
        const SizedBox(height: 16),
        _CompactStepper(
          label: loc.sideBuildingHp,
          value: _buildingHp,
          step: 100,
          min: 100,
          onChanged: (value) => setState(() => _buildingHp = value),
        ),
        _LevelSelector(
          label: loc.sideFireballLevel,
          value: _fireballLevel,
          min: 1,
          max: 27,
          onChanged: (value) => setState(() => _fireballLevel = value),
        ),
        _LevelSelector(
          label: loc.sideEarthquakeLevel,
          value: _quakeLevel,
          min: 1,
          max: 5,
          onChanged: (value) => setState(() => _quakeLevel = value),
        ),
      ],
    );
  }
}

class _CalculatorResponsiveLayout extends StatelessWidget {
  const _CalculatorResponsiveLayout({
    required this.lead,
    required this.controls,
  });

  final List<Widget> lead;
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) {
    if (!_isSidePageDesktop(context)) {
      return ListView(padding: _pagePadding, children: [...lead, ...controls]);
    }

    return ListView(
      padding: _pagePadding,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final useColumns = constraints.maxWidth >= 760;
            if (!useColumns) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [...lead, ...controls],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: lead,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: controls,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SidePageScaffold extends StatelessWidget {
  const _SidePageScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.bottom,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktopWeb = _isSidePageDesktop(context);

    PreferredSizeWidget? constrainedBottom() {
      final value = bottom;
      if (value == null || !isDesktopWeb) return value;
      return PreferredSize(
        preferredSize: value.preferredSize,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: value,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        bottom: constrainedBottom(),
      ),
      body: isDesktopWeb
          ? LayoutBuilder(
              builder: (context, constraints) => Center(
                child: SizedBox(
                  width: math.min(constraints.maxWidth, 1200),
                  height: constraints.maxHeight,
                  child: child,
                ),
              ),
            )
          : child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularSummaryChips extends StatelessWidget {
  const _PopularSummaryChips({
    required this.playerCount,
    required this.clanCount,
    required this.warCount,
  });

  final int playerCount;
  final int clanCount;
  final int warCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        MetricChip(
          label: AppLocalizations.of(context)!.sidePopularPlayers,
          value: '$playerCount',
          icon: Icons.person_rounded,
          color: colorScheme.primary,
        ),
        MetricChip(
          label: AppLocalizations.of(context)!.sidePopularClans,
          value: '$clanCount',
          icon: Icons.shield_rounded,
          color: colorScheme.secondary,
        ),
        MetricChip(
          label: AppLocalizations.of(context)!.sidePopularWarsCwl,
          value: '$warCount',
          icon: Icons.sports_martial_arts_rounded,
          color: StatColors.warStarGold,
        ),
      ],
    );
  }
}

class _PopularSection extends StatelessWidget {
  const _PopularSection({
    required this.icon,
    required this.title,
    required this.count,
    required this.children,
  });

  final IconData icon;
  final String title;
  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 0, 2, 6),
          child: Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _PopularRow extends StatelessWidget {
  const _PopularRow({required this.item});

  final _PopularItem item;

  factory _PopularRow.player(_PopularItem item) => _PopularRow(item: item);
  factory _PopularRow.clan(_PopularItem item) => _PopularRow(item: item);
  factory _PopularRow.war(_PopularItem item) => _PopularRow(item: item);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 40,
            child: MobileWebImage(imageUrl: item.imageUrl, fit: BoxFit.contain),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PopularMiniStat(
            imageUrl: item.metricImageUrl,
            icon: item.metricIcon,
            value: item.metricLabel == 'active' || item.metricLabel == 'tracked'
                ? item.metricLabel
                : _formatInt(item.displayMetric ?? item.metric),
          ),
        ],
      ),
    );
  }
}

class _PopularMiniStat extends StatelessWidget {
  const _PopularMiniStat({this.imageUrl, this.icon, required this.value});

  final String? imageUrl;
  final IconData? icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null)
            MobileWebImage(imageUrl: imageUrl!, width: 18, height: 18)
          else
            Icon(icon ?? Icons.trending_up_rounded, size: 18),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 74),
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.entry});

  final _RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${entry.rank}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                if (entry.movement != '=') ...[
                  const SizedBox(height: 3),
                  Text(
                    entry.movement,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: entry.movement.startsWith('+')
                          ? StatColors.win
                          : StatColors.loss,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox.square(
            dimension: 40,
            child: MobileWebImage(
              imageUrl: entry.imageUrl,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  entry.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PopularMiniStat(
            imageUrl: entry.metricImageUrl,
            value: _formatInt(entry.score),
          ),
        ],
      ),
    );
  }
}

class _RankingTitle extends StatelessWidget {
  const _RankingTitle({required this.type});

  final _OfficialRankingType type;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.32,
              ),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: MobileWebImage(
                imageUrl: type.iconUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.headingOf(AppLocalizations.of(context)!),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                AppLocalizations.of(context)!.sideOfficialClashLeaderboard,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RankingControlRow extends StatelessWidget {
  const _RankingControlRow({
    required this.location,
    required this.townHall,
    required this.townHallEnabled,
    required this.onLocationChanged,
    required this.onTownHallChanged,
  });

  final _LocationOption location;
  final int townHall;
  final bool townHallEnabled;
  final ValueChanged<_LocationOption> onLocationChanged;
  final ValueChanged<int> onTownHallChanged;

  @override
  Widget build(BuildContext context) {
    final locationPanel = _DropdownPanel<_LocationOption>(
      icon: Icons.public_rounded,
      value: location,
      values: _locations,
      labelBuilder: (value) => value.name,
      onChanged: onLocationChanged,
    );
    final townHallPanel = _DropdownPanel<int>(
      icon: Icons.home_work_outlined,
      value: townHallEnabled ? townHall : 0,
      values: townHallEnabled ? _townHallFilters : const [0],
      labelBuilder: (value) => value == 0 ? 'All town halls' : 'TH$value',
      onChanged: townHallEnabled ? onTownHallChanged : (_) {},
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(
            children: [
              locationPanel,
              const SizedBox(height: 10),
              townHallPanel,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: locationPanel),
            const SizedBox(width: 10),
            Expanded(child: townHallPanel),
          ],
        );
      },
    );
  }
}

class _DropdownPanel<T> extends StatelessWidget {
  const _DropdownPanel({
    required this.icon,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final IconData icon;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: values
                .map(
                  (entry) => DropdownMenuItem<T>(
                    value: entry,
                    child: Row(
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            labelBuilder(entry),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ),
      ),
    );
  }
}

class _LeaderboardMeta extends StatelessWidget {
  const _LeaderboardMeta({
    required this.count,
    required this.type,
    required this.location,
    required this.townHall,
    required this.onRefresh,
  });

  final int count;
  final _OfficialRankingType type;
  final _LocationOption location;
  final int townHall;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MetricChip(
                label: type.labelOf(AppLocalizations.of(context)!),
                value: 'Top ${math.min(count, 200)}',
                imageUrl: type.iconUrl,
              ),
              MetricChip(
                label: AppLocalizations.of(context)!.sideLocation,
                value: location.name,
                icon: Icons.public_rounded,
              ),
              MetricChip(
                label: AppLocalizations.of(context)!.sideFilter,
                value: townHall > 0
                    ? 'TH$townHall'
                    : AppLocalizations.of(context)!.sideAllTownHallsShort,
                icon: Icons.home_work_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: AppLocalizations.of(context)!.sideRefresh,
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }
}

class _ListLine extends StatelessWidget {
  const _ListLine({
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColoredBox(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                child: MobileWebImage(
                  imageUrl: imageUrl!,
                  width: 40,
                  height: 40,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}

class _HorizontalSelector<T> extends StatelessWidget {
  const _HorizontalSelector({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = values[index];
          final isSelected = value == selected;
          return ChoiceChip(
            label: Text(labelBuilder(value)),
            selected: isSelected,
            onSelected: (_) => onSelected(value),
            showCheckmark: false,
            selectedColor: colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          );
        },
      ),
    );
  }
}

class _EndpointPreview extends StatelessWidget {
  const _EndpointPreview({required this.option});

  final _EndpointOption option;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cardColor = Theme.of(context).cardTheme.color ?? colorScheme.surface;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 40,
            child: MobileWebImage(
              imageUrl: option.iconUrl,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.titleOf(AppLocalizations.of(context)!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 1),
                Text(
                  option.previewOf(AppLocalizations.of(context)!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _PopularMiniStat(
            icon: option.stateIcon,
            value: option.stateOf(AppLocalizations.of(context)!),
          ),
        ],
      ),
    );
  }
}

class _EndpointMockupSummary extends StatelessWidget {
  const _EndpointMockupSummary();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        MetricChip(
          label: AppLocalizations.of(context)!.sideMockupSource,
          value: 'ClashKing',
          icon: Icons.query_stats_rounded,
        ),
        MetricChip(
          label: AppLocalizations.of(context)!.sideMockupMode,
          value: AppLocalizations.of(context)!.sideMockupPreview,
          icon: Icons.visibility_rounded,
        ),
        MetricChip(
          label: AppLocalizations.of(context)!.sideMockupRows,
          value: AppLocalizations.of(context)!.sideMockupRowsValue,
          icon: Icons.view_list_rounded,
        ),
      ],
    );
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorResult extends StatelessWidget {
  const _CalculatorResult({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.label,
    required this.owned,
    required this.target,
    required this.daily,
    required this.onOwnedChanged,
    required this.onTargetChanged,
  });

  final String label;
  final int owned;
  final int target;
  final int daily;
  final ValueChanged<int> onOwnedChanged;
  final ValueChanged<int> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                AppLocalizations.of(context)!.sideDailyValue(_formatInt(daily)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SmallNumberField(
                  label: AppLocalizations.of(context)!.sideOwned,
                  value: owned,
                  onChanged: onOwnedChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallNumberField(
                  label: AppLocalizations.of(context)!.sideTarget,
                  value: target,
                  onChanged: onTargetChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallNumberField extends StatelessWidget {
  const _SmallNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value.toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      onChanged: (raw) => onChanged(int.tryParse(raw) ?? 0),
    );
  }
}

class _CompactStepper extends StatelessWidget {
  const _CompactStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.min = 0,
  });

  final String label;
  final int value;
  final int step;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            tooltip: AppLocalizations.of(context)!.sideDecrease,
            onPressed: value <= min
                ? null
                : () => onChanged(math.max(min, value - step)),
            icon: const Icon(Icons.remove_circle_outline_rounded),
          ),
          SizedBox(
            width: 72,
            child: Text(
              _formatInt(value),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.sideIncrease,
            onPressed: () => onChanged(value + step),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          DropdownButton<int>(
            value: value,
            items: [
              for (var level = min; level <= max; level++)
                DropdownMenuItem(
                  value: level,
                  child: Text(AppLocalizations.of(context)!.sideLevel(level)),
                ),
            ],
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    );
  }
}

class _AssetTile extends StatelessWidget {
  const _AssetTile({required this.entry});

  final _AssetEntry entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: MobileWebImage(imageUrl: entry.url, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              entry.folder,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(icon, size: 42, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.detail,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              detail,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(AppLocalizations.of(context)!.generalRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        8,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: LinearProgressIndicator(
            minHeight: 6,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _TeasePanel extends StatelessWidget {
  const _TeasePanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

class _SavedLinkPlaceholder extends StatelessWidget {
  const _SavedLinkPlaceholder({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _ListLine(
      imageUrl: ImageAssets.clanCastle,
      title: title,
      subtitle: body,
      trailing: 'sync',
    );
  }
}

class _PopularItem {
  const _PopularItem({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.metricLabel,
    required this.imageUrl,
    this.displayMetric,
    this.metricImageUrl,
    this.metricIcon,
  });

  final String title;
  final String subtitle;
  final int metric;
  final String metricLabel;
  final String imageUrl;
  final int? displayMetric;
  final String? metricImageUrl;
  final IconData? metricIcon;
}

class _RankingEntry {
  const _RankingEntry({
    required this.rank,
    required this.previousRank,
    required this.name,
    required this.subtitle,
    required this.score,
    required this.imageUrl,
    required this.metricImageUrl,
    required this.townHallLevel,
  });

  final int rank;
  final int previousRank;
  final String name;
  final String subtitle;
  final int score;
  final String imageUrl;
  final String metricImageUrl;
  final int townHallLevel;

  String get movement {
    if (previousRank <= 0 || rank <= 0) return '=';
    final delta = previousRank - rank;
    if (delta == 0) return '=';
    return delta > 0 ? '+$delta' : '$delta';
  }

  factory _RankingEntry.fromJson(
    Map<String, dynamic> json,
    _OfficialRankingType type,
  ) {
    final isClan = type.isClan;
    final badgeUrls = json['badgeUrls'];
    final league = json['league'];
    final leagueUrl =
        _nestedString(league, 'iconUrls.small') ??
        _nestedString(league, 'iconUrls.medium');
    final imageUrl = isClan
        ? _nestedString(badgeUrls, 'medium') ?? ImageAssets.clanCastle
        : ImageAssets.townHall(_asInt(json['townHallLevel'], fallback: 1));
    final metricImageUrl = isClan ? type.iconUrl : leagueUrl ?? type.iconUrl;
    final score = type.scoreKey
        .map((key) => _asInt(json[key]))
        .firstWhere((value) => value > 0, orElse: () => 0);
    final tag = json['tag']?.toString() ?? '';
    final clanName =
        _nestedString(json['clan'], 'name') ??
        json['clanName']?.toString() ??
        '';
    final subtitle = clanName.isEmpty ? tag : '$clanName · $tag';
    return _RankingEntry(
      rank: _asInt(json['rank']),
      previousRank: _asInt(json['previousRank']),
      name: json['name']?.toString() ?? tag,
      subtitle: subtitle,
      score: score,
      imageUrl: imageUrl,
      metricImageUrl: metricImageUrl,
      townHallLevel: _asInt(json['townHallLevel']),
    );
  }
}

class _LocationOption {
  const _LocationOption(this.id, this.name);

  final int id;
  final String name;

  String get apiPath => id == 32000000 ? 'global' : '$id';
}

enum _OfficialRankingType {
  playerTrophies(
    path: 'players',
    isClan: false,
    scoreKey: ['trophies'],
    iconUrl: ImageAssets.trophies,
    supportsTownHallFilter: true,
  ),
  playerBuilder(
    path: 'players-builder-base',
    isClan: false,
    scoreKey: ['builderBaseTrophies', 'trophies'],
    iconUrl: ImageAssets.builderBaseStar,
    supportsTownHallFilter: false,
  ),
  clanTrophies(
    path: 'clans',
    isClan: true,
    scoreKey: ['clanPoints', 'clanPoints'],
    iconUrl: ImageAssets.trophies,
    supportsTownHallFilter: false,
  ),
  clanBuilder(
    path: 'clans-builder-base',
    isClan: true,
    scoreKey: ['clanBuilderBasePoints', 'clanPoints'],
    iconUrl: ImageAssets.builderBaseStar,
    supportsTownHallFilter: false,
  ),
  clanCapital(
    path: 'capitals',
    isClan: true,
    scoreKey: ['clanCapitalPoints', 'capitalPoints'],
    iconUrl: ImageAssets.capitalTrophy,
    supportsTownHallFilter: false,
  );

  const _OfficialRankingType({
    required this.path,
    required this.isClan,
    required this.scoreKey,
    required this.iconUrl,
    required this.supportsTownHallFilter,
  });

  final String path;
  final bool isClan;
  final List<String> scoreKey;
  final String iconUrl;
  final bool supportsTownHallFilter;
}

extension _OfficialRankingTypeL10n on _OfficialRankingType {
  String labelOf(AppLocalizations loc) => switch (this) {
    _OfficialRankingType.playerTrophies => loc.rankingPlayerTrophies,
    _OfficialRankingType.playerBuilder => loc.rankingPlayerBuilder,
    _OfficialRankingType.clanTrophies => loc.rankingClanTrophies,
    _OfficialRankingType.clanBuilder => loc.rankingClanBuilder,
    _OfficialRankingType.clanCapital => loc.rankingClanCapital,
  };

  String headingOf(AppLocalizations loc) => switch (this) {
    _OfficialRankingType.playerTrophies => loc.rankingPlayerTrophiesHeading,
    _OfficialRankingType.playerBuilder => loc.rankingPlayerBuilderHeading,
    _OfficialRankingType.clanTrophies => loc.rankingClanTrophiesHeading,
    _OfficialRankingType.clanBuilder => loc.rankingClanBuilderHeading,
    _OfficialRankingType.clanCapital => loc.rankingClanCapitalHeading,
  };
}

class _EndpointOption {
  const _EndpointOption({
    required this.titleKey,
    required this.previewKey,
    required this.iconUrl,
    required this.stateKey,
    required this.stateIcon,
  });

  final String titleKey;
  final String previewKey;
  final String iconUrl;
  final String stateKey;
  final IconData stateIcon;
}

extension _EndpointOptionL10n on _EndpointOption {
  String titleOf(AppLocalizations loc) => switch (titleKey) {
    'league_top_200' => loc.endpointLeagueTop200,
    'townhall_top_200' => loc.endpointTownhallTop200,
    'clan_donations' => loc.endpointClanDonations,
    'clan_war_wins' => loc.endpointClanWarWins,
    'top_200_army_usage' => loc.endpointTop200ArmyUsage,
    _ => titleKey,
  };

  String previewOf(AppLocalizations loc) => switch (previewKey) {
    'league_top_200' => loc.endpointLeagueTop200Preview,
    'townhall_top_200' => loc.endpointTownhallTop200Preview,
    'clan_donations' => loc.endpointClanDonationsPreview,
    'clan_war_wins' => loc.endpointClanWarWinsPreview,
    'top_200_army_usage' => loc.endpointTop200ArmyUsagePreview,
    _ => previewKey,
  };

  String stateOf(AppLocalizations loc) => switch (stateKey) {
    'top_200' => loc.endpointStateTop200,
    'weekly' => loc.endpointStateWeekly,
    'wins' => loc.endpointStateWins,
    'usage' => loc.endpointStateUsage,
    _ => stateKey.toUpperCase(),
  };
}

class _OreBonus {
  const _OreBonus(this.shiny, this.glowy, this.starry);

  final int shiny;
  final int glowy;
  final int starry;

  static _OreBonus forLeague(String league) {
    final normalized = league.toLowerCase();
    if (normalized.contains('legend')) return const _OreBonus(1000, 54, 6);
    if (normalized.contains('titan')) return const _OreBonus(925, 50, 5);
    if (normalized.contains('champion')) return const _OreBonus(810, 46, 4);
    if (normalized.contains('master')) return const _OreBonus(700, 38, 3);
    if (normalized.contains('crystal')) return const _OreBonus(560, 30, 2);
    if (normalized.contains('gold')) return const _OreBonus(420, 24, 1);
    if (normalized.contains('silver')) return const _OreBonus(320, 14, 0);
    return const _OreBonus(220, 10, 0);
  }
}

class _AssetEntry {
  const _AssetEntry({
    required this.name,
    required this.folder,
    required this.url,
  });

  final String name;
  final String folder;
  final String url;
}

const _locations = [
  _LocationOption(32000000, 'Worldwide'),
  _LocationOption(32000006, 'United States'),
  _LocationOption(32000249, 'International'),
];

const _townHallFilters = [0, 17, 16, 15, 14, 13, 12, 11, 10, 9];

final _clashKingLeaderboardOptions = [
  _EndpointOption(
    titleKey: 'league_top_200',
    previewKey: 'league_top_200',
    iconUrl: ImageAssets.legendBlazon,
    stateKey: 'top_200',
    stateIcon: Icons.emoji_events_rounded,
  ),
  _EndpointOption(
    titleKey: 'townhall_top_200',
    previewKey: 'townhall_top_200',
    iconUrl: ImageAssets.townHall(17),
    stateKey: 'th17',
    stateIcon: Icons.home_work_outlined,
  ),
  _EndpointOption(
    titleKey: 'clan_donations',
    previewKey: 'clan_donations',
    iconUrl: ImageAssets.clanGamesMedals,
    stateKey: 'weekly',
    stateIcon: Icons.volunteer_activism_rounded,
  ),
  _EndpointOption(
    titleKey: 'clan_war_wins',
    previewKey: 'clan_war_wins',
    iconUrl: ImageAssets.war,
    stateKey: 'wins',
    stateIcon: Icons.military_tech_rounded,
  ),
  _EndpointOption(
    titleKey: 'top_200_army_usage',
    previewKey: 'top_200_army_usage',
    iconUrl: ImageAssets.sword,
    stateKey: 'usage',
    stateIcon: Icons.analytics_rounded,
  ),
];

const _assetFolders = [
  'troops',
  'spells',
  'heroes',
  'equipment',
  'leagues',
  'resources',
  'stickers',
];

const _staticAssetCatalog = [
  _AssetEntry(name: 'Villager', folder: 'stickers', url: ImageAssets.villager),
  _AssetEntry(
    name: 'Builder',
    folder: 'stickers',
    url: ImageAssets.builderWave,
  ),
  _AssetEntry(name: 'Goblin', folder: 'stickers', url: ImageAssets.goblin),
  _AssetEntry(
    name: 'Thinking Barbarian King',
    folder: 'stickers',
    url: ImageAssets.thinkingBarbarianKing,
  ),
  _AssetEntry(
    name: 'Legend League',
    folder: 'leagues',
    url: ImageAssets.legendBlazon,
  ),
  _AssetEntry(name: 'Clan War', folder: 'resources', url: ImageAssets.warClan),
  _AssetEntry(name: 'Trophy', folder: 'resources', url: ImageAssets.trophies),
  _AssetEntry(
    name: 'Capital Trophy',
    folder: 'resources',
    url: ImageAssets.capitalTrophy,
  ),
];

const _lightningDamage = {
  1: 150,
  2: 180,
  3: 210,
  4: 240,
  5: 270,
  6: 320,
  7: 400,
  8: 480,
  9: 560,
  10: 600,
  11: 640,
  12: 680,
};

const _quakePercent = {1: 14, 2: 17, 3: 21, 4: 25, 5: 29};

int _fireballDamage(int level) {
  return 900 + ((level - 1) * 65);
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String? _nestedString(Object? raw, String path) {
  Object? current = raw;
  for (final segment in path.split('.')) {
    if (current is! Map) return null;
    current = current[segment];
  }
  return current?.toString();
}

String _formatInt(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final indexFromEnd = raw.length - i;
    buffer.write(raw[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _formatCompactNumber(num value) {
  if (value >= 1000000) {
    final formatted = (value / 1000000).toStringAsFixed(1);
    return '${formatted.endsWith('.0') ? formatted.replaceAll('.0', '') : formatted}M';
  }
  if (value >= 1000) {
    final formatted = (value / 1000).toStringAsFixed(1);
    return '${formatted.endsWith('.0') ? formatted.replaceAll('.0', '') : formatted}K';
  }
  return value.toInt().toString();
}

String _formatUpgradeDuration(int seconds) {
  if (seconds <= 0) return '0d';
  final days = seconds ~/ 86400;
  final hours = (seconds % 86400) ~/ 3600;
  if (days > 0) return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  return hours > 0 ? '${hours}h' : '<1h';
}

class _UpgradeResourceVisual {
  final String imageUrl;

  const _UpgradeResourceVisual({required this.imageUrl});

  factory _UpgradeResourceVisual.forKey(String key) {
    if (key.contains('dark')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/dark_elixir.webp',
      );
    }
    if (key.contains('builder') && key.contains('elixir')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/builder_elixir.webp',
      );
    }
    if (key.contains('builder') && key.contains('gold')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/builder_gold.webp',
      );
    }
    if (key.contains('elixir')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/elixir.webp',
      );
    }
    if (key.contains('gold')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/gold.webp',
      );
    }
    if (key.contains('glowy')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/glowy_ore.webp',
      );
    }
    if (key.contains('starry')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/starry_ore.webp',
      );
    }
    if (key.contains('shiny')) {
      return const _UpgradeResourceVisual(
        imageUrl: '${ImageAssets.baseUrl}/resources/shiny_ore.webp',
      );
    }
    return const _UpgradeResourceVisual(imageUrl: ImageAssets.defaultImage);
  }
}

String _assetFolderLabel(String folder, AppLocalizations loc) {
  return switch (folder) {
    'troops' => loc.assetFolderTroops,
    'spells' => loc.assetFolderSpells,
    'heroes' => loc.assetFolderHeroes,
    'equipment' => loc.assetFolderEquipment,
    'leagues' => loc.assetFolderLeagues,
    'resources' => loc.assetFolderResources,
    'stickers' => loc.assetFolderStickers,
    _ => folder,
  };
}
