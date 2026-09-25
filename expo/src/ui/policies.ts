export type CKPlatform = 'ios' | 'android' | 'web' | 'other';
export type CKGlassMode = 'native' | 'opaque' | 'decorated';

export function durationForMotion(duration: number, reduceMotion: boolean): number {
  return reduceMotion ? 0 : duration;
}

export function resolveGlassMode({
  platform,
  nativeGlassAvailable,
  nativeGlassEnabled = true,
  reduceTransparency,
  highContrast,
}: {
  platform: CKPlatform;
  nativeGlassAvailable: boolean;
  nativeGlassEnabled?: boolean;
  reduceTransparency: boolean;
  highContrast: boolean;
}): CKGlassMode {
  if (platform === 'web' || reduceTransparency || highContrast) return 'opaque';
  // Preserve native refraction and interaction on supported iOS versions.
  if (platform === 'ios' && nativeGlassAvailable && nativeGlassEnabled) return 'native';
  return 'decorated';
}
