import { badgeImageSource } from '../core/assets/badge-token-hints';
import { Image, type ImageProps, type ImageLoadEventData } from 'expo-image';
import {
  useCallback,
  useEffect,
  useMemo,
  useState,
  useSyncExternalStore,
  type ReactNode,
} from 'react';
import { localImageCache } from '../core/assets/local-asset-cache';
import { Platform, StyleSheet, PixelRatio, View } from 'react-native';
import { sizedAssetUrl, sizedBadgeUrl, originalBadgeUrl } from './image-delivery';

import { ImageAssets } from '../core/assets/image-assets';
import {
  assetManifestRevision,
  manifestImage,
  subscribeAssetManifest,
} from '../core/assets/asset-manifest';

const OFFICIAL_ASSET_HOST = 'https://api-assets.clashofclans.com';
const ASSET_PROXY_HOST = 'https://assets-proxy.clashk.ing';
const MAX_RESOLVED_IMAGES = 512;
const MAX_FAILED_IMAGES = 1_024;
const FAILURE_TTL_MS = 20_000;
const EMPTY_FALLBACKS: readonly string[] = [];

const resolvedImages = new Map<string, string>();
const failedImages = new Map<string, number>();
subscribeAssetManifest(() => {
  resolvedImages.clear();
  failedImages.clear();
});
let cacheRevision = 0;
const cacheListeners = new Set<() => void>();
const subscribeCache = (listener: () => void) => {
  cacheListeners.add(listener);
  return () => {
    cacheListeners.delete(listener);
  };
};
const getCacheRevision = () => cacheRevision;

export async function clearMobileImageCache(): Promise<void> {
  if (Platform.OS !== 'web') await localImageCache.clear();
  const results = await Promise.all([Image.clearMemoryCache(), Image.clearDiskCache()]);
  if (results.some((result) => result === false))
    throw new Error('Image cache could not be cleared');
  resetMobileWebImageCacheForTesting();
  cacheRevision += 1;
  for (const listener of cacheListeners) listener();
}

export interface MobileWebImageProps extends Omit<ImageProps, 'source' | 'onError'> {
  readonly imageUrl: string;
  readonly fallbackImageUrls?: readonly string[];
  readonly errorFallback?: ReactNode;
  readonly preserveAnimation?: boolean;
  /** Layout points, not physical pixels. Use only when layout cannot describe the display size. */
  readonly displaySize?: { readonly width: number; readonly height: number };
}

