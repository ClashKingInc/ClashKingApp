import {
  StatsBattleFilters,
  StatsCwlQuery,
  StatsDateFilter,
  StatsItemQuantityFilter,
  StatsItemSelector,
  StatsItemType,
  StatsMetrics,
  StatsRankedQuery,
} from './stats-models';

describe('stats models', () => {
  const dates = new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30));

  it('matches Flutter battle filter wire keys and date semantics', () => {
    expect(dates.inclusiveDays).toBe(30);
    expect(
      new StatsBattleFilters(
        dates,
        18,
        17,
        false,
        2,
        [new StatsItemQuantityFilter('Root Rider', 2, 6)],
        ['Goblin'],
        250,
      ).toJson(),
    ).toEqual({
      start_date: '2026-08-01',
      end_date: '2026-08-30',
      townhall_level: 18,
      opponent_townhall_level: 17,
      equal_townhalls: false,
      ranked_league_tier_id: 2,
      include_items: [{ item: 'Root Rider', min_quantity: 2, max_quantity: 6 }],
      exclude_items: ['Goblin'],
      minimum_sample_size: 250,
    });
  });

  it('keeps ranked dates nested and CWL filters additive', () => {
    expect(new StatsRankedQuery(dates, 18, 1).toJson()).toEqual({
      dates: { start_date: '2026-08-01', end_date: '2026-08-30' },
      townhall_level: 18,
      ranked_league_tier_id: 1,
    });
    expect(new StatsCwlQuery(dates, 18, 18, true, 48000000, ['2026-08']).toJson()).toEqual({
      dates: { start_date: '2026-08-01', end_date: '2026-08-30' },
      townhall_level: 18,
      opponent_townhall_level: 18,
      equal_townhalls: true,
      cwl_league_id: 48000000,
      seasons: ['2026-08'],
    });
  });

  it('validates equipment ownership exactly like Flutter', () => {
    expect(new StatsItemSelector('Magic Mirror', StatsItemType.equipment).isValid).toBe(false);
    expect(
      new StatsItemSelector('Magic Mirror', StatsItemType.equipment, 'Archer Queen').toJson(),
    ).toEqual({ item: 'Magic Mirror', type: 'equipment', hero: 'Archer Queen' });
  });

  it('normalizes numeric metrics without changing rate units', () => {
    const value = StatsMetrics.fromJson({
      available: true,
      sample_size: '12',
      average_stars: '2.1',
      average_destruction: 81.3,
      zero_star_rate: 0.01,
      one_star_rate: 0.09,
      two_star_rate: 0.4,
      three_star_rate: 0.5,
      daily: [{ date: '2026-08-01', sample_size: 12, average_stars: 2.1 }],
    });
    expect(value.sampleSize).toBe(12);
    expect(value.threeStarRate).toBe(0.5);
    expect(value.daily).toHaveLength(1);
  });
});
