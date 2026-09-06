import { sizedBadgeUrl, originalBadgeUrl } from './image-delivery';
import { ImageAssets } from '../core/assets/image-assets';

test.each([[16, 3, 64], [32, 3, 128], [64, 3, 256], [120, 3, 512], [600, 3, 512], [0, 3, 512], [NaN, 3, 512]])(
  'requests a supported badge variant for %s points at %sx', (points, scale, pixels) => {
    const url = sizedBadgeUrl('https://badges.clashk.ing/ABC?token=ignored&size=small', points, points, scale);
    expect(url).toBe(`https://badges.clashk.ing/ABC.avif?size=${pixels}`);
    expect(originalBadgeUrl(url)).toBe(`https://badges.clashk.ing/ABC.png?size=${pixels}`);
  },
);
test.each(['small', 'medium', 'large', '64', '128', '256', '512'])('PNG fallback preserves allowed size %s', (size) => {
  expect(originalBadgeUrl(`https://badges.clashk.ing/ABC.avif?size=${size}&hint=ignored`))
    .toBe(`https://badges.clashk.ing/ABC.png?size=${size}`);
});
test('widget and unmeasured fallbacks always have explicit extensions', () => {
  expect(ImageAssets.widgetClanBadgeForTag(' #abc ')).toBe('https://badges.clashk.ing/ABC.png?size=256');
  expect(ImageAssets.widgetClanBadgeForTag('')).toBe('');
  expect(originalBadgeUrl('https://badges.clashk.ing/ABC')).toBe('https://badges.clashk.ing/ABC.png?size=512');
  expect(originalBadgeUrl('https://badges.clashk.ing/ABC?size=1024')).toBe('https://badges.clashk.ing/ABC.png?size=512');
  expect(originalBadgeUrl('https://example.com/a')).toBe('https://example.com/a');
});
