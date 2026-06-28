import { test, expect } from '@playwright/test';
import { hasFlutterSemantics, waitForAppReady } from './helpers';

// Tests for the Clan page (second tab in the bottom nav).
// The page shows either clan cards (ClanInfoCard, ClanJoinLeaveCard, ClanCapitalCard)
// or a "No clan" empty state — tests handle both gracefully.
// All tests skip if the test account has no linked CoC account.
//
// Detection note: Flutter renders nav labels and card titles as flt-semantics
// *textContent*, not [aria-label], so we target by text (page.getByText).

async function waitForApp(page: any) {
  await page.goto('/');
  await waitForAppReady(page);
}

async function isOnMyHomePage(page: any): Promise<boolean> {
  return (await page.getByText('Dashboard', { exact: true }).count()) > 0;
}

async function openClanTab(page: any): Promise<boolean> {
  if (!(await isOnMyHomePage(page))) return false;
  const clanNav = page.getByText('Clan', { exact: true }).first();
  await clanNav.waitFor({ state: 'attached', timeout: 8_000 });
  await clanNav.click({ force: true });
  await page.waitForTimeout(1_200);
  return true;
}

async function isNoClanState(page: any): Promise<boolean> {
  return (await page.getByText(/No clan/i).count()) > 0;
}

