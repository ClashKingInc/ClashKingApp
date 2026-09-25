import {
  StatsArmiesResponse,
  StatsClanCountsResponse,
  StatsCwlResponse,
  StatsDateRange,
  StatsLegendCohort,
  StatsLegendDay,
  StatsLegendResponse,
  StatsTroopStatsResponse,
  StatsMetrics,
  StatsPerformanceResponse,
  StatsPlayerCountsResponse,
  StatsSection,
} from '../models';
import type { StatsRepositoryContract } from './stats-repository';
import { StatsLoadStatus, StatsProvider } from './stats-provider';

const range = new StatsDateRange(null, null);
const performance = (available = true) =>
  new StatsPerformanceResponse(range, new StatsMetrics(available, 1, 2, 3, 4, 5, 6, 7, []), []);

function repository(overrides: Partial<StatsRepositoryContract> = {}): StatsRepositoryContract {
  return {
    loadPlayerCounts: jest.fn(async () => new StatsPlayerCountsResponse([], [])),
    loadClanCounts: jest.fn(async () => new StatsClanCountsResponse([], [], [])),
    loadArmies: jest.fn(async () => new StatsArmiesResponse(range, [], 0)),
    loadArmySetups: jest.fn(async () => ({
      firstDay: '2026-09-15',
      lastDay: '2026-09-15',
      completedDays: ['2026-09-15'],
      totalAttacks: 10,
      classifiedAttacks: 9,
      leagueTierId: 105000036,
      rankLimit: null,
      items: [],
    })),
    loadArmySetupTimeline: jest.fn(),
    loadItems: jest.fn(async () => new StatsLegendResponse(StatsLegendCohort.legend, [])),
    loadRanked: jest.fn(async () => performance()),
    loadWar: jest.fn(async () => performance()),
    loadCwl: jest.fn(async () => new StatsCwlResponse('2026-08', 0, 0, 0, [])),
    ...overrides,
  };
}

const settle = async () => {
  await Promise.resolve();
  await Promise.resolve();
};

