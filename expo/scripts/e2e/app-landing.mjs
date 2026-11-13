// HTTP end-to-end checks against the built landing running in Wrangler Pages.
// Uses a real public post; does not mock the API or mutate any environment.
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
const origin = process.env.CK_LANDING_E2E_ORIGIN ?? 'http://127.0.0.1:8792';
assert(
  ['127.0.0.1', 'localhost'].includes(new URL(origin).hostname),
  'Run against a local Pages worker',
);
const postId = process.env.CK_LANDING_E2E_POST_ID;
assert(postId, 'Set CK_LANDING_E2E_POST_ID to a currently published post');
const root = await fetch(origin);
assert.equal(root.status, 200);
const home = await root.text();
assert(home.includes('property="og:title"'));
assert(home.includes('property="og:image"'));
assert(home.includes('href="https://apps.apple.com/'));
assert(home.includes('href="https://play.google.com/'));
const response = await fetch(`${origin}/posts/${encodeURIComponent(postId)}?token=must-not-leak`);
assert.equal(response.status, 200);
assert.equal(response.headers.get('cache-control'), 'no-store');
const post = await response.text();
assert.equal((post.match(/property="og:title"/g) ?? []).length, 1);
assert.equal((post.match(/property="og:description"/g) ?? []).length, 1);
assert(post.includes(`https://app.clashk.ing/share/posts/${postId}`));
assert(post.includes(`href="clashking:///posts/${postId}"`));
assert(!post.includes('must-not-leak'));
const shared = await fetch(`${origin}/share/posts/${encodeURIComponent(postId)}`);
assert.equal(shared.status, 200);
const sharedHtml = await shared.text();
assert(sharedHtml.includes('class="app-banner"'));
assert(!sharedHtml.includes('/landing/open-app.js'));
assert(sharedHtml.includes('name="twitter:image"'));
if (process.env.CK_EXPECTED_POST_IMAGE_URL) {
  assert(
    sharedHtml.includes(`property="og:image" content="${process.env.CK_EXPECTED_POST_IMAGE_URL}"`),
  );
}
if (sharedHtml.includes('id="story"')) {
  assert(sharedHtml.includes('sandbox="allow-scripts"'));
  const story = await fetch(`${origin}/share/posts/${encodeURIComponent(postId)}/story`);
  assert.equal(story.status, 200);
  assert.match(story.headers.get('content-security-policy'), /sandbox allow-scripts/);
  const html = await story.text();
  assert(html.includes('__clashkingStoryContentFit'));
  assert(html.includes('parent.postMessage'));
  for (const locale of ['fr', 'nl', 'ar']) {
    const catalog = JSON.parse(
      await readFile(new URL(`../../src/i18n/arb/app_${locale}.arb`, import.meta.url), 'utf8'),
    );
    const response = await fetch(`${origin}/share/posts/${encodeURIComponent(postId)}`, {
      headers: { 'Accept-Language': `${locale},en;q=0.8` },
    });
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('content-language'), locale);
    const localized = await response.text();
    assert(localized.includes(`<html lang="${locale}"`));
    assert(localized.includes(catalog.postsStoryFinished));
    assert(localized.includes(catalog.postsWatchAgain));
    assert(localized.includes(catalog.generalOpen));
    if (locale === 'ar') assert(localized.includes('dir="rtl"'));
  }
}
if (process.env.CK_LANDING_E2E_ARTICLE_ID) {
  const article = await fetch(
    `${origin}/share/posts/${encodeURIComponent(process.env.CK_LANDING_E2E_ARTICLE_ID)}`,
  );
  assert.equal(article.status, 200);
  const html = await article.text();
  assert(html.includes('<article>'));
  assert(!html.includes('id="story"'));
  assert(!html.includes('/landing/open-app.js'));
  assert(html.includes('class="app-banner"'));
}
const missing = await fetch(`${origin}/posts/nonexistent`);
assert.equal(missing.status, 404);
assert((await missing.text()).includes('name="robots" content="noindex"'));
assert.equal((await fetch(`${origin}/posts/%3Cscript%3E`)).status, 404);
assert.equal((await fetch(`${origin}/posts/${postId}`, { method: 'POST' })).status, 405);
const head = await fetch(`${origin}/posts/${postId}`, { method: 'HEAD' });
assert.equal(head.status, 200);
assert.equal(await head.text(), '');
assert.equal((await fetch(`${origin}/.well-known/apple-app-site-association`)).status, 200);
console.log(
  'PASS: local Pages root, stores, web post, canonical/image metadata, sandboxed story, unavailable/invalid post, method, HEAD, association file',
);
