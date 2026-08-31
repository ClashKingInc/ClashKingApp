export type CKPlatform = 'ios' | 'android' | 'web' | 'other';
export type CKGlassMode = 'native' | 'opaque' | 'decorated';

export function durationForMotion(duration: number, reduceMotion: boolean): number {
  return reduceMotion ? 0 : duration;
}

export function resolveGlassMode({
  platform,
  nativeGlassAvailable,
  reduceTransparency,
  highContrast,
}: {
  platform: CKPlatform;
  nativeGlassAvailable: boolean;
  reduceTransparency: boolean;
  highContrast: boolean;
}): CKGlassMode {
  if (platform === 'web' || reduceTransparency || highContrast) return 'opaque';
  if (platform === 'ios' && nativeGlassAvailable) return 'native';
  return 'decorated';
}
