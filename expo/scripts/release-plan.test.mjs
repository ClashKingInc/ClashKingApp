import assert from 'node:assert/strict';
import test from 'node:test';
import { decideRelease } from './release-plan.mjs';

const fingerprints = { ios: 'ios-a', android: 'android-a' };
const native = (version, track = 'beta', values = fingerprints) => ({
  version,
  track,
  type: 'native',
  platforms: { ios: { fingerprint: values.ios }, android: { fingerprint: values.android } },
});
const ota = (version, track = 'beta') => ({ version, track, type: 'ota', platforms: {} });

test('uses an explicitly selected patch-zero version for a native beta release', () => {
  assert.deepEqual(decideRelease({ markers: [], track: 'beta', version: '1.0.0', fingerprints }), {
    type: 'native',
    version: '1.0.0-beta',
    appVersion: '1.0.0',
    baseNativeVersion: null,
  });
});

test('uses an explicitly selected positive patch for OTA', () => {
  assert.deepEqual(
    decideRelease({
      markers: [native('1.1.0-beta')],
      track: 'beta',
      version: '1.1.4',
      fingerprints,
    }),
    {
      type: 'ota',
      version: '1.1.4-beta',
      appVersion: '1.1.4',
      baseNativeVersion: '1.1.0-beta',
    },
  );
});

test('rejects OTA when the selected native line does not exist', () => {
  assert.throws(
    () => decideRelease({ markers: [], track: 'production', version: '1.2.1', fingerprints }),
    /requires native release 1\.2\.0/,
  );
});

test('rejects OTA when native fingerprints changed', () => {
  assert.throws(
    () =>
      decideRelease({
        markers: [native('1.1.0-beta', 'beta', { ios: 'old', android: 'android-a' })],
        track: 'beta',
        version: '1.1.1',
        fingerprints,
      }),
    /Native fingerprints changed/,
  );
});

test('rejects an existing immutable version', () => {
  assert.throws(
    () =>
      decideRelease({
        markers: [native('1.1.0-beta'), ota('1.1.1-beta')],
        track: 'beta',
        version: '1.1.1',
        fingerprints,
      }),
    /already exists/,
  );
});

test('rejects a version older than the current track', () => {
  assert.throws(
    () =>
      decideRelease({
        markers: [native('1.2.0-beta')],
        track: 'beta',
        version: '1.1.0',
        fingerprints,
      }),
    /must be newer/,
  );
});

test('production may publish the same native core already used by beta', () => {
  assert.deepEqual(
    decideRelease({
      markers: [native('1.3.0-beta')],
      track: 'production',
      version: '1.3.0',
      fingerprints,
    }),
    { type: 'native', version: '1.3.0', appVersion: '1.3.0', baseNativeVersion: null },
  );
});

test('requires a suffix-free version input', () => {
  assert.throws(
    () => decideRelease({ markers: [], track: 'beta', version: '1.0.0-beta', fingerprints }),
    /without a suffix/,
  );
});
