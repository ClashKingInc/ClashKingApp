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
      FlutterSecureStorage.setMockInitialValues({
        'access_token': expiredToken,
        'refresh_token': 'refresh-token',
      });
      var refreshRequests = 0;
      final client = MockClient((request) async {
        refreshRequests++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response(jsonEncode({'access_token': refreshedToken}), 200);
      });
      final tokenService = _CountingTokenService(client: client);

      final tokens = await Future.wait([
        tokenService.getAccessToken(),
        tokenService.getAccessToken(),
      ]);

      expect(tokens, everyElement(refreshedToken));
      expect(refreshRequests, 1);
      expect(tokenService.deviceIdReads, 1);
      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'access_token'), refreshedToken);
    });
  });
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
