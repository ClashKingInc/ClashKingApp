import 'package:clashkingapp/features/pages/presentation/dashboard_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateUpgradeSummaryCompletion', () {
    test('counts accounts without imported data in the denominator', () {
      final completion = calculateUpgradeSummaryCompletion(
        importedCompletions: const [1],
        missingCount: 1,
      );

      expect(completion, 0.5);
    });

    test('returns zero when every configured account is missing data', () {
      final completion = calculateUpgradeSummaryCompletion(
        importedCompletions: const [],
        missingCount: 2,
      );

      expect(completion, 0);
    });
  });
}
