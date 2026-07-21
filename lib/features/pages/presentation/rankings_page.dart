// Compatibility facade for the app-section exports and the temporary Stats
// page. Rankings itself now lives in its feature package.
export 'package:clashkingapp/features/rankings/presentation/rankings_page.dart'
    show RankingsPage;

import 'package:clashkingapp/common/widgets/mobile_web_image.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class RankingRow extends StatelessWidget {
  const RankingRow({super.key, required this.entry});

  final RankingEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: MobileWebImage(imageUrl: entry.imageUrl, width: 40, height: 40),
      title: Text(entry.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        entry.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text('${entry.score}'),
    );
  }
}

class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.name,
    required this.subtitle,
    required this.score,
    required this.imageUrl,
  });

  final int rank;
  final String name;
  final String subtitle;
  final int score;
  final String imageUrl;

  factory RankingEntry.fromJson(
    Map<String, dynamic> json,
    OfficialRankingType type,
  ) {
    final badgeUrls = json['badgeUrls'];
    final townHall = _asInt(json['townHallLevel']);
    final tag = json['tag']?.toString() ?? '';
    final clan = json['clan'];
    final clanName = clan is Map ? clan['name']?.toString() ?? '' : '';
    return RankingEntry(
      rank: _asInt(json['rank']),
      name: json['name']?.toString() ?? tag,
      subtitle: clanName.isEmpty ? tag : '$clanName · $tag',
      score: _asInt(json[type.scoreKey]),
      imageUrl: type.isClan
          ? (badgeUrls is Map
                ? badgeUrls['medium']?.toString() ?? ImageAssets.clanCastle
                : ImageAssets.clanCastle)
          : ImageAssets.townHall(townHall == 0 ? 1 : townHall),
    );
  }
}

class LocationOption {
  const LocationOption(this.id, this.name);

  final int id;
  final String name;

  String get apiPath => id == 0 ? 'global' : '$id';
}

enum OfficialRankingType {
  playerTrophies('players', false, 'trophies'),
  playerBuilder('players-builder-base', false, 'builderBaseTrophies'),
  clanTrophies('clans', true, 'clanPoints'),
  clanBuilder('clans-builder-base', true, 'clanBuilderBasePoints'),
  clanCapital('capitals', true, 'clanCapitalPoints');

  const OfficialRankingType(this.path, this.isClan, this.scoreKey);

  final String path;
  final bool isClan;
  final String scoreKey;
}

extension OfficialRankingTypeL10n on OfficialRankingType {
  String labelOf(AppLocalizations loc) => switch (this) {
    OfficialRankingType.playerTrophies => loc.rankingPlayerTrophies,
    OfficialRankingType.playerBuilder => loc.rankingPlayerBuilder,
    OfficialRankingType.clanTrophies => loc.rankingClanTrophies,
    OfficialRankingType.clanBuilder => loc.rankingClanBuilder,
    OfficialRankingType.clanCapital => loc.rankingClanCapital,
  };
}

const rankingLocations = [
  LocationOption(0, 'Worldwide'),
  LocationOption(32000006, 'International'),
];

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