/** Expo equivalent of Flutter's shared MobileWebImage resolution/fallback behavior. */
export function MobileWebImage({
  imageUrl,
  fallbackImageUrls = EMPTY_FALLBACKS,
  errorFallback,
  preserveAnimation = false,
  displaySize,
  allowDownscaling = true,
  cachePolicy = 'disk',
  contentFit = 'contain',
  enforceEarlyResizing = Platform.OS === 'ios',
  onLoad,
  ...imageProps
}: MobileWebImageProps) {
  const revision = useSyncExternalStore(subscribeCache, getCacheRevision, getCacheRevision);
  useSyncExternalStore(subscribeAssetManifest, assetManifestRevision, assetManifestRevision);
  const [measured, setMeasured] = useState({ width: 0, height: 0 });
  const layout = StyleSheet.flatten(imageProps.style);
  const width =
    displaySize?.width ?? (typeof layout?.width === 'number' ? layout.width : measured.width);
  const height =
    displaySize?.height ?? (typeof layout?.height === 'number' ? layout.height : measured.height);
  const ratio =
    typeof layout?.aspectRatio === 'number' && layout.aspectRatio > 0
      ? layout.aspectRatio
      : undefined;
  const renderedWidth = width || (ratio && height ? height * ratio : 0);
  const renderedHeight = height || (ratio && width ? width / ratio : 0);
  const badgeUrl = sizedBadgeUrl(imageUrl, renderedWidth, renderedHeight, PixelRatio.get());
  const metadata = manifestImage(imageUrl);
  const originalUrl = originalBadgeUrl(badgeUrl);
  const requestedUrl =
    preserveAnimation || metadata?.animated
      ? badgeUrl
      : sizedAssetUrl(badgeUrl, renderedWidth, renderedHeight, PixelRatio.get());
  const [retryAttempt, setRetryAttempt] = useState(0);
  const [exhausted, setExhausted] = useState(false);
  const [retryUrl, setRetryUrl] = useState(requestedUrl);
  const onExhausted = useCallback(() => setExhausted(true), []);
  if (retryUrl !== requestedUrl) {
    setRetryUrl(requestedUrl);
    setRetryAttempt(0);
    setExhausted(false);
  }
  useEffect(() => {
    if (!exhausted || retryAttempt >= 2) return;
    // Wait beyond the shared failure cooldown; stop after two retry rounds.
    const timer = setTimeout(
      () => {
        setExhausted(false);
        setRetryAttempt((attempt) => attempt + 1);
      },
      (FAILURE_TTL_MS + 1_000) * (retryAttempt + 1),
    );
    return () => clearTimeout(timer);
  }, [exhausted, retryAttempt]);
  const candidates = useMemo(
    () => mobileWebImageCandidates(requestedUrl, [originalUrl, ...fallbackImageUrls]),
    // Cache clearing must also retry previously failed candidates.
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [fallbackImageUrls, requestedUrl, originalUrl, revision, metadata?.sha, retryAttempt],
  );
  const identity = `${retryAttempt}\u0000${revision}\u0000${metadata?.sha}\u0000${imageUrl}\u0000${candidates.join('\u0000')}`;
  const onLayout: NonNullable<ImageProps['onLayout']> = (event) => {
    const { width, height } = event.nativeEvent.layout;
    setMeasured((current) =>
      current.width === width && current.height === height ? current : { width, height },
    );
    imageProps.onLayout?.(event);
  };
  // Percentage/flex images have a definite parent layout, but not on the first
  // render. Measure an empty box instead of downloading a full-size image first.
  const layoutPending =
    (!renderedWidth || !renderedHeight) &&
    (typeof layout?.width === 'string' ||
      typeof layout?.height === 'string' ||
      layout?.flex === 1 ||
      (layout?.position === 'absolute' && layout.left === 0 && layout.right === 0));
  if (layoutPending)
    return <View testID={imageProps.testID} style={imageProps.style} onLayout={onLayout} />;
  return (
    <CandidateImage
      key={identity}
      {...imageProps}
      onLayout={onLayout}
      allowDownscaling={allowDownscaling}
      cachePolicy={cachePolicy}
      candidates={candidates}
      contentFit={contentFit}
      enforceEarlyResizing={enforceEarlyResizing}
      errorFallback={errorFallback}
      onLoad={onLoad}
      resolutionKey={requestedUrl}
      originalUrl={imageUrl}
      onExhausted={onExhausted}
    />
  );
}

