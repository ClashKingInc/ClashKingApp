import { test, expect } from "@playwright/test";
import {
  authSegment,
  clickAuthSegment,
  hasExpoAccessibility,
  waitForAppReady,
} from "./helpers";

async function waitForApp(page: any) {
  page.setDefaultNavigationTimeout(30_000);
  page.setDefaultTimeout(30_000);
  await page.goto("/");
  await waitForAppReady(page);
}

async function openLogoutControl(page: any) {
  const authenticatedShell =
    (await page.getByText("Home", { exact: true }).count()) > 0;
  if (authenticatedShell) {
    await page.getByRole("button", { name: /^Settings$/i }).click();
  }

  const control = page.getByRole("button", { name: /^log out$/i }).last();
  await control.waitFor({ state: "attached", timeout: 8_000 });
  return { authenticatedShell, control };
}

async function logOut(page: any) {
  const { authenticatedShell, control } = await openLogoutControl(page);
  await control.click();

  if (authenticatedShell) {
    await expect(
      page.getByText(/are you sure you want to log out/i),
    ).toBeAttached();
    await page.getByRole("button", { name: /^ok$/i }).click();
  }

  await expect(authSegment(page, /discord/i)).toBeAttached({ timeout: 12_000 });
}

test.describe("Logout", () => {
  test.beforeEach(async ({ page }) => {
    test.setTimeout(60_000);
    await waitForApp(page);
  });

  test('"Log out" is reachable from account setup or Settings', async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo accessibility tree unavailable");
    const { control } = await openLogoutControl(page);
    await expect(control).toBeAttached();
  });

  test("confirming logout returns to login and exposes the Email login action", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo accessibility tree unavailable");
    await logOut(page);
    await clickAuthSegment(page, /email/i);
    await expect(page.getByRole("button", { name: /^login$/i })).toBeAttached({
      timeout: 8_000,
    });
  });
});
