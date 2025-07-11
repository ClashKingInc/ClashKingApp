import 'package:clashkingapp/features/player/models/player_equiped_equipment.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';

class PlayerHero extends PlayerItem {
  final String village;
  final List<PlayerEquipedEquipment> equipment;

  PlayerHero({
    required super.name,
    required super.level,
    required super.maxLevel,
    required this.village,
    required this.equipment,
    required super.isUnlocked,
  }) : super(
          type: 'hero',
          imageUrl: ImageAssets.getHeroImage(name),
        );

  factory PlayerHero.fromJson(Map<String, dynamic> json) {
    return PlayerHero(
        name: json['name'] ?? 'No name',
        level: json['level'] ?? 0,
        maxLevel: json['maxLevel'] ?? 0,
        village: json['village'] ?? 'home',
        equipment: json['equipment'] != null
            ? List<PlayerEquipedEquipment>.from(json['equipment']
                .map((x) => PlayerEquipedEquipment.fromJson(x)))
            : [],
        isUnlocked: true);
  }

  factory PlayerHero.fromRaw({
    required String name,
    required int level,
    required int maxLevel,
    required bool isUnlocked,
    Map<String, dynamic>? meta,
    Map<String, dynamic>? rawJson,
  }) {
    return PlayerHero(
      name: name,
      level: level,
      maxLevel: maxLevel,
      isUnlocked: isUnlocked,
      equipment: rawJson?['equipment'] != null
          ? List<PlayerEquipedEquipment>.from(rawJson!['equipment']
              .map((x) => PlayerEquipedEquipment.fromJson(x)))
          : [],
      village: meta?['village'] ?? 'home',
    );
  }
}
