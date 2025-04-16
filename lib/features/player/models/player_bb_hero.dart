import 'package:clashkingapp/features/player/models/player_item.dart';
import 'package:clashkingapp/core/constants/image_assets.dart';

class PlayerBuilderBaseHero extends PlayerItem {
  final String village;

  PlayerBuilderBaseHero(
      {required super.name,
      required super.level,
      required super.maxLevel,
      required this.village,
      required super.isUnlocked})
      : super(
          type: 'hero',
          imageUrl: ImageAssets.getBuilderBaseHeroImage(name),
        );

  factory PlayerBuilderBaseHero.fromJson(Map<String, dynamic> json) {
    return PlayerBuilderBaseHero(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'builderBase',
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }

  factory PlayerBuilderBaseHero.fromRaw(
      {required String name,
      required int level,
      required int maxLevel,
      required bool isUnlocked,
      Map<String, dynamic>? meta,
    Map<String, dynamic>? rawJson}) {
    return PlayerBuilderBaseHero(
      name: name,
      level: level,
      maxLevel: maxLevel,
      isUnlocked: isUnlocked,
      village: meta?['village'] ?? 'builderBase',
    );
  }
}
