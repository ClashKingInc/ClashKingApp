import { Locator, Page } from "@playwright/test";

const INTERACTIVE_SELECTOR =
  "#root [role], #root [aria-label], #root input, #root button, #root [data-testid]";

/** Wait for Expo Router and React Native Web to mount real DOM content. */
export async function waitForExpo(page: Page) {
  await page.locator("#root").waitFor({ state: "attached", timeout: 10_000 });
  await page.waitForFunction(
    () => (document.querySelector("#root")?.childElementCount ?? 0) > 0,
    { timeout: 10_000 },
  );
}

/** React Native Web exposes accessibility roles directly; no renderer toggle is required. */
export async function waitForExpoAccessibility(page: Page) {
  await waitForExpo(page);
  await page
    .locator(INTERACTIVE_SELECTOR)
    .first()
    .waitFor({ state: "attached", timeout: 10_000 });
}

/**
 * Return true if Expo semantics are currently active on the page.
 * Use this to skip or soften assertions when the tree is unavailable.
 */
export async function hasExpoAccessibility(page: Page): Promise<boolean> {
  return (await page.locator(INTERACTIVE_SELECTOR).count()) > 0;
}

/**
 * Locate an auth segmented-control item.
 *
 * The login UI used to expose Material tabs, but it now renders a custom
 * LiquidGlass segmented control. Expo web may expose those segments as
 * buttons or plain semantics nodes depending on renderer/accessibility state,
 * so tests should not hard-code ARIA tab roles for this control.
 */
export function authSegment(page: Page, name: RegExp): Locator {
  const exactName = /email/i.test(name.source)
    ? /^email(?:\s+email)?$/i
    : /discord/i.test(name.source)
      ? /^discord(?:\s+discord)?$/i
      : name;

  return page
    .getByRole("tab", { name: exactName })
    .or(page.getByRole("button", { name: exactName }))
    .or(page.getByText(exactName))
    .first();
}

export async function clickAuthSegment(page: Page, name: RegExp) {
  await authSegment(page, name).click({ timeout: 8_000 });
}

/**
 * Navigate to '/' and wait for the authenticated app to reach a stable state.
 *
 * After login the app goes through startup coordinator before landing on
 * either authenticated shell (user has CoC accounts → Home primary navigation appears) or
 * account setup (no CoC accounts).  A fixed sleep is unreliable; instead
 * we poll for the Home nav and fall back after 15 s so the account setup
 * case is also handled gracefully.
 */
export async function waitForAppReady(page: Page) {
  await waitForExpoAccessibility(page);
  await page
    .locator(
      '[data-testid="desktop-navigation-shell"], [data-testid="mobile-navigation-shell"]',
    )
    .or(page.getByRole("textbox", { name: /player tag/i }))
    .first()
    .waitFor({ state: "attached", timeout: 25_000 });
}
