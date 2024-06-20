
class Troop {
  final String name;
  final int level;
  final int maxLevel;
  final String village;
  final bool superTroopIsActive;
  late String imageUrl;
  late String type;

  Troop(
      {required this.name,
      required this.level,
      required this.maxLevel,
      required this.superTroopIsActive,
      required this.village});

  factory Troop.fromJson(Map<String, dynamic> json) {
    String name = json['name'] ?? 'No name';
    if (name == 'Baby Dragon' && json['village'] == 'builderBase') {
      name = 'Baby Dragon 2';
    }

    return Troop(
      name: name,
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      superTroopIsActive: json['superTroopIsActive'] ?? false,
      village: json['village'] ?? 'home',
    );
  }
}