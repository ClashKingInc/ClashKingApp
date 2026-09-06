export const ASSET_IMAGE_SIZES = [64, 128, 256, 512, 1024] as const;

/** Only first-party raster images opt in. The caller retains the original fallback. */
export function sizedAssetUrl(url: string, width: number, height: number, scale: number): string {
  if (!url.startsWith('https://assets.clashk.ing/')) return url;
  const value = new URL(url);
  if (!/\.(png|webp|jpe?g|avif)$/i.test(value.pathname)) return url;
  const pixels = Math.ceil(Math.max(width, height) * Math.max(1, scale));
  const size = pixels > 0 ? (ASSET_IMAGE_SIZES.find((bound) => bound >= pixels) ?? 1024) : 1024;
  value.pathname = value.pathname.replace(/\.(png|webp|jpe?g|avif)$/i, '.avif');
  value.search = '';
  value.searchParams.set('size', String(size));
  return value.toString();
}

/** Match badge Worker variants to physical pixels, not layout points. */
export function sizedBadgeUrl(url: string, width: number, height: number, scale: number): string {
  if (!url.startsWith('https://badges.clashk.ing/')) return url;
  const pixels = Math.ceil(Math.max(width, height) * Math.max(1, scale));
  const size =
    pixels > 0 && pixels <= 70 ? 'small' : pixels > 0 && pixels <= 200 ? 'medium' : 'large';
  const value = new URL(url);
  value.searchParams.set('size', size);
  return value.toString();
}
