import 'clan_district.dart';

class ClanCapital {
  final int capitalHallLevel;
  final List<ClanDistrict> districts;

  ClanCapital({required this.capitalHallLevel, required this.districts});

  factory ClanCapital.fromJson(Map<String, dynamic> json) {
    final districts = (json["districts"] as List<dynamic>? ?? const []);

    return ClanCapital(
      capitalHallLevel: (json["capitalHallLevel"] as num?)?.toInt() ?? 0,
      districts: districts
          .map((district) => ClanDistrict.fromJson(district))
          .toList(),
    );
  }
}
