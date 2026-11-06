import { expect, test } from "@playwright/test";
// This development-only route renders the real screen with fictional data.
// It needs no authenticated session and must never target the production app.
test.use({ channel: 'chrome', viewport: { width: 393, height: 852 } });

test.describe("Local war detail redesign", () => {
  test.beforeAll(() => {
    const url = new URL(process.env.BASE_URL ?? "https://app.clashk.ing");
    expect(
      ["localhost", "127.0.0.1", "[::1]"].includes(url.hostname),
      "This suite must use the local development app, never production.",
    ).toBe(true);
  });
  test.beforeEach(async ({ page }) => {
    await page.goto("/war-preview");
    await expect(page.getByTestId("war-detail")).toBeVisible();
  });
  test("uses one activity surface, without player search", async ({ page }) => {
    await expect(page.getByTestId("war-player-#DEMO00")).toBeVisible();
    await expect(page.getByPlaceholder("Player's name or tag")).toHaveCount(0);
    await page.getByRole("tab", { name: "Recent", exact: true }).click();
    await expect(page.getByTestId("war-page-players")).toHaveAttribute(
      "aria-hidden",
      "true",
    );
    await expect(page.getByTestId("war-event-10")).toBeVisible();
    await expect(page.getByText("#10", { exact: true })).toHaveCount(0);
    await expect(
      page.getByTestId("war-event-10").getByRole("button"),
    ).toHaveCount(1);
  });
  test("keeps current score unchanged while showing history in Details", async ({
    page,
  }) => {
    await page.getByRole("tab", { name: "Details", exact: true }).click();
    const score = page.getByTestId("war-header-score-clan");
    await expect(page.getByTestId("war-history-graph")).toBeVisible();
    await expect(page.getByTestId("war-history-scrubber")).toHaveCount(0);
    await expect(score).toHaveText("10");
    await expect(
      page.getByText("Fast calculator", { exact: true }),
    ).toHaveCount(0);
  });
  test("disables historical reconstruction when the archive is incomplete", async ({
    page,
  }) => {
    await page.getByTestId("war-preview-ended").click();
    await page.getByTestId("war-preview-incomplete").click();
    await page.getByRole("tab", { name: "Details", exact: true }).click();
    await expect(page.getByTestId("war-history-scrubber")).toHaveCount(0);
    await expect(
      page
        .getByText("Recorded activity only; history may be incomplete.", {
          exact: true,
        })
        .first(),
    ).toBeVisible();
    await page.getByRole("tab", { name: "Players", exact: true }).click();
    await expect(page.getByTestId("war-player-#DEMO00")).not.toContainText(
      "Missed",
    );
    await expect(page.getByTestId("war-header-score-clan")).toHaveText("10");
  });
  test("filters activity without changing the original clan perspective", async ({
    page,
  }) => {
    await page.getByRole("tab", { name: "Recent", exact: true }).click();
    await page.getByRole("button", { name: "All", exact: true }).click();
    await page.getByRole("radio", { name: "Attacks", exact: true }).click();
    await expect(page.getByTestId("war-event-9")).toBeVisible();
    await expect(page.getByTestId("war-event-10")).toHaveCount(0);
    await page.getByRole("button", { name: "Attacks", exact: true }).click();
    await page.getByRole("radio", { name: "Defenses", exact: true }).click();
    await expect(page.getByTestId("war-event-10")).toBeVisible();
    await expect(page.getByTestId("war-event-9")).toHaveCount(0);
  });
  test("filters unused attacks without growing the compact player cards", async ({
    page,
  }) => {
    const card = page.getByTestId("war-player-#DEMO00");
    const height = (await card.boundingBox())!.height;
    await page.getByRole("button", { name: "All", exact: true }).click();
    await page.getByRole("radio", { name: "Remaining", exact: true }).click();
    await expect(card).toHaveCount(0);
    await expect(page.getByTestId("war-player-#DEMO04")).toBeVisible();
    await page.getByRole("button", { name: "Remaining", exact: true }).click();
    await page.getByRole("radio", { name: "All", exact: true }).click();
    expect((await card.boundingBox())!.height).toBe(height);
  });
  test("opponent player selection does not flip Recent or Details", async ({
    page,
  }) => {
    await page
      .getByTestId("destination-picker-control")
      .filter({ hasText: "Ember Alliance" })
      .getByRole("button")
      .click();
    await page
      .getByRole("radio", { name: "Frost Company", exact: true })
      .click();
    await expect(page.getByTestId("war-player-#DEMO10")).toBeVisible();
    await page.getByRole("tab", { name: "Recent", exact: true }).click();
    await page.getByRole("button", { name: "All", exact: true }).click();
    await page.getByRole("radio", { name: "Attacks", exact: true }).click();
    await expect(page.getByTestId("war-event-9")).toBeVisible();
    await expect(page.getByTestId("war-event-10")).toHaveCount(0);
    await page.getByRole("tab", { name: "Details", exact: true }).click();
    await expect(
      page.getByText("Opponent’s recent wars", { exact: true }),
    ).toBeVisible();
    await expect(
      page.getByText("State of the war", { exact: true }),
    ).toHaveCount(0);
  });
  test("shows ten-war scouting coverage only on request", async ({ page }) => {
    await page.getByRole("tab", { name: "Details", exact: true }).click();
    const scope = page.getByText("Last 10 wars", { exact: true });
    await expect(scope).not.toBeVisible();
    await page
      .getByRole("button", {
        name: "Ember Alliance: Lineup scouting",
        exact: true,
      })
      .click();
    await expect(scope).toBeVisible();
    await page.mouse.click(5, 5);
    await expect(scope).not.toBeVisible();
  });
  test("mirrors defenses and returns promptly to Players", async ({ page }) => {
    await page.getByRole("tab", { name: "Recent", exact: true }).click();
    const defense = page.getByTestId("war-event-10");
    const attack = page.getByTestId("war-event-9");
    await expect.poll(async () => (await defense.boundingBox())!.x).toBeGreaterThan((await attack.boundingBox())!.x);
    await expect(defense).toContainText("Drift");
    await expect(defense).not.toContainText("Iris");
    await expect(defense).not.toContainText("Defender");
    await expect(defense).not.toContainText("Ember Alliance");
    await expect(defense.getByRole("button", { name: "Attacker", exact: true })).toBeVisible();
    await page.getByRole("tab", { name: "Details", exact: true }).click();
    await page.getByRole("button", { name: "Ember Alliance: Lineup scouting", exact: true }).scrollIntoViewIfNeeded();
    await page.getByRole("tab", { name: "Players", exact: true }).click();
    await expect.poll(async () => Math.abs((await page.getByTestId("war-page-players").boundingBox())!.x), { timeout: 750 }).toBeLessThan(1);
  });
  test("shows only the home player and discloses the opposing player on request", async ({ page }) => {
    await page.getByRole("tab", { name: "Recent", exact: true }).click();
    const defense = page.getByTestId("war-event-10");
    const attack = page.getByTestId("war-event-9");
    await expect(attack).toContainText("Drift");
    await expect(attack).not.toContainText("Iris");
    await expect(attack).not.toContainText("Attacker");
    await defense.getByRole("button", { name: "Attacker", exact: true }).click();
    await expect(page.getByText("Attacker: Iris", { exact: true })).toBeVisible();
    await page.mouse.click(5, 5);
    await expect(page.getByText("Attacker: Iris", { exact: true })).not.toBeVisible();
    await attack.getByRole("button", { name: "Defender", exact: true }).click();
    await expect(page.getByText("Defender: Iris", { exact: true })).toBeVisible();
  });
  test("keeps header artwork behind all stats and controls above the first player", async ({ page }) => {
    for (const width of [393, 320]) {
      await page.setViewportSize({ width, height: 852 });
      const header = page.getByTestId("war-battle-header");
      const artwork = page.getByTestId("war-header-artwork");
      expect((await header.boundingBox())!.height).toBeLessThan(280);
      await expect.poll(async () => {
        const h = (await header.boundingBox())!;
        const a = (await artwork.boundingBox())!;
        return Math.abs(h.height - a.height) + Math.abs(h.width - a.width);
      }).toBeLessThan(2);
      const controls = (await page.getByTestId("war-player-controls").boundingBox())!;
      const first = (await page.getByTestId("war-player-#DEMO00").boundingBox())!;
      expect(controls.height).toBeGreaterThanOrEqual(44);
      expect(first.y).toBeGreaterThanOrEqual(controls.y + controls.height + 10);
      await page.getByRole("button", { name: "All", exact: true }).click();
      await expect(page.getByRole("radio", { name: "Remaining", exact: true })).toBeVisible();
      await page.getByRole("radio", { name: "All", exact: true }).click();
    }
  });
  test("puts info at the uncolored outer edge and pairs historical clan scores", async ({ page }) => {
    await page.getByRole("tab", { name: "Recent", exact: true }).click();
    const defense = page.getByTestId("war-event-10");
    const attack = page.getByTestId("war-event-9");
    const defenseInfo = (await defense.getByRole("button", { name: "Attacker", exact: true }).boundingBox())!;
    const attackInfo = (await attack.getByRole("button", { name: "Defender", exact: true }).boundingBox())!;
    expect(defenseInfo.x - (await defense.boundingBox())!.x).toBeLessThan(20);
    expect((await attack.boundingBox())!.x + (await attack.boundingBox())!.width - attackInfo.x - attackInfo.width).toBeLessThan(20);
    await page.getByRole("tab", { name: "Details", exact: true }).click();
    const history = page.getByTestId("war-scout-history-#DEMO1");
    await expect(history).toContainText("Frost Company");
    await expect(history).toContainText("Ember Alliance");
    await expect(history).toContainText("Defeat");
  });
});
