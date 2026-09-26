import { FileUpdateIndex } from './file-update-index';
function setup(now = () => 1_000) {
  const values = new Map<string, string>();
  const storage = {
    getKeys: jest.fn(async () => [...values.keys()]),
    getMany: jest.fn(async (keys: readonly string[]) =>
      keys.map((key) => [key, values.get(key) ?? null] as const),
    ),
    getString: jest.fn(async (key: string) => values.get(key) ?? null),
    setString: jest.fn(async (key: string, value: string) => {
      values.set(key, value);
    }),
    removeString: jest.fn(async (key: string) => {
      values.delete(key);
    }),
  };
  return { values, storage, index: new FileUpdateIndex(storage, now) };
}
const oldRecord = {
  path: 'icons/a.webp',
  file: 'file:///a',
  sha: 'a',
  pendingSha: null,
  bytes: 42,
  usedAt: 10,
};

test('migrates old records once and bulk-hydrates paths without filesystem access', async () => {
  const s = setup();
  s.values.set('asset-local-files-v2', JSON.stringify({ 'image:a': oldRecord }));
  await s.index.hydrate();
  expect(s.values.has('asset-local-files-v2')).toBe(false);
  expect(s.index.peek('image:a')).toEqual({
    path: 'icons/a.webp',
    file: 'file:///a',
    installedSha: 'a',
    pendingSha: null,
    bytes: 42,
    lastViewed: 1_000,
  });
  expect([...s.values.values()].join('')).not.toContain('usedAt');
  expect([...s.values.values()].join('')).not.toContain('"sha"');
  const reopened = new FileUpdateIndex(s.storage, () => 1_000);
  await reopened.hydrate();
  expect(reopened.peek('image:a')?.file).toBe('file:///a');
  s.storage.getString.mockClear();
  s.storage.setString.mockClear();
  s.storage.getMany.mockClear();
  await reopened.prepare('image:a', 'icons/a.webp', 'a');
  await reopened.get('image:a');
  expect(s.storage.getString).not.toHaveBeenCalled();
  expect(s.storage.getMany).not.toHaveBeenCalled();
  expect(s.storage.setString).not.toHaveBeenCalled();
});

test('a failed migration retains the old index and retries without losing downloads', async () => {
  const s = setup();
  s.values.set(
    'asset-local-files-v2',
    JSON.stringify({ 'image:a': oldRecord, 'image:b': oldRecord }),
  );
  s.storage.setString.mockRejectedValueOnce(new Error('disk full'));
  await expect(s.index.hydrate()).rejects.toThrow('disk full');
  expect(s.values.has('asset-local-files-v2')).toBe(true);
  await s.index.hydrate();
  expect(s.index.imageBytes()).toBe(84);
});

test('a blocked write for one image does not block a different image', async () => {
  const s = setup();
  await s.index.hydrate();
  let release!: () => void;
  const realWrite = s.storage.setString.getMockImplementation()!;
  s.storage.setString.mockImplementation(async (key, value) => {
    if (key.endsWith('image%3Aa'))
      await new Promise<void>((resolve) => {
        release = resolve;
      });
    await realWrite(key, value);
  });
  const first = s.index.prepare('image:a', 'a', 'sha');
  await s.index.prepare('image:b', 'b', 'sha');
  expect(s.index.peek('image:b')).toBeDefined();
  expect(s.index.peek('image:a')).toBeUndefined();
  release();
  await first;
});

test('failed writes leave the in-memory copy consistent with durable storage', async () => {
  const s = setup();
  await s.index.prepare('image:a', 'a', 'a');
  s.storage.setString.mockRejectedValueOnce(new Error('disk full'));
  await expect(s.index.commit('image:a', 'file:///a', 'a', 42)).rejects.toThrow();
  expect(s.index.peek('image:a')?.file).toBeNull();
  await s.index.commit('image:a', 'file:///a', 'a', 42);
  expect(s.index.imageBytes()).toBe(42);
});

test('a persisted pending SHA survives a stale caller after restart', async () => {
  const s = setup();
  await s.index.prepare('image:a', 'a', 'old');
  await s.index.commit('image:a', 'file:///old', 'old');
  await s.index.notice(new Map([['a', 'new']]));
  const reopened = new FileUpdateIndex(s.storage, () => 1_000);
  expect(await reopened.prepare('image:a', 'a', 'old')).toMatchObject({
    installedSha: 'old',
    pendingSha: 'new',
  });
});

test('updates lastViewed in memory and storage at most once per day', async () => {
  let now = 1_000;
  const s = setup(() => now);
  await s.index.prepare('image:a', 'a', 'sha');
  s.storage.setString.mockClear();
  now += 60 * 60 * 1_000;
  await s.index.prepare('image:a', 'a', 'sha');
  expect(s.storage.setString).not.toHaveBeenCalled();
  now += 24 * 60 * 60 * 1_000;
  await s.index.prepare('image:a', 'a', 'sha');
  expect(s.storage.setString).toHaveBeenCalledTimes(1);
  expect(s.index.peek('image:a')?.lastViewed).toBe(now);
});
