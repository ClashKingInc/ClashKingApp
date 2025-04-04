import 'package:clashkingapp/features/war_cwl/models/cwl_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_league_round.dart';

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

  factory CwlLeague.fromJson(Map<String, dynamic> json) {
    return CwlLeague(
      state: json['state'],
      season: json['season'],
      clans: (json['clans'] as List)
          .map((clan) => CwlClan.fromJson(clan))
          .toList(),
      rounds: (json['rounds'] as List)
          .asMap()
          .entries
          .map((entry) => CwlLeagueRound.fromJson(entry.value, entry.key))
          .toList(),
    );
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
}
