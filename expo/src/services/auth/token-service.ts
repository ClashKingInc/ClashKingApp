import { ApiResponseError, TransportError } from '@clashking/api-client';

import type { StoredAuthSession } from '../../core/dto/auth-session';
import type { AuthSessionRepository, RuntimePlatform } from '../storage/auth-storage';
import { withWebAuthRefreshLock, type AuthRefreshLock } from './refresh-lock';

export interface DeviceIdentity {
  getDeviceId(): Promise<string>;
  getDeviceName(): Promise<string>;
}

export interface TokenServiceOptions {
  readonly apiV2Url: string;
  readonly platform: RuntimePlatform;
  readonly sessions: AuthSessionRepository;
  readonly refreshLock: AuthRefreshLock;
  readonly deviceIdentity: DeviceIdentity;
  readonly fetchImplementation?: typeof fetch;
  readonly nowSeconds?: () => number;
  readonly onSessionRejected?: () => Promise<void>;
}

export class TokenService {
  private cachedAccessToken: string | null = null;
  private cachedRefreshToken: string | null = null;
  private tokensLoaded = false;
  private tokenLoad: Promise<StoredAuthSession> | null = null;
  private refreshInFlight: Promise<string | null> | null = null;
  private sessionGeneration = 0;
  private readonly fetchImplementation: typeof fetch;
  private readonly nowSeconds: () => number;

  constructor(private readonly options: TokenServiceOptions) {
    // Browser fetch requires its Window receiver in WebKit. Calling an unbound
    // copy as this.fetchImplementation makes every session restore fail.
    this.fetchImplementation = options.fetchImplementation ?? globalThis.fetch.bind(globalThis);
    this.nowSeconds = options.nowSeconds ?? (() => Math.floor(Date.now() / 1000));
  }

  getDeviceId(): Promise<string> {
    return this.options.deviceIdentity.getDeviceId();
  }

  getDeviceName(): Promise<string> {
    return this.options.deviceIdentity.getDeviceName();
  }

  get sessionVersion(): number {
    return this.sessionGeneration;
  }

  canReplayWithAccessToken(rejected: string, current: string): boolean {
    try {
      const previous = JSON.parse(decodeBase64Url(rejected.split('.')[1]!)) as unknown;
      const next = JSON.parse(decodeBase64Url(current.split('.')[1]!)) as unknown;
      return (
        isRecord(previous) &&
        isRecord(next) &&
        typeof previous.sub === 'string' &&
        previous.sub === next.sub
      );
    } catch {
      return false;
    }
  }

  async refreshAfterUnauthorized(rejectedAccessToken: string): Promise<string | null> {
    if (
      this.cachedAccessToken !== null &&
      this.cachedAccessToken !== rejectedAccessToken &&
      !this.isTokenExpired(this.cachedAccessToken)
    ) {
      return this.cachedAccessToken;
    }
    if (this.options.platform === 'web') return this.refreshWebAccessToken();
    const session = await this.options.sessions.read();
    if (session.refreshToken === null) return null;
    return this.refreshExpiredToken(session.refreshToken, rejectedAccessToken);
  }

  async getAccessToken(): Promise<string | null> {
    if (this.options.platform === 'web') {
      if (this.cachedAccessToken !== null && !this.isTokenExpired(this.cachedAccessToken)) {
        return this.cachedAccessToken;
      }
      return this.refreshWebAccessToken();
    }

    const session = await this.loadTokensOnce();
    if (session.accessToken === null || session.refreshToken === null) {
      return null;
    }
    if (this.isTokenExpired(session.accessToken)) {
      return this.refreshExpiredToken(session.refreshToken);
    }
    return session.accessToken;
  }

  async saveWebAccessToken(accessToken: string): Promise<void> {
    this.sessionGeneration += 1;
    this.cachedAccessToken = accessToken;
    this.cachedRefreshToken = null;
    this.tokensLoaded = true;
    await this.options.sessions.clearWebLegacyTokens();
  }

  async saveTokens(accessToken: string, refreshToken: string): Promise<void> {
    if (this.options.platform === 'web') {
      await this.saveWebAccessToken(accessToken);
      return;
    }
    const deviceId = this.options.platform === 'ios' ? await this.getDeviceId() : null;
    const saved = await this.options.refreshLock.run(async () => {
      this.sessionGeneration += 1;
      await this.saveSession({ accessToken, refreshToken, deviceId });
      return true;
    });
    if (saved !== true) {
      throw new Error('Could not acquire the shared authentication lock.');
    }
  }

  async clearTokens(): Promise<void> {
    const clear = async () => {
      await this.clearSessionUnlocked();
      return true;
    };
    const cleared = await this.options.refreshLock.run(clear);
    if (cleared !== true) {
      throw new Error('Could not acquire the shared authentication lock.');
    }
  }

