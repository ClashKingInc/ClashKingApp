import assert from 'node:assert/strict';
import test from 'node:test';
import { republishManifest, rollbackDescriptorKey } from './release-manifest.mjs';

test('republishes immutable content with a new identity and rollback metadata', () => {
  const source = {
    id: 'old-id',
    createdAt: '2026-09-01T00:00:00.000Z',
    runtimeVersion: 'runtime-ios',
    launchAsset: { url: 'https://assets.example/launch' },
    assets: [{ url: 'https://assets.example/asset' }],
    metadata: { channel: 'beta', version: '1.0.1-beta' },
    extra: { expoClient: { name: 'ClashKing' } },
  };

  const rollback = republishManifest(source, {
    id: 'new-id',
    createdAt: '2026-09-02T00:00:00.001Z',
    track: 'beta',
    targetVersion: '1.0.1-beta',
    rollbackFrom: '1.0.2-beta',
  });

  assert.equal(rollback.id, 'new-id');
  assert.equal(rollback.createdAt, '2026-09-02T00:00:00.001Z');
  assert.equal(rollback.metadata.rollbackFrom, '1.0.2-beta');
  assert.strictEqual(rollback.launchAsset, source.launchAsset);
  assert.strictEqual(rollback.assets, source.assets);
  assert.equal(source.id, 'old-id');
  assert.equal(source.metadata.rollbackFrom, undefined);
});

test('uses a deterministic safe rollback descriptor key', () => {
  assert.equal(
    rollbackDescriptorKey({
      track: 'production',
      fromVersion: '1.2.2',
      targetVersion: '1.2.0',
      platform: 'android',
      updateId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    }),
    'rollbacks/production/1.2.2/1.2.0/android-aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee.json',
  );
});
