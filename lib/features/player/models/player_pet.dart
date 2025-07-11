import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';

class PlayerPet extends PlayerItem {
  final String village;

  PlayerPet(
      {required super.name,
      required super.level,
      required super.maxLevel,
      required this.village})
      : super(
          isUnlocked: true,
          type: 'pet',
          imageUrl: ImageAssets.getPetImage(name),
        );

  factory PlayerPet.fromJson(Map<String, dynamic> json) {
    return PlayerPet(
      name: json['name'],
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
    );
  }

  factory PlayerPet.fromRaw(
      {required String name,
      required int level,
      required int maxLevel,
      required bool isUnlocked,
      Map<String, dynamic>? meta,
    Map<String, dynamic>? rawJson}) {
    return PlayerPet(
      name: name,
      level: level,
      maxLevel: maxLevel,
      village: meta?['village'] ?? 'home',
    );
  }
}
