import 'dart:convert';

import 'package:clashkingapp/core/services/token_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  group('TokenService.isTokenExpired', () {
    final tokenService = TokenService();

    test('returns false for a token comfortably before expiry', () {
      final token = _buildToken(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 120,
      );

      expect(tokenService.isTokenExpired(token), isFalse);
    });

    test('returns true for an expired token inside the refresh buffer', () {
      final token = _buildToken(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 10,
      );

      expect(tokenService.isTokenExpired(token), isTrue);
    });

    test('returns true for malformed tokens', () {
      expect(tokenService.isTokenExpired('invalid-token'), isTrue);
    });
  });

  group('TokenService session cache', () {
    test('valid cached token never queries device identity', () async {
      final token = _buildToken(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 120,
      );
      FlutterSecureStorage.setMockInitialValues({
        'access_token': token,
        'refresh_token': 'refresh-token',
      });
      final tokenService = _CountingTokenService();

      expect(await tokenService.getAccessToken(), token);
      FlutterSecureStorage.setMockInitialValues({});
      expect(await tokenService.getAccessToken(), token);
      expect(tokenService.deviceIdReads, 0);
    });

    test('concurrent expired-token requests share one refresh', () async {
      final expiredToken = _buildToken(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60,
      );
      final refreshedToken = _buildToken(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 120,
      );
      const replacementRefreshToken = 'replacement-refresh-token';
      FlutterSecureStorage.setMockInitialValues({
        'access_token': expiredToken,
        'refresh_token': 'refresh-token',
      });
      var refreshRequests = 0;
      final client = MockClient((request) async {
        refreshRequests++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response(
          jsonEncode({
            'access_token': refreshedToken,
            'refresh_token': replacementRefreshToken,
          }),
          200,
        );
      });
      final tokenService = _CountingTokenService(client: client);

      final tokens = await Future.wait([
        tokenService.getAccessToken(),
        tokenService.getAccessToken(),
      ]);

      expect(tokens, everyElement(refreshedToken));
      expect(refreshRequests, 1);
      expect(tokenService.deviceIdReads, 1);
      final storedSession = await _storedSession();
      expect(storedSession['access_token'], refreshedToken);
      expect(storedSession['refresh_token'], replacementRefreshToken);
      expect(storedSession['device_id'], 'test-device');
    });

    test('uses the replacement refresh token on the next rotation', () async {
      final expiredToken = _buildToken(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60,
      );
      final firstRefreshedToken = _buildToken(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60,
      );
      final secondRefreshedToken = _buildToken(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 120,
      );
      FlutterSecureStorage.setMockInitialValues({
        'access_token': expiredToken,
        'refresh_token': 'initial-refresh-token',
      });
      final presentedRefreshTokens = <String>[];
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        presentedRefreshTokens.add(body['refresh_token'] as String);
        final firstRequest = presentedRefreshTokens.length == 1;
        return http.Response(
          jsonEncode({
            'access_token': firstRequest
                ? firstRefreshedToken
                : secondRefreshedToken,
            'refresh_token': firstRequest
                ? 'first-replacement-refresh-token'
                : 'second-replacement-refresh-token',
          }),
          200,
        );
      });
      final tokenService = _CountingTokenService(client: client);

      expect(await tokenService.getAccessToken(), firstRefreshedToken);
      expect(await tokenService.getAccessToken(), secondRefreshedToken);

      expect(presentedRefreshTokens, [
        'initial-refresh-token',
        'first-replacement-refresh-token',
      ]);
      final storedSession = await _storedSession();
      expect(storedSession['access_token'], secondRefreshedToken);
      expect(
        storedSession['refresh_token'],
        'second-replacement-refresh-token',
      );
    });

    test(
      'rejects a successful response missing a replacement token without corrupting the session',
      () async {
        final expiredToken = _buildToken(
          DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60,
        );
        FlutterSecureStorage.setMockInitialValues({
          'access_token': expiredToken,
          'refresh_token': 'deleted-refresh-token',
        });
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode({'access_token': 'new-access-token'}),
            200,
          ),
        );
        final tokenService = _CountingTokenService(client: client);

        expect(await tokenService.getAccessToken(), isNull);

        final storedSession = await _storedSession();
        expect(storedSession['access_token'], expiredToken);
        expect(storedSession['refresh_token'], 'deleted-refresh-token');
      },
    );
  });

  test('migrates the legacy iOS fallback device ID', () async {
    final sharedStorage = _MemorySecureStorage();
    final legacyStorage = _MemorySecureStorage({
      'device_id_fallback': 'legacy-device-id',
    });
    final tokenService = TokenService(
      secureStorage: sharedStorage,
      legacySecureStorage: legacyStorage,
    );

    expect(await tokenService.loadIOSFallbackDeviceId(), 'legacy-device-id');
    expect(sharedStorage.values['device_id_fallback'], 'legacy-device-id');
  });
}

class _MemorySecureStorage extends FlutterSecureStorage {
  _MemorySecureStorage([Map<String, String>? initialValues])
    : values = {...?initialValues};

  final Map<String, String> values;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}

class _CountingTokenService extends TokenService {
  _CountingTokenService({super.client});

  int deviceIdReads = 0;

  @override
  Future<String> getDeviceId() async {
    deviceIdReads++;
    return 'test-device';
  }
}

String _buildToken(int expiration) {
  final header = _base64UrlEncode({'alg': 'HS256', 'typ': 'JWT'});
  final payload = _base64UrlEncode({'exp': expiration});
  return '$header.$payload.signature';
}

String _base64UrlEncode(Map<String, dynamic> value) {
  return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
}

Future<Map<String, dynamic>> _storedSession() async {
  const storage = FlutterSecureStorage();
  final encoded = await storage.read(key: 'shared_auth_session_v1');
  expect(encoded, isNotNull);
  return Map<String, dynamic>.from(jsonDecode(encoded!) as Map);
}
