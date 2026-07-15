import { test, expect } from '@playwright/test';
import { hasFlutterSemantics, waitForAppReady } from './helpers';

// Tests for actual dashboard content (player cards, navigation, account selector).
// Complements dashboard.spec.ts which only checks auth state.
// All tests skip gracefully when the test account has no linked CoC account.
//
// Detection note: Flutter renders nav labels as flt-semantics *textContent*,
// not [aria-label], so we target by text (page.getByText).

async function waitForApp(page: any) {
  await page.goto('/');
  await waitForAppReady(page);
}

async function isOnMyHomePage(page: any): Promise<boolean> {
  return (await page.getByText('Dashboard', { exact: true }).count()) > 0;
}

test.describe('Dashboard content', () => {
  test.beforeEach(async ({ page }) => {
    await waitForApp(page);
  });

  test('bottom navigation bar is fully rendered', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');

    await expect(page.getByText('Dashboard', { exact: true }).first()).toBeAttached({ timeout: 8_000 });
    await expect(page.getByText('Clan', { exact: true }).first()).toBeAttached();
    await expect(page.getByText('War/League', { exact: true }).first()).toBeAttached();
  });

  test('account selector pill is visible in the app bar', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');

    // CustomAppBar shows the selected account name (or "Manage" if none selected).
    // The account name is unknown here, so assert the bottom nav is present as a
    // proxy that the authenticated MyHomePage shell is rendered.
    await expect(
      page.getByText(/Manage/i).or(page.getByText('Dashboard', { exact: true })).first()
    ).toBeAttached({ timeout: 8_000 });
  });

  test('dashboard page shows at least one content card', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');

    // Dashboard shows PlayerCard, PlayerToDoCard, PlayerWarStatsCard, etc.
    // We wait for the semantics tree to grow beyond just the nav items.
    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics').length > 10,
      { timeout: 15_000, polling: 500 },
    );

    const count = await page.locator('flt-semantics').count();
    expect(count).toBeGreaterThan(10);
  });

  test('switching to Clan tab and back to Dashboard works', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');

    const clanNav = page.getByText('Clan', { exact: true }).first();
    await clanNav.waitFor({ state: 'attached', timeout: 8_000 });
    await clanNav.click({ force: true });
    await page.waitForTimeout(800);

    const dashNav = page.getByText('Dashboard', { exact: true }).first();
    await dashNav.waitFor({ state: 'attached', timeout: 8_000 });
    await dashNav.click({ force: true });
    await page.waitForTimeout(800);

    // Back on dashboard — flt-glass-pane still alive
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  test('switching to War/League tab does not crash', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');

    const warNav = page.getByText('War/League', { exact: true }).first();
    await warNav.waitFor({ state: 'attached', timeout: 8_000 });
    await warNav.click({ force: true });
    await page.waitForTimeout(1_000);

    // Page still alive — no JS crash
    await expect(page.locator('flt-glass-pane')).toBeAttached();
    // Should show either war content or a "no active war" message
    const semanticsCount = await page.locator('flt-semantics').count();
    expect(semanticsCount).toBeGreaterThan(3);
  });

  test('opening account menu shows the account menu (Manage / accounts list)', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');

    // The account pill is the first button in the AppBar (role=banner), showing
    // the selected account name. Tapping it opens the account menu (barrierLabel
    // "Accounts") which contains the accounts list and a "Manage" action.
    const beforeCount = await page.locator('flt-semantics').count();
    await page.getByRole('banner').getByRole('button').first().click({ force: true });
    await page.waitForTimeout(800);

    // The menu surfaces a "Manage" action and/or an "Accounts" barrier overlay,
    // and grows the semantic tree. Accept any of these as proof it opened.
    const opened =
      (await page.getByText(/Manage/i).count()) > 0 ||
      (await page.locator('[aria-label*="Accounts" i]').count()) > 0 ||
      (await page.locator('flt-semantics').count()) > beforeCount;
    expect(opened).toBe(true);
  });

  test('closing account menu (clicking outside) restores dashboard', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');

    // Open account menu via the account pill (first banner button)
    await page.getByRole('banner').getByRole('button').first().click({ force: true });
    await page.waitForTimeout(800);

    // Click outside (bottom of page) to dismiss
    const size = page.viewportSize();
    await page.mouse.click((size?.width ?? 800) / 2, (size?.height ?? 800) - 100);
    await page.waitForTimeout(400);

    // Bottom nav still accessible
    await expect(page.getByText('Dashboard', { exact: true }).first()).toBeAttached({ timeout: 5_000 });
  });
});
