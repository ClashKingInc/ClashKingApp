import { ApiClient } from '../../../core/api/client';
import type { StringStore } from '../../../services/storage/auth-storage';
import { UpgradeTrackerFormatError, UpgradeTrackerRepository } from './upgrade-tracker-repository';

class MemoryStore implements StringStore {
  readonly values = new Map<string, string>();
  async getItem(key: string) {
    return this.values.get(key) ?? null;
  }
  async setItem(key: string, value: string) {
    this.values.set(key, value);
  }
  async removeItem(key: string) {
    this.values.delete(key);
  }
}
const bundle = {
  buildings: [
    {
      _id: 1,
      name: 'Town Hall',
      village: 'home',
      type: 'Town Hall',
      upgrade_resource: 'Gold',
      levels: [{ level: 18, build_cost: 1, build_time: 1, required_townhall: 18 }],
    },
  ],
};
function reply(body: unknown, status = 200): Response {
  return {
    status,
    url: '',
    headers: new Headers(),
    text: async () => JSON.stringify(body),
  } as Response;
}
function setup(
  handler: (path: string, init: RequestInit) => Promise<Response> = async () => reply({}, 404),
) {
  const calls: { path: string; init: RequestInit }[] = [];
  const fetchImplementation = jest.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = new URL(String(input)),
      request = init ?? {};
    calls.push({ path: url.pathname, init: request });
    return handler(url.pathname, request);
  });
  const api = new ApiClient({
    baseUrl: 'https://api.test',
    environment: 'development',
    tokenProvider: { getAccessToken: async () => 'token' },
    fetchImplementation: fetchImplementation as typeof fetch,
  });
  const store = new MemoryStore();
  return {
    repository: new UpgradeTrackerRepository(api, store, undefined, () => bundle),
    calls,
    store,
  };
}

test('imports, normalizes, indexes, and reloads a linked raw snapshot', async () => {
  const { repository } = setup();
  const imported = await repository.importSnapshotBytes(
    new TextEncoder().encode(
      JSON.stringify({
        player: { tag: '2j8v28gv0', name: 'File Name', buildings: [{ data: 1, lvl: 18 }] },
      }),
    ),
    {
      allowedTags: new Set(['#2J8V28GV0']),
      linkedNamesByTag: { '#2J8V28GV0': 'Magic Jr.' },
    },
  );
  expect(imported).toMatchObject({ tag: '#2J8V28GV0', name: 'Magic Jr.', townHallLevel: 18 });
  expect(await repository.load('2j8v28gv0')).toBe(imported);
  expect(await repository.savedSnapshotAccounts()).toEqual([
    expect.objectContaining({ tag: '#2J8V28GV0', name: 'Magic Jr.', townHallLevel: '18' }),
  ]);
});

test('classifies malformed account JSON without leaking parser details', async () => {
  const { repository } = setup();
  await expect(
    repository.importSnapshotBytes(new TextEncoder().encode('{"tag":'), {
      allowedTags: new Set(['#TEST']),
    }),
  ).rejects.toEqual(
    expect.objectContaining<Partial<UpgradeTrackerFormatError>>({
      reason: 'invalid-account-json',
      message: 'Account data is not valid JSON',
    }),
  );

  await expect(
    repository.importSnapshotBytes(
      new TextEncoder().encode(JSON.stringify({ tag: '#OTHER', buildings: [] })),
      { allowedTags: new Set(['#TEST']) },
    ),
  ).rejects.toEqual(
    expect.objectContaining<Partial<UpgradeTrackerFormatError>>({ reason: 'unlinked-account' }),
  );
});

test('coalesces normalized remote loads and persists successful remote data', async () => {
  let resolve: ((response: Response) => void) | undefined;
  const pending = new Promise<Response>((done) => {
    resolve = done;
  });
  const { repository, calls } = setup(async (path) =>
    path.endsWith('/upgrades') ? pending : reply({}, 404),
  );
  repository.configureRemote({ accountId: 'user-1', verifiedPlayerTags: ['#TEST'] });
  const first = repository.load('test', true),
    second = repository.load('#TEST', true);
  resolve?.(reply({ data: { tag: '#TEST', name: 'Remote', buildings: [{ data: 1, lvl: 18 }] } }));
  const [one, two] = await Promise.all([first, second]);
  expect(one).toBe(two);
  expect(repository.peekCached('#TEST')?.name).toBe('Remote');
  expect(calls.filter((call) => call.path.endsWith('/upgrades'))).toHaveLength(1);
});

