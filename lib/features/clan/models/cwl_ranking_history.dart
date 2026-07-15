class CwlRankingHistoryEntry {
  final String season;
  final String? league;
  final int rank;
  final int stars;
  final double destruction;
  final int roundsWon;
  final int roundsTied;
  final int roundsLost;

  const CwlRankingHistoryEntry({
    required this.season,
    required this.league,
    required this.rank,
    required this.stars,
    required this.destruction,
    required this.roundsWon,
    required this.roundsTied,
    required this.roundsLost,
  });

  factory CwlRankingHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rounds = json['rounds'] as Map<String, dynamic>? ?? const {};
    return CwlRankingHistoryEntry(
      season: json['season']?.toString() ?? '',
      league: json['league']?.toString(),
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      stars: (json['stars'] as num?)?.toInt() ?? 0,
      destruction: (json['destruction'] as num?)?.toDouble() ?? 0.0,
      roundsWon: (rounds['won'] as num?)?.toInt() ?? 0,
      roundsTied: (rounds['tied'] as num?)?.toInt() ?? 0,
      roundsLost: (rounds['lost'] as num?)?.toInt() ?? 0,
    );
  }
}
