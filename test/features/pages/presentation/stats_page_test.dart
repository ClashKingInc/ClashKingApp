import 'package:clashkingapp/features/pages/presentation/stats_page.dart';
import 'package:clashkingapp/features/stats/data/stats_repository.dart';
import 'package:clashkingapp/features/stats/models/stats_models.dart';
import 'package:clashkingapp/features/stats/presentation/stats_provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Stats is battle intelligence with six mobile subpages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = StatsProvider(
      repository: _WidgetStatsRepository(),
      now: () => DateTime(2026, 7, 20),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatsPage(provider: provider),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Battle Intelligence from aggregated battlelogs.'),
      findsOneWidget,
    );
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Armies'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('War'), findsWidgets);
    expect(find.text('CWL'), findsWidgets);
    expect(find.text('Ranked'), findsWidgets);
    expect(find.text('Top score'), findsNothing);
    expect(find.text('Global counts'), findsOneWidget);

    await tester.tap(find.text('Armies'));
    await tester.pumpAndSettle();
    expect(find.text('Search exact compositions'), findsOneWidget);
    expect(provider.dates.inclusiveDays, 30);
  });
}

class _WidgetStatsRepository extends StatsRepository {
  @override
  Future<StatsOverviewResponse> loadOverview(StatsDateFilter dates) async =>
      const StatsOverviewResponse(
        dateRange: StatsDateRange(start: null, end: null),
        counts: StatsGlobalCounts(
          playersInWar: 1,
          clansInWar: 1,
          totalJoinLeaves: 1,
          playersInLegends: 1,
          playerCount: 1,
          clanCount: 1,
          warsStored: 1,
        ),
        ranked: _widgetMetrics,
        war: _widgetMetrics,
        cwl: _widgetMetrics,
      );

  @override
  Future<StatsArmiesResponse> loadArmies(StatsArmiesQuery request) async =>
      const StatsArmiesResponse(
        dateRange: StatsDateRange(start: null, end: null),
        items: [],
        count: 0,
      );
}

const _widgetMetrics = StatsMetrics(
  available: true,
  sampleSize: 10,
  averageStars: 2,
  averageDestruction: 80,
  zeroStarRate: 5,
  oneStarRate: 10,
  twoStarRate: 45,
  threeStarRate: 40,
  daily: [],
);
