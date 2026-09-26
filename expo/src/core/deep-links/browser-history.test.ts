import { Platform } from 'react-native';
import { recordBrowserPath } from './browser-history';
import { ExpoDeepLinkRuntime } from './expo-deep-link-runtime';

test('web startup and back navigation deliver the full destination and detach cleanly', async () => {
  const original = Object.getOwnPropertyDescriptor(window, 'location');
  const add = window.addEventListener;
  const remove = window.removeEventListener;
  const handlers = new Map<string, EventListenerOrEventListenerObject>();
  Object.defineProperty(window, 'location', {
    configurable: true,
    value: { pathname: '/player/ABC', search: '?tab=battles' },
  });
  window.addEventListener = jest.fn((event, listener) => {
    handlers.set(event, listener);
  });
  window.removeEventListener = jest.fn((event) => {
    handlers.delete(event);
  });
  try {
    const runtime = new ExpoDeepLinkRuntime('web');
    expect(await runtime.getInitialUrl()).toBe('https://app.clashk.ing/player/ABC?tab=battles');
    const listener = jest.fn();
    const stop = runtime.subscribe(listener);
    (handlers.get('popstate') as () => void)();
    expect(listener).toHaveBeenCalledWith('https://app.clashk.ing/player/ABC?tab=battles');
    stop();
    expect(handlers.has('popstate')).toBe(false);
  } finally {
    if (original) Object.defineProperty(window, 'location', original);
    else Reflect.deleteProperty(window, 'location');
    window.addEventListener = add;
    window.removeEventListener = remove;
  }
});

test('native navigation does not manipulate browser history', () => {
  const original = Platform.OS;
  Platform.OS = 'ios';
  try {
    expect(() => recordBrowserPath('/settings')).not.toThrow();
  } finally {
    Platform.OS = original;
  }
});
