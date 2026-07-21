import 'package:clashkingapp/features/rankings/data/rankings_provider.dart';
import 'package:clashkingapp/features/rankings/data/rankings_service.dart';
import 'package:clashkingapp/features/rankings/models/ranking_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every board and filter change issues a new request', () async {
    final service = _RecordingRankingsService();
    final provider = RankingsProvider(
      service: service,
      leagueOptions: const [
        RankingLeagueOption.legendOne,
        RankingLeagueOption(
          id: 105000033,
          name: 'Legend II',
          iconUrl: 'legend-2',
        ),
      ],
      clock: () => DateTime(2026, 7, 20),
    );

    await provider.initialize();
    expect(service.queries, hasLength(1));
    expect(service.queries.last.board, RankingBoard.playerHome);
    expect(service.queries.last.location.apiPath, 'global');

    await provider.selectLocation(service.locations.last);
    expect(service.queries.last.location.name, 'United States');

    await provider.selectBoard(RankingBoard.playerTownHall);
    await provider.selectTownHall(17);
    await provider.selectPeriod(RankingPeriod.history);
    await provider.selectHistoryDate(DateTime(2026, 7, 18));
    expect(service.queries.last.board, RankingBoard.playerTownHall);
    expect(service.queries.last.townHallLevel, 17);
    expect(service.queries.last.period, RankingPeriod.history);
    expect(service.queries.last.historyDate, DateTime(2026, 7, 18));

    await provider.selectBoard(RankingBoard.playerRanked);
    await provider.selectLeague(provider.leagueOptions.last);
    expect(service.queries.last.leagueTier.id, 105000033);

    await provider.selectAudience(RankingAudience.clans);
    await provider.selectBoard(RankingBoard.clanDonations);
    expect(service.queries.last.board, RankingBoard.clanDonations);
    expect(service.queries.last.period, RankingPeriod.current);
    expect(service.queries.length, 10);
  });

  test('surfaces a clear empty history result without an error', () async {
    final service = _RecordingRankingsService(empty: true);
    final provider = RankingsProvider(
      service: service,
      leagueOptions: const [RankingLeagueOption.legendOne],
      clock: () => DateTime(2026, 7, 20),
    );

    await provider.initialize();
    await provider.selectPeriod(RankingPeriod.history);

    expect(provider.error, isNull);
    expect(provider.result?.entries, isEmpty);
    expect(provider.isLoading, isFalse);
  });
}

class _RecordingRankingsService extends RankingsService {
  _RecordingRankingsService({this.empty = false});

  final bool empty;
  final queries = <RankingQuery>[];
  final locations = const [
    RankingLocation.worldwide(),
    RankingLocation(id: 32000006, name: 'International', isCountry: false),
    RankingLocation(
      id: 32000007,
      name: 'United States',
      isCountry: true,
      countryCode: 'US',
    ),
  ];

  @override
  Future<List<RankingLocation>> fetchLocations() async => locations;

  @override
  Future<RankingResult> fetchRankings(RankingQuery query) async {
    queries.add(query);
    return RankingResult(
      entries: empty
          ? const []
          : [
              RankingEntry(
                audience: query.board.audience,
                rank: 1,
                previousRank: 2,
                tag: query.board.isClan ? '#CLAN' : '#PLAYER',
                name: query.board.isClan ? 'Clan One' : 'Player One',
                subtitle: query.board.isClan ? '#CLAN' : '#PLAYER',
                score: 6000,
                imageUrl: query.board.iconUrl,
                metricImageUrl: query.board.iconUrl,
                townHallLevel: 18,
              ),
            ],
      source: query.board.source,
      limit: query.board.source == RankingSource.official ? 200 : 500,
    );
  }
}
