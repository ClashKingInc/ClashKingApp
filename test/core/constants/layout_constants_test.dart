import 'package:clashkingapp/core/constants/layout_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('layout_constants', () {
    test('kMaxContentWidth is 800.0', () {
      expect(kMaxContentWidth, 800.0);
    });

    test('kChipRunSpacing returns a double', () {
      expect(kChipRunSpacing, isA<double>());
    });
  });
}
