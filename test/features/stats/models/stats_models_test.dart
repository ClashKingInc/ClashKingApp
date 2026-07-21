import 'package:clashkingapp/features/stats/models/stats_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes typed metrics and exact army composition', () {
    final response = StatsArmiesResponse.fromJson({
      'date_range': {
        'start': '2026-07-01T00:00:00Z',
        'end': '2026-07-20T23:59:59Z',
      },
      'count': 1,
      'items': [
        {
          'army_share_code': 'u1x8-u2x2',
          'army_items': ['u_1', 'u_2'],
          'army_counts': {'u_1': 8, 'u_2': 2},
          'available': true,
          'sample_size': 250,
          'usage_rate': 12.5,
          'average_stars': 2.2,
          'average_destruction': 88.4,
          'zero_star_rate': 2,
          'one_star_rate': 8,
          'two_star_rate': 48,
          'three_star_rate': 42,
          'daily': [
            {
              'date': '2026-07-20',
              'sample_size': 20,
              'average_stars': 2.3,
              'average_destruction': 90,
              'zero_star_rate': 0,
              'one_star_rate': 10,
              'two_star_rate': 40,
              'three_star_rate': 50,
            },
          ],
        },
      ],
    });

    expect(response.count, 1);
    expect(response.items.single.armyCounts['u_1'], 8);
    expect(response.items.single.metrics.sampleSize, 250);
    expect(response.items.single.metrics.daily.single.threeStarRate, 50);
  });

  test('request JSON has quantity filters and intentionally no levels', () {
    final json = StatsArmiesQuery(
      filters: StatsBattleFilters(
        dates: StatsDateFilter(
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 20),
        ),
        includeItems: const [
          StatsItemQuantityFilter(item: 'u_1', minQuantity: 2, maxQuantity: 5),
        ],
      ),
    ).toJson();

    expect(json['dates'], {
      'start_date': '2026-07-01',
      'end_date': '2026-07-20',
    });
    expect((json['include_items'] as List).single, {
      'item': 'u_1',
      'min_quantity': 2,
      'max_quantity': 5,
    });
    expect(json.toString(), isNot(contains('level')));
  });

  test('equipment requires one valid owning hero in the typed selector', () {
    expect(
      const StatsItemSelector(
        item: 'Magic Mirror',
        type: StatsItemType.equipment,
      ).isValid,
      isFalse,
    );
    expect(
      const StatsItemSelector(
        item: 'Magic Mirror',
        type: StatsItemType.equipment,
        hero: 'Archer Queen',
      ).isValid,
      isTrue,
    );
    expect(
      const StatsItemSelector(
        item: 'Magic Mirror',
        type: StatsItemType.equipment,
        hero: 'Battle Copter',
      ).isValid,
      isFalse,
    );
  });

  test('decodes grouped count keys without losing null buckets', () {
    final counts = decodeStatsGroupedCounts({
      'items': [
        {'townhall_level': 18, 'count': 200},
        {'townhall_level': null, 'count': 3},
      ],
    }, 'townhall_level');

    expect(counts.first.id, 18);
    expect(counts.first.count, 200);
    expect(counts.last.id, isNull);
  });
}
