// Headless application flow: import account bytes, persist to real files, reopen
// the repository, and build the same summaries/plan used by the native tracker.
// No native UI, mocked HTTP, or production writes are involved.
import { createRequire } from 'node:module';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { spawnSync } from 'node:child_process';
import assert from 'node:assert/strict';

const root = resolve(import.meta.dirname, '../..');
const staticPath = process.env.CLASHKING_E2E_STATIC_DATA;
assert(staticPath, 'Set CLASHKING_E2E_STATIC_DATA to the authoritative static_data.json');
const apiRoot = process.env.CLASHKING_E2E_API_REPO;
assert(apiRoot, 'Set CLASHKING_E2E_API_REPO to the API checkout that supplies esbuild');
const { build } = createRequire(join(apiRoot, 'package.json'))('esbuild');
const work = mkdtempSync(join(tmpdir(), 'ck-crafted-import-'));
try {
  const output = join(work, 'flow.mjs');
  await build({
    stdin: {
      resolveDir: root,
      loader: 'ts',
      contents: `
import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { join } from 'node:path';
import { createApiClient, httpTransport } from '@clashking/api-client';
import { UpgradeTrackerRepository } from './src/features/upgrade-tracker/data/upgrade-tracker-repository';
import { UpgradeCategory, UpgradeQueue, UpgradeVillage, UpgradePlanPreferences } from './src/features/upgrade-tracker/models';
import { filteredUpgradeItems, groupUpgradeItems, buildTrackerPlanData } from './src/features/upgrade-tracker/presentation/upgrade-tracker-logic';
import { ongoingUpgradeQueues } from './src/features/upgrade-tracker/models/ongoing-upgrade-queues';
import { applyGameDataBundle } from './src/core/game-data/game-data-normalization';
const bundle = JSON.parse(await readFile(process.env.CLASHKING_E2E_STATIC_DATA!, 'utf8'));
applyGameDataBundle(bundle);
const station = bundle.buildings.find((item: any) => item._id === 1000097);
const townHall = bundle.buildings.find((item: any) => item.name === 'Town Hall');
assert.deepEqual(station.levels, [], 'Fixture must exercise the level-less station');
const families = station.seasonal_defenses.filter((item: any) => item.modules.length).slice(0, 2);
assert.equal(families.length, 2);
const tag = '#P0LYQ';
const now = new Date();
const raw = { tag, name: 'Crafted defense import', timestamp: Math.floor(now.getTime()/1000), buildings: [
  {data: townHall._id, lvl: 19},
  {data: station._id, lvl: 0, types: families.map((family: any, index: number) => ({
    data: family._id,
    modules: family.modules.map((module: any, moduleIndex: number) => ({data:module._id, lvl:1, ...(index === 0 && moduleIndex === 0 ? {timer:3600} : {})}))
  }))}
] };
const directory = process.env.CK_CRAFTED_DISK!;
await mkdir(directory, {recursive:true});
// A real disk adapter exercises persisted JSON rather than an in-memory mock.
const disk = {
  async getItem(key: string) { try {return await readFile(join(directory, encodeURIComponent(key)), 'utf8');} catch (error: any) {if(error.code === 'ENOENT') return null; throw error;} },
  async setItem(key: string, value: string) {await writeFile(join(directory, encodeURIComponent(key)), value);},
  async removeItem(key: string) {const {rm} = await import('node:fs/promises'); await rm(join(directory, encodeURIComponent(key)), {force:true});}
};
const api = createApiClient({baseUrl:'http://127.0.0.1:1', transport:httpTransport(fetch)});
const repository = new UpgradeTrackerRepository(api, disk, undefined, () => bundle);
const imported = await repository.importSnapshotBytes(new TextEncoder().encode(JSON.stringify(raw)), {allowedTags:new Set([tag])});
const reopened = new UpgradeTrackerRepository(api, disk, undefined, () => bundle);
const restored = await reopened.load(tag);
assert(restored);
for (const snapshot of [imported, restored]) {
  const crafted = snapshot.items.filter(item => item.category === UpgradeCategory.craftedDefenses);
  assert.equal(crafted.length, families.reduce((n: number, family: any) => n + family.modules.length, 0), 'Every nested module survives import and reload');
  assert.equal(new Set(crafted.map(item => item.parentName)).size, 2, 'Families remain separate nested types');
  assert(!snapshot.items.some(item => item.id === station._id), 'The level-less container stays hidden');
  assert(crafted.every(item => item.queue === UpgradeQueue.builders && item.levelsRemaining > 0));
  const visible = groupUpgradeItems(filteredUpgradeItems(snapshot, UpgradeVillage.home, '', false));
  assert(visible.some(([category, items]) => category === UpgradeCategory.craftedDefenses && items.length === crafted.length));
  assert(snapshot.summaryFor(UpgradeCategory.craftedDefenses).levelsRemaining > 0);
  assert.equal(ongoingUpgradeQueues(snapshot, UpgradeVillage.home, now).find(item => item.queue === UpgradeQueue.builders)?.used, 1);
  const plan = buildTrackerPlanData(snapshot, 0, new UpgradePlanPreferences(), now);
  assert(plan.upgrades.some(upgrade => upgrade.item.category === UpgradeCategory.craftedDefenses), 'Planner includes restored modules');
}
console.log('PASS actual tracker import → file persistence → fresh repository load → category summary, nested families, builder timer and planner');
`,
    },
    outfile: output,
    bundle: true,
    platform: 'node',
    format: 'esm',
    define: { __DEV__: 'false' },
    logLevel: 'silent',
  });
  const child = spawnSync(process.execPath, [output], {
    stdio: 'inherit',
    env: { ...process.env, CK_CRAFTED_DISK: join(work, 'storage') },
  });
  assert.equal(child.status, 0, 'Tracker import flow failed');
} finally {
  rmSync(work, { recursive: true, force: true });
}
