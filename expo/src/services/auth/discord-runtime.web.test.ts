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

  it('reserves a popup before navigating it to Discord', async () => {
    const popup = {
      closed: false,
      close: jest.fn(),
      location: { href: 'about:blank' },
    };
    const open = jest.fn(() => popup);
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
        open,
        location: { origin: 'https://app.clashk.ing' },
        setInterval,
        setTimeout,
      },
    });
    const runtime = new PlatformDiscordOAuthRuntime();

    runtime.prepareAuthorization();
    expect(open).toHaveBeenCalledWith('', 'discordLogin', 'popup=yes,width=520,height=760');

    const authorization = runtime.authorize(
      'https://discord.com/oauth2/authorize',
      'https://app.clashk.ing/auth/discord_callback.html',
      'expected-state',
    );
    expect(popup.location.href).toBe('https://discord.com/oauth2/authorize');
    expect(open).toHaveBeenCalledTimes(1);

    onMessage?.({
      origin: 'https://app.clashk.ing',
      source: popup,
      data: { type: 'discord-auth', state: 'expected-state', code: 'authorization-code' },
    } as unknown as MessageEvent<unknown>);

    await expect(authorization).resolves.toContain('code=authorization-code');
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
