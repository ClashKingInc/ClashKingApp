import { redirectSystemPath } from '../../app/+native-intent';
import {
  extractDeepLinkRoute,
  extractNormalizedDeepLinkTag,
} from '../../core/deep-links/deep-link-handler';
import { DISCORD_NATIVE_REDIRECT_URI, isDiscordNativeCallbackUrl } from './discord-callback';

describe('native intent routing', () => {
  it('keeps the registered Discord callback out of the Expo Router route tree', () => {
    const callback = `${DISCORD_NATIVE_REDIRECT_URI}?code=code&state=state`;

    expect(isDiscordNativeCallbackUrl(callback)).toBe(true);
    expect(redirectSystemPath({ path: callback, initial: false })).toBe('/');
  });

  it.each([
    ['player', 'clashking://player?tag=%232J8V28GV0', '#2J8V28GV0'],
    ['clan', 'clashking://clan?tag=%232VC0Q9LV', '#2VC0Q9LV'],
    ['war', 'clashking://war?tag=%232J8V28GV0', '#2J8V28GV0'],
  ])(
    'mounts the app root for a supported %s link while preserving its handler URL',
    (route, appLink, tag) => {
      expect(redirectSystemPath({ path: appLink, initial: false })).toBe('/');

      const originalUrl = new URL(appLink);
      expect(extractDeepLinkRoute(originalUrl)).toBe(route);
      expect(extractNormalizedDeepLinkTag(originalUrl)).toBe(tag);
    },
  );

  it('leaves unrelated and malformed incoming links unchanged', () => {
    const appLink = 'clashking://settings';

    expect(isDiscordNativeCallbackUrl(appLink)).toBe(false);
    expect(redirectSystemPath({ path: appLink, initial: false })).toBe(appLink);
    expect(redirectSystemPath({ path: 'not a url', initial: false })).toBe('not a url');
    expect(isDiscordNativeCallbackUrl('not a url')).toBe(false);
  });
});
