import { test, expect } from '@playwright/test';
import { hasFlutterSemantics, enableFlutterSemantics } from './helpers';

// This spec runs with saved auth state (chromium-auth project).
// It targets the AddCocAccountPage shown to a user with no linked CoC accounts.
// If the test account already has CoC accounts, all tests are skipped gracefully.
//
// Detection note: labels are flt-semantics *textContent*, not [aria-label], so
// we target by text (page.getByText). Icon buttons with tooltips fall back to
// getByRole (the tooltip becomes the accessible name).

async function waitForApp(page: any) {
  await page.goto('/');
  await enableFlutterSemantics(page);
  // Let the post-auth redirect start before we poll for the settled state
  await page.waitForTimeout(2_000);
}

/**
 * Returns true when the app has landed on AddCocAccountPage.
 * AddCocAccountPage has a 'Confirm' button; MyHomePage does not.
 * If 'Confirm' is not found within 10 s the user is already on MyHomePage.
 */
async function isOnAddAccountPage(page: any): Promise<boolean> {
  try {
    await page
      .getByText('Confirm', { exact: true })
      .first()
      .waitFor({ state: 'attached', timeout: 10_000 });
    return true;
  } catch {
    return false;
  }
}

test.describe('Add CoC Account page (first-connection flow)', () => {
  test.beforeEach(async ({ page }) => {
    // Give enough budget for enableFlutterSemantics (~5 s) + isOnAddAccountPage (10 s)
    // + assertion (8 s). test.slow() in beforeEach only triples the hook timeout, not
    // the test-body timeout — use test.setTimeout() instead.
    test.setTimeout(45_000);
    await waitForApp(page);
  });

  test('player tag input field is present', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnAddAccountPage(page))) test.skip(true, 'Test account already has CoC accounts — not on AddCocAccountPage');

    const tagInput = page
      .getByRole('textbox', { name: /player tag/i })
      .or(page.getByText(/Player Tag/i))
      .first();
    await expect(tagInput).toBeAttached({ timeout: 8_000 });
  });

  test('"Add account" button is present', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnAddAccountPage(page))) test.skip(true, 'Test account already has CoC accounts');

    // The + button has tooltip "Add account" which becomes its accessible name
    const addBtn = page
      .getByRole('button', { name: /add account/i })
      .or(page.getByText(/Add account/i))
      .first();
    await expect(addBtn).toBeAttached({ timeout: 8_000 });
  });

  test('welcome or manage-accounts text is visible', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnAddAccountPage(page))) test.skip(true, 'Test account already has CoC accounts');

    // First-connection shows "Welcome!", returning users see "Manage your accounts"
    const welcomeOrManage = page
      .getByText(/Welcome/i)
      .or(page.getByText(/Manage/i))
      .first();
    await expect(welcomeOrManage).toBeAttached({ timeout: 8_000 });
  });

  test('Confirm button is present', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnAddAccountPage(page))) test.skip(true, 'Test account already has CoC accounts');

    const confirmBtn = page
      .getByRole('button', { name: /^confirm$/i })
      .or(page.getByText('Confirm', { exact: true }))
      .first();
    await expect(confirmBtn).toBeAttached({ timeout: 8_000 });
  });

  test('Confirm button is disabled before any account is added', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnAddAccountPage(page))) test.skip(true, 'Test account already has CoC accounts');

    // Flutter sets aria-disabled="true" on ElevatedButton when onPressed is null
    const confirmBtn = page
      .getByText('Confirm', { exact: true })
      .or(page.getByRole('button', { name: /^confirm$/i }))
      .first();
    await confirmBtn.waitFor({ state: 'attached', timeout: 8_000 });

    // Disabled button should not be enabled yet (no accounts added)
    await expect(confirmBtn).toBeDisabled({ timeout: 5_000 });
  });

  test('can type a player tag into the input', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnAddAccountPage(page))) test.skip(true, 'Test account already has CoC accounts');

    const tagInput = page
      .getByRole('textbox', { name: /player tag/i })
      .first();
    await tagInput.waitFor({ state: 'attached', timeout: 8_000 });
    await tagInput.click();
    await tagInput.pressSequentially('#2PP', { delay: 30 });

    await expect(tagInput).toHaveValue(/#?2PP/i, { timeout: 5_000 });
  });

  test('adding a non-existent tag shows an error message', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnAddAccountPage(page))) test.skip(true, 'Test account already has CoC accounts');

    const tagInput = page
      .getByRole('textbox', { name: /player tag/i })
      .first();
    await tagInput.waitFor({ state: 'attached', timeout: 8_000 });
    await tagInput.click();
    // Use a tag that is guaranteed not to exist
    await tagInput.pressSequentially('#INVALID999', { delay: 30 });

    const addBtn = page
      .getByRole('button', { name: /add account/i })
      .or(page.getByText(/Add account/i))
      .first();
    await addBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await addBtn.click({ force: true });

    // Wait for the API response (may take a couple of seconds)
    await page.waitForTimeout(3_000);

    // An error message should appear (e.g. "does not exist" or "Failed to add")
    const errorEl = page
      .getByText(/does not exist/i)
      .or(page.getByText(/Failed/i))
      .or(page.getByText(/invalid/i))
      .first();
    await expect(errorEl).toBeAttached({ timeout: 8_000 });
  });

  // §7.8, §7.9, §7.11 combined — full CoC account addition flow
  // Uses E2E_TEST_COC_TAG (real player tag) to exercise the complete add → confirm → MyHomePage path.
  test('adding a valid CoC tag, confirming, and landing on MyHomePage (full flow)', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnAddAccountPage(page))) test.skip(true, 'Test account already has CoC accounts — full add flow not testable');

    const cocTag = process.env.E2E_TEST_COC_TAG;
    if (!cocTag) test.skip(true, 'E2E_TEST_COC_TAG not set — set it to a real player tag to enable this test');

    // §7.8 — type valid tag and add
    const tagInput = page.getByRole('textbox', { name: /player tag/i }).first();
    await tagInput.waitFor({ state: 'attached', timeout: 8_000 });
    await tagInput.click();
    await tagInput.pressSequentially(cocTag, { delay: 30 });

    const addBtn = page
      .getByRole('button', { name: /add account/i })
      .or(page.getByText(/Add account/i))
      .first();
    await addBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await addBtn.click({ force: true });
    await page.waitForTimeout(4_000);

    // Account should appear in list — semantic count grows
    const countAfterAdd = await page.locator('flt-semantics').count();
    expect(countAfterAdd).toBeGreaterThan(8);

    // §7.9 — Confirm button is now enabled
    const confirmBtn = page
      .getByText('Confirm', { exact: true })
      .or(page.getByRole('button', { name: /^confirm$/i }))
      .first();
    await confirmBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await expect(confirmBtn).not.toBeDisabled({ timeout: 5_000 });

    // §7.11 — click Confirm → app loads player data → navigates to MyHomePage
    await confirmBtn.click({ force: true });
    await page.waitForTimeout(10_000);

    await expect(page.getByText('Dashboard', { exact: true }).first()).toBeAttached({ timeout: 20_000 });
  });
});
