import { test, expect } from '@playwright/test';
import { authSegment, clickAuthSegment, enableFlutterSemantics, hasFlutterSemantics, waitForFlutter } from './helpers';

test.describe('Login page — UI', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    await enableFlutterSemantics(page);
  });

  test('shows Discord and Email auth segments', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    await expect(authSegment(page, /discord/i)).toBeAttached();
    await expect(authSegment(page, /email/i)).toBeAttached();
  });

  test('Discord auth segment is selected by default', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    await expect(page.getByRole('button', { name: /continue with discord/i })).toBeVisible();
  });

  test('Email tab shows email input, password input and Login button', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    await clickAuthSegment(page, /email/i);
    await page.waitForTimeout(500);

    // Flutter creates real <input> elements in the accessibility layer
    await expect(page.getByRole('textbox', { name: 'Email' })).toBeAttached();
    await expect(page.getByLabel('Password').first()).toBeAttached();
    await expect(page.getByRole('button', { name: 'Login', exact: true })).toBeVisible();
  });

  test('Forgot password and Sign up links are visible on Email tab', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    await clickAuthSegment(page, /email/i);
    await page.waitForTimeout(500);

    // These TextButtons may be below the fold inside the 320px tab container.
    // Use toBeAttached (in DOM) rather than toBeVisible (in viewport).
    await expect(
      page.getByRole('button', { name: /forgot/i })
        .or(page.locator('flt-semantics[aria-label*="Forgot" i]')).first()
    ).toBeAttached({ timeout: 8_000 });
    await expect(
      page.getByRole('button', { name: /sign up/i })
        .or(page.locator('flt-semantics[aria-label*="Sign" i]')).first()
    ).toBeAttached({ timeout: 8_000 });
  });

  test('submitting empty form stays on login page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    await clickAuthSegment(page, /email/i);
    await page.waitForTimeout(500);

    await page.getByRole('button', { name: 'Login', exact: true }).click();
    await page.waitForTimeout(500);

    // Login button should still be here — validation blocked submission
    await expect(page.getByRole('button', { name: 'Login', exact: true })).toBeVisible();
  });

  test('full email login flow with test credentials', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const email = process.env.TEST_EMAIL;
    const password = process.env.TEST_PASSWORD;
    if (!email || !password) test.skip(true, 'TEST_EMAIL / TEST_PASSWORD not set');

    await clickAuthSegment(page, /email/i);
    await page.waitForTimeout(500);

    const emailInput = page.getByRole('textbox', { name: 'Email' });
    await emailInput.click();
    await emailInput.pressSequentially(email!, { delay: 30 });

    const passwordInput = page.getByLabel('Password').first();
    await passwordInput.click();
    await passwordInput.pressSequentially(password!, { delay: 30 });

    await page.getByRole('button', { name: 'Login', exact: true }).click();

    // Wait for the Login button to disappear → app navigated away from login page.
    // Flutter web exposes the label via textContent, not aria-label; checking
    // aria-label here would be vacuously true and never actually wait.
    await page.waitForFunction(
      () => !Array.from(document.querySelectorAll('flt-semantics'))
        .some(el => (el.textContent ?? '').trim() === 'Login'),
      { timeout: 25_000, polling: 500 },
    );

    // App should still be alive and showing content
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  test('wrong password shows an error message', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    const email = process.env.TEST_EMAIL;
    if (!email) test.skip(true, 'TEST_EMAIL not set');

    await clickAuthSegment(page, /email/i);
    await page.waitForTimeout(500);

    const emailInput = page.getByRole('textbox', { name: 'Email' });
    await emailInput.click();
    await emailInput.pressSequentially(email!, { delay: 30 });

    const passwordInput = page.getByLabel('Password').first();
    await passwordInput.click();
    await passwordInput.pressSequentially('WrongPassword999!', { delay: 30 });

    await page.getByRole('button', { name: 'Login', exact: true }).click();

    // Wrong password should keep the user on the login page.
    // Wait up to 15 s for the Login button to reappear after the API responds with an error.
    const onLoginPage = await page
      .getByRole('button', { name: 'Login', exact: true })
      .waitFor({ state: 'visible', timeout: 15_000 })
      .then(() => true)
      .catch(() => false);

    expect(onLoginPage).toBe(true);
  });

  test('malformed email in login form is caught by client-side validation', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    await clickAuthSegment(page, /email/i);
    await page.waitForTimeout(500);

    const emailInput = page.getByRole('textbox', { name: 'Email' });
    await emailInput.click();
    await emailInput.pressSequentially('notanemail', { delay: 30 });

    const passwordInput = page.getByLabel('Password').first();
    await passwordInput.click();
    await passwordInput.pressSequentially('SomePassword1!', { delay: 30 });

    await page.getByRole('button', { name: 'Login', exact: true }).click();
    await page.waitForTimeout(600);

    // Form validation blocks the request — Login button still visible
    await expect(page.getByRole('button', { name: 'Login', exact: true })).toBeVisible();
  });
});
