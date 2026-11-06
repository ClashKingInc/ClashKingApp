import { expect, test } from "@playwright/test";
import { existsSync } from "node:fs";
import path from "node:path";
import { waitForAppReady } from "./helpers";

const authFile = path.resolve(__dirname, "../playwright/.auth/user.json");

// Reuse an existing local session. This suite never provisions an account or
// runs the auth setup/cleanup workflow against a remote environment.
test.use({ storageState: authFile });

test.describe("Calculator tools", () => {
  test.beforeAll(() => {
    const target = new URL(process.env.BASE_URL ?? "https://app.clashk.ing");
    expect(
      ["localhost", "127.0.0.1", "[::1]"].includes(target.hostname),
      "Set BASE_URL to the running local Expo app before running calculator checks.",
    ).toBe(true);
    expect(
      existsSync(authFile),
      "Provide an existing local authenticated storage state at e2e/playwright/.auth/user.json.",
    ).toBe(true);
  });

  test.beforeEach(async ({ page }) => {
    await page.goto("/calculators");
    await waitForAppReady(page);
    await expect(page.getByTestId("calculator-hub")).toBeVisible();
  });

  test("shows the three selected cards and blocks Farming deep links", async ({
    page,
  }) => {
    await expect(page.getByTestId("calculator-card-damage")).toBeEnabled();
    await expect(page.getByTestId("calculator-card-equipment")).toBeEnabled();
    await expect(page.getByTestId("calculator-card-farming")).toBeDisabled();
    await expect(
      page
        .getByTestId("calculator-hub")
        .getByText("Calculators", { exact: true }),
    ).toHaveCount(1);
    await page.goto("/calculators?mode=farmGoal");
    await waitForAppReady(page);
    await expect(page.getByTestId("calculator-hub")).toBeVisible();
    await expect(page.getByTestId("calculator-card-farming")).toBeDisabled();
  });

  test("calculates real combinations directly from the selected target and sources", async ({
    page,
  }) => {
    await page.getByTestId("calculator-card-damage").click();
    const calculator = page.getByTestId("damage-workbench");
    await expect(calculator).toBeVisible();
    const combination = calculator.getByTestId("damage-combination").first();
    await expect(combination).toBeVisible({ timeout: 20000 });
    await expect(
      combination.getByText("Lowest cost", { exact: true }),
    ).toBeVisible();
    await expect(
      combination.getByText(/\d+ spell space · \d+ equipment/),
    ).toBeVisible();
    await expect(combination.getByText(/^×\d+$/).first()).toBeVisible();

    // A one-space budget cannot destroy the initial max-level defense with
    // Lightning alone. This exercises recalculation through the real service.
    await calculator
      .getByRole("button", { name: "Spell capacity", exact: true })
      .click();
    await page.getByRole("radio", { name: "1", exact: true }).click();
    await expect(calculator.getByTestId("damage-combination")).toHaveCount(0);
    await calculator
      .getByRole("button", { name: "Spell capacity", exact: true })
      .click();
    await page.getByRole("radio", { name: "20", exact: true }).click();
    await expect(combination).toBeVisible();
  });

  test("compares actual values and updates the permanent baseline with hero level", async ({
    page,
  }) => {
    await page.getByTestId("calculator-card-equipment").click();
    const calculator = page.getByTestId("equipment-compare");
    const matrix = calculator.getByTestId("equipment-comparison-table");
    await expect(matrix).toBeVisible({ timeout: 20000 });
    await calculator
      .getByRole("button", { name: "Attributes", exact: true })
      .click();
    const hpChoice = page.getByRole("checkbox", {
      name: "Hero HP",
      exact: true,
    });
    await expect(hpChoice).toBeChecked();
    await hpChoice.click();
    await expect(hpChoice).not.toBeChecked();
    await hpChoice.click();
    await expect(hpChoice).toBeChecked();
    await page.getByTestId("selection-picker-backdrop").click();
    await expect(
      calculator.getByRole("switch", { name: "No equipment", exact: true }),
    ).toHaveCount(0);
    const baseline = calculator.getByTestId("compare-row-baseline");
    const hitpoints = calculator.getByTestId(
      "compare-value-baseline-hitpoints",
    );
    await expect(baseline).toBeVisible();
    const before = await hitpoints.innerText();
    await calculator
      .getByLabel("Hero level", { exact: true })
      .first()
      .press("Home");
    await expect(hitpoints).not.toHaveText(before);
    await expect(baseline).toHaveAttribute("aria-label", "No equipment");
    await expect(matrix.getByText(/^Level \d+$/)).toHaveCount(0);
    await expect(
      calculator.getByRole("tab", { name: "Level progression", exact: true }),
    ).toHaveCount(0);
    await expect(
      calculator.getByTestId("equipment-comparison-copy"),
    ).toBeVisible();
  });

  test("compares a duplicated loadout at an independently chosen equipment level", async ({
    page,
  }) => {
    await page.getByTestId("calculator-card-equipment").click();
    const calculator = page.getByTestId("equipment-compare");
    const first = calculator
      .locator(
        '[data-testid^="compare-row-"]:not([data-testid="compare-row-baseline"])',
      )
      .first();
    await expect(first).toBeVisible({ timeout: 20000 });
    const sourceId = await first.getAttribute("data-testid");
    const original = await first.getAttribute("aria-label");
    await first.click();
    await calculator
      .getByRole("button", { name: "Duplicate loadout", exact: true })
      .click();
    const copy = calculator
      .locator('[data-testid^="compare-row-"][data-testid*="-copy-"]')
      .first();
    await expect(copy).toHaveAttribute("aria-label", original!);
    const editor = calculator.getByTestId("equipment-row-editor");
    const gearSlider = editor
      .locator('[data-testid^="equipment-row-level-"]')
      .first()
      .locator("[aria-valuenow]");
    await gearSlider.press("Home");
    await expect(gearSlider).toHaveAttribute("aria-valuenow", "1");
    await gearSlider.press("ArrowRight");
    await expect(gearSlider).toHaveAttribute("aria-valuenow", "3");
    await expect(copy).not.toHaveAttribute("aria-label", original!);
    await expect(calculator.getByTestId(sourceId!)).toHaveAttribute(
      "aria-label",
      original!,
    );
  });
});
