import 'dart:convert';

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

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

  group('ClanService — loadAllClanData', () {
    test('does nothing for empty tag list', () async {
      final service = ClanService();
      await service.loadAllClanData([]);
      expect(service.clans, isEmpty);
    });

    test('resets isLoading to false on 200 with no items', () async {
      final fakeClient = MockClient((_) async => http.Response(
            jsonEncode({'items': []}),
            200,
          ));
      final service = ClanService(apiService: ApiService(client: fakeClient));

      await service.loadAllClanData(['#CLAN1']);

      expect(service.isLoading, isFalse);
    });

    test('resets isLoading to false on server error', () async {
      final fakeClient = MockClient((_) async => http.Response('error', 500));
      final service = ClanService(apiService: ApiService(client: fakeClient));

      await service.loadAllClanData(['#CLAN1']);

      expect(service.isLoading, isFalse);
    });

    test('resets isLoading to false on network exception', () async {
      final fakeClient = MockClient((_) async => throw Exception('no network'));
      final service = ClanService(apiService: ApiService(client: fakeClient));

      await service.loadAllClanData(['#CLAN1']);

      expect(service.isLoading, isFalse);
    });

    test('throws HttpException when throwOnError is true on server error',
        () async {
      final fakeClient = MockClient((_) async => http.Response('error', 503));
      final service = ClanService(apiService: ApiService(client: fakeClient));

      await expectLater(
        () => service.loadAllClanData(['#CLAN1'], throwOnError: true),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ClanService — loadClanWarStatsData', () {
    test('returns empty list for empty tag list', () async {
      final service = ClanService();
      final result = await service.loadClanWarStatsData([]);
      expect(result, isEmpty);
    });

    test('returns empty list on server error without throwOnError', () async {
      final fakeClient = MockClient((_) async => http.Response('error', 500));
      final service = ClanService(apiService: ApiService(client: fakeClient));

      final result = await service.loadClanWarStatsData(['#CLAN1']);

      expect(result, isEmpty);
    });

    test('returns empty list on 200 with no items', () async {
      final fakeClient = MockClient((_) async => http.Response(
            jsonEncode({'items': []}),
            200,
          ));
      final service = ClanService(apiService: ApiService(client: fakeClient));

      final result = await service.loadClanWarStatsData(['#CLAN1']);

      expect(result, isEmpty);
    });
  });
}
