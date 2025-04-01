import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';

class PlayerSiegeMachine extends PlayerItem {
  final String village;
  final bool superTroopIsActive;

  PlayerSiegeMachine(
      {required String name,
      required int level,
      required int maxLevel,
      required this.superTroopIsActive,
      required this.village})
      : super(
          name: name,
          type: 'pet',
          imageUrl: ImageAssets.getSiegeMachineImage(name),
          level: level,
          maxLevel: maxLevel,
        );

  factory PlayerSiegeMachine.fromJson(Map<String, dynamic> json) {
    return PlayerSiegeMachine(
      name: json['name'],
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      superTroopIsActive: json['superTroopIsActive'] ?? false,
      village: json['village'] ?? 'home',
    );
  }
}
