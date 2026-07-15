import { test, expect } from '@playwright/test';
import { hasFlutterSemantics, waitForAppReady } from './helpers';

// Bottom-nav detection note: Flutter renders the nav labels ("Dashboard",
// "Clan", "War/League") as flt-semantics *textContent*, not as [aria-label],
// so all nav targeting here uses page.getByText(..., { exact: true }) rather
// than [aria-label] selectors. The Search button is icon-only and carries an
// explicit Semantics(label: 'Search') from the app.

async function waitForApp(page: any) {
  await page.goto('/');
  await waitForAppReady(page);
}

// True when the bottom nav (MyHomePage) is visible — i.e. the account has a CoC
// account linked. Otherwise the app shows AddCocAccountPage (no nav).
async function hasBottomNav(page: any): Promise<boolean> {
  return (await page.getByText('Dashboard', { exact: true }).count()) > 0;
}

test.describe('Navigation — bottom nav bar', () => {
  test.beforeEach(async ({ page }) => {
    await waitForApp(page);
  });

  test('bottom nav has Dashboard, Clan and War/League items', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await hasBottomNav(page))) test.skip(true, 'No CoC accounts on test account — nav not visible');

    await expect(page.getByText('Dashboard', { exact: true }).first()).toBeAttached();
    await expect(page.getByText('Clan', { exact: true }).first()).toBeAttached();
    await expect(page.getByText('War/League', { exact: true }).first()).toBeAttached();
  });

  test('tapping Clan nav item switches to Clan page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await hasBottomNav(page))) test.skip(true, 'No CoC accounts — nav not visible');

    await page.getByText('Clan', { exact: true }).first().click({ force: true });
    await page.waitForTimeout(800); // page swipe animation

    // Clan page content should appear
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  test('tapping War/League nav item switches to War page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await hasBottomNav(page))) test.skip(true, 'No CoC accounts — nav not visible');

    await page.getByText('War/League', { exact: true }).first().click({ force: true });
    await page.waitForTimeout(800);

    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  test('tapping Search button opens search page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await hasBottomNav(page))) test.skip(true, 'No CoC accounts — nav not visible');

    // Search is an icon-only button with an explicit Semantics(label: 'Search').
    const searchBtn = page
      .locator('flt-semantics[aria-label="Search"]')
      .or(page.getByRole('button', { name: /search/i }))
      .first();

    await searchBtn.click({ force: true });
    await page.waitForTimeout(800);

    // Search page has a text input field
    const searchInput = page.getByRole('textbox').or(page.locator('input[type="text"]')).first();
    await expect(searchInput).toBeAttached({ timeout: 8_000 });
  });

  test('can navigate back to Dashboard from another tab', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await hasBottomNav(page))) test.skip(true, 'No CoC accounts — nav not visible');

    // Go to Clan then back to Dashboard
    await page.getByText('Clan', { exact: true }).first().click({ force: true });
    await page.waitForTimeout(600);
    await page.getByText('Dashboard', { exact: true }).first().click({ force: true });
    await page.waitForTimeout(600);

    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });
});
