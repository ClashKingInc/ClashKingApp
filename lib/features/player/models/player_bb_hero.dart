import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';

class PlayerBuilderBaseHero extends PlayerItem {
  final String village;

  PlayerBuilderBaseHero({
    required String name,
    required int level,
    required int maxLevel,
    required this.village,
  }) : super(
          name: name,
          type: 'hero',
          imageUrl: ImageAssets.getBuilderBaseHeroImage(name),
          level: level,
          maxLevel: maxLevel,
        );

  factory PlayerBuilderBaseHero.fromJson(Map<String, dynamic> json) {
    return PlayerBuilderBaseHero(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'builderBase',
    );
  }
}
