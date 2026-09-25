import {
  StatsArmiesResponse,
  StatsAudience,
  StatsCwlResponse,
  StatsDateRange,
  StatsDateFilter,
  StatsLegendCohort,
  StatsLegendDay,
  StatsLegendResponse,
  StatsLegendQuery,
  StatsMetrics,
  StatsPerformanceResponse,
  StatsPlayerCountsResponse,
  StatsSection,
} from '../models';
import { StatsLoadStatus, StatsProvider } from './stats-provider';
import type { StatsRepositoryContract } from './stats-repository';

const performance = new StatsPerformanceResponse(
  new StatsDateRange(null, null),
  new StatsMetrics(true, 100, 2, 80, 1, 9, 50, 40, []),
  [],
);

function repository(overrides: Partial<StatsRepositoryContract> = {}): StatsRepositoryContract {
  return {
    loadPlayerCounts: jest.fn(async () => new StatsPlayerCountsResponse([], [])),
    loadClanCounts: jest.fn(),
    loadArmies: jest.fn(async () => new StatsArmiesResponse(new StatsDateRange(null, null), [], 0)),
    loadArmySetups: jest.fn(),
    loadArmySetupTimeline: jest.fn(),
    loadItems: jest.fn(async () => new StatsLegendResponse(StatsLegendCohort.legend, [])),
    loadRanked: jest.fn(async () => performance),
    loadWar: jest.fn(async () => performance),
    loadCwl: jest.fn(
      async () =>
        new StatsCwlResponse('2026-09', 8, 180, 1, [
          {
            leagueId: 48000022,
            warSize: 15,
            groupCount: 1,
            clanCount: 8,
            registeredPlayerCount: 180,
            townHallDistribution: [],
            sameTownHallHitRates: null,
            finalizedWars: 0,
            archivedWars: 0,
            calculatedAt: '2026-09-22T00:00:00Z',
          },
        ]),
    ),
    ...overrides,
  };
}

