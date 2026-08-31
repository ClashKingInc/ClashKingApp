import {
  StatsArmiesResponse,
  StatsAudience,
  StatsDateRange,
  StatsMetrics,
  StatsOverviewResponse,
  StatsPerformanceResponse,
  StatsSection,
} from '../models';
import { StatsLoadStatus, StatsProvider } from './stats-provider';
import type { StatsRepositoryContract } from './stats-repository';

const emptyMetrics = new StatsMetrics(false, 0, 0, 0, 0, 0, 0, 0, []);
const performance = new StatsPerformanceResponse(
  new StatsDateRange(null, null),
  new StatsMetrics(true, 100, 2, 80, 1, 9, 50, 40, []),
  [],
);

function repository(overrides: Partial<StatsRepositoryContract> = {}): StatsRepositoryContract {
  return {
    loadOverview: jest.fn(
      async () =>
        new StatsOverviewResponse(
          new StatsDateRange(null, null),
          {} as never,
          emptyMetrics,
          emptyMetrics,
          emptyMetrics,
        ),
    ),
    loadPlayerCounts: jest.fn(),
    loadClanCounts: jest.fn(),
    loadArmies: jest.fn(async () => new StatsArmiesResponse(new StatsDateRange(null, null), [], 0)),
    loadItems: jest.fn(),
    loadRanked: jest.fn(async () => performance),
    loadWar: jest.fn(async () => performance),
    loadCwl: jest.fn(async () => performance),
    ...overrides,
  };
}

describe('StatsProvider', () => {
  it('starts on the 30-day ranked battle view and loads lazily', async () => {
    const repo = repository();
    const provider = new StatsProvider(repo, () => new Date(2026, 7, 30, 15));
    expect(provider.dates.inclusiveDays).toBe(30);
    provider.ensureLoaded();
    await Promise.resolve();
    await Promise.resolve();
    expect(repo.loadRanked).toHaveBeenCalledTimes(1);
    expect(provider.currentState.status).toBe(StatsLoadStatus.data);
  });

  it('switches audience to overview and retains section caches', async () => {
    const repo = repository();
    const provider = new StatsProvider(repo);
    provider.selectAudience(StatsAudience.world);
    await Promise.resolve();
    await Promise.resolve();
    expect(provider.section).toBe(StatsSection.overview);
    expect(repo.loadOverview).toHaveBeenCalledTimes(1);
    provider.selectAudience(StatsAudience.battle);
    expect(provider.section).toBe(StatsSection.ranked);
  });

  it('rejects invalid ranges and invalidates every section for valid ranges', async () => {
    const provider = new StatsProvider(repository());
    await expect(provider.setDates(new Date(2026, 0, 1), new Date(2026, 4, 1))).rejects.toThrow(
      '1 to 90 days',
    );
    await provider.setDates(new Date(2026, 7, 1), new Date(2026, 7, 3));
    expect(provider.dates.inclusiveDays).toBe(3);
  });

  it('suppresses stale responses using per-section request versions', async () => {
    let firstResolve!: (value: StatsPerformanceResponse) => void;
    const first = new Promise<StatsPerformanceResponse>((resolve) => (firstResolve = resolve));
    const second = new StatsPerformanceResponse(
      new StatsDateRange(null, null),
      new StatsMetrics(true, 200, 2, 80, 1, 9, 50, 40, []),
      [],
    );
    const loadRanked = jest.fn().mockReturnValueOnce(first).mockResolvedValueOnce(second);
    const provider = new StatsProvider(repository({ loadRanked }));
    const pending = provider.load(StatsSection.ranked);
    await provider.load(StatsSection.ranked, true);
    firstResolve(performance);
    await pending;
    expect((provider.currentState.data as StatsPerformanceResponse).metrics.sampleSize).toBe(200);
  });
});
