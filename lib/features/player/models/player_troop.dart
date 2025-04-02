import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';

class PlayerTroop extends PlayerItem {
  final String village;
  final bool superTroopIsActive;

  PlayerTroop(
      {required super.name,
      required super.level,
      required super.maxLevel,
      required this.superTroopIsActive,
      required this.village})
      : super(
          type: 'troop',
          imageUrl: ImageAssets.getTroopImage(name),
        );

  factory PlayerTroop.fromJson(Map<String, dynamic> json) {
    String name = json['name'] ?? 'No name';
    if (name == 'Baby Dragon' && json['village'] == 'builderBase') {
      name = 'Baby Dragon 2';
    }

    return PlayerTroop(
      name: name,
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      superTroopIsActive: json['superTroopIsActive'] ?? false,
      village: json['village'] ?? 'home',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'level': level,
      'maxLevel': maxLevel,
      'superTroopIsActive': superTroopIsActive,
      'village': village,
    };
  }
}
