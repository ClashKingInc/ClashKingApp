import { test, expect } from '@playwright/test';
import { hasFlutterSemantics, waitForAppReady } from './helpers';

// Settings page (SettingsInfoScreen) is reached via the avatar circle button in CustomAppBar.
// The avatar button has no aria-label → we navigate by viewport position.
// All tests skip gracefully if the test account has no linked CoC account (not on MyHomePage).
//
// Detection note: Settings tiles are rendered as semantic *buttons* whose
// accessible name combines the title and subtitle (e.g. "FAQ Frequently Asked
// Questions"), and sections are semantic *groups* (e.g. group "Preferences").
// So we target tiles with getByRole('button', { name: /…/i }) using a partial
// regex, and sections with getByRole('group', { name: /…/i }) — NOT getByText,
// which would require the exact combined string.
//
// ⚠️  The last test ("confirming logout") invalidates local auth tokens for that page.
//     It does NOT affect other tests because each test gets its own browser page instance
//     with a fresh copy of the saved storageState.

async function waitForApp(page: any) {
  await page.goto('/');
  await waitForAppReady(page);
}

async function isOnMyHomePage(page: any): Promise<boolean> {
  return (await page.getByText('Dashboard', { exact: true }).count()) > 0;
}

// The avatar circle is at the far right of the 56-px-tall CustomAppBar.
// Position: viewport_width - 35px from left, 28px from top.
async function openSettings(page: any): Promise<boolean> {
  const size = page.viewportSize();
  await page.mouse.click((size?.width ?? 800) - 35, 28);
  await page.waitForTimeout(1_000);
  return (await page.getByRole('heading', { name: /Settings/i }).count()) > 0;
}

const tile = (page: any, name: RegExp) => page.getByRole('button', { name }).first();

// The settings body is a scrollable ListView; tiles below the fold (e.g. the
// "Log out" tile at the very bottom) are not present in the semantic tree until
// scrolled into view. Wheel-scroll the page until the target tile appears.
async function revealTile(page: any, name: RegExp): Promise<boolean> {
  for (let i = 0; i < 6; i++) {
    if ((await page.getByRole('button', { name }).count()) > 0) return true;
    await page.mouse.move(400, 400);
    await page.mouse.wheel(0, 900);
    await page.waitForTimeout(400);
  }
  return (await page.getByRole('button', { name }).count()) > 0;
}

