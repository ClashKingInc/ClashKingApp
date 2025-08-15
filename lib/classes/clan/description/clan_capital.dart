class ClanCapital {
  final int capitalHallLevel;

  ClanCapital({required this.capitalHallLevel});

  factory ClanCapital.fromJson(Map<String, dynamic> json) {
    return ClanCapital(
      capitalHallLevel: json['capitalHallLevel'],
    );
  }
}