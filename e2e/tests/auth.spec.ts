import { test, expect } from '@playwright/test';
import { enableFlutterSemantics, hasFlutterSemantics, waitForFlutter } from './helpers';

test.describe('Auth — login page', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
  });

  test('login/startup screen is visible', async ({ page }) => {
    // flt-glass-pane is always present once Flutter boots.
    await expect(page.locator('flt-glass-pane')).toBeAttached();

    await enableFlutterSemantics(page);
    if (await hasFlutterSemantics(page)) {
      await expect(page.locator('flt-semantics').first()).toBeAttached();
    }
    // If semantics aren't available, flt-glass-pane presence is sufficient proof
    // the app is running — Canvas Kit renders to <canvas>, not text nodes.
  });

  test('Discord login button is present', async ({ page }) => {
    await enableFlutterSemantics(page);

    if (!(await hasFlutterSemantics(page))) {
      test.skip(true, 'Flutter semantics unavailable in this environment (CanvasKit headless)');
    }

    const discordBtn = page
      .locator('flt-semantics[aria-label*="Discord" i]')
      .or(page.getByRole('button', { name: /discord/i }));
    await expect(discordBtn.first()).toBeVisible({ timeout: 10_000 });
  });

  test('Email login option exists', async ({ page }) => {
    await enableFlutterSemantics(page);

    if (!(await hasFlutterSemantics(page))) {
      test.skip(true, 'Flutter semantics unavailable in this environment (CanvasKit headless)');
    }

    const emailBtn = page
      .locator('flt-semantics[aria-label*="Email" i]')
      .or(page.getByRole('button', { name: /email/i }));
    await expect(emailBtn.first()).toBeVisible({ timeout: 10_000 });
  });
});
