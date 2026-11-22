import { ASSET_ORIGIN, resolveAssetUrl } from '../core/assets/asset-origin';
import { manifestImage } from '../core/assets/asset-manifest';

export const ASSET_IMAGE_SIZES = [64, 128, 256, 512, 1024] as const;

function requiredPixels(width: number, height: number, scale: number): number | undefined {
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

export type BadgeSizeName = 'small' | 'medium' | 'large';

const BADGE_SIZE_ALIASES: Readonly<Record<string, BadgeSizeName>> = {
  small: 'small',
  medium: 'medium',
  large: 'large',
  '64': 'small',
  '128': 'medium',
  '256': 'medium',
  '512': 'large',
};

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
  const requested = value.searchParams.get('size') ?? '';
  const size = BADGE_SIZE_ALIASES[requested] ?? 'large';
  value.search = '';
  value.hash = '';
  value.searchParams.set('size', size);
  return value.toString();
}
