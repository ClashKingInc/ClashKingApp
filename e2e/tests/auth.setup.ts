import { test as setup, request } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import { createE2eEmail, getOtpInboxConfig, waitForOtp } from './otp-inbox';

const AUTH_FILE = path.join(__dirname, '../playwright/.auth/user.json');
const TEMPORARY_ACCOUNT_FILE = path.join(__dirname, '../playwright/.auth/temporary-account');
// API host the app talks to. Defaults to prod (go.api.clashk.ing) so CI works
// against the deployed app; override with API_BASE_URL in .env for local runs
// (e.g. http://127.0.0.1:8000).
const API_BASE = (process.env.API_BASE_URL ?? 'https://go.api.clashk.ing').replace(/\/+$/, '');

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
  let capturedTokens: { access_token: string; refresh_token: string } | null = null;
  let temporaryAccountCreated = false;
  try {
    // Prefer an isolated account that teardown can delete. Static credentials
    // remain a fallback for environments where the OTP inbox is unavailable.
    if (email && password && !canProvisionAccount) {
      const resp = await apiContext.post('/v2/auth/email', {
        headers: { 'Content-Type': 'application/json' },
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
        if (json?.access_token && json?.refresh_token) {
          capturedTokens = { access_token: json.access_token, refresh_token: json.refresh_token };
          console.log('[auth.setup] static account tokens captured ✓');
        }
      }
    }

    if (!capturedTokens && canProvisionAccount) {
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
      const verify = await apiContext.post('/v2/auth/verify-email-code', {
        headers: { 'Content-Type': 'application/json' },
        data: JSON.stringify({ email: provisionedEmail, code }),
      });
      if (!verify.ok()) {
        throw new Error(`temporary account verification returned ${verify.status()}`);
      }
      const json = await verify.json();
      if (json?.access_token && json?.refresh_token) {
        capturedTokens = { access_token: json.access_token, refresh_token: json.refresh_token };
        temporaryAccountCreated = true;
        console.log('[auth.setup] temporary verified account tokens captured ✓');
      }
    }
  } catch (err) {
    console.warn(`[auth.setup] API call threw: ${err}`);
    if (canProvisionAccount) throw err;
  } finally {
    await apiContext.dispose();
  }

  fs.mkdirSync(path.dirname(AUTH_FILE), { recursive: true });

  if (!capturedTokens) {
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
  // shared_preferences_web stores String values as JSON.stringify(value) under
  // the key 'flutter.<prefKey>'. We write the file directly instead of
  // navigating to the app — avoids dependency on the preview URL being ready
  // and removes a potential source of unhandled exceptions.
  fs.writeFileSync(AUTH_FILE, JSON.stringify({
    cookies: [],
    origins: [{
      origin,
      localStorage: [
        { name: 'flutter.access_token', value: JSON.stringify(capturedTokens.access_token) },
        { name: 'flutter.refresh_token', value: JSON.stringify(capturedTokens.refresh_token) },
      ],
    }],
  }));
  if (temporaryAccountCreated) fs.writeFileSync(TEMPORARY_ACCOUNT_FILE, 'created-by-playwright');
  console.log(`[auth.setup] storageState saved → ${AUTH_FILE}`);
});
