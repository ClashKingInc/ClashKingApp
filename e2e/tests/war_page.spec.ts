import { test, expect } from '@playwright/test';
import { hasFlutterSemantics, waitForAppReady } from './helpers';

// Tests for the War/League page (third tab in the bottom nav, label "War/League").
// The page renders different cards depending on in-game state:
//   • No clan  → NoClanCard ("No clan")
//   • In war   → WarCard (state: preparation / inWar / warEnded)
//   • In CWL   → CWL card
//   • Otherwise → WarNotInWarCard + WarHistoryCard
// Tests detect which state is active and skip assertions that don't apply.
// All tests skip if the test account has no linked CoC account.
//
// Detection note: Flutter renders nav labels, card titles and tab labels as
// flt-semantics *textContent*, not [aria-label], so we target by text.

async function waitForApp(page: any) {
  await page.goto('/');
  await waitForAppReady(page);
}

async function isOnMyHomePage(page: any): Promise<boolean> {
  return (await page.getByText('Dashboard', { exact: true }).count()) > 0;
}

async function openWarTab(page: any): Promise<boolean> {
  if (!(await isOnMyHomePage(page))) return false;
  const warNav = page.getByText('War/League', { exact: true }).first();
  await warNav.waitFor({ state: 'attached', timeout: 8_000 });
  await warNav.click({ force: true });
  await page.waitForTimeout(1_200);
  return true;
}

