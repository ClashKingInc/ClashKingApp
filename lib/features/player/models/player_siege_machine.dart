import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';

class PlayerSiegeMachine extends PlayerItem {
  final String village;

  PlayerSiegeMachine(
      {required super.name,
      required super.level,
      required super.maxLevel,
      required this.village,
      required super.isUnlocked})
      : super(
          type: 'pet',
          imageUrl: ImageAssets.getSiegeMachineImage(name),
        );

  factory PlayerSiegeMachine.fromJson(Map<String, dynamic> json) {
    return PlayerSiegeMachine(
      name: json['name'],
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      village: json['village'] ?? 'home',
      isUnlocked: true,
    );
  }

  factory PlayerSiegeMachine.fromRaw(
      {required String name,
      required int level,
      required int maxLevel,
      required bool isUnlocked,
      Map<String, dynamic>? meta,
      bool? superTroopIsActive,
    Map<String, dynamic>? rawJson}) {
    return PlayerSiegeMachine(
      name: name,
      level: level,
      maxLevel: maxLevel,
      isUnlocked: isUnlocked,
      village: meta?['village'] ?? 'home',
    );
  }
}
