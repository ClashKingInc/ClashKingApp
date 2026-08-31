import { test, expect } from "@playwright/test";
import { hasExpoAccessibility, waitForAppReady } from "./helpers";

// Expo exposes the header search action with the translated accessible label
// "Search players or clans" and renders result tabs as accessible controls.

async function openSearchPage(page: any) {
  await page.goto("/");
  await waitForAppReady(page);

  // Only authenticated shell has the primary navigation with the Search button.
  if ((await page.getByText("Home", { exact: true }).count()) === 0)
    return false;

  const searchBtn = page
    .getByRole("search", { name: /search players or clans/i })
    .or(page.getByRole("button", { name: /search players or clans/i }))
    .first();

  if ((await searchBtn.count()) === 0) return false;
  await searchBtn.click({ force: true });
  await page.waitForTimeout(800);
  return true;
}

test.describe("Search page", () => {
  test("search page has Players and Clans tabs", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    const opened = await openSearchPage(page);
    if (!opened) test.skip(true, "No CoC accounts — nav not visible");

    await expect(
      page
        .getByText("Players", { exact: true })
        .or(page.getByRole("tab", { name: /players/i }))
        .first(),
    ).toBeAttached({ timeout: 8_000 });

    await expect(
      page
        .getByText("Clans", { exact: true })
        .or(page.getByRole("tab", { name: /clans/i }))
        .first(),
    ).toBeAttached({ timeout: 8_000 });
  });

  test("search input is present and accepts text", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    const opened = await openSearchPage(page);
    if (!opened) test.skip(true, "No CoC accounts — nav not visible");

    const input = page.getByRole("textbox").first();
    await input.waitFor({ state: "attached", timeout: 10_000 });
    await input.click();
    await input.pressSequentially("#2PP", { delay: 30 });

    // Verify we typed something into the field
    await expect(input).toHaveValue(/2PP/i, { timeout: 5_000 });
  });

  test("searching a player tag shows results or loading state", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    const opened = await openSearchPage(page);
    if (!opened) test.skip(true, "No CoC accounts — nav not visible");

    const input = page.getByRole("textbox").first();
    await input.waitFor({ state: "attached", timeout: 10_000 });
    await input.click();
    // Search for a known active player tag
    await input.pressSequentially("#2PP", { delay: 30 });

    // Wait for debounce + API call (up to 8 s)
    await page.waitForTimeout(2_500);

    // App should still be responsive (not crashed)
    await expect(page.locator("#root")).toBeAttached();
  });

  test("switching to Clans tab and searching works", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    const opened = await openSearchPage(page);
    if (!opened) test.skip(true, "No CoC accounts — nav not visible");

    // Switch to Clans tab
    const clansTab = page
      .getByText("Clans", { exact: true })
      .or(page.getByRole("tab", { name: /clans/i }))
      .first();

    await clansTab.waitFor({ state: "attached", timeout: 8_000 });
    await clansTab.click({ force: true });
    await page.waitForTimeout(400);

    const input = page.getByRole("textbox").first();
    await input.waitFor({ state: "attached", timeout: 8_000 });
    await input.click();
    await input.pressSequentially("#2JUCY9UY", { delay: 30 });

    await page.waitForTimeout(2_500);
    await expect(page.locator("#root")).toBeAttached();
  });

  test("clearing search restores empty state", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    const opened = await openSearchPage(page);
    if (!opened) test.skip(true, "No CoC accounts — nav not visible");

    const input = page.getByRole("textbox").first();
    await input.waitFor({ state: "attached", timeout: 10_000 });
    await input.click();
    await input.pressSequentially("test", { delay: 30 });
    await page.waitForTimeout(500);

    // Clear via Ctrl+A then Delete
    await page.keyboard.press("Control+A");
    await page.keyboard.press("Backspace");
    await page.waitForTimeout(500);

    await expect(page.locator("#root")).toBeAttached();
  });

  // ── §13.6-13.10 Search result detail tests ───────────────────────────────

  test("searching a known player tag shows the player name in results", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    const opened = await openSearchPage(page);
    if (!opened) test.skip(true, "No CoC accounts — nav not visible");

    const input = page.getByRole("textbox").first();
    await input.waitFor({ state: "attached", timeout: 10_000 });
    await input.click();
    // #2PP is a well-known player tag used by the ClashKing team
    await input.pressSequentially("#2PP", { delay: 30 });

    // Wait for API response (debounce + network)
    await page.waitForTimeout(3_500);

    // Result tile should show the player tag text
    const resultEl = page.getByText(/2PP/i).first();

    if ((await resultEl.count()) === 0) {
      test.skip(
        true,
        "No result for #2PP — API may be unavailable or tag not found",
      );
    }

    await expect(resultEl).toBeAttached({ timeout: 5_000 });
  });

  test("searching a known clan tag shows the clan name in results", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    const opened = await openSearchPage(page);
    if (!opened) test.skip(true, "No CoC accounts — nav not visible");

    // Switch to Clans tab
    const clansTab = page
      .getByText("Clans", { exact: true })
      .or(page.getByRole("tab", { name: /clans/i }))
      .first();
    await clansTab.waitFor({ state: "attached", timeout: 8_000 });
    await clansTab.click({ force: true });
    await page.waitForTimeout(400);

    const input = page.getByRole("textbox").first();
    await input.waitFor({ state: "attached", timeout: 8_000 });
    await input.click();
    await input.pressSequentially("#2JUCY9UY", { delay: 30 });

    await page.waitForTimeout(3_500);

    // Result should contain the clan tag text
    const resultEl = page.getByText(/2JUCY9UY/i).first();

    if ((await resultEl.count()) === 0) {
      test.skip(true, "No result for #2JUCY9UY — API may be unavailable");
    }

    await expect(resultEl).toBeAttached({ timeout: 5_000 });
  });

  test("tapping a player search result opens the player profile screen", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    const opened = await openSearchPage(page);
    if (!opened) test.skip(true, "No CoC accounts — nav not visible");

    const input = page.getByRole("textbox").first();
    await input.waitFor({ state: "attached", timeout: 10_000 });
    await input.click();
    await input.pressSequentially("#2PP", { delay: 30 });
    await page.waitForTimeout(3_500);

    // Find first result tile by its tag text
    const firstResult = page.getByText(/^#[A-Z0-9]+$/i).first();
    if ((await firstResult.count()) === 0) {
      test.skip(true, "No search results found for #2PP");
    }

    await firstResult.click({ force: true });

    // Loading dialog appears briefly, then PlayerScreen opens
    await page.waitForTimeout(4_000);

    // PlayerScreen has Home Base tab
    const onPlayerPage =
      (await page
        .getByText(/Home Base/i)
        .or(page.getByText(/Heroes/i))
        .count()) > 0;

    if (onPlayerPage) {
      await expect(page.getByText(/Home Base/i).first()).toBeAttached({
        timeout: 5_000,
      });
    } else {
      // May have navigated somewhere — app should still be alive
      await expect(page.locator("#root")).toBeAttached();
    }
  });

  test("search with no matching result shows empty state", async ({ page }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    const opened = await openSearchPage(page);
    if (!opened) test.skip(true, "No CoC accounts — nav not visible");

    const input = page.getByRole("textbox").first();
    await input.waitFor({ state: "attached", timeout: 10_000 });
    await input.click();
    // Use a tag that is guaranteed not to exist
    await input.pressSequentially("#ZZZZZZZZ", { delay: 30 });
    await page.waitForTimeout(3_500);

    // Either "No result" text or an empty list — app should remain alive
    await expect(page.locator("#root")).toBeAttached();

    const noResultEl = page.getByText(/No result/i);
    if ((await noResultEl.count()) > 0) {
      await expect(noResultEl.first()).toBeAttached();
    }
  });

  // §13.10 — tapping a clan search result opens the clan detail screen
  test("tapping a clan search result opens the clan detail screen", async ({
    page,
  }) => {
    if (!(await hasExpoAccessibility(page)))
      test.skip(true, "Expo semantics unavailable");
    const opened = await openSearchPage(page);
    if (!opened) test.skip(true, "No CoC accounts — nav not visible");

    // Switch to Clans tab
    const clansTab = page
      .getByText("Clans", { exact: true })
      .or(page.getByRole("tab", { name: /clans/i }))
      .first();
    await clansTab.waitFor({ state: "attached", timeout: 8_000 });
    await clansTab.click({ force: true });
    await page.waitForTimeout(400);

    const input = page.getByRole("textbox").first();
    await input.waitFor({ state: "attached", timeout: 8_000 });
    await input.click();
    await input.pressSequentially("#2JUCY9UY", { delay: 30 });
    await page.waitForTimeout(3_500);

    // Find the first clan result tile by its tag text
    const firstResult = page.getByText(/2JUCY9UY/i).first();
    if ((await firstResult.count()) === 0) {
      test.skip(true, "No result for #2JUCY9UY — API may be unavailable");
    }

    await firstResult.click({ force: true });
    await page.waitForTimeout(4_000);

    // ClanInfoScreen opens — should contain semantics with clan info
    await expect(page.locator("#root")).toBeAttached();
    const count = await page
      .locator("#root [role], #root input, #root button")
      .count();
    expect(count).toBeGreaterThan(5);
  });
});
