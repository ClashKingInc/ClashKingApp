import assert from 'node:assert/strict';
import test from 'node:test';
import { releaseEnvironment } from './release-environment.mjs';
import { compareVersions, decideRelease } from './release-plan.mjs';

const fingerprints = { ios: 'ios-runtime', android: 'android-runtime' };
const native = (track, version = `0.5.0-${track}`) => ({
  track,
  version,
  type: 'native',
  platforms: Object.fromEntries(
    Object.entries(fingerprints).map(([platform, fingerprint]) => [platform, { fingerprint }]),
  ),
});

for (const [track, origin] of [
  ['alpha', 'https://local-api.clashk.ing'],
  ['beta', 'https://dev-api.clashk.ing'],
  ['production', 'https://api.clashk.ing'],
]) {
  test(`${track} uses the same API host for app, proxy, push, and OTA delivery`, () => {
    const environment = releaseEnvironment(track);
    assert.equal(environment.EXPO_PUBLIC_CK_API_V2_BASE_URL, `${origin}/v2`);
    assert.equal(environment.EXPO_PUBLIC_CK_PUSH_API_V2_BASE_URL, `${origin}/v2`);
    assert.equal(environment.EXPO_PUBLIC_CK_PROXY_BASE_URL, `${origin}/proxy/v1`);
    assert.equal(environment.CK_UPDATES_URL, `${origin}/v2/app/updates/manifest`);
  });
}

test('rejects unknown channels instead of falling back to production', () => {
  assert.throws(() => releaseEnvironment('preview'), /Unsupported release track/);
  assert.throws(() => decideRelease({ track: 'preview' }), /Release track must/);
});

test('the first 0.5.0 alpha is native even without previous Expo releases', () => {
  assert.deepEqual(decideRelease({ markers: [], track: 'alpha', version: '0.5.0', fingerprints }), {
    type: 'native',
    version: '0.5.0-alpha',
    appVersion: '0.5.0',
    baseNativeVersion: null,
  });
});

test('a compatible alpha patch targets the alpha native baseline', () => {
  const plan = decideRelease({
    markers: [native('alpha')],
    track: 'alpha',
    version: '0.5.1',
    fingerprints,
  });
  assert.equal(plan.type, 'ota');
  assert.equal(plan.baseNativeVersion, '0.5.0-alpha');
});

test('an alpha native baseline cannot authorize a beta OTA', () => {
  assert.throws(
    () =>
      decideRelease({
        markers: [native('alpha')],
        track: 'beta',
        version: '0.5.1',
        fingerprints,
      }),
    /requires native release 0\.5\.0-beta/,
  );
});

for (const platform of ['ios', 'android']) {
  test(`a changed ${platform} runtime blocks OTA publication`, () => {
    assert.throws(
      () =>
        decideRelease({
          markers: [native('alpha')],
          track: 'alpha',
          version: '0.5.1',
          fingerprints: { ...fingerprints, [platform]: 'changed' },
        }),
      /Native fingerprints changed/,
    );
  });
}

test('immutable alpha versions cannot be reused', () => {
  assert.throws(
    () =>
      decideRelease({
        markers: [native('alpha')],
        track: 'alpha',
        version: '0.5.0',
        fingerprints,
      }),
    /already exists/,
  );
});

test('a malformed cross-channel marker cannot authorize an alpha OTA', () => {
  assert.throws(
    () =>
      decideRelease({
        markers: [native('alpha', '0.5.0-beta')],
        track: 'alpha',
        version: '0.5.1',
        fingerprints,
      }),
    /requires native release/,
  );
});

test('version ordering keeps alpha, beta, and production distinct', () => {
  assert.ok(compareVersions('0.5.0-alpha', '0.5.0-beta') < 0);
  assert.ok(compareVersions('0.5.0-beta', '0.5.0') < 0);
});
