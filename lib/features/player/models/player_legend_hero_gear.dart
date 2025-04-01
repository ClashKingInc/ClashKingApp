class LegendHeroGear {
  final String name;
  final int level;

  LegendHeroGear({
    required this.name,
    required this.level,
  });

  factory LegendHeroGear.fromJson(Map<String, dynamic> json) {
    return LegendHeroGear(
      name: json['name'] ?? '',
      level: json['level'] ?? 0,
    );
  }
}