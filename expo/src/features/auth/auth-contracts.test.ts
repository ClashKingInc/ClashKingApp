import { ApiClient } from '../../core/api/client';
import type { DiscordOAuthClient } from '../../services/auth/discord-oauth';
import {
  DISCORD_CLIENT_ID,
  buildDiscordAuthorizationUrl,
  resolveDiscordRedirectUri,
} from '../../services/auth/discord-oauth';
import type { TokenService } from '../../services/auth/token-service';
import type { StringStore } from '../../services/storage/auth-storage';
import { CocAccountService } from './account-service';
import { AuthService } from './auth-service';
import { parseCocAccountLink } from './models';
import { startupDecision } from './startup';

class MemoryPreferences implements StringStore {
  readonly values = new Map<string, string>();
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
    this.values.clear();
  }
}

function fakeTokens(overrides: Partial<TokenService> = {}): TokenService {
  return {
    getAccessToken: async () => null,
    getDeviceId: async () => 'device-id',
    getDeviceName: async () => 'device-name',
    saveWebAccessToken: async () => undefined,
    saveTokens: async () => undefined,
    clearTokens: async () => undefined,
    isTokenExpired: () => false,
    ...overrides,
  } as TokenService;
}

describe('auth endpoint contracts', () => {
  it('preserves Discord redirect selection and authorization parameters', () => {
    expect(
      resolveDiscordRedirectUri({
        platform: 'web',
        webOrigin: 'http://localhost:8081',
        webHost: 'localhost',
      }),
    ).toBe('http://localhost:8081/auth/callback');
    expect(
      resolveDiscordRedirectUri({
        platform: 'web',
        webOrigin: 'https://dev-app.clashk.ing',
        webHost: 'dev-app.clashk.ing',
      }),
    ).toBe('https://dev-app.clashk.ing/auth/discord_callback.html');
    const authorization = new URL(
      buildDiscordAuthorizationUrl('clashking://callback', 'state', 'challenge'),
    );
    expect(authorization.searchParams.get('client_id')).toBe(DISCORD_CLIENT_ID);
    expect(authorization.searchParams.get('scope')).toBe('identify');
    expect(authorization.searchParams.get('code_challenge_method')).toBe('S256');
  });

  it('uses web email endpoints and stores only the returned access token', async () => {
    let request: { input: RequestInfo | URL; init?: RequestInit } | undefined;
    let savedAccess: string | null = null;
    const api = new ApiClient({
      baseUrl: 'https://api.example/v2',
      environment: 'production',
      platform: 'web',
      fetchImplementation: async (input, init) => {
        request = { input, init };
        return new Response(
          JSON.stringify({
            access_token: 'access',
            user: { user_id: 'user-1', username: 'Name' },
          }),
          { status: 200 },
        );
      },
    });
    const auth = new AuthService({
      api,
      tokens: fakeTokens({
        saveWebAccessToken: async (token) => {
          savedAccess = token;
        },
      }),
      preferences: new MemoryPreferences(),
      environment: 'production',
      platform: 'web',
      discordOAuth: {} as DiscordOAuthClient,
      unregisterPushDevice: async () => undefined,
    });

    await auth.signInWithEmail('a@example.com', 'secret');
    expect(request?.input).toBe('https://api.example/v2/auth/web/email');
    expect(JSON.parse(String(request?.init?.body))).toEqual({
      email: 'a@example.com',
      password: 'secret',
      device_id: 'device-id',
      device_name: 'device-name',
    });
    expect(savedAccess).toBe('access');
    expect(auth.state.currentUser?.userId).toBe('user-1');
  });

  it('unregisters push before clearing the local session', async () => {
    const order: string[] = [];
    const api = new ApiClient({
      baseUrl: 'https://api.example/v2',
      environment: 'production',
      fetchImplementation: async () => new Response('{}'),
    });
    const auth = new AuthService({
      api,
      tokens: fakeTokens({
        clearTokens: async () => {
          order.push('tokens');
        },
      }),
      preferences: Object.assign(new MemoryPreferences(), {
        clear: async () => {
          order.push('preferences');
        },
      }),
      environment: 'production',
      platform: 'native',
      discordOAuth: {} as DiscordOAuthClient,
      unregisterPushDevice: async () => {
        order.push('push');
      },
      clearAccountData: () => {
        order.push('account-data');
      },
    });
    await auth.signOut();
    expect(order).toEqual(['push', 'tokens', 'preferences', 'account-data']);
  });
});

