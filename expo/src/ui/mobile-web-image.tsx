import { Image, type ImageProps, type ImageLoadEventData } from 'expo-image';
import { useMemo, useState, type ReactNode } from 'react';
import { Platform } from 'react-native';

import { ImageAssets } from '../core/assets/image-assets';

const OFFICIAL_ASSET_HOST = 'https://api-assets.clashofclans.com';
const ASSET_PROXY_HOST = 'https://assets-proxy.clashk.ing';
const MAX_RESOLVED_IMAGES = 512;
const MAX_FAILED_IMAGES = 1_024;
const FAILURE_TTL_MS = 20_000;
const EMPTY_FALLBACKS: readonly string[] = [];

const resolvedImages = new Map<string, string>();
const failedImages = new Map<string, number>();

export interface MobileWebImageProps extends Omit<ImageProps, 'source' | 'onError'> {
  readonly imageUrl: string;
  readonly fallbackImageUrls?: readonly string[];
  readonly errorFallback?: ReactNode;
}

/** Expo equivalent of Flutter's shared MobileWebImage resolution/fallback behavior. */
export function MobileWebImage({
  imageUrl,
  fallbackImageUrls = EMPTY_FALLBACKS,
  errorFallback,
  allowDownscaling = true,
  cachePolicy = 'disk',
  contentFit = 'contain',
  enforceEarlyResizing = Platform.OS === 'ios',
  onLoad,
  ...imageProps
}: MobileWebImageProps) {
  const candidates = useMemo(
    () => mobileWebImageCandidates(imageUrl, fallbackImageUrls),
    [fallbackImageUrls, imageUrl],
  );
  const identity = `${imageUrl}\u0000${candidates.join('\u0000')}`;
  return (
    <CandidateImage
      key={identity}
      {...imageProps}
      allowDownscaling={allowDownscaling}
      cachePolicy={cachePolicy}
      candidates={candidates}
      contentFit={contentFit}
      enforceEarlyResizing={enforceEarlyResizing}
      errorFallback={errorFallback}
      onLoad={onLoad}
      resolutionKey={imageUrl}
    />
  );
}

function CandidateImage({
  candidates,
  resolutionKey,
  errorFallback,
  onLoad,
  ...imageProps
}: Omit<ImageProps, 'source' | 'onError'> & {
  readonly candidates: readonly string[];
  readonly resolutionKey: string;
  readonly errorFallback?: ReactNode;
}) {
  const [index, setIndex] = useState(0);
  const candidate = candidates[index];
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
      source={{ uri: candidate }}
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
  for (const rawCandidate of [resolved, requested, ...fallbacks]) {
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
  try {
    const url = new URL(candidate);
    if (url.host !== new URL(ImageAssets.baseUrl).host) return [candidate];
    url.searchParams.set('_ck_image_retry', '1');
    return [candidate, url.toString()];
  } catch {
    return [candidate];
  }
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