  isTokenExpired(token: string, skewSeconds = 30): boolean {
    try {
      const parts = token.split('.');
      if (parts.length !== 3) return true;
      const payload = JSON.parse(decodeBase64Url(parts[1]!)) as unknown;
      if (!isRecord(payload) || typeof payload.exp !== 'number') return true;
      return this.nowSeconds() >= payload.exp - skewSeconds;
    } catch {
      return true;
    }
  }

  private async refreshExpiredToken(
    refreshToken: string,
    rejectedAccessToken?: string,
  ): Promise<string | null> {
    if (this.refreshInFlight !== null) return this.refreshInFlight;
    const refresh = (async () =>
      this.refreshAccessToken(refreshToken, await this.getDeviceId(), rejectedAccessToken))();
    this.refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      if (this.refreshInFlight === refresh) this.refreshInFlight = null;
    }
  }

  private async refreshAccessToken(
    capturedRefreshToken: string,
    deviceId: string,
    rejectedAccessToken?: string,
  ): Promise<string | null> {
    if (this.options.platform === 'web') return this.refreshWebAccessToken();
    const refreshed = await this.options.refreshLock.run(async () => {
      const version = this.sessionGeneration;
      const latest = await this.options.sessions.read();
      if (
        latest.accessToken !== null &&
        latest.refreshToken !== null &&
        !this.isTokenExpired(latest.accessToken) &&
        latest.accessToken !== rejectedAccessToken
      ) {
        this.cacheSession(latest);
        return latest.accessToken;
      }
      // Re-reading while holding the cross-process lock prevents an old token
      // from resurrecting a session cleared by logout or rotated by WidgetKit.
      if (latest.refreshToken === null) return null;
      const currentDeviceId = latest.deviceId ?? deviceId;
      const response = await this.fetchWithTimeout(
        `${withoutTrailingSlash(this.options.apiV2Url)}/auth/refresh`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            refresh_token:
              latest.refreshToken === capturedRefreshToken
                ? capturedRefreshToken
                : latest.refreshToken,
            device_id: currentDeviceId,
          }),
        },
      );
      const current = await this.options.sessions.read();
      if (version !== this.sessionGeneration || current.refreshToken !== latest.refreshToken) {
        // Another process/session may have replaced these credentials while
        // the rejected request was in flight. Never clear its newer session.
        this.cacheSession(current);
        if (current.accessToken !== null && !this.isTokenExpired(current.accessToken))
          return current.accessToken;
        throw new TransportError({
          cause: null,
          message: 'Session changed during refresh. Retry authentication.',
        });
      }
      if (response.status === 401) {
        await this.clearSessionUnlocked();
        await this.options.onSessionRejected?.();
        return null;
      }
      if (response.status !== 200) {
        throw new TransportError({
          cause: null,
          message: `Native session refresh failed (${response.status}). Retry authentication.`,
        });
      }
      const data = await parseResponseRecord(response);
      const accessToken = nonEmptyString(data.access_token);
      const refreshToken = nonEmptyString(data.refresh_token);
      if (accessToken === null || refreshToken === null)
        throw new TransportError({
          cause: null,
          message: 'Invalid native session refresh response. Retry authentication.',
        });
      await this.saveSession({
        accessToken,
        refreshToken,
        deviceId: currentDeviceId,
      });
      return accessToken;
    });
    return refreshed ?? null;
  }

  private async refreshWebAccessToken(): Promise<string | null> {
    if (this.refreshInFlight !== null) return this.refreshInFlight;
    const generation = this.sessionGeneration;
    const refresh = withWebAuthRefreshLock(
      withoutTrailingSlash(this.options.apiV2Url),
      async () => {
        try {
          if (generation !== this.sessionGeneration) return null;
          const request = () =>
            this.fetchWithTimeout(
              `${withoutTrailingSlash(this.options.apiV2Url)}/auth/web/refresh`,
              { method: 'POST', credentials: 'include' },
            );
          let response = await request();
          if (response.status === 401 && (await canRetryWebRotation(response))) {
            // Another origin can rotate the same API cookie outside our Web Lock.
            // Let its Set-Cookie settle, then retry once with the browser's cookie.
            await new Promise((resolve) => setTimeout(resolve, 200));
            if (generation !== this.sessionGeneration) return null;
            response = await request();
          }
          if (generation !== this.sessionGeneration) return null;
          if (response.status === 401) {
            const rotationRace = await isWebRotationRace(response);
            // Parsing the response yields, so a newer sign-in can invalidate
            // the generation checked above. Never clear its cached bearer.
            if (generation !== this.sessionGeneration) return null;
            if (rotationRace) {
              throw new TransportError({
                cause: null,
                message: 'Browser session refresh is busy. Retry startup.',
              });
            }
            this.cachedAccessToken = null;
            return null;
          }
          // Only an explicit rejected session means anonymous. Outages and bad
          // responses must reach startup's retry UI without discarding a session.
          if (response.status !== 200) {
            throw new ApiResponseError({
              status: response.status,
              body: await response.json().catch(() => null),
            });
          }
          const data = await parseResponseRecord(response);
          const token = nonEmptyString(data.access_token);
          if (token === null) throw new TypeError('Invalid browser session refresh response.');
          if (generation !== this.sessionGeneration) return null;
          this.cachedAccessToken = token;
          this.cachedRefreshToken = null;
          this.tokensLoaded = true;
          await this.options.sessions.clearWebLegacyTokens();
          if (generation !== this.sessionGeneration) return null;
          return token;
        } catch (cause) {
          if (generation !== this.sessionGeneration) return null;
          if (cause instanceof ApiResponseError || cause instanceof TransportError) throw cause;
          throw new TransportError({
            cause,
            message: 'Browser session refresh failed. Retry startup.',
          });
        }
      },
    );
    this.refreshInFlight = refresh;
    try {
      return await refresh;
    } finally {
      if (this.refreshInFlight === refresh) this.refreshInFlight = null;
    }
  }

  private async loadTokensOnce(): Promise<StoredAuthSession> {
    if (this.tokensLoaded) {
      return {
        accessToken: this.cachedAccessToken,
        refreshToken: this.cachedRefreshToken,
        deviceId: null,
      };
    }
    if (this.tokenLoad !== null) return this.tokenLoad;
    const load = this.options.sessions.read();
    const generation = this.sessionGeneration;
    this.tokenLoad = load;
    try {
      const session = await load;
      if (generation !== this.sessionGeneration) {
        return {
          accessToken: this.cachedAccessToken,
          refreshToken: this.cachedRefreshToken,
          deviceId: null,
        };
      }
      this.cacheSession(session);
      this.tokensLoaded = true;
      return session;
    } finally {
      if (this.tokenLoad === load) this.tokenLoad = null;
    }
  }

  private async saveSession(session: StoredAuthSession): Promise<void> {
    await this.options.sessions.write(session);
    this.cacheSession(session);
    this.tokensLoaded = true;
  }

  private cacheSession(session: StoredAuthSession): void {
    this.cachedAccessToken = session.accessToken;
    this.cachedRefreshToken = session.refreshToken;
  }

  private async clearSessionUnlocked(): Promise<void> {
    this.sessionGeneration += 1;
    this.cachedAccessToken = null;
    this.cachedRefreshToken = null;
    this.tokensLoaded = true;
    this.tokenLoad = null;
    this.refreshInFlight = null;
    await this.options.sessions.clear();
  }

  private async fetchWithTimeout(input: string, init: RequestInit): Promise<Response> {
    const controller = new AbortController();
    let timedOut = false;
    const timer = setTimeout(() => {
      timedOut = true;
      controller.abort();
    }, 10_000);
    try {
      return await this.fetchImplementation(input, {
        ...init,
        signal: controller.signal,
      });
    } catch (error) {
      if (timedOut) {
        const timeout = new Error('Token refresh timed out.');
        timeout.name = 'TimeoutError';
        throw timeout;
      }
      throw error;
    } finally {
      clearTimeout(timer);
    }
  }
}

