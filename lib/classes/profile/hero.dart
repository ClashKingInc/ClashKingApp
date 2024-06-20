import 'package:clashkingapp/classes/profile/equiped_equipment.dart';

class Hero {
  final String name;
  final int level;
  final int maxLevel;
  final String village;
  final List<EquipedEquipment> equipment;
  late String imageUrl;
  late String type;

  Hero(
      {required this.name,
      required this.level,
      required this.maxLevel,
      required this.village,
      required this.equipment});

  factory Hero.fromJson(Map<String, dynamic> json) {
    return Hero(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
      equipment: json['equipment'] != null
          ? List<EquipedEquipment>.from(
              json['equipment'].map((x) => EquipedEquipment.fromJson(x)))
          : [],
    );
  }
}