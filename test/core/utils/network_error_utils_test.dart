import 'dart:async';
import 'dart:io';

import 'package:clashkingapp/core/utils/network_error_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isNetworkError', () {
    test('matches socket and timeout exceptions', () {
      expect(isNetworkError(const SocketException('offline')), isTrue);
      expect(isNetworkError(TimeoutException('slow request')), isTrue);
    });

    test('matches known network error strings', () {
      expect(
        isNetworkError(Exception('No address associated with hostname')),
        isTrue,
      );
      expect(isNetworkError(Exception('plain failure')), isFalse);
    });
  });

  group('isMaintenanceError', () {
    test('returns true when error contains 503', () {
      expect(
        isMaintenanceError(Exception('HTTP 503 Service Unavailable')),
        isTrue,
      );
    });

    test('returns true when error contains 500', () {
      expect(
        isMaintenanceError(Exception('HTTP 500 Internal Server Error')),
        isTrue,
      );
    });

    test('returns false for other status codes', () {
      expect(isMaintenanceError(Exception('HTTP 404 Not Found')), isFalse);
      expect(isMaintenanceError(Exception('HTTP 401 Unauthorized')), isFalse);
      expect(isMaintenanceError(Exception('network failure')), isFalse);
    });
  });
}
