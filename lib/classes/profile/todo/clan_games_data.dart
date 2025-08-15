
class ClanGames {
  final String clanTag;
  final int points;

  ClanGames({required this.clanTag, required this.points});

  factory ClanGames.fromJson(Map<String, dynamic> json) {
    return ClanGames(
      clanTag: json['clanTag'] ?? '',
      points: json['points'] ?? 0,
    );
  }
}