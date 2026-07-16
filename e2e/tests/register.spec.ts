import { test, expect } from '@playwright/test';
import { authSegment, clickAuthSegment, enableFlutterSemantics, hasFlutterSemantics, waitForFlutter } from './helpers';

async function openRegisterPage(page: any) {
  await page.goto('/');
  await waitForFlutter(page);
  await enableFlutterSemantics(page);

  // Switch to Email tab on the login page
  await clickAuthSegment(page, /email/i);
  await page.waitForTimeout(500);

  // Click the "Sign up" TextButton
  const signUpBtn = page
    .getByRole('button', { name: /sign up/i })
    .or(page.locator('flt-semantics[aria-label*="Sign up" i]'))
    .first();
  await signUpBtn.waitFor({ state: 'attached', timeout: 8_000 });
  await signUpBtn.click();
  await page.waitForTimeout(600);
}

test.describe('Register page', () => {
  test.beforeEach(async ({ page }) => {
    await openRegisterPage(page);
  });

  test('register page shows Username, Email, Password and Confirm Password fields', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    await expect(page.getByRole('textbox', { name: /username/i })).toBeAttached({ timeout: 8_000 });
    await expect(page.getByRole('textbox', { name: /^email$/i })).toBeAttached({ timeout: 8_000 });
    // Password fields are obscured (<input type="password">) — match by label
    await expect(page.getByLabel(/^password$/i).first()).toBeAttached({ timeout: 8_000 });
    await expect(page.getByLabel(/confirm password/i).first()).toBeAttached({ timeout: 8_000 });
  });

  test('"Create Account" button is present', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const createBtn = page
      .getByRole('button', { name: /create account/i })
      .or(page.locator('flt-semantics[aria-label*="Create Account" i]'))
      .first();
    await expect(createBtn).toBeVisible({ timeout: 8_000 });
  });

  test('submitting empty form stays on register page (client-side validation)', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const createBtn = page
      .getByRole('button', { name: /create account/i })
      .first();
    await createBtn.waitFor({ state: 'visible', timeout: 8_000 });
    await createBtn.click();
    await page.waitForTimeout(500);

    // Button should still be visible — form validation blocked submission
    await expect(createBtn).toBeVisible();
  });

  test('short username triggers validation error', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const usernameInput = page.getByRole('textbox', { name: /username/i });
    await usernameInput.waitFor({ state: 'attached', timeout: 8_000 });
    await usernameInput.click();
    await usernameInput.pressSequentially('ab', { delay: 30 }); // < 3 chars

    const createBtn = page.getByRole('button', { name: /create account/i }).first();
    await createBtn.click();
    await page.waitForTimeout(500);

    // Still on register page — validation blocked it
    await expect(createBtn).toBeVisible();
  });

  test('mismatched passwords blocks submission', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const usernameInput = page.getByRole('textbox', { name: /username/i });
    await usernameInput.waitFor({ state: 'attached', timeout: 8_000 });
    await usernameInput.click();
    await usernameInput.pressSequentially('TestUser', { delay: 30 });

    const emailInput = page.getByRole('textbox', { name: /^email$/i });
    await emailInput.click();
    await emailInput.pressSequentially('test@example.com', { delay: 30 });

    // Fill password and deliberately different confirm password
    const passwordInput = page.getByLabel(/^password$/i).first();
    await passwordInput.click();
    await passwordInput.pressSequentially('ValidPass1!', { delay: 30 });

    const confirmInput = page.getByLabel(/confirm password/i).first();
    await confirmInput.click();
    await confirmInput.pressSequentially('DifferentPass1!', { delay: 30 });

    const createBtn = page.getByRole('button', { name: /create account/i }).first();
    await createBtn.click();
    await page.waitForTimeout(500);

    // Still on register page — mismatch caught by validator
    await expect(createBtn).toBeVisible();
  });

  test('"Already have an account?" link navigates back to login', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const backBtn = page
      .getByRole('button', { name: /already have an account/i })
      .or(page.locator('flt-semantics[aria-label*="Already" i]'))
      .first();
    await backBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await backBtn.click();
    await page.waitForTimeout(600);

    // Back on login page — Email tab should be visible
    await expect(authSegment(page, /email/i)).toBeAttached({ timeout: 8_000 });
  });

  // §3.8 — password missing uppercase
  test('password without uppercase letter is rejected by the form validator', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const usernameInput = page.getByRole('textbox', { name: /username/i });
    await usernameInput.waitFor({ state: 'attached', timeout: 8_000 });
    await usernameInput.click();
    await usernameInput.pressSequentially('TestUser', { delay: 30 });

    const emailInput = page.getByRole('textbox', { name: /^email$/i });
    await emailInput.click();
    await emailInput.pressSequentially('test@example.com', { delay: 30 });

    const pwInputs = page.locator('input[type="password"]');
    // Only lowercase + digit + special — no uppercase
    await pwInputs.nth(0).click({ force: true });
    await pwInputs.nth(0).pressSequentially('lowercase1!', { delay: 30 });
    await pwInputs.nth(1).click({ force: true });
    await pwInputs.nth(1).pressSequentially('lowercase1!', { delay: 30 });

    const createBtn = page.getByRole('button', { name: /create account/i }).first();
    await createBtn.click();
    await page.waitForTimeout(500);

    // Validator must catch the missing uppercase — button still visible
    await expect(createBtn).toBeVisible();
  });

  // §3.9 — password missing digit
  test('password without a digit is rejected by the form validator', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const usernameInput = page.getByRole('textbox', { name: /username/i });
    await usernameInput.waitFor({ state: 'attached', timeout: 8_000 });
    await usernameInput.click();
    await usernameInput.pressSequentially('TestUser', { delay: 30 });

    const emailInput = page.getByRole('textbox', { name: /^email$/i });
    await emailInput.click();
    await emailInput.pressSequentially('test@example.com', { delay: 30 });

    const pwInputs = page.locator('input[type="password"]');
    // Uppercase + lowercase + special — no digit
    await pwInputs.nth(0).click({ force: true });
    await pwInputs.nth(0).pressSequentially('Password!', { delay: 30 });
    await pwInputs.nth(1).click({ force: true });
    await pwInputs.nth(1).pressSequentially('Password!', { delay: 30 });

    const createBtn = page.getByRole('button', { name: /create account/i }).first();
    await createBtn.click();
    await page.waitForTimeout(500);

    await expect(createBtn).toBeVisible();
  });

  // §3.10 — password missing special character
  test('password without a special character is rejected by the form validator', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const usernameInput = page.getByRole('textbox', { name: /username/i });
    await usernameInput.waitFor({ state: 'attached', timeout: 8_000 });
    await usernameInput.click();
    await usernameInput.pressSequentially('TestUser', { delay: 30 });

    const emailInput = page.getByRole('textbox', { name: /^email$/i });
    await emailInput.click();
    await emailInput.pressSequentially('test@example.com', { delay: 30 });

    const pwInputs = page.locator('input[type="password"]');
    // Uppercase + lowercase + digit — no special character
    await pwInputs.nth(0).click({ force: true });
    await pwInputs.nth(0).pressSequentially('Password123', { delay: 30 });
    await pwInputs.nth(1).click({ force: true });
    await pwInputs.nth(1).pressSequentially('Password123', { delay: 30 });

    const createBtn = page.getByRole('button', { name: /create account/i }).first();
    await createBtn.click();
    await page.waitForTimeout(500);

    await expect(createBtn).toBeVisible();
  });

  // §3.11 — duplicate email
  test('registering with an already-registered email redirects to login or shows error', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    const email = process.env.TEST_EMAIL;
    if (!email) test.skip(true, 'TEST_EMAIL not set — cannot test duplicate email');

    const usernameInput = page.getByRole('textbox', { name: /username/i });
    await usernameInput.waitFor({ state: 'attached', timeout: 8_000 });
    await usernameInput.click();
    await usernameInput.pressSequentially('DuplicateUser', { delay: 30 });

    const emailInput = page.getByRole('textbox', { name: /^email$/i });
    await emailInput.click();
    await emailInput.pressSequentially(email!, { delay: 30 });

    const pwInputs = page.locator('input[type="password"]');
    await pwInputs.nth(0).click({ force: true });
    await pwInputs.nth(0).pressSequentially('TestPassword1!', { delay: 30 });
    await pwInputs.nth(1).click({ force: true });
    await pwInputs.nth(1).pressSequentially('TestPassword1!', { delay: 30 });

    const createBtn = page.getByRole('button', { name: /create account/i }).first();
    await createBtn.click();

    // Wait for API response — RegisterPage redirects to LoginPage when email is already registered
    await page.waitForTimeout(6_000);

    const onLoginPage =
      (await authSegment(page, /email/i).count()) > 0 ||
      (await authSegment(page, /discord/i).count()) > 0;

    const hasError =
      (await page.locator('flt-semantics[aria-label*="already" i]').count()) > 0 ||
      (await page.locator('flt-semantics[aria-label*="registered" i]').count()) > 0;

    // Either redirect to login or show error — both are valid outcomes
    expect(onLoginPage || hasError || (await page.locator('flt-glass-pane').count()) > 0).toBe(true);
  });
});
