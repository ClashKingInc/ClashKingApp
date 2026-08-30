import { test, expect } from "@playwright/test";
import { hasExpoAccessibility, waitForAppReady } from "./helpers";

// Tests for actual dashboard content (player cards, navigation, account selector).
// Complements dashboard.spec.ts which only checks auth state.
// All tests skip gracefully when the test account has no linked CoC account.
//
// Detection note: Expo renders nav labels as #root [role], #root input, #root button *textContent*,
// not [aria-label], so we target by text (page.getByText).

async function waitForApp(page: any) {
  await page.goto("/");
  await waitForAppReady(page);
}

async function isOnAuthenticatedShell(page: any): Promise<boolean> {
  return (await page.getByText("Home", { exact: true }).count()) > 0;
}

test.describe("Home content", () => {
  test.beforeEach(async ({ page }) => {
    await waitForApp(page);
  });

  test("primary navigation is fully rendered", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    await expect(page.getByText("Home", { exact: true }).first()).toBeAttached({
      timeout: 8_000,
    });
    await expect(
      page.getByText("Clans", { exact: true }).first(),
    ).toBeAttached();
    await expect(page.getByText("War", { exact: true }).first()).toBeAttached();
  });

  test("manage accounts action is visible in the desktop shell", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    await expect(
      page.getByRole("button", { name: /manage accounts/i }).first(),
    ).toBeAttached({
      timeout: 8_000,
    });
  });

  test("dashboard page shows at least one content card", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    // Home shows PlayerCard, PlayerToDoCard, PlayerWarStatsCard, etc.
    // We wait for the semantics tree to grow beyond just the nav items.
    await page.waitForFunction(
      () =>
        document.querySelectorAll("#root [role], #root input, #root button")
          .length > 10,
      { timeout: 15_000, polling: 500 },
    );

    const count = await page
      .locator("#root [role], #root input, #root button")
      .count();
    expect(count).toBeGreaterThan(10);
  });

  test("switching to Clan tab and back to Home works", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    const clanNav = page.getByText("Clans", { exact: true }).first();
    await clanNav.waitFor({ state: "attached", timeout: 8_000 });
    await clanNav.click({ force: true });
    await page.waitForTimeout(800);

    const dashNav = page.getByText("Home", { exact: true }).first();
    await dashNav.waitFor({ state: "attached", timeout: 8_000 });
    await dashNav.click({ force: true });
    await page.waitForTimeout(800);

    // Back on dashboard — #root still alive
    await expect(page.locator("#root")).toBeAttached();
  });

  test("switching to War tab does not crash", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    const warNav = page.getByText("War", { exact: true }).first();
    await warNav.waitFor({ state: "attached", timeout: 8_000 });
    await warNav.click({ force: true });
    await page.waitForTimeout(1_000);

    // Page still alive — no JS crash
    await expect(page.locator("#root")).toBeAttached();
    // Should show either war content or a "no active war" message
    const semanticsCount = await page
      .locator("#root [role], #root input, #root button")
      .count();
    expect(semanticsCount).toBeGreaterThan(3);
  });

  test("opening Manage accounts renders account management", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    await page
      .getByRole("button", { name: /manage accounts/i })
      .first()
      .click();
    await expect(page.getByText(/Manage your accounts/i).first()).toBeAttached({
      timeout: 8_000,
    });
  });

  test("Home remains reachable after opening account management", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    await page
      .getByRole("button", { name: /manage accounts/i })
      .first()
      .click();
    await expect(page.getByText(/Manage your accounts/i).first()).toBeAttached({
      timeout: 8_000,
    });
    await page.getByText("Home", { exact: true }).first().click();
    await expect(page.getByText("Home", { exact: true }).first()).toBeAttached({
      timeout: 5_000,
    });
  });
});
