
class Equipment {
  final String name;
  final int level;
  final int maxLevel;
  final String village;
  late String imageUrl;
  late String type;
  late String rarity;

  Equipment(
      {required this.name,
      required this.level,
      required this.maxLevel,
      required this.village});

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
    );
  }
}
