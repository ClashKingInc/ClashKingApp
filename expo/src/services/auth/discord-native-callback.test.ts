import { redirectSystemPath } from '../../app/+native-intent';
import { DISCORD_NATIVE_REDIRECT_URI, isDiscordNativeCallbackUrl } from './discord-callback';

describe('native Discord callback routing', () => {
  it('keeps the registered Discord callback out of the Expo Router route tree', () => {
    const callback = `${DISCORD_NATIVE_REDIRECT_URI}?code=code&state=state`;

    expect(isDiscordNativeCallbackUrl(callback)).toBe(true);
    expect(redirectSystemPath({ path: callback, initial: false })).toBe('/');
  });

  it('leaves unrelated and malformed incoming links unchanged', () => {
    const appLink = 'clashking://player/%232J8V28GV0';

    expect(isDiscordNativeCallbackUrl(appLink)).toBe(false);
    expect(redirectSystemPath({ path: appLink, initial: false })).toBe(appLink);
    expect(isDiscordNativeCallbackUrl('not a url')).toBe(false);
  });
});
