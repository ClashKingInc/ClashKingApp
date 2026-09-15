import * as Linking from 'expo-linking';
import { Platform } from 'react-native';
import type { DeepLinkHandler } from './deep-link-handler';
import type { DeepLinkRuntime } from './contracts';
import { parseAppLink } from './app-link';

export class ExpoDeepLinkRuntime implements DeepLinkRuntime {
  constructor(
    private readonly platform: 'ios' | 'android' | 'web' = Platform.OS === 'ios' ||
    Platform.OS === 'android'
      ? Platform.OS
      : 'web',
  ) {}

  async getInitialUrl(): Promise<string | null> {
    if (this.platform === 'web')
      return typeof window === 'undefined' || !window.location
        ? null
        : new URL(window.location.pathname + window.location.search, 'https://app.clashk.ing').href;
    const url = await Linking.getInitialURL();
    return url !== null && isClashKingDeepLink(url) ? url : null;
  }

  subscribe(listener: (url: string) => void): () => void {
    if (this.platform === 'web') {
      if (typeof window === 'undefined' || !window.addEventListener) return () => undefined;
      const onPop = () =>
        listener(
          new URL(window.location.pathname + window.location.search, 'https://app.clashk.ing').href,
        );
      window.addEventListener('popstate', onPop);
      return () => window.removeEventListener('popstate', onPop);
    }
    const subscription = Linking.addEventListener('url', ({ url }) => {
      if (isClashKingDeepLink(url)) listener(url);
    });
    return () => subscription.remove();
  }
}

export function isClashKingDeepLink(url: string): boolean {
  return parseAppLink(url) !== null;
}

export async function startDeepLinkHandling<Player, Clan>(
  runtime: DeepLinkRuntime,
  handler: DeepLinkHandler<Player, Clan>,
  reportError?: (operation: string, error: unknown) => void | Promise<void>,
): Promise<() => void> {
  const safelyReport = async (operation: string, error: unknown) => {
    try {
      await reportError?.(operation, error);
    } catch {
      // Observability cannot change listener lifetime or queue behavior.
    }
  };
  const handle = (url: string, operation: string) => {
    handler.queueDeepLink(url);
    void handler.tryHandlePendingDeepLink().catch((error) => safelyReport(operation, error));
  };
  const unsubscribe = runtime.subscribe((url) => handle(url, 'deep_link.running'));
  try {
    const initial = await runtime.getInitialUrl();
    if (initial !== null) handle(initial, 'deep_link.initial');
  } catch (error) {
    await safelyReport('deep_link.initial', error);
  }
  return unsubscribe;
}
