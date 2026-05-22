import 'dart:convert';

import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/war_stats_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

Map<String, dynamic> _playerBasicJson(String tag,
        {String name = 'Hero', String clanTag = '#CLAN1'}) =>
    <String, dynamic>{
      'tag': tag,
      'name': name,
      'trophies': 1000,
      'townHallLevel': 14,
      'clan': {
        'tag': clanTag,
        'name': 'Test Clan',
        'clanLevel': 5,
        'badgeUrls': {
          'small': 'https://example.com/small.png',
          'large': 'https://example.com/large.png',
          'medium': 'https://example.com/medium.png',
        },
      },
    };

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('PlayerService — initial state', () {
    test('starts not loading', () {
      final service = PlayerService();
      expect(service.isLoading, isFalse);
    });

    test('starts with no profiles', () {
      final service = PlayerService();
      expect(service.profiles, isEmpty);
    });

    test('getSelectedProfile returns null when no profiles', () {
      final playerService = PlayerService();
      final cocService = CocAccountService();
      expect(playerService.getSelectedProfile(cocService), isNull);
    });

    test('getSelectedProfile returns null when selectedTag is null', () {
      final playerService = PlayerService();
      final cocService = CocAccountService();
      cocService.addLocalAccount({'player_tag': '#ABC'});
      expect(playerService.getSelectedProfile(cocService), isNull);
    });

    test('getMinimalisticPlayerByTag returns empty json when not found', () {
      final service = PlayerService();
      expect(service.getMinimalisticPlayerByTag('#UNKNOWN'), '{}');
    });
  });

  // ---------------------------------------------------------------------------
  // initPlayerData (FakeApiService, success)
  // ---------------------------------------------------------------------------

  group('PlayerService — initPlayerData (200 with items)', () {
    late FakeApiService fakeApi;
    late PlayerService service;

    setUp(() {
      fakeApi = FakeApiService();
      fakeApi.postStubs['/players'] = http.Response(
        jsonEncode({
          'items': [
            _playerBasicJson('#P1', name: 'Alice'),
            _playerBasicJson('#P2', name: 'Bob'),
          ]
        }),
        200,
      );
      service = PlayerService(apiService: fakeApi);
    });

    test('populates profiles', () async {
      await service.initPlayerData(['#P1', '#P2']);
      expect(service.profiles, hasLength(2));
    });

    test('profile name is parsed correctly', () async {
      await service.initPlayerData(['#P1']);
      expect(service.profiles.first.name, 'Alice');
    });

    test('sets isLoading to false', () async {
      await service.initPlayerData(['#P1']);
      expect(service.isLoading, isFalse);
    });

    test('notifies listeners', () async {
      var notified = false;
      service.addListener(() => notified = true);
      await service.initPlayerData(['#P1']);
      expect(notified, isTrue);
    });

    test('returns clan tags map', () async {
      final result = await service.initPlayerData(['#P1']);
      expect(result['#P1'], '#CLAN1');
    });
  });

  group('PlayerService — initPlayerData (200 with empty items)', () {
    test('returns empty map on 200 with no items', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/players'] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = PlayerService(apiService: fakeApi);
      final result = await service.initPlayerData(['#ABC']);
      expect(result, isEmpty);
      expect(service.isLoading, isFalse);
    });
  });

  group('PlayerService — initPlayerData (errors)', () {
    test('resets isLoading to false after 500 error', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/players'] =
          http.Response('error', 500);
      final service = PlayerService(apiService: fakeApi);
      await service.initPlayerData(['#ABC']);
      expect(service.isLoading, isFalse);
    });

    test('resets isLoading to false on network exception', () async {
      final service =
          PlayerService(apiService: NetworkErrorApiService());
      await service.initPlayerData(['#ABC']);
      expect(service.isLoading, isFalse);
    });

    test('throws when throwOnError = true and server returns 500', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/players'] =
          http.Response('error', 500);
      final service = PlayerService(apiService: fakeApi);
      await expectLater(
        () => service.initPlayerData(['#ABC'], throwOnError: true),
        throwsA(anything),
      );
    });

    test('throws 503 when throwOnError = true', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/players'] =
          http.Response('maintenance', 503);
      final service = PlayerService(apiService: fakeApi);
      await expectLater(
        () => service.initPlayerData(['#ABC'], throwOnError: true),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // loadPlayerData
  // ---------------------------------------------------------------------------

  group('PlayerService — loadPlayerData', () {
    test('resets isLoading to false after server error', () async {
      final service =
          PlayerService(apiService: NetworkErrorApiService());
      await service.loadPlayerData(['#ABC'], {'#ABC': '#CLAN'});
      expect(service.isLoading, isFalse);
    });

    test('resets isLoading to false on network exception', () async {
      final service =
          PlayerService(apiService: NetworkErrorApiService());
      await service.loadPlayerData(['#ABC'], {'#ABC': '#CLAN'});
      expect(service.isLoading, isFalse);
    });

    test('does not throw on error when throwOnError = false', () async {
      final service =
          PlayerService(apiService: NetworkErrorApiService());
      await expectLater(
        () => service.loadPlayerData(['#ABC'], {}),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // processBulkPlayerData
  // ---------------------------------------------------------------------------

  group('PlayerService — processBulkPlayerData', () {
    test('builds profiles from basic data', () {
      final service = PlayerService();
      service.processBulkPlayerData(
        [],
        [_playerBasicJson('#P1', name: 'Alpha')],
      );
      expect(service.profiles, hasLength(1));
      expect(service.profiles.first.name, 'Alpha');
    });

    test('profiles are empty for empty input', () {
      final service = PlayerService();
      service.processBulkPlayerData([], []);
      expect(service.profiles, isEmpty);
    });

    test('notifies listeners when notify = true', () {
      final service = PlayerService();
      var notified = false;
      service.addListener(() => notified = true);
      service.processBulkPlayerData([], [_playerBasicJson('#P1')], notify: true);
      expect(notified, isTrue);
    });

    test('does not notify when notify = false', () {
      final service = PlayerService();
      var notified = false;
      service.addListener(() => notified = true);
      service.processBulkPlayerData([], [_playerBasicJson('#P1')], notify: false);
      expect(notified, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // getSelectedProfile
  // ---------------------------------------------------------------------------

  group('PlayerService — getSelectedProfile', () {
    test('returns profile matching selectedTag', () {
      final service = PlayerService();
      service.processBulkPlayerData([], [_playerBasicJson('#P1')]);
      final cocService = CocAccountService();
      cocService.addLocalAccount({'player_tag': '#P1'});
      cocService.setSelectedTag('#P1');
      expect(service.getSelectedProfile(cocService)?.tag, '#P1');
    });

    test('returns null when selectedTag does not match any profile', () {
      final service = PlayerService();
      service.processBulkPlayerData([], [_playerBasicJson('#P1')]);
      final cocService = CocAccountService();
      cocService.setSelectedTag('#NOMATCH');
      expect(service.getSelectedProfile(cocService), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // getMinimalisticPlayerByTag
  // ---------------------------------------------------------------------------

  group('PlayerService — getMinimalisticPlayerByTag', () {
    test('returns JSON when profile exists', () {
      final service = PlayerService();
      service.processBulkPlayerData([], [_playerBasicJson('#P1')]);
      final result = service.getMinimalisticPlayerByTag('#P1');
      expect(result, isNot('{}'));
    });

    test('returns empty json when profile not found', () {
      final service = PlayerService();
      expect(service.getMinimalisticPlayerByTag('#NONE'), '{}');
    });
  });

  // ---------------------------------------------------------------------------
  // getPlayerAndClanData (preserves existing profiles)
  // ---------------------------------------------------------------------------

  group('PlayerService — getPlayerAndClanData', () {
    test('merges fetched player into existing profiles without replacing', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/initialization'] = http.Response(
        jsonEncode({
          'players': [_playerBasicJson('#NEW', name: 'Newcomer')],
          'players_basic': [_playerBasicJson('#NEW', name: 'Newcomer')],
          'clan_tags': [],
        }),
        200,
      );
      final service = PlayerService(apiService: fakeApi);
      service.processBulkPlayerData([], [_playerBasicJson('#ORIG', name: 'Original')]);
      expect(service.profiles, hasLength(1));

      await service.getPlayerAndClanData('#NEW');
      // Must contain the original profile too (not replaced)
      expect(service.profiles.any((p) => p.tag == '#ORIG'), isTrue);
    });

    test('uses fallback when bulk endpoint returns non-200', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/initialization'] =
          http.Response('{}', 400);
      fakeApi.postStubs['/players'] = http.Response(
        jsonEncode({
          'items': [_playerBasicJson('#P1', name: 'Hero')]
        }),
        200,
      );
      // /players/extended and /war/players/warhits default to 200 {}
      final service = PlayerService(apiService: fakeApi);
      final player = await service.getPlayerAndClanData('#P1');
      expect(player.tag, '#P1');
      expect(service.isLoading, isFalse);
    });

    test('throws when fallback also fails', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/initialization'] =
          http.Response('{}', 400);
      fakeApi.postStubs['/players'] =
          http.Response('error', 500);
      final service = PlayerService(apiService: fakeApi);
      await expectLater(
        () => service.getPlayerAndClanData('#P1'),
        throwsA(anything),
      );
      expect(service.isLoading, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // loadPlayerData (200 success path)
  // ---------------------------------------------------------------------------

  group('PlayerService — loadPlayerData (200 with items)', () {
    test('enriches existing profiles on 200', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/players/extended'] = http.Response(
        jsonEncode({
          'items': [
            _playerBasicJson('#P1', name: 'Extended Alice'),
          ]
        }),
        200,
      );
      final service = PlayerService(apiService: fakeApi);
      service.processBulkPlayerData(
          [], [_playerBasicJson('#P1', name: 'Alice')]);
      await service.loadPlayerData(['#P1'], {'#P1': '#CLAN1'});
      expect(service.isLoading, isFalse);
      expect(service.profiles, hasLength(1));
    });

    test('returns normally on 200 with no items key', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/players/extended'] = http.Response(
        jsonEncode({}),
        200,
      );
      final service = PlayerService(apiService: fakeApi);
      await expectLater(
        () => service.loadPlayerData(['#P1'], {}),
        returnsNormally,
      );
      expect(service.isLoading, isFalse);
    });

    test('throws when throwOnError = true and non-200', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/players/extended'] =
          http.Response('error', 500);
      final service = PlayerService(apiService: fakeApi);
      await expectLater(
        () => service.loadPlayerData(['#P1'], {}, throwOnError: true),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // loadPlayerWarStats
  // ---------------------------------------------------------------------------

  group('PlayerService — loadPlayerWarStats', () {
    test('does not throw on 200 with empty items', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/players/warhits'] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = PlayerService(apiService: fakeApi);
      await expectLater(
        () => service.loadPlayerWarStats(['#P1']),
        returnsNormally,
      );
    });

    test('does not throw on non-200 when throwOnError = false', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/players/warhits'] =
          http.Response('error', 500);
      final service = PlayerService(apiService: fakeApi);
      await expectLater(
        () => service.loadPlayerWarStats(['#P1'], throwOnError: false),
        returnsNormally,
      );
    });

    test('throws on non-200 when throwOnError = true', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/players/warhits'] =
          http.Response('error', 500);
      final service = PlayerService(apiService: fakeApi);
      await expectLater(
        () => service.loadPlayerWarStats(['#P1'], throwOnError: true),
        throwsA(anything),
      );
    });

    test('notifies listeners on success', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/players/warhits'] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = PlayerService(apiService: fakeApi);
      var notified = false;
      service.addListener(() => notified = true);
      await service.loadPlayerWarStats(['#P1']);
      expect(notified, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // processBulkWarStats
  // ---------------------------------------------------------------------------

  group('PlayerService — processBulkWarStats', () {
    test('processes empty war stats without error', () {
      final service = PlayerService();
      service.processBulkPlayerData([], [_playerBasicJson('#P1')]);
      expect(() => service.processBulkWarStats([]), returnsNormally);
    });

    test('notifies listeners when notify = true', () {
      final service = PlayerService();
      var notified = false;
      service.addListener(() => notified = true);
      service.processBulkWarStats([], notify: true);
      expect(notified, isTrue);
    });

    test('does not notify when notify = false', () {
      final service = PlayerService();
      var notified = false;
      service.addListener(() => notified = true);
      service.processBulkWarStats([], notify: false);
      expect(notified, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // linkClansToPlayer
  // ---------------------------------------------------------------------------

  group('PlayerService — linkClansToPlayer', () {
    test('does not throw with empty inputs', () {
      final service = PlayerService();
      expect(() => service.linkClansToPlayer([], []), returnsNormally);
    });

    test('links matching clan to player profile', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/players'] = http.Response(
        jsonEncode({'items': [_playerBasicJson('#P1', clanTag: '#CLAN1')]}),
        200,
      );
      final service = PlayerService(apiService: fakeApi);
      await service.initPlayerData(['#P1']);

      final fakeClanApi = FakeApiService();
      fakeClanApi.postStubs['/clans/details'] = http.Response(
        jsonEncode({'items': [{'tag': '#CLAN1', 'name': 'Alpha'}]}),
        200,
      );
      final clanService =
          ClanService(apiService: fakeClanApi);
      await clanService.loadAllClanData(['#CLAN1']);

      service.linkClansToPlayer(
          service.profiles, clanService.clans.values.toList());
      expect(service.profiles.first.clan, isNotNull);
      expect(service.profiles.first.clan?.tag, '#CLAN1');
    });
  });

  // ---------------------------------------------------------------------------
  // processBulkWarStats (with actual data)
  // ---------------------------------------------------------------------------

  group('PlayerService — processBulkWarStats with matching data', () {
    test('links war stats to matching player', () {
      final service = PlayerService();
      service.processBulkPlayerData([], [_playerBasicJson('#P1')]);
      service.processBulkWarStats([
        {'tag': '#P1', 'wars': [], 'attacks': [], 'defenses': []}
      ]);
      expect(service.profiles.first.warStats, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // loadPlayerWarStatsWithFilter
  // ---------------------------------------------------------------------------

  group('PlayerService — loadPlayerWarStatsWithFilter', () {
    test('returns PlayerWarStats when item matches player tag', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/players/warhits'] = http.Response(
        jsonEncode({
          'items': [
            {'tag': '#P1', 'wars': [], 'attacks': [], 'defenses': []}
          ]
        }),
        200,
      );
      final service = PlayerService(apiService: fakeApi);
      final result = await service.loadPlayerWarStatsWithFilter(
        '#P1',
        const WarStatsFilter(),
      );
      expect(result, isNotNull);
    });

    test('returns null when items list is empty', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/players/warhits'] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = PlayerService(apiService: fakeApi);
      final result = await service.loadPlayerWarStatsWithFilter(
        '#P1',
        const WarStatsFilter(),
      );
      expect(result, isNull);
    });

    test('returns null when no item matches player tag', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/players/warhits'] = http.Response(
        jsonEncode({
          'items': [
            {'tag': '#OTHER', 'wars': [], 'attacks': [], 'defenses': []}
          ]
        }),
        200,
      );
      final service = PlayerService(apiService: fakeApi);
      final result = await service.loadPlayerWarStatsWithFilter(
        '#P1',
        const WarStatsFilter(),
      );
      expect(result, isNull);
    });

    test('throws on non-200 response', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/players/warhits'] =
          http.Response('error', 500);
      final service = PlayerService(apiService: fakeApi);
      await expectLater(
        () => service.loadPlayerWarStatsWithFilter('#P1', const WarStatsFilter()),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // PlayerService.clans getter
  // ---------------------------------------------------------------------------

  group('PlayerService — clans getter', () {
    test('starts empty', () {
      final service = PlayerService();
      expect(service.clans, isEmpty);
    });
  });
}

