import 'dart:convert';

import 'package:clashkingapp/features/stats/data/stats_repository.dart';
import 'package:clashkingapp/features/stats/models/stats_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

void main() {
  test('uses QUERY with typed JSON for army intelligence', () async {
    final api = FakeApiService();
    api.queryStubs['/stats/armies'] = http.Response(
      jsonEncode({'date_range': {}, 'items': [], 'count': 0}),
      200,
    );
    final repository = StatsRepository(apiService: api);

    final result = await repository.loadArmies(
      StatsArmiesQuery(
        filters: StatsBattleFilters(
          dates: StatsDateFilter(
            start: DateTime(2026, 7, 1),
            end: DateTime(2026, 7, 20),
          ),
          minimumSampleSize: 100,
        ),
      ),
    );

    expect(result.items, isEmpty);
    expect(api.lastQueryBodies, contains('/stats/armies'));
    expect(
      (api.lastQueryBodies['/stats/armies'] as Map)['minimum_sample_size'],
      100,
    );
  });

  test('overview sends the selected inclusive date range', () async {
    final api = FakeApiService();
    const endpoint =
        '/stats/overview?start_date=2026-07-01&end_date=2026-07-20';
    api.getStubs[endpoint] = http.Response(
      jsonEncode({
        'date_range': {},
        'counts': {},
        'ranked': _metricsJson(),
        'war': _metricsJson(),
        'cwl': _metricsJson(),
      }),
      200,
    );

    final result = await StatsRepository(apiService: api).loadOverview(
      StatsDateFilter(start: DateTime(2026, 7, 1), end: DateTime(2026, 7, 20)),
    );

    expect(api.getCallCounts[endpoint], 1);
    expect(result.ranked.available, isFalse);
  });
}

Map<String, dynamic> _metricsJson() => {
  'available': false,
  'sample_size': 0,
  'average_stars': 0,
  'average_destruction': 0,
  'zero_star_rate': 0,
  'one_star_rate': 0,
  'two_star_rate': 0,
  'three_star_rate': 0,
  'daily': [],
};
