import * as Crypto from 'expo-crypto';

import { DISCORD_NATIVE_REDIRECT_URI } from './discord-callback';

export const DISCORD_CLIENT_ID = '824653933347209227';
export { DISCORD_NATIVE_REDIRECT_URI } from './discord-callback';

const STATE_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
const VERIFIER_CHARACTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

export interface DiscordAuthorizationResult {
  readonly code: string;
  readonly codeVerifier: string;
  readonly redirectUri: string;
}

export interface DiscordOAuthRuntime {
  prepareAuthorization?(): void;
  cancelPreparedAuthorization?(): void;
  authorize(
    authorizationUrl: string,
    redirectUri: string,
    expectedState: string,
  ): Promise<string | null>;
}

export interface DiscordOAuthOptions {
  readonly platform: 'web' | 'native';
  readonly runtime: DiscordOAuthRuntime;
  readonly webOrigin?: string;
  readonly webHost?: string;
  readonly webRedirectOverride?: string;
}

export class DiscordOAuthClient {
  constructor(private readonly options: DiscordOAuthOptions) {}

  async authorize(): Promise<DiscordAuthorizationResult | null> {
    this.options.runtime.prepareAuthorization?.();
    let authorizationStarted = false;
    try {
      const state = await randomString(64, STATE_CHARACTERS);
      const codeVerifier = await randomString(128, VERIFIER_CHARACTERS);
      const codeChallenge = await Crypto.digestStringAsync(
        Crypto.CryptoDigestAlgorithm.SHA256,
        codeVerifier,
        { encoding: Crypto.CryptoEncoding.BASE64 },
      );
      const redirectUri = resolveDiscordRedirectUri(this.options);
      const authorizationUrl = buildDiscordAuthorizationUrl(
        redirectUri,
        state,
        codeChallenge.replaceAll('=', '').replaceAll('+', '-').replaceAll('/', '_'),
      );
      authorizationStarted = true;
      const callback = await withTimeout(
        this.options.runtime.authorize(authorizationUrl, redirectUri, state),
        120_000,
      );
      if (callback === null) return null;

      const result = new URL(callback);
      if (result.searchParams.get('state') !== state) {
        throw new Error('Discord OAuth state did not match this login.');
      }
      const error = result.searchParams.get('error');
      if (error === 'access_denied') return null;
      if (error !== null) {
        throw new Error(result.searchParams.get('error_description') ?? error);
      }
      const code = result.searchParams.get('code');
      return code === null || code.length === 0 ? null : { code, codeVerifier, redirectUri };
    } catch (error) {
      if (!authorizationStarted) this.options.runtime.cancelPreparedAuthorization?.();
      throw error;
    }
  }
}

export function resolveDiscordRedirectUri(
  options: Pick<DiscordOAuthOptions, 'platform' | 'webOrigin' | 'webHost' | 'webRedirectOverride'>,
): string {
  if (options.platform === 'native') return DISCORD_NATIVE_REDIRECT_URI;
  if (options.webOrigin === undefined || options.webHost === undefined) {
    throw new Error('The web origin and host are required for Discord OAuth.');
  }
  if (options.webHost === 'localhost' || options.webHost === '127.0.0.1') {
    return `${options.webOrigin}/auth/callback`;
  }
  if ((options.webRedirectOverride ?? '').length > 0) {
    return options.webRedirectOverride!;
  }
  return `${options.webOrigin}/auth/discord_callback.html`;
}

export function buildDiscordAuthorizationUrl(
  redirectUri: string,
  state: string,
  codeChallenge: string,
): string {
  const url = new URL('https://discord.com/api/oauth2/authorize');
  url.searchParams.set('response_type', 'code');
  url.searchParams.set('client_id', DISCORD_CLIENT_ID);
  url.searchParams.set('scope', 'identify');
  url.searchParams.set('redirect_uri', redirectUri);
  url.searchParams.set('code_challenge', codeChallenge);
  url.searchParams.set('code_challenge_method', 'S256');
  url.searchParams.set('state', state);
  return url.toString();
}

async function randomString(length: number, characters: string): Promise<string> {
  const bytes = await Crypto.getRandomBytesAsync(length);
  return Array.from(bytes, (value) => characters[value % characters.length]!).join('');
}

async function withTimeout<T>(promise: Promise<T>, milliseconds: number): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timer = setTimeout(() => reject(new Error('Discord OAuth timed out.')), milliseconds);
  });
  try {
    return await Promise.race([promise, timeout]);
  } finally {
    if (timer !== undefined) clearTimeout(timer);
  }
}
