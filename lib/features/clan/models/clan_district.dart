class ClanDistrict {
  final int id;
  final String name;
  final int districtHallLevel;

  ClanDistrict({
    required this.id,
    required this.name,
    required this.districtHallLevel,
  });

  factory ClanDistrict.fromJson(Map<String, dynamic> json) {
    return ClanDistrict(
      id: (json["id"] as num?)?.toInt() ?? 0,
      name: json["name"]?.toString() ?? "",
      districtHallLevel: (json["districtHallLevel"] as num?)?.toInt() ?? 0,
    );
  }
}
