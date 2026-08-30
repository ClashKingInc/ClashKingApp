import { fireEvent, render } from '@testing-library/react-native';
import { createElement } from 'react';

import { ImageAssets } from '../../core/assets/image-assets';
import {
  MobileWebImage,
  cocAssetsProxyUrl,
  mobileWebImageCandidates,
  resetMobileWebImageCacheForTesting,
} from '../mobile-web-image';

afterEach(() => {
  resetMobileWebImageCacheForTesting();
  jest.restoreAllMocks();
});

describe('MobileWebImage resolution', () => {
  it('proxies official Clash assets through the same host as Flutter', () => {
    expect(cocAssetsProxyUrl('https://api-assets.clashofclans.com/badges/example.png')).toBe(
      'https://assets-proxy.clashk.ing/badges/example.png',
    );
  });

  it('adds one stable retry candidate for first-party assets before fallbacks', () => {
    const requested = `${ImageAssets.baseUrl}/icons/example.png`;
    expect(mobileWebImageCandidates(requested, ['https://example.test/fallback.png'])).toEqual([
      requested,
      `${requested}?_ck_image_retry=1`,
      'https://example.test/fallback.png',
    ]);
  });

  it('deduplicates identical requested and fallback URLs', () => {
    expect(
      mobileWebImageCandidates('https://example.test/image.png', [
        'https://example.test/image.png',
      ]),
    ).toEqual(['https://example.test/image.png']);
  });

  it('uses disk-only caching, early iOS resizing, and a stable recycling identity by default', async () => {
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'image',
        imageUrl: 'https://example.test/oversized.png',
      }),
    );

    expect(image.getByTestId('image').props.allowDownscaling).toBe(true);
    expect(image.getByTestId('image').props.cachePolicy).toBe('disk');
    expect(image.getByTestId('image').props.enforceEarlyResizing).toBe(true);
    expect(image.getByTestId('image').props.recyclingKey).toBe(
      'https://example.test/oversized.png',
    );
  });

  it('forgets a resolved fallback when that URL later fails', async () => {
    const failedAt = 1_000_000;
    jest.spyOn(Date, 'now').mockReturnValue(failedAt);
    const requested = 'https://example.test/requested.png';
    const fallback = 'https://example.test/fallback.png';
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'image',
        imageUrl: requested,
        fallbackImageUrls: [fallback],
      }),
    );

    await fireEvent(image.getByTestId('image'), 'error', { nativeEvent: {} });
    expect(image.getByTestId('image').props.source).toEqual([{ uri: fallback }]);
    await fireEvent(image.getByTestId('image'), 'load', { nativeEvent: {} });
    await fireEvent(image.getByTestId('image'), 'error', { nativeEvent: {} });

    expect(mobileWebImageCandidates(requested, [fallback], failedAt + 20_000)).toEqual([]);
    expect(mobileWebImageCandidates(requested, [fallback], failedAt + 20_001)[0]).toBe(requested);
  });
});
