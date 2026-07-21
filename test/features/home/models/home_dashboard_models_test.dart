import 'package:clashkingapp/features/home/models/home_dashboard_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes a complete Home activity item', () {
    final item = HomeActivityItem.fromJson({
      'type': 'player_history',
      'timestamp': '2026-07-20T12:30:00Z',
      'event_type': 'hero_upgrade',
      'player_tag': '#ABC',
      'clan_tag': null,
      'player_name': 'Archer',
      'townhall_level': 17,
      'value': 101,
      'data': {'hero': 'Archer Queen'},
    });

    expect(item.playerTag, '#ABC');
    expect(item.clanTag, isNull);
    expect(item.value, 101);
    expect(item.isNewSince(DateTime.parse('2026-07-20T12:00:00Z')), isTrue);
  });

  test('rejects malformed activity instead of silently dropping it', () {
    expect(
      () => HomeActivityItem.fromJson({
        'type': 'unknown',
        'timestamp': 'not-a-date',
        'event_type': 'change',
        'player_tag': '#ABC',
        'data': <String, dynamic>{},
      }),
      throwsFormatException,
    );
  });

  test('finds active and recently completed upgrade timers', () {
    final record = HomeUpgradeRecord.fromJson({
      'player_tag': '#ABC',
      'updated_at': '2026-07-20T12:00:00Z',
      'data': {
        'buildings': [
          {'name': 'Cannon', 'upgrade_timer': 600},
          {'name': 'Archer Tower', 'timer': 1800},
        ],
      },
    });

    final timers = record.timers();
    expect(timers.map((timer) => timer.name), ['Cannon', 'Archer Tower']);
    expect(timers.first.finishesAt, DateTime.parse('2026-07-20T12:10:00Z'));
    expect(
      timers.first.isRecentlyCompleted(DateTime.parse('2026-07-20T12:20:00Z')),
      isTrue,
    );
  });

  test('anchors upgrade timers to the snapshot timestamp', () {
    final capturedAt = DateTime.utc(2026, 7, 20, 12);
    final record = HomeUpgradeRecord(
      playerTag: '#ABC',
      data: {
        'timestamp': capturedAt.millisecondsSinceEpoch ~/ 1000,
        'buildings': [
          {'name': 'Cannon', 'timer': 900},
        ],
      },
      updatedAt: capturedAt.add(const Duration(hours: 2)),
    );

    expect(
      record.timers().single.finishesAt,
      capturedAt.add(const Duration(minutes: 15)),
    );
  });
}
