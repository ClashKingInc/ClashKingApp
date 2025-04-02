import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';

class PlayerBuilderBaseTroop extends PlayerItem {
  final String village;
  final bool superTroopIsActive;

  PlayerBuilderBaseTroop(
      {required super.name,
      required super.level,
      required super.maxLevel,
      required this.superTroopIsActive,
      required this.village})
      : super(
          type: 'builderBase',
          imageUrl: ImageAssets.getBuilderBaseTroopImage(name),
        );

  factory PlayerBuilderBaseTroop.fromJson(Map<String, dynamic> json) {
    return PlayerBuilderBaseTroop(
      name: json['name'],
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      superTroopIsActive: json['superTroopIsActive'] ?? false,
      village: json['village'] ?? 'home',
    );
  }
}
