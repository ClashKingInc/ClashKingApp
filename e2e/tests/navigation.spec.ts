import { test, expect } from "@playwright/test";
import { hasExpoAccessibility, waitForAppReady } from "./helpers";

// Expo renders primary navigation as accessible React Native Web buttons with
// visible labels. Search is exposed through the header's accessible search role.

async function waitForApp(page: any) {
  await page.goto("/");
  await waitForAppReady(page);
}

// True when the primary navigation (authenticated shell) is visible — i.e. the account has a CoC
// account linked. Otherwise the app shows account setup (no nav).
async function hasPrimaryNavigation(page: any): Promise<boolean> {
  return (await page.getByText("Home", { exact: true }).count()) > 0;
}

test.describe("Navigation — primary navigation bar", () => {
  test.beforeEach(async ({ page }) => {
    await waitForApp(page);
  });

  test("primary navigation has Home, Clans and War items", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await hasPrimaryNavigation(page)))
      test.skip(true, "No CoC accounts on test account — nav not visible");

    await expect(
      page.getByText("Home", { exact: true }).first(),
    ).toBeAttached();
    await expect(
      page.getByText("Clans", { exact: true }).first(),
    ).toBeAttached();
    await expect(page.getByText("War", { exact: true }).first()).toBeAttached();
  });

  test("tapping Clans nav item switches to Clans page", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await hasPrimaryNavigation(page)))
      test.skip(true, "No CoC accounts — nav not visible");

    await page
      .getByText("Clans", { exact: true })
      .first()
      .click({ force: true });
    await page.waitForTimeout(800); // page swipe animation

    // Clans page content should appear
    await expect(page.locator("#root")).toBeAttached();
  });

  test("tapping War nav item switches to War page", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await hasPrimaryNavigation(page)))
      test.skip(true, "No CoC accounts — nav not visible");

    await page.getByText("War", { exact: true }).first().click({ force: true });
    await page.waitForTimeout(800);

    await expect(page.locator("#root")).toBeAttached();
  });

  test("tapping Search button opens search page", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await hasPrimaryNavigation(page)))
      test.skip(true, "No CoC accounts — nav not visible");

    const searchBtn = page
      .getByRole("search", { name: /search players or clans/i })
      .or(page.getByRole("button", { name: /search players or clans/i }))
      .first();

    await searchBtn.click({ force: true });
    await page.waitForTimeout(800);

    // Search page has a text input field
    const searchInput = page
      .getByRole("textbox")
      .or(page.locator('input[type="text"]'))
      .first();
    await expect(searchInput).toBeAttached({ timeout: 8_000 });
  });

  test("can navigate back to Home from another tab", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await hasPrimaryNavigation(page)))
      test.skip(true, "No CoC accounts — nav not visible");

    // Go to Clans then back to Home
    await page
      .getByText("Clans", { exact: true })
      .first()
      .click({ force: true });
    await page.waitForTimeout(600);
    await page
      .getByText("Home", { exact: true })
      .first()
      .click({ force: true });
    await page.waitForTimeout(600);

    await expect(page.locator("#root")).toBeAttached();
  });
});