test('validated import prevents an older remote load from repopulating cache', async () => {
  let resolveGet: ((response: Response) => void) | undefined;
  const pending = new Promise<Response>((done) => {
    resolveGet = done;
  });
  const { repository } = setup(async (path, init) => {
    if (path.endsWith('/upgrades') && init.method === 'GET') return pending;
    if (path.endsWith('/upgrades') && init.method === 'PUT') return reply({});
    return reply({}, 404);
  });
  repository.configureRemote({ accountId: 'user1', verifiedPlayerTags: ['#TEST'] });
  const stale = repository.load('#TEST', true);
  await Promise.resolve();
  const imported = await repository.importSnapshotBytes(
    new TextEncoder().encode(
      JSON.stringify({ tag: '#TEST', name: 'Imported', buildings: [{ data: 1, lvl: 18 }] }),
    ),
    { allowedTags: new Set(['#TEST']) },
  );
  resolveGet?.(reply({ data: { tag: '#TEST', name: 'Stale remote', buildings: [] } }));
  await stale;
  expect(imported.name).toBe('Imported');
  expect(repository.peekCached('#TEST')?.name).toBe('Imported');
});

test('verified remote writes use whole-object PUT/PATCH and unverified writes fail', async () => {
  const { repository, calls } = setup(async () => reply({}));
  repository.configureRemote({ accountId: 'user-1', verifiedPlayerTags: ['#TEST'] });
  await repository.saveRawSnapshot('#TEST', { tag: '#TEST', buildings: [{ data: 1, lvl: 18 }] });
  await repository.savePlanPreferences('#TEST', 20, 'shortest');
  expect(calls.map((call) => [call.init.method, call.path])).toEqual(
    expect.arrayContaining([
      ['PUT', '/links/user-1/%23TEST/upgrades'],
      ['PATCH', '/links/user-1/%23TEST/upgrade-preferences'],
    ]),
  );
  repository.configureRemote({ accountId: 'user-1', verifiedPlayerTags: ['#OTHER'] });
  await expect(repository.saveRawSnapshot('#TEST', { tag: '#TEST' })).rejects.toThrow(
    'verified linked accounts',
  );
});

test('persists plan preferences locally per normalized account tag', async () => {
  const { repository } = setup();
  await repository.savePlanPreferences('#TEST', 20, 'shortest');
  await expect(repository.loadPlanPreferences('test')).resolves.toMatchObject({
    gold_pass_percent: 20,
    strategy: 'shortest',
  });
});

test('uses a warmed snapshot unless force refresh explicitly revalidates remote data', async () => {
  const { repository, calls } = setup(async (path) =>
    path.endsWith('/upgrades')
      ? reply({ data: { tag: '#TEST', name: 'Remote', buildings: [] } })
      : reply({}, 404),
  );
  await repository.importSnapshotBytes(
    new TextEncoder().encode(
      JSON.stringify({ tag: '#TEST', name: 'Local', buildings: [{ data: 1, lvl: 18 }] }),
    ),
    { allowedTags: new Set(['#TEST']) },
  );
  repository.configureRemote({ accountId: 'user', verifiedPlayerTags: ['#TEST'] });
  expect((await repository.load('#TEST'))?.name).toBe('Local');
  expect((await repository.load('#TEST', true))?.name).toBe('Remote');
  expect(calls.filter((call) => call.path.endsWith('/upgrades'))).toHaveLength(1);
});

test('remote failures fall back to the last local snapshot and clearCache removes remote ownership', async () => {
  const { repository, calls } = setup(async () => {
    throw new TypeError('offline');
  });
  await repository.importSnapshotBytes(
    new TextEncoder().encode(
      JSON.stringify({ tag: '#TEST', name: 'Local', buildings: [{ data: 1, lvl: 18 }] }),
    ),
    { allowedTags: new Set(['#TEST']) },
  );
  repository.configureRemote({ accountId: 'user', verifiedPlayerTags: ['#TEST'] });
  expect((await repository.load('#TEST', true))?.name).toBe('Local');
  repository.clearCache();
  expect((await repository.load('#TEST'))?.name).toBe('Local');
  expect(calls.filter((call) => call.path.endsWith('/upgrades'))).toHaveLength(1);
});

