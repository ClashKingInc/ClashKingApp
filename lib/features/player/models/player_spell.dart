import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';

class PlayerSpell extends PlayerItem {
  final String village;

  PlayerSpell(
      {required super.name,
      required super.level,
      required super.maxLevel,
      required this.village,
      required super.isUnlocked})
      : super(
          type: 'spell',
          imageUrl: ImageAssets.getSpellImage(name),
        );

  factory PlayerSpell.fromJson(Map<String, dynamic> json) {
    return PlayerSpell(
      name: json['name'] ?? 'No name',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
      isUnlocked: true,
    );
  }

  factory PlayerSpell.fromRaw(
      {required String name,
      required int level,
      required int maxLevel,
      required bool isUnlocked,
      Map<String, dynamic>? meta,
    Map<String, dynamic>? rawJson}) {
    return PlayerSpell(
      name: name,
      level: level,
      maxLevel: maxLevel,
      isUnlocked: isUnlocked,
      village: meta?['village'] ?? 'home',
    );
  }
}