describe('StatsProvider state and query coverage', () => {
  it('notifies subscribers, suppresses duplicate selections, and stops after unsubscribe/dispose', async () => {
    const provider = new StatsProvider(repository());
    const listener = jest.fn();
    const unsubscribe = provider.subscribe(listener);

    provider.selectSection(StatsSection.ranked);
    expect(listener).toHaveBeenCalledTimes(2);
    listener.mockClear();
    provider.selectSection(StatsSection.ranked);
    expect(listener).not.toHaveBeenCalled();
    provider.selectSection(StatsSection.players);
    await settle();
    expect(listener).toHaveBeenCalled();

    unsubscribe();
    listener.mockClear();
    provider.selectSection(StatsSection.clans);
    await settle();
    expect(listener).not.toHaveBeenCalled();
    provider.dispose();
  });

  it('updates every filter family and sends the resulting query to its repository method', async () => {
    const repo = repository();
    const provider = new StatsProvider(repo);

    provider.updateArmySetupFilters({ rankLimit: 200, sort: 'tripleRate' });
    await provider.load(StatsSection.armies);
    const armies = (repo.loadArmySetups as jest.Mock).mock.calls[0]![0];
    expect(armies).toMatchObject({
      leagueTierId: 105000036,
      rankLimit: 200,
      sort: 'tripleRate',
    });
    expect(armies['time[after]']).toMatch(/^\d{4}-\d{2}-\d{2}$/u);

    provider.updateArmySetupFilters({ rankLimit: null });
    expect(provider.armyRankLimit).toBeUndefined();

    provider.updateWarFilters({ townHall: 16, opponentTownHall: 17, equalTownHalls: false });
    await provider.load(StatsSection.war);
    expect((repo.loadWar as jest.Mock).mock.calls[0]![0]).toMatchObject({
      townHallLevel: 16,
      opponentTownHallLevel: 17,
      equalTownHalls: false,
    });

    provider.setCwlSeason('2026-08');
    await provider.load(StatsSection.cwl);
    expect((repo.loadCwl as jest.Mock).mock.calls[0]![0]).toMatchObject({
      season: '2026-08',
    });

    provider.updateRankedFilters({ townHall: 16, leagueTier: 3 });
    await provider.load(StatsSection.ranked);
    expect((repo.loadItems as jest.Mock).mock.calls[0]![0]).toMatchObject({
      cohort: StatsLegendCohort.legend,
    });
    expect(repo.loadRanked).not.toHaveBeenCalled();
  });

  it('keeps Troop Stats on Legend League 1 after legacy cohort state changes', async () => {
    const repo = repository({
      loadItems: jest.fn(
        async () =>
          new StatsLegendResponse(StatsLegendCohort.top200, [
            new StatsLegendDay('2026-08-01', 10, 2, [0, 1, 4, 5], 90, 95, [], [], [], []),
          ]),
      ),
    });
    const provider = new StatsProvider(repo);

    await provider.load(StatsSection.items);
    expect(provider.stateFor(StatsSection.items).status).toBe(StatsLoadStatus.data);
    expect((repo.loadItems as jest.Mock).mock.calls[0]![0]).toMatchObject({
      cohort: StatsLegendCohort.legend,
    });
    provider.updateLegendCohort(StatsLegendCohort.top200);
    await provider.load(StatsSection.items);
    expect(
      (repo.loadItems as jest.Mock).mock.calls.slice(0, 3).map((call) => call[0].cohort),
    ).toEqual([StatsLegendCohort.legend, StatsLegendCohort.top1000, StatsLegendCohort.top200]);
    expect(
      (repo.loadItems as jest.Mock).mock.calls.slice(3, 6).map((call) => call[0].cohort),
    ).toEqual([StatsLegendCohort.legend, StatsLegendCohort.top1000, StatsLegendCohort.top200]);
  });

  it('keeps Legend item data when a comparison cohort fails, but fails when Legend data fails', async () => {
    const legend = new StatsLegendResponse(StatsLegendCohort.legend, [
      new StatsLegendDay('2026-08-01', 10, 2, [0, 1, 4, 5], 90, 95, [], [], [], []),
    ]);
    const repo = repository({
      loadItems: jest.fn(async (query) => {
        if (query.cohort === StatsLegendCohort.top1000) throw new Error('Top 1000 unavailable');
        return legend;
      }),
    });
    const provider = new StatsProvider(repo);
    await provider.load(StatsSection.items);
    const state = provider.stateFor(StatsSection.items);
    expect(state.status).toBe(StatsLoadStatus.data);
    expect(state.data).toBeInstanceOf(StatsTroopStatsResponse);
    expect(state.data).toMatchObject({ legend, top1000: null, top200: legend });

    const failure = new StatsProvider(
      repository({
        loadItems: jest.fn(async (query) => {
          if (query.cohort === StatsLegendCohort.legend) throw new Error('Legend unavailable');
          return legend;
        }),
      }),
    );
    await failure.load(StatsSection.items);
    expect(failure.stateFor(StatsSection.items).status).toBe(StatsLoadStatus.error);
  });

  it('classifies empty response models and preserves cached data across refresh failures', async () => {
    const loadItems = jest
      .fn()
      .mockResolvedValueOnce(
        new StatsLegendResponse(StatsLegendCohort.legend, [
          new StatsLegendDay('2026-08-30', 10, 2, [0, 1, 4, 5], 90, 95, [], [], [], []),
        ]),
      )
      .mockRejectedValueOnce('offline');
    const repo = repository({ loadItems });
    const provider = new StatsProvider(repo, () => new Date('2026-08-30T12:00:00Z'));

    provider.selectSection(StatsSection.ranked);
    await settle();
    await provider.refresh();
    expect(provider.currentState).toMatchObject({
      status: StatsLoadStatus.data,
      error: 'offline',
      isRefreshing: false,
    });
    expect(provider.currentState.data).toBeDefined();

    await new StatsProvider(repository()).load(StatsSection.players);
    const emptyPlayers = new StatsProvider(repository());
    await emptyPlayers.load(StatsSection.players);
    expect(emptyPlayers.stateFor(StatsSection.players).status).toBe(StatsLoadStatus.empty);
    const emptyClans = new StatsProvider(repository());
    await emptyClans.load(StatsSection.clans);
    expect(emptyClans.stateFor(StatsSection.clans).status).toBe(StatsLoadStatus.empty);
    const emptyWar = new StatsProvider(
      repository({ loadWar: jest.fn(async () => performance(false)) }),
    );
    await emptyWar.load(StatsSection.war);
    expect(emptyWar.stateFor(StatsSection.war).status).toBe(StatsLoadStatus.empty);
  });

  it('preserves an unrelated request across a date change and reports first-load errors', async () => {
    let resolvePlayers!: (value: StatsPlayerCountsResponse) => void;
    const pendingPlayers = new Promise<StatsPlayerCountsResponse>((resolve) => {
      resolvePlayers = resolve;
    });
    const provider = new StatsProvider(
      repository({
        loadPlayerCounts: jest.fn(() => pendingPlayers),
        loadRanked: jest.fn(async () => performance()),
      }),
    );
    const pending = provider.load(StatsSection.players);
    await provider.setDates(new Date('2026-08-01'), new Date('2026-08-02'));
    resolvePlayers(new StatsPlayerCountsResponse([{ townHall: 17, count: 1 }] as never, []));
    await pending;
    expect(provider.stateFor(StatsSection.players).status).toBe(StatsLoadStatus.data);

    const failed = new StatsProvider(
      repository({ loadPlayerCounts: jest.fn(async () => Promise.reject(new Error('boom'))) }),
    );
    await failed.load(StatsSection.players);
    expect(failed.stateFor(StatsSection.players)).toMatchObject({
      status: StatsLoadStatus.error,
      isRefreshing: false,
    });
  });
});
