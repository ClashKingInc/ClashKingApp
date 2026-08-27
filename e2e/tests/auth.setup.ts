import { test as setup, request } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import { createE2eEmail, getOtpInboxConfig, waitForOtp } from './otp-inbox';

const AUTH_FILE = path.join(__dirname, '../playwright/.auth/user.json');
const TEMPORARY_ACCOUNT_FILE = path.join(__dirname, '../playwright/.auth/temporary-account');
// API host the app talks to. Defaults to the canonical production v2 host
// against the deployed app; override with API_BASE_URL in .env for local runs
// (e.g. http://127.0.0.1:8000).
const API_BASE = (process.env.API_BASE_URL ?? 'https://v2-api.clashk.ing').replace(/\/+$/, '');

setup('authenticate with email', async () => {
  fs.rmSync(TEMPORARY_ACCOUNT_FILE, { force: true });
  const email = process.env.TEST_EMAIL;
  const password = process.env.TEST_PASSWORD;
  // Skip gracefully when credentials are not provided (e.g. fork PRs without secrets access).
  // This also skips all chromium-auth tests that depend on this setup.
  const canProvisionAccount = getOtpInboxConfig() !== null;
  setup.skip(
    (!email || !password) && !canProvisionAccount,
    'No static credentials or Cloudflare OTP inbox — skipping authenticated tests',
  );

  setup.setTimeout(90_000);

  // ── Direct API login (bypass Flutter form to avoid keyboard-layout issues) ─
  // pressSequentially('@') sends the wrong character on AZERTY layouts,
  // making the Flutter form unreliable. A direct POST is faster and correct.
  // Trim credentials: .env on Windows may have \r\n line endings, leaving a
  // trailing \r that bcrypt sees as part of the password → 401.
  const baseURL = (process.env.BASE_URL ?? 'https://app.clashk.ing').trim();
  const origin = (() => { try { return new URL(baseURL).origin; } catch { return baseURL; } })();
  const apiContext = await request.newContext({ baseURL: API_BASE });
  let capturedAccessToken: string | null = null;
  let capturedCookies: Awaited<ReturnType<typeof apiContext.storageState>>['cookies'] = [];
  let temporaryAccountCreated = false;
  try {
    // Use the fixed account first so linked-account coverage remains active.
    // Provision a disposable account only when credentials are unavailable or
    // the fixed account can no longer authenticate.
    if (email && password) {
      const resp = await apiContext.post('/v2/auth/web/email', {
        headers: { 'Content-Type': 'application/json', Origin: origin },
        data: JSON.stringify({
          email: email.trim(),
          password: password.trim(),
          device_id: 'playwright-setup',
          device_name: 'Playwright E2E',
        }),
      });
      console.log(`[auth.setup] static account API → ${resp.status()}`);
      if (resp.ok()) {
        const json = await resp.json();
        if (typeof json?.access_token === 'string' && json.access_token) {
          capturedAccessToken = json.access_token;
          console.log('[auth.setup] static account tokens captured ✓');
        }
      }
    }

    if (!capturedAccessToken && canProvisionAccount) {
      const provisionedEmail = createE2eEmail('auth');
      const provisionedPassword = `E2e!${crypto.randomUUID()}Aa1`;
      const requestedAt = Date.now();
      const register = await apiContext.post('/v2/auth/register', {
        headers: { 'Content-Type': 'application/json' },
        data: JSON.stringify({
          email: provisionedEmail,
          password: provisionedPassword,
          username: `e2e_${Date.now()}`,
          device_id: 'playwright-setup',
          device_name: 'Playwright E2E',
        }),
      });
      if (!register.ok()) {
        throw new Error(`temporary account registration returned ${register.status()}`);
      }

      const registration: unknown = await register.json();
      const developmentCode =
        typeof registration === 'object' &&
        registration !== null &&
        'verification_code' in registration &&
        typeof registration.verification_code === 'string' &&
        /^\d{6}$/.test(registration.verification_code)
          ? registration.verification_code
          : null;
      const code = developmentCode ?? await waitForOtp(provisionedEmail, { notBefore: requestedAt });
      const verify = await apiContext.post('/v2/auth/web/verify-email-code', {
        headers: { 'Content-Type': 'application/json', Origin: origin },
        data: JSON.stringify({ email: provisionedEmail, code }),
      });
      if (!verify.ok()) {
        throw new Error(`temporary account verification returned ${verify.status()}`);
      }
      const json = await verify.json();
      if (typeof json?.access_token === 'string' && json.access_token) {
        capturedAccessToken = json.access_token;
        temporaryAccountCreated = true;
        console.log('[auth.setup] temporary verified account tokens captured ✓');
      }
    }
    if (capturedAccessToken) {
      capturedCookies = (await apiContext.storageState()).cookies;
      if (capturedCookies.length === 0) {
        throw new Error('web authentication did not issue a browser session cookie');
      }
    }
  } catch (err) {
    console.warn(`[auth.setup] API call threw: ${err}`);
    if (canProvisionAccount) throw err;
  } finally {
    await apiContext.dispose();
  }

  fs.mkdirSync(path.dirname(AUTH_FILE), { recursive: true });

  if (!capturedAccessToken) {
    console.warn('[auth.setup] tokens not captured — chromium-auth tests will run with empty auth');
    // Write a valid-but-empty state so Playwright can load the file.
    // Tests that need real auth will fail or skip on their own assertions.
    fs.writeFileSync(AUTH_FILE, JSON.stringify({
      cookies: [],
      origins: [{ origin, localStorage: [] }],
    }));
    return;
  }

  // ── Write tokens directly into the storageState JSON ─────────────────────
  // Browser auth uses an HttpOnly refresh cookie. Keep the access token in
  // localStorage only for teardown; the app obtains its own access token by
  // calling /auth/web/refresh with the saved cookie.
  fs.writeFileSync(AUTH_FILE, JSON.stringify({
    cookies: capturedCookies,
    origins: [{
      origin,
      localStorage: [
        { name: 'flutter.access_token', value: JSON.stringify(capturedAccessToken) },
      ],
    }],
  }));
  if (temporaryAccountCreated) fs.writeFileSync(TEMPORARY_ACCOUNT_FILE, 'created-by-playwright');
  console.log(`[auth.setup] storageState saved → ${AUTH_FILE}`);
});
