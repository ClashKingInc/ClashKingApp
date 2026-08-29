import { env, exports } from 'cloudflare:workers';
import { describe, expect, it } from 'vitest';

const EMAIL = 'run-integration@e2e-mail.clashk.ing';

describe('OTP inbox Worker', () => {
  it('protects the inbox API with its bearer token', async () => {
    const response = await exports.default.fetch(`https://example.com/v1/otp?email=${EMAIL}`);
    expect(response.status).toBe(401);
    expect(response.headers.get('cache-control')).toBe('no-store');
  });

  it('reads and deletes an OTP through the public API', async () => {
    const stub = env.OTP_INBOX.get(env.OTP_INBOX.idFromName(EMAIL));
    const stored = await stub.fetch('https://otp-inbox.internal/', {
      method: 'PUT',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ code: '472819', receivedAt: new Date().toISOString() }),
    });
    expect(stored.status).toBe(201);

    const authorization = { authorization: 'Bearer local-test-token' };
    const response = await exports.default.fetch(`https://example.com/v1/otp?email=${EMAIL}`, {
      headers: authorization,
    });
    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({ code: '472819' });

    const deleted = await exports.default.fetch(`https://example.com/v1/otp?email=${EMAIL}`, {
      method: 'DELETE',
      headers: authorization,
    });
    expect(deleted.status).toBe(204);

    const missing = await exports.default.fetch(`https://example.com/v1/otp?email=${EMAIL}`, {
      headers: authorization,
    });
    expect(missing.status).toBe(404);
  });
});
