import { ASSET_ORIGIN, assetPath, resolveAssetUrl } from '../core/assets/asset-origin';
import { manifestImage } from '../core/assets/asset-manifest';
import type { ImageRequest } from '../core/assets/managed-image-cache';

export const ASSET_IMAGE_SIZES = [64, 128, 256, 512, 1024] as const;

export function requiredPixels(width: number, height: number, scale: number): number | undefined {
  if (![width, height, scale].every((value) => Number.isFinite(value) && value > 0))
    return undefined;
  return Math.ceil(Math.max(width, height) * scale);
}

/** Only first-party raster images opt in. The caller retains the original fallback. */
export function sizedAssetUrl(
  url: string,
  width: number,
  height: number,
  scale: number,
  preserveAnimation = false,
): string {
  url = resolveAssetUrl(url);
  if (!url.startsWith(`${ASSET_ORIGIN}/`)) return url;
  // The local file server serves originals; CDN-only image transforms are unavailable.
  if (__DEV__ && process.env.EXPO_PUBLIC_CK_ASSET_ORIGIN) return url;
  const value = new URL(url);
  if (!/\.(png|webp|jpe?g|avif)$/i.test(value.pathname)) return url;
  const metadata = manifestImage(url);
  // PNG, WebP and AVIF can contain animation. Until the manifest identifies a
  // static source, use the original rather than probing a potentially animated file.
  if (preserveAnimation || metadata?.animated || (!metadata && !/\.jpe?g$/i.test(value.pathname)))
    return url;
  const pixels = requiredPixels(width, height, scale);
  const size =
    pixels === undefined ? undefined : ASSET_IMAGE_SIZES.find((bound) => bound >= pixels);
  value.pathname = value.pathname.replace(/\.(png|webp|jpe?g|avif)$/i, '.avif');
  value.search = '';
  // Unknown dimensions and displays larger than our biggest variant retain full resolution.
  if (size !== undefined) value.searchParams.set('size', String(size));
  return value.toString();
}

/** Use the original manifest identity for CDN variants, and a fallback's own identity otherwise. */
export function managedAssetRequest(
  original: string,
  candidate: string,
  preserveAnimation = false,
): ImageRequest | undefined {
  if (
    preserveAnimation ||
    !candidate.startsWith(ASSET_ORIGIN + '/') ||
    (__DEV__ && process.env.EXPO_PUBLIC_CK_ASSET_ORIGIN)
  )
    return undefined;
  const url = new URL(candidate);
  if (!/\.(png|webp|jpe?g|avif)$/i.test(url.pathname)) return undefined;
  const origin = resolveAssetUrl(original);
  const transformed =
    origin.startsWith(ASSET_ORIGIN + '/') &&
    url.pathname === new URL(origin).pathname.replace(/\.(png|webp|jpe?g|avif)$/i, '.avif');
  const source = transformed ? origin : candidate;
  const metadata = manifestImage(source);
  if (!metadata || metadata.animated) return undefined;
  const size = transformed
    ? ASSET_IMAGE_SIZES.find((bucket) => String(bucket) === url.searchParams.get('size'))
    : undefined;
  return { url: candidate, path: assetPath(source), sha: metadata.sha, size };
}

export type BadgeSizeName = 'small' | 'medium' | 'large';

function badgeSizeForPixels(pixels: number): BadgeSizeName {
  if (pixels <= 70) return 'small';
  if (pixels <= 256) return 'medium';
  return 'large';
}

/** Match supported named badge variants (small/medium/large) to physical pixels. */
export function sizedBadgeUrl(url: string, width: number, height: number, scale: number): string {
  if (!url.startsWith('https://badges.clashk.ing/')) return url;
  const pixels = [width, height, scale].every((value) => Number.isFinite(value) && value > 0)
    ? Math.ceil(Math.max(width, height) * scale)
    : 512;
  const size = badgeSizeForPixels(pixels);
  const value = new URL(url);
  value.pathname = value.pathname.replace(/\.(png|avif)$/i, '') + '.avif';
  value.search = '';
  value.hash = '';
  value.searchParams.set('size', size);
  return value.toString();
}

/** PNG fallback uses the same named size and never adds private hints to public URLs. */
export function originalBadgeUrl(url: string): string {
  if (!url.startsWith('https://badges.clashk.ing/')) return url;
  const value = new URL(url);
  value.pathname = value.pathname.replace(/\.(png|avif)$/i, '') + '.png';
  const requested = value.searchParams.get('size');
  const size: BadgeSizeName =
    requested === 'small' || requested === 'medium' || requested === 'large' ? requested : 'large';
  value.search = '';
  value.hash = '';
  value.searchParams.set('size', size);
  return value.toString();
}
