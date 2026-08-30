import assert from 'node:assert/strict';
import { mkdtemp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import { stampWebServiceWorker, webExportFingerprint } from './stamp-web-service-worker.mjs';

test('stamps a deterministic content fingerprint into the exported worker', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'clashking-web-export-'));
  try {
    await mkdir(join(directory, '_expo'));
    await writeFile(join(directory, 'index.html'), '<main>ClashKing</main>');
    await writeFile(join(directory, '_expo', 'bundle.js'), 'console.log("build")');
    await writeFile(
      join(directory, 'sw.js'),
      "const CACHE_NAME = 'clashking-expo-__CLASHKING_WEB_BUILD__';",
    );

    const expected = await webExportFingerprint(directory);
    await assert.doesNotReject(stampWebServiceWorker(directory));
    assert.match(
      await readFile(join(directory, 'sw.js'), 'utf8'),
      new RegExp(`clashking-expo-${expected}`),
    );
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});

test('fails closed when an export no longer contains the cache token', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'clashking-web-export-'));
  try {
    await writeFile(join(directory, 'index.html'), '<main>ClashKing</main>');
    await writeFile(join(directory, 'sw.js'), "const CACHE_NAME = 'fixed';");
    await assert.rejects(stampWebServiceWorker(directory), /does not contain/);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
});
