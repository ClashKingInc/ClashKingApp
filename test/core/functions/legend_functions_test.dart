import 'package:clashkingapp/core/functions/legend_functions.dart';
import 'package:clashkingapp/features/player/models/player_legend_day.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final PlayerLegendDay _dummyLegendDay = PlayerLegendDay.fromJson({});

Future<BuildContext> _pumpLocalizedApp(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (buildContext) {
          context = buildContext;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return context;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('legend_functions.dart utilities', () {
    group('convertToTimeAgo', () {
      testWidgets('returns localized relative time text', (tester) async {
        final context = await _pumpLocalizedApp(tester);
        final localizations = AppLocalizations.of(context)!;
        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        expect(
          convertToTimeAgo(nowSeconds - 30, context),
          localizations.timeJustNow,
        );
        expect(
          convertToTimeAgo(nowSeconds - 60, context),
          localizations.timeMinuteAgo(1),
        );
        expect(
          convertToTimeAgo(nowSeconds - (2 * 3600), context),
          localizations.timeHoursAgo(2),
        );
        expect(
          convertToTimeAgo(nowSeconds - (2 * 86400), context),
          localizations.timeDaysAgo(2),
        );
      });
    });

    group('findSeasonStartDate', () {
      test('returns the last Monday of the previous month before rollover', () {
        final result = findSeasonStartDate(DateTime(2025, 5, 15));

        expect(result.weekday, DateTime.monday);
        expect(result.year, 2025);
        expect(result.month, 4);
        expect(result.day, 28);
      });

      test(
        'returns the last Monday of the current month during the season',
        () {
          final result = findSeasonStartDate(DateTime(2025, 5, 30));

          expect(result.weekday, DateTime.monday);
          expect(result.year, 2025);
          expect(result.month, 5);
          expect(result.day, 26);
        },
      );
    });

    group('convertToContinuousScale', () {
      test('returns an empty list for empty data', () {
        final spots = convertToContinuousScale({}, DateTime.utc(2025, 4, 28));

        expect(spots, isEmpty);
      });

      test('converts season data to continuous FlSpot values', () {
        final spots = convertToContinuousScale({
          '28': '5000',
          '30': '5100',
          '1': '5200',
        }, DateTime.utc(2025, 4, 28));

        expect(spots, hasLength(3));
        expect(spots[0], isA<FlSpot>());
        expect(spots[0].x, 0.0);
        expect(spots[0].y, 5000.0);
        expect(spots[1].x, 2.0);
        expect(spots[1].y, 5100.0);
        expect(spots[2].x, 3.0);
        expect(spots[2].y, 5200.0);
      });
    });

    group('findSeasonStartEndDate', () {
      test('returns two dates for a date before the current season start', () {
        final range = findSeasonStartEndDate(DateTime(2025, 5, 15));

        expect(range, hasLength(2));
        expect(range[0], DateTime(2025, 4, 28));
        expect(range[0].weekday, DateTime.monday);
        expect(range[1], DateTime(2025, 5, 25));
        expect(range[1].isAfter(range[0]), isTrue);
      });

      test(
        'returns Monday boundaries for a date inside the current season',
        () {
          final range = findSeasonStartEndDate(DateTime(2025, 5, 30));

          expect(range, hasLength(2));
          expect(range[0], DateTime(2025, 5, 26));
          expect(range[0].weekday, DateTime.monday);
          expect(range[1], DateTime(2025, 6, 30));
          expect(range[1].weekday, DateTime.monday);
        },
      );
    });

    group('findCurrentSeasonMonth', () {
      test('returns the first day of the season month', () {
        final result = findCurrentSeasonMonth(DateTime(2025, 5, 15));

        expect(result.year, 2025);
        expect(result.month, 5);
        expect(result.day, 1);
      });
    });

    group('getLastMonthWithSeasonData', () {
      test('returns the most recent month from season data', () {
        final result = getLastMonthWithSeasonData({
          '1-15': _dummyLegendDay,
          '4-20': _dummyLegendDay,
        });

        expect(result.year, DateTime.now().year);
        expect(result.month, 4);
        expect(result.day, 1);
      });

      test('throws when season data is empty', () {
        expect(() => getLastMonthWithSeasonData({}), throwsA(isA<Exception>()));
      });
    });
  });
}
