import { AchievementsCheckEndpoint } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../../core/api/contract-api';
import { AchievementsRepository } from './achievements-repository';

const response = {
  items: [
    {
      id: 'townhall_18',
      asset_url: 'https://assets.clashk.ing/achievements/town-hall-18-achievement-badge.glb',
      repeatable: true,
      earned_count: 3,
    },
    {
      id: 'war_warrior',
      asset_url: 'https://assets.clashk.ing/achievements/war-champion-achievement-badge.glb',
      repeatable: true,
      earned_count: 1,
    },
    {
      id: 'mr_legend',
      asset_url: 'https://assets.clashk.ing/achievements/perfect-legends-day-achievement-badge.glb',
      repeatable: true,
      earned_count: 0,
    },
    {
      id: 'defense_doesnt_matter',
      asset_url: 'https://assets.clashk.ing/achievements/bad-legends-achievement-badge.glb',
      repeatable: true,
      earned_count: -4,
    },
  ],
};

function setup(result: Record<string, unknown> | Promise<Record<string, unknown>> = response) {
  const execute = jest.fn(() => Effect.promise(() => Promise.resolve(result))) as unknown as
    jest.MockedFunction<ContractApiService['execute']>;
  const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
  return {
    execute,
    repository: new AchievementsRepository({ execute, executeStatus }),
  };
}

test('does not expose fallback entries before an authenticated response', () => {
  expect(setup().repository.snapshot.achievements).toEqual([]);
});

test('check posts an empty body with auth and maps server state in catalog order', async () => {
  const { repository, execute } = setup();
  await repository.check();
  expect(execute).toHaveBeenCalledWith(AchievementsCheckEndpoint, {
    path: {}, query: {}, body: {},
  });
  expect(repository.snapshot.achievements.map((item) => [item.id, item.earnedCount])).toEqual([
    ['townhall_18', 3],
    ['war_warrior', 1],
    ['mr_legend', 0],
    ['defense_doesnt_matter', 0],
  ]);
  expect(repository.snapshot.isRefreshing).toBe(false);
});

test('load uses the only deployed catalog response', async () => {
  const { repository, execute } = setup();
  await repository.load();
  expect(execute).toHaveBeenCalledWith(AchievementsCheckEndpoint, {
    path: {}, query: {}, body: {},
  });
});

test('skips invalid and unknown entries and rejects a missing items list', async () => {
  const { repository } = setup({
    items: [
      response.items[0],
      { id: 'unknown', asset_url: 'x', earned_count: 1, repeatable: true },
    ],
  });
  await repository.check();
  expect(repository.snapshot.achievements.map((item) => item.id)).toEqual(['townhall_18']);

  const malformed = setup({}).repository;
  await expect(malformed.check()).rejects.toBeInstanceOf(TypeError);
  expect(malformed.snapshot.isRefreshing).toBe(false);
});

test('session changes clear state and stale checks cannot replace a newer refresh', async () => {
  let resolveFirst: ((value: Record<string, unknown>) => void) | undefined;
  let resolveSecond: ((value: Record<string, unknown>) => void) | undefined;
  const first = new Promise<Record<string, unknown>>((resolve) => (resolveFirst = resolve));
  const second = new Promise<Record<string, unknown>>((resolve) => (resolveSecond = resolve));
  const execute = jest
    .fn()
    .mockImplementationOnce(() => Effect.promise(() => first))
    .mockImplementationOnce(() => Effect.promise(() => second)) as unknown as
    jest.MockedFunction<ContractApiService['execute']>;
  const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
  const repository = new AchievementsRepository({ execute, executeStatus });

  const stale = repository.check();
  repository.bindSession('user-2');
  const current = repository.check();
  resolveFirst?.(response);
  await stale;
  expect(repository.snapshot.isRefreshing).toBe(true);
  expect(repository.snapshot.achievements).toEqual([]);
  resolveSecond?.(response);
  await current;
  expect(repository.snapshot.isRefreshing).toBe(false);
  expect(repository.snapshot.achievements).toHaveLength(4);
});

test('coalesces checks while a refresh is active', async () => {
  let resolve: ((value: Record<string, unknown>) => void) | undefined;
  const pending = new Promise<Record<string, unknown>>((done) => (resolve = done));
  const { repository, execute } = setup(pending);
  const first = repository.check();
  await repository.check();
  expect(execute).toHaveBeenCalledTimes(1);
  resolve?.(response);
  await first;
});
