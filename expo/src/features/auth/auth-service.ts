import {
  AuthDeleteEndpoint,
  AuthDiscordEndpoint,
  AuthEmailEndpoint,
  AuthExportEndpoint,
  AuthForgotPasswordEndpoint,
  AuthMeEndpoint,
  AuthRegisterEndpoint,
  AuthResendVerificationEndpoint,
  AuthResetPasswordEndpoint,
  AuthVerifyEmailEndpoint,
  AuthWebDiscordEndpoint,
  AuthWebEmailEndpoint,
  AuthWebLogoutEndpoint,
  AuthWebResetPasswordEndpoint,
  AuthWebVerifyEmailEndpoint,
  type AnyEndpoint,
  type EndpointRequest,
  type EndpointResponse,
} from '@clashking/api-contracts/expo';
import { Effect } from 'effect';
import { TransportError } from '@clashking/api-client';

import {
  EmailVerificationRequiredException,
  type ContractApiService,
} from '../../core/api/contract-api';
import type { ApiEnvironment } from '../../core/config/api-config';
import type { DiscordOAuthClient } from '../../services/auth/discord-oauth';
import type { TokenService } from '../../services/auth/token-service';
import type { StringStore } from '../../services/storage/auth-storage';
import { parseAuthUser, type AuthUser } from './models';

export interface AuthObservability {
  setAuthenticatedUser(user: AuthUser): Promise<void>;
  clearUser(): Promise<void>;
}

export interface AuthServiceOptions {
  readonly api: ContractApiService;
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

interface AuthenticationResponse {
  readonly access_token: string;
  readonly account_summary?: unknown;
  readonly refresh_token?: string;
  readonly user: unknown;
}

type CurrentUserResponse = EndpointResponse<typeof AuthMeEndpoint>;

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
      const response = await this.execute(AuthMeEndpoint, {});
      await this.applyAuthenticatedResponse(response, null);
      return;
    }

    const accessToken = await this.options.tokens.getAccessToken();
    if (accessToken === null) {
      this.publish({ ...this.stateValue, accessToken: null });
      return;
    }

    try {
      const response = await this.execute(AuthMeEndpoint, {});
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
      const input = {
        path: {},
        query: {},
        body: {
          code: authorization.code,
          redirect_uri: authorization.redirectUri,
          code_verifier: authorization.codeVerifier,
          device_id: deviceId,
        },
      };
      const response =
        this.options.platform === 'web'
          ? await Effect.runPromise(this.options.api.execute(AuthWebDiscordEndpoint, input))
          : await Effect.runPromise(this.options.api.execute(AuthDiscordEndpoint, input));
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
      const input = {
        path: {},
        query: {},
        body: { email, password, device_id: deviceId, device_name: deviceName },
      };
      const result =
        this.options.platform === 'web'
          ? await Effect.runPromise(this.options.api.executeStatus(AuthWebEmailEndpoint, input))
          : await Effect.runPromise(this.options.api.executeStatus(AuthEmailEndpoint, input));
      if (!result.ok) throw new EmailVerificationRequiredException(result.body.message);
      const response = result.value;
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
  ): Promise<EndpointResponse<typeof AuthRegisterEndpoint>> {
    return this.withDevice(async (deviceId, deviceName) =>
      this.execute(AuthRegisterEndpoint, {
        email,
        password,
        username,
        device_id: deviceId,
        device_name: deviceName,
      }),
    );
  }

  async verifyEmailWithCode(email: string, code: string): Promise<void> {
    const input = { path: {}, query: {}, body: { email, code } };
    const response =
      this.options.platform === 'web'
        ? await Effect.runPromise(this.options.api.execute(AuthWebVerifyEmailEndpoint, input))
        : await Effect.runPromise(this.options.api.execute(AuthVerifyEmailEndpoint, input));
    await this.finishAuthentication(response);
  }

  resendVerificationEmail(
    email: string,
  ): Promise<EndpointResponse<typeof AuthResendVerificationEndpoint>> {
    return this.execute(AuthResendVerificationEndpoint, { email });
  }

  forgotPassword(email: string): Promise<EndpointResponse<typeof AuthForgotPasswordEndpoint>> {
    return this.execute(AuthForgotPasswordEndpoint, { email });
  }

  async resetPassword(email: string, resetCode: string, newPassword: string): Promise<void> {
    const response = await this.withDevice((deviceId, deviceName) => {
      const input = {
        path: {},
        query: {},
        body: {
          email,
          reset_code: resetCode,
          new_password: newPassword,
          device_id: deviceId,
          device_name: deviceName,
        },
      };
      return this.options.platform === 'web'
        ? Effect.runPromise(this.options.api.execute(AuthWebResetPasswordEndpoint, input))
        : Effect.runPromise(this.options.api.execute(AuthResetPasswordEndpoint, input));
    });
    await this.finishAuthentication(response);
  }

  requestDataExport(): Promise<EndpointResponse<typeof AuthExportEndpoint>> {
    return this.execute(AuthExportEndpoint, {});
  }

  async deleteAccount(): Promise<void> {
    await this.execute(AuthDeleteEndpoint, {});
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
        await this.execute(AuthWebLogoutEndpoint, {});
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

  private async finishAuthentication(response: AuthenticationResponse): Promise<void> {
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
    response: CurrentUserResponse,
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
      const response = await this.execute(AuthMeEndpoint, {});
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

  private execute<E extends AnyEndpoint>(
    endpoint: E,
    body: EndpointRequest<E>['body'],
  ): Promise<EndpointResponse<E>> {
    const input = { path: {}, query: {}, body } as EndpointRequest<E>;
    return Effect.runPromise(this.options.api.execute(endpoint, input));
  }

  private publish(state: AuthState): void {
    this.stateValue = state;
    for (const listener of this.listeners) listener(state);
  }
}

function followerCount(response: { readonly account_summary?: unknown }): number | null {
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
    error instanceof TransportError ||
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
