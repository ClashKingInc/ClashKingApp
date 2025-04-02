import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';

class PlayerSpell extends PlayerItem {
  final String village;

  PlayerSpell(
      {required super.name,
      required super.level,
      required super.maxLevel,
      required this.village})
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
    );
  }
}
