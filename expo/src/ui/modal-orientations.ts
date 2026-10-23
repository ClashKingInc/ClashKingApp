import { Platform, type ModalProps } from 'react-native';

// RN modals default to portrait independently of the presenting controller.
// Permit rotation on iPad without changing the portrait-only phone experience.
export const modalOrientations: ModalProps['supportedOrientations'] =
  Platform.OS === 'ios' && Platform.isPad
    ? ['portrait', 'landscape-left', 'landscape-right']
    : ['portrait'];
