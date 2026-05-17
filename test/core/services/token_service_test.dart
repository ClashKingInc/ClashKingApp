import 'dart:convert';

import 'package:clashkingapp/core/services/token_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}

String _buildToken(int expiration) {
  final header = _base64UrlEncode({'alg': 'HS256', 'typ': 'JWT'});
  final payload = _base64UrlEncode({'exp': expiration});
  return '$header.$payload.signature';
}

String _base64UrlEncode(Map<String, dynamic> value) {
  return base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
}
