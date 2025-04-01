import 'package:clashkingapp/features/player/models/player_equiped_equipment.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';

class PlayerHero extends PlayerItem {
  final String village;
  final List<PlayerEquipedEquipment> equipment;

  PlayerHero({
    required String name,
    required int level,
    required int maxLevel,
    required this.village,
    required this.equipment,
  }) : super(
          name: name,
          type: 'hero',
          imageUrl: ImageAssets.getHeroImage(name),
          level: level,
          maxLevel: maxLevel,
        );

  factory PlayerHero.fromJson(Map<String, dynamic> json) {
    return PlayerHero(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
      equipment: json['equipment'] != null
          ? List<PlayerEquipedEquipment>.from(
              json['equipment'].map((x) => PlayerEquipedEquipment.fromJson(x)))
          : [],
    );
  }
}
