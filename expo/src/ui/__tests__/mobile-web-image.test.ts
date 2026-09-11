import { act, fireEvent, render } from '@testing-library/react-native';
import { createElement } from 'react';
import { Image } from 'expo-image';
import { PixelRatio } from 'react-native';

import { ImageAssets } from '../../core/assets/image-assets';
import { localImageCache } from '../../core/assets/local-asset-cache';
import { applyAssetManifest } from '../../core/assets/asset-manifest';
import {
  MobileWebImage,
  cocAssetsProxyUrl,
  mobileWebImageCandidates,
  resetMobileWebImageCacheForTesting,
  clearMobileImageCache,
} from '../mobile-web-image';

jest.mock('../../core/assets/local-asset-cache', () => ({
  localImageCache: {
    subscribe: () => () => {},
    getRevision: () => 0,
    peek: jest.fn((url: string) => url),
    clear: jest.fn(),
    resolve: jest.fn(async (url: string) => url),
  },
}));

afterEach(() => {
  jest.useRealTimers();
  resetMobileWebImageCacheForTesting();
  jest.restoreAllMocks();
});
beforeEach(() => {
  jest
    .mocked(localImageCache.peek)
    .mockReset()
    .mockImplementation((url: string) => url);
  jest
    .mocked(localImageCache.resolve)
    .mockReset()
    .mockImplementation(async (url: string) => url);
});

