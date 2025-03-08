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
      id: json["id"],
      name: json["name"],
      isCountry: json["isCountry"],
      countryCode: json["countryCode"],
    );
  }
}
