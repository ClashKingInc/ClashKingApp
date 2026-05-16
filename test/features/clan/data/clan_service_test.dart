import 'dart:convert';

import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan_war_log.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

Map<String, dynamic> _clanJson(String tag, {String name = 'Test Clan'}) =>
    <String, dynamic>{'tag': tag, 'name': name};

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('ClanService — initial state', () {
    test('starts not loading', () {
      final service = ClanService();
      expect(service.isLoading, isFalse);
    });

    test('clans map starts empty', () {
      final service = ClanService();
      expect(service.clans, isEmpty);
    });

    test('fetchedClans starts empty', () {
      final service = ClanService();
      expect(service.fetchedClans, isEmpty);
    });

    test('getClanByTag returns null when no clans loaded', () {
      final service = ClanService();
      expect(service.getClanByTag('#UNKNOWN'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // loadAllClanData
  // ---------------------------------------------------------------------------

  group('ClanService — loadAllClanData (empty)', () {
    test('does nothing for empty tag list', () async {
      final service = ClanService();
      await service.loadAllClanData([]);
      expect(service.clans, isEmpty);
    });
  });

  group('ClanService — loadAllClanData (FakeApiService, 200)', () {
    late FakeApiService fakeApi;
    late ClanService service;

    setUp(() {
      fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/details'] = http.Response(
        jsonEncode({
          'items': [
            _clanJson('#CLAN1', name: 'Alpha'),
            _clanJson('#CLAN2', name: 'Bravo'),
          ]
        }),
        200,
      );
      service = ClanService(apiService: fakeApi);
    });

    test('populates fetchedClans', () async {
      await service.loadAllClanData(['#CLAN1', '#CLAN2']);
      expect(service.fetchedClans, hasLength(2));
    });

    test('populates clans map by tag', () async {
      await service.loadAllClanData(['#CLAN1', '#CLAN2']);
      expect(service.clans.containsKey('#CLAN1'), isTrue);
      expect(service.getClanByTag('#CLAN2')?.name, 'Bravo');
    });

    test('sets isLoading to false', () async {
      await service.loadAllClanData(['#CLAN1']);
      expect(service.isLoading, isFalse);
    });

    test('notifies listeners', () async {
      var notifyCount = 0;
      service.addListener(() => notifyCount++);
      await service.loadAllClanData(['#CLAN1']);
      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });

  group('ClanService — loadAllClanData (FakeApiService, errors)', () {
    test('resets isLoading to false on 500', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/details'] =
          http.Response('error', 500);
      final service = ClanService(apiService: fakeApi);
      await service.loadAllClanData(['#CLAN1']);
      expect(service.isLoading, isFalse);
    });

    test('throws on 503 when throwOnError = true', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/details'] =
          http.Response('error', 503);
      final service = ClanService(apiService: fakeApi);
      await expectLater(
        () => service.loadAllClanData(['#CLAN1'], throwOnError: true),
        throwsA(isA<Exception>()),
      );
    });

    test('does not throw on network error when throwOnError = false', () async {
      final service =
          ClanService(apiService: NetworkErrorApiService());
      await expectLater(
        () => service.loadAllClanData(['#CLAN1']),
        returnsNormally,
      );
    });

    test('throws on network error when throwOnError = true', () async {
      final service =
          ClanService(apiService: NetworkErrorApiService());
      await expectLater(
        () => service.loadAllClanData(['#CLAN1'], throwOnError: true),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // loadClanWarStatsData
  // ---------------------------------------------------------------------------

  group('ClanService — loadClanWarStatsData', () {
    test('returns empty list for empty tag list', () async {
      final service = ClanService();
      final result = await service.loadClanWarStatsData([]);
      expect(result, isEmpty);
    });

    test('returns war stats list on 200 with items', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/clans/warhits'] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      final result = await service.loadClanWarStatsData(['#CLAN1']);
      expect(result, isEmpty);
    });

    test('returns empty list on error without throwOnError', () async {
      final service =
          ClanService(apiService: NetworkErrorApiService());
      final result = await service.loadClanWarStatsData(['#CLAN1']);
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // loadClanJoinLeaveData
  // ---------------------------------------------------------------------------

  group('ClanService — loadClanJoinLeaveData', () {
    test('returns empty list for empty tag list', () async {
      final service = ClanService();
      final result = await service.loadClanJoinLeaveData([]);
      expect(result, isEmpty);
    });

    test('populates joinLeaveList on 200', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/join-leave?current_season=true'] =
          http.Response(
        jsonEncode({
          'items': [
            {
              'clan_tag': '#CLAN1',
              'timestamp_start': 0,
              'timestamp_end': 0,
              'stats': {
                'total_events': 0,
                'total_joins': 0,
                'total_leaves': 0,
                'unique_players': 0,
                'moving_players': 0,
                'players_still_in_clan': 0,
                'players_left_forever': 0,
                'rejoined_players': 0,
                'most_moving_players': [],
              },
              'join_leave_list': [],
            }
          ]
        }),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      final result =
          await service.loadClanJoinLeaveData(['#CLAN1']);
      expect(result, isNotEmpty);
    });

    test('sets isLoading to false after error', () async {
      final service =
          ClanService(apiService: NetworkErrorApiService());
      await service.loadClanJoinLeaveData(['#CLAN1']);
      expect(service.isLoading, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // linkWarsToClans
  // ---------------------------------------------------------------------------

  group('ClanService — linkWarsToClans', () {
    test('links WarCwl to matching Clan by tag', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/details'] = http.Response(
        jsonEncode({'items': [_clanJson('#CLAN1')]}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadAllClanData(['#CLAN1']);

      final warCwl = WarCwl(
        tag: '#CLAN1',
        isInWar: false,
        isInCwl: false,
        warInfo: WarInfo(state: 'notInWar'),
        warLeagueInfos: [],
      );
      service.linkWarsToClans(service.clans.values.toList(), [warCwl]);
      expect(service.clans['#CLAN1']?.warCwl, isNotNull);
    });

    test('does nothing for non-matching tag', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/details'] = http.Response(
        jsonEncode({'items': [_clanJson('#CLAN1')]}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadAllClanData(['#CLAN1']);

      final warCwl = WarCwl(
        tag: '#OTHER',
        isInWar: false,
        isInCwl: false,
        warInfo: WarInfo(state: 'notInWar'),
        warLeagueInfos: [],
      );
      service.linkWarsToClans(service.clans.values.toList(), [warCwl]);
      expect(service.clans['#CLAN1']?.warCwl, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // linkJoinLeaveToClans
  // ---------------------------------------------------------------------------

  group('ClanService — linkJoinLeaveToClans', () {
    test('assigns empty JoinLeave when no matching entry', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/details'] = http.Response(
        jsonEncode({'items': [_clanJson('#CLAN1')]}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadAllClanData(['#CLAN1']);
      service.linkJoinLeaveToClans(); // joinLeaveList is empty
      expect(service.clans['#CLAN1']?.joinLeave, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // loadWarLogData
  // ---------------------------------------------------------------------------

  group('ClanService — loadWarLogData', () {
    test('returns empty list for empty tags', () async {
      final service = ClanService();
      final result = await service.loadWarLogData([]);
      expect(result, isEmpty);
    });

    test('returns ClanWarLog with empty items on 403', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[''] = http.Response('Forbidden', 403);
      final service = ClanService(apiService: fakeApi);
      final result = await service.loadWarLogData(['#CLAN1']);
      expect(result, hasLength(1));
      expect(result.first.items, isEmpty);
    });

    test('returns empty list on network error without throwOnError', () async {
      final service =
          ClanService(apiService: NetworkErrorApiService());
      final result = await service.loadWarLogData(['#CLAN1']);
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // linkWarLogToClans
  // ---------------------------------------------------------------------------

  group('ClanService — linkWarLogToClans', () {
    test('assigns empty ClanWarLog when no matching entry', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/details'] = http.Response(
        jsonEncode({'items': [_clanJson('#CLAN1')]}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadAllClanData(['#CLAN1']);
      service.linkWarLogToClans(); // warLogList is empty
      expect(service.clans['#CLAN1']?.clanWarLog, isNotNull);
    });

    test('links correct warLog to clan', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/details'] = http.Response(
        jsonEncode({'items': [_clanJson('#CLAN1')]}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadAllClanData(['#CLAN1']);
      service.warLogList = [ClanWarLog(items: [], clanTag: '#CLAN1')];
      service.linkWarLogToClans();
      expect(service.clans['#CLAN1']?.clanWarLog?.clanTag, '#CLAN1');
    });
  });

  // ---------------------------------------------------------------------------
  // linkWarStatsToClans
  // ---------------------------------------------------------------------------

  group('ClanService — linkWarStatsToClans', () {
    test('does not throw when warStatsList is empty', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/details'] = http.Response(
        jsonEncode({'items': [_clanJson('#CLAN1')]}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadAllClanData(['#CLAN1']);
      expect(() => service.linkWarStatsToClans(), returnsNormally);
    });
  });
}

