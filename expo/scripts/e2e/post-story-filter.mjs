// Actual Worker HTTP against a disposable Goose-migrated database. No mocks.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { createRequire } from 'node:module';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { once } from 'node:events';
const apiRoot = process.env.CLASHKING_E2E_API_REPO;
assert(apiRoot, 'CLASHKING_E2E_API_REPO must identify the local API checkout');
const requireApi = createRequire(join(apiRoot, 'package.json'));
const pg = requireApi('pg');
const { build } = requireApi('esbuild');
const buildDir = mkdtempSync(join(tmpdir(), 'ck-app-posts-'));
assert.equal(process.env.CLASHKING_DISPOSABLE_TIMESCALE, '1');
const dsn = new URL(process.env.TEST_DATABASE_URL);
assert.equal(dsn.hostname, '127.0.0.1');
assert.equal(dsn.pathname, '/clashking_test');
const db = new pg.Client({ connectionString: dsn.href });
await db.connect();
const port = 8826, origin = `http://127.0.0.1:${port}`;
let logs = '';
const child = spawn(process.execPath, ['scripts/start-local-rewrite-api.mjs'], {
  cwd: apiRoot, stdio: ['ignore', 'pipe', 'pipe'], env: { ...process.env,
    CLASHKING_LOCAL_API_PORT: String(port), CLASHKING_LOCAL_ADMIN_IDENTITY: '0',
    CLASHKING_LOCAL_DISCORD_CLIENT_ID: '999999999999999999',
    CLASHKING_LOCAL_DISCORD_CLIENT_SECRET: 'fixture', CLASHKING_LOCAL_ARCHIVE_BRIDGE: '0',
    CLASHKING_LOCAL_PRODUCTION_READS: '0', CLASHKING_LOCAL_FCM_CREDENTIALS_FILE: '',
  },
});
child.stdout.on('data', (chunk) => logs += chunk);
child.stderr.on('data', (chunk) => logs += chunk);
const ids = [];
const seed = async (title, type, minute, status = 'live', platforms = ['ios', 'android'], legacy = false) => {
  const id = randomUUID(); ids.push(id);
  await db.query(`INSERT INTO admin_posts(id,slug,title,summary,presentation_type,story_url,status,platforms,published_at)
    VALUES($1::uuid,$1::text,$2,'Fixture summary',$3,$4,$5,$6,$7)`,
  [id, title, type, type === 'story' || legacy ? 'https://posts.clashk.ing/fixture.html' : null,
    status, platforms, new Date(Date.now() - minute * 60000)]);
  return id;
};
try {
  let ready = false;
  for (let i = 0; i < 120; i++) {
    if (child.exitCode !== null) throw Error(logs.slice(-1800));
    try { ready = (await fetch(origin + '/v2/health')).ok && logs.includes('isolated_api_ready'); } catch {}
    if (ready) break;
    await new Promise((resolve) => setTimeout(resolve, 250));
  }
  assert(ready, logs.slice(-1800));
  for (let i = 0; i < 25; i++) await seed(`Article ${i}`, 'article', i);
  const expected = [];
  for (let i = 0; i < 7; i++) expected.push(await seed(`Story ${i}`, 'story', 30 + i));
  const legacy = await seed('Legacy story', 'article', 37, 'live', ['ios', 'android'], true);
  const draft = await seed('Draft story', 'story', 0, 'draft');
  await seed('Android only', 'story', 1, 'live', ['android']);
  const output = join(buildDir, 'check.mjs');
  await build({
    stdin: {
      resolveDir: process.cwd(), loader: 'ts',
      contents: `
        import assert from 'node:assert/strict';
        import { createApiClient, httpTransport } from '@clashking/api-client';
        import { AnnouncementService } from './src/features/home/data/announcement-service';
        const client = createApiClient({ baseUrl: process.env.CLASHKING_E2E_BASE_URL, transport: httpTransport(fetch) });
        const service = new AnnouncementService(client, 'ios', () => 'en');
        const expected = JSON.parse(process.env.CLASHKING_E2E_EXPECTED);
        const first = await service.getPublishedPosts(5, 0, 'story');
        assert.deepEqual(first.items.map(item => item.id), expected.slice(0, 5));
        assert(first.items.every(item => item.isStory));
        assert.equal(first.hasMore, true); assert.equal(first.nextOffset, 5);
        const next = await service.getPublishedPosts(5, 5, 'story');
        assert.deepEqual(next.items.map(item => item.id), [...expected.slice(5), process.env.CLASHKING_E2E_LEGACY]);
        assert.equal(next.hasMore, false);
        assert(next.items.every(item => item.isStory));
        const articles = await service.getPublishedPosts(50, 0, 'article');
        assert.equal(articles.items.length, 25);
        assert(articles.items.every(item => !item.isStory));
        const combined = await service.getPublishedPosts(50);
        assert.equal(combined.items.length, 33);
        assert(!combined.items.some(item => item.id === process.env.CLASHKING_E2E_DRAFT));
        console.log('PASS App AnnouncementService -> installed API client -> local Worker/Timescale: newest five stories past 25 articles, pagination, legacy story, platform and draft exclusion, mixed-feed compatibility');
      `,
    },
    outfile: output, bundle: true, platform: 'node', format: 'esm', logLevel: 'silent',
  });
  const check = spawn(process.execPath, [output], {
    stdio: 'inherit', env: { ...process.env, CLASHKING_E2E_BASE_URL: origin + '/v2',
      CLASHKING_E2E_EXPECTED: JSON.stringify(expected), CLASHKING_E2E_LEGACY: legacy,
      CLASHKING_E2E_DRAFT: draft },
  });
  const [code] = await once(check, 'exit');
  assert.equal(code, 0);

} finally {
  await db.query('DELETE FROM admin_posts WHERE id=ANY($1::uuid[])', [ids]);
  child.kill('SIGTERM'); await db.end();
  rmSync(buildDir, { recursive: true, force: true });
}
