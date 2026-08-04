import 'package:clashkingapp/features/clan/models/clan_war_log.dart';
import 'package:clashkingapp/features/player/models/player_join_leave.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('player history retains clan metadata from each event', () {
    final page = PlayerJoinLeavePage.fromJson({
      'available': 72,
      'items': [
        {
          'time': '2026-08-03T12:00:00Z',
          'type': 'join',
          'tag': '#PLAYER',
          'name': 'Player',
          'townHallLevel': 17,
          'clan': {
            'tag': '#CLAN',
            'name': 'Clan',
            'badge': 'https://example.com/badge.png',
          },
        },
      ],
    });

    expect(page.available, 72);
    expect(page.items.single.clan?.tag, '#CLAN');
    expect(page.items.single.th, 17);
  });

  test('war log exposes reconstructed state and display wars', () {
    final log = ClanWarLog.fromJson({
      'isPrivate': true,
      'reconstructed': true,
      'items': [
        {
          'result': 'win',
          'endTime': '2026-08-03T12:00:00Z',
          'teamSize': 15,
          'attacksPerMember': 2,
          'clan': {'tag': '#CLAN', 'name': 'Clan', 'badgeUrls': {}},
          'opponent': {'tag': '#OTHER', 'name': 'Other', 'badgeUrls': {}},
        },
      ],
    }, '#CLAN');

    expect(log.reconstructed, isTrue);
    expect(log.isPrivate, isTrue);
    expect(log.wars.single.state, 'warEnded');
    expect(log.wars.single.warType, 'random');
  });
}
