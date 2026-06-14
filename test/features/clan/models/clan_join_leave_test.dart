import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _statsJson({
  int totalEvents = 10,
  int totalJoins = 6,
  int totalLeaves = 4,
  int uniquePlayers = 5,
  int movingPlayers = 2,
  int playerStillInClan = 3,
  int playerLeftClan = 1,
  int rejoinedPlayers = 1,
  String? firstEvent,
  String? lastEvent,
  int? mostMovingHour,
  double? avgTimeBetweenJoinLeave,
  List<dynamic>? mostMovingPlayers,
}) =>
    <String, dynamic>{
      'total_events': totalEvents,
      'total_joins': totalJoins,
      'total_leaves': totalLeaves,
      'unique_players': uniquePlayers,
      'moving_players': movingPlayers,
      'players_still_in_clan': playerStillInClan,
      'players_left_forever': playerLeftClan,
      'rejoined_players': rejoinedPlayers,
      if (firstEvent != null) 'first_event': firstEvent,
      if (lastEvent != null) 'last_event': lastEvent,
      if (mostMovingHour != null) 'most_moving_hour': mostMovingHour,
      if (avgTimeBetweenJoinLeave != null)
        'avg_time_between_join_leave': avgTimeBetweenJoinLeave,
      'most_moving_players': mostMovingPlayers ?? [],
    };

Map<String, dynamic> _joinLeaveJson({
  String tag = '#CLAN1',
  int tsStart = 1000,
  int tsEnd = 2000,
  List<dynamic>? events,
}) =>
    <String, dynamic>{
      'clan_tag': tag,
      'timestamp_start': tsStart,
      'timestamp_end': tsEnd,
      'stats': _statsJson(),
      'join_leave_list': events ?? [],
    };

