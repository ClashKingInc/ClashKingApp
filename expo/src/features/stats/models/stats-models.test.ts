import {
  StatsArmiesQuery,
  StatsArmiesResponse,
  StatsBattleFilters,
  StatsCwlQuery,
  StatsCwlResponse,
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

  it('clamps army result limits to the API range-specific maximum', () => {
    const oneDay = new Date(2026, 7, 1);
    expect(
      new StatsArmiesQuery(
        new StatsBattleFilters(new StatsDateFilter(oneDay, oneDay)),
        999,
      ).toQuery().limit,
    ).toBe(250);
    expect(new StatsArmiesQuery(new StatsBattleFilters(dates), 25).toQuery().limit).toBe(10);
    expect(new StatsArmiesQuery(new StatsBattleFilters(dates), 4).toQuery().limit).toBe(4);
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
    expect(response.items[0]).toMatchObject({
      troops: [],
      spells: [],
      sieges: [],
      equipmentPairs: [],
      petCombos: [],
    });
  });

  it('preserves the local daily metadata and top-100 cohort', () => {
    const metadata = {
      troops: [{ id: 4000000, uses: 8, triples: 4 }],
      spells: [{ id: 26000000, uses: 7, triples: 3 }],
      sieges: [{ id: 4000051, uses: 6, triples: 3 }],
      equipmentPairs: [
        { heroId: 28000000, equipmentIds: [90000000, 90000001], uses: 5, triples: 2 },
      ],
      petCombos: [{ petIds: [73000000, 73000001], uses: 4, triples: 2 }],
    };
    const response = StatsLegendResponse.fromJson({
      cohort: 'top_100',
      items: [
        {
          day: '2026-09-20',
          attacks: 10,
          players: 2,
          starCounts: { zero: 0, one: 1, two: 4, three: 5 },
          ...metadata,
        },
      ],
    });
    expect(response.cohort).toBe(StatsLegendCohort.top100);
    expect(response.items[0]).toMatchObject(metadata);
    expect(
      new StatsArmiesQuery(
        new StatsBattleFilters(dates),
        10,
        'usage',
        StatsLegendCohort.top100,
      ).toQuery().cohort,
    ).toBe('top_100');
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

  it('keeps ranked filters and selects CWL by season', () => {
    expect(new StatsRankedQuery(dates, 18, 1).toQuery()).toEqual({
      startDate: '2026-08-01',
      endDate: '2026-08-30',
      townHallLevel: 18,
      leagueTierId: 1,
    });
    expect(new StatsCwlQuery().toQuery()).toEqual({});
    expect(new StatsCwlQuery('2026-08').toQuery()).toEqual({ season: '2026-08' });
  });

  it('decodes CWL participation and preserves unavailable hit rates', () => {
    const value = StatsCwlResponse.fromJson({
      season: '2026-09', clanCount: 8, registeredPlayerCount: 180, groupCount: 1,
      availableSeasons: ['2026-09', '2026-08'],
      history: [{ season: '2026-09', clanCount: 8, registeredPlayerCount: 180, groupCount: 1 }],
      items: [{ leagueId: 48000022, warSize: 15, groupCount: 1, clanCount: 8,
        registeredPlayerCount: 180, townHallDistribution: [{ level: 18, count: 120 }],
        sameTownHallHitRates: null, finalizedWars: 7, archivedWars: 0,
        calculatedAt: '2026-09-22T12:00:00Z' }],
    });
    expect(value.items[0]).toMatchObject({
      leagueId: 48000022, registeredPlayerCount: 180, sameTownHallHitRates: null,
      archivedWars: 0, finalizedWars: 7,
    });
    expect(value.availableSeasons).toEqual(['2026-09', '2026-08']);
    expect(value.history).toEqual([{ season: '2026-09', clanCount: 8, registeredPlayerCount: 180, groupCount: 1 }]);
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
      cohort: 'legend_i',
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
