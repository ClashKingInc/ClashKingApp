import { FileUpdateIndex } from './file-update-index';
import { ManagedImageCache, type ImageFiles } from './managed-image-cache';

function setup(now = () => 1_000) {
  const storage = new Map<string, string>();
  const preferences = {
    getKeys: async () => [...storage.keys()],
    getMany: async (keys: readonly string[]) =>
      keys.map((key) => [key, storage.get(key) ?? null] as const),
    removeString: async (key: string) => {
      storage.delete(key);
    },
    getString: async (key: string) => storage.get(key) ?? null,
    setString: async (key: string, value: string) => {
      storage.set(key, value);
    },
  };
  const index = new FileUpdateIndex(preferences, now);
  const files: ImageFiles = {
    exists: jest.fn(async () => true),
    remove: jest.fn(async () => {}),
    download: jest.fn(async (_url, sha) => ({ file: 'file:///' + sha, sha, bytes: 100 })),
  };
  return { index, files, preferences, cache: new ManagedImageCache(index, files, now) };
}
const url = 'https://assets.clashk.ing/icons/a.avif?size=128';
const path = 'icons/a.webp';
const key = 'image:' + url;

test('prunes images unused for 30 days while preserving JSON records', async () => {
  let now = 1_000;
  const s = setup(() => now);
  await s.cache.resolve(url, path, 'aaa', () => {});
  await s.index.prepare('json:troops', 'static_data/troops.json', 'aaa');
  await s.index.commit('json:troops', 'file:///troops', 'aaa');
  now += 31 * 86_400_000;
  const reopenedIndex = new FileUpdateIndex(s.preferences, () => now);
  const reopened = new ManagedImageCache(reopenedIndex, s.files, () => now);
  await reopened.hydrate();
  expect(s.files.download).toHaveBeenCalledTimes(1);
  expect(s.files.remove).toHaveBeenCalledWith('file:///aaa');
  expect(reopened.peek(url)).toBeUndefined();
  expect(reopened.getSize()).toBe(0);
  expect(await reopenedIndex.get('json:troops')).toBeDefined();
});

test('notices are persistent and lazy, then replace only the displayed size', async () => {
  const s = setup();
  await s.cache.resolve(url, path, 'aaa', () => {});
  await s.index.prepare('image:other-size', path, 'aaa');
  await s.index.commit('image:other-size', 'file:///other', 'aaa');
  await s.index.notice(
    new Map([
      [path, 'bbb'],
      ['unused.webp', 'ccc'],
    ]),
  );
  expect(s.files.download).toHaveBeenCalledTimes(1);
  const reopened = new FileUpdateIndex(s.preferences, () => 1_000);
  expect(await reopened.get(key)).toMatchObject({ installedSha: 'aaa', pendingSha: 'bbb' });
  const show = jest.fn();
  await new ManagedImageCache(reopened, s.files, () => 1_000).resolve(url, path, 'bbb', show);
  expect(show).toHaveBeenCalledWith('file:///aaa');
  expect(await reopened.get(key)).toMatchObject({ installedSha: 'bbb', pendingSha: null });
  expect(await reopened.get('image:other-size')).toMatchObject({
    installedSha: 'aaa',
    pendingSha: 'bbb',
  });
  expect(Object.keys(await reopened.all())).toHaveLength(2);
});

test('a failed download retains the file and pending version across restart', async () => {
  const s = setup();
  await s.cache.resolve(url, path, 'aaa', () => {});
  jest.mocked(s.files.download).mockRejectedValueOnce(new Error('offline'));
  expect(await s.cache.resolve(url, path, 'bbb', () => {})).toBe('file:///aaa');
  expect(await new FileUpdateIndex(s.preferences).get(key)).toMatchObject({
    file: 'file:///aaa',
    installedSha: 'aaa',
    pendingSha: 'bbb',
  });
  expect(s.files.remove).not.toHaveBeenCalled();
});

test('new pending SHA survives an older download finishing', async () => {
  const s = setup();
  await s.index.prepare(key, path, 'aaa');
  await s.index.notice(new Map([[path, 'bbb']]));
  await s.index.commit(key, 'file:///aaa', 'aaa');
  expect(await s.index.get(key)).toMatchObject({ installedSha: 'aaa', pendingSha: 'bbb' });
  await s.index.commit(key, 'file:///bbb', 'bbb');
  // Even out-of-order completion after the latest download must remain pending.
  await s.index.commit(key, 'file:///aaa-late', 'aaa');
  expect(await s.index.get(key)).toMatchObject({ installedSha: 'aaa', pendingSha: 'bbb' });
});

test('wrong server SHA never advances the saved record', async () => {
  const s = setup();
  jest
    .mocked(s.files.download)
    .mockResolvedValue({ file: 'file:///wrong', sha: 'wrong', bytes: 20 });
  await expect(s.cache.resolve(url, path, 'aaa', () => {})).rejects.toThrow('SHA');
  expect(await s.index.get(key)).toMatchObject({ installedSha: null, pendingSha: 'aaa' });
  expect(s.files.remove).toHaveBeenCalledWith('file:///wrong');
});

test('a record does not conceal an evicted disk file', async () => {
  const s = setup();
  await s.cache.resolve(url, path, 'aaa', () => {});
  jest.mocked(s.files.exists).mockResolvedValue(false);
  await s.cache.resolve(url, path, 'aaa', () => {});
  expect(s.files.download).toHaveBeenCalledTimes(2);
});

test('clearing waits for in-flight downloads and removes their records and bytes', async () => {
  const s = setup();
  let finish!: (value: { file: string; sha: string; bytes: number }) => void;
  let started!: () => void;
  const downloading = new Promise<void>((resolve) => {
    started = resolve;
  });
  jest.mocked(s.files.download).mockImplementationOnce(() => {
    started();
    return new Promise((resolve) => {
      finish = resolve;
    });
  });
  const load = s.cache.resolve(url, path, 'aaa', () => {});
  await downloading;
  const clear = s.cache.clear();
  finish({ file: 'file:///aaa', sha: 'aaa', bytes: 100 });
  await Promise.all([load, clear]);
  expect(s.cache.peek(url)).toBeUndefined();
  expect(s.cache.getSize()).toBe(0);
  expect(s.files.remove).toHaveBeenCalledWith('file:///aaa');
});
