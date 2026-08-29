import 'package:clashkingapp/features/player/models/player_activity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses normalized troop upgrade and boost changes', () {
    final feed = PlayerActivityFeed.fromJson({
      'items': [
        {
          'time': '2026-08-16T12:00:00Z',
          'type': 'troop_level',
          'item': {'id': 1, 'name': 'Super Wizard'},
          'townhall_level': 17,
          'previous': 11,
          'current': 12,
        },
        {
          'time': '2026-08-16T13:00:00Z',
          'type': 'super_troop_boost',
          'item': {'id': 1, 'name': 'Super Wizard'},
          'previous': 0,
          'current': 12,
        },
      ],
    });

    expect(feed.items, hasLength(2));
    expect(feed.items.first.kind, PlayerActivityKind.superTroopBoost);
    expect(feed.items.last.kind, PlayerActivityKind.troopUpgrade);
    expect(feed.items.last.townHallLevel, 17);
  });

  test('parses supported upgrades and excludes name changes', () {
    final feed = PlayerActivityFeed.fromJson({
      'items': [
        {
          'time': '2026-08-16T14:00:00Z',
          'type': 'townhall_level',
          'previous': 16,
          'current': 17,
        },
        {
          'time': '2026-08-16T13:00:00Z',
          'type': 'equipment_level',
          'item': {'id': 7, 'name': 'Giant Gauntlet'},
          'previous': 20,
          'current': 21,
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
    ]);
    expect(feed.items.first.currentLevel, 17);
  });
}
