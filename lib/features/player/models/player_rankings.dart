class PlayerRankings {
  final String tag;
  final PlayerRankingCategory homeVillage;
  final PlayerRankingCategory builderBase;

  const PlayerRankings({
    required this.tag,
    required this.homeVillage,
    required this.builderBase,
  });

  factory PlayerRankings.fromJson(Map<String, dynamic> json) {
    return PlayerRankings(
      tag: json['tag'] as String? ?? '',
      homeVillage: PlayerRankingCategory.fromJson(
        json['homeVillage'] as Map<String, dynamic>? ?? const {},
      ),
      builderBase: PlayerRankingCategory.fromJson(
        json['builderBase'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class PlayerRankingCategory {
  final int? points;
  final int? globalRank;
  final String? locationId;
  final String? locationName;
  final String? countryCode;
  final int? localRank;

  const PlayerRankingCategory({
    this.points,
    this.globalRank,
    this.locationId,
    this.locationName,
    this.countryCode,
    this.localRank,
  });

  factory PlayerRankingCategory.fromJson(Map<String, dynamic> json) {
    return PlayerRankingCategory(
      points: (json['points'] as num?)?.toInt(),
      globalRank: (json['globalRank'] as num?)?.toInt(),
      locationId: json['locationId'] as String?,
      locationName: json['locationName'] as String?,
      countryCode: json['countryCode'] as String?,
      localRank: (json['localRank'] as num?)?.toInt(),
    );
  }
}
