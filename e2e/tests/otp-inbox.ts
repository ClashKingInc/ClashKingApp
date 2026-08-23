interface OtpInboxConfig {
  apiUrl: string;
  apiToken: string;
  emailDomain: string;
}

interface WaitForOtpOptions {
  notBefore?: number;
  timeoutMs?: number;
}

export function getOtpInboxConfig(): OtpInboxConfig | null {
  const apiUrl = process.env.E2E_OTP_API_URL?.trim().replace(/\/+$/, '');
  const apiToken = process.env.E2E_OTP_API_TOKEN?.trim();
  const emailDomain = process.env.E2E_EMAIL_DOMAIN?.trim().toLowerCase();
  return apiUrl && apiToken && emailDomain ? { apiUrl, apiToken, emailDomain } : null;
}

export function createE2eEmail(prefix = 'run'): string {
  const config = getOtpInboxConfig();
  if (!config) throw new Error('Cloudflare OTP inbox is not configured');
  return `e2e+${prefix}-${crypto.randomUUID()}@${config.emailDomain}`;
}

export async function waitForOtp(
  email: string,
  { notBefore = Date.now() - 5_000, timeoutMs = 60_000 }: WaitForOtpOptions = {},
): Promise<string> {
  const config = getOtpInboxConfig();
  if (!config) throw new Error('Cloudflare OTP inbox is not configured');

  const endpoint = new URL('/v1/otp', `${config.apiUrl}/`);
  endpoint.searchParams.set('email', email);
  const headers = { authorization: `Bearer ${config.apiToken}` };
  const deadline = Date.now() + timeoutMs;

  while (Date.now() < deadline) {
    const response = await fetch(endpoint, { headers });
    if (response.status === 404) {
      await new Promise((resolve) => setTimeout(resolve, 1_000));
      continue;
    }
    if (!response.ok) {
      throw new Error(`OTP inbox returned ${response.status}`);
    }

    const payload: unknown = await response.json();
    if (
      typeof payload !== 'object' ||
      payload === null ||
      !('code' in payload) ||
      !('receivedAt' in payload) ||
      typeof payload.code !== 'string' ||
      typeof payload.receivedAt !== 'string' ||
      !/^\d{6}$/.test(payload.code)
    ) {
      throw new Error('OTP inbox returned an invalid response');
    }

    if (Date.parse(payload.receivedAt) < notBefore) {
      await fetch(endpoint, { method: 'DELETE', headers });
      await new Promise((resolve) => setTimeout(resolve, 1_000));
      continue;
    }

    const consumed = await fetch(endpoint, { method: 'DELETE', headers });
    if (!consumed.ok) throw new Error(`OTP inbox cleanup returned ${consumed.status}`);
    return payload.code;
  }

  throw new Error(`Timed out waiting for an OTP for ${email}`);
}
