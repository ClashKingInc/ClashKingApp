import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_league_round.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class CwlLeague {
  final String state;
  final String season;
  final List<CwlClan> clans;
  final List<CwlLeagueRound> rounds;

  CwlLeague({
    required this.state,
    required this.season,
    required this.clans,
    required this.rounds,
  });

  factory CwlLeague.fromJson(Map<String, dynamic>? json) {
    try {
      final data = json ?? const <String, dynamic>{};

      return CwlLeague(
        state: data['state']?.toString() ?? 'unknown',
        season: data['season']?.toString() ?? 'unknown',
        clans: (data['clans'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((clan) => CwlClan.fromJson(Map<String, dynamic>.from(clan)))
            .toList(),
        rounds: (data['rounds'] as List<dynamic>? ?? [])
            .whereType<Map>()
            .map((round) => Map<String, dynamic>.from(round))
            .toList()
            .asMap()
            .entries
            .where((entry) {
              final warTags =
                  (entry.value['warTags'] as List?)?.cast<String>() ?? [];
              return warTags.any((tag) => tag != '#0');
            })
            .map((entry) => CwlLeagueRound.fromJson(entry.value, entry.key))
            .toList(),
      );
    } catch (e) {
      DebugUtils.debugError(" Error parsing CwlLeague: $e");
      return CwlLeague(
        state: 'unknown',
        season: 'unknown',
        clans: [],
        rounds: [],
      );
    }
  }

  int? getStarsGapFromRank(String clanTag, int targetRank) {
    if (clans.isEmpty) return null;

    final currentClan = clans.firstWhere((c) => c.tag == clanTag,
        orElse: () => CwlClan.empty());
    if (currentClan.tag.isEmpty) return null;

    final targetClan = clans.firstWhere(
      (c) => c.rank == targetRank,
      orElse: () {
        final sortedByGap = List<CwlClan>.from(clans)
          ..sort((a, b) => (a.rank - targetRank)
              .abs()
              .compareTo((b.rank - targetRank).abs()));
        return sortedByGap.first;
      },
    );

    return targetClan.stars - currentClan.stars;
  }

  CwlClan? getClanDetails(String tag) {
    try {
      return clans.firstWhere((c) => c.tag == tag);
    } catch (_) {
      return null;
    }
  }

  void sortClans(String sortBy) {
    switch (sortBy) {
      case 'stars':
        clans.sort((a, b) => b.stars.compareTo(a.stars));
        break;
      case 'percentage':
        clans.sort((a, b) =>
            b.destructionPercentage.compareTo(a.destructionPercentage));
        break;
    }
  }

  List<CwlLeagueRound> getRounds() {
    return rounds
        .where((round) => round.warTags.any((tag) => tag != "#0"))
        .toList();
  }

  CwlLeagueRound getCurrentRounds() {
    if (rounds.length == 1) {
      return rounds.first;
    } else if (rounds.length <= 6) {
      return rounds[rounds.length - 2];
    }
    return rounds[rounds.length - 1];
  }
}
