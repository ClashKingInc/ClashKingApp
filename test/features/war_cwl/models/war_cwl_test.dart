import 'package:clashkingapp/features/clan/models/clan_badge.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_league.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_league_round.dart';
import 'package:clashkingapp/features/war_cwl/models/war_clan.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/war_member.dart';
import 'package:flutter_test/flutter_test.dart';

WarMember _member(String tag) => WarMember(
  tag: tag,
  name: 'Player $tag',
  townhallLevel: 14,
  mapPosition: 1,
  opponentAttacks: 0,
);

WarClan _clan(String tag, {List<WarMember> members = const []}) => WarClan(
  tag: tag,
  name: 'Clan $tag',
  badgeUrls: ClanBadgeUrls(small: '', medium: '', large: ''),
  clanLevel: 10,
  attacks: 0,
  stars: 0,
  destructionPercentage: 0.0,
  members: members,
);

WarInfo _war(
  String state,
  String clanTag,
  String oppTag, {
  String? warTag,
  List<WarMember> clanMembers = const [],
}) => WarInfo(
  state: state,
  tag: warTag,
  clan: _clan(clanTag, members: clanMembers),
  opponent: _clan(oppTag),
);

WarCwl _warCwl(List<WarInfo> wars, {CwlLeague? league}) => WarCwl(
  tag: '#CLAN',
  isInWar: false,
  isInCwl: true,
  warInfo: WarInfo(state: 'notInWar'),
  leagueInfo: league,
  warLeagueInfos: wars,
);

