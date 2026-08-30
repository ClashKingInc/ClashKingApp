import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

import { paritySourceFingerprint } from './parity-source-fingerprint.mjs';

function fixture() {
  const root = mkdtempSync(join(tmpdir(), 'clashking-parity-'));
  mkdirSync(join(root, 'lib'), { recursive: true });
  mkdirSync(join(root, 'expo/docs'), { recursive: true });
  writeFileSync(join(root, 'lib/main.dart'), 'void main() {}\n');
  writeFileSync(join(root, 'expo/docs/parity-manifest.json'), '{}\n');
  return root;
}

test('tracked Flutter source drift changes the parity fingerprint', () => {
  const root = fixture();
  const paths = ['lib/main.dart', 'expo/docs/parity-manifest.json'];
  const before = paritySourceFingerprint(root, paths);

  writeFileSync(join(root, 'lib/main.dart'), 'void main() { runApp(); }\n');

  assert.notEqual(paritySourceFingerprint(root, paths), before);
});

test('Expo and parity-manifest-only edits do not change the Flutter source fingerprint', () => {
  const root = fixture();
  const paths = ['lib/main.dart', 'expo/docs/parity-manifest.json'];
  const before = paritySourceFingerprint(root, paths);

  writeFileSync(join(root, 'expo/docs/parity-manifest.json'), '{"schemaVersion":2}\n');

  assert.equal(paritySourceFingerprint(root, paths), before);
});
