import { defineConfig, devices } from '@playwright/test';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '.env') });

const BASE_URL = process.env.BASE_URL ?? 'https://app.clashk.ing';
const AUTH_FILE = path.join(__dirname, 'playwright/.auth/user.json');

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  expect: { timeout: 10_000 },
  retries: process.env.CI ? 2 : 0,
  workers: 4,
  reporter: [['html', { open: 'never' }], ['list']],

  use: {
    baseURL: BASE_URL,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },

  projects: [
    // ── Setup: log in once and persist auth state ──────────────────────────
    {
      name: 'setup',
      testMatch: '**/auth.setup.ts',
    },

    // ── Public tests (no auth) ─────────────────────────────────────────────
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
      testIgnore: [
        '**/dashboard.spec.ts',
        '**/dashboard_content.spec.ts',
        '**/navigation.spec.ts',
        '**/search.spec.ts',
        '**/add_account.spec.ts',
        '**/logout.spec.ts',
        '**/settings.spec.ts',
        '**/clan_page.spec.ts',
        '**/war_page.spec.ts',
        '**/player_profile.spec.ts',
        '**/coc_account_management.spec.ts',
        '**/error_handling.spec.ts',
      ],
    },

    // ── Authenticated tests ────────────────────────────────────────────────
    {
      name: 'chromium-auth',
      use: {
        ...devices['Desktop Chrome'],
        storageState: AUTH_FILE,
      },
      testMatch: [
        '**/dashboard.spec.ts',
        '**/dashboard_content.spec.ts',
        '**/navigation.spec.ts',
        '**/search.spec.ts',
        '**/add_account.spec.ts',
        '**/logout.spec.ts',
        '**/settings.spec.ts',
        '**/clan_page.spec.ts',
        '**/war_page.spec.ts',
        '**/player_profile.spec.ts',
        '**/coc_account_management.spec.ts',
        '**/error_handling.spec.ts',
      ],
      dependencies: ['setup'],
    },
  ],
});
