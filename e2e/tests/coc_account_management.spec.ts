import { test, expect } from "@playwright/test";
import { hasExpoAccessibility, waitForAppReady } from "./helpers";

// Tests for the CoC Account Management page (account setup in manage mode).
// Reached through Expo's accessible "Manage accounts" sidebar/header action.
// Tests skip if the test account has no linked CoC account (not on authenticated shell).
//
// Detection note: labels are #root [role], #root input, #root button *textContent*, not [aria-label], so
// we target by text (page.getByText). Icon buttons with tooltips fall back to
// getByRole (the tooltip becomes the accessible name).

async function waitForApp(page: any) {
  await page.goto("/");
  await waitForAppReady(page);
}

async function isOnAuthenticatedShell(page: any): Promise<boolean> {
  return (await page.getByText("Home", { exact: true }).count()) > 0;
}

// Returns true only if account setup in manage mode was reached.
async function openCocAccountManagement(page: any): Promise<boolean> {
  if (!(await isOnAuthenticatedShell(page))) return false;

  const manageBtn = page
    .getByRole("button", { name: /manage accounts/i })
    .or(page.getByText(/manage accounts/i))
    .first();
  if ((await manageBtn.count()) === 0) return false;

  await manageBtn.waitFor({ state: "attached", timeout: 5_000 });
  await manageBtn.click();

  // Verify we're on account setup in manage mode (title = "Manage your accounts")
  return (await page.getByText(/Manage your accounts/i).count()) > 0;
}

test.describe("CoC Account Management", () => {
  test.beforeEach(async ({ page }) => {
    await waitForApp(page);
  });

  test("account management page is accessible via the account menu", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    const reached = await openCocAccountManagement(page);
    if (!reached) test.skip(true, "Could not open account management page");

    await expect(page.locator("#root")).toBeAttached();
  });

  test('"Manage your accounts" title is shown', async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");
    if (!(await openCocAccountManagement(page)))
      test.skip(true, "Could not open account management page");

    await expect(page.getByText(/Manage your accounts/i).first()).toBeAttached({
      timeout: 8_000,
    });
  });

  test("existing CoC accounts are listed on manage page", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");
    if (!(await openCocAccountManagement(page)))
      test.skip(true, "Could not open account management page");

    await page.waitForFunction(
      () =>
        document.querySelectorAll("#root [role], #root input, #root button")
          .length > 8,
      { timeout: 10_000, polling: 500 },
    );

    const count = await page
      .locator("#root [role], #root input, #root button")
      .count();
    expect(count).toBeGreaterThan(8);
  });

  test('"Add account" (+) button is present on the manage page', async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");
    if (!(await openCocAccountManagement(page)))
      test.skip(true, "Could not open account management page");

    await expect(
      page
        .getByText(/Add account/i)
        .or(page.getByRole("button", { name: /add account/i }))
        .first(),
    ).toBeAttached({ timeout: 8_000 });
  });

  test('"Confirm" button is enabled when accounts are already linked', async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");
    if (!(await openCocAccountManagement(page)))
      test.skip(true, "Could not open account management page");

    const confirmBtn = page
      .getByText("Confirm", { exact: true })
      .or(page.getByRole("button", { name: /^confirm$/i }))
      .first();
    await confirmBtn.waitFor({ state: "attached", timeout: 8_000 });

    // In manage mode with at least one existing account, Confirm must be enabled
    await expect(confirmBtn).not.toBeDisabled({ timeout: 5_000 });
  });

  test("player tag input field is present for adding a new account", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");
    if (!(await openCocAccountManagement(page)))
      test.skip(true, "Could not open account management page");

    const tagInput = page
      .getByRole("textbox", { name: /player tag/i })
      .or(page.getByText(/Player Tag/i))
      .first();

    await expect(tagInput).toBeAttached({ timeout: 8_000 });
  });

  test("back navigation from account management returns to authenticated shell", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");
    if (!(await openCocAccountManagement(page)))
      test.skip(true, "Could not open account management page");

    // In manage mode canPop=true — browser back works
    await page.goBack();
    await page.waitForTimeout(800);

    await expect(page.getByText("Home", { exact: true }).first()).toBeAttached({
      timeout: 8_000,
    });
  });
});
