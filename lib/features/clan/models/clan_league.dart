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
      id: json["id"],
      name: json["name"],
      smallIconUrl: json["iconUrls"]?["small"],
      mediumIconUrl: json["iconUrls"]?["medium"],
      tinyIconUrl: json["iconUrls"]?["tiny"],
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
