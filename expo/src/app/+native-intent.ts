import { isDiscordNativeCallbackUrl } from '../services/auth/discord-callback';

interface NativeIntentOptions {
  readonly path: string;
  readonly initial: boolean;
}

export function redirectSystemPath({ path }: NativeIntentOptions): string {
  return isDiscordNativeCallbackUrl(path) ? '/' : path;
}
