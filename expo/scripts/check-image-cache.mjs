import assert from 'node:assert/strict';
import { Buffer } from 'node:buffer';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { registerHooks } from 'node:module';
import { test } from 'node:test';
import ts from 'typescript';

// Run the app's cache and manifest code in Node without loading native Expo modules.
globalThis.__DEV__ = false;
registerHooks({
  load(url, context, nextLoad) {
    if (!url.startsWith('file:') || !url.endsWith('.ts')) return nextLoad(url, context);
    const source = ts.transpileModule(readFileSync(new URL(url), 'utf8'), {
      compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 },
    }).outputText;
    return { format: 'module', source, shortCircuit: true };
  },
  resolve(specifier, context, nextResolve) {
    if (specifier === 'expo-crypto') {
      const stub = [
        "import { createHash } from 'node:crypto';",
        "export const CryptoDigestAlgorithm = { SHA256: 'sha256' };",
        'export const digestStringAsync = async (algorithm, text) =>',
        "  createHash(algorithm).update(text).digest('hex');",
      ].join('\n');
      return { url: 'data:text/javascript,' + encodeURIComponent(stub), shortCircuit: true };
    }
    if (specifier.startsWith('.') && context.parentURL) {
      const source = new URL(specifier + '.ts', context.parentURL);
      if (source.protocol === 'file:' && existsSync(source))
        return nextResolve(source.href, context);
    }
    return nextResolve(specifier, context);
  },
});

const { FileUpdateIndex } = await import('../src/core/assets/file-update-index.ts');
const { ManagedImageCache } = await import('../src/core/assets/managed-image-cache.ts');
const { avifPixelBound } = await import('../src/core/assets/avif-dimensions.ts');
const { applyAssetManifest } = await import('../src/core/assets/asset-manifest.ts');
const { GameDataService } = await import('../src/core/game-data/game-data-service.ts');
const { GameAssetManifestService } = await import('../src/features/game-assets/repository.ts');
const { managedAssetRequest, sizedAssetUrl, sizedBadgeUrl, originalBadgeUrl } =
  await import('../src/ui/image-delivery.ts');

const assetPath = 'buildings/home-village/town_hall/level_18.webp';
const sha = 'a'.repeat(64);
const nextSha = 'b'.repeat(64);
const now = () => Date.UTC(2026, 10, 24);
const deferred = () => Promise.withResolvers();
const request = (size, version = sha) => ({
  path: assetPath,
  url: 'https://assets.clashk.ing/' + assetPath.replace('.webp', '.avif') + '?size=' + size,
  sha: version,
  size,
});

function memoryStore() {
  const values = new Map();
  const writes = [];
  return {
    writes,
    getKeys: async () => [...values.keys()],
    getMany: async (keys) => keys.map((key) => [key, values.get(key) ?? null]),
    getString: async (key) => values.get(key) ?? null,
    setString: async (key, value) => {
      writes.push(key);
      values.set(key, value);
    },
    removeString: async (key) => {
      values.delete(key);
    },
  };
}

function imageFixture() {
  const storage = memoryStore();
  const files = new Set();
  const transfers = [];
  let handle = async () => {};
  const implementation = {
    exists: async (file) => files.has(file),
    remove: async (file) => {
      files.delete(file);
    },
    async download({ size, sha: version }, signal, validateReplacement) {
      const pixels = Math.min(size, 221);
      // Town Hall 18 response sizes measured against the CDN for issue #281.
      const bytes = size <= 128 ? 5681 : 12784;
      const file = 'file://' + (transfers.length + 1);
      transfers.push({ size, bytes });
      await handle({ signal, size, validateReplacement });
      files.add(file);
      return { file, sha: version, bytes, pixels, fullSize: pixels < size };
    },
  };
  const create = () => {
    const index = new FileUpdateIndex(storage, now);
    return { index, cache: new ManagedImageCache(index, implementation, now) };
  };
  return {
    ...create(),
    create,
    transfers,
    files,
    storage,
    onDownload: (callback) => {
      handle = callback;
    },
  };
}

