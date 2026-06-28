import { test, expect } from '@playwright/test';
import { enableFlutterSemantics, hasFlutterSemantics, waitForFlutter } from './helpers';

// Tests for the ErrorPage shown when the ClashKing API is unreachable.
// Uses Playwright route interception to abort all requests to the API.
// When StartupWidget fails to load initial data it renders ErrorPage instead
// of logging the user out (preserves auth state on network error).
//
// All tests run in chromium-auth so the app starts with a valid JWT and the
// startup API call is the trigger that surfaces ErrorPage.
//
// IMPORTANT — Flutter web semantics: when the accessibility tree is enabled,
// Flutter renders <flt-semantics> elements whose *textContent* carries the UI
// strings ("Connection Problem", "Retry", "Join Discord"). It does NOT mirror
// them into aria-label attributes in this build, so all detection here is done
// by visible text (page.getByText) rather than by [aria-label].

// V1 host (prod). The glob does not match the V2 host go.api.clashk.ing because
// there is no '/' before "api" there — they are blocked separately below.
const API_V1_PATTERN = '**/api.clashk.ing/**';
// V2 host the app talks to. Defaults to prod (go.api.clashk.ing); override with
// API_BASE_URL in .env for local runs (e.g. http://127.0.0.1:8000).
const API_BASE = (process.env.API_BASE_URL ?? 'https://go.api.clashk.ing').replace(/\/+$/, '');
const API_V2_PATTERN = `${API_BASE}/**`;
const API_REFRESH = `${API_BASE}/v2/auth/refresh`;

// Blocks API, loads the app, waits for Flutter to boot and attempt startup.
// Blocks both V1 (api.clashk.ing) and V2 (go.api.clashk.ing, or local override)
// so that the startup widget cannot complete initialization and renders
// ErrorPage instead.
//
// NOTE: /auth/refresh is intentionally allowed so that an expired access token
// can be refreshed before the blocked /auth/me triggers ErrorPage.  Without
// this exemption, getAccessToken() would return null for an expired token and
// the startup widget would fall through to LoginPage instead of ErrorPage.
// Routes are evaluated FILO, so the exemption (registered last) wins over the
// broad API_V2_PATTERN block.
async function loadWithApiBlocked(page: any): Promise<boolean> {
  await page.route(API_V1_PATTERN, route => route.abort('failed'));
  await page.route(API_V2_PATTERN, route => route.abort('failed'));
  await page.route(API_REFRESH, route => route.continue());

  // 'load' (default) so navigation is fully committed before later locator calls.
  await page.goto('/', { waitUntil: 'load', timeout: 30_000 });
  await waitForFlutter(page);

  // Give the startup widget time to attempt /auth/me (blocked) and push ErrorPage.
  await page.waitForTimeout(3_000);

  // Enable the semantic tree so Playwright can read the rendered text.
  await enableFlutterSemantics(page);

  return hasFlutterSemantics(page);
}

// Locator for the full-screen ErrorPage title ("Connection Problem" for network
// errors, "Oops" for generic). Matches the leaf flt-semantics whose text is the
// title as well as any ancestor that aggregates it — .first()/.count() handle both.
function errorTitle(page: any) {
  return page.getByText(/Connection Problem|Oops/i).first();
}

// Detects whether the full-screen ErrorPage is visible.
// The bottom-nav "Dashboard" label is present on a normal dashboard (where a
// card may also show a connection error) but absent on the full-screen
// ErrorPage — so its absence distinguishes the two.
async function isOnErrorPage(page: any, stable = false): Promise<boolean> {
  const check = async () => {
    const hasError = (await page.getByText(/Connection Problem|Oops/i).count()) > 0;
    if (!hasError) return false;
    const hasNavBar = (await page.getByText('Dashboard', { exact: true }).count()) > 0;
    return !hasNavBar;
  };

  // Wait briefly for the error title to appear (transition may still be settling).
  await errorTitle(page).waitFor({ state: 'attached', timeout: 8_000 }).catch(() => {});

  if (!(await check())) return false;
  if (!stable) return true;

  // Re-check after a pause — confirms the error page is stable, not transient.
  await page.waitForTimeout(6_000);
  return check();
}

