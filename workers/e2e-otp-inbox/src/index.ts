import { DurableObject } from 'cloudflare:workers';
import { extractOtp, isRecipientForDomain, normalizeEmail, secretsMatch } from './otp';

interface StoredOtp {
  code: string;
  receivedAt: string;
}

const JSON_HEADERS = {
  'cache-control': 'no-store',
  'content-type': 'application/json; charset=utf-8',
};

function json(body: unknown, status = 200): Response {
  return Response.json(body, { status, headers: JSON_HEADERS });
}

function parsePositiveInteger(value: string, fallback: number): number {
  const parsed = Number.parseInt(value, 10);
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : fallback;
}

export class OtpInbox extends DurableObject<Env> {
  async fetch(request: Request): Promise<Response> {
    if (request.method === 'PUT') {
      const record = await request.json<StoredOtp>();
      if (!/^\d{6}$/.test(record.code) || Number.isNaN(Date.parse(record.receivedAt))) {
        return json({ error: 'Invalid OTP record' }, 400);
      }

      await this.ctx.storage.put('otp', record);
      const ttlSeconds = parsePositiveInteger(this.env.OTP_TTL_SECONDS, 600);
      await this.ctx.storage.setAlarm(Date.now() + ttlSeconds * 1_000);
      return json({ stored: true }, 201);
    }

    if (request.method === 'GET') {
      const record = await this.ctx.storage.get<StoredOtp>('otp');
      return record ? json(record) : json({ error: 'OTP not found' }, 404);
    }

    if (request.method === 'DELETE') {
      await this.ctx.storage.deleteAll();
      return new Response(null, { status: 204, headers: { 'cache-control': 'no-store' } });
    }

    return json({ error: 'Method not allowed' }, 405);
  }

  async alarm(): Promise<void> {
    await this.ctx.storage.deleteAll();
  }
}

async function authorized(request: Request, env: Env): Promise<boolean> {
  const authorization = request.headers.get('authorization');
  if (!authorization?.startsWith('Bearer ')) return false;
  return secretsMatch(authorization.slice(7), env.OTP_API_TOKEN);
}

function stubForEmail(env: Env, email: string): DurableObjectStub {
  return env.OTP_INBOX.get(env.OTP_INBOX.idFromName(email));
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (request.method === 'GET' && url.pathname === '/health') {
      return json({ ok: true });
    }

    if (url.pathname !== '/v1/otp' || !['GET', 'DELETE'].includes(request.method)) {
      return json({ error: 'Not found' }, 404);
    }
    if (!(await authorized(request, env))) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const email = normalizeEmail(url.searchParams.get('email') ?? '');
    if (!email || !isRecipientForDomain(email, env.EMAIL_DOMAIN)) {
      return json({ error: 'Invalid E2E email address' }, 400);
    }

    return stubForEmail(env, email).fetch('https://otp-inbox.internal/', {
      method: request.method,
    });
  },

  async email(message: ForwardableEmailMessage, env: Env): Promise<void> {
    if (!isRecipientForDomain(message.to, env.EMAIL_DOMAIN)) {
      message.setReject('Recipient is outside the E2E email domain');
      return;
    }

    const maxEmailBytes = parsePositiveInteger(env.MAX_EMAIL_BYTES, 262_144);
    if (message.rawSize > maxEmailBytes) {
      message.setReject('Email is too large');
      return;
    }

    try {
      const raw = await new Response(message.raw).arrayBuffer();
      const code = await extractOtp(raw);
      if (!code) {
        message.setReject('No six-digit OTP found');
        return;
      }

      const email = normalizeEmail(message.to);
      if (!email) {
        message.setReject('Invalid recipient');
        return;
      }

      const response = await stubForEmail(env, email).fetch('https://otp-inbox.internal/', {
        method: 'PUT',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ code, receivedAt: new Date().toISOString() } satisfies StoredOtp),
      });
      if (!response.ok) throw new Error(`Durable Object returned ${response.status}`);
    } catch (error) {
      console.error(JSON.stringify({
        message: 'Failed to process E2E OTP email',
        recipient: message.to,
        error: error instanceof Error ? error.message : String(error),
      }));
      message.setReject('Unable to process OTP email');
    }
  },
} satisfies ExportedHandler<Env>;
