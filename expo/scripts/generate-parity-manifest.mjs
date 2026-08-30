import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { isParitySourcePath, paritySourceFingerprint } from './parity-source-fingerprint.mjs';

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const expoRoot = resolve(scriptDirectory, '..');
const repositoryRoot = resolve(expoRoot, '..');
const manifestPath = resolve(expoRoot, 'docs/parity-manifest.json');
const overridesPath = resolve(expoRoot, 'docs/parity-overrides.json');

const tracked = execFileSync('git', ['ls-files'], {
  cwd: repositoryRoot,
  encoding: 'utf8',
})
  .split('\n')
  .map((value) => value.trim())
  .filter(Boolean)
  .filter(isParitySourcePath)
  .sort((left, right) => left.localeCompare(right));

const sourceCommit = execFileSync('git', ['rev-parse', 'HEAD'], {
  cwd: repositoryRoot,
  encoding: 'utf8',
}).trim();
const checkMode = process.argv.includes('--check');
const currentManifest = checkMode ? JSON.parse(readFileSync(manifestPath, 'utf8')) : undefined;
const sourceTreeSha256 = paritySourceFingerprint(repositoryRoot, tracked);

const overrides = JSON.parse(readFileSync(overridesPath, 'utf8'));
const areaOverrides = overrides.$areas ?? {};
const entries = tracked.map((source) => {
  const area = classify(source);
  return {
    source,
    area,
    disposition: 'port',
    status: 'pending',
    target: suggestedTarget(source),
    notes: '',
    evidence: [],
    ...(areaOverrides[area] ?? {}),
    ...(overrides[source] ?? {}),
  };
});

for (const source of Object.keys(overrides)) {
  if (source === '$areas') continue;
  if (!tracked.includes(source)) {
    throw new Error(`Parity override references an untracked source: ${source}`);
  }
}

const knownAreas = new Set(tracked.map(classify));
for (const area of Object.keys(areaOverrides)) {
  if (!knownAreas.has(area)) {
    throw new Error(`Parity area override references an unknown area: ${area}`);
  }
}

const manifest = `${JSON.stringify(
  {
    schemaVersion: 2,
    sourceCommit: currentManifest?.sourceCommit ?? sourceCommit,
    sourceTreeSha256,
    sourceRoot: relative(repositoryRoot, repositoryRoot) || '.',
    counts: entries.reduce(
      (result, entry) => {
        result.total += 1;
        result.byArea[entry.area] = (result.byArea[entry.area] ?? 0) + 1;
        result.byStatus[entry.status] = (result.byStatus[entry.status] ?? 0) + 1;
        return result;
      },
      { total: 0, byArea: {}, byStatus: {} },
    ),
    entries,
  },
  null,
  2,
)}\n`;

if (checkMode) {
  const current = readFileSync(manifestPath, 'utf8');
  if (current !== manifest) {
    throw new Error('Parity manifest is stale. Run npm run parity:generate.');
  }
} else {
  writeFileSync(manifestPath, manifest);
}

function classify(path) {
  if (path.startsWith('lib/features/')) return `feature:${path.split('/')[2]}`;
  if (path.startsWith('lib/common/')) return 'shared-ui';
  if (path.startsWith('lib/core/')) return 'core';
  if (path.startsWith('lib/l10n/')) return 'localization';
  if (path.startsWith('lib/widgets/')) return 'native-widgets';
  if (path === 'lib/main.dart') return 'bootstrap';
  if (path.startsWith('ios/')) return 'native:ios';
  if (path.startsWith('android/')) return 'native:android';
  if (path.startsWith('web/')) return 'web';
  if (path.startsWith('test/') || path.startsWith('e2e/')) return 'verification';
  if (path.startsWith('assets/') || path.startsWith('fonts/')) return 'assets';
  if (path.startsWith('docs/') || path.startsWith('design-system/')) return 'design';
  if (path.startsWith('.github/workflows/')) return 'delivery';
  return 'configuration';
}

function suggestedTarget(path) {
  if (path.startsWith('lib/features/')) {
    return `expo/src/features/${path.split('/')[2]}/`;
  }
  if (path.startsWith('lib/common/')) return 'expo/src/ui/';
  if (path.startsWith('lib/core/')) return 'expo/src/core/';
  if (path.startsWith('lib/l10n/')) return 'expo/src/i18n/';
  if (path.startsWith('ios/')) return 'expo/ios/ or expo/modules/';
  if (path.startsWith('android/')) return 'expo/android/ or expo/modules/';
  if (path.startsWith('web/')) return 'expo/public/ or expo/src/app/';
  if (path.startsWith('test/') || path.startsWith('e2e/'))
    return 'expo/src/**/__tests__/ or expo/e2e/';
  if (path.startsWith('assets/') || path.startsWith('fonts/')) return 'expo/assets/';
  return 'expo/';
}
