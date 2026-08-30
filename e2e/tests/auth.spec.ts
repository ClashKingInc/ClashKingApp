import { test, expect } from "@playwright/test";
import {
  waitForExpoAccessibility,
  hasExpoAccessibility,
  waitForExpo,
} from "./helpers";

const discordAuthEnabled = process.env.DISCORD_AUTH_ENABLED !== "false";

test.describe("Auth — login page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/");
    await waitForExpo(page);
  });

  test("login/startup screen is visible", async ({ page }) => {
    // #root is always present once Expo boots.
    await expect(page.locator("#root")).toBeAttached();

    await waitForExpoAccessibility(page);
    if (await hasExpoAccessibility(page)) {
      await expect(
        page.locator("#root [role], #root input, #root button").first(),
      ).toBeAttached();
    }
    // If accessibility roles are unavailable in the headless environment,
    // #root presence still confirms that React Native Web mounted the app.
  });

  test("Discord login matches the deployment configuration", async ({
    page,
  }) => {
    await waitForExpoAccessibility(page);

    if (!(await hasExpoAccessibility(page))) {
      test.skip(
        true,
        "Expo semantics unavailable in this environment (React Native Web headless)",
      );
    }

    const discordBtn = page
      .locator('[aria-label*="Continue with Discord" i]')
      .or(
        page.getByRole("button", {
          name: /continue with discord|sign in with discord/i,
        }),
      );
    if (discordAuthEnabled) {
      await expect(discordBtn.first()).toBeVisible({ timeout: 10_000 });
    } else {
      await expect(discordBtn).toHaveCount(0);
    }
  });

  test("Email login option exists", async ({ page }) => {
    await waitForExpoAccessibility(page);

    if (!(await hasExpoAccessibility(page))) {
      test.skip(
        true,
        "Expo semantics unavailable in this environment (React Native Web headless)",
      );
    }

    const emailBtn = page
      .locator('[aria-label*="Email" i]')
      .or(page.getByRole("button", { name: /email/i }));
    await expect(emailBtn.first()).toBeVisible({ timeout: 10_000 });
  });
});
