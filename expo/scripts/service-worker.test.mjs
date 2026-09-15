import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import vm from 'node:vm';

const source = readFileSync(new URL('../public/sw.js', import.meta.url), 'utf8');
function harness({ denied = false, response = new Response('online'), cached } = {}) {
  const events = new Map();
  const writes = [];
  const deleted = [];
  let fetches = 0;
  vm.runInNewContext(source, {
    URL,
    Response,
    self: {
      addEventListener: (name, handler) => events.set(name, handler),
      location: { origin: 'https://app.clashk.ing' },
      clients: { claim() {} },
      skipWaiting() {},
    },
    caches: {
      keys: async () => ['clashking-expo-old', 'clashking-game-data-v1', 'other-app'],
      delete: async (key) => deleted.push(key),
      open: async () => {
        if (denied) throw new Error('Storage denied');
        return {
          match: async () => cached,
          put: async (...args) => {
            writes.push(args);
          },
        };
      },
    },
    fetch: async () => {
      fetches++;
      return response;
    },
  });
  return {
    writes,
    deleted,
    fetches: () => fetches,
    fetch(path, mode = 'cors') {
      let result;
      events.get('fetch')({
        request: { url: `https://app.clashk.ing${path}`, method: 'GET', mode },
        respondWith: (promise) => {
          result = promise;
        },
      });
      return result;
    },
    async activate() {
      let done;
      events.get('activate')({
        waitUntil: (promise) => {
          done = promise;
        },
      });
      await done;
    },
  };
}

test('denied cache access does not break successful network loads', async () => {
  const h = harness({ denied: true });
  assert.equal(await (await h.fetch('/bundle.js')).text(), 'online');
  assert.equal(h.fetches(), 1);
});

test('never stores private responses or intercepts OAuth callback credentials', async () => {
  const h = harness({
    response: new Response('private', { headers: { 'Cache-Control': 'private, no-store' } }),
  });
  await h.fetch('/index.html', 'navigate');
  assert.equal(h.writes.length, 0);
  assert.equal(h.fetch('/auth/callback?code=sensitive', 'navigate'), undefined);
  assert.equal(h.fetches(), 1);
});

test('serves the cached navigation document during a server failure', async () => {
  const h = harness({
    response: new Response('failure', { status: 503 }),
    cached: new Response('offline shell'),
  });
  assert.equal(await (await h.fetch('/', 'navigate')).text(), 'offline shell');
});

test('activation preserves metadata and caches owned by other applications', async () => {
  const h = harness();
  await h.activate();
  assert.deepEqual(h.deleted, ['clashking-expo-old']);
});
