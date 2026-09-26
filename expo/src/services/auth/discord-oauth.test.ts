import * as Crypto from 'expo-crypto';

import { DiscordOAuthClient, type DiscordOAuthRuntime } from './discord-oauth';

jest.mock('expo-crypto', () => ({
  CryptoDigestAlgorithm: { SHA256: 'SHA-256' },
  CryptoEncoding: { BASE64: 'base64' },
  getRandomBytesAsync: jest.fn(async (length: number) => new Uint8Array(length).fill(1)),
  digestStringAsync: jest.fn(async () => 'challenge'),
}));

describe('Discord OAuth client', () => {
  it('reserves the web popup before awaiting PKCE generation', async () => {
    const prepareAuthorization = jest.fn();
    const authorize = jest.fn(async (authorizationUrl: string) => {
      const state = new URL(authorizationUrl).searchParams.get('state');
      return `https://app.clashk.ing/auth/callback?code=authorization-code&state=${state}`;
    });
    const runtime: DiscordOAuthRuntime = { prepareAuthorization, authorize };
    const client = new DiscordOAuthClient({
      platform: 'web',
      runtime,
      webOrigin: 'https://app.clashk.ing',
      webHost: 'app.clashk.ing',
    });

    const result = client.authorize();

    expect(prepareAuthorization).toHaveBeenCalledTimes(1);
    expect(prepareAuthorization.mock.invocationCallOrder[0]).toBeLessThan(
      jest.mocked(Crypto.getRandomBytesAsync).mock.invocationCallOrder[0]!,
    );
    await expect(result).resolves.toEqual(
      expect.objectContaining({
        code: 'authorization-code',
        redirectUri: 'https://app.clashk.ing/auth/discord_callback.html',
      }),
    );
  });

  it('uses the explicit local Discord application without changing the production default', async () => {
    const authorize = jest.fn(async (authorizationUrl: string) => {
      const url = new URL(authorizationUrl);
      return `clashking://com.clashking.clashkingapp/oauth?code=code&state=${url.searchParams.get('state')}`;
    });
    const client = new DiscordOAuthClient({
      platform: 'native',
      runtime: { authorize },
      clientId: '123456789',
    });

    await expect(client.authorize()).resolves.toEqual(expect.objectContaining({ code: 'code' }));
    expect(new URL(authorize.mock.calls[0]![0]).searchParams.get('client_id')).toBe('123456789');
  });
});
