import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WarCwl.fromJson', () {
    test('ignores null CWL wars and keeps valid entries', () {
      final warCwl = WarCwl.fromJson({
        'clan_tag': '#2QPCJQQ2U',
        'isInWar': false,
        'isInCwl': true,
        'war_info': {
          'state': 'notInWar',
          'currentWarInfo': null,
        },
        'league_info': {
          'state': 'inWar',
          'season': '2025-05',
          'clans': [
            {
              'tag': '#2QPCJQQ2U',
              'name': 'Test Clan',
              'badgeUrls': null,
              'clanLevel': 10,
              'members': [],
              'town_hall_levels': <String, int>{},
            },
          ],
          'rounds': [
            {
              'warTags': ['#0'],
            },
          ],
        },
        'war_league_infos': [
          null,
          {
            'war_tag': '#WAR',
            'state': 'inWar',
            'teamSize': 15,
            'attacksPerMember': 1,
            'clan': {
              'tag': '#2QPCJQQ2U',
              'name': 'Test Clan',
              'badgeUrls': null,
              'clanLevel': 10,
              'members': [],
            },
            'opponent': {
              'tag': '#VY2J0LL',
              'name': 'Opponent',
              'badgeUrls': null,
              'clanLevel': 9,
              'members': [],
            },
          },
        ],
      }, null);

      expect(warCwl.tag, '#2QPCJQQ2U');
      expect(warCwl.isInCwl, isTrue);
      expect(warCwl.warInfo.state, 'notInWar');
      expect(warCwl.warLeagueInfos, hasLength(1));
      expect(warCwl.teamSize, 15);
      expect(warCwl.warLeagueInfos.single.clan?.badgeUrls.large, isEmpty);
    });
  });
}