test('reads AVIF dimensions from complete metadata without scanning pixel data', () => {
  const box = (type, ...parts) => {
    const body = Buffer.concat(parts);
    const header = Buffer.alloc(8);
    header.writeUInt32BE(body.length + 8);
    header.write(type, 4);
    return Buffer.concat([header, body]);
  };
  const ispe = (width, height) => {
    const body = Buffer.alloc(12);
    body.writeUInt32BE(width, 4);
    body.writeUInt32BE(height, 8);
    return box('ispe', body);
  };
  const metadata = Buffer.concat([
    box('ftyp', Buffer.from('avif'), Buffer.alloc(4)),
    box('meta', Buffer.alloc(4), box('iprp', box('ipco', ispe(64, 64), ispe(199, 221)))),
  ]);
  assert.equal(avifPixelBound(metadata), 221);
  assert.equal(avifPixelBound(metadata.subarray(0, -1)), undefined);
  assert.equal(avifPixelBound(Buffer.from('not AVIF')), undefined);
});

test('writes a first install once and notifies only subscribers for its path', async () => {
  const { cache, index, storage, onDownload } = imageFixture();
  await cache.hydrate();
  let matching = 0;
  let unrelated = 0;
  const stopMatching = cache.subscribeImage(assetPath, () => matching++);
  const stopUnrelated = cache.subscribeImage('troops/barbarian/icon.webp', () => unrelated++);
  const validations = [];
  onDownload(async ({ validateReplacement }) => validations.push(validateReplacement));

  await cache.resolve(request(256), () => {});
  assert.equal(storage.writes.length, 1);
  assert.equal(matching, 1);
  assert.equal(unrelated, 0);
  assert.deepEqual(validations, [false]);

  await index.notice(new Map([[assetPath, nextSha]]));
  await cache.resolve(request(256, nextSha), () => {});
  assert.deepEqual(validations, [false, true]);
  stopMatching();
  stopUnrelated();
});

test('reuses a maximum-resolution file across larger and smaller URLs and after restart', async (t) => {
  const { cache, create, transfers } = imageFixture();
  const downloaded = await cache.resolve(request(256), () => {});
  for (const size of [512, 1024, 128])
    assert.equal(await cache.resolve(request(size), () => {}), downloaded);
  const restarted = create().cache;
  assert.equal(await restarted.resolve(request(128), () => {}), downloaded);
  assert.deepEqual(transfers, [{ size: 256, bytes: 12784 }]);
  assert.equal(restarted.getSize(), 12784);
  t.diagnostic(
    'CDN replay for 256 → 512 → 1024 → 128: 4 requests / 44,033 B before, 1 / 12,784 B after',
  );
});

test('downloads small first, then upgrades and reuses the file when needed', async () => {
  const { cache, transfers } = imageFixture();
  const small = await cache.resolve(request(128), () => {});
  const large = await cache.resolve(request(512), () => {});
  assert.notEqual(large, small);
  assert.equal(await cache.resolve(request(128), () => {}), small);
  assert.equal(await cache.resolve(request(256), () => {}), large);
  assert.deepEqual(
    transfers.map(({ size }) => size),
    [128, 512],
  );
});

test('joins an in-flight larger download and retries independently if it fails', async () => {
  for (const fail of [false, true]) {
    const { cache, onDownload, transfers } = imageFixture();
    const started = deferred();
    const finish = deferred();
    const joined = deferred();
    onDownload(async ({ size }) => {
      if (size !== 512) return;
      started.resolve();
      await finish.promise;
      if (fail) throw new Error('Variant unavailable');
    });
    const large = cache.resolve(request(512), () => {});
    const largeResult = large.catch((error) => error);
    await started.promise;
    const small = cache.resolve(request(128), () => {});
    setImmediate(joined.resolve);
    await joined.promise;
    assert.equal(transfers.length, 1);
    finish.resolve();
    if (fail) {
      assert.match(String(await largeResult), /Variant unavailable/);
      assert.equal(await small, 'file://2');
      assert.deepEqual(
        transfers.map(({ size }) => size),
        [512, 128],
      );
    } else {
      assert.equal(await small, await large);
      assert.equal(transfers.length, 1);
    }
  }
});