describe('MobileWebImage resolution', () => {
  it('shows a slow managed download without reopening or an index notification', async () => {
    applyAssetManifest({
      version: 2,
      assets: { icons: [{ path: 'icons/slow.webp', sha: 'a'.repeat(64), animated: false }] },
      data: { stats: [{ path: 'static_data/troops.json', sha: 'a'.repeat(64) }], translations: [] },
    });
    jest.mocked(localImageCache.peek).mockReturnValue(undefined as unknown as string);
    let finish!: (file: string) => void;
    jest.mocked(localImageCache.resolve).mockImplementationOnce(
      () =>
        new Promise((resolve) => {
          finish = resolve;
        }),
    );
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'slow',
        imageUrl: 'https://assets.clashk.ing/icons/slow.webp',
        style: { width: 24, height: 24 },
      }),
    );
    await act(async () => {
      finish('file:///finished.webp');
    });
    expect(image.getByTestId('slow').props.source[0].uri).toBe('file:///finished.webp');
  });

  it('retries exhausted candidates while mounted and stops after two retry rounds', async () => {
    jest.useFakeTimers();
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'recover',
        imageUrl: 'https://example.test/recover.png',
        errorFallback: null,
      }),
    );
    for (const wait of [21_000, 42_000]) {
      await fireEvent(image.getByTestId('recover'), 'error', { nativeEvent: {} });
      expect(image.queryByTestId('recover')).toBeNull();
      await act(async () => {
        jest.advanceTimersByTime(wait);
      });
      expect(image.getByTestId('recover').props.source[0].uri).toBe(
        'https://example.test/recover.png',
      );
    }
    await fireEvent(image.getByTestId('recover'), 'error', { nativeEvent: {} });
    await act(async () => {
      jest.advanceTimersByTime(120_000);
    });
    expect(image.queryByTestId('recover')).toBeNull();
  });
  it('uses manifest animation metadata and refreshes the visible image when its SHA changes', async () => {
    const manifest = (sha: string, animated: boolean) => ({
      version: 2,
      assets: { icons: [{ path: 'icons/manifest-example.webp', sha, animated }] },
      data: { stats: [{ path: 'static_data/troops.json', sha }], translations: [] },
    });
    applyAssetManifest(manifest('a'.repeat(64), true));
    const prefetch = jest.spyOn(Image, 'prefetch');
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'manifest-image',
        imageUrl: 'https://assets.clashk.ing/icons/manifest-example.webp',
        style: { width: 64, height: 64 },
      }),
    );
    expect(image.getByTestId('manifest-image').props.source[0].uri).toBe(
      'https://assets.clashk.ing/icons/manifest-example.webp',
    );
    await act(async () => {
      applyAssetManifest(manifest('b'.repeat(64), false));
    });
    const url = new URL(image.getByTestId('manifest-image').props.source[0].uri);
    expect(url.pathname).toBe('/icons/manifest-example.avif');
    expect(url.searchParams.has('v')).toBe(false);
    expect(prefetch).not.toHaveBeenCalled();
  });
  it('shows a hydrated local path while background file validation is still pending', async () => {
    applyAssetManifest({
      version: 2,
      assets: { icons: [{ path: 'icons/warm.webp', sha: 'a'.repeat(64), animated: false }] },
      data: { stats: [{ path: 'static_data/troops.json', sha: 'a'.repeat(64) }], translations: [] },
    });
    jest.mocked(localImageCache.peek).mockReturnValue('file:///warm.avif');
    jest.mocked(localImageCache.resolve).mockImplementationOnce(() => new Promise(() => {}));
    const screen = await render(
      createElement(MobileWebImage, {
        testID: 'warm',
        imageUrl: 'https://assets.clashk.ing/icons/warm.webp',
        style: { width: 64, height: 64 },
      }),
    );
    expect(screen.getByTestId('warm').props.source[0].uri).toBe('file:///warm.avif');
  });
  it('falls back from sized AVIF to the original image', async () => {
    const original = 'https://assets.clashk.ing/icons/example.jpg';
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'image',
        imageUrl: original,
        style: { width: 64, height: 64 },
      }),
    );
    expect(image.getByTestId('image').props.source[0].uri).toMatch(/example\.avif\?size=/);
    await fireEvent(image.getByTestId('image'), 'error', { nativeEvent: {} });
    expect(image.getByTestId('image').props.source).toEqual([
      { uri: original, headers: { 'Cache-Control': 'no-cache' } },
    ]);
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
    expect(image.getByTestId('image').props.source).toEqual([
      { uri: original, headers: { 'Cache-Control': 'no-cache' } },
    ]);
  });

  it('falls back from a correctly sized AVIF badge to PNG at the same size', async () => {
    jest.spyOn(PixelRatio, 'get').mockReturnValue(3);
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'badge',
        imageUrl: 'https://badges.clashk.ing/CLAN',
        style: { width: 40, height: 40 },
      }),
    );
    expect(image.getByTestId('badge').props.source[0].uri).toBe(
      'https://badges.clashk.ing/CLAN.avif?size=128',
    );
    await fireEvent(image.getByTestId('badge'), 'error', { nativeEvent: {} });
    expect(image.getByTestId('badge').props.source[0].uri).toBe(
      'https://badges.clashk.ing/CLAN.png?size=128',
    );
  });

  it('retries optimization after the failure cooldown instead of permanently preferring a fallback', async () => {
    const clock = jest.spyOn(Date, 'now').mockReturnValue(1_000);
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'retry',
        imageUrl: 'https://assets.clashk.ing/retry.jpg',
        style: { width: 16, height: 16 },
      }),
    );
    const requested = image.getByTestId('retry').props.source[0].uri;
    await fireEvent(image.getByTestId('retry'), 'error', { nativeEvent: {} });
    await fireEvent(image.getByTestId('retry'), 'load', { nativeEvent: {} });
    clock.mockReturnValue(22_000);
    expect(mobileWebImageCandidates(requested, ['https://assets.clashk.ing/retry.jpg'])[0]).toBe(
      requested,
    );
  });

  it('uses measured percentage layouts, changes size with layout, and forwards onLayout', async () => {
    jest.spyOn(PixelRatio, 'get').mockReturnValue(3);
    const onLayout = jest.fn();
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'measured',
        imageUrl: 'https://assets.clashk.ing/photo.jpg',
        style: { width: '100%', height: '100%' },
        onLayout,
      }),
    );
    expect(image.getByTestId('measured').props.source).toBeUndefined();
    await fireEvent(image.getByTestId('measured'), 'layout', {
      nativeEvent: { layout: { width: 24, height: 24 } },
    });
    expect(image.getByTestId('measured').props.source[0].uri).toContain('?size=128');
    await fireEvent(image.getByTestId('measured'), 'layout', {
      nativeEvent: { layout: { width: 100, height: 120 } },
    });
    expect(image.getByTestId('measured').props.source[0].uri).toContain('?size=512');
    expect(onLayout).toHaveBeenCalledTimes(2);
  });

  it('accepts an explicit display size and infers a missing dimension from aspect ratio', async () => {
    jest.spyOn(PixelRatio, 'get').mockReturnValue(3);
    const image = await render(
      createElement(MobileWebImage, {
        testID: 'sized',
        imageUrl: 'https://assets.clashk.ing/photo.jpg',
        displaySize: { width: 16, height: 16 },
      }),
    );
    expect(image.getByTestId('sized').props.source[0].uri).toContain('?size=64');
    await image.rerender(
      createElement(MobileWebImage, {
        testID: 'sized',
        imageUrl: 'https://assets.clashk.ing/photo.jpg',
        style: { width: 100, aspectRatio: 2 },
      }),
    );
    expect(image.getByTestId('sized').props.source[0].uri).toContain('?size=512');
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