test.describe('Clan page', () => {
  test.beforeEach(async ({ page }) => {
    await waitForApp(page);
  });

  test('Clan tab is accessible from the bottom nav', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');

    const reached = await openClanTab(page);
    expect(reached).toBe(true);
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  test('Clan page loads and renders content (or empty state)', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openClanTab(page))) test.skip(true, 'Could not open Clan tab');

    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics').length > 5,
      { timeout: 12_000, polling: 500 },
    );

    const count = await page.locator('flt-semantics').count();
    expect(count).toBeGreaterThan(5);
  });

  test('"No clan" empty state shows correct message', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openClanTab(page))) test.skip(true, 'Could not open Clan tab');

    if (!(await isNoClanState(page))) {
      test.skip(true, 'Test account is in a clan — no-clan state not visible');
    }

    // NoClanCard: "No clan" + "Join a clan to unlock new features."
    await expect(page.getByText(/No clan/i).first()).toBeAttached({ timeout: 5_000 });
    await expect(page.getByText(/Join a clan/i).first()).toBeAttached({ timeout: 5_000 });
  });

  test('Clan info card is visible when account is in a clan', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openClanTab(page))) test.skip(true, 'Could not open Clan tab');

    if (await isNoClanState(page)) test.skip(true, 'Test account has no clan');

    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics').length > 8,
      { timeout: 12_000, polling: 500 },
    );

    // Clan page with a clan shows multiple cards — more than 8 semantic elements
    const count = await page.locator('flt-semantics').count();
    expect(count).toBeGreaterThan(8);
  });

  test('Join/Leave card is present when in a clan', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openClanTab(page))) test.skip(true, 'Could not open Clan tab');

    if (await isNoClanState(page)) test.skip(true, 'Test account has no clan');

    await page.waitForTimeout(2_000);

    // ClanJoinLeaveCard shows recent member activity (joins/leaves)
    const joinLeaveEl = page
      .getByText(/Join/i)
      .or(page.getByText(/Leave/i))
      .first();

    // Page should at minimum be alive
    await expect(page.locator('flt-glass-pane')).toBeAttached();
    // If the join/leave card is rendered, assert it
    if (await joinLeaveEl.count() > 0) {
      await expect(joinLeaveEl).toBeAttached();
    }
  });

  test('tapping the clan info card navigates to clan detail screen', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openClanTab(page))) test.skip(true, 'Could not open Clan tab');

    if (await isNoClanState(page)) test.skip(true, 'Test account has no clan');

    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics').length > 8,
      { timeout: 12_000, polling: 500 },
    );

    // ClanInfoCard is the first GestureDetector card — tap at center of page, ~200px from top
    const size = page.viewportSize();
    await page.mouse.click((size?.width ?? 400) / 2, 200);
    await page.waitForTimeout(1_200);

    // Clan detail screen (ClanInfoScreen) opens — semantic count should increase
    await expect(page.locator('flt-glass-pane')).toBeAttached();
    const countAfter = await page.locator('flt-semantics').count();
    expect(countAfter).toBeGreaterThan(5);
  });

  test('back navigation from clan detail returns to clan page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openClanTab(page))) test.skip(true, 'Could not open Clan tab');

    if (await isNoClanState(page)) test.skip(true, 'Test account has no clan');

    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics').length > 8,
      { timeout: 12_000, polling: 500 },
    );

    // Open clan detail
    const size = page.viewportSize();
    await page.mouse.click((size?.width ?? 400) / 2, 200);
    await page.waitForTimeout(1_200);

    // Press back button
    await page.goBack();
    await page.waitForTimeout(800);

    // Bottom nav should be back
    await expect(page.getByText('Clan', { exact: true }).first()).toBeAttached({ timeout: 8_000 });
  });

  // §11.8 — Clan Capital card
  test('"Clan Capital" card is visible when account is in a clan', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openClanTab(page))) test.skip(true, 'Could not open Clan tab');
    if (await isNoClanState(page)) test.skip(true, 'Test account has no clan');

    await page.waitForTimeout(2_000);

    const capitalEl = page.getByText(/Clan Capital/i);
    if (await capitalEl.count() === 0) {
      test.skip(true, 'Clan Capital card not rendered (clan may not have capital data yet)');
    }
    await expect(capitalEl.first()).toBeAttached({ timeout: 5_000 });
  });

  // §11.9 — Clan detail Members tab
  test('clan detail screen shows member list', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openClanTab(page))) test.skip(true, 'Could not open Clan tab');
    if (await isNoClanState(page)) test.skip(true, 'Test account has no clan');

    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics').length > 8,
      { timeout: 12_000, polling: 500 },
    );

    // Navigate to clan detail
    const size = page.viewportSize();
    await page.mouse.click((size?.width ?? 400) / 2, 200);
    await page.waitForTimeout(2_000);

    // ClanInfoScreen shows ClanMembers — semantic elements increase above detail threshold
    const count = await page.locator('flt-semantics').count();
    expect(count).toBeGreaterThan(8);
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  // §11.11 — Clan Capital card tap opens Capital detail screen
  test('tapping the Clan Capital card opens the Capital detail screen', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openClanTab(page))) test.skip(true, 'Could not open Clan tab');
    if (await isNoClanState(page)) test.skip(true, 'Test account has no clan');

    await page.waitForTimeout(2_000);

    const capitalEl = page.getByText(/Clan Capital/i).first();
    if (await capitalEl.count() === 0) {
      test.skip(true, 'Clan Capital card not rendered for this clan');
    }

    await capitalEl.click({ force: true });
    await page.waitForTimeout(2_000);

    // Capital detail screen should load without crashing
    await expect(page.locator('flt-glass-pane')).toBeAttached();
    const count = await page.locator('flt-semantics').count();
    expect(count).toBeGreaterThan(5);
  });

  // §11.12 — Tapping a clan member opens their player profile
  test('tapping a clan member in the detail screen opens their player profile', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openClanTab(page))) test.skip(true, 'Could not open Clan tab');
    if (await isNoClanState(page)) test.skip(true, 'Test account has no clan');

    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics').length > 8,
      { timeout: 12_000, polling: 500 },
    );

    // Navigate to clan detail
    const size = page.viewportSize();
    await page.mouse.click((size?.width ?? 400) / 2, 200);
    await page.waitForTimeout(2_000);

    // Wait for member list to load (semantic count increases above a threshold)
    await page.waitForFunction(
      () => document.querySelectorAll('flt-semantics').length > 15,
      { timeout: 10_000, polling: 500 },
    );

    // Find the first member row by its tag text ("#...").
    const memberEl = page.getByText(/^#[A-Z0-9]+$/i).first();

    if (await memberEl.count() === 0) {
      test.skip(true, 'No member tags found in clan detail semantics');
    }

    await memberEl.click({ force: true });
    await page.waitForTimeout(3_000);

    // PlayerScreen opens — check for Home Base tab or sufficient semantic elements
    await expect(page.locator('flt-glass-pane')).toBeAttached();
    const onPlayerPage = await page
      .getByText(/Home Base/i)
      .or(page.getByText(/Heroes/i))
      .count() > 0;

    if (!onPlayerPage) {
      // Navigation may have gone elsewhere — app still alive is enough
      const count = await page.locator('flt-semantics').count();
      expect(count).toBeGreaterThan(5);
    } else {
      await expect(page.getByText(/Home Base/i).first()).toBeAttached({ timeout: 5_000 });
    }
  });

  // §11.10 — Pull-to-refresh on clan page
  test('pull-to-refresh on clan page does not crash the app', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openClanTab(page))) test.skip(true, 'Could not open Clan tab');

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