describe('account and startup contracts', () => {
  it('requires hidden, defaults is_verified, and requires verification for Home', () => {
    expect(parseCocAccountLink({ player_tag: '#ABC', hidden: false }).isVerified).toBe(false);
    expect(() => parseCocAccountLink({ player_tag: '#ABC' })).toThrow('hidden must be a bool');
    expect(startupDecision(true, false).destination).toBe('account-setup');
    expect(startupDecision(true, true).destination).toBe('home');
  });

  it('fetches only the encoded user links endpoint', async () => {
    const requested: string[] = [];
    const api = new ApiClient({
      baseUrl: 'https://api.example/v2',
      environment: 'production',
      tokenProvider: { getAccessToken: async () => 'token' },
      fetchImplementation: async (input) => {
        requested.push(String(input));
        return new Response(
          JSON.stringify({
            items: [{ player_tag: '#ABC', hidden: false, is_verified: true }],
          }),
        );
      },
    });
    const accounts = new CocAccountService(api, new MemoryPreferences());
    accounts.setCurrentUserId('user/id');
    await accounts.fetchAccounts();
    expect(requested).toEqual(['https://api.example/v2/links/user%2Fid']);
    expect(accounts.hasVerifiedAccounts).toBe(true);
  });

  it('publishes account changes and clears the Flutter-compatible refresh timestamp on logout', async () => {
    const api = new ApiClient({
      baseUrl: 'https://api.example/v2',
      environment: 'production',
      tokenProvider: { getAccessToken: async () => 'token' },
      fetchImplementation: async () =>
        new Response(
          JSON.stringify({
            items: [{ player_tag: '#ABC', hidden: false, is_verified: true }],
          }),
        ),
    });
    const accounts = new CocAccountService(api, new MemoryPreferences());
    accounts.setCurrentUserId('user');
    let changes = 0;
    const unsubscribe = accounts.subscribe(() => changes++);

    await accounts.fetchAccounts();
    const refreshedAt = new Date('2026-08-29T12:00:00.000Z');
    accounts.updateRefreshTime(refreshedAt);
    expect(accounts.lastRefresh).toEqual(refreshedAt);
    accounts.clearAccountData();

    expect(accounts.lastRefresh).toBeNull();
    expect(changes).toBe(3);
    unsubscribe();
  });

  it('preserves the stored selection even when that linked account is unverified', async () => {
    const preferences = new MemoryPreferences();
    await preferences.setItem('selectedTag', '#UNVERIFIED');
    const api = new ApiClient({
      baseUrl: 'https://api.example/v2',
      environment: 'production',
      tokenProvider: { getAccessToken: async () => 'token' },
      fetchImplementation: async () =>
        new Response(
          JSON.stringify({
            items: [
              { player_tag: '#UNVERIFIED', hidden: false, is_verified: false },
              { player_tag: '#VERIFIED', hidden: false, is_verified: true },
            ],
          }),
        ),
    });
    const accounts = new CocAccountService(api, preferences);
    accounts.setCurrentUserId('user-1');

    await accounts.loadSelectedTag();
    await accounts.fetchAccounts();
    await accounts.initializeSelectedTag();

    expect(accounts.selectedTag).toBe('#UNVERIFIED');
    expect(await preferences.getItem('selectedTag')).toBe('#UNVERIFIED');
  });

  it('defaults to the first linked account when no selection is stored', async () => {
    const preferences = new MemoryPreferences();
    const api = new ApiClient({
      baseUrl: 'https://api.example/v2',
      environment: 'production',
      tokenProvider: { getAccessToken: async () => 'token' },
      fetchImplementation: async () =>
        new Response(
          JSON.stringify({
            items: [
              { player_tag: '#UNVERIFIED', hidden: false, is_verified: false },
              { player_tag: '#VERIFIED', hidden: false, is_verified: true },
            ],
          }),
        ),
    });
    const accounts = new CocAccountService(api, preferences);
    accounts.setCurrentUserId('user-1');

    await accounts.fetchAccounts();
    await accounts.initializeSelectedTag();

    expect(accounts.selectedTag).toBe('#UNVERIFIED');
    expect(await preferences.getItem('selectedTag')).toBe('#UNVERIFIED');
  });

  it('reports genuine account failures but not expected verification rejections', async () => {
    const reportError = jest.fn();
    const responses = [
      new Response('not-json', { status: 200 }),
      new Response('{"detail":"failed"}', { status: 500 }),
      new Response('{"detail":"invalid token"}', { status: 403 }),
    ];
    const api = new ApiClient({
      baseUrl: 'https://api.example/v2',
      environment: 'production',
      tokenProvider: { getAccessToken: async () => 'token' },
      fetchImplementation: jest.fn(async () => responses.shift()!),
    });
    const accounts = new CocAccountService(api, new MemoryPreferences(), reportError);
    accounts.setCurrentUserId('user-1');

    await expect(accounts.fetchAccounts()).rejects.toThrow();
    await expect(accounts.addAccount('#ABC')).resolves.toMatchObject({ code: 500 });
    await expect(accounts.verifyAccount('#ABC', 'invalid')).resolves.toMatchObject({
      success: false,
      message: 'Invalid API token for this account',
    });

    expect(reportError).toHaveBeenNthCalledWith(1, 'accounts.fetch', expect.any(Error));
    expect(reportError).toHaveBeenNthCalledWith(2, 'coc_account.add', expect.any(Error));
    expect(reportError).toHaveBeenCalledTimes(2);
  });

  it('reports linked-account mutation failures with Flutter operation names', async () => {
    const reportError = jest.fn();
    const api = new ApiClient({
      baseUrl: 'https://api.example/v2',
      environment: 'production',
      tokenProvider: { getAccessToken: async () => 'token' },
      fetchImplementation: jest.fn(
        async () => new Response('{"detail":"failed"}', { status: 500 }),
      ),
    });
    const accounts = new CocAccountService(api, new MemoryPreferences(), reportError);
    accounts.setCurrentUserId('user-1');

    await expect(accounts.removeAccount('#ABC')).resolves.toBe(false);
    await expect(accounts.updateAccountHidden('#ABC', true)).rejects.toThrow(
      'Failed to update account visibility',
    );
    await expect(accounts.updateAccountOrder(['#ABC'])).resolves.toBe(false);

    expect(reportError.mock.calls.map(([operation]) => operation)).toEqual([
      'accounts.remove',
      'accounts.visibility',
      'accounts.order',
    ]);
  });
});
