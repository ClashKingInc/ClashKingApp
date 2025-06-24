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
      id: json["id"],
      name: json["name"],
      districtHallLevel: json["districtHallLevel"],
    );
  }
}
