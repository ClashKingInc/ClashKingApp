import nativeContract from '../../../../native/parity-contract.json';
import {
  APP_ICON_OPTIONS,
  AppIconService,
  UnsupportedAppIconPlatformError,
} from './app-icon-service';

function nativeBridge() {
  return {
    supportsAlternateIcons: jest.fn(async () => true),
    getAlternateIconName: jest.fn(async () => 'AppIconChristmas' as string | null),
    setAlternateIconName: jest.fn(async (_name: string | null) => undefined),
  };
}

describe('AppIconService', () => {
  test('matches the exact retained Flutter option manifest', () => {
    expect(APP_ICON_OPTIONS).toEqual(nativeContract.alternateIconOptions);
  });

  test('uses the native bridge only on iOS', async () => {
    const native = nativeBridge();
    const ios = new AppIconService('ios', native);
    await expect(ios.supportsAlternateIcons()).resolves.toBe(true);
    await expect(ios.getAlternateIconName()).resolves.toBe('AppIconChristmas');
    await ios.setAlternateIconName(null);
    expect(native.setAlternateIconName).toHaveBeenCalledWith(null);

    const android = new AppIconService('android', native);
    await expect(android.supportsAlternateIcons()).resolves.toBe(false);
    await expect(android.getAlternateIconName()).resolves.toBeNull();
    await expect(android.setAlternateIconName('AppIconChristmas')).rejects.toMatchObject({
      code: 'unsupported',
    });
    expect(native.setAlternateIconName).toHaveBeenCalledTimes(1);
  });

  test('falls back to the default option for null and unknown native names', () => {
    const service = new AppIconService('ios', nativeBridge());
    expect(service.optionForName(null)).toEqual(APP_ICON_OPTIONS[0]);
    expect(service.optionForName('UnknownIcon')).toEqual(APP_ICON_OPTIONS[0]);
    expect(service.optionForName('AppIconDarkLogo')).toEqual(APP_ICON_OPTIONS[3]);
  });

  test('reports a missing bridge as unavailable without inventing platform support', async () => {
    const service = new AppIconService('ios', undefined);
    await expect(service.supportsAlternateIcons()).resolves.toBe(false);
    await expect(service.getAlternateIconName()).resolves.toBeNull();
    await expect(service.setAlternateIconName(null)).rejects.toThrow(
      'ClashKing native app-icon bridge is unavailable.',
    );
    expect(new UnsupportedAppIconPlatformError().code).toBe('unsupported');
  });
});
