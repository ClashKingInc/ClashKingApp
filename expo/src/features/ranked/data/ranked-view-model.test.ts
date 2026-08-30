import {
  PlayerLegendSeason,
  RankedLeagueBattle,
  RankedLeagueData,
  RankedLeagueGroup,
  RankedLeagueHistoryEntry,
  RankedLeagueMember,
  RankedLeagueTier,
} from '../../player/models';
import {
  legendHistorySeries,
  legendSeasonSeries,
  rankedBattleSummary,
  rankedHistoricalPeriods,
  rankedHistorySeries,
  rankedPeriods,
  rankedTierHighlights,
} from './ranked-view-model';

describe('Ranked and Legend view models', () => {
  const gold = new RankedLeagueTier(2, 'Gold', 'small', 'large');
  const silver = new RankedLeagueTier(1, 'Silver', 'small', 'large');
  const currentMember = new RankedLeagueMember('#P', 'Player', '#C', 'Clan', 1200, 2, 1, 1, 2);
  const attack = new RankedLeagueBattle('#A', 'A', 3, 100, 40, new Date('2026-08-25T12:00:00Z'));
  const defense = new RankedLeagueBattle('#D', 'D', 2, 80, 20, new Date('2026-08-26T12:00:00Z'));
  const currentGroup = new RankedLeagueGroup(
    '#G',
    1_777_000_000,
    [currentMember],
    [attack],
    [defense],
  );
  const history = [
    new RankedLeagueHistoryEntry(1_776_000_000, 1180, 2, 2, 4, 1, 10, 3, 2, 8, 14),
    new RankedLeagueHistoryEntry(1_775_000_000, 900, 1, 0, 2, 2, 5, 1, 3, 4, 14),
  ];
  const data = new RankedLeagueData(
    '#P',
    'Player',
    18,
    1200,
    1300,
    gold,
    new Map([
      [1, silver],
      [2, gold],
    ]),
    history,
    currentGroup,
  );

  test('builds the live period from group logs and historical periods from official summaries', () => {
    const periods = rankedPeriods(data);
    expect(periods).toHaveLength(3);
    expect(periods[0]).toMatchObject({
      isCurrent: true,
      attackCount: 1,
      defenseCount: 1,
      attackStars: 3,
      defenseStars: 2,
      placement: 1,
      hasDetails: true,
    });
    expect(periods[1]).toMatchObject({
      isCurrent: false,
      attackCount: 5,
      defenseCount: 5,
      hasDetails: false,
    });
  });

  test('groups official history by tier and selects each Flutter highlight independently', () => {
    const highlights = rankedTierHighlights(rankedHistoricalPeriods(rankedPeriods(data)));
    expect(highlights.map((item) => item.tier?.id)).toEqual([2, 1]);
    expect(highlights[0]).toMatchObject({
      lastPeriod: { seasonId: 1_776_000_000 },
      bestRankPeriod: { placement: 2 },
      bestTrophiesPeriod: { trophies: 1180 },
      mostAttacksPeriod: { attackCount: 5 },
    });
    expect(highlights[1]?.bestRankPeriod).toBeNull();
  });

  test('uses battle trophy deltas rather than star totals for the offense and defense summary', () => {
    const second = new RankedLeagueBattle('#B', 'B', 1, 40, 20, null);
    expect(rankedBattleSummary([attack, second], 2, 14)).toEqual({
      trophyTotal: 60,
      trophyAverage: 30,
      remaining: 12,
    });
    expect(rankedBattleSummary([], 0, 0)).toEqual({
      trophyTotal: 0,
      trophyAverage: null,
      remaining: null,
    });
  });

  test('sorts ranked trophy history chronologically', () => {
    expect(rankedHistorySeries(rankedPeriods(data)).map((point) => point.y)).toEqual([
      900, 1180, 1200,
    ]);
  });

  test('finds the current member when API tag formatting differs', () => {
    const normalizedData = new RankedLeagueData(
      ' p ',
      'Player',
      18,
      1200,
      1300,
      gold,
      new Map([[2, gold]]),
      history,
      currentGroup,
    );

    expect(normalizedData.currentMember).toBe(currentMember);
    expect(normalizedData.currentRank).toBe(1);
    expect(rankedPeriods(normalizedData)[0]).toMatchObject({ trophies: 1200, placement: 1 });
  });

  test('splits Legend season chart lines when calendar days have a gap', () => {
    const season = {
      start: new Date('2026-08-01T00:00:00Z'),
      days: {
        '2026-08-01': { endTrophies: 5100 },
        '2026-08-02': { endTrophies: 5120 },
        '2026-08-04': { endTrophies: 5150 },
      },
    } as unknown as PlayerLegendSeason;
    expect(legendSeasonSeries(season).map((line) => line.map((point) => point.y))).toEqual([
      [5100, 5120],
      [5150],
    ]);
  });

  test('normalizes and sorts end-of-season rankings', () => {
    const series = legendHistorySeries([
      { season: '2026-08', trophies: 5200 },
      { season: '2026-07', trophies: 5100 },
    ] as never);
    expect(series.map((point) => point.y)).toEqual([5100, 5200]);
    expect(series[0]?.label).toBe('2026-07');
  });
});
