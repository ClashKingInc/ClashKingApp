import 'dart:convert';

import 'package:clashkingapp/features/auth/data/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

const testUserId = 'user-123';
const testLinksEndpoint = '/links/user-123';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ---------------------------------------------------------------------------
  // getClashKingUser
  // ---------------------------------------------------------------------------

  group('UserService — getClashKingUser', () {
    test('returns the response map on 200', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/auth/me'] = http.Response(
        jsonEncode({'user_id': 'u1', 'discord_username': 'TestUser'}),
        200,
      );
      final service = UserService(apiService: fakeApi);
      final result = await service.getClashKingUser();
      expect(result['user_id'], 'u1');
      expect(result['discord_username'], 'TestUser');
    });

    test('returns map with all expected fields', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/auth/me'] = http.Response(
        jsonEncode({
          'user_id': 'abc123',
          'discord_username': 'Player1',
          'avatar_url': 'https://example.com/avatar.png',
          'auth_methods': ['discord'],
        }),
        200,
      );
      final service = UserService(apiService: fakeApi);
      final result = await service.getClashKingUser();
      expect(result['user_id'], 'abc123');
      expect(result['avatar_url'], 'https://example.com/avatar.png');
    });

    test('throws on 401 response', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/auth/me'] = http.Response('Unauthorized', 401);
      final service = UserService(apiService: fakeApi);
      await expectLater(() => service.getClashKingUser(), throwsA(anything));
    });

    test('throws on network error', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnGet['/auth/me'] = Exception('Network error');
      final service = UserService(apiService: fakeApi);
      await expectLater(() => service.getClashKingUser(), throwsA(anything));
    });
  });

  // ---------------------------------------------------------------------------
  // getClashAccounts
  // ---------------------------------------------------------------------------

  group('UserService — getClashAccounts', () {
    test('returns player tags from items key on 200', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({
          'items': [
            {'player_tag': '#ABC123', 'hidden': false},
            {'player_tag': '#DEF456', 'hidden': true},
            {'player_tag': '#GHI789', 'hidden': false},
          ],
        }),
        200,
      );
      final service = UserService(apiService: fakeApi);
      final result = await service.getClashAccounts(testUserId);
      expect(result, hasLength(3));
      expect(result, containsAll(['#ABC123', '#DEF456', '#GHI789']));
    });

    test('returns single-element list', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({
          'items': [
            {'player_tag': '#ONLY1', 'hidden': false},
          ],
        }),
        200,
      );
      final service = UserService(apiService: fakeApi);
      final result = await service.getClashAccounts(testUserId);
      expect(result, hasLength(1));
      expect(result.first, '#ONLY1');
    });

    test('returns empty list when items key is missing', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({'other_key': 'value'}),
        200,
      );
      final service = UserService(apiService: fakeApi);
      final result = await service.getClashAccounts(testUserId);
      expect(result, isEmpty);
    });

    test('returns empty list when items value is not a List', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({'items': 'not-a-list'}),
        200,
      );
      final service = UserService(apiService: fakeApi);
      final result = await service.getClashAccounts(testUserId);
      expect(result, isEmpty);
    });

    test('returns empty list when items is an empty list', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = UserService(apiService: fakeApi);
      final result = await service.getClashAccounts(testUserId);
      expect(result, isEmpty);
    });

    test('returns empty list when response body is empty object', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response(jsonEncode({}), 200);
      final service = UserService(apiService: fakeApi);
      final result = await service.getClashAccounts(testUserId);
      expect(result, isEmpty);
    });

    test('throws on 401 response', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response('Unauthorized', 401);
      final service = UserService(apiService: fakeApi);
      await expectLater(
        () => service.getClashAccounts(testUserId),
        throwsA(anything),
      );
    });

    test('throws on network error', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnGet[testLinksEndpoint] = Exception('Network error');
      final service = UserService(apiService: fakeApi);
      await expectLater(
        () => service.getClashAccounts(testUserId),
        throwsA(anything),
      );
    });
  });
}
