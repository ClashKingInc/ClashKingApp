import { versionDeviceLabel } from './settings-runtime';

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
