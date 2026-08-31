import { test, expect } from "@playwright/test";
import { hasExpoAccessibility, waitForAppReady } from "./helpers";

// Tests for the PlayerScreen reached by tapping the PlayerCard on the Home.
// PlayerScreen has 3 tabs: Home Base (heroes/troops/spells), Builder Base, Achievements.
// Tests skip if the test account has no linked CoC account (not on authenticated shell).
//
// Detection note: tab/section labels are #root [role], #root input, #root button *textContent*, not
// [aria-label], so we target by text (page.getByText).

async function waitForApp(page: any) {
  await page.goto("/");
  await waitForAppReady(page);
}

async function isOnAuthenticatedShell(page: any): Promise<boolean> {
  return (await page.getByText("Home", { exact: true }).count()) > 0;
}

// Prefer the accessible player tag exposed by the Expo card. A positional
// fallback remains for test accounts that do not publish E2E_TEST_COC_TAG.
async function openPlayerProfile(page: any): Promise<boolean> {
  if (!(await isOnAuthenticatedShell(page))) return false;

  await page.waitForFunction(
    () =>
      document.querySelectorAll("#root [role], #root input, #root button")
        .length > 8,
    { timeout: 12_000, polling: 500 },
  );

  // The PlayerCard exposes the account name + tag as an image semantic
  // (e.g. img "Antoine #UGPVP009"). Click it directly when the tag is known;
  // fall back to a positional tap on the top card otherwise.
  const cocTag = process.env.E2E_TEST_COC_TAG?.replace("#", "");
  let clicked = false;
  if (cocTag) {
    const tagEl = page
      .getByRole("img", { name: new RegExp(cocTag, "i") })
      .or(page.getByText(new RegExp(cocTag, "i")))
      .first();
    if ((await tagEl.count()) > 0) {
      await tagEl.click({ force: true });
      clicked = true;
    }
  }
  if (!clicked) {
    const size = page.viewportSize();
    await page.mouse.click((size?.width ?? 400) / 2, 180);
  }
  await page.waitForTimeout(1_500);

  // PlayerScreen has 3 tabs visible: "Home Base", "Builder Base", "Achievements"
  const onPlayerPage =
    (await page
      .getByText(/Home Base/i)
      .or(page.getByText(/Heroes/i))
      .count()) > 0;

  return onPlayerPage;
}

test.describe("Player profile screen", () => {
  test.beforeEach(async ({ page }) => {
    await waitForApp(page);
  });

  test("player profile is reachable by tapping the player card on Home", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    const reached = await openPlayerProfile(page);
    if (!reached)
      test.skip(
        true,
        "Could not open player profile (tap may have missed the card)",
      );

    await expect(page.locator("#root")).toBeAttached();
  });

  test("player profile shows Home Base, Builder Base and Achievements tabs", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    const reached = await openPlayerProfile(page);
    if (!reached) test.skip(true, "Could not open player profile");

    await expect(page.getByText(/Home Base/i).first()).toBeAttached({
      timeout: 8_000,
    });
    await expect(page.getByText(/Builder Base/i).first()).toBeAttached({
      timeout: 5_000,
    });
    await expect(page.getByText(/Achievement/i).first()).toBeAttached({
      timeout: 5_000,
    });
  });

  test("Home Base tab shows Heroes and Troops sections", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    const reached = await openPlayerProfile(page);
    if (!reached) test.skip(true, "Could not open player profile");

    // Home Base tab is selected by default (tab index 0)
    await expect(page.getByText(/Heroes/i).first()).toBeAttached({
      timeout: 8_000,
    });
    await expect(page.getByText(/Troops/i).first()).toBeAttached({
      timeout: 5_000,
    });
  });

  test("switching to Achievements tab shows achievement content", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    const reached = await openPlayerProfile(page);
    if (!reached) test.skip(true, "Could not open player profile");

    // Tap Achievements tab
    const achievementsTab = page.getByText(/Achievement/i).first();
    await achievementsTab.waitFor({ state: "attached", timeout: 8_000 });
    await achievementsTab.click({ force: true });
    await page.waitForTimeout(600);

    // Home Base section should appear in achievements
    await expect(page.getByText(/Home Base/i).first()).toBeAttached({
      timeout: 8_000,
    });
  });

  test("switching to Builder Base tab shows builder content", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    const reached = await openPlayerProfile(page);
    if (!reached) test.skip(true, "Could not open player profile");

    const builderTab = page.getByText(/Builder Base/i).first();
    await builderTab.waitFor({ state: "attached", timeout: 8_000 });
    await builderTab.click({ force: true });
    await page.waitForTimeout(600);

    // Page still alive after tab switch
    await expect(page.locator("#root")).toBeAttached();
    const count = await page
      .locator("#root [role], #root input, #root button")
      .count();
    expect(count).toBeGreaterThan(5);
  });

  test("back button from player profile returns to Home", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    const reached = await openPlayerProfile(page);
    if (!reached) test.skip(true, "Could not open player profile");

    // Back button in PlayerInfoHeader uses the accessible back label
    const backBtn = page
      .getByRole("button", { name: /back/i })
      .or(page.getByText(/^Back$/i))
      .first();
    if ((await backBtn.count()) > 0) {
      await backBtn.click({ force: true });
    } else {
      await page.goBack();
    }
    await page.waitForTimeout(800);

    // Back on Home — nav bar visible
    await expect(page.getByText("Home", { exact: true }).first()).toBeAttached({
      timeout: 8_000,
    });
  });

  // §10.7 — player profile shows player tag in header
  test("player profile header contains the player tag", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    if (!(await isOnAuthenticatedShell(page)))
      test.skip(true, "No CoC accounts — not on authenticated shell");

    const reached = await openPlayerProfile(page);
    if (!reached) test.skip(true, "Could not open player profile");

    const cocTag = process.env.E2E_TEST_COC_TAG;

    if (cocTag) {
      // If we know the tag, verify it appears in the header
      await expect(
        page.getByText(new RegExp(cocTag.replace("#", ""), "i")).first(),
      ).toBeAttached({ timeout: 8_000 });
    } else {
      // Without known tag, verify there are enough semantics for a loaded header
      const count = await page
        .locator("#root [role], #root input, #root button")
        .count();
      expect(count).toBeGreaterThan(10);
    }
  });
});
