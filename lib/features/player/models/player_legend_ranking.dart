class PlayerLegendRanking {
  final String tag;
  final String name;
  final int expLevel;
  final int trophies;
  final int attackWins;
  final int defenseWins;
  final int rank;
  final String season;
  final PlayerLegendClan clan;

  PlayerLegendRanking({
    required this.tag,
    required this.name,
    required this.expLevel,
    required this.trophies,
    required this.attackWins,
    required this.defenseWins,
    required this.rank,
    required this.season,
    required this.clan,
  });

  factory PlayerLegendRanking.fromJson(Map<String, dynamic> json) {
    return PlayerLegendRanking(
      tag: json['tag'] ?? "",
      name: json['name'] ?? "",
      expLevel: json['expLevel'] ?? 0,
      trophies: json['trophies'] ?? 0,
      attackWins: json['attackWins'] ?? 0,
      defenseWins: json['defenseWins'] ?? 0,
      rank: json['rank'] ?? 0,
      season: json['season'] ?? "",
      clan: json['clan'] != null
          ? PlayerLegendClan.fromJson(json['clan'])
          : PlayerLegendClan(tag: "", name: "", badgeUrls: {}),
    );
  }
}

class PlayerLegendClan {
  final String tag;
  final String name;
  final Map<String, String> badgeUrls;

  PlayerLegendClan({
    required this.tag,
    required this.name,
    required this.badgeUrls,
  });

  factory PlayerLegendClan.fromJson(Map<String, dynamic> json) {
    return PlayerLegendClan(
      tag: json['tag'] ?? "",
      name: json['name'] ?? "",
      badgeUrls: Map<String, String>.from(json['badgeUrls'])
    );
  }
}
