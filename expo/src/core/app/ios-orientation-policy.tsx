import { useEffect, useRef } from 'react';
import { Platform } from 'react-native';
import { useHinge } from 'expo-hinge';
import * as Device from 'expo-device';
import { useVerticalBarEdgeIOS } from 'expo-status-bar';
import * as ScreenOrientation from 'expo-screen-orientation';
import { reportException } from '../observability/observability';

export function IosOrientationPolicy() {
  return Platform.OS === 'ios' ? <DeviceOrientationPolicy /> : null;
}

function DeviceOrientationPolicy() {
  const hinge = useHinge();
  const railEdge = useVerticalBarEdgeIOS();
  const hasHinge = useRef(false);
  // Hinge updates can briefly disappear when the scene changes displays.
  // Once identified, a Duo must not be relocked during that transition.
  useEffect(() => {
    if (hinge !== null || railEdge !== null) hasHinge.current = true;
    // Hinge events may arrive after the first scene. Expo's device map lets
    // a cold-launch Duo unlock before its native tab rail is constructed.
    const isKnownDuo =
      Device.modelName === 'iPhone Duo' ||
      (!Device.isDevice && Device.deviceName?.startsWith('iPhone Duo'));
    const mayRotate =
      (Platform.OS === 'ios' && Platform.isPad) ||
      isKnownDuo ||
      railEdge !== null ||
      hasHinge.current;
    const request = mayRotate
      ? ScreenOrientation.unlockAsync()
      : ScreenOrientation.lockAsync(ScreenOrientation.OrientationLock.PORTRAIT_UP);
    void request.catch((error) => reportException(error, 'orientation.apply_policy'));
  }, [hinge, railEdge]);

  return null;
}
