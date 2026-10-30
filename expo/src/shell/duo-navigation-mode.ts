import { useWindowDimensions } from 'react-native';
import { isDuoDevice } from '../ui/adaptive-layout';

/** The open portrait display uses the ordinary bottom bar. Keep the native
 * navigator mounted across rotations, and let the system rail remain on the
 * cover display and in landscape. Use window geometry rather than the status
 * bar edge (which remains vertical even when we request horizontal bars) or
 * hinge events (which can be absent during display transitions). The 600-point
 * breakpoint distinguishes the roomy inner portrait window from the cover. */
export function useDuoPortraitBottomBar() {
  const { width, height } = useWindowDimensions();
  return isDuoDevice && height > width && width >= 600;
}
