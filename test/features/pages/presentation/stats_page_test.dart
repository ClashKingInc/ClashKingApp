import 'dart:async';

import 'package:clashkingapp/common/widgets/empty_state.dart';
import 'package:clashkingapp/common/widgets/loading/skeleton_loading.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/pages/presentation/stats_page.dart';
import 'package:clashkingapp/features/stats/data/stats_repository.dart';
import 'package:clashkingapp/features/stats/models/stats_models.dart';
import 'package:clashkingapp/features/stats/presentation/stats_provider.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Stats battle tabs fill the available width on wide screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
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

    final battleTabBar = find.byType(TabBar);
    expect(tester.widget<TabBar>(battleTabBar).isScrollable, isFalse);
    final tabBarBounds = tester.getRect(battleTabBar);
    final battleTabs = find.descendant(
      of: battleTabBar,
      matching: find.byType(Tab),
    );
    expect(battleTabs, findsNWidgets(5));
    for (var index = 0; index < 5; index++) {
      expect(
        tester.getCenter(battleTabs.at(index)).dx,
        moreOrLessEquals(
          tabBarBounds.left + tabBarBounds.width * (index + 0.5) / 5,
          epsilon: 2,
        ),
      );
    }
  });

  testWidgets('Stats audience selector exposes each matching tab group', (
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
      find.text('Explore battle performance and the world we track.'),
      findsNothing,
    );
    expect(find.text('Battle'), findsOneWidget);
    expect(find.text('World'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
    expect(find.text('Players'), findsNothing);
    expect(find.text('Clans'), findsNothing);
    expect(find.text('Meta'), findsWidgets);
    expect(find.text('Armies'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('War'), findsWidgets);
    expect(find.text('CWL'), findsWidgets);
    expect(find.text('Top score'), findsNothing);
    expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);

    provider.selectAudience(StatsAudience.world);
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Players'), findsWidgets);
    expect(find.text('Clans'), findsWidgets);
    expect(find.text('Armies'), findsNothing);
    expect(find.text('Global counts'), findsOneWidget);
    expect(find.text('Preview'), findsNothing);
    expect(find.byType(AppEmptyState), findsOneWidget);
    final worldTabBar = find.byType(TabBar);
    expect(tester.widget<TabBar>(worldTabBar).isScrollable, isFalse);
    final tabBarBounds = tester.getRect(worldTabBar);
    final worldTabs = find.descendant(
      of: worldTabBar,
      matching: find.byType(Tab),
    );
    expect(worldTabs, findsNWidgets(3));
    for (var index = 0; index < 3; index++) {
      expect(
        tester.getCenter(worldTabs.at(index)).dx,
        moreOrLessEquals(
          tabBarBounds.left + tabBarBounds.width * (index + 0.5) / 3,
          epsilon: 2,
        ),
      );
    }
    provider.selectSection(StatsSection.players);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'TH18: 100')), findsOneWidget);

    provider.selectAudience(StatsAudience.battle);
    provider.selectSection(StatsSection.armies);
    await tester.pumpAndSettle();
    expect(find.text('Search exact compositions'), findsOneWidget);
    expect(find.byTooltip('Choose up to 90 days'), findsNothing);
    expect(find.byTooltip('Filters'), findsOneWidget);
    expect(provider.dates.inclusiveDays, 30);

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Quick Filters'), findsOneWidget);
    expect(find.text('Last 30 Days'), findsOneWidget);
    expect(find.text('Time Filters'), findsOneWidget);
  });

  testWidgets('War keeps detailed filters in the shared filter dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = StatsProvider(repository: _WidgetStatsRepository());

    await tester.pumpWidget(_StatsTestApp(provider: provider));
    await tester.pumpAndSettle();
    provider.selectSection(StatsSection.war);
    await tester.pumpAndSettle();

    expect(
      find.text('Regular wars only; friendly wars and CWL are excluded.'),
      findsNothing,
    );
    expect(find.textContaining('All Town Halls'), findsOneWidget);

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsOneWidget);
    final dialog = find.byType(Dialog);
    expect(dialog, findsOneWidget);
    expect(tester.widget<Dialog>(dialog).insetPadding, isNull);
    expect(find.byType(BottomSheet), findsNothing);
    expect(
      find.descendant(of: dialog, matching: find.byType(Card)),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: dialog, matching: find.byType(ElevatedButton)),
      findsOneWidget,
    );
    expect(find.text('War Settings'), findsOneWidget);
    expect(
      find.text('Regular wars only; friendly wars and CWL are excluded.'),
      findsNothing,
    );

    await tester.tap(find.text('War Settings'));
    await tester.pumpAndSettle();

    expect(
      find.text('Regular wars only; friendly wars and CWL are excluded.'),
      findsOneWidget,
    );
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('Items keeps selection controls in the shared filter dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = StatsProvider(repository: _WidgetStatsRepository());

    await tester.pumpWidget(_StatsTestApp(provider: provider));
    await tester.pumpAndSettle();
    provider.selectSection(StatsSection.items);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Army records do not contain item levels. Composition data comes '
        'from ranked battlelogs; War and CWL performance remain separate.',
      ),
      findsNothing,
    );
    expect(find.text('Item ID or stored name'), findsNothing);
    expect(find.text('Add item'), findsNothing);

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Town Hall'), findsOneWidget);
    final itemsSection = find.descendant(
      of: find.byType(Dialog),
      matching: find.text('Items'),
    );
    expect(itemsSection, findsOneWidget);

    await tester.tap(find.text('Town Hall'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Army records do not contain item levels. Composition data comes '
        'from ranked battlelogs; War and CWL performance remain separate.',
      ),
      findsNothing,
    );
    expect(find.text('Town Hall'), findsNWidgets(2));
    expect(find.text('League tier'), findsOneWidget);

    await tester.ensureVisible(itemsSection);
    await tester.pumpAndSettle();
    await tester.tap(itemsSection);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Army records do not contain item levels. Composition data comes '
        'from ranked battlelogs; War and CWL performance remain separate.',
      ),
      findsOneWidget,
    );
    expect(find.text('Item ID or stored name'), findsOneWidget);
    expect(find.text('Item type'), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('Items uses no-data copy after an empty filtered query', (
    tester,
  ) async {
    final provider = StatsProvider(repository: _EmptyItemsStatsRepository());
    provider.setItemSelectors(const [
      StatsItemSelector(item: 'Barbarian', type: StatsItemType.troop),
    ]);
    provider.selectSection(StatsSection.items);

    await tester.pumpWidget(_StatsTestApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('No battle data yet'), findsOneWidget);
    expect(find.text('Choose items to analyze'), findsNothing);
  });

  testWidgets('Stats loading state uses section-shaped skeletons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _LoadingStatsRepository();
    final provider = StatsProvider(repository: repository);

    await tester.pumpWidget(_StatsTestApp(provider: provider));
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('stats-loading-skeleton')),
      findsOneWidget,
    );
    expect(find.byType(SkeletonLoader), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    repository.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Stats empty data uses the shared clan-style empty state', (
    tester,
  ) async {
    final provider = StatsProvider(repository: _EmptyStatsRepository());

    await tester.pumpWidget(_StatsTestApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.byType(AppEmptyState), findsOneWidget);
    expect(find.text('No battle data yet'), findsOneWidget);
  });

  testWidgets('Stats error state keeps a visible retry action', (tester) async {
    final provider = StatsProvider(repository: _ErrorStatsRepository());

    await tester.pumpWidget(_StatsTestApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Could not load battle intelligence.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('CWL filters use official game league translations', (
    tester,
  ) async {
    GameDataService.loadFromBundleForTesting({
      'war_leagues': [
        {
          '_id': 48000007,
          'name': 'Gold League III',
          'TID': {'name': 'TID_LEAGUE_GOLD3'},
        },
      ],
    });
    GameDataService.loadTranslationsForTesting({
      'TID_LEAGUE_GOLD3': {'DE': 'Gold-Liga III'},
    }, locale: const Locale('de'));
    addTearDown(() {
      GameDataService.loadFromBundleForTesting({});
      GameDataService.translationsData.clear();
    });
    final provider = StatsProvider(repository: _WidgetStatsRepository());
    provider.updateCwlFilters(leagueId: 48000006);
    provider.selectSection(StatsSection.cwl);

    await tester.pumpWidget(
      _StatsTestApp(provider: provider, locale: const Locale('de')),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Gold-Liga III'), findsOneWidget);
    expect(find.textContaining('Gold III'), findsNothing);
  });

  testWidgets('CWL stats keep ARB league fallbacks without static data', (
    tester,
  ) async {
    GameDataService.loadFromBundleForTesting({});
    final provider = StatsProvider(repository: _WidgetStatsRepository());
    provider.selectSection(StatsSection.clans);

    await tester.pumpWidget(_StatsTestApp(provider: provider));
    await tester.pumpAndSettle();

    expect(find.text('Champion I'), findsOneWidget);
    expect(find.text('48000017'), findsNothing);
  });

  testWidgets('Stats header remains stable with large text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = StatsProvider(repository: _WidgetStatsRepository());

    await tester.pumpWidget(
      _StatsTestApp(provider: provider, textScaler: const TextScaler.linear(2)),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Stats'), findsOneWidget);
  });

  testWidgets('Stats content remains bounded on wide layouts', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final provider = StatsProvider(repository: _WidgetStatsRepository());

    await tester.pumpWidget(_StatsTestApp(provider: provider));
    await tester.pumpAndSettle();

    final bounds = find.byKey(const ValueKey('stats-content-bound'));
    expect(bounds, findsWidgets);
    for (final element in bounds.evaluate()) {
      expect(
        tester.getSize(find.byWidget(element.widget)).width,
        lessThanOrEqualTo(1120),
      );
    }
  });
}

class _StatsTestApp extends StatelessWidget {
  const _StatsTestApp({required this.provider, this.textScaler, this.locale});

  final StatsProvider provider;
  final TextScaler? textScaler;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      builder: textScaler == null
          ? null
          : (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
      home: StatsPage(provider: provider),
    );
  }
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
  Future<StatsPerformanceResponse> loadWar(StatsWarQuery request) async =>
      const StatsPerformanceResponse(
        dateRange: StatsDateRange(start: null, end: null),
        metrics: _widgetMetrics,
        breakdowns: [],
      );

  @override
  Future<StatsPerformanceResponse> loadCwl(StatsCwlQuery request) async =>
      const StatsPerformanceResponse(
        dateRange: StatsDateRange(start: null, end: null),
        metrics: _widgetMetrics,
        breakdowns: [],
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

class _LoadingStatsRepository extends StatsRepository {
  final _completer = Completer<StatsPerformanceResponse>();

  @override
  Future<StatsPerformanceResponse> loadRanked(StatsRankedQuery request) =>
      _completer.future;

  void complete() {
    if (_completer.isCompleted) return;
    _completer.complete(
      const StatsPerformanceResponse(
        dateRange: StatsDateRange(start: null, end: null),
        metrics: _widgetMetrics,
        breakdowns: [],
      ),
    );
  }
}

class _EmptyStatsRepository extends StatsRepository {
  @override
  Future<StatsPerformanceResponse> loadRanked(StatsRankedQuery request) async =>
      const StatsPerformanceResponse(
        dateRange: StatsDateRange(start: null, end: null),
        metrics: _emptyMetrics,
        breakdowns: [],
      );
}

class _EmptyItemsStatsRepository extends _WidgetStatsRepository {
  @override
  Future<StatsItemsResponse> loadItems(StatsItemsQuery request) async =>
      const StatsItemsResponse(
        dateRange: StatsDateRange(start: null, end: null),
        items: [],
        count: 0,
      );
}

class _ErrorStatsRepository extends StatsRepository {
  @override
  Future<StatsPerformanceResponse> loadRanked(StatsRankedQuery request) =>
      Future.error(StateError('stats unavailable'));
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

const _emptyMetrics = StatsMetrics(
  available: false,
  sampleSize: 0,
  averageStars: 0,
  averageDestruction: 0,
  zeroStarRate: 0,
  oneStarRate: 0,
  twoStarRate: 0,
  threeStarRate: 0,
  daily: [],
);
