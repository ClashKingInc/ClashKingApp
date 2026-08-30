import * as WebBrowser from 'expo-web-browser';

import { PlatformDiscordOAuthRuntime } from './discord-runtime';

jest.mock('expo-web-browser', () => ({
  openAuthSessionAsync: jest.fn(),
}));

const openAuthSessionAsync = jest.mocked(WebBrowser.openAuthSessionAsync);
const authorizationUrl = 'https://discord.com/api/oauth2/authorize?client_id=123';
const redirectUri = 'clashking://com.clashking.clashkingapp/oauth';

describe('native Discord OAuth runtime', () => {
  beforeEach(() => openAuthSessionAsync.mockReset());

  it('uses the native authentication session and returns its ClashKing callback', async () => {
    const callback = `${redirectUri}?code=abc&state=expected`;
    openAuthSessionAsync.mockResolvedValue({ type: 'success', url: callback } as never);

    await expect(
      new PlatformDiscordOAuthRuntime().authorize(authorizationUrl, redirectUri, 'expected'),
    ).resolves.toBe(callback);
    expect(openAuthSessionAsync).toHaveBeenCalledWith(authorizationUrl, redirectUri, {
      preferEphemeralSession: false,
    });
  });

  it('returns null when the user dismisses the authentication session', async () => {
    openAuthSessionAsync.mockResolvedValue({ type: 'cancel' } as never);

    await expect(
      new PlatformDiscordOAuthRuntime().authorize(authorizationUrl, redirectUri, 'expected'),
    ).resolves.toBeNull();
  });
});
