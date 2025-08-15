

class LegendData {
  final List<int> defenses;
  final int numAttacks;
  final List<int> attacks;

  LegendData({
    required this.defenses,
    required this.numAttacks,
    required this.attacks,
  });

  factory LegendData.fromJson(Map<String, dynamic> json) {
    return LegendData(
      defenses: List<int>.from(json['defenses'] ?? []),
      numAttacks: json['num_attacks'] ?? 0,
      attacks: List<int>.from(json['attacks'] ?? []),
    );
  }
}