test('shows the previous file when a replacement fails and recovers on retry', async () => {
  const { cache, index, files, onDownload } = imageFixture();
  const old = await cache.resolve(request(512), () => {});
  await index.notice(new Map([[assetPath, nextSha]]));
  onDownload(async () => {
    throw new Error('Broken response');
  });
  const displayed = [];
  assert.equal(await cache.resolve(request(512, nextSha), (file) => displayed.push(file)), old);
  assert.deepEqual(displayed, [old]);
  assert.deepEqual([...files], [old]);
  onDownload(async () => {});
  const replacement = await cache.resolve(request(512, nextSha), () => {});
  assert.notEqual(replacement, old);
  assert.deepEqual([...files], [replacement]);
});

test('rejects a download superseded while the previous version is in flight', async () => {
  const { cache, index, files, onDownload } = imageFixture();
  const started = deferred();
  const finish = deferred();
  onDownload(async () => {
    started.resolve();
    await finish.promise;
  });
  const old = cache.resolve(request(512), () => {});
  const rejection = assert.rejects(old, /superseded/);
  await started.promise;
  await index.notice(new Map([[assetPath, nextSha]]));
  finish.resolve();
  await rejection;
  assert.equal(files.size, 0);
  assert.equal(cache.getSize(), 0);
  assert.equal(await cache.resolve(request(512, nextSha), () => {}), 'file://2');
});

test('removes failed files, reuses pre-upgrade records and clears during a download', async () => {
  const { cache, index, files, onDownload, transfers } = imageFixture();
  const legacy = request(512);
  await index.prepare('image:' + legacy.url, legacy.path, sha);
  await index.commit('image:' + legacy.url, 'file://legacy', sha, 12000);
  files.add('file://legacy');
  assert.equal(await cache.resolve(request(128), () => {}), 'file://legacy');
  assert.equal(transfers.length, 0);
  await cache.invalidate(assetPath, 'file://legacy');
  assert.equal(cache.peek(request(128)), undefined);

  const started = deferred();
  onDownload(async ({ signal }) => {
    started.resolve();
    await new Promise((_, reject) => {
      signal.addEventListener('abort', () => reject(new Error('Aborted')), { once: true });
    });
  });
  const pending = cache.resolve(request(128), () => {});
  const rejection = assert.rejects(pending, /cleared/);
  await started.promise;
  await cache.clear();
  await rejection;
  assert.equal(cache.getSize(), 0);
  assert.equal(files.size, 0);
});

test('consumers of a shared image can replace it after one invalidates it', async () => {
  const { cache, transfers } = imageFixture();
  const large = request(512);
  const small = request(128);
  const shared = await cache.resolve(large, () => {});
  assert.equal(cache.peek(small), shared);

  const recover = (consumer) => new Promise((resolve, reject) => {
    const unsubscribe = cache.subscribeImage(consumer.path, () => {
      if (cache.peek(consumer) !== undefined) return;
      unsubscribe();
      cache.resolve(consumer, () => {}).then(resolve, reject);
    });
  });
  const recovering = [recover(large), recover(small)];
  await cache.invalidate(assetPath, shared);

  const replacement = await Promise.all(recovering);
  assert.notEqual(replacement[0], shared);
  assert.equal(replacement[1], replacement[0]);
  assert.equal(cache.peek(large), replacement[0]);
  assert.equal(cache.peek(small), replacement[1]);
  assert.equal(transfers.length, 2);
});

