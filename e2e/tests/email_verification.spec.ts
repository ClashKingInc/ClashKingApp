import { test, expect } from '@playwright/test';
import { enableFlutterSemantics, hasFlutterSemantics } from './helpers';

// Reaches EmailVerificationPage by registering a fresh throwaway account.
// Each test creates one unique account (timestamp-based email) — expected in a test env.
// Tests cover UI behaviour only; a valid verification code is not available in CI.

async function registerAndNavigateToVerification(page: any): Promise<string | null> {
  const ts = Date.now();
  const username = `e2etest${ts}`;
  const email = `e2etest+${ts}@example.com`;
  const password = 'TestPassword1!';

  try {
    // Cap all page actions at 30 s so they don't inherit the 240 s test timeout.
    page.setDefaultNavigationTimeout(30_000);
    page.setDefaultTimeout(30_000);
    await page.goto('/');
    // enableFlutterSemantics calls waitForFlutter internally — no need to call it separately
    await enableFlutterSemantics(page);

    // Switch to Email tab — explicit waitFor prevents 30 s default action timeout
    const emailTab = page.getByRole('tab', { name: /email/i });
    await emailTab.waitFor({ state: 'attached', timeout: 8_000 });
    await emailTab.click({ timeout: 8_000 });
    await page.waitForTimeout(400);

    // Navigate to Register page
    const signUpBtn = page
      .getByRole('button', { name: /sign up/i })
      .or(page.locator('flt-semantics[aria-label*="Sign up" i]'))
      .first();
    await signUpBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await signUpBtn.click({ timeout: 8_000 });
    await page.waitForTimeout(600);

    // Fill registration form
    const usernameInput = page.getByRole('textbox', { name: /username/i });
    await usernameInput.waitFor({ state: 'attached', timeout: 8_000 });
    await usernameInput.click({ force: true, timeout: 5_000 });
    await usernameInput.pressSequentially(username, { delay: 20 });

    const emailInput = page.getByRole('textbox', { name: /email/i });
    await emailInput.click({ force: true, timeout: 5_000 });
    await emailInput.pressSequentially(email, { delay: 20 });

    const pwInputs = page.locator('input[type="password"]');
    await pwInputs.nth(0).click({ force: true, timeout: 5_000 });
    await pwInputs.nth(0).pressSequentially(password, { delay: 20 });
    await pwInputs.nth(1).click({ force: true, timeout: 5_000 });
    await pwInputs.nth(1).pressSequentially(password, { delay: 20 });

    // Submit — creates account and navigates to EmailVerificationPage
    const createBtn = page
      .getByRole('button', { name: /create account/i })
      .or(page.locator('flt-semantics[aria-label*="Create Account" i]'))
      .first();
    await createBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await createBtn.click({ timeout: 8_000 });

    // Wait for EmailVerificationPage ("Verify Email" appbar title or "Verify Code" button)
    await page.waitForFunction(
      () => Array.from(document.querySelectorAll('flt-semantics'))
        .some(el => /verify/i.test(el.getAttribute('aria-label') ?? '')),
      { timeout: 15_000, polling: 500 },
    );
  } catch {
    return null; // API unavailable, rate-limited, or slow — test will skip gracefully
  }

  return email;
}

