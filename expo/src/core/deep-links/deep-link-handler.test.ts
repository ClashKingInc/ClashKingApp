import type { DeepLinkFeedback, DeepLinkHandlerOptions, DeepLinkRuntime } from './contracts';
import {
  DeepLinkHandler,
  extractDeepLinkRoute,
  extractNormalizedDeepLinkTag,
} from './deep-link-handler';
import {
  ExpoDeepLinkRuntime,
  isClashKingDeepLink,
  startDeepLinkHandling,
} from './expo-deep-link-runtime';

function harness(overrides: Partial<DeepLinkHandlerOptions<string, string>> = {}) {
  let ready = true;
  let authenticated = true;
  const feedback = jest.fn(async (_feedback: DeepLinkFeedback) => undefined);
  const loading = jest.fn(async (_loading: boolean) => undefined);
  const openPlayer = jest.fn(async (_player: string) => undefined);
  const openClan = jest.fn(async (_clan: string) => undefined);
  const loadPlayer = jest.fn(async (tag: string) => `player:${tag}`);
  const loadClan = jest.fn(async (tag: string) => `clan:${tag}`);
  const reportError = jest.fn(async (_operation: string, _error: unknown) => undefined);
  const options: DeepLinkHandlerOptions<string, string> = {
    isReady: () => ready,
    isAuthenticated: () => authenticated,
    loadPlayer,
    loadClan,
    openPlayer,
    openClan,
    showLoading: loading,
    showFeedback: feedback,
    reportError,
    ...overrides,
  };
  const handler = new DeepLinkHandler(options);
  return {
    handler,
    feedback,
    loading,
    openPlayer,
    openClan,
    loadPlayer,
    loadClan,
    reportError,
    setReady: (value: boolean) => {
      ready = value;
    },
    setAuthenticated: (value: boolean) => {
      authenticated = value;
    },
  };
}

async function flush(): Promise<void> {
  for (let index = 0; index < 10; index += 1) await Promise.resolve();
}

describe('deep-link parsing', () => {
  test('prefers the first path segment and normalizes tag aliases', () => {
    expect(extractDeepLinkRoute(new URL('clashking://host/Player/extra'))).toBe('player');
    expect(extractDeepLinkRoute(new URL('clashking://host/Pl%61yer'))).toBe('player');
    expect(extractDeepLinkRoute(new URL('clashking://Clan?tag=abc'))).toBe('clan');
    expect(extractNormalizedDeepLinkTag(new URL('clashking://player?player_tag=%21a b'))).toBe(
      '#AB',
    );
    expect(extractNormalizedDeepLinkTag(new URL('clashking://player?tag=a%21b'))).toBe('#A#B');
    expect(extractNormalizedDeepLinkTag(new URL('clashking://clan?clan_tag='))).toBeNull();
  });

  test('the Expo runtime is deliberately unsupported on web', async () => {
    const runtime = new ExpoDeepLinkRuntime('web');
    const listener = jest.fn();
    await expect(runtime.getInitialUrl()).resolves.toBeNull();
    runtime.subscribe(listener)();
    expect(listener).not.toHaveBeenCalled();
  });

  test('the linking runtime reserves widget actions for the native widget service', () => {
    expect(isClashKingDeepLink('clashking://player?tag=abc')).toBe(true);
    expect(isClashKingDeepLink('warWidget://refreshClicked')).toBe(false);
    expect(isClashKingDeepLink('not a URL')).toBe(false);
  });
});

describe('DeepLinkHandler', () => {
  test('consumes OAuth before authentication and defers player links until authenticated', async () => {
    const h = harness();
    h.setAuthenticated(false);
    h.handler.queueDeepLink('clashking://com.clashking.clashkingapp/oauth?code=ok');
    await h.handler.tryHandlePendingDeepLink();
    expect(h.handler.pendingDeepLink).toBeNull();

    h.handler.queueDeepLink('clashking://player?tag=abc');
    await h.handler.tryHandlePendingDeepLink();
    expect(h.handler.pendingDeepLink).toBe('clashking://player?tag=abc');
    expect(h.loadPlayer).not.toHaveBeenCalled();
    h.setAuthenticated(true);
    await h.handler.tryHandlePendingDeepLink();
    expect(h.loadPlayer).toHaveBeenCalledWith('#ABC');
    expect(h.openPlayer).toHaveBeenCalledWith('player:#ABC');
    expect(h.handler.pendingDeepLink).toBeNull();
  });

  test('keeps a queued link until navigation is ready', async () => {
    const h = harness();
    h.setReady(false);
    h.handler.queueDeepLink('clashking://clan?tag=xyz');
    await h.handler.tryHandlePendingDeepLink();
    expect(h.loadClan).not.toHaveBeenCalled();
    h.setReady(true);
    await h.handler.tryHandlePendingDeepLink();
    expect(h.openClan).toHaveBeenCalledWith('clan:#XYZ');
  });

  test('preserves Flutter feedback and loading behavior for supported routes', async () => {
    const h = harness({ loadPlayer: async () => Promise.reject(new Error('offline')) });
    for (const url of [
      'clashking://player',
      'clashking://clan',
      'clashking://war',
      'clashking://other',
      'clashking://player?tag=abc',
    ]) {
      h.handler.queueDeepLink(url);
      await h.handler.tryHandlePendingDeepLink();
    }
    expect(h.feedback.mock.calls.map(([value]) => value)).toEqual([
      'invalidPlayer',
      'invalidClan',
      'comingSoon',
      'unknown',
      'failedPlayer',
    ]);
    expect(h.loading.mock.calls.map(([value]) => value)).toEqual([true, false]);
    expect(h.reportError).toHaveBeenCalledWith('deep_link.player', expect.any(Error));
  });

  test('the runtime wires running and initial links and returns its unsubscribe', async () => {
    const h = harness();
    let listener: ((url: string) => void) | undefined;
    const unsubscribe = jest.fn();
    const runtime: DeepLinkRuntime = {
      getInitialUrl: async () => 'clashking://clan?tag=initial',
      subscribe: (next) => {
        listener = next;
        return unsubscribe;
      },
    };
    const stop = await startDeepLinkHandling(runtime, h.handler);
    await flush();
    expect(h.loadClan).toHaveBeenCalledWith('#INITIAL');
    listener?.('clashking://player?tag=running');
    await flush();
    expect(h.loadPlayer).toHaveBeenCalledWith('#RUNNING');
    stop();
    expect(unsubscribe).toHaveBeenCalledTimes(1);
  });
});
