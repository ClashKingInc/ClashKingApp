import {
  StatsArmiesQuery,
  StatsArmiesResponse,
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

  it('builds the canonical camelCase stats query and preserves date semantics', () => {
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
      ).toQuery(),
    ).toEqual({
      startDate: '2026-08-01',
      endDate: '2026-08-30',
      townHallLevel: 18,
      opponentTownHallLevel: 17,
      equalTownHalls: false,
      leagueTierId: 2,
      includeItems: ['Root Rider:2:6'],
      excludeItems: ['Goblin'],
      minimumSampleSize: 250,
    });
  });

  it('keeps a single-day army range as the same inclusive start and end date', () => {
    const day = new Date(2026, 7, 1);
    const query = new StatsArmiesQuery(
      new StatsBattleFilters(new StatsDateFilter(day, day)),
    ).toQuery();

    expect(query['time[after]']).toBe('2026-08-01');
    expect(query['time[before]']).toBe('2026-08-01');
  });

  it('maps supported hero and equipment identities onto family filters', () => {
    const query = new StatsArmiesQuery(
      new StatsBattleFilters(dates, undefined, undefined, undefined, undefined, [
        new StatsItemQuantityFilter('hero:100', 1),
        new StatsItemQuantityFilter('hero_equipment:200', 1),
      ]),
    ).toQuery();

    expect(query.heroIds).toBe('100');
    expect(query.equipmentIds).toBe('200');
  });

  it('keeps ranked and CWL filters flat and additive', () => {
    expect(new StatsRankedQuery(dates, 18, 1).toQuery()).toEqual({
      startDate: '2026-08-01',
      endDate: '2026-08-30',
      townHallLevel: 18,
      leagueTierId: 1,
    });
    expect(new StatsCwlQuery(dates, 18, 18, true, 48000000, ['2026-08']).toQuery()).toEqual({
      startDate: '2026-08-01',
      endDate: '2026-08-30',
      townHallLevel: 18,
      opponentTownHallLevel: 18,
      equalTownHalls: true,
      cwlLeagueId: 48000000,
      seasons: ['2026-08'],
    });
  });

  it('maps the canonical army search contract into the existing stats view model', () => {
    const query = new StatsArmiesQuery(
      new StatsBattleFilters(
        dates,
        18,
        undefined,
        undefined,
        2,
        [new StatsItemQuantityFilter('troop:4000000', 2, 6)],
        ['spell:26000000'],
        250,
      ),
      10,
      'tripleRate',
    );
    expect(query.toQuery()).toEqual({
      'time[after]': '2026-08-01',
      'time[before]': '2026-08-30',
      minimumAttacks: 250,
      limit: 10,
      sort: 'tripleRate',
      direction: 'desc',
    });

    const response = StatsArmiesResponse.fromJson({
      items: [
        {
          armyHash: '0'.repeat(64),
          name: 'Queen Charge',
          shareCode: 'u1x2',
          attacks: 20,
          players: 12,
          starCounts: { zero: 1, one: 2, two: 7, three: 10 },
          averageDuration: 97,
          averageDestruction: 92.5,
        },
      ],
      nextCursor: null,
    });
    expect(response.count).toBe(1);
    expect(response.items[0]).toMatchObject({
      armyShareCode: 'u1x2',
      armyItems: ['Queen Charge'],
      armyCounts: {},
      metrics: {
        sampleSize: 20,
        averageStars: 2.3,
        averageDestruction: 92.5,
        threeStarRate: 0.5,
      },
    });
  });

  it('validates equipment ownership exactly like Flutter', () => {
    expect(new StatsItemSelector('Magic Mirror', StatsItemType.equipment).isValid).toBe(false);
    expect(
      new StatsItemSelector('Magic Mirror', StatsItemType.equipment, 'Archer Queen').toQueryValue(),
    ).toBe('equipment:Magic Mirror:Archer Queen');
  });

  it('normalizes numeric metrics without changing rate units', () => {
    const value = StatsMetrics.fromJson({
      available: true,
      sampleSize: '12',
      averageStars: '2.1',
      averageDestruction: 81.3,
      zeroStarRate: 0.01,
      oneStarRate: 0.09,
      twoStarRate: 0.4,
      threeStarRate: 0.5,
      daily: [{ date: '2026-08-01', sampleSize: 12, averageStars: 2.1 }],
    });
    expect(value.sampleSize).toBe(12);
    expect(value.threeStarRate).toBe(0.5);
    expect(value.daily).toHaveLength(1);
  });
});