describe('StatsProvider', () => {
  it('starts on the 90-day War view and loads lazily', async () => {
    const repo = repository();
    const provider = new StatsProvider(repo, () => new Date(2026, 7, 30, 15));
    expect(provider.dates.inclusiveDays).toBe(90);
    provider.ensureLoaded();
    await Promise.resolve();
    await Promise.resolve();
    expect(provider.section).toBe(StatsSection.war);
    expect(repo.loadWar).toHaveBeenCalledTimes(1);
    expect(provider.currentState.status).toBe(StatsLoadStatus.data);
  });

  it('keeps loaded data for an hour and then refreshes the selected section', async () => {
    let now = new Date(2026, 7, 30, 15);
    const repo = repository();
    const provider = new StatsProvider(repo, () => now);
    await provider.load(StatsSection.ranked);
    now = new Date(2026, 7, 30, 15, 59);
    provider.ensureLoaded();
    expect(repo.loadItems).toHaveBeenCalledTimes(1);
    now = new Date(2026, 7, 30, 16);
    await provider.load(StatsSection.ranked);
    expect(repo.loadItems).toHaveBeenCalledTimes(2);
    expect((repo.loadItems as jest.Mock).mock.calls[0][0].toQuery()).toMatchObject({
      cohort: 'legend_i',
    });
  });

  it('caches Army results by exact cohort and sort without showing the prior cohort while loading', async () => {
    const all = {
      firstDay: '2026-09-15',
      lastDay: '2026-09-15',
      completedDays: ['2026-09-15'],
      totalAttacks: 10,
      classifiedAttacks: 10,
      leagueTierId: 105000036,
      rankLimit: null,
      items: [{ groupKey: 'all' }],
    };
    const top200 = { ...all, rankLimit: 200, items: [{ groupKey: 'top200' }] };
    let resolveTop200!: (value: typeof top200) => void;
    const pendingTop200 = new Promise<typeof top200>((resolve) => {
      resolveTop200 = resolve;
    });
    const loadArmySetups = jest
      .fn()
      .mockResolvedValue(all)
      .mockResolvedValueOnce(all)
      .mockReturnValueOnce(pendingTop200);
    const provider = new StatsProvider(repository({ loadArmySetups }));
    await provider.load(StatsSection.armies);
    expect(provider.stateFor(StatsSection.armies).data).toBe(all);

    provider.updateArmySetupFilters({ rankLimit: 200 });
    expect(provider.stateFor(StatsSection.armies).status).toBe(StatsLoadStatus.loading);
    expect(provider.stateFor(StatsSection.armies).data).toBeUndefined();
    resolveTop200(top200);
    await pendingTop200;
    await Promise.resolve();
    expect(provider.stateFor(StatsSection.armies).data).toBe(top200);

    provider.updateArmySetupFilters({ rankLimit: null });
    expect(provider.stateFor(StatsSection.armies).data).toBe(all);
    expect(loadArmySetups).toHaveBeenCalledTimes(2);
    provider.updateArmySetupFilters({ rankLimit: null });
    expect(loadArmySetups).toHaveBeenCalledTimes(2);

    await provider.load(StatsSection.armies, true);
    expect(loadArmySetups).toHaveBeenCalledTimes(3);
    provider.updateArmySetupFilters({ sort: 'tripleRate' });
    expect(provider.stateFor(StatsSection.armies).data).toBeUndefined();
    await Promise.resolve();
    expect(loadArmySetups).toHaveBeenCalledTimes(4);
    provider.updateArmySetupFilters({ sort: 'usage' });
    expect(provider.stateFor(StatsSection.armies).data).toBe(all);
    expect(loadArmySetups).toHaveBeenCalledTimes(4);

    provider.selectSection(StatsSection.armies);
    await provider.setDates(new Date(2026, 6, 1), new Date(2026, 7, 29));
    expect(loadArmySetups).toHaveBeenCalledTimes(5);
    expect((loadArmySetups as jest.Mock).mock.calls[4]![0]['time[before]']).toBe('2026-08-29');
  });

  it('loads the latest CWL season and accepts an explicit retained season', async () => {
    const repo = repository();
    const provider = new StatsProvider(repo, () => new Date(2026, 8, 22));
    await provider.load(StatsSection.cwl);
    const first = (repo.loadCwl as jest.Mock).mock.calls[0][0];
    expect(first.toQuery()).toEqual({});

    provider.setCwlSeason('2026-08');
    await Promise.resolve();
    const second = (repo.loadCwl as jest.Mock).mock.calls.at(-1)[0];
    expect(second.toQuery()).toEqual({ season: '2026-08' });
  });

  it('publishes a stable external-store snapshot that advances for every visible mutation', () => {
    const provider = new StatsProvider(repository());
    const initial = provider.getSnapshot();
    expect(provider.getSnapshot()).toBe(initial);

    provider.updateRankedFilters({ townHall: 17, leagueTier: 2 });
    expect(provider.getSnapshot()).toBeGreaterThan(initial);
    const filtered = provider.getSnapshot();

    provider.selectAudience(StatsAudience.world);
    expect(provider.getSnapshot()).toBeGreaterThan(filtered);
  });

  it('restarts a loading request after an effect cleanup disposes the provider', async () => {
    const loadWar = jest
      .fn()
      .mockReturnValueOnce(new Promise<never>(() => undefined))
      .mockResolvedValueOnce(performance);
    const provider = new StatsProvider(repository({ loadWar }));

    provider.ensureLoaded();
    expect(provider.currentState.status).toBe(StatsLoadStatus.loading);
    provider.dispose();
    expect(provider.currentState.status).toBe(StatsLoadStatus.idle);

    provider.ensureLoaded();
    await Promise.resolve();
    await Promise.resolve();
    expect(loadWar).toHaveBeenCalledTimes(2);
    expect(provider.currentState.status).toBe(StatsLoadStatus.data);
  });

  it('switches audience to player counts and retains section caches', async () => {
    const repo = repository();
    const provider = new StatsProvider(repo);
    provider.selectAudience(StatsAudience.world);
    await Promise.resolve();
    await Promise.resolve();
    expect(provider.section).toBe(StatsSection.players);
    expect(repo.loadPlayerCounts).toHaveBeenCalledTimes(1);
    provider.selectAudience(StatsAudience.battle);
    expect(provider.section).toBe(StatsSection.war);
  });

  it('switches between Battle and World with one section selector', () => {
    const provider = new StatsProvider(repository());
    provider.selectSection(StatsSection.players);
    expect(provider.audience).toBe(StatsAudience.world);
    provider.selectSection(StatsSection.war);
    expect(provider.audience).toBe(StatsAudience.battle);
  });

  it('rejects invalid ranges and applies valid ranges only to the current page', async () => {
    const provider = new StatsProvider(repository());
    await expect(provider.setDates(new Date(2026, 0, 1), new Date(2026, 4, 1))).rejects.toThrow(
      '1 to 90 days',
    );
    await provider.setDates(new Date(2026, 7, 1), new Date(2026, 7, 3));
    expect(provider.dates.inclusiveDays).toBe(3);
  });

  it('keeps War, Ranked, Troop and Army date ranges independent and preserves other caches', async () => {
    const repo = repository();
    const provider = new StatsProvider(repo, () => new Date(2026, 8, 22, 12));
    await provider.load(StatsSection.war);
    provider.section = StatsSection.ranked;
    await provider.setDates(new Date(2026, 6, 1), new Date(2026, 6, 7));
    await provider.load(StatsSection.ranked);
    await provider.load(StatsSection.items);
    const war = (repo.loadWar as jest.Mock).mock.calls.at(-1)[0] as { dates: StatsDateFilter };
    const ranked = (repo.loadItems as jest.Mock).mock.calls[0][0] as StatsLegendQuery;
    const items = (repo.loadItems as jest.Mock).mock.calls[1][0] as StatsLegendQuery;
    expect(war.dates.inclusiveDays).toBe(90);
    expect(ranked.dates.inclusiveDays).toBe(7);
    expect(items.dates.inclusiveDays).toBe(90);
    expect(provider.datesFor(StatsSection.armies).inclusiveDays).toBe(90);
    expect(ranked.toQuery().cohort).toBe(StatsLegendCohort.legend);
    provider.section = StatsSection.items;
    await provider.setDates(new Date(2026, 6, 1), new Date(2026, 6, 30));
    expect(provider.dates.inclusiveDays).toBe(30);
    expect(provider.datesFor(StatsSection.ranked).inclusiveDays).toBe(7);
    const calls = (repo.loadItems as jest.Mock).mock.calls.length;
    await provider.load(StatsSection.ranked);
    await provider.load(StatsSection.war);
    expect(repo.loadItems).toHaveBeenCalledTimes(calls);
    expect(repo.loadWar).toHaveBeenCalledTimes(1);
  });

  it('rejects invalid Date objects before clearing data or requesting stats', async () => {
    const repo = repository();
    const provider = new StatsProvider(repo);
    await expect(provider.setDates(new Date('bad'), new Date())).rejects.toThrow(RangeError);
    await expect(provider.setWarDates(new Date(), new Date('bad'))).rejects.toThrow(RangeError);
    expect(repo.loadWar).not.toHaveBeenCalled();
  });

  it('allows all-time War without expanding ranked or troop windows', async () => {
    const repo = repository();
    const provider = new StatsProvider(repo, () => new Date(2026, 8, 22, 12));
    await provider.setWarDates(new Date(2012, 7, 2), new Date(2026, 8, 22));
    expect(provider.warDates.inclusiveDays).toBeGreaterThan(365);
    expect(provider.dates.inclusiveDays).toBe(90);
    const query = (repo.loadWar as jest.Mock).mock.calls.at(-1)[0] as { dates: StatsDateFilter };
    expect(query.dates.start).toEqual(new Date(2012, 7, 2));
    await expect(provider.setDates(new Date(2025, 8, 22), new Date(2026, 8, 22))).rejects.toThrow(
      '90',
    );
  });

  it('suppresses stale responses using per-section request versions', async () => {
    let firstResolve!: (value: StatsLegendResponse) => void;
    const first = new Promise<StatsLegendResponse>((resolve) => (firstResolve = resolve));
    const day = (attacks: number) =>
      new StatsLegendDay('2026-08-30', attacks, 20, [0, 0, 0, attacks], 120, 100, [], [], [], []);
    const second = new StatsLegendResponse(StatsLegendCohort.legend, [day(200)]);
    const loadItems = jest.fn().mockReturnValueOnce(first).mockResolvedValueOnce(second);
    const provider = new StatsProvider(repository({ loadItems }));
    const pending = provider.load(StatsSection.ranked);
    await provider.load(StatsSection.ranked, true);
    firstResolve(new StatsLegendResponse(StatsLegendCohort.legend, [day(100)]));
    await pending;
    expect(
      (provider.stateFor(StatsSection.ranked).data as StatsLegendResponse).items[0]?.attacks,
    ).toBe(200);
  });
});
