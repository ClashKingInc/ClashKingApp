
class RaidData {
  final int attacksDone;
  final int attackLimit;

  RaidData({required this.attacksDone, required this.attackLimit});

  factory RaidData.fromJson(Map<String, dynamic> json) {
    return RaidData(
      attacksDone: json['attacks_done'] ?? 0,
      attackLimit: json['attack_limit'] ?? 0,
    );
  }
}