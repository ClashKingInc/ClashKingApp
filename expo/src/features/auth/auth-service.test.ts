import { ApiClient, EmailVerificationRequiredException } from '../../core/api/client';
import type { DiscordOAuthClient } from '../../services/auth/discord-oauth';
import type { TokenService } from '../../services/auth/token-service';
import type { StringStore } from '../../services/storage/auth-storage';
import { AuthFlowException, AuthService, type AuthObservability } from './auth-service';

class MemoryPreferences implements StringStore {
  readonly values = new Map<string, string>();
  clearError: Error | null = null;

  async getItem(key: string) {
    return this.values.get(key) ?? null;
  }

  async setItem(key: string, value: string) {
    this.values.set(key, value);
  }

  async removeItem(key: string) {
    this.values.delete(key);
  }

  async clear() {
    if (this.clearError) throw this.clearError;
    this.values.clear();
  }
}

function tokens(overrides: Partial<TokenService> = {}): TokenService {
  return {
    getAccessToken: jest.fn(async () => null),
    getDeviceId: jest.fn(async () => 'device-id'),
    getDeviceName: jest.fn(async () => 'device-name'),
    saveWebAccessToken: jest.fn(async () => undefined),
    saveTokens: jest.fn(async () => undefined),
    clearTokens: jest.fn(async () => undefined),
    isTokenExpired: jest.fn(() => false),
    ...overrides,
  } as TokenService;
}

function apiWith(responder: (path: string, init?: RequestInit) => Response | Promise<Response>): {
  api: ApiClient;
  requests: { path: string; init?: RequestInit }[];
} {
  const requests: { path: string; init?: RequestInit }[] = [];
  const api = new ApiClient({
    baseUrl: 'https://api.example/v2',
    environment: 'production',
    tokenProvider: { getAccessToken: async () => 'access' },
    fetchImplementation: jest.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = new URL(String(input));
      const path = `${url.pathname}${url.search}`;
      requests.push({ path, init });
      return responder(path, init);
    }) as typeof fetch,
  });
  return { api, requests };
}

function authResponse(overrides: Record<string, unknown> = {}) {
  return {
    access_token: 'access',
    refresh_token: 'refresh',
    user: { user_id: 'user-1', username: 'Player' },
    account_summary: { follower_count: '7' },
    ...overrides,
  };
}

function serviceOptions(options: {
  api: ApiClient;
  tokenService?: TokenService;
  preferences?: MemoryPreferences;
  platform?: 'web' | 'native';
  environment?: 'local' | 'staging' | 'production';
  discordOAuth?: DiscordOAuthClient;
  unregisterPushDevice?: () => Promise<void>;
  observability?: AuthObservability;
  isNetworkError?: (error: unknown) => boolean;
}) {
  return {
    api: options.api,
    tokens: options.tokenService ?? tokens(),
    preferences: options.preferences ?? new MemoryPreferences(),
    environment: options.environment ?? ('production' as const),
    platform: options.platform ?? ('native' as const),
    discordOAuth: options.discordOAuth ?? ({} as DiscordOAuthClient),
    unregisterPushDevice: options.unregisterPushDevice ?? (async () => undefined),
    observability: options.observability,
    isNetworkError: options.isNetworkError,
  };
}

