import {
  StatsArmiesResponse,
  StatsClanCountsResponse,
  StatsDateRange,
  StatsItemSelector,
  StatsItemType,
  StatsItemQuantityFilter,
  StatsItemsResponse,
  StatsMetrics,
  StatsGlobalCounts,
  StatsOverviewResponse,
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
    loadOverview: jest.fn(
      async () =>
        new StatsOverviewResponse(
          range,
          new StatsGlobalCounts(0, 0, 0, 0, 0, 0, 0),
          performance().metrics,
          performance().metrics,
          performance().metrics,
        ),
    ),
    loadPlayerCounts: jest.fn(async () => new StatsPlayerCountsResponse([], [], [])),
    loadClanCounts: jest.fn(async () => new StatsClanCountsResponse([], [], [])),
    loadArmies: jest.fn(async () => new StatsArmiesResponse(range, [], 0)),
    loadItems: jest.fn(async () => new StatsItemsResponse(range, [], 0)),
    loadRanked: jest.fn(async () => performance()),
    loadWar: jest.fn(async () => performance()),
    loadCwl: jest.fn(async () => performance()),
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

    provider.updateArmiesFilters({
      townHall: 17,
      leagueTier: 2,
      minimumSample: 50,
      limit: 10,
      sortBy: 'win_rate',
      include: [new StatsItemQuantityFilter('Wizard', 2)],
      exclude: ['Wizard'],
    });
    await provider.load(StatsSection.armies);
    const armies = (repo.loadArmies as jest.Mock).mock.calls[0]![0];
    expect(armies).toMatchObject({ limit: 10, sortBy: 'win_rate' });
    expect(armies.filters).toMatchObject({
      townHallLevel: 17,
      rankedLeagueTierId: 2,
      minimumSampleSize: 50,
    });

    provider.updateArmiesFilters({ townHall: null, leagueTier: null });
    expect(provider.armiesTownHall).toBeUndefined();
    expect(provider.armiesLeagueTier).toBeUndefined();

    provider.updateWarFilters({ townHall: 16, opponentTownHall: 17, equalTownHalls: false });
    await provider.load(StatsSection.war);
    expect((repo.loadWar as jest.Mock).mock.calls[0]![0]).toMatchObject({
      townHallLevel: 16,
      opponentTownHallLevel: 17,
      equalTownHalls: false,
    });

    provider.updateCwlFilters({
      townHall: 15,
      opponentTownHall: 16,
      equalTownHalls: false,
      leagueId: 48000010,
      seasons: ['2026-08'],
    });
    await provider.load(StatsSection.cwl);
    expect((repo.loadCwl as jest.Mock).mock.calls[0]![0]).toMatchObject({
      townHallLevel: 15,
      opponentTownHallLevel: 16,
      equalTownHalls: false,
      cwlLeagueId: 48000010,
      seasons: ['2026-08'],
    });

    provider.updateRankedFilters({ townHall: 16, leagueTier: 3 });
    await provider.load(StatsSection.ranked);
    expect((repo.loadRanked as jest.Mock).mock.calls[0]![0]).toMatchObject({
      townHallLevel: 16,
      rankedLeagueTierId: 3,
    });
  });

  it('keeps items empty without selectors, filters invalid selectors, and loads valid items', async () => {
    const repo = repository({
      loadItems: jest.fn(async () => new StatsItemsResponse(range, [{ id: 1 }] as never, 1)),
    });
    const provider = new StatsProvider(repo);

    await provider.load(StatsSection.items);
    expect(provider.stateFor(StatsSection.items).status).toBe(StatsLoadStatus.empty);
    expect(repo.loadItems).not.toHaveBeenCalled();

    const invalid = new StatsItemSelector('', StatsItemType.troop);
    const valid = new StatsItemSelector('Wizard', StatsItemType.troop);
    provider.setItemSelectors([invalid, valid]);
    provider.updateItemFilters({ townHall: 17, leagueTier: 1 });
    await provider.load(StatsSection.items);
    expect(provider.itemSelectors).toEqual([valid]);
    expect((repo.loadItems as jest.Mock).mock.calls[0]![0]).toMatchObject({ items: [valid] });
    expect(provider.stateFor(StatsSection.items).status).toBe(StatsLoadStatus.data);

    provider.updateItemFilters({ townHall: null, leagueTier: null });
    expect(provider.itemsTownHall).toBeUndefined();
    expect(provider.itemsLeagueTier).toBeUndefined();
  });

  it('classifies empty response models and preserves cached data across refresh failures', async () => {
    const loadRanked = jest
      .fn()
      .mockResolvedValueOnce(performance())
      .mockRejectedValueOnce('offline');
    const repo = repository({ loadRanked });
    const provider = new StatsProvider(repo, () => new Date('2026-08-30T12:00:00Z'));

    await provider.load(StatsSection.ranked);
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

  it('ignores a request invalidated by a date change and reports first-load errors', async () => {
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
    resolvePlayers(new StatsPlayerCountsResponse([{ townHall: 17, count: 1 }] as never, [], []));
    await pending;
    expect(provider.stateFor(StatsSection.players).status).toBe(StatsLoadStatus.idle);

    const failed = new StatsProvider(
      repository({ loadOverview: jest.fn(async () => Promise.reject(new Error('boom'))) }),
    );
    await failed.load(StatsSection.overview);
    expect(failed.stateFor(StatsSection.overview)).toMatchObject({
      status: StatsLoadStatus.error,
      isRefreshing: false,
    });
  });
});