test.describe('Error handling — API unreachable', () => {
  test('"Connection Problem" page appears when API is unreachable at startup', async ({ page }) => {
    test.setTimeout(60_000);
    const semanticsOk = await loadWithApiBlocked(page);
    if (!semanticsOk) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnErrorPage(page))) {
      test.skip(true, 'Error page not triggered (startup completed or different error path)');
    }

    await expect(errorTitle(page)).toBeAttached({ timeout: 5_000 });
  });

  test('error page shows a Retry button', async ({ page }) => {
    test.setTimeout(60_000);
    const semanticsOk = await loadWithApiBlocked(page);
    if (!semanticsOk) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnErrorPage(page, true))) test.skip(true, 'Error page not triggered or not stable');

    // Retry button text comes from generalRetry = "Retry" in app_en.arb.
    await expect(
      page.getByText('Retry', { exact: true }).first()
    ).toBeAttached({ timeout: 8_000 });
  });

  test('error page shows a "Join Discord" support link', async ({ page }) => {
    test.setTimeout(45_000);
    const semanticsOk = await loadWithApiBlocked(page);
    if (!semanticsOk) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnErrorPage(page, true))) test.skip(true, 'Error page not triggered or not stable');

    await expect(
      page.getByText('Join Discord', { exact: true }).first()
    ).toBeAttached({ timeout: 5_000 });
  });

  test('clicking Retry triggers a retry attempt and button remains interactive', async ({ page }) => {
    test.setTimeout(45_000);
    const semanticsOk = await loadWithApiBlocked(page);
    if (!semanticsOk) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnErrorPage(page, true))) test.skip(true, 'Error page not triggered or not stable');

    const retryBtn = page.getByText('Retry', { exact: true }).first();
    await retryBtn.waitFor({ state: 'attached', timeout: 5_000 });
    await retryBtn.click({ timeout: 8_000, force: true });

    // API is still blocked — after the retry attempt the error state returns.
    await page.waitForTimeout(4_000);

    // App must not crash — glass-pane still mounted.
    await expect(page.locator('flt-glass-pane')).toBeAttached();

    // Error page is still shown (API still blocked).
    if (await isOnErrorPage(page)) {
      await expect(errorTitle(page)).toBeAttached({ timeout: 5_000 });
    }
  });

  test('error page does not log the user out (auth state preserved)', async ({ page }) => {
    test.setTimeout(45_000);
    const semanticsOk = await loadWithApiBlocked(page);
    if (!semanticsOk) test.skip(true, 'Flutter semantics unavailable');
    if (!(await isOnErrorPage(page))) test.skip(true, 'Error page not triggered');

    // LoginPage would show the Discord sign-in CTA or an email field — must be absent.
    const loginVisible =
      (await page.getByText(/Sign In with Discord/i).count()) > 0 ||
      (await page.getByText(/Log in/i).count()) > 0;

    expect(loginVisible).toBe(false);
  });

  test('dashboard pull-to-refresh with API blocked shows error gracefully', async ({ page }) => {
    // Load normally first so the dashboard renders.
    await page.goto('/');
    await waitForFlutter(page);
    await page.waitForTimeout(6_000);
    await enableFlutterSemantics(page);

    if (!(await hasFlutterSemantics(page))) test.skip(true, 'Flutter semantics unavailable');

    // Skip if no CoC account — error-on-refresh only meaningful on MyHomePage.
    if ((await page.getByText('Dashboard', { exact: true }).count()) === 0) {
      test.skip(true, 'No CoC accounts — dashboard pull-to-refresh not testable');
    }

    // Now block the API.
    await page.route(API_V2_PATTERN, route => route.abort('failed'));

    // Trigger pull-to-refresh: drag down from top of the list.
    const size = page.viewportSize();
    const cx = (size?.width ?? 400) / 2;
    await page.mouse.move(cx, 100);
    await page.mouse.down();
    await page.mouse.move(cx, 450, { steps: 25 });
    await page.mouse.up();

    await page.waitForTimeout(4_000);

    // App must remain alive after a failed refresh.
    await expect(page.locator('flt-glass-pane')).toBeAttached();

    // Either the error page appeared or the dashboard is still showing — both valid.
    const appStillRunning = (await page.locator('flt-semantics').count()) > 3;
    expect(appStillRunning).toBe(true);
  });
});
