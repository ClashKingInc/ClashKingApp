import {
  CLASHKING_FONT_CACHE_LIFETIME_MS,
  isClashKingFontCacheStale,
} from './clashking-font-contract';

describe('ClashKing font cache parity', () => {
  it('refreshes only after the Flutter seven-day cache lifetime', () => {
    const now = Date.UTC(2026, 7, 29);
    expect(isClashKingFontCacheStale(undefined, now)).toBe(true);
    expect(isClashKingFontCacheStale(now - CLASHKING_FONT_CACHE_LIFETIME_MS + 1, now)).toBe(false);
    expect(isClashKingFontCacheStale(now - CLASHKING_FONT_CACHE_LIFETIME_MS, now)).toBe(true);
  });
});
