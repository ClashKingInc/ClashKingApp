import 'dart:convert';

import 'package:clashkingapp/features/rankings/data/rankings_service.dart';
import 'package:clashkingapp/features/rankings/models/ranking_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

void main() {
  test('loads the complete dynamic list with Worldwide pinned first', () async {
    final api = FakeApiService();
    api.getStubs['/locations'] = http.Response(
      jsonEncode({
        'items': [
          {
            'id': 32000007,
            'name': 'Afghanistan',
            'isCountry': true,
            'countryCode': 'AF',
          },
          {'id': 32000000, 'name': 'Europe', 'isCountry': false},
          {'id': 32000006, 'name': 'International', 'isCountry': false},
        ],
      }),
      200,
    );

    final locations = await RankingsService(apiService: api).fetchLocations();

    expect(locations.map((item) => item.name), ['Worldwide', 'Afghanistan']);
    expect(locations[1].id, 32000007);
    expect(api.getCallCounts['/locations'], 1);
  });

  test('uses the official proxy route for current Home Village', () async {
    final api = FakeApiService();
    const endpoint = '/locations/global/rankings/players?limit=200';
    api.getStubs[endpoint] = http.Response(
      jsonEncode({
        'items': [
          {'tag': '#ONE', 'name': 'One', 'rank': 1, 'trophies': 6200},
        ],
      }),
      200,
    );

    final result = await RankingsService(apiService: api).fetchRankings(
      RankingQuery(
        board: RankingBoard.playerHome,
        location: const RankingLocation.worldwide(),
        period: RankingPeriod.current,
        historyDate: DateTime(2026, 7, 19),
        townHallLevel: 18,
        leagueTier: RankingLeagueOption.legendOne,
      ),
    );

    expect(api.getCallCounts[endpoint], 1);
    expect(result.source, RankingSource.official);
    expect(result.limit, 200);
    expect(result.entries.single.tag, '#ONE');
  });

  test('uses ClashKing top-500 and stored-history routes', () async {
    final api = FakeApiService();
    const current = '/leaderboard/townhalls/17?limit=500';
    const history = '/leaderboard/townhalls/17/history/2026-07-18?limit=200';
    api.getStubs[current] = http.Response(
      jsonEncode({
        'items': [
          {
            'tag': '#TOWN',
            'name': 'Town Player',
            'rank': 1,
            'townhall_level': 17,
            'trophies': 5800,
          },
        ],
      }),
      200,
    );
    api.getStubs[history] = http.Response(
      jsonEncode({'kind': 'townhall', 'items': []}),
      200,
    );
    final service = RankingsService(apiService: api);
    final base = RankingQuery(
      board: RankingBoard.playerTownHall,
      location: const RankingLocation.worldwide(),
      period: RankingPeriod.current,
      historyDate: DateTime(2026, 7, 18),
      townHallLevel: 17,
      leagueTier: RankingLeagueOption.legendOne,
    );

    final currentResult = await service.fetchRankings(base);
    final historyResult = await service.fetchRankings(
      RankingQuery(
        board: base.board,
        location: base.location,
        period: RankingPeriod.history,
        historyDate: base.historyDate,
        townHallLevel: base.townHallLevel,
        leagueTier: base.leagueTier,
      ),
    );

    expect(api.getCallCounts[current], 1);
    expect(api.getCallCounts[history], 1);
    expect(currentResult.limit, 500);
    expect(currentResult.entries.single.townHallLevel, 17);
    expect(historyResult.entries, isEmpty);
  });

  test('applies the selected tier badge to ranked leaderboard rows', () async {
    final api = FakeApiService();
    const endpoint = '/leaderboard/league/105000036?limit=500';
    api.getStubs[endpoint] = http.Response(
      jsonEncode({
        'items': [
          {
            'tag': '#RANKED',
            'name': 'Ranked Player',
            'placement': 1,
            'league_trophies': 900,
            'league': {
              'iconUrls': {'medium': 'legacy-purple'},
            },
          },
        ],
      }),
      200,
    );

    const selectedLeague = RankingLeagueOption(
      id: 105000036,
      name: 'Legend I',
      iconUrl: 'legend-one',
    );
    final result = await RankingsService(apiService: api).fetchRankings(
      RankingQuery(
        board: RankingBoard.playerRanked,
        location: const RankingLocation.worldwide(),
        period: RankingPeriod.current,
        historyDate: DateTime(2026, 7, 20),
        townHallLevel: 18,
        leagueTier: selectedLeague,
      ),
    );

    expect(result.entries.single.imageUrl, selectedLeague.iconUrl);
    expect(result.entries.single.metricImageUrl, selectedLeague.iconUrl);
  });
}
