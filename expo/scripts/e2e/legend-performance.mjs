// Headless end-to-end data-path check. Run from the API's disposable fixture
// via CLASHKING_E2E_APP_REPO; never connects to a public service or mocks HTTP.
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
assert(apiRoot, 'The disposable API harness must supply its repository path');
const { build } = createRequire(join(apiRoot, 'package.json'))('esbuild');
const directory = mkdtempSync(join(tmpdir(), 'ck-legend-app-'));
try {
  const output = join(directory, 'check.mjs');
  await build({
    stdin: {
      resolveDir: root,
      loader: 'ts',
      contents: `
    import assert from 'node:assert/strict';
    import { createApiClient, httpTransport } from '@clashking/api-client';
    import { StatsRepository } from './src/features/stats/data/stats-repository';
    import { aggregateChartSeries } from './src/features/stats/presentation/chart-aggregation';
    import { StatsDateFilter, StatsLegendQuery, StatsLegendCohort } from './src/features/stats/models';
    let requests = 0;
    const api = createApiClient({ baseUrl: process.env.CLASHKING_E2E_BASE_URL, transport: httpTransport((...args) => {
      requests++; return fetch(...args);
    }) });
    const repository = new StatsRepository(api);
    const dates = new StatsDateFilter(new Date(process.env.CLASHKING_E2E_FIRST_DAY + 'T12:00:00'), new Date(process.env.CLASHKING_E2E_LAST_DAY + 'T12:00:00'));
    const query = new StatsLegendQuery(dates, StatsLegendCohort.legend);
    const data = await repository.loadLegendPerformance(query);
    assert.equal(data.periods[0].offense.perfectDayRate, 2 / 3);
    assert.equal(data.periods[0].perfectOffensePlayers, 1);
    assert.equal(data.periods[0].availableDays, 2);
    assert.equal(data.periods[0].expectedDays, 3);
    assert.equal(data.items.length, 2);
    const trend = aggregateChartSeries([{key:'mean',label:'mean',aggregation:'weightedMean',points:data.items.map(item=>({day:item.day,value:item.offense.meanTrophies,weight:item.offense.completePlayerDays}))}], 'week', false)[0].points;
    const trendMean = trend.reduce((sum,p)=>sum+(p.value??0)*(p.weight??0),0)/trend.reduce((sum,p)=>sum+(p.weight??0),0);
    assert.equal(trendMean,640/3,'Weekly averages must preserve player-day weights');
    assert.strictEqual(await repository.loadLegendPerformance(query), data);
    assert.equal(requests, 1, 'The repository should reuse the completed response');
    const top = await repository.loadLegendPerformance(new StatsLegendQuery(dates, StatsLegendCohort.top200));
    assert.equal(top.periods[0].offense.completePlayerDays, 1);
    assert.notStrictEqual(await repository.loadLegendPerformance(query, true), data);
    assert.equal(requests, 3, 'Explicit refresh should reach the actual API');
    console.log('PASS: app StatsRepository -> vendored typed client -> real local Worker/Timescale; ranges, cohorts, coverage, cache and refresh');
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
