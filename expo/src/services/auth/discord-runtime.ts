import * as WebBrowser from 'expo-web-browser';

import { isDiscordNativeCallbackUrl } from './discord-callback';
import type { DiscordOAuthRuntime } from './discord-oauth';

export class PlatformDiscordOAuthRuntime implements DiscordOAuthRuntime {
  async authorize(
    authorizationUrl: string,
    redirectUri: string,
    _expectedState: string,
  ): Promise<string | null> {
    const result = await WebBrowser.openAuthSessionAsync(authorizationUrl, redirectUri, {
      preferEphemeralSession: false,
    });
    return result.type === 'success' && isDiscordNativeCallbackUrl(result.url) ? result.url : null;
  }
}
