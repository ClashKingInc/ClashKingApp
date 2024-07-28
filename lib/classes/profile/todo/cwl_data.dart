
class CwlData {
  final int attackLimit;
  final int attacksDone;

  CwlData({required this.attackLimit, required this.attacksDone});

  factory CwlData.fromJson(Map<String, dynamic> json) {
    return CwlData(
      attackLimit: json['attack_limit'] ?? 0,
      attacksDone: json['attacks_done'] ?? 0,
    );
  }
}