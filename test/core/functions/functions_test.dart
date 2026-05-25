import 'package:clashkingapp/core/functions/functions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('functions.dart utilities', () {
    group('formatSecondsToHHMM', () {
      test('formats 0 seconds', () {
        expect(formatSecondsToHHMM(0.0), '00:00');
      });

      test('formats 1 hour', () {
        expect(formatSecondsToHHMM(3600.0), '01:00');
      });

      test('formats 1 hour and 1 minute', () {
        expect(formatSecondsToHHMM(3661.0), '01:01');
      });

      test('formats 2 hours', () {
        expect(formatSecondsToHHMM(7200.0), '02:00');
      });

      test('rounds to the nearest second before formatting', () {
        expect(formatSecondsToHHMM(90.0), '00:01');
      });
    });

    group('findLastMondayOfMonth', () {
      test('returns a Monday', () {
        final result = findLastMondayOfMonth(2025, 5);

        expect(result.weekday, DateTime.monday);
      });

      test('May 2025 last Monday is May 26', () {
        final result = findLastMondayOfMonth(2025, 5);

        expect(result.year, 2025);
        expect(result.month, 5);
        expect(result.day, 26);
      });

      test('December 2025 last Monday is December 29', () {
        final result = findLastMondayOfMonth(2025, 12);

        expect(result.year, 2025);
        expect(result.month, 12);
        expect(result.day, 29);
      });
    });

    group('time frame helpers', () {
      test('isInTimeFrameForRaid returns a bool', () {
        expect(isInTimeFrameForRaid(), isA<bool>());
      });

      test('isInTimeFrameForClanGames returns a bool', () {
        expect(isInTimeFrameForClanGames(), isA<bool>());
      });

      test('isInTimeFrameForCwl returns a bool', () {
        expect(isInTimeFrameForCwl(), isA<bool>());
      });
    });

    group('progress getters', () {
      test('requiredSeasonPassPoints returns an int within range', () {
        expect(requiredSeasonPassPoints, isA<int>());
        expect(requiredSeasonPassPoints, greaterThanOrEqualTo(0));
        expect(requiredSeasonPassPoints, lessThanOrEqualTo(2600));
      });

      test('requiredClanGamesPoints returns a non-negative int', () {
        expect(requiredClanGamesPoints, isA<int>());
        expect(requiredClanGamesPoints, greaterThanOrEqualTo(0));
      });
    });
  });
}
