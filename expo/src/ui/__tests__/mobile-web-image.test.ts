import { act, fireEvent, render } from '@testing-library/react-native';
import { createElement } from 'react';
import { Image } from 'expo-image';

import { ImageAssets } from '../../core/assets/image-assets';
import { applyAssetManifest } from '../../core/assets/asset-manifest';
jest.mock('../../core/assets/local-asset-cache', () => ({
  localImageCache: { clear: jest.fn(), resolve: jest.fn(async (url: string) => url) },
}));
import {
  MobileWebImage,
  cocAssetsProxyUrl,
  mobileWebImageCandidates,
  resetMobileWebImageCacheForTesting,
  clearMobileImageCache,
} from '../mobile-web-image';

afterEach(() => {
  resetMobileWebImageCacheForTesting();
  jest.restoreAllMocks();
});

describe('MobileWebImage resolution', () => {
  it('uses manifest animation metadata and refreshes the visible image when its SHA changes', async () => {
    const manifest = (sha: string, animated: boolean) => ({
      version: 2, assets: { icons: [{ path: 'icons/manifest-example.webp', sha, animated }] },
      data: [{ path: 'static_data/troops.json', sha }],
    });
    applyAssetManifest(manifest('a'.repeat(64), true));
    const prefetch = jest.spyOn(Image, 'prefetch');
    const image = await render(createElement(MobileWebImage, {
      testID: 'manifest-image', imageUrl: 'https://assets.clashk.ing/icons/manifest-example.webp',
      style: { width: 64, height: 64 },
    }));
    expect(image.getByTestId('manifest-image').props.source[0].uri).toBe(
      'https://assets.clashk.ing/icons/manifest-example.webp');
    await act(async () => { applyAssetManifest(manifest('b'.repeat(64), false)); });
    const url = new URL(image.getByTestId('manifest-image').props.source[0].uri);
    expect(url.pathname).toBe('/icons/manifest-example.avif');
    expect(url.searchParams.has('v')).toBe(false);
    expect(prefetch).not.toHaveBeenCalled();
  });
  it('falls back from sized AVIF to the original image', async () => {
    const original = 'https://assets.clashk.ing/icons/example.webp';
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'image',
        imageUrl: original,
        style: { width: 64, height: 64 },
      }),
    );
    expect(image.getByTestId('image').props.source[0].uri).toMatch(/example\.avif\?size=/);
    await fireEvent(image.getByTestId('image'), 'error', { nativeEvent: {} });
    expect(image.getByTestId('image').props.source).toEqual([{ uri: original, headers: { 'Cache-Control': 'no-cache' } }]);
  });

  it('leaves explicitly animated images on their original URL', async () => {
    const original = 'https://assets.clashk.ing/animation.webp';
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'image',
        imageUrl: original,
        preserveAnimation: true,
      }),
    );
    expect(image.getByTestId('image').props.source).toEqual([{ uri: original, headers: { 'Cache-Control': 'no-cache' } }]);
  });

  it('clears both native image caches and reports unsuccessful clearing', async () => {
    const memory = jest.spyOn(Image, 'clearMemoryCache').mockResolvedValue(true);
    const disk = jest.spyOn(Image, 'clearDiskCache').mockResolvedValue(true);
    await clearMobileImageCache();
    expect(memory).toHaveBeenCalledTimes(1);
    expect(disk).toHaveBeenCalledTimes(1);
    disk.mockResolvedValue(false);
    await expect(clearMobileImageCache()).rejects.toThrow('could not be cleared');
  });
  it('proxies official Clash assets through the same host as Flutter', () => {
    expect(cocAssetsProxyUrl('https://api-assets.clashofclans.com/badges/example.png')).toBe(
      'https://assets-proxy.clashk.ing/badges/example.png',
    );
  });

  it('does not add ineffective cache-buster retries', () => {
    const requested = `${ImageAssets.baseUrl}/icons/example.png`;
    expect(mobileWebImageCandidates(requested, ['https://example.test/fallback.png'])).toEqual([
      requested,
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
