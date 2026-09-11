import {
  StatsArmiesQuery,
  StatsArmiesResponse,
  StatsBattleFilters,
  StatsCwlQuery,
  StatsDateFilter,
  StatsItemQuantityFilter,
  StatsItemSelector,
  StatsItemType,
  StatsLegendCohort,
  StatsLegendQuery,
  StatsLegendResponse,
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

  it('maps the exact Legend day range and cohort without inventing item dimensions', () => {
    expect(new StatsLegendQuery(dates, StatsLegendCohort.top1000).toQuery()).toEqual({
      'time[after]': '2026-08-01',
      'time[before]': '2026-08-30',
      cohort: 'top_1000',
    });
    const response = StatsLegendResponse.fromJson({
      cohort: 'top_1000',
      items: [
        {
          day: '2026-08-30',
          attacks: 10,
          players: 3,
          starCounts: { zero: 0, one: 1, two: 4, three: 5 },
          averageDuration: 90,
          averageDestruction: 95,
          heroes: [{ id: 100, uses: 10, triples: 5 }],
          pets: [{ id: 200, uses: 8, triples: 4 }],
          equipment: [{ id: 300, uses: 6, triples: 3 }],
          petAssignments: [{ petId: 200, heroId: 100, uses: 8, triples: 4 }],
        },
      ],
    });
    expect(response).toMatchObject({
      cohort: 'top_1000',
      items: [{ day: '2026-08-30', attacks: 10, heroes: [{ id: 100, uses: 10 }] }],
    });
    expect(response.items[0]?.metrics).toMatchObject({ averageStars: 2.4, threeStarRate: 0.5 });
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
          familyId: '123',
          name: null,
          shareCode: 'u1x2',
          attacks: 20,
          players: 12,
          starCounts: { zero: 1, one: 2, two: 7, three: 10 },
          averageDuration: 97,
          averageDestruction: 92.5,
          totalLegendAttacks: 200,
        },
      ],
      nextCursor: null,
    });
    expect(response.count).toBe(1);
    expect(response.items[0]).toMatchObject({
      familyId: '123',
      name: null,
      armyShareCode: 'u1x2',
      players: 12,
      totalLegendAttacks: 200,
      averageDuration: 97,
      metrics: {
        sampleSize: 20,
        averageStars: 2.3,
        averageDestruction: 92.5,
        threeStarRate: 0.5,
        usageRate: 0.1,
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
