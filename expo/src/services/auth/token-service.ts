import type { StoredAuthSession } from '../../core/dto/auth-session';
import type { AuthSessionRepository, RuntimePlatform } from '../storage/auth-storage';
import type { AuthRefreshLock } from './refresh-lock';

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
}

export class TokenService {
  private cachedAccessToken: string | null = null;
  private cachedRefreshToken: string | null = null;
  private tokensLoaded = false;
  private tokenLoad: Promise<StoredAuthSession> | null = null;
  private refreshInFlight: Promise<string | null> | null = null;
  private readonly fetchImplementation: typeof fetch;
  private readonly nowSeconds: () => number;

  constructor(private readonly options: TokenServiceOptions) {
    this.fetchImplementation = options.fetchImplementation ?? fetch;
    this.nowSeconds = options.nowSeconds ?? (() => Math.floor(Date.now() / 1000));
  }

  getDeviceId(): Promise<string> {
    return this.options.deviceIdentity.getDeviceId();
  }

  getDeviceName(): Promise<string> {
    return this.options.deviceIdentity.getDeviceName();
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
      await this.saveSession({ accessToken, refreshToken, deviceId });
      return true;
    });
    if (saved !== true) {
      throw new Error('Could not acquire the shared authentication lock.');
    }
  }

  async clearTokens(): Promise<void> {
    const clear = async () => {
      this.cachedAccessToken = null;
      this.cachedRefreshToken = null;
      this.tokensLoaded = true;
      this.tokenLoad = null;
      this.refreshInFlight = null;
      await this.options.sessions.clear();
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

  private async refreshExpiredToken(refreshToken: string): Promise<string | null> {
    if (this.refreshInFlight !== null) return this.refreshInFlight;
    const refresh = (async () => this.refreshAccessToken(refreshToken, await this.getDeviceId()))();
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
  ): Promise<string | null> {
    if (this.options.platform === 'web') return this.refreshWebAccessToken();
    try {
      const refreshed = await this.options.refreshLock.run(async () => {
        const latest = await this.options.sessions.read();
        if (
          latest.accessToken !== null &&
          latest.refreshToken !== null &&
          !this.isTokenExpired(latest.accessToken)
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
        if (response.status !== 200) return null;
        const data = await parseResponseRecord(response);
        const accessToken = nonEmptyString(data.access_token);
        const refreshToken = nonEmptyString(data.refresh_token);
        if (accessToken === null || refreshToken === null) return null;
        await this.saveSession({
          accessToken,
          refreshToken,
          deviceId: currentDeviceId,
        });
        return accessToken;
      });
      return refreshed ?? null;
    } catch {
      return null;
    }
  }

  private async refreshWebAccessToken(): Promise<string | null> {
    if (this.refreshInFlight !== null) return this.refreshInFlight;
    const refresh = (async () => {
      try {
        const response = await this.fetchWithTimeout(
          `${withoutTrailingSlash(this.options.apiV2Url)}/auth/web/refresh`,
          { method: 'POST', credentials: 'include' },
        );
        if (response.status !== 200) {
          this.cachedAccessToken = null;
          return null;
        }
        const data = await parseResponseRecord(response);
        const token = nonEmptyString(data.access_token);
        if (token === null) return null;
        await this.saveWebAccessToken(token);
        return token;
      } catch {
        return null;
      }
    })();
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
    this.tokenLoad = load;
    try {
      const session = await load;
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

  private async fetchWithTimeout(input: string, init: RequestInit): Promise<Response> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 10_000);
    try {
      return await this.fetchImplementation(input, {
        ...init,
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timer);
    }
  }
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
