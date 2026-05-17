import 'dart:convert';

import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/clan/models/clan_war_log.dart';
import 'package:clashkingapp/features/clan/models/clan_war_stats_filter.dart';
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

  // ---------------------------------------------------------------------------
  // loadClanData
  // ---------------------------------------------------------------------------

  group('ClanService — loadClanData', () {
    test('returns clan from API on 200', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/clan/%23CLAN1/details'] = http.Response(
        jsonEncode(_clanJson('#CLAN1', name: 'Alpha')),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      final clan = await service.loadClanData('#CLAN1');
      expect(clan.tag, '#CLAN1');
      expect(clan.name, 'Alpha');
    });

    test('stores clan in clans map', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/clan/%23CLAN1/details'] = http.Response(
        jsonEncode(_clanJson('#CLAN1')),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadClanData('#CLAN1');
      expect(service.getClanByTag('#CLAN1'), isNotNull);
    });

    test('returns from cache when clan already loaded', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/clan/%23CLAN1/details'] = http.Response(
        jsonEncode(_clanJson('#CLAN1', name: 'Cached')),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadClanData('#CLAN1');
      // Replace stub with error — second call must still succeed via cache
      fakeApi.getStubs['/clan/%23CLAN1/details'] = http.Response('{}', 500);
      final cachedClan = await service.loadClanData('#CLAN1');
      expect(cachedClan.tag, '#CLAN1');
      expect(cachedClan.name, 'Cached');
    });

    test('sets isLoading to false after success', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/clan/%23CLAN1/details'] = http.Response(
        jsonEncode(_clanJson('#CLAN1')),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadClanData('#CLAN1');
      expect(service.isLoading, isFalse);
    });

    test('throws and resets isLoading on non-200 response', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/clan/%23CLAN1/details'] =
          http.Response('Not Found', 404);
      final service = ClanService(apiService: fakeApi);
      await expectLater(
        () => service.loadClanData('#CLAN1'),
        throwsA(anything),
      );
      expect(service.isLoading, isFalse);
    });

    test('throws on network error', () async {
      final service =
          ClanService(apiService: NetworkErrorApiService());
      await expectLater(
        () => service.loadClanData('#CLAN1'),
        throwsA(anything),
      );
      expect(service.isLoading, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // getClanAndWarData
  // ---------------------------------------------------------------------------

  group('ClanService — getClanAndWarData', () {
    test('returns clan on success', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/clan/%23CLAN1/details'] = http.Response(
        jsonEncode(_clanJson('#CLAN1', name: 'Alpha')),
        200,
      );
      fakeApi.postStubs['/war/clans/warhits'] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      final clan = await service.getClanAndWarData('#CLAN1');
      expect(clan.tag, '#CLAN1');
    });

    test('returns clan even when war stats loading fails', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/clan/%23CLAN1/details'] = http.Response(
        jsonEncode(_clanJson('#CLAN1')),
        200,
      );
      fakeApi.throwOnPost['/war/clans/warhits'] =
          Exception('war stats error');
      final service = ClanService(apiService: fakeApi);
      final clan = await service.getClanAndWarData('#CLAN1');
      expect(clan.tag, '#CLAN1');
    });
  });

  // ---------------------------------------------------------------------------
  // loadCapitalData
  // ---------------------------------------------------------------------------

  group('ClanService — loadCapitalData', () {
    test('returns empty list for empty tag list', () async {
      final service = ClanService();
      final result = await service.loadCapitalData([], 10);
      expect(result, isEmpty);
    });

    test('returns CapitalHistoryItems on 200 with items', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[''] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      final result = await service.loadCapitalData(['#CLAN1'], 5);
      expect(result, hasLength(1));
      expect(result.first.clanTag, '#CLAN1');
    });

    test('returns empty list for single tag when response has no items key',
        () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[''] = http.Response(jsonEncode({}), 200);
      final service = ClanService(apiService: fakeApi);
      final result = await service.loadCapitalData(['#CLAN1'], 5);
      expect(result, isEmpty);
    });

    test('returns empty list on network error without throwOnError', () async {
      final service =
          ClanService(apiService: NetworkErrorApiService());
      final result = await service.loadCapitalData(['#CLAN1'], 5);
      expect(result, isEmpty);
    });

    test('sets isLoading to false after network error', () async {
      final service =
          ClanService(apiService: NetworkErrorApiService());
      await service.loadCapitalData(['#CLAN1'], 5);
      expect(service.isLoading, isFalse);
    });

    test('throws on network error when throwOnError = true', () async {
      final service =
          ClanService(apiService: NetworkErrorApiService());
      await expectLater(
        () => service.loadCapitalData(['#CLAN1'], 5, throwOnError: true),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // linkCapitalToClans
  // ---------------------------------------------------------------------------

  group('ClanService — linkCapitalToClans', () {
    test('assigns empty CapitalHistoryItems when no matching entry', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/details'] = http.Response(
        jsonEncode({'items': [_clanJson('#CLAN1')]}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadAllClanData(['#CLAN1']);
      service.linkCapitalToClans();
      expect(service.clans['#CLAN1']?.clanCapitalRaid, isNotNull);
    });

    test('links capital history to matching clan', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/clans/details'] = http.Response(
        jsonEncode({'items': [_clanJson('#CLAN1')]}),
        200,
      );
      fakeApi.getStubs[''] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadAllClanData(['#CLAN1']);
      await service.loadCapitalData(['#CLAN1'], 5);
      service.linkCapitalToClans();
      expect(service.clans['#CLAN1']?.clanCapitalRaid?.clanTag, '#CLAN1');
    });
  });

  // ---------------------------------------------------------------------------
  // loadWarLogData (200 success path)
  // ---------------------------------------------------------------------------

  group('ClanService — loadWarLogData (200 success)', () {
    test('returns ClanWarLog with correct clanTag on 200 with empty items',
        () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[''] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      final result = await service.loadWarLogData(['#CLAN1']);
      expect(result, hasLength(1));
      expect(result.first.clanTag, '#CLAN1');
    });

    test('populates warLogList on 200', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[''] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      await service.loadWarLogData(['#CLAN1']);
      expect(service.warLogList, hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // loadClanWarStatsWithFilter
  // ---------------------------------------------------------------------------

  group('ClanService — loadClanWarStatsWithFilter', () {
    test('returns ClanWarStats when item matches clan tag', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/clans/warhits'] = http.Response(
        jsonEncode({
          'items': [
            {
              'tag': '#CLAN1',
              'clan_tag': '#CLAN1',
              'players': [],
              'wars': [],
            }
          ]
        }),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      final result = await service.loadClanWarStatsWithFilter(
        '#CLAN1',
        const ClanWarStatsFilter(),
      );
      expect(result, isNotNull);
      expect(result?.clanTag, '#CLAN1');
    });

    test('returns null when items list is empty', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/clans/warhits'] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      final result = await service.loadClanWarStatsWithFilter(
        '#CLAN1',
        const ClanWarStatsFilter(),
      );
      expect(result, isNull);
    });

    test('returns null when no item matches clan tag', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/clans/warhits'] = http.Response(
        jsonEncode({
          'items': [
            {
              'tag': '#OTHER',
              'clan_tag': '#OTHER',
              'players': [],
              'wars': [],
            }
          ]
        }),
        200,
      );
      final service = ClanService(apiService: fakeApi);
      final result = await service.loadClanWarStatsWithFilter(
        '#CLAN1',
        const ClanWarStatsFilter(),
      );
      expect(result, isNull);
    });

    test('throws on non-200 response', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/clans/warhits'] =
          http.Response('error', 503);
      final service = ClanService(apiService: fakeApi);
      await expectLater(
        () => service.loadClanWarStatsWithFilter(
          '#CLAN1',
          const ClanWarStatsFilter(),
        ),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // processBulkClanData
  // ---------------------------------------------------------------------------

  group('ClanService — processBulkClanData', () {
    test('populates clans map from clan_details', () async {
      final service = ClanService();
      await service.processBulkClanData(
        {
          'clan_details': {
            '#CLAN1': {'tag': '#CLAN1', 'name': 'Bulk Clan'},
          }
        },
        ['#CLAN1'],
      );
      expect(service.clans.containsKey('#CLAN1'), isTrue);
      expect(service.clans['#CLAN1']?.name, 'Bulk Clan');
    });

    test('populates joinLeaveList from join_leave_data', () async {
      final service = ClanService();
      await service.processBulkClanData(
        {
          'join_leave_data': {
            '#CLAN1': {
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
          }
        },
        ['#CLAN1'],
      );
      expect(service.joinLeaveList, hasLength(1));
      expect(service.joinLeaveList.first.clanTag, '#CLAN1');
    });

    test('populates capitalHistory from capital_data', () async {
      final service = ClanService();
      await service.processBulkClanData(
        {
          'capital_data': [
            {'clan_tag': '#CLAN1', 'history': [], 'stats': null}
          ]
        },
        ['#CLAN1'],
      );
      expect(service.capitalHistory, hasLength(1));
      expect(service.capitalHistory.first.clanTag, '#CLAN1');
    });

    test('populates warLogList from war_log_data', () async {
      final service = ClanService();
      await service.processBulkClanData(
        {
          'war_log_data': [
            {'clan_tag': '#CLAN1', 'items': []}
          ]
        },
        ['#CLAN1'],
      );
      expect(service.warLogList, hasLength(1));
      expect(service.warLogList.first.clanTag, '#CLAN1');
    });

    test('populates warStatsList from clan_war_stats', () async {
      final service = ClanService();
      await service.processBulkClanData(
        {
          'clan_war_stats': [
            {'clan_tag': '#CLAN1', 'players': [], 'wars': []}
          ]
        },
        ['#CLAN1'],
      );
      expect(service.warStatsList, hasLength(1));
      expect(service.warStatsList.first.clanTag, '#CLAN1');
    });

    test('notifies listeners when notify = true', () async {
      final service = ClanService();
      var notified = false;
      service.addListener(() => notified = true);
      await service.processBulkClanData({}, [], notify: true);
      expect(notified, isTrue);
    });

    test('does not notify when notify = false', () async {
      final service = ClanService();
      var notified = false;
      service.addListener(() => notified = true);
      await service.processBulkClanData({}, [], notify: false);
      expect(notified, isFalse);
    });
  });
}

