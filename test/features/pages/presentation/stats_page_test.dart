import 'package:clashkingapp/features/pages/presentation/stats_page.dart';
import 'package:clashkingapp/features/stats/data/stats_repository.dart';
import 'package:clashkingapp/features/stats/models/stats_models.dart';
import 'package:clashkingapp/features/stats/presentation/stats_provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Stats uses Battle and World header subpages', (tester) async {
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
      find.text('Explore battle performance and the world we track.'),
      findsOneWidget,
    );
    expect(find.text('Battle'), findsOneWidget);
    expect(find.text('World'), findsOneWidget);
    expect(find.text('Meta'), findsOneWidget);
    expect(find.text('Armies'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('War'), findsWidgets);
    expect(find.text('CWL'), findsWidgets);
    expect(find.text('Top score'), findsNothing);

    await tester.tap(find.text('World'));
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Players'), findsWidgets);
    expect(find.text('Clans'), findsWidgets);
    expect(find.text('Global counts'), findsOneWidget);

    await tester.tap(find.text('Battle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Armies'));
    await tester.pumpAndSettle();
    expect(find.text('Search exact compositions'), findsOneWidget);
    expect(provider.dates.inclusiveDays, 30);
  });
}

class _WidgetStatsRepository extends StatsRepository {
  @override
  Future<StatsPerformanceResponse> loadRanked(StatsRankedQuery request) async =>
      const StatsPerformanceResponse(
        dateRange: StatsDateRange(start: null, end: null),
        metrics: _widgetMetrics,
        breakdowns: [],
      );

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

  @override
  Future<StatsPlayerCountsResponse> loadPlayerCounts() async =>
      const StatsPlayerCountsResponse(
        townHalls: [StatsGroupedCount(id: 18, count: 100)],
        builderHalls: [StatsGroupedCount(id: 10, count: 50)],
        leagueTiers: [StatsGroupedCount(id: 105000035, count: 25)],
      );

  @override
  Future<StatsClanCountsResponse> loadClanCounts() async =>
      const StatsClanCountsResponse(
        locations: [StatsGroupedCount(id: 32000000, count: 10)],
        cwlLeagues: [StatsGroupedCount(id: 48000017, count: 8)],
        capitalLeagues: [StatsGroupedCount(id: 85000018, count: 7)],
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
