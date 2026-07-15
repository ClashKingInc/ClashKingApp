import { test, expect } from '@playwright/test';
import { waitForFlutter } from './helpers';

test.describe('Smoke — app loads', () => {
  test('page returns 200 and Flutter mounts', async ({ page }) => {
    const response = await page.goto('/');
    expect(response?.status()).toBeLessThan(400);
    await waitForFlutter(page);
    // flt-glass-pane is Flutter's root canvas mount
    await expect(page.locator('flt-glass-pane')).toBeAttached();
  });

  test('page title is set', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    await expect(page).toHaveTitle(/ClashKing/i);
  });

  test('no JavaScript errors on load', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (err) => errors.push(err.message));
    await page.goto('/');
    await waitForFlutter(page);
    // Filter known Flutter noise (font loading warnings etc.)
    const realErrors = errors.filter(
      (e) => !e.includes('FontFace') && !e.includes('Noto')
    );
    expect(realErrors).toHaveLength(0);
  });

  test('initial page load completes in under 20 seconds', async ({ page }) => {
    const start = Date.now();
    await page.goto('/');
    await waitForFlutter(page);
    const elapsed = Date.now() - start;
    expect(elapsed).toBeLessThan(20_000);
  });

  test('startup makes no HTTP 5xx requests', async ({ page }) => {
    const serverErrors: string[] = [];
    page.on('response', res => {
      if (res.status() >= 500) serverErrors.push(`${res.status()} ${res.url()}`);
    });
    await page.goto('/');
    await waitForFlutter(page);
    await page.waitForTimeout(4_000); // let deferred API calls complete
    expect(serverErrors).toHaveLength(0);
  });
});
