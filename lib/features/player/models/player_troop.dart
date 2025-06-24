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
      required this.village,
      required super.isUnlocked})
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
      isUnlocked: true,
      village: json['village'] ?? 'home',
    );
  }

  factory PlayerTroop.fromRaw({
    required String name,
    required int level,
    required int maxLevel,
    required bool isUnlocked,
    Map<String, dynamic>? meta,
    bool? superTroopIsActive,
    Map<String, dynamic>? rawJson
  }) {
    return PlayerTroop(
      name: name,
      level: level,
      maxLevel: maxLevel,
      isUnlocked: isUnlocked,
      superTroopIsActive: superTroopIsActive ?? false,
      village: meta?['village'] ?? 'home',
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
