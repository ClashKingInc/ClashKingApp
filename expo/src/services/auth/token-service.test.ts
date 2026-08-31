import { AuthSessionRepository, type StringStore } from '../storage/auth-storage';
import { NoopAuthRefreshLock } from './refresh-lock';
import { TokenService } from './token-service';

class MemoryStore implements StringStore {
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
}

function jwt(exp: number): string {
  const payload = btoa(JSON.stringify({ exp }))
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
  return `header.${payload}.signature`;
}

describe('TokenService', () => {
  it('deduplicates refresh and atomically rotates both native tokens', async () => {
    const secure = new MemoryStore();
    const sessions = new AuthSessionRepository(
      secure,
      new MemoryStore(),
      'android',
      async () => 'device',
    );
    await sessions.write({
      accessToken: jwt(100),
      refreshToken: 'old-refresh',
      deviceId: null,
    });
    let calls = 0;
    let lockRuns = 0;
    const service = new TokenService({
      apiV2Url: 'https://api.example/v2',
      platform: 'android',
      sessions,
      refreshLock: {
        run: async (operation) => {
          lockRuns += 1;
          return operation();
        },
      },
      deviceIdentity: {
        getDeviceId: async () => 'device',
        getDeviceName: async () => 'Pixel',
      },
      nowSeconds: () => 1_000,
      fetchImplementation: async (_input, init) => {
        calls += 1;
        expect(JSON.parse(String(init?.body))).toEqual({
          refresh_token: 'old-refresh',
          device_id: 'device',
        });
        return new Response(
          JSON.stringify({
            access_token: jwt(10_000),
            refresh_token: 'new-refresh',
          }),
          { status: 200 },
        );
      },
    });

    const [first, second] = await Promise.all([service.getAccessToken(), service.getAccessToken()]);
    expect(first).toBe(second);
    expect(calls).toBe(1);
    expect(lockRuns).toBe(1);
    await expect(sessions.read()).resolves.toMatchObject({
      refreshToken: 'new-refresh',
    });
  });

  it('uses the web refresh cookie and never persists its access token', async () => {
    const secure = new MemoryStore();
    const preferences = new MemoryStore();
    const sessions = new AuthSessionRepository(
      secure,
      preferences,
      'web',
      async () => 'web-device',
    );
    let credentials: RequestCredentials | undefined;
    const service = new TokenService({
      apiV2Url: 'https://api.example/v2',
      platform: 'web',
      sessions,
      refreshLock: new NoopAuthRefreshLock(),
      deviceIdentity: {
        getDeviceId: async () => 'ua',
        getDeviceName: async () => 'chrome',
      },
      fetchImplementation: async (_input, init) => {
        credentials = init?.credentials;
        return new Response(JSON.stringify({ access_token: jwt(10_000) }), { status: 200 });
      },
      nowSeconds: () => 1_000,
    });
    await expect(service.getAccessToken()).resolves.toBeTruthy();
    expect(credentials).toBe('include');
    expect(secure.values.size).toBe(0);
    expect(preferences.values.size).toBe(0);
  });
});