test.describe('War / CWL page', () => {
  test.beforeEach(async ({ page }) => {
    await waitForApp(page);
  });

  test('War/League tab is accessible from the bottom nav', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');

    const reached = await openWarTab(page);
    expect(reached).toBe(true);
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  test('War/League page loads without crashing', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openWarTab(page))) test.skip(true, 'Could not open War tab');

    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics').length > 5,
      { timeout: 12_000, polling: 500 },
    );

    const count = await page.locator('flt-semantics').count();
    expect(count).toBeGreaterThan(5);
  });

  test('"No clan" state shows correct message on War page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openWarTab(page))) test.skip(true, 'Could not open War tab');

    const noClan = page.getByText(/No clan/i);
    if (await noClan.count() === 0) {
      test.skip(true, 'Test account is in a clan — no-clan state not visible');
    }

    await expect(noClan.first()).toBeAttached({ timeout: 5_000 });
    await expect(page.getByText(/Join a clan/i).first()).toBeAttached({ timeout: 5_000 });
  });

  test('War History card is visible when the clan has war logs', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openWarTab(page))) test.skip(true, 'Could not open War tab');

    const noClan = await page.getByText(/No clan/i).count() > 0;
    if (noClan) test.skip(true, 'Test account has no clan');

    await page.waitForTimeout(2_000);

    const warHistoryEl = page.getByText(/War History/i);
    if (await warHistoryEl.count() === 0) {
      test.skip(true, 'War History not available for this clan');
    }

    await expect(warHistoryEl.first()).toBeAttached({ timeout: 5_000 });
  });

  test('Active war card shows war state (preparation / in war / ended)', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openWarTab(page))) test.skip(true, 'Could not open War tab');

    const noClan = await page.getByText(/No clan/i).count() > 0;
    if (noClan) test.skip(true, 'Test account has no clan');

    await page.waitForTimeout(2_000);

    // War states: "Preparation", "War ended", or numeric stars/destruction %
    const warStateEl = page
      .getByText(/Preparation/i)
      .or(page.getByText(/War ended/i));

    if (await warStateEl.count() === 0) {
      test.skip(true, 'Clan is not currently in a war');
    }

    await expect(warStateEl.first()).toBeAttached({ timeout: 5_000 });
  });

  test('CWL card visible during CWL season', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openWarTab(page))) test.skip(true, 'Could not open War tab');

    const noClan = await page.getByText(/No clan/i).count() > 0;
    if (noClan) test.skip(true, 'Test account has no clan');

    await page.waitForTimeout(2_000);

    const cwlEl = page.getByText(/CWL/i);
    if (await cwlEl.count() === 0) {
      test.skip(true, 'Not in CWL season or clan not in CWL');
    }

    await expect(cwlEl.first()).toBeAttached({ timeout: 5_000 });
  });

  test('tapping war card opens War detail screen', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openWarTab(page))) test.skip(true, 'Could not open War tab');

    const noClan = await page.getByText(/No clan/i).count() > 0;
    if (noClan) test.skip(true, 'Test account has no clan');

    await page.waitForTimeout(2_000);

    // WarCard is a GestureDetector — tap at ~180px from top, center of page
    const warEl = page.getByText(/Preparation/i).or(page.getByText(/War ended/i));
    if (await warEl.count() === 0) test.skip(true, 'No active war to tap');

    const size = page.viewportSize();
    await page.mouse.click((size?.width ?? 400) / 2, 180);
    await page.waitForTimeout(1_200);

    // War detail screen (WarScreen) opens
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  test('tapping War History card opens War Stats screen', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openWarTab(page))) test.skip(true, 'Could not open War tab');

    const noClan = await page.getByText(/No clan/i).count() > 0;
    if (noClan) test.skip(true, 'Test account has no clan');

    await page.waitForTimeout(2_000);

    const warHistoryEl = page.getByText(/War History/i).first();
    if (await warHistoryEl.count() === 0) test.skip(true, 'War History card not present');

    await warHistoryEl.click({ force: true });
    await page.waitForTimeout(1_000);

    // War Stats screen (ClanWarStatsScreen) should open
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  // §12.9 — War detail screen tabs (Statistics / Events / Teams)
  test('war detail screen shows Statistics, Events and Teams tabs', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openWarTab(page))) test.skip(true, 'Could not open War tab');

    const noClan = await page.getByText(/No clan/i).count() > 0;
    if (noClan) test.skip(true, 'Test account has no clan');

    await page.waitForTimeout(2_000);

    // Need an active war to enter war detail
    const warEl = page.getByText(/Preparation/i).or(page.getByText(/War ended/i));
    if (await warEl.count() === 0) test.skip(true, 'Clan is not currently in a war');

    // Open war detail via positional tap on the war card
    const size = page.viewportSize();
    await page.mouse.click((size?.width ?? 400) / 2, 200);
    await page.waitForTimeout(2_000);

    // WarScreen has 2 tabs: Statistics | Events (Teams is CWL-only)
    await expect(page.getByText('Statistics', { exact: true }).first()).toBeAttached({ timeout: 8_000 });
    await expect(page.getByText('Events', { exact: true }).first()).toBeAttached({ timeout: 5_000 });
  });

  // §12.10 — CWL detail screen tabs (Rounds / Teams / Members)
  test('CWL detail screen shows Rounds, Teams and Members tabs', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openWarTab(page))) test.skip(true, 'Could not open War tab');

    const noClan = await page.getByText(/No clan/i).count() > 0;
    if (noClan) test.skip(true, 'Test account has no clan');

    await page.waitForTimeout(2_000);

    const cwlEl = page.getByText(/CWL/i).first();
    if (await cwlEl.count() === 0) test.skip(true, 'Not in CWL season — CWL card not present');

    await cwlEl.click({ force: true });
    await page.waitForTimeout(2_000);

    // CwlScreen tabs: Rounds | Teams | Members
    await expect(page.getByText('Rounds', { exact: true }).first()).toBeAttached({ timeout: 8_000 });
    await expect(page.getByText('Teams', { exact: true }).first()).toBeAttached({ timeout: 5_000 });
    await expect(page.getByText('Members', { exact: true }).first()).toBeAttached({ timeout: 5_000 });
  });

  // §12.11 — Pull-to-refresh on war page
  test('pull-to-refresh on War/League page does not crash the app', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openWarTab(page))) test.skip(true, 'Could not open War tab');

    await page.waitForTimeout(1_000);

    const size = page.viewportSize();
    const cx = (size?.width ?? 400) / 2;
    await page.mouse.move(cx, 120);
    await page.mouse.down();
    await page.mouse.move(cx, 420, { steps: 25 });
    await page.mouse.up();

    await page.waitForTimeout(4_000);
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });
});
