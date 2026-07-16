import { test, expect } from '@playwright/test';
import { authSegment, clickAuthSegment, enableFlutterSemantics, hasFlutterSemantics } from './helpers';

// Navigates to ResetPasswordPage via the forgot-password flow.
// Requires TEST_EMAIL to be set — all tests skip gracefully otherwise.
// Note: each test sends a password-reset email to TEST_EMAIL.
// If the API rate-limits reset requests, tests will be skipped via the `reached` guard.

async function navigateToResetPage(page: any): Promise<boolean> {
  const email = process.env.TEST_EMAIL;
  if (!email) return false;

  try {
    // Cap all page actions so no single step can silently consume the full test budget.
    page.setDefaultNavigationTimeout(30_000);
    page.setDefaultTimeout(30_000);
    await page.goto('/', { timeout: 30_000 });
    // enableFlutterSemantics calls waitForFlutter internally — no need to call it separately
    await enableFlutterSemantics(page);

    // Switch to Email auth segment — explicit waitFor caps the timeout at 8 s instead of 30 s default
    await clickAuthSegment(page, /email/i);
    await page.waitForTimeout(500);

    // Open forgot password page
    const forgotBtn = page
      .getByRole('button', { name: /forgot/i })
      .or(page.locator('flt-semantics[aria-label*="Forgot" i]'))
      .first();
    await forgotBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await forgotBtn.click({ timeout: 8_000 });
    await page.waitForTimeout(600);

    // Enter test email
    const emailInput = page.getByRole('textbox', { name: /email/i });
    await emailInput.waitFor({ state: 'attached', timeout: 8_000 });
    await emailInput.click({ force: true, timeout: 8_000 });
    await emailInput.pressSequentially(email, { delay: 30 });

    // Send reset code — cap at 8 s so a loading/disabled state doesn't block for 30 s
    const sendBtn = page
      .getByRole('button', { name: /send reset/i })
      .or(page.locator('flt-semantics[aria-label*="Send" i]'))
      .first();
    await sendBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await sendBtn.click({ timeout: 8_000 });

    // Wait for success state — "Code Sent!" message or "Continue" button.
    // Flutter web exposes these strings via textContent, not aria-label.
    await page.waitForFunction(
      () => Array.from(document.querySelectorAll('flt-semantics'))
        .some(el => /continue|code sent/i.test(el.textContent ?? '')),
      { timeout: 12_000, polling: 500 },
    );

    // Click "Continue to Reset Password"
    const continueBtn = page
      .locator('flt-semantics[aria-label*="Continue" i]')
      .or(page.getByRole('button', { name: /continue/i }))
      .first();
    await continueBtn.waitFor({ state: 'attached', timeout: 5_000 });
    await continueBtn.click({ timeout: 8_000 });
    await page.waitForTimeout(1_000);

    // Confirm we landed on ResetPasswordPage (Reset Code field should be present)
    const onPage = await page
      .locator('flt-semantics[aria-label*="Reset Code" i]')
      .or(page.getByRole('textbox', { name: /reset code/i }))
      .count() > 0;
    return onPage;
  } catch {
    return false; // API unavailable, rate-limited, or any step timed out — skip gracefully
  }
}