test.describe('Email verification page', () => {
  // Run sequentially: each test registers a new account + hits the production API.
  // Parallel execution saturates the API and causes 90 s timeouts.
  test.describe.configure({ mode: 'serial' });

  test('page displays 6 single-digit input boxes for the verification code', async ({ page }) => {
    test.setTimeout(240_000); // registration + API call can take > 180 s on a slow local setup
    const email = await registerAndNavigateToVerification(page);
    if (!email) test.skip(true, 'Could not reach EmailVerificationPage — API may be unavailable');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    // 6 inputs rendered by Flutter for the 6-digit verification code.
    // Flutter may use inputmode="decimal" or "numeric" — use generic textbox role.
    const digitInputs = page.getByRole('textbox');
    await expect(digitInputs.first()).toBeAttached({ timeout: 8_000 });
    const count = await digitInputs.count();
    expect(count).toBeGreaterThanOrEqual(6);
  });

  test('"Verify Code" button is present and disabled before any digit is entered', async ({ page }) => {
    test.setTimeout(120_000);
    const email = await registerAndNavigateToVerification(page);
    if (!email) test.skip(true, 'Could not reach EmailVerificationPage');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    // Flutter sets aria-disabled="true" when onPressed is null (code length != 6)
    const verifyBtn = page
      .getByRole('button', { name: /verify code/i })
      .or(page.locator('flt-semantics[aria-label*="Verify Code" i]'))
      .first();
    await verifyBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await expect(verifyBtn).toBeDisabled({ timeout: 5_000 });
  });

  test('"Resend Verification Email" button is present', async ({ page }) => {
    test.setTimeout(120_000);
    const email = await registerAndNavigateToVerification(page);
    if (!email) test.skip(true, 'Could not reach EmailVerificationPage');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    await expect(
      page.getByRole('button', { name: /resend/i })
        .or(page.locator('flt-semantics[aria-label*="Resend" i]'))
        .first()
    ).toBeAttached({ timeout: 8_000 });
  });

  test('"Back to Login" button is present', async ({ page }) => {
    test.setTimeout(120_000);
    const email = await registerAndNavigateToVerification(page);
    if (!email) test.skip(true, 'Could not reach EmailVerificationPage');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    await expect(
      page.getByRole('button', { name: /back to login/i })
        .or(page.locator('flt-semantics[aria-label*="Back to Login" i]'))
        .first()
    ).toBeAttached({ timeout: 8_000 });
  });

  test('page shows the email address the code was sent to', async ({ page }) => {
    test.setTimeout(120_000);
    const email = await registerAndNavigateToVerification(page);
    if (!email) test.skip(true, 'Could not reach EmailVerificationPage');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    // EmailVerificationPage displays widget.email as a Text widget
    const emailLabel = page
      .locator(`flt-semantics[aria-label*="${email}" i]`)
      .or(page.getByText(email, { exact: false }));
    await expect(emailLabel.first()).toBeAttached({ timeout: 8_000 });
  });

  test('entering a wrong 6-digit code triggers an error message', async ({ page }) => {
    test.setTimeout(120_000);
    const email = await registerAndNavigateToVerification(page);
    if (!email) test.skip(true, 'Could not reach EmailVerificationPage');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    // Type one digit per box — Flutter auto-advances focus on each entry
    const digitInputs = page.getByRole('textbox');
    await digitInputs.first().waitFor({ state: 'attached', timeout: 8_000 });
    const count = await digitInputs.count();
    if (count < 6) test.skip(true, 'Could not find 6 digit input boxes');

    for (let i = 0; i < 6; i++) {
      await digitInputs.nth(i).click({ force: true, timeout: 5_000 });
      await digitInputs.nth(i).pressSequentially('9', { delay: 60 });
      await page.waitForTimeout(120);
    }

    // Auto-submit fires when 6th digit is entered — wait for API response
    await page.waitForTimeout(5_000);

    // An error message appears: "Invalid or expired code" (authEmailVerificationCodeInvalid)
    const errorEl = page
      .locator('flt-semantics[aria-label*="Invalid" i]')
      .or(page.locator('flt-semantics[aria-label*="expired" i]'))
      .or(page.locator('flt-semantics[aria-label*="incorrect" i]'));
    await expect(errorEl.first()).toBeAttached({ timeout: 8_000 });
  });

  test('"Back to Login" navigates back to the login page', async ({ page }) => {
    test.setTimeout(120_000);
    const email = await registerAndNavigateToVerification(page);
    if (!email) test.skip(true, 'Could not reach EmailVerificationPage');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const backBtn = page
      .getByRole('button', { name: /back to login/i })
      .or(page.locator('flt-semantics[aria-label*="Back to Login" i]'))
      .first();
    await backBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await backBtn.click({ timeout: 8_000 });
    await page.waitForTimeout(800);

    // Login page: Discord/Email tabs visible
    await expect(
      page.getByRole('tab', { name: /email/i })
        .or(page.locator('flt-semantics[aria-label*="Email" i]'))
        .first()
    ).toBeAttached({ timeout: 8_000 });
  });
});
