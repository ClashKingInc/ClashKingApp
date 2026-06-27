import { test as setup, request } from '@playwright/test';
import path from 'path';
import fs from 'fs';

const AUTH_FILE = path.join(__dirname, '../playwright/.auth/user.json');
// API host the app talks to. Defaults to prod (go.api.clashk.ing) so CI works
// against the deployed app; override with API_BASE_URL in .env for local runs
// (e.g. http://127.0.0.1:8000).
const API_BASE = (process.env.API_BASE_URL ?? 'https://go.api.clashk.ing').replace(/\/+$/, '');

setup('authenticate with email', async ({ page }) => {
  const email = process.env.TEST_EMAIL;
  const password = process.env.TEST_PASSWORD;
  // Skip gracefully when credentials are not provided (e.g. fork PRs without secrets access).
  // This also skips all chromium-auth tests that depend on this setup.
  setup.skip(!email || !password, 'TEST_EMAIL / TEST_PASSWORD not set — skipping authenticated tests');

  setup.setTimeout(60_000);

  // ── Direct API login (bypass Flutter form to avoid keyboard-layout issues) ─
  // pressSequentially('@') sends the wrong character on AZERTY layouts,
  // making the Flutter form unreliable. A direct POST is faster and correct.
  // Trim credentials: .env on Windows may have \r\n line endings, leaving a
  // trailing \r that bcrypt sees as part of the password → 401.
  const apiContext = await request.newContext({ baseURL: API_BASE });
  let capturedTokens: { access_token: string; refresh_token: string } | null = null;
  try {
    const resp = await apiContext.post('/v2/auth/email', {
      headers: { 'Content-Type': 'application/json' },
      data: JSON.stringify({
        email: email!.trim(),
        password: password!.trim(),
        device_id: 'playwright-setup',
        device_name: 'Playwright E2E',
      }),
    });
    console.log(`[auth.setup] API → ${resp.status()}`);
    if (resp.ok()) {
      const json = await resp.json();
      if (json?.access_token && json?.refresh_token) {
        capturedTokens = { access_token: json.access_token, refresh_token: json.refresh_token };
        console.log('[auth.setup] tokens captured ✓');
      } else {
        console.warn(`[auth.setup] unexpected response shape: ${JSON.stringify(json).slice(0, 200)}`);
      }
    } else {
      const body = await resp.text().catch(() => '<unreadable>');
      console.warn(`[auth.setup] API returned ${resp.status()}: ${body.slice(0, 200)}`);
    }
  } finally {
    await apiContext.dispose();
  }

  if (!capturedTokens) {
    console.warn('[auth.setup] tokens not captured — chromium-auth tests will be skipped');
    // Include the app origin so Playwright's BrowserContext initialises correctly.
    // An empty origins array causes "Cannot navigate to invalid URL" in dependent tests.
    const baseURL = (process.env.BASE_URL ?? 'http://localhost:5000').trim();
    fs.mkdirSync(path.dirname(AUTH_FILE), { recursive: true });
    fs.writeFileSync(AUTH_FILE, JSON.stringify({
      cookies: [],
      origins: [{ origin: baseURL, localStorage: [] }],
    }));
    return;
  }

  // ── Write tokens to localStorage in SharedPreferences format ──────────────
  // shared_preferences_web stores String values as JSON.stringify(value) under
  // the key 'flutter.<prefKey>'. Flutter's _readTokens() fallback reads from
  // SharedPreferences and migrates tokens to SecureStorage on first run in
  // each fresh browser context.
  await page.goto('/');
  await page.evaluate(({ at, rt }) => {
    localStorage.setItem('flutter.access_token', JSON.stringify(at));
    localStorage.setItem('flutter.refresh_token', JSON.stringify(rt));
  }, { at: capturedTokens.access_token, rt: capturedTokens.refresh_token });

  // ── Save storageState (now includes the localStorage tokens) ─────────────
  fs.mkdirSync(path.dirname(AUTH_FILE), { recursive: true });
  await page.context().storageState({ path: AUTH_FILE });
  console.log(`[auth.setup] storageState saved → ${AUTH_FILE}`);
});
