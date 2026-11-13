// HTTP end-to-end checks against the built landing running in Wrangler Pages.
// Uses a real public post; does not mock the API or mutate any environment.
import assert from 'node:assert/strict';
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
assert(post.includes(`https://app.clashk.ing/posts/${postId}`));
assert(post.includes(`href="clashking:///posts/${postId}"`));
assert(!post.includes('must-not-leak'));
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
  'PASS: local Pages root, stores, published post, canonical metadata, unavailable/invalid post, method, HEAD, association file',
);
