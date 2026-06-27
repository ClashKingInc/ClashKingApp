import 'dart:async';
import 'dart:io';

import 'package:clashkingapp/core/utils/network_error_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('isNetworkError', () {
    test('matches socket and timeout exceptions', () {
      expect(isNetworkError(const SocketException('offline')), isTrue);
      expect(isNetworkError(TimeoutException('slow request')), isTrue);
    });

    test('matches http.ClientException (Flutter web XHR/fetch failures)', () {
      expect(isNetworkError(http.ClientException('Failed to fetch')), isTrue);
      // Even a ClientException with an unrelated message is treated as network.
      expect(isNetworkError(http.ClientException('boom')), isTrue);
    });

    test('matches known network error strings', () {
      expect(isNetworkError(Exception('No address associated with hostname')),
          isTrue);
      expect(isNetworkError(Exception('A network error occurred')), isTrue);
      expect(isNetworkError(Exception('Connection reset')), isTrue);
      expect(isNetworkError(Exception('socket hang up')), isTrue);
      expect(isNetworkError(Exception('Request timeout')), isTrue);
      expect(isNetworkError(Exception('plain failure')), isFalse);
    });

    test('matches Flutter web fetch error strings', () {
      expect(isNetworkError(Exception('XMLHttpRequest error')), isTrue);
      expect(isNetworkError(Exception('Failed to fetch')), isTrue);
    });
  });

  group('isMaintenanceError', () {
    test('returns true when error contains 503', () {
      expect(isMaintenanceError(Exception('HTTP 503 Service Unavailable')), isTrue);
    });

    test('returns true when error contains 500', () {
      expect(isMaintenanceError(Exception('HTTP 500 Internal Server Error')), isTrue);
    });

    test('returns false for other status codes', () {
      expect(isMaintenanceError(Exception('HTTP 404 Not Found')), isFalse);
      expect(isMaintenanceError(Exception('HTTP 401 Unauthorized')), isFalse);
      expect(isMaintenanceError(Exception('network failure')), isFalse);
    });
  });
}