void main() {
  group('WarCwl.fromJson', () {
    test('ignores null CWL wars and keeps valid entries', () {
      final warCwl = WarCwl.fromJson({
        'clan_tag': '#2QPCJQQ2U',
        'isInWar': false,
        'isInCwl': true,
        'war_info': {'state': 'notInWar', 'currentWarInfo': null},
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

  group('WarCwl.teamSize getter', () {
    test('uses warLeagueInfos first element when available', () {
      final cwl = _warCwl([_war('inWar', '#A', '#B')]);
      expect(cwl.teamSize, 0);
    });

    test('falls back to warInfo.teamSize when warLeagueInfos is empty', () {
      final cwl = WarCwl(
        tag: '#CLAN',
        isInWar: true,
        isInCwl: false,
        warInfo: WarInfo(state: 'inWar', teamSize: 20),
        warLeagueInfos: [],
      );
      expect(cwl.teamSize, 20);
    });
  });

  group('WarCwl.getActiveWarByTag', () {
    test('returns inWar war when clan is in clan position', () {
      final cwl = _warCwl([
        _war('preparation', '#CLAN', '#OPP1'),
        _war('inWar', '#CLAN', '#OPP2'),
      ]);
      final result = cwl.getActiveWarByTag('#CLAN');
      expect(result, isNotNull);
      expect(result!.state, 'inWar');
    });

    test('finds war when clan is in opponent position', () {
      final cwl = _warCwl([_war('inWar', '#OPP', '#CLAN')]);
      final result = cwl.getActiveWarByTag('#CLAN');
      expect(result, isNotNull);
      expect(result!.clan!.tag, '#CLAN');
    });

    test('falls back to preparation when no inWar', () {
      final cwl = _warCwl([_war('preparation', '#CLAN', '#OPP')]);
      final result = cwl.getActiveWarByTag('#CLAN');
      expect(result, isNotNull);
      expect(result!.state, 'preparation');
    });

    test('falls back to warEnded when no inWar or preparation', () {
      final cwl = _warCwl([_war('warEnded', '#CLAN', '#OPP')]);
      final result = cwl.getActiveWarByTag('#CLAN');
      expect(result, isNotNull);
      expect(result!.state, 'warEnded');
    });

    test('returns null when no wars match the clan tag', () {
      final cwl = _warCwl([_war('inWar', '#OTHER', '#YET')]);
      expect(cwl.getActiveWarByTag('#CLAN'), isNull);
    });

    test('returns null when warLeagueInfos is empty', () {
      final cwl = _warCwl([]);
      expect(cwl.getActiveWarByTag('#CLAN'), isNull);
    });

    test('normalizes # prefix when tag supplied without it', () {
      final cwl = _warCwl([_war('inWar', '#CLAN', '#OPP')]);
      final result = cwl.getActiveWarByTag('CLAN');
      expect(result, isNotNull);
      expect(result!.state, 'inWar');
    });
  });

  group('WarCwl.getActiveWarForClan', () {
    test('returns notInCwl state when no war found', () {
      final cwl = _warCwl([]);
      final result = cwl.getActiveWarForClan('#CLAN');
      expect(result.state, 'notInCwl');
    });

    test('returns war info when war found', () {
      final cwl = _warCwl([_war('inWar', '#CLAN', '#OPP')]);
      final result = cwl.getActiveWarForClan('#CLAN');
      expect(result.state, 'inWar');
    });
  });

  group('WarCwl.getRoundForWarTag', () {
    test('returns round -1 when leagueInfo is null', () {
      final cwl = _warCwl([]);
      final result = cwl.getRoundForWarTag('#WARTAG');
      expect(result?.roundNumber, -1);
    });

    test('returns round -1 when war tag is not found in any round', () {
      final league = CwlLeague(
        state: 'ended',
        season: '2025-05',
        clans: [],
        rounds: [
          CwlLeagueRound(roundNumber: 1, warTags: ['#OTHER']),
        ],
      );
      final cwl = _warCwl([], league: league);
      final result = cwl.getRoundForWarTag('#NOTFOUND');
      expect(result?.roundNumber, -1);
    });

    test('returns matching round when war tag is found', () {
      final league = CwlLeague(
        state: 'ended',
        season: '2025-05',
        clans: [],
        rounds: [
          CwlLeagueRound(roundNumber: 1, warTags: ['#W1']),
          CwlLeagueRound(roundNumber: 2, warTags: ['#W2', '#W3']),
        ],
      );
      final cwl = _warCwl([], league: league);
      final result = cwl.getRoundForWarTag('#W2');
      expect(result?.roundNumber, 2);
    });
  });

  group('WarCwl.getWarInfoFromTag', () {
    test('returns unknown WarInfo when war tag is not found', () {
      final cwl = _warCwl([_war('inWar', '#A', '#B', warTag: '#WAR1')]);
      final result = cwl.getWarInfoFromTag('#NOTEXIST');
      expect(result?.state, 'unknown');
    });

    test('returns matching WarInfo when war tag matches', () {
      final cwl = _warCwl([
        _war('inWar', '#A', '#B', warTag: '#WAR1'),
        _war('warEnded', '#C', '#D', warTag: '#WAR2'),
      ]);
      final result = cwl.getWarInfoFromTag('#WAR2');
      expect(result?.state, 'warEnded');
    });
  });

  group('WarCwl.getMemberPresence', () {
    test('returns not in war when no active war found', () {
      final cwl = _warCwl([]);
      final presence = cwl.getMemberPresence('#P1', '#CLAN');
      expect(presence.isInWar, isFalse);
    });

    test('returns in war with correct attack count', () {
      final cwl = _warCwl([
        _war('inWar', '#CLAN', '#OPP', clanMembers: [_member('#P1')]),
      ]);
      final presence = cwl.getMemberPresence('#P1', '#CLAN');
      expect(presence.isInWar, isTrue);
      expect(presence.attacksDone, 0);
    });

    test('returns not in war when member not in the war', () {
      final cwl = _warCwl([
        _war('inWar', '#CLAN', '#OPP', clanMembers: [_member('#P1')]),
      ]);
      final presence = cwl.getMemberPresence('#NOBODY', '#CLAN');
      expect(presence.isInWar, isFalse);
    });
  });

  group('WarCwl.getActiveWarByPlayerTag', () {
    test('returns null when no wars exist', () {
      final cwl = _warCwl([]);
      expect(cwl.getActiveWarByPlayerTag('#P1'), isNull);
    });

    test('finds inWar war containing player in clan', () {
      final cwl = _warCwl([
        _war('inWar', '#CLAN', '#OPP', clanMembers: [_member('#P1')]),
      ]);
      final result = cwl.getActiveWarByPlayerTag('#P1');
      expect(result, isNotNull);
      expect(result!.state, 'inWar');
      expect(result.clan!.tag, '#CLAN');
    });

    test(
      'finds inWar war and reorders when player is in opponent position',
      () {
        final cwl = _warCwl([
          _war('inWar', '#CLAN', '#OPP', clanMembers: [_member('#P1')]),
        ]);
        // Member P1 is in clan already — no swap needed
        final result = cwl.getActiveWarByPlayerTag('#P1');
        expect(result!.clan!.tag, '#CLAN');
      },
    );

    test('falls back to preparation when no inWar', () {
      final cwl = _warCwl([
        _war('preparation', '#CLAN', '#OPP', clanMembers: [_member('#P1')]),
      ]);
      final result = cwl.getActiveWarByPlayerTag('#P1');
      expect(result, isNotNull);
      expect(result!.state, 'preparation');
    });

    test('falls back to warEnded when no active or prep war', () {
      final cwl = _warCwl([
        _war('warEnded', '#CLAN', '#OPP', clanMembers: [_member('#P1')]),
      ]);
      final result = cwl.getActiveWarByPlayerTag('#P1');
      expect(result, isNotNull);
      expect(result!.state, 'warEnded');
    });

    test('returns null when player is not in any war', () {
      final cwl = _warCwl([
        _war('inWar', '#CLAN', '#OPP', clanMembers: [_member('#OTHER')]),
      ]);
      expect(cwl.getActiveWarByPlayerTag('#P1'), isNull);
    });
  });
}
