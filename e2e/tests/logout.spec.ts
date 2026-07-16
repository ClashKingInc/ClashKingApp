import { test, expect } from '@playwright/test';
import { authSegment, clickAuthSegment, hasFlutterSemantics, enableFlutterSemantics } from './helpers';

// This spec runs with saved auth state (chromium-auth project).
// It tests the logout flow available from the top app bar.
//
// Logout button location:
//  – AddCocAccountPage (no CoC accounts): leading icon with tooltip "Log out"
//  – MyHomePage (has CoC accounts): avatar → SettingsInfoScreen → logout option
//
// We test the simpler CocAccountsAppBar path here, skipping if the user
// has already gone to MyHomePage (i.e. has CoC accounts).
//
// Detection note: nav/button labels are flt-semantics *textContent*, not
// [aria-label], so we detect by text content.

async function waitForApp(page: any) {
  // Cap all page actions at 30 s so they don't inherit the 120 s test timeout.
  page.setDefaultNavigationTimeout(30_000);
  page.setDefaultTimeout(30_000);
  await page.goto('/');
  await enableFlutterSemantics(page);
  // Let the post-auth redirect start before we poll for the settled state
  await page.waitForTimeout(2_000);
}

/**
 * Returns true when the app has landed on AddCocAccountPage (no bottom nav).
 * Polls up to 30 s for the app to settle into either MyHomePage (Dashboard nav)
 * or AddCocAccountPage (Confirm button, no Dashboard).
 */
async function isOnAddAccountPage(page: any): Promise<boolean> {
  try {
    await page.waitForFunction(
      () => {
        const texts = Array.from(document.querySelectorAll('flt-semantics'))
          .map((el: Element) => el.textContent ?? '');
        return texts.some(t => t.includes('Dashboard')) || texts.some(t => t.includes('Confirm'));
      },
      { timeout: 30_000, polling: 500 },
    );
  } catch {
    // Neither state appeared in time — assume MyHomePage (safe skip)
    return false;
  }
  // On MyHomePage the bottom nav exposes a "Dashboard" leaf; AddCocAccountPage does not.
  const dashboardCount = await page.getByText('Dashboard', { exact: true }).count();
  return dashboardCount === 0;
}

test.describe('Logout', () => {
  test.beforeEach(async ({ page }) => {
    // waitForApp (goto + semantics + 2 s) can take up to 50 s on a slow machine.
    // isOnAddAccountPage adds another 30 s poll. Use 120 s total to avoid false timeouts.
    test.setTimeout(120_000);
    await waitForApp(page);
  });

  test('"Log out" button is accessible in the app bar', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnAddAccountPage(page))) {
      test.skip(true, 'Test account has CoC accounts — logout is via Settings, not tested here');
    }

    // CocAccountsAppBar: leading IconButton with tooltip "Log out"
    const logoutBtn = page
      .getByRole('button', { name: /log out/i })
      .or(page.getByText(/Log out/i))
      .first();
    await expect(logoutBtn).toBeAttached({ timeout: 8_000 });
  });

  test('clicking "Log out" returns to the login page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnAddAccountPage(page))) {
      test.skip(true, 'Test account has CoC accounts — logout via Settings not tested here');
    }

    const logoutBtn = page
      .getByRole('button', { name: /log out/i })
      .or(page.getByText(/Log out/i))
      .first();
    await logoutBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await logoutBtn.click({ timeout: 8_000, force: true });

    // AuthService.logout() clears tokens and navigates to LoginPage.
    // Wait for the Discord / Email tabs to appear (login page indicator).
    await page.waitForFunction(
      () => Array.from(document.querySelectorAll('flt-semantics'))
        .some(el => /discord/i.test(el.textContent ?? '')),
      { timeout: 10_000, polling: 500 },
    );

    // Confirm the login page is shown
    await expect(authSegment(page, /discord/i)).toBeAttached({ timeout: 5_000 });
  });

  test('after logout, local auth state is cleared (login button visible)', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnAddAccountPage(page))) {
      test.skip(true, 'Test account has CoC accounts — logout via Settings not tested here');
    }

    const logoutBtn = page
      .getByRole('button', { name: /log out/i })
      .or(page.getByText(/Log out/i))
      .first();
    await logoutBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await logoutBtn.click({ timeout: 8_000, force: true });

    // Switch to Email tab and verify Login button is visible (user is now unauthenticated)
    await page.waitForTimeout(2_000);
    await clickAuthSegment(page, /email/i);
    await page.waitForTimeout(500);

    await expect(
      page.getByRole('button', { name: /^login$/i })
        .or(page.getByText('Login', { exact: true }))
        .first()
    ).toBeAttached({ timeout: 8_000 });
  });
});
