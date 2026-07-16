import { Locator, Page } from '@playwright/test';

/** Wait until Flutter finishes its initial frame render */
export async function waitForFlutter(page: Page) {
  await page.locator('flt-glass-pane').waitFor({ state: 'attached', timeout: 10_000 });
  // Give Flutter a frame to paint before we interact
  await page.waitForTimeout(500);
}

/**
 * Enable the Flutter web semantic tree so Playwright can use accessible roles/labels.
 *
 * Flutter only renders `flt-semantics` elements when accessibility mode is active.
 * This function tries three escalating methods to activate it:
 *  1. Click the "Enable accessibility" button Flutter puts in the page DOM
 *  2. Tab-key navigation (signals keyboard usage → Flutter enables semantics)
 *  3. Direct JS call into Flutter's internal API as a last resort
 */
export async function enableFlutterSemantics(page: Page) {
  await waitForFlutter(page);

  // Method 1 — Flutter renders a focusable "Enable accessibility" button.
  // It lives outside the shadow root as a regular DOM element.
  const enabled = await page.evaluate(() => {
    // Walk all elements looking for the Flutter accessibility toggle
    const candidates = document.querySelectorAll('[role="button"], button, [aria-label]');
    for (const el of candidates) {
      const label = el.getAttribute('aria-label') ?? el.textContent ?? '';
      if (/accessibility/i.test(label)) {
        (el as HTMLElement).click();
        return true;
      }
    }
    // Also try inside flt-glass-pane shadow root
    const glassPane = document.querySelector('flt-glass-pane');
    if (glassPane?.shadowRoot) {
      const shadowCandidates = glassPane.shadowRoot.querySelectorAll('[role="button"], button, [aria-label]');
      for (const el of shadowCandidates) {
        const label = el.getAttribute('aria-label') ?? el.textContent ?? '';
        if (/accessibility/i.test(label)) {
          (el as HTMLElement).click();
          return true;
        }
      }
    }
    return false;
  });

  if (!enabled) {
    // Method 2 — Tab triggers keyboard-navigation mode which forces semantics on.
    // Click at (100, 250) to avoid Flutter's 44 px tap targets in the corner
    // (e.g. the ErrorPage exit button whose hitbox spans roughly 5–49 px on each axis).
    await page.locator('flt-glass-pane').click({
      force: true,
      timeout: 5_000,
      position: { x: 100, y: 250 },
    });
    await page.keyboard.press('Tab');
    await page.waitForTimeout(800);
  }

  // Give Flutter up to 3 s to create the semantic tree
  try {
    await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: 3_000 });
  } catch {
    // Semantics tree did not appear — tests that need it will fail with clear messages
  }
}

/**
 * Return true if Flutter semantics are currently active on the page.
 * Use this to skip or soften assertions when the tree is unavailable.
 */
export async function hasFlutterSemantics(page: Page): Promise<boolean> {
  const count = await page.locator('flt-semantics').count();
  return count > 0;
}

/**
 * Locate an auth segmented-control item.
 *
 * The login UI used to expose Material tabs, but it now renders a custom
 * LiquidGlass segmented control. Flutter web may expose those segments as
 * buttons or plain semantics nodes depending on renderer/accessibility state,
 * so tests should not hard-code ARIA tab roles for this control.
 */
export function authSegment(page: Page, name: RegExp): Locator {
  const exactName = /email/i.test(name.source)
    ? /^email$/i
    : /discord/i.test(name.source)
      ? /^discord$/i
      : name;

  return page
    .getByRole('tab', { name: exactName })
    .or(page.getByRole('button', { name: exactName }))
    .or(page.locator('flt-semantics').filter({ hasText: exactName }))
    .first();
}

export async function clickAuthSegment(page: Page, name: RegExp) {
  const segment = authSegment(page, name);
  await segment.waitFor({ state: 'attached', timeout: 8_000 });
  const box = await segment.boundingBox();
  if (box) {
    await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    return;
  }
  await segment.click({ timeout: 8_000, force: true });
}

/**
 * Navigate to '/' and wait for the authenticated app to reach a stable state.
 *
 * After login the app goes through _PostAuthLoadingScreen before landing on
 * either MyHomePage (user has CoC accounts → Dashboard bottom-nav appears) or
 * AddCocAccountPage (no CoC accounts).  A fixed sleep is unreliable; instead
 * we poll for the Dashboard nav and fall back after 15 s so the AddCocAccountPage
 * case is also handled gracefully.
 */
export async function waitForAppReady(page: Page) {
  await waitForFlutter(page);
  await enableFlutterSemantics(page);
  // Wait up to 25 s for the app to settle past the _PostAuthLoadingScreen
  // ("Almost ready..."), which has only ~7 flt-semantics nodes. MyHomePage and
  // AddCocAccountPage both produce many more, so a node-count threshold detects
  // either landing page. The bottom-nav uses custom _GlassNavItem widgets
  // (not ARIA tabs), so we poll for tree size rather than a specific label.
  await page.waitForFunction(
    () => document.querySelectorAll('flt-semantics').length > 8,
    { timeout: 25_000, polling: 500 },
  ).catch(() => { /* app may be on AddCocAccountPage or still loading — proceed */ });
  // Small settle so late-rendered cards register in the semantic tree.
  // NB: we deliberately do NOT call enableFlutterSemantics again here — the
  // accessibility mode set above persists across the post-auth navigation, and
  // its fallback path clicks into the page (which on a loaded dashboard would
  // activate a card / navigate away).
  await page.waitForTimeout(500);
}
