import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS supports portrait orientation only', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(plist, contains('<key>UIRequiresFullScreen</key>\n\t<true/>'));
    expect(
      RegExp(
        r'<string>UIInterfaceOrientationPortrait</string>',
      ).allMatches(plist),
      hasLength(2),
    );
    expect(plist, isNot(contains('UIInterfaceOrientationLandscape')));
    expect(plist, isNot(contains('UIInterfaceOrientationPortraitUpsideDown')));
  });
}
