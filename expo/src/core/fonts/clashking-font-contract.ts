export const CLASHKING_FONT_FAMILY = 'ClashKing';
export const CLASHKING_FONT_URL = 'https://assets.clashk.ing/fonts/clashking.ttf';
export const CLASHKING_FONT_CACHE_LIFETIME_MS = 7 * 24 * 60 * 60 * 1_000;

export function isClashKingFontCacheStale(
  modificationTime: number | undefined,
  now = Date.now(),
): boolean {
  return (
    modificationTime === undefined || now - modificationTime >= CLASHKING_FONT_CACHE_LIFETIME_MS
  );
}