function CandidateImage({
  onExhausted,
  originalUrl,
  candidates,
  resolutionKey,
  errorFallback,
  onLoad,
  ...imageProps
}: Omit<ImageProps, 'source' | 'onError'> & {
  readonly candidates: readonly string[];
  readonly onExhausted: () => void;
  readonly resolutionKey: string;
  readonly originalUrl: string;
  readonly errorFallback?: ReactNode;
}) {
  const [index, setIndex] = useState(0);
  const candidate = candidates[index];
  const [downloaded, setDownloaded] = useState<{ candidate: string; file: string }>();
  useEffect(() => {
    if (candidate === undefined) onExhausted();
  }, [candidate, onExhausted]);
  const metadata = manifestImage(originalUrl);
  const managed =
    Platform.OS !== 'web' && metadata && candidate?.startsWith('https://assets.clashk.ing/');
  const cachedFile = useSyncExternalStore(
    localImageCache.subscribe,
    useCallback(
      () => (managed && candidate ? localImageCache.peek(candidate) : undefined),
      [managed, candidate],
    ),
    () => undefined,
  );
  const localUri =
    managed && candidate
      ? downloaded?.candidate === candidate
        ? downloaded.file
        : cachedFile
      : undefined;
  useEffect(() => {
    if (!managed || !candidate || !metadata) return;
    let active = true;
    const display = (file: string) => {
      if (active) setDownloaded({ candidate, file });
    };
    void localImageCache
      .resolve(
        candidate,
        decodeURIComponent(new URL(originalUrl).pathname.slice(1)),
        metadata.sha,
        display,
      )
      .then(display)
      .catch(() => {
        if (active) {
          rememberFailure(resolutionKey, candidate);
          setIndex((current) => current + 1);
        }
      });
    return () => {
      active = false;
    };
  }, [candidate, managed, metadata, originalUrl, resolutionKey]);
  if (candidate === undefined) {
    if (errorFallback !== undefined) return errorFallback;
    return (
      <Image
        {...imageProps}
        recyclingKey={imageProps.recyclingKey ?? ImageAssets.defaultImage}
        source={{ uri: ImageAssets.defaultImage }}
        onLoad={onLoad}
      />
    );
  }
  return (
    <Image
      {...imageProps}
      recyclingKey={imageProps.recyclingKey ?? candidate}
      source={
        managed
          ? localUri
            ? { uri: localUri }
            : null
          : {
              ...badgeImageSource(candidate, Platform.OS),
              ...(Platform.OS !== 'web' && candidate.startsWith('https://assets.clashk.ing/')
                ? { headers: { 'Cache-Control': 'no-cache' } }
                : {}),
            }
      }
      onLoad={(event: ImageLoadEventData) => {
        rememberResolved(resolutionKey, candidate);
        onLoad?.(event);
      }}
      onError={() => {
        rememberFailure(resolutionKey, candidate);
        setIndex((current) => current + 1);
      }}
    />
  );
}

export function mobileWebImageCandidates(
  requested: string,
  fallbacks: readonly string[] = [],
  now = Date.now(),
): readonly string[] {
  const candidates: string[] = [];
  const resolved = resolvedImages.get(requested);
  for (const rawCandidate of [requested, resolved, ...fallbacks]) {
    if (!rawCandidate) continue;
    for (const candidate of candidateVariants(cocAssetsProxyUrl(rawCandidate))) {
      const failedAt = failedImages.get(candidate);
      if (failedAt !== undefined && now - failedAt > FAILURE_TTL_MS) {
        failedImages.delete(candidate);
      }
      if (!candidate || failedImages.has(candidate) || candidates.includes(candidate)) continue;
      candidates.push(candidate);
    }
  }
  return candidates;
}

export function cocAssetsProxyUrl(value: string): string {
  return value.startsWith(OFFICIAL_ASSET_HOST)
    ? value.replace(OFFICIAL_ASSET_HOST, ASSET_PROXY_HOST)
    : value;
}

function candidateVariants(candidate: string): readonly string[] {
  // The Worker discards cache-buster queries; retry the real original instead.
  return [candidate];
}

function rememberResolved(resolutionKey: string, resolvedUrl: string): void {
  if (resolvedImages.get(resolutionKey) === resolvedUrl) return;
  setBounded(resolvedImages, resolutionKey, resolvedUrl, MAX_RESOLVED_IMAGES);
}

function rememberFailure(resolutionKey: string, url: string): void {
  if (resolvedImages.get(resolutionKey) === url) resolvedImages.delete(resolutionKey);
  setBounded(failedImages, url, Date.now(), MAX_FAILED_IMAGES);
}

function setBounded<T>(map: Map<string, T>, key: string, value: T, maximum: number): void {
  map.delete(key);
  map.set(key, value);
  while (map.size > maximum) {
    const oldest = map.keys().next().value as string | undefined;
    if (oldest === undefined) return;
    map.delete(oldest);
  }
}

export function resetMobileWebImageCacheForTesting(): void {
  resolvedImages.clear();
  failedImages.clear();
}
