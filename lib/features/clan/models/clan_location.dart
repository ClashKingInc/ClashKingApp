class ClanLocation {
  final int id;
  final String name;
  final bool isCountry;
  final String? countryCode;

  ClanLocation({
    required this.id,
    required this.name,
    required this.isCountry,
    this.countryCode,
  });

  factory ClanLocation.fromJson(Map<String, dynamic> json) {
    return ClanLocation(
      id: (json["id"] as num?)?.toInt() ?? 0,
      name: json["name"]?.toString() ?? "",
      isCountry: json["isCountry"] ?? false,
      countryCode: json["countryCode"]?.toString(),
    );
  }
}
