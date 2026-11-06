import { Platform, type ModalProps } from 'react-native';
import * as Device from 'expo-device';

// RN modals default to portrait independently of the presenting controller.
// Permit rotation on iPad and Duo without changing standard iPhones.
export const modalOrientations: ModalProps['supportedOrientations'] =
  Platform.OS === 'ios' &&
  (Platform.isPad ||
    Device.modelName === 'iPhone Duo' ||
    (!Device.isDevice && Device.deviceName?.startsWith('iPhone Duo')))
    ? [
        'portrait',
        'landscape-left',
        'landscape-right',
        // iPad supports inversion in its host controller; presented dialogs
        // must not rotate it back. Ordinary iPhones retain portrait-only.
        ...(Platform.isPad ? (['portrait-upside-down'] as const) : []),
      ]
    : ['portrait'];
