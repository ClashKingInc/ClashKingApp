import { AchievementModelCache } from './achievement-model-cache';

function binaryResponse(bytes: readonly number[], status = 200): Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    arrayBuffer: async () => Uint8Array.from(bytes).buffer,
  } as Response;
}

test('downloads a model once and reuses the in-memory data source', async () => {
  const fetchImplementation = jest.fn(async () => binaryResponse([1, 2, 3, 4]));
  const cache = new AchievementModelCache({
    fetchImplementation: fetchImplementation as typeof fetch,
  });
  const url = 'https://assets.example/badge.glb';
  const [first, second] = await Promise.all([cache.resolve(url), cache.resolve(url)]);
  expect(first).toBe('data:model/gltf-binary;base64,AQIDBA==');
  expect(second).toBe(first);
  expect(await cache.resolve(url)).toBe(first);
  expect(cache.peek(url)).toBe(first);
  expect(fetchImplementation).toHaveBeenCalledTimes(1);
});

test('memoizes the remote URL when the preload fails', async () => {
  const fetchImplementation = jest.fn(async () => binaryResponse([], 503));
  const cache = new AchievementModelCache({
    fetchImplementation: fetchImplementation as typeof fetch,
  });
  const url = 'https://assets.example/badge.glb';
  expect(await cache.resolve(url)).toBe(url);
  expect(await cache.resolve(url)).toBe(url);
  expect(fetchImplementation).toHaveBeenCalledTimes(1);
});

test('aborts a timed-out preload and falls back to the remote URL', async () => {
  const fetchImplementation = jest.fn(
    (_url: RequestInfo | URL, init?: RequestInit) =>
      new Promise<Response>((_resolve, reject) => {
        init?.signal?.addEventListener('abort', () => reject(new Error('aborted')));
      }),
  );
  const cache = new AchievementModelCache({
    fetchImplementation: fetchImplementation as typeof fetch,
    timeoutMs: 1,
  });
  const url = 'https://assets.example/slow.glb';
  expect(await cache.resolve(url)).toBe(url);
  expect(cache.peek(url)).toBe(url);
});
