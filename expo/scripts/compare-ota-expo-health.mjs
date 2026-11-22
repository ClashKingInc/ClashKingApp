// Run full online Doctor checks and compare an OTA candidate with the released
// native source. Actual release still requires the authenticated native marker
// and real embedded certificate through the release-plan fingerprint gate.
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { X509Certificate } from 'node:crypto';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';

const [baselineArgument, certificateArgument] = process.argv.slice(2);
if (!baselineArgument || !certificateArgument) {
  throw new Error('Usage: node scripts/compare-ota-expo-health.mjs BASELINE_REPO CERTIFICATE_PATH');
}
// Update these values only when a newly published native binary becomes the
// supported OTA baseline. PR review and release-plan verify the real release.
const baselineSha = 'c4c5fba58db2bd06bb48082cfc045ff54efe14f4';
const markerUrl = 'https://updates.clashk.ing/releases/production/1.0.0/release.json';
const candidate = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const baselineRepo = resolve(baselineArgument);
const baseline = join(baselineRepo, 'expo');
const certificate = resolve(certificateArgument);
new X509Certificate(readFileSync(certificate));

function run(command, args, cwd, env, allowedStatuses = [0]) {
  const result = spawnSync(command, args, { cwd, env, encoding: 'utf8', maxBuffer: 16 * 1024 * 1024 });
  if (result.error) throw result.error;
  if (!allowedStatuses.includes(result.status)) {
    throw new Error(`${command} exited ${result.status}:\n${result.stdout}\n${result.stderr}`);
  }
  return { status: result.status, stdout: result.stdout, stderr: result.stderr, output: `${result.stdout}${result.stderr}` };
}
const gitEnv = { ...process.env };
const commit = run('git', ['rev-parse', 'HEAD'], baselineRepo, gitEnv).output.trim();
assert.equal(commit, baselineSha, 'The baseline checkout must match the selected native release source');
assert.equal(run('git', ['status', '--porcelain', '--untracked-files=no'], baselineRepo, gitEnv).output.trim(), '', 'The baseline tracked files must be clean');

