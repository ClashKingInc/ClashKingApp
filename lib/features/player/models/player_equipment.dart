import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';

class PlayerEquipment extends PlayerItem {
  final String village;
  final String rarity;

  PlayerEquipment(
      {required super.name,
      required super.level,
      required super.maxLevel,
      required this.rarity,
      required this.village})
      : super(
          type: 'gear',
          imageUrl: ImageAssets.getGearImage(name),
        );

  factory PlayerEquipment.fromJson(Map<String, dynamic> json) {
    return PlayerEquipment(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
      rarity: GameDataService.gearsData["gears"]?[json['name']]?["rarity"] ?? "1",
    );
  }
}
