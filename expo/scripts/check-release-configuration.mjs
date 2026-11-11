import './check-push-release-environment.mjs';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { X509Certificate } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { releaseEnvironment } from './release-environment.mjs';

const root = fileURLToPath(new URL('../', import.meta.url));
const track = process.env.CK_RELEASE_TRACK;
const expected = releaseEnvironment(track);
// Inspect the same environment and resolved Expo config used by prebuild.
// Never silently correct a mismatched release: that would hide build leakage.
for (const [key, value] of Object.entries(expected)) assert.equal(process.env[key], value, `Release environment mismatch: ${key}`);
const config = JSON.parse(execFileSync(process.execPath, [fileURLToPath(new URL('../node_modules/expo/bin/cli', import.meta.url)), 'config', '--json'], { cwd: root, encoding: 'utf8' }));
assert.equal(config.ios.bundleIdentifier, 'com.clashking.apps');
assert.equal(config.android.package, 'com.clashking.clashkingapp');
assert.ok(config.ios.associatedDomains.includes('applinks:app.clashk.ing'));
assert.equal(config.extra.clashKing.apiEnvironment, expected.EXPO_PUBLIC_CK_API_ENV);
assert.equal(config.version, process.env.CK_APP_VERSION);
if (track === 'production') {
  assert.equal(process.env.CK_ENABLE_UPDATES, 'true', 'Public store builds require signed OTA configuration');
  assert.equal(config.updates.enabled, true);
  assert.equal(config.updates.url, expected.CK_UPDATES_URL);
  assert.equal(config.updates.requestHeaders['expo-channel-name'], 'production');
  assert.equal(config.updates.codeSigningMetadata.alg, 'rsa-v1_5-sha256');
  assert.equal(config.updates.codeSigningMetadata.keyid, 'main');
  assert.equal(process.env.EXPO_PUBLIC_CK_DISCORD_CLIENT_ID, '824653933347209227');
  assert.ok(!process.env.EXPO_PUBLIC_CK_ASSET_ORIGIN || process.env.EXPO_PUBLIC_CK_ASSET_ORIGIN === 'https://assets.clashk.ing', 'Production asset override must use the production CDN');
  assert.ok(!process.env.EXPO_PUBLIC_LOCAL_GAME_ASSETS_URL, 'Local game-data preview must not enter a public build');
  const certificate = new X509Certificate(readFileSync(process.env.CK_UPDATES_CERTIFICATE_PATH));
  assert.ok(Date.parse(certificate.validFrom) <= Date.now() && Date.parse(certificate.validTo) > Date.now(), 'OTA certificate must be currently valid');
  assert.equal(certificate.publicKey.asymmetricKeyType, 'rsa');
}
console.log(`Verified actual Expo release configuration: ${track}, app ${config.version}, API ${expected.EXPO_PUBLIC_CK_API_V2_BASE_URL}, bot ${expected.EXPO_PUBLIC_CK_DISCORD_CLIENT_ID}, OTA ${config.updates.enabled ? 'enabled' : 'disabled'}.`);
