class ClanBadgeUrls {
  final String small;
  final String medium;
  final String large;

  ClanBadgeUrls({required this.small, required this.medium, required this.large});

  factory ClanBadgeUrls.fromJson(Map<String, dynamic> json) {
    return ClanBadgeUrls(
      small: json["small"],
      medium: json["medium"],
      large: json["large"],
    );
  }
}
