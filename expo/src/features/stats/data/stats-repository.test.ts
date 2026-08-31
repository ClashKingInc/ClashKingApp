import type { ApiClient } from '../../../core/api/client';
import { StatsDateFilter, StatsRankedQuery } from '../models';
import { StatsRepository } from './stats-repository';

describe('StatsRepository', () => {
  it('uses the exact public overview/count routes', async () => {
    const requestRecord = jest.fn(async () => ({ items: [] }));
    const repo = new StatsRepository({ requestRecord } as unknown as ApiClient);
    await repo.loadPlayerCounts();
    const calls = requestRecord.mock.calls as unknown as [string, { requiresAuth?: boolean }][];
    expect(calls.map(([path]) => path)).toEqual([
      '/counts/players/town-halls',
      '/counts/players/builder-halls',
      '/counts/players/league-tiers',
    ]);
    expect(calls.every(([, options]) => options.requiresAuth === false)).toBe(true);
  });

  it('preserves RFC QUERY for battle stats rather than inventing POST aliases', async () => {
    const requestRecord = jest.fn(async () => ({ metrics: {}, breakdowns: [] }));
    const repo = new StatsRepository({ requestRecord } as unknown as ApiClient);
    const dates = new StatsDateFilter(new Date(2026, 7, 1), new Date(2026, 7, 30));
    await repo.loadRanked(new StatsRankedQuery(dates, 18, 1));
    expect(requestRecord).toHaveBeenCalledWith('/stats/ranked', {
      method: 'QUERY',
      requiresAuth: false,
      body: {
        dates: { start_date: '2026-08-01', end_date: '2026-08-30' },
        townhall_level: 18,
        ranked_league_tier_id: 1,
      },
    });
  });
});
