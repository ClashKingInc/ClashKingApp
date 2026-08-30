import { PlatformDiscordOAuthRuntime } from './discord-runtime.web';

describe('web Discord OAuth runtime', () => {
  const originalWindow = globalThis.window;

  afterEach(() => {
    jest.useRealTimers();
    Object.defineProperty(globalThis, 'window', {
      configurable: true,
      value: originalWindow,
    });
  });

  it('closes the popup and listener when the Flutter-equivalent timeout expires', async () => {
    jest.useFakeTimers();
    const popup = { closed: false, close: jest.fn() };
    const removeEventListener = jest.fn();
    Object.defineProperty(globalThis, 'window', {
      configurable: true,
      value: {
        addEventListener: jest.fn(),
        removeEventListener,
        open: jest.fn(() => popup),
        location: { origin: 'https://app.clashk.ing' },
        setInterval,
        setTimeout,
      },
    });

    const authorization = new PlatformDiscordOAuthRuntime().authorize(
      'https://discord.com/oauth2/authorize',
      'https://app.clashk.ing/auth/discord_callback.html',
      'expected-state',
    );
    const rejection = expect(authorization).rejects.toThrow('Discord OAuth timed out.');

    await jest.advanceTimersByTimeAsync(120_000);
    await rejection;
    expect(removeEventListener).toHaveBeenCalledWith('message', expect.any(Function));
    expect(popup.close).toHaveBeenCalledTimes(1);
  });
});
