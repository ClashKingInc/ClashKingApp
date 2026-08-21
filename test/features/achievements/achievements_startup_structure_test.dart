import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup checks achievements after linked accounts initialize', () {
    final source = File(
      'lib/features/auth/presentation/startup_widget.dart',
    ).readAsStringSync();
    final bootstrap = source.indexOf('await _accountBootstrap.initialize(');
    final achievementCheck = source.indexOf('achievementsRepository.check()');

    expect(bootstrap, greaterThanOrEqualTo(0));
    expect(achievementCheck, greaterThan(bootstrap));
    expect(source, contains("operation: 'startup.achievements'"));
  });
}
