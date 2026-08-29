import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS widget retains a valid legacy token until session migration', () {
    final source = File('ios/WarWidget/WarWidget.swift').readAsStringSync();

    expect(
      source,
      contains('return validLegacyAccessToken(defaults: defaults)'),
    );
    expect(source, contains('defaults.string(forKey: "warWidgetAuthToken")'));
    expect(source, contains('!isExpired(token)'));
  });

  test('Runner startup does not clear the legacy token before migration', () {
    final source = File('ios/Runner/AppDelegate.swift').readAsStringSync();

    expect(source, isNot(contains('forKey: "warWidgetAuthToken"')));
  });

  test('iOS widget fallbacks use the canonical API host', () {
    final source = File('ios/WarWidget/WarWidget.swift').readAsStringSync();

    expect(source, contains('https://api.clashk.ing/v2'));
    expect(source, contains('https://api.clashk.ing/proxy/v1'));
    expect(source, isNot(contains('https://v2-api.clashk.ing')));
    expect(source, isNot(contains('https://proxy.clashk.ing')));
  });
}
