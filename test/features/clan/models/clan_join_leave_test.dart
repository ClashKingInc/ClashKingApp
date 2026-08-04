import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _joinLeaveJson({
  String tag = '#CLAN1',
  int available = 10,
  int uniquePlayers = 5,
  List<dynamic>? events,
}) => <String, dynamic>{
  'clan_tag': tag,
  'available': available,
  'uniquePlayers': uniquePlayers,
  'items': events ?? [],
};

Map<String, dynamic> _eventJson({
  String type = 'join',
  String clan = '#CLAN1',
  String time = '2024-01-15T10:00:00',
  String playerTag = '#P1',
  String name = 'Hero',
  int th = 14,
}) => <String, dynamic>{
  'type': type,
  'clan': {'tag': clan, 'name': 'Test Clan', 'badge': 'badge.png'},
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
      expect(event.clan?.tag, '#TESTCLAN');
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
      final event = JoinLeaveEvent.fromJson(
        _eventJson(time: '2024-06-01T12:30:00'),
      );
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
      expect(event.clan?.tag, '#MYHOME');
      expect(event.tag, '#XYZ');
      expect(event.name, 'Santa');
      expect(event.th, 15);
    });

    test('type defaults to empty string when null', () {
      // The source uses json['type'] ?? "" — if key is present with value it works
      final event = JoinLeaveEvent.fromJson(_eventJson()..['type'] = null);
      expect(event.type, '');
    });

    test('clan defaults to null when absent', () {
      final event = JoinLeaveEvent.fromJson(_eventJson()..['clan'] = null);
      expect(event.clan, isNull);
    });

    test('tag defaults to empty string when null', () {
      final event = JoinLeaveEvent.fromJson(_eventJson()..['tag'] = null);
      expect(event.tag, '');
    });

    test('name defaults to empty string when null', () {
      final event = JoinLeaveEvent.fromJson(_eventJson()..['name'] = null);
      expect(event.name, '');
    });

    test('th defaults to 0 when null', () {
      final event = JoinLeaveEvent.fromJson(_eventJson()..['th'] = null);
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

    test('parses available', () {
      final obj = ClanJoinLeave.fromJson(_joinLeaveJson(available: 5000));
      expect(obj.available, 5000);
    });

    test('parses uniquePlayers', () {
      final obj = ClanJoinLeave.fromJson(_joinLeaveJson(uniquePlayers: 9999));
      expect(obj.uniquePlayers, 9999);
    });

    test('parses empty join_leave_list', () {
      final obj = ClanJoinLeave.fromJson(_joinLeaveJson(events: []));
      expect(obj.joinLeaveList, isEmpty);
    });

    test('parses non-empty join_leave_list', () {
      final obj = ClanJoinLeave.fromJson(
        _joinLeaveJson(
          events: [
            _eventJson(playerTag: '#P1'),
            _eventJson(playerTag: '#P2', type: 'leave'),
          ],
        ),
      );
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

    test('uses 0 for missing available', () {
      final json = _joinLeaveJson();
      json.remove('available');
      json['stats'] = <String, dynamic>{};
      final obj = ClanJoinLeave.fromJson(json);
      expect(obj.available, 0);
    });

    test('uses 0 for missing uniquePlayers', () {
      final json = _joinLeaveJson();
      json.remove('uniquePlayers');
      json['stats'] = <String, dynamic>{};
      final obj = ClanJoinLeave.fromJson(json);
      expect(obj.uniquePlayers, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // ClanJoinLeave.empty()
  // ---------------------------------------------------------------------------

  group('ClanJoinLeave.empty()', () {
    test('clanTag is empty string', () {
      expect(ClanJoinLeave.empty().clanTag, '');
    });

    test('available is 0', () {
      expect(ClanJoinLeave.empty().available, 0);
    });

    test('uniquePlayers is 0', () {
      expect(ClanJoinLeave.empty().uniquePlayers, 0);
    });

    test('joinLeaveList is empty', () {
      expect(ClanJoinLeave.empty().joinLeaveList, isEmpty);
    });

    test('returns a valid ClanJoinLeave instance', () {
      expect(ClanJoinLeave.empty(), isA<ClanJoinLeave>());
    });
  });
}