async function canRetryWebRotation(response: Response): Promise<boolean> {
  const data: unknown = await response
    .clone()
    .json()
    .catch(() => null);
  // A delayed loser may reach SELECT after the winning transaction deleted the
  // old token; the API then uses "Invalid session" for the same race.
  return isRecord(data) && (data.message === 'Invalid session' || isRotationMessage(data.message));
}

async function isWebRotationRace(response: Response): Promise<boolean> {
  const data: unknown = await response
    .clone()
    .json()
    .catch(() => null);
  return isRecord(data) && isRotationMessage(data.message);
}

function isRotationMessage(message: unknown): boolean {
  return (
    message === 'Session was already refreshed' ||
    message === 'Browser session was already refreshed'
  );
}

function decodeBase64Url(value: string): string {
  const normalized = value.replaceAll('-', '+').replaceAll('_', '/');
  const padded = normalized.padEnd(normalized.length + ((4 - (normalized.length % 4)) % 4), '=');
  const binary = globalThis.atob(padded);
  const bytes = Uint8Array.from(binary, (character) => character.charCodeAt(0));
  return new TextDecoder().decode(bytes);
}

async function parseResponseRecord(response: Response): Promise<Record<string, unknown>> {
  const value: unknown = await response.json();
  if (!isRecord(value)) throw new TypeError('Invalid token response.');
  return value;
}

function nonEmptyString(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}

function withoutTrailingSlash(value: string): string {
  return value.replace(/\/+$/, '');
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
