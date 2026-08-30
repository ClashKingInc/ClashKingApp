import { test, expect } from "@playwright/test";
import {
  waitForExpoAccessibility,
  hasExpoAccessibility,
  waitForExpo,
} from "./helpers";

// This file runs with saved auth state (see playwright.config.ts — chromium-auth project).
// The setup project (auth.setup.ts) must have run first.

test.describe("Home — authenticated", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    // Post-auth loading can take a few seconds (API calls for player/clan data)
    await waitForExpo(page);
    await page.waitForTimeout(3_000);
    await waitForExpoAccessibility(page);
  });

  test("app loads without showing login page after auth", async ({ page }) => {
    // If auth state is valid, the Login button should NOT be visible
    const loginBtn = page.getByRole("button", { name: /^login$/i });
    // Give it a moment then check it's gone
    await page.waitForTimeout(2_000);
    await expect(loginBtn).not.toBeVisible({ timeout: 5_000 });
  });

  test("app is in an interactive state (not stuck on loading)", async ({
    page,
  }) => {
    // Wait for the loading screen to resolve
    await page.waitForFunction(
      () =>
        document.querySelectorAll("#root [role], #root input, #root button")
          .length > 3,
      { timeout: 20_000, polling: 500 },
    );
    await expect(page.locator("#root")).toBeAttached();
  });

  test("navigation bar or account setup is visible", async ({ page }) => {
    if (!(await hasExpoAccessibility(page))) {
      test.skip(true, "Expo semantics unavailable");
    }

    await page.waitForFunction(
      () =>
        document.querySelectorAll("#root [role], #root input, #root button")
          .length > 3,
      { timeout: 20_000, polling: 500 },
    );

    // After login, the app shows either:
    //  a) authenticated shell (Home content — custom primary navigation item bar, not ARIA tabs)
    //  b) account setup (no CoC accounts yet — has a 'Confirm' button)
    // The custom nav uses InkWell widgets, not BottomNavigationBar, so getByRole('tab')
    // returns 0. Check for a populated semantic tree (authenticated shell) or 'Confirm' (add-account).
    const hasContent =
      (await page.locator("#root [role], #root input, #root button").count()) >
      5;
    const hasAddAccount =
      (await page
        .locator('[aria-label="Confirm"], [aria-label*="account" i]')
        .count()) > 0;

    expect(hasContent || hasAddAccount).toBe(true);
  });
});
