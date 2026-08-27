import 'package:clashkingapp/features/player/models/player_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expands one tracked troop snapshot into upgrade and boost events', () {
    final feed = PlayerActivityFeed.fromJson({
      'items': [
        {
          'time': '2026-08-16T12:00:00Z',
          'type': 'troops',
          'previous': [
            {'name': 'Super Wizard', 'level': 11, 'superTroopIsActive': false},
          ],
          'current': [
            {'name': 'Super Wizard', 'level': 12, 'superTroopIsActive': true},
          ],
        },
      ],
    });

    expect(feed.items, hasLength(2));
    expect(
      feed.items.map((event) => event.kind),
      containsAll([
        PlayerActivityKind.troopUpgrade,
        PlayerActivityKind.superTroopBoost,
      ]),
    );
  });

  test('expands town hall, equipment, and name changes', () {
    final feed = PlayerActivityFeed.fromJson({
      'items': [
        {
          'time': '2026-08-16T14:00:00Z',
          'type': 'townHallLevel',
          'previous': 16,
          'current': 17,
        },
        {
          'time': '2026-08-16T13:00:00Z',
          'type': 'heroEquipment',
          'previous': [
            {'name': 'Giant Gauntlet', 'level': 20},
          ],
          'current': [
            {'name': 'Giant Gauntlet', 'level': 21},
          ],
        },
        {
          'time': '2026-08-16T12:00:00Z',
          'type': 'name',
          'previous': 'Old Name',
          'current': 'New Name',
        },
      ],
    });

    expect(feed.items.map((event) => event.kind), [
      PlayerActivityKind.townHallUpgrade,
      PlayerActivityKind.equipmentUpgrade,
      PlayerActivityKind.nameChange,
    ]);
    expect(feed.items.first.currentLevel, 17);
    expect(feed.items.last.previousValue, 'Old Name');
  });
}
