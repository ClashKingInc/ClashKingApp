import { EmailVerificationRequiredException, type ApiClient } from '../../core/api/client';
import type { ApiEnvironment } from '../../core/config/api-config';
import type { DiscordOAuthClient } from '../../services/auth/discord-oauth';
import type { TokenService } from '../../services/auth/token-service';
import type { StringStore } from '../../services/storage/auth-storage';
import { parseAuthUser, type AuthUser } from './models';

const AUTH_ME_PATH = '/auth/me';
const ALL_SUCCESS_STATUSES = Array.from({ length: 100 }, (_, index) => index + 200);

export interface AuthObservability {
  setAuthenticatedUser(user: AuthUser): Promise<void>;
  clearUser(): Promise<void>;
}

export interface AuthServiceOptions {
  readonly api: ApiClient;
  readonly tokens: TokenService;
  readonly preferences: StringStore & { clear(): Promise<void> };
  readonly environment: ApiEnvironment;
  readonly platform: 'web' | 'native';
  readonly discordOAuth: DiscordOAuthClient;
  readonly unregisterPushDevice: () => Promise<void>;
  readonly clearAccountData?: () => void;
  readonly observability?: AuthObservability;
  readonly isNetworkError?: (error: unknown) => boolean;
}

export interface AuthState {
  readonly accessToken: string | null;
  readonly isAuthenticated: boolean;
  readonly currentUser: AuthUser | null;
  readonly followerCount: number | null;
}

export class AuthFlowException extends Error {
  constructor(message: string, options?: ErrorOptions) {
    super(message, options);
    this.name = 'AuthFlowException';
  }
}

export class AuthService {
  private stateValue: AuthState = {
    accessToken: null,
    isAuthenticated: false,
    currentUser: null,
    followerCount: null,
  };
  private readonly listeners = new Set<(state: AuthState) => void>();
  private readonly isNetworkError: (error: unknown) => boolean;

  constructor(private readonly options: AuthServiceOptions) {
    this.isNetworkError = options.isNetworkError ?? defaultIsNetworkError;
  }

  get state(): AuthState {
    return this.stateValue;
  }

  get canUseApp(): boolean {
    return this.stateValue.isAuthenticated;
  }

  subscribe(listener: (state: AuthState) => void): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  async initializeAuth(): Promise<void> {
    await this.options.preferences.removeItem('auth_local_mode');
    if (this.options.environment === 'local') {
      const response = await this.options.api.requestRecord(AUTH_ME_PATH, {
        requiresAuth: false,
      });
      await this.applyAuthenticatedResponse(response, null);
      return;
    }

    const accessToken = await this.options.tokens.getAccessToken();
    if (accessToken === null) {
      this.publish({ ...this.stateValue, accessToken: null });
      return;
    }

    try {
      const response = await this.options.api.requestRecord(AUTH_ME_PATH, {
        requiresAuth: true,
      });
      await this.applyAuthenticatedResponse(response, accessToken);
    } catch (error) {
      if (this.isNetworkError(error)) {
        this.publish({
          ...this.stateValue,
          accessToken,
          isAuthenticated: true,
        });
      } else {
        await this.options.tokens.clearTokens();
        await this.options.observability?.clearUser();
        this.publish({
          accessToken: null,
          isAuthenticated: false,
          currentUser: null,
          followerCount: null,
        });
      }
      throw error;
    }
  }

  async signInWithDiscord(): Promise<void> {
    try {
      const authorization = await this.options.discordOAuth.authorize();
      if (authorization === null) {
        throw new AuthFlowException('Discord login was cancelled.');
      }
      const deviceId = await this.options.tokens.getDeviceId();
      const response = await this.options.api.requestRecord(
        this.options.platform === 'web' ? '/auth/web/discord' : '/auth/discord',
        {
          method: 'POST',
          body: {
            code: authorization.code,
            redirect_uri: authorization.redirectUri,
            code_verifier: authorization.codeVerifier,
            device_id: deviceId,
          },
        },
      );
      await this.finishAuthentication(response);
    } catch (error) {
      throw new AuthFlowException('Discord login failed.', { cause: error });
    }
  }

  async signInWithEmail(email: string, password: string): Promise<void> {
    try {
      const [deviceId, deviceName] = await Promise.all([
        this.options.tokens.getDeviceId(),
        this.options.tokens.getDeviceName(),
      ]);
      const response = await this.options.api.requestRecord(
        this.options.platform === 'web' ? '/auth/web/email' : '/auth/email',
        {
          method: 'POST',
          body: {
            email,
            password,
            device_id: deviceId,
            device_name: deviceName,
          },
        },
      );
      await this.finishAuthentication(response);
    } catch (error) {
      if (error instanceof EmailVerificationRequiredException) throw error;
      throw new AuthFlowException('Email login failed.', { cause: error });
    }
  }

  registerWithEmail(
    email: string,
    password: string,
    username: string,
  ): Promise<Record<string, unknown>> {
    return this.withDevice(async (deviceId, deviceName) =>
      this.options.api.requestRecord('/auth/register', {
        method: 'POST',
        body: {
          email,
          password,
          username,
          device_id: deviceId,
          device_name: deviceName,
        },
      }),
    );
  }

  async verifyEmailWithCode(email: string, code: string): Promise<void> {
    const response = await this.options.api.requestRecord(
      this.options.platform === 'web' ? '/auth/web/verify-email-code' : '/auth/verify-email-code',
      { method: 'POST', body: { email, code } },
    );
    await this.finishAuthentication(response);
  }

