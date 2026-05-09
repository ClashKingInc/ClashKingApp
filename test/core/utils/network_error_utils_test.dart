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
      expect(isNetworkError(Exception('No address associated with hostname')),
          isTrue);
      expect(isNetworkError(Exception('plain failure')), isFalse);
    });
  });
}
