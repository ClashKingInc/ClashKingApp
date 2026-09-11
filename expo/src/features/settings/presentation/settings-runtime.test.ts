import { versionDeviceLabel, runningAppVersion } from './settings-runtime';

describe('versionDeviceLabel', () => {
  it('matches Flutter Android copy exactly', () => {
    expect(
      versionDeviceLabel({
        platform: 'android',
        version: '0.3.5',
        buildNumber: '25',
        modelName: 'Pixel 9',
        osVersion: '16',
        platformApiLevel: 36,
      }),
    ).toBe('Version: 0.3.5 (Build 25)\nDevice: Pixel 9, OS: Android 16 (SDK 36)');
  });

  it('matches Flutter iOS copy and prefers the machine identifier', () => {
    expect(
      versionDeviceLabel({
        platform: 'ios',
        version: '0.3.5',
        buildNumber: '25',
        modelId: 'iPhone17,2',
        modelName: 'iPhone 16 Pro Max',
        osVersion: '26.0',
      }),
    ).toBe('Version: 0.3.5 (Build 25)\nDevice: iPhone17,2, OS: iOS 26.0');
  });

  it('keeps Flutter web output', () => {
    expect(versionDeviceLabel({ platform: 'web', version: '0.3.5', buildNumber: '25' })).toBe(
      'Version: 0.3.5 (Build 25)\nUnknown Platform',
    );
  });
});

describe('runningAppVersion', () => {
  const config = { version: '0.4.2', ios: { buildNumber: '42' }, android: { versionCode: 43 } };

  it('uses the Metro config version and build during local development', () => {
    expect(
      runningAppVersion({
        platform: 'ios',
        nativeVersion: '0.3.5',
        nativeBuild: '25',
        config,
        isDevelopment: true,
        isEmbeddedLaunch: true,
      }),
    ).toEqual({ version: '0.4.2', buildNumber: '42' });
  });
  it('reports the running OTA version and platform-specific build instead of the installed binary', () => {
    expect(
      runningAppVersion({
        platform: 'android',
        nativeVersion: '0.3.5',
        nativeBuild: '25',
        config,
        isEmbeddedLaunch: false,
        manifest: { metadata: { version: '0.4.2-beta' } },
      }),
    ).toEqual({ version: '0.4.2-beta', buildNumber: '43' });
  });
  it('keeps the installed version authoritative for embedded builds', () => {
    expect(
      runningAppVersion({
        platform: 'ios',
        nativeVersion: '0.4.1',
        nativeBuild: '41',
        config,
        isEmbeddedLaunch: true,
      }),
    ).toEqual({ version: '0.4.1', buildNumber: '41' });
  });
});
