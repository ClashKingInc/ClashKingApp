import 'dart:convert';

import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
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
  });
}

