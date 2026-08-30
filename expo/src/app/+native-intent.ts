import { isDiscordNativeCallbackUrl } from '../services/auth/discord-callback';
import { extractDeepLinkRoute } from '../core/deep-links/deep-link-handler';

interface NativeIntentOptions {
  readonly path: string;
  readonly initial: boolean;
}

export function redirectSystemPath({ path }: NativeIntentOptions): string {
  return isDiscordNativeCallbackUrl(path) || isSupportedNativeAppLink(path) ? '/' : path;
}

function isSupportedNativeAppLink(path: string): boolean {
  try {
    const url = new URL(path);
    if (url.protocol.toLowerCase() !== 'clashking:') return false;
    const route = extractDeepLinkRoute(url);
    return route === 'player' || route === 'clan';
  } catch {
    return false;
  }
}
