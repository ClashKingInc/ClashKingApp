class ClanLeague {
  final int id;
  final String name;
  final String? smallIconUrl;
  final String? mediumIconUrl;
  final String? tinyIconUrl;

  ClanLeague({
    required this.id,
    required this.name,
    this.smallIconUrl,
    this.mediumIconUrl,
    this.tinyIconUrl,
  });

  factory ClanLeague.fromJson(Map<String, dynamic> json) {
    return ClanLeague(
      id: (json["id"] as num?)?.toInt() ?? 0,
      name: json["name"]?.toString() ?? "",
      smallIconUrl: json["iconUrls"]?["small"]?.toString(),
      mediumIconUrl: json["iconUrls"]?["medium"]?.toString(),
      tinyIconUrl: json["iconUrls"]?["tiny"]?.toString(),
    );
  }

  factory ClanLeague.unranked() {
    return ClanLeague(
      id: 0,
      name: "Unranked",
      smallIconUrl: null,
      mediumIconUrl: null,
      tinyIconUrl: null,
    );
  }
}