// Do not permit an inherited switch to turn off network/version checks or
// downgrade network errors. The two Doctor runs execute the same pinned binary.
const env = { ...process.env, CI: '1', NO_COLOR: '1', EXPO_NO_TELEMETRY: '1', EXPO_NO_GIT_STATUS: '1', EXPO_NO_DOTENV: '1', EXPO_NO_CACHE: '1' };
for (const key of ['EXPO_OFFLINE', 'EXPO_LOCAL', 'EXPO_STAGING', 'EXPO_UNIVERSE_DIR', 'EXPO_DOCTOR_ENABLE_DIRECTORY_CHECK', 'EXPO_DOCTOR_SKIP_DEPENDENCY_VERSION_CHECK', 'EXPO_DOCTOR_WARN_ON_NETWORK_ERRORS', 'EXPO_NO_DEPENDENCY_VALIDATION']) delete env[key];
const pin = 'expo-doctor@1.21.8';
const stripAnsi = value => value.replace(/\x1b\[[0-9;]*m/g, '');
const failingSdkCheck = 'Check that packages match versions required by installed Expo SDK';
function doctor(cwd, label) {
  const pkg = JSON.parse(readFileSync(join(cwd, 'package.json'), 'utf8'));
  assert(!(pkg.expo?.install?.exclude?.length), 'Expo dependency validation exclusions are not permitted');
  for (const settings of Object.values(pkg.expo?.doctor ?? {})) {
    assert(settings?.enabled !== false && !settings?.exclude?.length && settings?.listUnknownPackages !== false, 'Doctor check exclusions are not permitted');
  }
  const { status, output: raw } = run('npx', ['--yes', pin, '--verbose'], cwd, env, [0, 1]);
  const output = stripAnsi(raw).replace(/\r\n/g, '\n');
  console.log(`\n===== Complete online Expo Doctor: ${label} =====\n${output}`);
  assert.match(output, /^expo-doctor: v1\.21\.8$/m, 'Unexpected Expo Doctor version');
  assert.doesNotMatch(output, /Unexpected error while running|network error|EXPO_OFFLINE|Unable to reach well-known versions endpoint|Using local dependency map/i, 'Doctor must complete online without suppressed network errors');
  const declared = Number(output.match(/^Running (\d+) checks on your project/m)?.[1]);
  assert.equal(declared, 20, 'The pinned Doctor must execute all 20 expected SDK 58 checks');
  const checks = new Map();
  for (const match of output.matchAll(/^(✔|✖) (.+)$/gm)) {
    const passed = match[1] === '✔';
    if (checks.has(match[2])) assert.equal(checks.get(match[2]), passed, 'Conflicting Doctor result');
    checks.set(match[2], passed);
  }
  assert.equal(checks.size, declared, 'Doctor output does not cover every declared check');
  const failures = [...checks].filter(([, passed]) => !passed).map(([name]) => name);
  assert.deepEqual(failures, status === 0 ? [] : [failingSdkCheck], 'Only the SDK version recommendation can be considered for comparison');
  const table = [];
  if (status !== 0) {
    assert.match(output, /Patch version mismatches/, 'Only patch-level recommendations can be compared');
    const lines = output.split('\n');
    const start = lines.findIndex(line => /^package\s+expected\s+found\s*$/.test(line));
    assert(start >= 0, 'Missing Doctor package recommendation table');
    for (const line of lines.slice(start + 1)) {
      if (!line.trim()) break;
      const match = line.match(/^(\S+)\s+~?(\d+)\.(\d+)\.(\d+)\s+(\d+)\.(\d+)\.(\d+)\s*$/);
      assert(match, `Unrecognized Doctor recommendation: ${line}`);
      assert.equal(match[2], match[5], 'Doctor reported a major-version mismatch');
      assert.equal(match[3], match[6], 'Doctor reported a minor-version mismatch');
      assert(Number(match[4]) > Number(match[7]), 'Doctor recommendation is not a newer patch');
      table.push({ package: match[1], expected: `${match[2]}.${match[3]}.${match[4]}`, found: `${match[5]}.${match[6]}.${match[7]}` });
    }
    assert(table.length > 0, 'Doctor failed without a recognized recommendation');
  }
  // Expo CLI can fall back to a bundled map after an API error. Probe its real
  // dependency check without cache and reject that fallback explicitly.
  const probe = run(process.execPath, [join(cwd, 'node_modules/expo/bin/cli'), 'install', '--check', '--json'], cwd, env, [0, 1]);
  assert.doesNotMatch(probe.output, /Unable to reach well-known versions endpoint|Using local dependency map|offline|network error/i, 'Expo dependency check must use the online SDK data');
  const probeResult = JSON.parse(probe.stdout);
  assert.equal(probe.status, probeResult.upToDate ? 0 : 1, 'Inconsistent Expo dependency check result');
  const probeTable = probeResult.dependencies.map(item => ({ package: item.packageName, expected: item.expectedVersionOrRange.replace(/^~/, ''), found: item.actualVersion }))
    .sort((a, b) => a.package.localeCompare(b.package));
  table.sort((a, b) => a.package.localeCompare(b.package));
  assert.deepEqual(probeTable, table, 'Doctor and the uncached online Expo dependency check disagree');
  // The individual check completions run concurrently, so their order can
  // differ. All other Doctor output must match, including warnings and advice.
  const diagnostics = output.split('\n').filter(line => !/^(✔|✖) /.test(line)).map(line => line.trimEnd()).join('\n').trim();
  return { status, checks: [...checks].sort(([a], [b]) => a.localeCompare(b)), table: table.sort((a, b) => a.package.localeCompare(b.package)), diagnostics };
}
// Prime the pinned package once so an npm installation notice cannot make the
// first Doctor result differ from the second purely because its cache was cold.
assert.match(run('npx', ['--yes', pin, '--version'], candidate, env).output, /1\.21\.8/);
const candidateDoctor = doctor(candidate, 'OTA candidate');
if (candidateDoctor.status === 0) {
  console.log('The full online Expo Doctor check passed. Native build and release checks still apply.');
  process.exit(0);
}
// The public HTTPS marker fixes which native source this comparison means. Its
// top-level metadata is not a substitute for the signed release-plan check.
const markerResponse = await fetch(markerUrl, { signal: AbortSignal.timeout(15_000), cache: 'no-store' });
assert(markerResponse.ok, `Native release marker is unavailable: ${markerResponse.status}`);
const marker = await markerResponse.json();
assert.equal(marker.type, 'native');assert.equal(marker.track, 'production');assert.equal(marker.version, '1.0.0');
assert.equal(marker.gitSha, baselineSha, 'Native marker source does not match the reviewed baseline');
assert.equal(marker.platforms?.android?.fingerprint, 'f420573d90cfc47c076e042ca47ae668e0da629cfeea9e242b3f6e4ac5a93348');
assert.equal(marker.platforms?.ios?.fingerprint, '0af0b2aefd4d599a5d716443f938e5c37171c2a6340a9f9c6c2192bfb2b54ad2');
const baselineDoctor = doctor(baseline, 'native baseline');
assert.deepEqual(candidateDoctor, baselineDoctor, 'Doctor results or diagnostics differ from the released native baseline');

function fingerprint(cwd, platform) {
  const path = join(cwd, 'node_modules/@expo/fingerprint/bin/cli.js');
  const fingerprintEnv = {
    ...env,
    CK_APP_VERSION: '0.0.0', CK_BUILD_NUMBER: '1', CK_RELEASE_TRACK: 'production',
    CK_RUNTIME_VERSION: 'native-fingerprint-input', CK_ENABLE_UPDATES: 'true',
    CK_UPDATES_CERTIFICATE_PATH: certificate,
  };
  const result = JSON.parse(run(process.execPath, [path, 'fingerprint:generate', '--platform', platform], cwd, fingerprintEnv).output);
  assert.match(result.hash ?? '', /^[a-f0-9]+$/, 'Invalid Expo fingerprint');
  assert(Array.isArray(result.sources), 'Fingerprint sources missing');
  const packages = result.sources.filter(source => source.type === 'package')
    .map(({ filePath, version, hash }) => ({ filePath, version, hash }))
    .sort((a, b) => a.filePath.localeCompare(b.filePath));
  assert(packages.length > 0 && packages.every(item => item.filePath && item.version && item.hash), 'Native package source information missing');
  return { hash: result.hash, packages };
}
for (const platform of ['android', 'ios']) {
  const old = fingerprint(baseline, platform);
  const current = fingerprint(candidate, platform);
  assert.deepEqual(current, old, `${platform} native fingerprint or package source changed`);
  console.log(`${platform}: matching Expo fingerprint ${current.hash}; ${current.packages.length} matching native package sources`);
}
console.log(`Both complete online Doctor runs match; ${candidateDoctor.table.length} identical patch recommendations remain.`);
console.log('This comparison does not replace the authenticated native marker and embedded production certificate checks.');
