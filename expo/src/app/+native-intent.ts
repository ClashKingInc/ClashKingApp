import { isDiscordNativeCallbackUrl } from '../services/auth/discord-callback';
import { parseAppLink } from '../core/deep-links/app-link';

interface NativeIntentOptions {
  readonly path: string;
  readonly initial: boolean;
}

export function redirectSystemPath({ path }: NativeIntentOptions): string {
  return isDiscordNativeCallbackUrl(path) || isSupportedNativeAppLink(path) ? '/' : path;
}

function isSupportedNativeAppLink(path: string): boolean {
  return parseAppLink(path) !== null;
}
