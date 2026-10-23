import { isDiscordNativeCallbackUrl } from '../services/auth/discord-callback';
import { parseAppLink } from '../core/deep-links/app-link';

interface NativeIntentOptions {
  readonly path: string;
  readonly initial: boolean;
}

export function redirectSystemPath({ path, initial }: NativeIntentOptions): string {
  if (isDiscordNativeCallbackUrl(path)) return '/';
  // RootLayout already delivers public URLs to the app-link handler.
  // A warm '/' redirect would push another index route in Expo Router 58,
  // mounting a second app root that competes for the same destination layer.
  // Empty warm redirects suppress only that duplicate router navigation;
  // cold launches still need the index route before the inbox is consumed.
  return isSupportedNativeAppLink(path)
    ? initial
      ? '/'
      : ''
    : path;
}

function isSupportedNativeAppLink(path: string): boolean {
  return parseAppLink(path) !== null;
}