function manifestFixture({ legacy = false } = {}) {
  const preferences = memoryStore();
  const files = memoryStore();
  const body = JSON.stringify({
    version: 2,
    assets: { buildings: [{ path: assetPath, display_name: 'Town Hall', sha, animated: false }] },
    data: {
      stats: [
        {
          path: 'static_data/buildings.json',
          sha: createHash('sha256').update('{}').digest('hex'),
        },
      ],
      translations: [],
    },
  });
  let stamp = now();
  const calls = [];
  let offline = legacy;
  const create = () =>
    new GameDataService({
      platform: 'native',
      preferences,
      files: { read: files.getString, write: files.setString },
      now: () => new Date(stamp),
      fetchImplementation: async (url, init) => {
        calls.push({ url, headers: init.headers });
        if (offline) throw new Error('Offline');
        if (init.headers['If-None-Match'] === '"manifest-1"')
          return new Response(null, { status: 304 });
        return new Response(body, { headers: { ETag: '"manifest-1"' } });
      },
    });
  return {
    create,
    preferences,
    body,
    calls,
    advance: () => {
      stamp += 60_001;
    },
    setOffline: () => {
      offline = true;
    },
  };
}

test('renderer and prefetch can use the original manifest identity for an AVIF variant', () => {
  const { body } = manifestFixture();
  const manifest = JSON.parse(body);
  const fallbackPath = 'icons/unknown.png';
  const animationPath = 'icons/animated.webp';
  manifest.assets.icons = [
    { path: fallbackPath, sha: nextSha, animated: false },
    { path: animationPath, sha: nextSha, animated: true },
  ];
  applyAssetManifest(manifest);
  const origin = 'https://assets.clashk.ing/';
  const original = origin + assetPath;
  const variant = sizedAssetUrl(original, 42, 42, 3);
  assert.deepEqual(managedAssetRequest(original, variant), request(128));
  assert.deepEqual(managedAssetRequest(original, original), {
    url: original,
    path: assetPath,
    sha,
    size: undefined,
  });
  assert.deepEqual(managedAssetRequest(original, origin + fallbackPath), {
    url: origin + fallbackPath,
    path: fallbackPath,
    sha: nextSha,
    size: undefined,
  });
  assert.equal(managedAssetRequest(original, variant, true), undefined);
  assert.equal(sizedAssetUrl(origin + animationPath, 42, 42, 3), origin + animationPath);
  assert.equal(managedAssetRequest(origin + animationPath, origin + animationPath), undefined);
  const badge = sizedBadgeUrl('https://badges.clashk.ing/ABC.png', 42, 42, 3);
  assert.equal(badge, 'https://badges.clashk.ing/ABC.avif?size=medium');
  assert.equal(originalBadgeUrl(badge), 'https://badges.clashk.ing/ABC.png?size=medium');
  assert.equal(managedAssetRequest(badge, badge), undefined);
});

test('Wiki and game data share one download and one conditional refresh', async () => {
  const { create, calls, advance, setOffline } = manifestFixture();
  const service = create();
  const wiki = new GameAssetManifestService((refresh) =>
    service.loadAssetManifest(refresh ? 'force' : 'cached'),
  );
  const [, catalogue] = await Promise.all([service.loadAssetManifest(), wiki.load()]);
  assert.equal(catalogue.assets[0].path, assetPath);
  assert.equal(calls.length, 1);
  advance();
  await Promise.all([service.loadAssetManifest('refresh'), wiki.load({ forceRefresh: true })]);
  assert.equal(calls.length, 2);
  assert.equal(calls[1].headers['If-None-Match'], '"manifest-1"');
  advance();
  setOffline();
  const restarted = create();
  await restarted.loadAssetManifest('refresh');
  assert.equal((await restarted.loadAssetManifest()).version, 2);
});

test('migrates a valid Wiki-only manifest and can open it offline', async () => {
  const { create, preferences, body, calls } = manifestFixture({ legacy: true });
  await preferences.setString('game_asset_manifest_v1', body);
  await preferences.setString('game_asset_manifest_v1_fetched_at', String(now()));
  assert.equal((await create().loadAssetManifest()).version, 2);
  assert.equal(await preferences.getString('game_asset_manifest_v1'), null);
  assert.equal((await create().loadAssetManifest()).version, 2);
  assert.equal(calls.length, 0);
});
