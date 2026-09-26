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
  if (!url.startsWith('https://assets.clashk.ing/')) return url;
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

/** Match supported badge variants to physical pixels, capped at the upstream 512px. */
export function sizedBadgeUrl(url: string, width: number, height: number, scale: number): string {
  if (!url.startsWith('https://badges.clashk.ing/')) return url;
  const pixels = [width, height, scale].every((value) => Number.isFinite(value) && value > 0)
    ? Math.ceil(Math.max(width, height) * scale) : 512;
  const size = [64, 128, 256, 512].find((bound) => bound >= pixels) ?? 512;
  const value = new URL(url);
  value.pathname = value.pathname.replace(/\.(png|avif)$/i, '') + '.avif';
  value.search = '';
  value.hash = '';
  value.searchParams.set('size', String(size));
  return value.toString();
}

/** PNG fallback uses the same size and never adds private hints to public URLs. */
export function originalBadgeUrl(url: string): string {
  if (!url.startsWith('https://badges.clashk.ing/')) return url;
  const value = new URL(url);
  value.pathname = value.pathname.replace(/\.(png|avif)$/i, '') + '.png';
  const size = value.searchParams.get('size') ?? '';
  value.search = '';
  value.hash = '';
  value.searchParams.set('size', ['small', 'medium', 'large', '64', '128', '256', '512'].includes(size) ? size : '512');
  return value.toString();
}