describe('AuthService', () => {
  test('initializes local auth without stored tokens and publishes the parsed account summary', async () => {
    const { api, requests } = apiWith(
      () =>
        new Response(
          JSON.stringify({ user_id: 'local-user', account_summary: { follower_count: 3 } }),
        ),
    );
    const preferenceStore = new MemoryPreferences();
    preferenceStore.values.set('auth_local_mode', 'true');
    const observability = {
      setAuthenticatedUser: jest.fn(async () => undefined),
      clearUser: jest.fn(async () => undefined),
    };
    const auth = new AuthService(
      serviceOptions({
        api,
        preferences: preferenceStore,
        environment: 'local',
        observability,
      }),
    );
    const listener = jest.fn();
    const unsubscribe = auth.subscribe(listener);

    await auth.initializeAuth();

    expect(requests[0]).toMatchObject({ path: '/v2/auth/me' });
    expect(auth.state).toMatchObject({ isAuthenticated: true, followerCount: 3 });
    expect(auth.canUseApp).toBe(true);
    expect(preferenceStore.values.has('auth_local_mode')).toBe(false);
    expect(observability.setAuthenticatedUser).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'local-user' }),
    );
    expect(listener).toHaveBeenCalledTimes(1);
    unsubscribe();
  });

  test('restores a remote session, keeps it during network failure, and clears invalid sessions', async () => {
    const restore = apiWith(() => new Response(JSON.stringify({ user_id: 'user-1' })));
    const storedTokens = tokens({ getAccessToken: jest.fn(async () => 'stored') });
    const restored = new AuthService(
      serviceOptions({ api: restore.api, tokenService: storedTokens }),
    );
    await restored.initializeAuth();
    expect(restored.state).toMatchObject({ accessToken: 'stored', isAuthenticated: true });

    const offline = apiWith(() => {
      throw new TypeError('offline');
    });
    const offlineAuth = new AuthService(
      serviceOptions({ api: offline.api, tokenService: storedTokens }),
    );
    await expect(offlineAuth.initializeAuth()).rejects.toThrow('offline');
    expect(offlineAuth.state).toMatchObject({ accessToken: 'stored', isAuthenticated: true });

    const rejected = apiWith(() => new Response('{"detail":"invalid"}', { status: 401 }));
    const rejectedTokens = tokens({ getAccessToken: jest.fn(async () => 'expired') });
    const observability = {
      setAuthenticatedUser: jest.fn(async () => undefined),
      clearUser: jest.fn(async () => undefined),
    };
    const rejectedAuth = new AuthService(
      serviceOptions({
        api: rejected.api,
        tokenService: rejectedTokens,
        observability,
        isNetworkError: () => false,
      }),
    );
    await expect(rejectedAuth.initializeAuth()).rejects.toThrow();
    expect(rejectedTokens.clearTokens).toHaveBeenCalled();
    expect(observability.clearUser).toHaveBeenCalled();
    expect(rejectedAuth.state.isAuthenticated).toBe(false);
  });

  test('uses native Discord exchange details and wraps cancellation and exchange failures', async () => {
    const { api, requests } = apiWith(
      (path) =>
        new Response(
          JSON.stringify(path.endsWith('/auth/me') ? { user_id: 'user-1' } : authResponse()),
        ),
    );
    const tokenService = tokens();
    const oauth = {
      authorize: jest.fn(async () => ({
        code: 'discord-code',
        redirectUri: 'clashking://callback',
        codeVerifier: 'verifier',
      })),
    } as unknown as DiscordOAuthClient;
    const auth = new AuthService(serviceOptions({ api, tokenService, discordOAuth: oauth }));

    await auth.signInWithDiscord();

    expect(requests[0]?.path).toBe('/v2/auth/discord');
    expect(JSON.parse(String(requests[0]?.init?.body))).toEqual({
      code: 'discord-code',
      redirect_uri: 'clashking://callback',
      code_verifier: 'verifier',
      device_id: 'device-id',
    });
    expect(tokenService.saveTokens).toHaveBeenCalledWith('access', 'refresh');
    expect(auth.state.followerCount).toBe(7);

    const cancelled = new AuthService(
      serviceOptions({
        api,
        discordOAuth: { authorize: jest.fn(async () => null) } as unknown as DiscordOAuthClient,
      }),
    );
    await expect(cancelled.signInWithDiscord()).rejects.toMatchObject({
      name: 'AuthFlowException',
      cause: expect.any(AuthFlowException),
    });
  });

  test('supports registration, verification, password reset, export, and deletion contracts', async () => {
    const { api, requests } = apiWith((path) => {
      if (path.endsWith('/auth/me')) return new Response('{}');
      if (path.endsWith('/auth/export')) return new Response('{"ready":true}');
      if (path.endsWith('/auth/register')) return new Response('{"registered":true}');
      if (path.endsWith('/auth/resend-verification')) return new Response('{"sent":true}');
      if (path.endsWith('/auth/forgot-password')) return new Response('{"sent":true}');
      return new Response(JSON.stringify(authResponse()));
    });
    const tokenService = tokens();
    const auth = new AuthService(serviceOptions({ api, tokenService }));

    await expect(auth.registerWithEmail('a@example.com', 'password', 'Name')).resolves.toEqual({
      registered: true,
    });
    await auth.verifyEmailWithCode('a@example.com', '123456');
    await expect(auth.resendVerificationEmail('a@example.com')).resolves.toEqual({ sent: true });
    await expect(auth.forgotPassword('a@example.com')).resolves.toEqual({ sent: true });
    await auth.resetPassword('a@example.com', 'reset', 'new-password');
    await expect(auth.requestDataExport()).resolves.toEqual({ ready: true });
    await auth.deleteAccount();

    expect(requests.map(({ path }) => path)).toEqual(
      expect.arrayContaining([
        '/v2/auth/register',
        '/v2/auth/verify-email-code',
        '/v2/auth/resend-verification',
        '/v2/auth/forgot-password',
        '/v2/auth/reset-password',
        '/v2/auth/export',
        '/v2/auth/me',
      ]),
    );
    expect(tokenService.clearTokens).toHaveBeenCalled();
    expect(auth.state.isAuthenticated).toBe(false);
  });

  test('preserves email-verification errors and rejects malformed authentication payloads', async () => {
    const verificationRequired = apiWith(
      () => new Response('{"detail":"verify"}', { status: 409 }),
    );
    const auth = new AuthService(serviceOptions({ api: verificationRequired.api }));
    await expect(auth.signInWithEmail('a@example.com', 'password')).rejects.toBeInstanceOf(
      EmailVerificationRequiredException,
    );

    const malformed = apiWith(() => new Response('{"user":{"user_id":"u"}}'));
    const malformedAuth = new AuthService(serviceOptions({ api: malformed.api }));
    await expect(malformedAuth.signInWithEmail('a@example.com', 'password')).rejects.toMatchObject({
      name: 'AuthFlowException',
      cause: expect.any(TypeError),
    });

    const nativeMissingRefresh = apiWith(
      () => new Response(JSON.stringify(authResponse({ refresh_token: undefined }))),
    );
    await expect(
      new AuthService(serviceOptions({ api: nativeMissingRefresh.api })).signInWithEmail(
        'a@example.com',
        'password',
      ),
    ).rejects.toMatchObject({ name: 'AuthFlowException', cause: expect.any(TypeError) });
  });

  test('sign out is local-first when remote cleanup and preference clearing fail', async () => {
    const { api, requests } = apiWith(() => {
      throw new TypeError('offline');
    });
    const preferenceStore = new MemoryPreferences();
    preferenceStore.clearError = new Error('storage unavailable');
    const tokenService = tokens();
    const observability = {
      setAuthenticatedUser: jest.fn(async () => undefined),
      clearUser: jest.fn(async () => undefined),
    };
    const clearAccountData = jest.fn();
    const auth = new AuthService({
      ...serviceOptions({
        api,
        tokenService,
        preferences: preferenceStore,
        platform: 'web',
        unregisterPushDevice: async () => {
          throw new TypeError('push offline');
        },
        observability,
      }),
      clearAccountData,
    });

    await expect(auth.signOut()).resolves.toBeUndefined();

    expect(requests[0]?.path).toBe('/v2/auth/web/logout');
    expect(tokenService.clearTokens).toHaveBeenCalled();
    expect(clearAccountData).toHaveBeenCalled();
    expect(observability.clearUser).toHaveBeenCalled();
    expect(auth.state).toEqual({
      accessToken: null,
      isAuthenticated: false,
      currentUser: null,
      followerCount: null,
    });
  });
});