test('validates object shape, player identity, static data, and recognizable village data', async () => {
  const { repository } = setup();
  await expect(
    repository.importSnapshotBytes(new TextEncoder().encode('[]'), {
      allowedTags: new Set(['#TEST']),
    }),
  ).rejects.toMatchObject({
    reason: 'invalid-account-json',
    message: expect.stringContaining('object'),
  });
  await expect(
    repository.importSnapshotBytes(new TextEncoder().encode('{}'), {
      allowedTags: new Set(['#TEST']),
    }),
  ).rejects.toThrow('missing its player tag');
  await expect(
    repository.importSnapshotBytes(new TextEncoder().encode('{"tag":"#TEST"}'), {
      allowedTags: new Set(['#TEST']),
    }),
  ).rejects.toThrow('raw Clash account snapshot');

  const noStatic = setup().repository;
  Object.defineProperty(noStatic, 'bundleProvider', { value: () => ({}) });
  await expect(noStatic.load('#TEST')).rejects.toThrow('Static game data was not loaded');
  await expect(noStatic.saveRawSnapshot('', {})).rejects.toThrow('must include a player tag');
});

test('loads saved snapshot batches, filters malformed index entries, and reuses cache', async () => {
  const { repository, store } = setup();
  await repository.importSnapshotBytes(
    new TextEncoder().encode(
      JSON.stringify({ tag: '#A', name: 'Alpha', buildings: [{ data: 1, lvl: 18 }] }),
    ),
    { allowedTags: new Set(['#A']) },
  );
  await store.setItem(
    'upgrade_tracker_snapshot_index_v1',
    JSON.stringify([null, {}, { tag: '#A', name: 'Alpha', townHallLevel: 18 }]),
  );
  await expect(repository.savedSnapshotAccounts()).resolves.toEqual([
    expect.objectContaining({ tag: '#A', name: 'Alpha', townHallLevel: '18' }),
  ]);
  const first = await repository.loadSavedSnapshots(['#A', '#MISSING']);
  const second = await repository.loadSavedSnapshots(['A']);
  expect(first).toHaveLength(1);
  expect(second[0]).toBe(first[0]);

  await store.setItem('upgrade_tracker_snapshot_index_v1', '{}');
  await expect(repository.savedSnapshotAccounts()).resolves.toEqual([]);
});

test('uses remote preferences when valid and keeps local preferences for invalid or failed responses', async () => {
  const { repository, store, calls } = setup(async (path) => {
    if (path.endsWith('/upgrade-preferences')) {
      return reply({ preferences: { strategy: 'cheapest', gold_pass_percent: 10 } });
    }
    return reply({}, 404);
  });
  repository.configureRemote({ accountId: ' user ', verifiedPlayerTags: ['test'] });
  await expect(repository.loadPlanPreferences('#TEST')).resolves.toMatchObject({
    strategy: 'cheapest',
    gold_pass_percent: 10,
  });
  expect(calls[0]?.path).toBe('/links/user/%23TEST/upgrade-preferences');

  await store.setItem(
    'upgrade_tracker_preferences_v2_#TEST',
    JSON.stringify({ strategy: 'shortest', gold_pass_percent: 20 }),
  );
  const fallback = setup(async () => reply({ preferences: [] }, 500));
  fallback.repository.configureRemote({ accountId: 'user', verifiedPlayerTags: ['#TEST'] });
  await fallback.store.setItem(
    'upgrade_tracker_preferences_v2_#TEST',
    JSON.stringify({ strategy: 'shortest', gold_pass_percent: 20 }),
  );
  await expect(fallback.repository.loadPlanPreferences('#TEST')).resolves.toMatchObject({
    strategy: 'shortest',
  });
});

test('surfaces rejected remote writes and ignores empty remote snapshot responses', async () => {
  const failed = setup(async () => reply({}, 503));
  failed.repository.configureRemote({ accountId: 'user', verifiedPlayerTags: ['#TEST'] });
  await expect(
    failed.repository.saveRawSnapshot('#TEST', { tag: '#TEST', buildings: [{ data: 1, lvl: 18 }] }),
  ).rejects.toThrow('Could not save upgrade data (503)');
  await expect(failed.repository.savePlanPreferences('#TEST', 0, 'balanced')).rejects.toThrow(
    'Could not save upgrade preferences (503)',
  );

  const empty = setup(async () => reply({ data: {} }));
  empty.repository.configureRemote({ accountId: 'user', verifiedPlayerTags: ['#TEST'] });
  await expect(empty.repository.load('#TEST', true)).resolves.toBeNull();
});
