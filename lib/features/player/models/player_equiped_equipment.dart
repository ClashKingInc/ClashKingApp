import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';

class PlayerEquipedEquipment extends PlayerItem {
  final String village;

  PlayerEquipedEquipment(
      {required String name,
      required int level,
      required int maxLevel,
      required this.village})
      : super(
          name: name,
          type: 'equipment',
          imageUrl: ImageAssets.getGearImage(name),
          level: level,
          maxLevel: maxLevel,
        );

  factory PlayerEquipedEquipment.fromJson(Map<String, dynamic> json) {
    return PlayerEquipedEquipment(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
    );
  }
}
