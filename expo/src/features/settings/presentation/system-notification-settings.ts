import * as Application from 'expo-application';
import { Linking, Platform } from 'react-native';

/** Open the notification panel, rather than the app's general settings page. */
export async function openSystemNotificationSettings(): Promise<void> {
  try {
    if (Platform.OS === 'ios') {
      // URL represented by UIApplication.openNotificationSettingsURLString (iOS 15.4+).
      // Use the existing URL bridge so installed builds do not need a new native module.
      await Linking.openURL('app-settings:notifications');
      return;
    }
    if (Platform.OS === 'android' && Application.applicationId) {
      await Linking.sendIntent('android.settings.APP_NOTIFICATION_SETTINGS', [
        { key: 'android.provider.extra.APP_PACKAGE', value: Application.applicationId },
      ]);
      return;
    }
  } catch {
    // Older OS versions and some Android Settings apps lack the dedicated panel.
  }
  await Linking.openSettings();
}
