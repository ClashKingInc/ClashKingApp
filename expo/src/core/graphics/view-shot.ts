import type * as ViewShot from 'react-native-view-shot';

// Resolve the native capture module only when a caller takes a screenshot.
function loadViewShot(): typeof ViewShot {
  // eslint-disable-next-line @typescript-eslint/no-require-imports -- Keep the first capture synchronous up to the native call.
  return require('react-native-view-shot');
}

export const captureRef: typeof ViewShot.captureRef = (...args) =>
  loadViewShot().captureRef(...args);

export const releaseCapture: typeof ViewShot.releaseCapture = (uri) =>
  loadViewShot().releaseCapture(uri);