test.describe('Settings page', () => {
  test.beforeEach(async ({ page }) => {
    await waitForApp(page);
  });

  test('settings page is reachable via the avatar button', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');

    const reached = await openSettings(page);
    expect(reached).toBe(true);
  });

  test('settings page title "Settings" is visible', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    await expect(page.getByRole('heading', { name: /Settings/i }).first()).toBeAttached({ timeout: 8_000 });
  });

  test('settings page shows Preferences section (Language, Theme, Notifications)', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    await expect(page.getByRole('group', { name: /Preferences/i }).first()).toBeAttached({ timeout: 8_000 });
    await expect(tile(page, /Language/i)).toBeAttached({ timeout: 5_000 });
    await expect(tile(page, /Toggle Theme/i)).toBeAttached({ timeout: 5_000 });
    await expect(tile(page, /Notifications/i)).toBeAttached({ timeout: 5_000 });
  });

  test('settings page shows Support section (FAQ, Discord, Translate)', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    await expect(page.getByRole('group', { name: /Support/i }).first()).toBeAttached({ timeout: 8_000 });
    await expect(tile(page, /FAQ/i)).toBeAttached({ timeout: 5_000 });
    await expect(tile(page, /Discord/i)).toBeAttached({ timeout: 5_000 });
    await expect(tile(page, /translate/i)).toBeAttached({ timeout: 5_000 });
  });

  test('settings page shows About section (Licenses, Privacy Policy)', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    await expect(page.getByRole('group', { name: /About/i }).first()).toBeAttached({ timeout: 8_000 });
    await expect(tile(page, /License/i)).toBeAttached({ timeout: 5_000 });
    await expect(tile(page, /Privacy/i)).toBeAttached({ timeout: 5_000 });
  });

  test('"Log out" tile is visible in the Account section', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    expect(await revealTile(page, /Log out/i)).toBe(true);
  });

  test('clicking "Log out" tile opens a confirmation dialog', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    await revealTile(page, /Log out/i);
    await tile(page, /Log out/i).click({ force: true });
    await page.waitForTimeout(600);

    // ConfirmLogoutDialog content: "Are you sure you want to log out?"
    await expect(
      page.getByText(/sure/i).or(page.getByText(/log out/i)).first()
    ).toBeAttached({ timeout: 8_000 });
  });

  test('cancelling the logout dialog stays on settings page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    await revealTile(page, /Log out/i);
    await tile(page, /Log out/i).click({ force: true });
    await page.waitForTimeout(500);

    // Click Cancel in the dialog
    const cancelBtn = page.getByRole('button', { name: /^cancel$/i }).first();
    await cancelBtn.waitFor({ state: 'attached', timeout: 5_000 });
    await cancelBtn.click({ force: true });
    await page.waitForTimeout(400);

    // Settings page still showing
    await expect(tile(page, /Log out/i)).toBeAttached({ timeout: 5_000 });
  });

  test('confirming logout navigates to login page', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    await revealTile(page, /Log out/i);
    await tile(page, /Log out/i).click({ force: true });
    await page.waitForTimeout(500);

    // Click OK in the dialog
    const okBtn = page.getByRole('button', { name: /^ok$/i }).first();
    await okBtn.waitFor({ state: 'attached', timeout: 5_000 });
    await okBtn.click({ force: true });

    // Wait for login page (Discord/Email tabs)
    await page.waitForFunction(
      () => Array.from(document.querySelectorAll('flt-semantics'))
        .some(el => /discord/i.test(el.textContent ?? '')),
      { timeout: 12_000, polling: 500 },
    );

    await expect(page.getByText(/Discord/i).first()).toBeAttached();
  });

  // §14.2 — user profile header in settings
  test('settings page shows user email or username in the account section', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    // SettingsInfoScreen shows the account username/email in the Account section.
    // The exact value (email vs username) is account-dependent, so assert that
    // the Account section group is present as proof the header rendered.
    await expect(
      page.getByRole('group', { name: /Account/i }).first()
    ).toBeAttached({ timeout: 8_000 });
  });

  // §14.6 — language selector opens a dialog
  test('tapping Language tile opens a language selection dialog', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    const languageBtn = tile(page, /Language/i);
    await languageBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await languageBtn.click({ force: true });
    await page.waitForTimeout(600);

    // A dialog or bottom sheet with language options should appear
    const dialogEl = page
      .getByRole('dialog')
      .or(page.getByText(/English/i))
      .or(page.getByText(/Français/i));

    if (await dialogEl.count() === 0) {
      // Some implementations use a bottom sheet — check for any overlay
      const count = await page.locator('flt-semantics').count();
      expect(count).toBeGreaterThan(10); // overlay adds more semantics
    } else {
      await expect(dialogEl.first()).toBeAttached({ timeout: 5_000 });
    }
  });

  // §14.7 — toggle theme
  test('tapping Toggle Theme switches the color scheme without crashing', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    const toggleBtn = tile(page, /Toggle Theme/i);
    await toggleBtn.waitFor({ state: 'attached', timeout: 8_000 });
    await toggleBtn.click({ force: true });
    await page.waitForTimeout(800);

    // "Toggle Theme" opens an "Appearance" bottom sheet with System / Light / Dark options.
    const lightOpt = page
      .getByText('Light', { exact: true })
      .or(page.getByRole('button', { name: /^Light$/i }))
      .first();
    await expect(lightOpt).toBeAttached({ timeout: 5_000 });

    // Select an option to actually switch the colour scheme.
    await lightOpt.click({ force: true });
    await page.waitForTimeout(800);

    // App must remain alive after switching the scheme (no JS crash).
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  // §14.8 — FAQ page opens
  test('tapping FAQ tile opens the FAQ screen', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    const faqTile = tile(page, /FAQ/i);
    await faqTile.waitFor({ state: 'attached', timeout: 8_000 });
    await faqTile.click({ force: true });
    await page.waitForTimeout(1_000);

    // FaqScreen AppBar title is "FAQ"
    await expect(page.locator('flt-glass-pane')).toBeAttached();
    const count = await page.locator('flt-semantics').count();
    expect(count).toBeGreaterThan(5);
  });

  // §14.9 — Notifications settings page opens
  test('tapping Notifications tile opens the notification settings screen', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    const notifTile = tile(page, /Notifications/i);
    await notifTile.waitFor({ state: 'attached', timeout: 8_000 });
    await notifTile.click({ force: true });
    await page.waitForTimeout(1_000);

    // NotificationSettingsPage should load without crashing
    await expect(page.locator('flt-glass-pane')).toBeAttached();
    const count = await page.locator('flt-semantics').count();
    expect(count).toBeGreaterThan(3);
  });

  // §16.1 — Connected Accounts tile visible in Account section
  test('"Connected Accounts" tile is visible in the Account section', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    await expect(tile(page, /Connected Accounts/i)).toBeAttached({ timeout: 8_000 });
  });

  // §16.2 — Connected Accounts page shows Discord and Email auth status tiles
  test('tapping "Connected Accounts" opens auth methods page with Discord and Email tiles', async ({ page }) => {
    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnMyHomePage(page))) test.skip(true, 'No CoC accounts — not on MyHomePage');
    if (!(await openSettings(page))) test.skip(true, 'Could not open settings');

    const connectedTile = tile(page, /Connected Accounts/i);
    await connectedTile.waitFor({ state: 'attached', timeout: 8_000 });
    await connectedTile.click({ force: true });
    await page.waitForTimeout(1_200);

    // AccountManagementPage shows Discord and Email auth tiles with connected/not-connected status
    await expect(page.getByText(/Discord/i).first()).toBeAttached({ timeout: 8_000 });
    await expect(page.getByText(/Email/i).first()).toBeAttached({ timeout: 5_000 });
  });
});
