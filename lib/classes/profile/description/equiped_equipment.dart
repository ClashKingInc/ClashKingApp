
class EquipedEquipment {
  final String name;
  final int level;
  final int maxLevel;
  final String village;
  String imageUrl;
  late String type;

  EquipedEquipment(
      {required this.name,
      required this.level,
      required this.maxLevel,
      required this.village,
      this.imageUrl = 'https://clashkingfiles.b-cdn.net/logos/crown-arrow-dark-bg/ClashKing-1.png'});

  factory EquipedEquipment.fromJson(Map<String, dynamic> json) {
    return EquipedEquipment(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
      imageUrl: json['imageUrl'] ??
          'https://clashkingfiles.b-cdn.net/logos/crown-arrow-dark-bg/ClashKing-1.png',
    );
  }
}