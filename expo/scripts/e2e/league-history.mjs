// Actual Expo loader -> vendored typed API client -> local Worker/Timescale.
// The API disposable fixture owns the stored observations and service lifetime.
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import { once } from 'node:events';

const root = resolve(fileURLToPath(new URL('../../', import.meta.url)));
const origin = new URL(process.env.CLASHKING_E2E_BASE_URL ?? '');
assert.equal(origin.hostname, '127.0.0.1');
assert.equal(process.env.CLASHKING_DISPOSABLE_TIMESCALE, '1');
const apiRoot = process.env.CLASHKING_E2E_API_REPO;
assert(apiRoot);
const { build } = createRequire(join(apiRoot, 'package.json'))('esbuild');
const directory = mkdtempSync(join(tmpdir(), 'ck-league-app-'));
try {
  const output = join(directory, 'check.mjs');
  await build({
    stdin: {
      resolveDir: root,
      loader: 'ts',
      contents: `
        import assert from 'node:assert/strict';
        import { createApiClient, httpTransport } from '@clashking/api-client';
        import { readPlayerLegendHistory } from './src/features/player/data/player-legend-history';
        import { legendHistoryBadge, formatLegendHistorySeason } from './src/features/legends/presentation/legend-history-presentation';
        const paths: string[] = [];
        const api = createApiClient({ baseUrl: process.env.CLASHKING_E2E_BASE_URL, transport: httpTransport((request) => {
          paths.push(new URL(request.url).pathname); return fetch(request);
        }) });
        const items = await readPlayerLegendHistory(api, process.env.CLASHKING_E2E_HISTORY_TAG!);
        assert.equal(items.length, 9);
        assert.equal(items[0].season, 'v2-2026-10-26T05:00:00Z');
        assert.equal(items[0].leagueName, 'Original Legend I');
        assert.equal(items[0].leagueNamespace, 'tier');
        assert.equal(items[0].leagueIconUrls?.medium, 'https://source.example/original-medium.png');
        assert.deepEqual(legendHistoryBadge(items[0]), {kind:'source', imageUrl:'https://source.example/original-medium.png'});
        assert.equal(items[0].population, 17);
        assert.equal(items[0].seasonStart?.toISOString(), '2026-09-28T05:00:00.000Z');
        const legacy = items.find(item => item.season === '2023-03')!;
        assert.equal(legacy.leagueId, 29000022);
        assert.equal(legacy.leagueName, 'Original Legend League');
        assert.equal(legacy.leagueNamespace, 'legacy');
        const unknown = items.find(item => item.season === '2024-03-25')!;
        assert.equal(unknown.leagueId, null);
        assert.equal(unknown.leagueName, null);
        assert.equal(unknown.seasonStart, null);
        assert.equal(unknown.seasonEnd, null);
        assert.equal(legendHistoryBadge(unknown), null);
        assert.equal(formatLegendHistorySeason(unknown, 'en-US'), '2024-03-25');
        const recentUnknown = items.find(item => item.season === 'v2-2026-08-31T05:00:00Z')!;
        assert.equal(legendHistoryBadge(recentUnknown), null, 'Recent unknown history must not invent Legend I');
        const namedTier = items.find(item => item.season === 'v2-2026-07-06T05:00:00Z')!;
        assert.deepEqual(legendHistoryBadge(namedTier), {kind:'tier', name:'Legend League II'});
        assert.notEqual(formatLegendHistorySeason(items[0], 'en-US'), items[0].season);
        assert.equal(paths.length, 1);
        assert(paths[0].endsWith('/legend-history'));
        assert(!paths.some(path => path.endsWith('/league/history')));
        console.log('PASS Expo shared Legend loader -> rc63 Legend alias -> real API: original tier/legacy labels, nullable metadata and raw-season boundaries');
      `,
    },
    outfile: output,
    bundle: true,
    platform: 'node',
    format: 'esm',
    logLevel: 'silent',
  });
  const child = spawn(process.execPath, [output], { stdio: 'inherit', env: process.env });
  const [code] = await once(child, 'exit');
  assert.equal(code, 0);
} finally {
  rmSync(directory, { recursive: true, force: true });
}
