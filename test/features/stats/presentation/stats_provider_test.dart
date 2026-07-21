import 'package:clashkingapp/features/stats/data/stats_repository.dart';
import 'package:clashkingapp/features/stats/models/stats_models.dart';
import 'package:clashkingapp/features/stats/presentation/stats_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps one date range while moving between Stats subpages', () async {
    final repository = _FakeStatsRepository();
    final provider = StatsProvider(
      repository: repository,
      now: () => DateTime(2026, 7, 20),
    );

    expect(provider.dates.inclusiveDays, 30);
    await provider.setDates(DateTime(2026, 6, 1), DateTime(2026, 6, 20));
    provider.selectSection(StatsSection.war);
    await _settle();

    expect(provider.dates.start, DateTime(2026, 6, 1));
    expect(provider.dates.end, DateTime(2026, 6, 20));
    expect(repository.lastWarQuery?.dates.start, DateTime(2026, 6, 1));
    expect(provider.stateFor(StatsSection.war).status, StatsLoadStatus.data);
  });

  test('rejects ranges longer than 90 inclusive days', () async {
    final provider = StatsProvider(
      repository: _FakeStatsRepository(),
      now: () => DateTime(2026, 7, 20),
    );

    await expectLater(
      provider.setDates(DateTime(2026, 1, 1), DateTime(2026, 4, 1)),
      throwsArgumentError,
    );
  });

  test('ranked always sends one Town Hall and one league tier', () async {
    final repository = _FakeStatsRepository();
    final provider = StatsProvider(
      repository: repository,
      now: () => DateTime(2026, 7, 20),
    );
    provider.updateRankedFilters(townHall: 17, leagueTier: 1);

    await provider.load(StatsSection.ranked, force: true);

    expect(repository.lastRankedQuery?.townHallLevel, 17);
    expect(repository.lastRankedQuery?.rankedLeagueTierId, 1);
  });
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

class _FakeStatsRepository extends StatsRepository {
  StatsWarQuery? lastWarQuery;
  StatsRankedQuery? lastRankedQuery;

  @override
  Future<StatsOverviewResponse> loadOverview(StatsDateFilter dates) async =>
      StatsOverviewResponse(
        dateRange: const StatsDateRange(start: null, end: null),
        counts: _counts,
        ranked: _metrics,
        war: _metrics,
        cwl: _metrics,
      );

  @override
  Future<StatsArmiesResponse> loadArmies(StatsArmiesQuery request) async =>
      const StatsArmiesResponse(
        dateRange: StatsDateRange(start: null, end: null),
        items: [],
        count: 0,
      );

  @override
  Future<StatsItemsResponse> loadItems(StatsItemsQuery request) async =>
      const StatsItemsResponse(
        dateRange: StatsDateRange(start: null, end: null),
        items: [],
        count: 0,
      );

  @override
  Future<StatsPerformanceResponse> loadWar(StatsWarQuery request) async {
    lastWarQuery = request;
    return _performance;
  }

  @override
  Future<StatsPerformanceResponse> loadCwl(StatsCwlQuery request) async =>
      _performance;

  @override
  Future<StatsPerformanceResponse> loadRanked(StatsRankedQuery request) async {
    lastRankedQuery = request;
    return _performance;
  }
}

const _counts = StatsGlobalCounts(
  playersInWar: 10,
  clansInWar: 2,
  totalJoinLeaves: 100,
  playersInLegends: 5,
  playerCount: 1000,
  clanCount: 100,
  warsStored: 50,
);

const _metrics = StatsMetrics(
  available: true,
  sampleSize: 100,
  averageStars: 2,
  averageDestruction: 80,
  zeroStarRate: 5,
  oneStarRate: 10,
  twoStarRate: 45,
  threeStarRate: 40,
  daily: [],
);

const _performance = StatsPerformanceResponse(
  dateRange: StatsDateRange(start: null, end: null),
  metrics: _metrics,
  breakdowns: [],
);
