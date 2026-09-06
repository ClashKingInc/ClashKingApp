import { sizedAssetUrl, sizedBadgeUrl } from './image-delivery';

test('sizes raster assets in physical pixels and leaves other formats and hosts alone', () => {
  const original = 'https://assets.clashk.ing/troops/barbarian/icon.webp';
  expect(sizedAssetUrl(original, 64, 64, 3)).toBe(
    'https://assets.clashk.ing/troops/barbarian/icon.avif?size=256',
  );
  expect(sizedAssetUrl(original, 12, 12, 2)).toContain('?size=64');
  expect(sizedAssetUrl(original, 700, 700, 3)).toContain('?size=1024');
  expect(sizedAssetUrl(original, 0, 0, 3)).toContain('?size=1024');
  for (const suffix of ['gif', 'svg', 'json', 'ogg', 'ttf', 'glb']) {
    const url = 'https://assets.clashk.ing/example.' + suffix;
    expect(sizedAssetUrl(url, 64, 64, 3)).toBe(url);
  }
  expect(sizedAssetUrl('https://other.test/a.png', 64, 64, 3)).toBe('https://other.test/a.png');
});
test('sizes badges for physical pixels and preserves the badge service', () => {
  const url = 'https://badges.clashk.ing/CLAN.avif';
  expect(sizedBadgeUrl(url, 64, 64, 3)).toBe(`${url}?size=medium`);
  expect(sizedBadgeUrl(url, 120, 120, 3)).toBe(`${url}?size=large`);
  expect(sizedBadgeUrl(url, 16, 16, 3)).toBe(`${url}?size=small`);
  expect(sizedBadgeUrl(url, 0, 0, 3)).toBe(`${url}?size=large`);
  expect(sizedBadgeUrl('https://example.com/a.gif', 64, 64, 3)).toBe('https://example.com/a.gif');
});