Map<String, dynamic> _eventJson({
  String type = 'join',
  String clan = '#CLAN1',
  String time = '2024-01-15T10:00:00',
  String playerTag = '#P1',
  String name = 'Hero',
  int th = 14,
}) =>
    <String, dynamic>{
      'type': type,
      'clan': clan,
      'time': time,
      'tag': playerTag,
      'name': name,
      'th': th,
    };

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ---------------------------------------------------------------------------
  // JoinLeaveEvent.fromJson — all fields present
  // ---------------------------------------------------------------------------

  group('JoinLeaveEvent.fromJson — all fields present', () {
    test('parses type correctly', () {
      final event = JoinLeaveEvent.fromJson(_eventJson(type: 'leave'));
      expect(event.type, 'leave');
    });

    test('parses clan tag correctly', () {
      final event = JoinLeaveEvent.fromJson(_eventJson(clan: '#TESTCLAN'));
      expect(event.clan, '#TESTCLAN');
    });

    test('parses player tag correctly', () {
      final event = JoinLeaveEvent.fromJson(_eventJson(playerTag: '#ABC123'));
      expect(event.tag, '#ABC123');
    });

    test('parses name correctly', () {
      final event = JoinLeaveEvent.fromJson(_eventJson(name: 'Warrior'));
      expect(event.name, 'Warrior');
    });

    test('parses townhall level correctly', () {
      final event = JoinLeaveEvent.fromJson(_eventJson(th: 16));
      expect(event.th, 16);
    });

    test('parses time as DateTime', () {
      final event =
          JoinLeaveEvent.fromJson(_eventJson(time: '2024-06-01T12:30:00'));
      expect(event.time, DateTime.parse('2024-06-01T12:30:00'));
    });

    test('full round-trip preserves all fields', () {
      final json = _eventJson(
        type: 'join',
        clan: '#MYHOME',
        time: '2023-12-25T00:00:00',
        playerTag: '#XYZ',
        name: 'Santa',
        th: 15,
      );
      final event = JoinLeaveEvent.fromJson(json);
      expect(event.type, 'join');
      expect(event.clan, '#MYHOME');
      expect(event.tag, '#XYZ');
      expect(event.name, 'Santa');
      expect(event.th, 15);
    });

    test('type defaults to empty string when null', () {
      // The source uses json['type'] ?? "" — if key is present with value it works
      final event = JoinLeaveEvent.fromJson(
          _eventJson()..['type'] = null,);
      expect(event.type, '');
    });

    test('clan defaults to empty string when null', () {
      final event = JoinLeaveEvent.fromJson(
          _eventJson()..['clan'] = null,);
      expect(event.clan, '');
    });

    test('tag defaults to empty string when null', () {
      final event = JoinLeaveEvent.fromJson(
          _eventJson()..['tag'] = null,);
      expect(event.tag, '');
    });

    test('name defaults to empty string when null', () {
      final event = JoinLeaveEvent.fromJson(
          _eventJson()..['name'] = null,);
      expect(event.name, '');
    });

    test('th defaults to 0 when null', () {
      final event = JoinLeaveEvent.fromJson(
          _eventJson()..['th'] = null,);
      expect(event.th, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // ClanJoinLeave.fromJson
  // ---------------------------------------------------------------------------

  group('ClanJoinLeave.fromJson', () {
    test('parses clan tag correctly', () {
      final obj = ClanJoinLeave.fromJson(_joinLeaveJson(tag: '#MYCLAN'));
      expect(obj.clanTag, '#MYCLAN');
    });

    test('parses timestamp_start', () {
      final obj = ClanJoinLeave.fromJson(_joinLeaveJson(tsStart: 5000));
      expect(obj.timeStampStart, 5000);
    });

    test('parses timestamp_end', () {
      final obj = ClanJoinLeave.fromJson(_joinLeaveJson(tsEnd: 9999));
      expect(obj.timeStampEnd, 9999);
    });

    test('parses empty join_leave_list', () {
      final obj = ClanJoinLeave.fromJson(_joinLeaveJson(events: []));
      expect(obj.joinLeaveList, isEmpty);
    });

    test('parses non-empty join_leave_list', () {
      final obj = ClanJoinLeave.fromJson(_joinLeaveJson(events: [
        _eventJson(playerTag: '#P1'),
        _eventJson(playerTag: '#P2', type: 'leave'),
      ]));
      expect(obj.joinLeaveList, hasLength(2));
      expect(obj.joinLeaveList.first.tag, '#P1');
      expect(obj.joinLeaveList.last.type, 'leave');
    });

    test('uses empty string for missing clan_tag', () {
      final json = _joinLeaveJson();
      json.remove('clan_tag');
      final obj = ClanJoinLeave.fromJson(json);
      expect(obj.clanTag, '');
    });

    test('uses 0 for missing timestamp_start', () {
      final json = _joinLeaveJson();
      json.remove('timestamp_start');
      final obj = ClanJoinLeave.fromJson(json);
      expect(obj.timeStampStart, 0);
    });

    test('uses 0 for missing timestamp_end', () {
      final json = _joinLeaveJson();
      json.remove('timestamp_end');
      final obj = ClanJoinLeave.fromJson(json);
      expect(obj.timeStampEnd, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // ClanJoinLeave.empty()
  // ---------------------------------------------------------------------------

  group('ClanJoinLeave.empty()', () {
    test('clanTag is empty string', () {
      expect(ClanJoinLeave.empty().clanTag, '');
    });

    test('timeStampStart is 0', () {
      expect(ClanJoinLeave.empty().timeStampStart, 0);
    });

    test('timeStampEnd is 0', () {
      expect(ClanJoinLeave.empty().timeStampEnd, 0);
    });

    test('joinLeaveList is empty', () {
      expect(ClanJoinLeave.empty().joinLeaveList, isEmpty);
    });

    test('stats.totalEvents is 0', () {
      expect(ClanJoinLeave.empty().stats.totalEvents, 0);
    });

    test('stats.totalJoins is 0', () {
      expect(ClanJoinLeave.empty().stats.totalJoins, 0);
    });

    test('stats.totalLeaves is 0', () {
      expect(ClanJoinLeave.empty().stats.totalLeaves, 0);
    });

    test('stats.mostMovingPlayers is empty', () {
      expect(ClanJoinLeave.empty().stats.mostMovingPlayers, isEmpty);
    });

    test('returns a valid ClanJoinLeave instance', () {
      expect(ClanJoinLeave.empty(), isA<ClanJoinLeave>());
    });
  });

  // ---------------------------------------------------------------------------
  // JoinLeaveStats.fromJson
  // ---------------------------------------------------------------------------

  group('JoinLeaveStats.fromJson', () {
    test('parses totalEvents', () {
      final stats = JoinLeaveStats.fromJson(_statsJson(totalEvents: 42));
      expect(stats.totalEvents, 42);
    });

    test('parses totalJoins', () {
      final stats = JoinLeaveStats.fromJson(_statsJson(totalJoins: 20));
      expect(stats.totalJoins, 20);
    });

    test('parses totalLeaves', () {
      final stats = JoinLeaveStats.fromJson(_statsJson(totalLeaves: 5));
      expect(stats.totalLeaves, 5);
    });

    test('parses uniquePlayers', () {
      final stats = JoinLeaveStats.fromJson(_statsJson(uniquePlayers: 8));
      expect(stats.uniquePlayers, 8);
    });

    test('parses movingPlayers', () {
      final stats = JoinLeaveStats.fromJson(_statsJson(movingPlayers: 3));
      expect(stats.movingPlayers, 3);
    });

    test('parses playerStillInClan', () {
      final stats =
          JoinLeaveStats.fromJson(_statsJson(playerStillInClan: 7));
      expect(stats.playerStillInClan, 7);
    });

    test('parses playerLeftClan', () {
      final stats = JoinLeaveStats.fromJson(_statsJson(playerLeftClan: 2));
      expect(stats.playerLeftClan, 2);
    });

    test('parses rejoinedPlayers', () {
      final stats = JoinLeaveStats.fromJson(_statsJson(rejoinedPlayers: 1));
      expect(stats.rejoinedPlayers, 1);
    });

    test('parses avgTimeBetweenJoinLeave as double', () {
      final stats = JoinLeaveStats.fromJson(
          _statsJson(avgTimeBetweenJoinLeave: 3.14));
      expect(stats.avgTimeBetweenJoinLeave, closeTo(3.14, 0.001));
    });

    test('avgTimeBetweenJoinLeave is null when missing', () {
      final stats = JoinLeaveStats.fromJson(_statsJson());
      expect(stats.avgTimeBetweenJoinLeave, isNull);
    });

    test('parses mostMovingPlayers list', () {
      final stats = JoinLeaveStats.fromJson(_statsJson(
        mostMovingPlayers: [
          {'tag': '#P1', 'name': 'Alpha', 'count': 5},
          {'tag': '#P2', 'name': 'Beta', 'count': 3},
        ],
      ));
      expect(stats.mostMovingPlayers, hasLength(2));
      expect(stats.mostMovingPlayers.first.tag, '#P1');
      expect(stats.mostMovingPlayers.last.count, 3);
    });

    test('uses 0 defaults for missing numeric fields', () {
      final stats = JoinLeaveStats.fromJson(<String, dynamic>{
        'most_moving_players': [],
      });
      expect(stats.totalEvents, 0);
      expect(stats.totalJoins, 0);
      expect(stats.totalLeaves, 0);
      expect(stats.uniquePlayers, 0);
      expect(stats.movingPlayers, 0);
    });

    test('parses firstEvent as string', () {
      final stats = JoinLeaveStats.fromJson(
          _statsJson(firstEvent: '2024-01-01T00:00:00'));
      expect(stats.firstEvent, '2024-01-01T00:00:00');
    });

    test('parses lastEvent as string', () {
      final stats =
          JoinLeaveStats.fromJson(_statsJson(lastEvent: '2024-12-31T23:59:59'));
      expect(stats.lastEvent, '2024-12-31T23:59:59');
    });

    test('parses mostMovingHour', () {
      final stats = JoinLeaveStats.fromJson(_statsJson(mostMovingHour: 14));
      expect(stats.mostMovingHour, 14);
    });
  });

  // ---------------------------------------------------------------------------
  // MostActivePlayer.fromJson
  // ---------------------------------------------------------------------------

  group('MostActivePlayer.fromJson', () {
    test('parses tag, name, count', () {
      final player = MostActivePlayer.fromJson(
          {'tag': '#MVP', 'name': 'King', 'count': 12});
      expect(player.tag, '#MVP');
      expect(player.name, 'King');
      expect(player.count, 12);
    });

    test('defaults to empty strings and 0 count on null fields', () {
      final player = MostActivePlayer.fromJson(
          <String, dynamic>{'tag': null, 'name': null, 'count': null});
      expect(player.tag, '');
      expect(player.name, '');
      expect(player.count, 0);
    });

    test('parses count correctly', () {
      final player = MostActivePlayer.fromJson(
          {'tag': '#A', 'name': 'B', 'count': 99});
      expect(player.count, 99);
    });
  });
}
