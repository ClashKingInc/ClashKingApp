class PlayerRankings {
  final String tag;
  final String? countryCode;
  final String? countryName;
  final int? localRank;
  final int? globalRank;
  final int? builderGlobalRank;
  final int? builderLocalRank;

  PlayerRankings({
    required this.tag,
    this.countryCode,
    this.countryName,
    this.localRank,
    this.globalRank,
    this.builderGlobalRank,
    this.builderLocalRank,
  });

  factory PlayerRankings.fromJson(Map<String, dynamic> json) {
    return PlayerRankings(
      tag: json['tag'] ?? "",
      countryCode: json['country_code'] ?? "",
      countryName: json['country_name'] ?? "",
      localRank: json['local_rank'] ?? 0,
      globalRank: json['global_rank'] ?? 0,
      builderGlobalRank: json['builder_global_rank'] ?? 0,
      builderLocalRank: json['builder_local_rank'] ?? 0,
    );
  }
}
