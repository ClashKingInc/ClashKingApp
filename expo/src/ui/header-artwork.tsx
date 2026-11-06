import { useEffect, useSyncExternalStore } from 'react';
import { Image, type ImageProps } from 'expo-image';
import {
  decodedHeaderArtwork,
  prepareHeaderArtwork,
  subscribeHeaderArtwork,
} from '../core/assets/header-artwork-cache';

/** A ready native image reference draws without repeating file lookup/decode. */
export function HeaderArtwork({
  source,
  ...props
}: Omit<ImageProps, 'source'> & { source: number }) {
  const image = useSyncExternalStore(
    subscribeHeaderArtwork,
    () => decodedHeaderArtwork(source),
    () => undefined,
  );
  useEffect(() => {
    void prepareHeaderArtwork(source);
  }, [source]);
  return (
    <Image
      {...props}
      source={image ?? source}
      cachePolicy="memory-disk"
      priority="high"
      transition={0}
    />
  );
}
