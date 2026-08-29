import { expect, request, test as teardown } from '@playwright/test';
import fs from 'fs';
import path from 'path';

const AUTH_FILE = path.join(__dirname, '../playwright/.auth/user.json');
const TEMPORARY_ACCOUNT_FILE = path.join(__dirname, '../playwright/.auth/temporary-account');
const API_BASE = (process.env.API_BASE_URL ?? 'https://v2-api.clashk.ing').replace(/\/+$/, '');

teardown('delete temporary email account', async () => {
  teardown.skip(!fs.existsSync(TEMPORARY_ACCOUNT_FILE), 'No temporary E2E account was created');

  const state = JSON.parse(fs.readFileSync(AUTH_FILE, 'utf8')) as {
    origins?: Array<{ localStorage?: Array<{ name?: string; value?: string }> }>;
  };
  const storedToken = state.origins
    ?.flatMap((origin) => origin.localStorage ?? [])
    .find((entry) => entry.name === 'flutter.access_token')
    ?.value;
  if (!storedToken) throw new Error('Temporary E2E account has no stored access token');

  const accessToken: unknown = JSON.parse(storedToken);
  if (typeof accessToken !== 'string' || !accessToken) {
    throw new Error('Temporary E2E account access token is invalid');
  }

  const apiContext = await request.newContext({ baseURL: API_BASE });
  try {
    const response = await apiContext.delete('/v2/auth/me', {
      headers: { authorization: `Bearer ${accessToken}` },
    });
    const responseBody = response.ok() ? '' : `: ${(await response.text()).slice(0, 300)}`;
    expect(response.ok(), `account cleanup returned ${response.status()}${responseBody}`).toBe(true);
    fs.rmSync(TEMPORARY_ACCOUNT_FILE, { force: true });
    fs.rmSync(AUTH_FILE, { force: true });
  } finally {
    await apiContext.dispose();
  }
});
