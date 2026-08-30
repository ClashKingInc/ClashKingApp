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

  it.each([null, undefined])('treats a %s OAuth error value as absent', async (errorValue) => {
    const popup = { closed: false, close: jest.fn() };
    let onMessage: ((event: MessageEvent<unknown>) => void) | undefined;
    Object.defineProperty(globalThis, 'window', {
      configurable: true,
      value: {
        addEventListener: jest.fn(
          (type: string, listener: (event: MessageEvent<unknown>) => void) => {
            if (type === 'message') onMessage = listener;
          },
        ),
        removeEventListener: jest.fn(),
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
    onMessage?.({
      origin: 'https://app.clashk.ing',
      source: popup,
      data: {
        type: 'discord-auth',
        state: 'expected-state',
        code: 'authorization-code',
        error: errorValue,
      },
    } as unknown as MessageEvent<unknown>);

    const callback = new URL((await authorization) ?? '');
    expect(callback.searchParams.get('code')).toBe('authorization-code');
    expect(callback.searchParams.has('error')).toBe(false);
  });
});
