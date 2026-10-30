import * as Device from 'expo-device';
import { useContext } from 'react';
import { Platform, useWindowDimensions } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { AdaptiveViewportContext } from './adaptive-viewport';

/** Identity and width are separate: large Android/regular iPhone windows must
 * retain their existing behavior, rather than entering the tablet redesign. */
export const isDuoDevice =
  Platform.OS === 'ios' &&
  (Device.modelName === 'iPhone Duo' ||
    (!Device.isDevice && !!Device.deviceName?.startsWith('iPhone Duo')));

export const isAdaptiveIOSDevice =
  Platform.OS === 'ios' && (Platform.isPad === true || isDuoDevice);

export function useAdaptiveLayout() {
  const { width: windowWidth, height: windowHeight, fontScale } = useWindowDimensions();
  const viewport = useContext(AdaptiveViewportContext);
  const width = viewport?.width ?? windowWidth;
  const height = viewport?.height ?? windowHeight;
  const insets = useSafeAreaInsets();
  const usableWidth = Math.max(0, width - insets.left - insets.right);
  const isDuo = isDuoDevice;
  const isTablet = Platform.OS === 'ios' && Platform.isPad === true && !isDuo;
  // Duo portrait deliberately follows the phone presentation, including on
  // the inner display. Narrow iPad multitasking windows also collapse safely.
  const mode =
    usableWidth >= 640 && (isTablet || (isDuo && windowWidth > windowHeight))
      ? isTablet
        ? 'tablet'
        : 'duo'
      : 'compact';
  const isExpanded = mode !== 'compact';
  const contentMaxWidth = isExpanded ? (isTablet ? 1280 : 1120) : usableWidth;
  const readableMaxWidth = isExpanded ? (isTablet ? 760 : 720) : contentMaxWidth;
  const columns = (minimum: number, maximum = isTablet ? 4 : 2) => {
    if (!isExpanded) return 1;
    const available = Math.min(usableWidth - 32, contentMaxWidth);
    const count = Math.max(
      1,
      Math.min(maximum, Math.floor((available + 12) / (minimum * Math.max(1, fontScale) + 12))),
    );
    // Even columns keep the fold between cards on the Duo's inner display.
    return isDuo && count > 2 && count % 2 === 1 ? count - 1 : count;
  };
  return {
    mode,
    isExpanded,
    isTablet,
    isDuo,
    width,
    height,
    usableWidth,
    contentMaxWidth,
    readableMaxWidth,
    columns,
  } as const;
}
