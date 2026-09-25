import { Linking, Platform } from 'react-native';

import { openSystemNotificationSettings } from './system-notification-settings';

jest.mock('expo-application', () => ({ applicationId: 'com.clashking.apps' }));

beforeEach(() => jest.clearAllMocks());
afterEach(() => jest.restoreAllMocks());

it('opens the notification subpage directly on iOS', async () => {
  jest.replaceProperty(Platform, 'OS', 'ios');
  const openURL = jest.spyOn(Linking, 'openURL').mockResolvedValue(undefined);
  const openSettings = jest.spyOn(Linking, 'openSettings').mockResolvedValue(undefined);
  await openSystemNotificationSettings();
  expect(openURL).toHaveBeenCalledWith('app-settings:notifications');
  expect(openSettings).not.toHaveBeenCalled();
});

it('targets the installed application notification panel on Android', async () => {
  jest.replaceProperty(Platform, 'OS', 'android');
  const sendIntent = jest.spyOn(Linking, 'sendIntent').mockResolvedValue(undefined);
  const openSettings = jest.spyOn(Linking, 'openSettings').mockResolvedValue(undefined);
  await openSystemNotificationSettings();
  expect(sendIntent).toHaveBeenCalledWith('android.settings.APP_NOTIFICATION_SETTINGS', [
    { key: 'android.provider.extra.APP_PACKAGE', value: 'com.clashking.apps' },
  ]);
  expect(openSettings).not.toHaveBeenCalled();
});

it.each(['ios', 'android'] as const)(
  'falls back to general app settings only if the dedicated %s panel fails',
  async (platform) => {
    jest.replaceProperty(Platform, 'OS', platform);
    jest.spyOn(Linking, 'openURL').mockRejectedValue(new Error('Unsupported URL'));
    jest.spyOn(Linking, 'sendIntent').mockRejectedValue(new Error('Unsupported activity'));
    const openSettings = jest.spyOn(Linking, 'openSettings').mockResolvedValue(undefined);
    await openSystemNotificationSettings();
    expect(openSettings).toHaveBeenCalledTimes(1);
  },
);

it('propagates failure when neither settings destination opens', async () => {
  jest.replaceProperty(Platform, 'OS', 'ios');
  jest.spyOn(Linking, 'openURL').mockRejectedValue(new Error('Unsupported URL'));
  jest.spyOn(Linking, 'openSettings').mockRejectedValue(new Error('Settings unavailable'));
  await expect(openSystemNotificationSettings()).rejects.toThrow('Settings unavailable');
});
