import 'dart:convert';
import 'dart:math' as math;

import 'package:clashkingapp/common/theme/app_tokens.dart';
import 'package:clashkingapp/common/widgets/header_widgets.dart';
import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/core/config/app_feature_flags.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'side_page_components.dart';

class RankingsPage extends StatefulWidget {
  const RankingsPage({super.key});

  @override
  State<RankingsPage> createState() => _RankingsPageState();
}

class _RankingsPageState extends State<RankingsPage> {
  final ApiService _apiService = ApiService();
  OfficialRankingType _type = OfficialRankingType.playerTrophies;
  LocationOption _location = rankingLocations.first;
  int _townHall = 0;
  late Future<List<RankingEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<RankingEntry>> _load() async {
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
        .map((item) => RankingEntry.fromJson(item, _type))
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
    return SidePageScaffold(
      title: loc.sideRankingsTitle,
      subtitle: loc.sideRankingsSubtitle,
      child: ListView(
        padding: sidePagePadding,
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
          SidePageHorizontalSelector<OfficialRankingType>(
            values: OfficialRankingType.values,
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
          FutureBuilder<List<RankingEntry>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SidePageLoadingRows();
              }
              if (snapshot.hasError) {
                return SidePageErrorPanel(
                  message: loc.sideRankingsLoadError,
                  detail: snapshot.error.toString(),
                  onRetry: _reload,
                );
              }
              final entries = snapshot.data ?? [];
              if (entries.isEmpty) {
                return SidePageEmptyState(
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
                  ...entries.take(200).map((entry) => RankingRow(entry: entry)),
                ],
              );
            },
          ),
          if (showPreviews) ...[
            const SizedBox(height: 24),
            SidePageSectionHeader(title: loc.sideRankingsMockups),
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

class _RankingMiniStat extends StatelessWidget {
  const _RankingMiniStat({this.imageUrl, this.icon, required this.value});

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

class RankingRow extends StatelessWidget {
  const RankingRow({super.key, required this.entry});

  final RankingEntry entry;

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
          _RankingMiniStat(
            imageUrl: entry.metricImageUrl,
            value: formatSidePageInt(entry.score),
          ),
        ],
      ),
    );
  }
}

class _RankingTitle extends StatelessWidget {
  const _RankingTitle({required this.type});

  final OfficialRankingType type;

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

  final LocationOption location;
  final int townHall;
  final bool townHallEnabled;
  final ValueChanged<LocationOption> onLocationChanged;
  final ValueChanged<int> onTownHallChanged;

  @override
  Widget build(BuildContext context) {
    final locationPanel = _DropdownPanel<LocationOption>(
      icon: Icons.public_rounded,
      value: location,
      values: rankingLocations,
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
  final OfficialRankingType type;
  final LocationOption location;
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
          _RankingMiniStat(
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

class RankingEntry {
  const RankingEntry({
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

  factory RankingEntry.fromJson(
    Map<String, dynamic> json,
    OfficialRankingType type,
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
    return RankingEntry(
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

class LocationOption {
  const LocationOption(this.id, this.name);

  final int id;
  final String name;

  String get apiPath => id == 32000000 ? 'global' : '$id';
}

enum OfficialRankingType {
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

  const OfficialRankingType({
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

extension OfficialRankingTypeL10n on OfficialRankingType {
  String labelOf(AppLocalizations loc) => switch (this) {
    OfficialRankingType.playerTrophies => loc.rankingPlayerTrophies,
    OfficialRankingType.playerBuilder => loc.rankingPlayerBuilder,
    OfficialRankingType.clanTrophies => loc.rankingClanTrophies,
    OfficialRankingType.clanBuilder => loc.rankingClanBuilder,
    OfficialRankingType.clanCapital => loc.rankingClanCapital,
  };

  String headingOf(AppLocalizations loc) => switch (this) {
    OfficialRankingType.playerTrophies => loc.rankingPlayerTrophiesHeading,
    OfficialRankingType.playerBuilder => loc.rankingPlayerBuilderHeading,
    OfficialRankingType.clanTrophies => loc.rankingClanTrophiesHeading,
    OfficialRankingType.clanBuilder => loc.rankingClanBuilderHeading,
    OfficialRankingType.clanCapital => loc.rankingClanCapitalHeading,
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

const rankingLocations = [
  LocationOption(32000000, 'Worldwide'),
  LocationOption(32000006, 'United States'),
  LocationOption(32000249, 'International'),
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
