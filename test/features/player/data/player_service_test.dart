import 'dart:convert';

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

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
      // selectedTag is still null (not initialized)
      expect(playerService.getSelectedProfile(cocService), isNull);
    });

    test('getMinimalisticPlayerByTag returns empty json when not found', () {
      final service = PlayerService();
      expect(service.getMinimalisticPlayerByTag('#UNKNOWN'), '{}');
    });
  });

  group('PlayerService — initPlayerData', () {
    test('returns empty map on 200 with no items', () async {
      final fakeClient = MockClient((_) async => http.Response(
            jsonEncode({'items': []}),
            200,
          ));
      final service = PlayerService(apiService: ApiService(client: fakeClient));

      final result = await service.initPlayerData(['#ABC']);

      expect(result, isEmpty);
      expect(service.isLoading, isFalse);
    });

    test('resets isLoading to false after 500 error', () async {
      final fakeClient = MockClient((_) async => http.Response('error', 500));
      final service = PlayerService(apiService: ApiService(client: fakeClient));

      await service.initPlayerData(['#ABC']);

      expect(service.isLoading, isFalse);
    });

    test('resets isLoading to false on network exception', () async {
      final fakeClient = MockClient((_) async => throw Exception('no network'));
      final service = PlayerService(apiService: ApiService(client: fakeClient));

      await service.initPlayerData(['#ABC']);

      expect(service.isLoading, isFalse);
    });

    test('throws when throwOnError is true and server returns 500', () async {
      final fakeClient = MockClient((_) async => http.Response('error', 500));
      final service = PlayerService(apiService: ApiService(client: fakeClient));

      await expectLater(
        () => service.initPlayerData(['#ABC'], throwOnError: true),
        throwsException,
      );
    });
  });

  group('PlayerService — loadPlayerData', () {
    test('resets isLoading to false after server error', () async {
      final fakeClient = MockClient((_) async => http.Response('error', 500));
      final service = PlayerService(apiService: ApiService(client: fakeClient));

      await service.loadPlayerData(['#ABC'], {'#ABC': '#CLAN'});

      expect(service.isLoading, isFalse);
    });

    test('resets isLoading to false on network exception', () async {
      final fakeClient = MockClient((_) async => throw Exception('no network'));
      final service = PlayerService(apiService: ApiService(client: fakeClient));

      await service.loadPlayerData(['#ABC'], {'#ABC': '#CLAN'});

      expect(service.isLoading, isFalse);
    });
  });
}
