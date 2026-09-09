import { sizedAssetUrl, sizedBadgeUrl } from './image-delivery';
import { applyAssetManifest } from '../core/assets/asset-manifest';

test('sizes raster assets in physical pixels and leaves other formats and hosts alone', () => {
  const original = 'https://assets.clashk.ing/troops/barbarian/icon.webp';
  applyAssetManifest({
    version: 2,
    assets: {
      troops: [{ path: 'troops/barbarian/icon.webp', sha: 'a'.repeat(64), animated: false }],
    },
    data: { stats: [{ path: 'static_data/troops.json', sha: 'a'.repeat(64) }], translations: [] },
  });
  expect(sizedAssetUrl(original, 64, 64, 3)).toBe(
    'https://assets.clashk.ing/troops/barbarian/icon.avif?size=256',
  );
  expect(sizedAssetUrl(original, 12, 12, 2)).toContain('?size=64');
  expect(sizedAssetUrl(original, 700, 700, 3)).toBe(original.replace('.webp', '.avif'));
  expect(sizedAssetUrl(original, 0, 0, 3)).toBe(original.replace('.webp', '.avif'));
  expect(sizedAssetUrl(original, 100, 0, 3)).not.toContain('size=');
  expect(sizedAssetUrl(original, NaN, 50, 3)).not.toContain('size=');
  expect(sizedAssetUrl(original, 12, 12, 3, true)).toBe(original);
  for (const suffix of ['gif', 'svg', 'json', 'ogg', 'ttf', 'glb']) {
    const url = 'https://assets.clashk.ing/example.' + suffix;
    expect(sizedAssetUrl(url, 64, 64, 3)).toBe(url);
  }
  expect(sizedAssetUrl('https://other.test/a.png', 64, 64, 3)).toBe('https://other.test/a.png');
});
test('sizes badges for physical pixels and preserves the badge service', () => {
  const url = 'https://badges.clashk.ing/CLAN.avif';
  expect(sizedBadgeUrl(url, 64, 64, 3)).toBe(`${url}?size=256`);
  expect(sizedBadgeUrl(url, 120, 120, 3)).toBe(`${url}?size=512`);
  expect(sizedBadgeUrl(url, 16, 16, 3)).toBe(`${url}?size=64`);
  expect(sizedBadgeUrl(url, 0, 0, 3)).toBe(`${url}?size=512`);
  expect(sizedBadgeUrl('https://example.com/a.gif', 64, 64, 3)).toBe('https://example.com/a.gif');
});

test('rounds each physical size up, without a global size or an undersized ceiling', () => {
  const url = 'https://assets.clashk.ing/photo.jpg';
  for (const [points, dpr, expected] of [
    [16, 3, 64],
    [24, 3, 128],
    [64, 3, 256],
    [120, 3, 512],
    [300, 3, 1024],
  ]) {
    expect(sizedAssetUrl(url, points!, points!, dpr!)).toBe(
      `https://assets.clashk.ing/photo.avif?size=${expected}`,
    );
  }
  expect(sizedAssetUrl(url, 600, 600, 3)).toBe('https://assets.clashk.ing/photo.avif');
  for (const extension of ['webp', 'png', 'avif', 'gif', 'svg']) {
    const unknown = `https://assets.clashk.ing/unclassified.${extension}`;
    expect(sizedAssetUrl(unknown, 30, 30, 3)).toBe(unknown);
  }
});
