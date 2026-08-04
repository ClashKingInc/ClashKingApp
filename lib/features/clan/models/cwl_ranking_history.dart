class CwlRankingHistoryEntry {
  final String season;
  final int? leagueId;
  final String? league;
  final int rank;
  final int stars;
  final double destruction;
  final int roundsWon;
  final int roundsTied;
  final int roundsLost;
  final bool hasStanding;

  const CwlRankingHistoryEntry({
    required this.season,
    required this.leagueId,
    required this.league,
    required this.rank,
    required this.stars,
    required this.destruction,
    required this.roundsWon,
    required this.roundsTied,
    required this.roundsLost,
    this.hasStanding = true,
  });

  factory CwlRankingHistoryEntry.fromJson(Map<String, dynamic> json) {
    final standing = json['standing'] as Map<String, dynamic>?;
    final rounds = json['rounds'] as Map<String, dynamic>? ?? const {};
    final warLeague = json['warLeague'] as Map<String, dynamic>?;
    return CwlRankingHistoryEntry(
      season: json['season']?.toString() ?? '',
      leagueId: (warLeague?['id'] as num?)?.toInt(),
      league: warLeague?['name']?.toString() ?? json['league']?.toString(),
      rank:
          (standing?['groupRank'] as num?)?.toInt() ??
          (json['rank'] as num?)?.toInt() ??
          0,
      stars:
          (standing?['stars'] as num?)?.toInt() ??
          (json['stars'] as num?)?.toInt() ??
          0,
      destruction:
          (standing?['destruction'] as num?)?.toDouble() ??
          (json['destruction'] as num?)?.toDouble() ??
          0.0,
      roundsWon:
          (standing?['wins'] as num?)?.toInt() ??
          (rounds['won'] as num?)?.toInt() ??
          0,
      roundsTied:
          (standing?['ties'] as num?)?.toInt() ??
          (rounds['tied'] as num?)?.toInt() ??
          0,
      roundsLost:
          (standing?['losses'] as num?)?.toInt() ??
          (rounds['lost'] as num?)?.toInt() ??
          0,
      hasStanding:
          standing != null ||
          json['rank'] != null ||
          json['stars'] != null ||
          json['destruction'] != null,
    );
  }
}
