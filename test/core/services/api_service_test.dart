import 'dart:async';
import 'dart:io';

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService', () {
    test('decodeResponseBody allows malformed utf8', () {
      final response = http.Response.bytes([0xC3, 0x28], 200);

      final decoded = ApiService.decodeResponseBody(response);

      expect(decoded, isNotEmpty);
    });

    test('getErrorMessage falls back without localization context', () {
      expect(
        ApiService.getErrorMessage(const SocketException('offline')),
        'Network connection error.',
      );
      expect(
        ApiService.getErrorMessage(TimeoutException('slow')),
        'Request timeout.',
      );
      expect(
        ApiService.getErrorMessage(FormatException('bad payload')),
        'Invalid response format.',
      );
      expect(
        ApiService.getErrorMessage(BadRequestException('bad request')),
        'bad request',
      );
    });
  });
}
