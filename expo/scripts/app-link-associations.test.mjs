import assert from 'node:assert/strict';
import test from 'node:test';
import { androidAssociation } from './app-link-associations.mjs';

test('does not invent an Android signing certificate', () => {
  assert.equal(androidAssociation(), null);
  assert.throws(() => androidAssociation('upload-key-alias'));
});
test('publishes only validated SHA256 fingerprints and supports key rotation', () => {
  const first = Array(32).fill('AB').join(':');
  const second = Array(32).fill('CD').join(':');
  const [item] = androidAssociation(`${first.toLowerCase()}, ${second}, ${first}`);
  assert.deepEqual(item.target.sha256_cert_fingerprints, [first, second]);
  assert.equal(item.target.package_name, 'com.clashking.clashkingapp');
});
