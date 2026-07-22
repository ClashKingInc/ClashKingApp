import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/player/models/player_item.dart';

class PlayerBuilderBaseTroop extends PlayerItem {
  final String village;
  final bool superTroopIsActive;

  PlayerBuilderBaseTroop({
    required super.name,
    required super.level,
    required super.maxLevel,
    required this.superTroopIsActive,
    required this.village,
    required super.isUnlocked,
    super.meta,
  }) : super(
         type: 'builderBase',
         imageUrl: ImageAssets.getBuilderBaseTroopImage(name),
       );

  factory PlayerBuilderBaseTroop.fromJson(Map<String, dynamic> json) {
    return PlayerBuilderBaseTroop(
      name: json['name']?.toString() ?? 'Unknown',
      level: json['level'] ?? 0,
      maxLevel: json['maxLevel'] ?? 0,
      superTroopIsActive: json['superTroopIsActive'] ?? false,
      village: json['village'] ?? 'home',
      isUnlocked: true,
    );
  }

  factory PlayerBuilderBaseTroop.fromRaw({
    required String name,
    required int level,
    required int maxLevel,
    required bool isUnlocked,
    Map<String, dynamic>? meta,
    bool? superTroopIsActive,
    Map<String, dynamic>? rawJson,
  }) {
    final normalizedLevel = isUnlocked
        ? _validBuilderBaseLevel(level, meta)
        : level;
    return PlayerBuilderBaseTroop(
      name: name,
      level: normalizedLevel,
      maxLevel: maxLevel,
      isUnlocked: isUnlocked,
      superTroopIsActive: superTroopIsActive ?? false,
      village: meta?['village'] ?? 'home',
      meta: meta,
    );
  }
}

int _validBuilderBaseLevel(int apiLevel, Map<String, dynamic>? meta) {
  if (apiLevel <= 0) return apiLevel;
  final levels = meta?['levels'];
  if (levels is! List) return apiLevel;
  final available = levels
      .whereType<Map>()
      .map((level) => level['level'])
      .map((level) => level is num ? level.toInt() : int.tryParse('$level'))
      .whereType<int>()
      .where((level) => level > 0);
  if (available.isEmpty) return apiLevel;
  final minimum = available.reduce(
    (lowest, level) => level < lowest ? level : lowest,
  );
  return apiLevel < minimum ? minimum : apiLevel;
}