  resendVerificationEmail(email: string): Promise<Record<string, unknown>> {
    return this.options.api.requestRecord('/auth/resend-verification', {
      method: 'POST',
      body: { email },
    });
  }

  forgotPassword(email: string): Promise<Record<string, unknown>> {
    return this.options.api.requestRecord('/auth/forgot-password', {
      method: 'POST',
      body: { email },
    });
  }

  async resetPassword(email: string, resetCode: string, newPassword: string): Promise<void> {
    const response = await this.withDevice((deviceId, deviceName) =>
      this.options.api.requestRecord(
        this.options.platform === 'web' ? '/auth/web/reset-password' : '/auth/reset-password',
        {
          method: 'POST',
          body: {
            email,
            reset_code: resetCode,
            new_password: newPassword,
            device_id: deviceId,
            device_name: deviceName,
          },
        },
      ),
    );
    await this.finishAuthentication(response);
  }

  requestDataExport(): Promise<Record<string, unknown>> {
    return this.options.api.requestRecord('/auth/export', {
      requiresAuth: true,
    });
  }

  async deleteAccount(): Promise<void> {
    await this.options.api.request(AUTH_ME_PATH, {
      method: 'DELETE',
      requiresAuth: true,
      acceptedStatuses: ALL_SUCCESS_STATUSES,
    });
    await this.signOut();
  }

  async signOut(): Promise<void> {
    // Push deregistration must observe the still-valid session and token.
    try {
      await this.options.unregisterPushDevice();
    } catch {
      // Logout remains local-first when the device is offline.
    }
    if (this.options.platform === 'web') {
      try {
        await this.options.api.request('/auth/web/logout', {
          method: 'POST',
          acceptedStatuses: ALL_SUCCESS_STATUSES,
        });
      } catch {
        // The HTTP-only refresh cookie may remain until the server is reachable.
      }
    }
    await this.options.tokens.clearTokens();
    try {
      await this.options.preferences.clear();
    } catch {
      // Flutter also treats clearing non-secret preferences as best effort.
    }
    this.options.clearAccountData?.();
    await this.options.observability?.clearUser();
    this.publish({
      accessToken: null,
      isAuthenticated: false,
      currentUser: null,
      followerCount: null,
    });
  }

  private async finishAuthentication(response: Record<string, unknown>): Promise<void> {
    const accessToken = nonEmptyString(response.access_token);
    if (accessToken === null) {
      throw new TypeError('Authentication response omitted access_token.');
    }
    if (this.options.platform === 'web') {
      await this.options.tokens.saveWebAccessToken(accessToken);
    } else {
      const refreshToken = nonEmptyString(response.refresh_token);
      if (refreshToken === null) {
        throw new TypeError('Authentication response omitted refresh_token.');
      }
      await this.options.tokens.saveTokens(accessToken, refreshToken);
    }
    await this.options.preferences.removeItem('auth_local_mode');
    const user = parseAuthUser(response.user);
    await this.options.observability?.setAuthenticatedUser(user);
    this.publish({
      accessToken,
      isAuthenticated: true,
      currentUser: user,
      followerCount: followerCount(response),
    });
    void this.refreshAccountSummary();
  }

  private async applyAuthenticatedResponse(
    response: Record<string, unknown>,
    accessToken: string | null,
  ): Promise<void> {
    const user = parseAuthUser(response);
    await this.options.observability?.setAuthenticatedUser(user);
    this.publish({
      accessToken,
      isAuthenticated: true,
      currentUser: user,
      followerCount: followerCount(response),
    });
  }

  private async refreshAccountSummary(): Promise<void> {
    try {
      const response = await this.options.api.requestRecord(AUTH_ME_PATH, {
        requiresAuth: true,
      });
      if (
        !this.stateValue.isAuthenticated ||
        String(response.user_id ?? '') !== this.stateValue.currentUser?.userId
      ) {
        return;
      }
      this.publish({ ...this.stateValue, followerCount: followerCount(response) });
    } catch {
      // Summary refresh is deliberately best effort.
    }
  }

  private withDevice<T>(
    operation: (deviceId: string, deviceName: string) => Promise<T>,
  ): Promise<T> {
    return Promise.all([
      this.options.tokens.getDeviceId(),
      this.options.tokens.getDeviceName(),
    ]).then(([deviceId, deviceName]) => operation(deviceId, deviceName));
  }

  private publish(state: AuthState): void {
    this.stateValue = state;
    for (const listener of this.listeners) listener(state);
  }
}

function followerCount(response: Record<string, unknown>): number | null {
  const summary = isRecord(response.account_summary) ? response.account_summary : null;
  const raw = summary?.follower_count;
  if (typeof raw === 'number') return Math.trunc(raw);
  if (raw === undefined || raw === null || String(raw).length === 0) return null;
  const parsed = Number.parseInt(String(raw), 10);
  return Number.isNaN(parsed) ? null : parsed;
}

function nonEmptyString(value: unknown): string | null {
  return typeof value === 'string' && value.length > 0 ? value : null;
}

function defaultIsNetworkError(error: unknown): boolean {
  const text = String(error).toLowerCase();
  return (
    error instanceof TypeError ||
    text.includes('network') ||
    text.includes('connection') ||
    text.includes('hostname') ||
    text.includes('socket') ||
    text.includes('timeout') ||
    text.includes('no address') ||
    text.includes('xmlhttprequest') ||
    text.includes('failed to fetch')
  );
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
