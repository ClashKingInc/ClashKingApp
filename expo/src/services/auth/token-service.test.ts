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

  it('clears a native session when the refresh token is rejected', async () => {
    const sessions = new AuthSessionRepository(
      new MemoryStore(),
      new MemoryStore(),
      'android',
      async () => 'device',
    );
    await sessions.write({
      accessToken: jwt(100),
      refreshToken: 'rejected-refresh',
      deviceId: null,
    });
    const service = new TokenService({
      apiV2Url: 'https://api.example/v2',
      platform: 'android',
      sessions,
      refreshLock: new NoopAuthRefreshLock(),
      deviceIdentity: {
        getDeviceId: async () => 'device',
        getDeviceName: async () => 'Pixel',
      },
      nowSeconds: () => 1_000,
      fetchImplementation: async () => new Response(null, { status: 401 }),
    });

    await expect(service.getAccessToken()).resolves.toBeNull();
    await expect(sessions.read()).resolves.toEqual({
      accessToken: null,
      refreshToken: null,
      deviceId: null,
    });
  });

  it('keeps a native session and reports the error when refresh is offline', async () => {
    const sessions = new AuthSessionRepository(
      new MemoryStore(),
      new MemoryStore(),
      'ios',
      async () => 'device',
    );
    const expiredAccessToken = jwt(100);
    await sessions.write({
      accessToken: expiredAccessToken,
      refreshToken: 'still-valid-refresh',
      deviceId: 'device',
    });
    const offline = new TypeError('Network request failed');
    const service = new TokenService({
      apiV2Url: 'https://api.example/v2',
      platform: 'ios',
      sessions,
      refreshLock: new NoopAuthRefreshLock(),
      deviceIdentity: {
        getDeviceId: async () => 'device',
        getDeviceName: async () => 'iPhone',
      },
      nowSeconds: () => 1_000,
      fetchImplementation: async () => {
        throw offline;
      },
    });

    await expect(service.getAccessToken()).rejects.toBe(offline);
    await expect(sessions.read()).resolves.toEqual({
      accessToken: expiredAccessToken,
      refreshToken: 'still-valid-refresh',
      deviceId: 'device',
    });
  });

  it('keeps a native session and identifies a refresh timeout as a network failure', async () => {
    jest.useFakeTimers();
    try {
      const sessions = new AuthSessionRepository(
        new MemoryStore(),
        new MemoryStore(),
        'android',
        async () => 'device',
      );
      const expiredAccessToken = jwt(100);
      await sessions.write({
        accessToken: expiredAccessToken,
        refreshToken: 'still-valid-refresh',
        deviceId: null,
      });
      let refreshStarted!: () => void;
      const started = new Promise<void>((resolve) => {
        refreshStarted = resolve;
      });
      const service = new TokenService({
        apiV2Url: 'https://api.example/v2',
        platform: 'android',
        sessions,
        refreshLock: new NoopAuthRefreshLock(),
        deviceIdentity: {
          getDeviceId: async () => 'device',
          getDeviceName: async () => 'Pixel',
        },
        nowSeconds: () => 1_000,
        fetchImplementation: async (_input, init) =>
          new Promise<Response>((_resolve, reject) => {
            refreshStarted();
            init?.signal?.addEventListener('abort', () => reject(init.signal?.reason), {
              once: true,
            });
          }),
      });

      const refresh = service.getAccessToken();
      await started;
      const rejection = expect(refresh).rejects.toMatchObject({ name: 'TimeoutError' });
      await jest.advanceTimersByTimeAsync(10_000);

      await rejection;
      await expect(sessions.read()).resolves.toEqual({
        accessToken: expiredAccessToken,
        refreshToken: 'still-valid-refresh',
        deviceId: null,
      });
    } finally {
      jest.useRealTimers();
    }
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

  it('does not restore a web session when refresh finishes after logout', async () => {
    const sessions = new AuthSessionRepository(
      new MemoryStore(),
      new MemoryStore(),
      'web',
      async () => 'web-device',
    );
    let releaseRefresh!: () => void;
    let refreshStarted!: () => void;
    const started = new Promise<void>((resolve) => {
      refreshStarted = resolve;
    });
    const release = new Promise<void>((resolve) => {
      releaseRefresh = resolve;
    });
    let refreshCalls = 0;
    const service = new TokenService({
      apiV2Url: 'https://api.example/v2',
      platform: 'web',
      sessions,
      refreshLock: new NoopAuthRefreshLock(),
      deviceIdentity: {
        getDeviceId: async () => 'ua',
        getDeviceName: async () => 'chrome',
      },
      fetchImplementation: async () => {
        refreshCalls += 1;
        if (refreshCalls === 1) {
          refreshStarted();
          await release;
          return new Response(JSON.stringify({ access_token: jwt(10_000) }), { status: 200 });
        }
        return new Response(null, { status: 401 });
      },
      nowSeconds: () => 1_000,
    });

    const pendingRefresh = service.getAccessToken();
    await started;
    await service.clearTokens();
    releaseRefresh();

    await expect(pendingRefresh).resolves.toBeNull();
    await expect(service.getAccessToken()).resolves.toBeNull();
    expect(refreshCalls).toBe(2);
  });
});