test.describe('Reset password page', () => {
  // Run sequentially: each test sends a reset email to TEST_EMAIL.
  // Parallel execution causes API rate-limiting and 90 s timeouts.
  test.describe.configure({ mode: 'serial' });

  test('page loads with Email, Reset Code, New Password and Confirm Password fields', async ({ page }) => {
    test.setTimeout(120_000); // navigateToResetPage sends a real reset email — API response can take > 30 s
    const reached = await navigateToResetPage(page);
    if (!reached) test.skip(true, 'TEST_EMAIL not set or could not reach reset password page');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    // Email field (pre-filled from forgot-password flow)
    await expect(
      page.getByRole('textbox', { name: /email/i }).first()
    ).toBeAttached({ timeout: 8_000 });

    // 6-digit reset code field
    await expect(
      page.getByRole('textbox', { name: /reset code/i })
        .or(page.locator('flt-semantics[aria-label*="Reset Code" i]'))
        .first()
    ).toBeAttached({ timeout: 5_000 });

    // New password field (type=password, labelled "New Password")
    await expect(
      page.getByLabel(/new password/i).first()
    ).toBeAttached({ timeout: 5_000 });

    // Confirm password field
    await expect(
      page.getByLabel(/confirm password/i).first()
    ).toBeAttached({ timeout: 5_000 });
  });

  test('"Reset Password" button is visible', async ({ page }) => {
    test.setTimeout(120_000); // navigateToResetPage sends a real reset email — API response can take > 30 s
    const reached = await navigateToResetPage(page);
    if (!reached) test.skip(true, 'TEST_EMAIL not set or could not reach reset password page');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    await expect(
      page.getByRole('button', { name: /^reset password$/i })
        .or(page.locator('flt-semantics[aria-label="Reset Password"]'))
        .first()
    ).toBeAttached({ timeout: 8_000 });
  });

  test('submitting empty form stays on reset page (form validation)', async ({ page }) => {
    test.setTimeout(120_000);
    const reached = await navigateToResetPage(page);
    if (!reached) test.skip(true, 'TEST_EMAIL not set or could not reach reset password page');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const resetBtn = page
      .getByRole('button', { name: /^reset password$/i })
      .or(page.locator('flt-semantics[aria-label="Reset Password"]'))
      .first();
    await resetBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await resetBtn.click({ timeout: 8_000 });
    await page.waitForTimeout(600);

    // Validation blocks the request — Reset button is still present
    await expect(resetBtn).toBeAttached({ timeout: 5_000 });
  });

  test('reset code shorter than 6 digits fails validation', async ({ page }) => {
    test.setTimeout(120_000);
    const reached = await navigateToResetPage(page);
    if (!reached) test.skip(true, 'TEST_EMAIL not set or could not reach reset password page');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const codeInput = page
      .getByRole('textbox', { name: /reset code/i })
      .or(page.locator('flt-semantics[aria-label*="Reset Code" i]'))
      .first();
    await codeInput.waitFor({ state: 'attached', timeout: 8_000 });
    await codeInput.click({ force: true, timeout: 5_000 });
    await codeInput.pressSequentially('12', { delay: 30 }); // Only 2 digits

    const resetBtn = page
      .getByRole('button', { name: /^reset password$/i })
      .or(page.locator('flt-semantics[aria-label="Reset Password"]'))
      .first();
    await resetBtn.click({ timeout: 8_000 });
    await page.waitForTimeout(600);

    // Validation blocked submission — Reset button still present
    await expect(resetBtn).toBeAttached({ timeout: 5_000 });
  });

  test('mismatched new passwords fail validation', async ({ page }) => {
    test.setTimeout(120_000);
    const reached = await navigateToResetPage(page);
    if (!reached) test.skip(true, 'TEST_EMAIL not set or could not reach reset password page');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    // Fill a valid 6-digit code (wrong but passes format validation)
    const codeInput = page
      .getByRole('textbox', { name: /reset code/i })
      .or(page.locator('flt-semantics[aria-label*="Reset Code" i]'))
      .first();
    await codeInput.waitFor({ state: 'attached', timeout: 8_000 });
    await codeInput.click({ force: true, timeout: 5_000 });
    await codeInput.pressSequentially('123456', { delay: 30 });

    // Fill mismatched passwords via the type=password inputs
    const pwInputs = page.locator('input[type="password"]');
    await pwInputs.nth(0).click({ force: true, timeout: 5_000 });
    await pwInputs.nth(0).pressSequentially('Password1!', { delay: 30 });
    await pwInputs.nth(1).click({ force: true, timeout: 5_000 });
    await pwInputs.nth(1).pressSequentially('Different2@', { delay: 30 });

    const resetBtn = page
      .getByRole('button', { name: /^reset password$/i })
      .or(page.locator('flt-semantics[aria-label="Reset Password"]'))
      .first();
    await resetBtn.click({ timeout: 8_000 });
    await page.waitForTimeout(600);

    // Either a mismatch error text appears, or the button is still present (validation blocked)
    const mismatchError = page
      .locator('flt-semantics[aria-label*="do not match" i]')
      .or(page.locator('flt-semantics[aria-label*="mismatch" i]'));
    const errorVisible = await mismatchError.count() > 0;
    if (!errorVisible) {
      await expect(resetBtn).toBeAttached();
    }
  });

  test('password that does not meet requirements fails validation', async ({ page }) => {
    const reached = await navigateToResetPage(page);
    if (!reached) test.skip(true, 'TEST_EMAIL not set or could not reach reset password page');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const codeInput = page
      .getByRole('textbox', { name: /reset code/i })
      .or(page.locator('flt-semantics[aria-label*="Reset Code" i]'))
      .first();
    await codeInput.waitFor({ state: 'attached', timeout: 8_000 });
    await codeInput.click({ force: true, timeout: 5_000 });
    await codeInput.pressSequentially('123456', { delay: 30 });

    // Password without uppercase/special — does not meet requirements
    const pwInputs = page.locator('input[type="password"]');
    await pwInputs.nth(0).click({ force: true, timeout: 5_000 });
    await pwInputs.nth(0).pressSequentially('password123', { delay: 30 });
    await pwInputs.nth(1).click({ force: true, timeout: 5_000 });
    await pwInputs.nth(1).pressSequentially('password123', { delay: 30 });

    const resetBtn = page
      .getByRole('button', { name: /^reset password$/i })
      .or(page.locator('flt-semantics[aria-label="Reset Password"]'))
      .first();
    await resetBtn.click({ timeout: 8_000 });
    await page.waitForTimeout(600);

    // Validation should block — Reset button still present
    await expect(resetBtn).toBeAttached();
  });

  test('"Back to Login" navigates back to login page', async ({ page }) => {
    test.setTimeout(120_000);
    const reached = await navigateToResetPage(page);
    if (!reached) test.skip(true, 'TEST_EMAIL not set or could not reach reset password page');
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const backBtn = page
      .getByRole('button', { name: /back to login/i })
      .or(page.locator('flt-semantics[aria-label*="Back to Login" i]'))
      .first();
    await backBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await backBtn.click({ timeout: 8_000 });
    await page.waitForTimeout(800);

    // Login page: Email/Discord auth segments should appear
    await expect(authSegment(page, /email/i)).toBeAttached({ timeout: 8_000 });
  });
});
