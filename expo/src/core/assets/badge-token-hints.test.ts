import { badgeImageSource, badgeRequestHeaders, rememberBadgeToken } from './badge-token-hints';
import { ImageAssets } from './image-assets';
import { ClanBadgeUrls } from '../../features/clan/models/clan-core';

test('preserves upstream tokens through model parsing without changing URLs or cache keys', () => {
  const badge = ClanBadgeUrls.fromJson({ tag: '#HINTA', badgeUrls: { medium: 'https://api-assets.clashofclans.com/badges/200/test_token-1.png' } }, '#HINTA');
  expect(badge.small).toBe('https://badges.clashk.ing/HINTA.avif');
  for (const format of ['avif', 'png']) {
    const url = `https://badges.clashk.ing/HINTA.${format}?size=128`;
    expect(badgeImageSource(url, 'ios')).toEqual({ uri: url, cacheKey: url, headers: { 'X-ClashKing-Badge-Token': 'test_token-1' } });
    expect(badgeImageSource(url, 'web')).toEqual({ uri: url });
  }
});
test('accepts provided tokens, updates changed mappings, and omits hints when unavailable', () => {
  ImageAssets.clanBadgeForTag('#HINTB', { tag: '#HINTB', badgeToken: 'old' });
  ImageAssets.clanBadgeForTag('#HINTB', { tag: '#HINTB', badgeToken: 'new' });
  expect(badgeRequestHeaders('https://badges.clashk.ing/HINTB.png', 'android')).toEqual({ 'X-ClashKing-Badge-Token': 'new' });
  expect(badgeRequestHeaders('https://badges.clashk.ing/NOHINT.avif', 'ios')).toBeUndefined();
});
test('rejects mismatched tags, nonofficial URLs, malformed tokens, and unrelated request hosts', () => {
  rememberBadgeToken('HINTC', { tag: '#OTHER', badgeToken: 'wrong' });
  for (const url of [
    'https://evil.test/badges/200/token.png',
    'https://api-assets.clashofclans.com.evil.test/badges/200/token.png',
    'https://api-assets.clashofclans.com/badges/200/token.png?extra=1',
    'http://api-assets.clashofclans.com/badges/200/token.png',
  ]) rememberBadgeToken('HINTC', { small: url });
  rememberBadgeToken('HINTC', { badgeToken: 'bad\r\nheader' });
  expect(badgeRequestHeaders('https://badges.clashk.ing/HINTC.avif', 'ios')).toBeUndefined();
  expect(badgeRequestHeaders('https://evil.test/HINTB.png', 'ios')).toBeUndefined();
  expect(badgeRequestHeaders('https://assets.clashk.ing/HINTB.png', 'ios')).toBeUndefined();
});
