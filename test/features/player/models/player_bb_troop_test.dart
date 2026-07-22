import 'package:clashkingapp/features/player/models/player_bb_troop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hogGliderMeta = {
    'village': 'builderBase',
    'levels': [
      {'level': 15},
      {'level': 16},
      {'level': 20},
    ],
  };

  test('raises an impossible owned API level to the first static level', () {
    final troop = PlayerBuilderBaseTroop.fromRaw(
      name: 'Hog Glider',
      level: 1,
      maxLevel: 20,
      isUnlocked: true,
      meta: hogGliderMeta,
    );

    expect(troop.level, 15);
  });

  test('preserves an owned level that is already valid', () {
    final troop = PlayerBuilderBaseTroop.fromRaw(
      name: 'Hog Glider',
      level: 16,
      maxLevel: 20,
      isUnlocked: true,
      meta: hogGliderMeta,
    );

    expect(troop.level, 16);
  });

  test('keeps an unowned troop locked at level zero', () {
    final troop = PlayerBuilderBaseTroop.fromRaw(
      name: 'Hog Glider',
      level: 0,
      maxLevel: 20,
      isUnlocked: false,
      meta: hogGliderMeta,
    );

    expect(troop.level, 0);
  });
}
