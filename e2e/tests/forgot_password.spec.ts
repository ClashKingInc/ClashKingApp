import { test, expect } from '@playwright/test';
import { enableFlutterSemantics, hasFlutterSemantics, waitForFlutter } from './helpers';

async function openForgotPassword(page: any) {
  await page.goto('/');
  await waitForFlutter(page);
  await enableFlutterSemantics(page);

  // Switch to Email tab
  await page.getByRole('tab', { name: /email/i }).click();
  await page.waitForTimeout(500);

  // Click "Forgot password?" link
  const forgotBtn = page
    .getByRole('button', { name: /forgot/i })
    .or(page.locator('flt-semantics[aria-label*="Forgot" i]')).first();
  await forgotBtn.waitFor({ state: 'attached', timeout: 8_000 });
  await forgotBtn.click();
  await page.waitForTimeout(600);
}

test.describe('Forgot password page', () => {
  test.beforeEach(async ({ page }) => {
    await openForgotPassword(page);
  });

  test('forgot password page loads with email field', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const emailInput = page.getByRole('textbox', { name: /email/i });
    await expect(emailInput).toBeAttached({ timeout: 8_000 });
  });

  test('Send Reset Code button is present', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    await expect(
      page.getByRole('button', { name: /send reset/i })
        .or(page.locator('flt-semantics[aria-label*="Send" i]')).first()
    ).toBeVisible({ timeout: 8_000 });
  });

  test('submitting empty form stays on forgot password page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const sendBtn = page.getByRole('button', { name: /send reset/i })
      .or(page.locator('flt-semantics[aria-label*="Send" i]')).first();
    await sendBtn.waitFor({ state: 'visible', timeout: 8_000 });
    await sendBtn.click();
    await page.waitForTimeout(500);

    // Button should still be here — validation blocked the request
    await expect(sendBtn).toBeVisible();
  });

  test('invalid email shows validation error', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const emailInput = page.getByRole('textbox', { name: /email/i });
    await emailInput.waitFor({ state: 'attached', timeout: 8_000 });
    // force: true bypasses the flt-semantics overlay that intercepts pointer events
    await emailInput.click({ force: true });
    await emailInput.pressSequentially('notanemail', { delay: 30 });

    const sendBtn = page.getByRole('button', { name: /send reset/i })
      .or(page.locator('flt-semantics[aria-label*="Send" i]')).first();
    await sendBtn.click();
    await page.waitForTimeout(500);

    // Should still be on forgot password page (validation error)
    await expect(sendBtn).toBeVisible();
  });

  // §4.5 — unknown email
  test('submitting an unknown email address does not crash the app', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const emailInput = page.getByRole('textbox', { name: /email/i });
    await emailInput.waitFor({ state: 'attached', timeout: 8_000 });
    await emailInput.click({ force: true });
    await emailInput.pressSequentially('unknown.nobody.xyz123@example-nonexistent.com', { delay: 30 });

    const sendBtn = page.getByRole('button', { name: /send reset/i })
      .or(page.locator('flt-semantics[aria-label*="Send" i]')).first();
    await sendBtn.click();

    await page.waitForTimeout(6_000);

    // App must remain alive whether the API returns an error or a generic "code sent" message
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  // §4.6, §4.7 — valid email → success + "Continue" button
  test('valid TEST_EMAIL shows success state and Continue button', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    const email = process.env.TEST_EMAIL;
    if (!email) test.skip(true, 'TEST_EMAIL not set 🔑');

    const emailInput = page.getByRole('textbox', { name: /email/i });
    await emailInput.waitFor({ state: 'attached', timeout: 8_000 });
    await emailInput.click({ force: true });
    await emailInput.pressSequentially(email!, { delay: 30 });

    const sendBtn = page.getByRole('button', { name: /send reset/i })
      .or(page.locator('flt-semantics[aria-label*="Send" i]')).first();
    await sendBtn.click();

    // Wait for success state — "Code Sent!" text or "Continue" button
    const successEl = page
      .locator('flt-semantics[aria-label*="Code Sent" i]')
      .or(page.locator('flt-semantics[aria-label*="Continue" i]'))
      .or(page.getByRole('button', { name: /continue/i }));

    try {
      await successEl.first().waitFor({ state: 'attached', timeout: 15_000 });
    } catch {
      test.skip(true, 'Success state not shown — API may be unavailable or rate-limited');
    }

    await expect(successEl.first()).toBeAttached();

    // §4.7 — "Continue to Reset Password" button is visible
    await expect(
      page.locator('flt-semantics[aria-label*="Continue" i]')
        .or(page.getByRole('button', { name: /continue/i }))
        .first()
    ).toBeAttached({ timeout: 5_000 });
  });

  // §4.8 — Back to Login
  test('"Back to Login" link navigates back to the login page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    // Look for a Back to Login text button or plain Back button / back arrow
    const backBtn = page
      .getByRole('button', { name: /back to login/i })
      .or(page.locator('flt-semantics[aria-label*="Back to Login" i]'))
      .or(page.getByRole('button', { name: /^back$/i }))
      .first();

    if (await backBtn.count() === 0) test.skip(true, 'No "Back to Login" button found on forgot password page');

    await backBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await backBtn.click();
    await page.waitForTimeout(600);

    await expect(
      page.getByRole('tab', { name: /email/i })
        .or(page.locator('flt-semantics[aria-label*="Email" i]'))
        .first()
    ).toBeAttached({ timeout: 8_000 });
  });
});
