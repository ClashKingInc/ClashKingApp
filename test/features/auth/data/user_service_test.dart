import 'dart:convert';

import 'package:clashkingapp/features/auth/data/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

// ---------------------------------------------------------------------------
// A testable variant of [UserService] that redirects calls through a
// provided [FakeApiService], since the production class creates its own
// [ApiService] internally and does not support injection.
// ---------------------------------------------------------------------------

class _TestableUserService extends UserService {
  _TestableUserService(this._fakeApi);

  final FakeApiService _fakeApi;

  @override
  Future<Map<String, dynamic>> getClashKingUser() async {
    // Delegate through the fake, which honours getStubs/throwOnGet.
    return _fakeApi.get('/auth/me');
  }

  @override
  Future<List<String>> getClashAccounts() async {
    final response = await _fakeApi.get('/users/coc-accounts');

    if (response.containsKey('accounts') && response['accounts'] is List) {
      return List<String>.from(response['accounts']);
    }

    return [];
  }
}

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
      final service = _TestableUserService(fakeApi);
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
      final service = _TestableUserService(fakeApi);
      final result = await service.getClashKingUser();
      expect(result['user_id'], 'abc123');
      expect(result['avatar_url'], 'https://example.com/avatar.png');
    });

    test('throws on 401 response', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/auth/me'] = http.Response('Unauthorized', 401);
      final service = _TestableUserService(fakeApi);
      await expectLater(
        () => service.getClashKingUser(),
        throwsA(anything),
      );
    });

    test('throws on network error', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnGet['/auth/me'] = Exception('Network error');
      final service = _TestableUserService(fakeApi);
      await expectLater(
        () => service.getClashKingUser(),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // getClashAccounts
  // ---------------------------------------------------------------------------

  group('UserService — getClashAccounts', () {
    test('returns list from accounts key on 200', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/users/coc-accounts'] = http.Response(
        jsonEncode({
          'accounts': ['#ABC123', '#DEF456', '#GHI789'],
        }),
        200,
      );
      final service = _TestableUserService(fakeApi);
      final result = await service.getClashAccounts();
      expect(result, hasLength(3));
      expect(result, containsAll(['#ABC123', '#DEF456', '#GHI789']));
    });

    test('returns single-element list', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/users/coc-accounts'] = http.Response(
        jsonEncode({'accounts': ['#ONLY1']}),
        200,
      );
      final service = _TestableUserService(fakeApi);
      final result = await service.getClashAccounts();
      expect(result, hasLength(1));
      expect(result.first, '#ONLY1');
    });

    test('returns empty list when accounts key is missing', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/users/coc-accounts'] = http.Response(
        jsonEncode({'other_key': 'value'}),
        200,
      );
      final service = _TestableUserService(fakeApi);
      final result = await service.getClashAccounts();
      expect(result, isEmpty);
    });

    test('returns empty list when accounts value is not a List', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/users/coc-accounts'] = http.Response(
        jsonEncode({'accounts': 'not-a-list'}),
        200,
      );
      final service = _TestableUserService(fakeApi);
      final result = await service.getClashAccounts();
      expect(result, isEmpty);
    });

    test('returns empty list when accounts is an empty list', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/users/coc-accounts'] = http.Response(
        jsonEncode({'accounts': []}),
        200,
      );
      final service = _TestableUserService(fakeApi);
      final result = await service.getClashAccounts();
      expect(result, isEmpty);
    });

    test('returns empty list when response body is empty object', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/users/coc-accounts'] =
          http.Response(jsonEncode({}), 200);
      final service = _TestableUserService(fakeApi);
      final result = await service.getClashAccounts();
      expect(result, isEmpty);
    });

    test('throws on 401 response', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/users/coc-accounts'] =
          http.Response('Unauthorized', 401);
      final service = _TestableUserService(fakeApi);
      await expectLater(
        () => service.getClashAccounts(),
        throwsA(anything),
      );
    });

    test('throws on network error', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnGet['/users/coc-accounts'] = Exception('Network error');
      final service = _TestableUserService(fakeApi);
      await expectLater(
        () => service.getClashAccounts(),
        throwsA(anything),
      );
    });
  });
}
