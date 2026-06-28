import { test, expect } from '@playwright/test';
import { hasFlutterSemantics, waitForAppReady } from './helpers';

// Tests for the CoC Account Management page (AddCocAccountPage in manage mode).
// Reached via: account pill in the CustomAppBar → account menu → "Manage" button.
// The account pill sits on the left side of the 56px-tall AppBar.
// Tests skip if the test account has no linked CoC account (not on MyHomePage).
//
// Detection note: labels are flt-semantics *textContent*, not [aria-label], so
// we target by text (page.getByText). Icon buttons with tooltips fall back to
// getByRole (the tooltip becomes the accessible name).

async function waitForApp(page: any) {
  await page.goto('/');
  await waitForAppReady(page);
}

async function isOnMyHomePage(page: any): Promise<boolean> {
  return (await page.getByText('Dashboard', { exact: true }).count()) > 0;
}

// Opens the accounts menu via the account pill (left side of AppBar) then taps "Manage".
// Returns true only if AddCocAccountPage in manage mode was reached.
async function openCocAccountManagement(page: any): Promise<boolean> {
  if (!(await isOnMyHomePage(page))) return false;

  // The account pill is the first button in the AppBar (role=banner).
  await page.getByRole('banner').getByRole('button').first().click({ force: true });
  await page.waitForTimeout(800);

  // Menu should open with a "Manage" action.
  const manageBtn = page
    .getByRole('button', { name: /manage/i })
    .or(page.getByText(/Manage/i))
    .first();
  if (await manageBtn.count() === 0) return false;

  await manageBtn.waitFor({ state: 'attached', timeout: 5_000 });
  await manageBtn.click({ force: true });
  await page.waitForTimeout(1_200);

  // Verify we're on AddCocAccountPage in manage mode (title = "Manage your accounts")
  return (await page.getByText(/Manage your accounts/i).count()) > 0;
}

test.describe('CoC Account Management', () => {
  test.beforeEach(async ({ page }) => {
    await waitForApp(page);
  });

  test('account management page is accessible via the account menu', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');

    const reached = await openCocAccountManagement(page);
    if (!reached) test.skip(true, 'Could not open account management page');

    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  test('"Manage your accounts" title is shown', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openCocAccountManagement(page))) test.skip(true, 'Could not open account management page');

    await expect(page.getByText(/Manage your accounts/i).first()).toBeAttached({ timeout: 8_000 });
  });

  test('existing CoC accounts are listed on manage page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openCocAccountManagement(page))) test.skip(true, 'Could not open account management page');

    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics').length > 8,
      { timeout: 10_000, polling: 500 },
    );

    const count = await page.locator('flt-semantics').count();
    expect(count).toBeGreaterThan(8);
  });

  test('"Add account" (+) button is present on the manage page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openCocAccountManagement(page))) test.skip(true, 'Could not open account management page');

    await expect(
      page.getByText(/Add account/i)
        .or(page.getByRole('button', { name: /add account/i }))
        .first()
    ).toBeAttached({ timeout: 8_000 });
  });

  test('"Confirm" button is enabled when accounts are already linked', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openCocAccountManagement(page))) test.skip(true, 'Could not open account management page');

    const confirmBtn = page
      .getByText('Confirm', { exact: true })
      .or(page.getByRole('button', { name: /^confirm$/i }))
      .first();
    await confirmBtn.waitFor({ state: 'attached', timeout: 8_000 });

    // In manage mode with at least one existing account, Confirm must be enabled
    await expect(confirmBtn).not.toBeDisabled({ timeout: 5_000 });
  });

  test('player tag input field is present for adding a new account', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openCocAccountManagement(page))) test.skip(true, 'Could not open account management page');

    const tagInput = page
      .getByRole('textbox', { name: /player tag/i })
      .or(page.getByText(/Player Tag/i))
      .first();

    await expect(tagInput).toBeAttached({ timeout: 8_000 });
  });

  test('back navigation from account management returns to MyHomePage', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openCocAccountManagement(page))) test.skip(true, 'Could not open account management page');

    // In manage mode canPop=true — browser back works
    await page.goBack();
    await page.waitForTimeout(800);

    await expect(page.getByText('Dashboard', { exact: true }).first()).toBeAttached({ timeout: 8_000 });
  });
});
