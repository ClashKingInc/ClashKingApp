const PRODUCTION_ASSET_ORIGIN = 'https://assets.clashk.ing';
// Preview data must never leak into exported production builds.
export const ASSET_ORIGIN = (__DEV__ && process.env.EXPO_PUBLIC_CK_ASSET_ORIGIN
  ? process.env.EXPO_PUBLIC_CK_ASSET_ORIGIN : PRODUCTION_ASSET_ORIGIN).replace(/\/$/, '');

/** API responses can retain canonical CDN URLs; route those through the preview too. */
export function resolveAssetUrl(url: string): string {
  return url.startsWith(PRODUCTION_ASSET_ORIGIN + '/')
    ? ASSET_ORIGIN + url.slice(PRODUCTION_ASSET_ORIGIN.length) : url;
}

export function assetPath(url: string): string {
  const resolved = resolveAssetUrl(url);
  return decodeURIComponent(resolved.slice(ASSET_ORIGIN.length + 1).split(/[?#]/)[0] ?? '');
}
