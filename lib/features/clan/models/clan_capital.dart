import 'clan_district.dart';

class ClanCapital {
  final int capitalHallLevel;
  final List<ClanDistrict> districts;

  ClanCapital({
    required this.capitalHallLevel,
    required this.districts,
  });

  factory ClanCapital.fromJson(Map<String, dynamic> json) {
    return ClanCapital(
      capitalHallLevel: json["capitalHallLevel"],
      districts: (json["districts"] as List)
          .map((district) => ClanDistrict.fromJson(district))
          .toList(),
    );
  }
}
