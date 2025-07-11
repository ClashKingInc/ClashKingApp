class PlayerClanGames {
  final String season;
  final int points;
  final String clanTag;

  PlayerClanGames({
    required this.season,
    required this.points,
    required this.clanTag,
  });

  factory PlayerClanGames.fromJson(String season, Map<String, dynamic> json) {
    return PlayerClanGames(
      season: season,
      clanTag: json['clan'] ?? '',
      points: json['points'] ?? 0,
    );
  }
}
