class PlayerSeasonPass {
  final String season;
  final int points;

  PlayerSeasonPass({
    required this.season,
    required this.points,
  });

  factory PlayerSeasonPass.fromJson(Map<String, dynamic> json) {
    return PlayerSeasonPass(
      season: json['season'] ?? '',
      points: json['points'] ?? 0,
    );
  }
}
