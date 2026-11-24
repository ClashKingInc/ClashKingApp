import { badgeRequestHeaders } from './badge-token-hints';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Directory, File, FileMode, Paths } from 'expo-file-system';
import { Image } from 'expo-image';
import { fetch } from 'expo/fetch';
import { randomUUID } from 'expo-crypto';
import { FileUpdateIndex } from './file-update-index';
import { ManagedImageCache } from './managed-image-cache';
import { avifPixelBound } from './avif-dimensions';

export const localFileIndex = new FileUpdateIndex({
  getKeys: () => AsyncStorage.getAllKeys(),
  getMany: (keys) => AsyncStorage.multiGet([...keys]),
  removeString: (key) => AsyncStorage.removeItem(key),
  removeStrings: (keys) => AsyncStorage.multiRemove([...keys]),
  getString: (key) => AsyncStorage.getItem(key),
  setString: (key, value) => AsyncStorage.setItem(key, value),
});
function cacheDirectory() {
  return new Directory(Paths.cache, 'clashking-images-v2');
}
function isOwnedFile(uri: string): boolean {
  return uri.startsWith(cacheDirectory().uri.replace(/\/$/, '') + '/');
}
function ownedFile(uri: string): File {
  if (!isOwnedFile(uri)) throw new Error('Invalid image cache path');
  return new File(uri);
}
const MAX_IMAGE_BYTES = 16 * 1024 * 1024;
const AVIF_HEADER_BYTES = 16 * 1024;
export const localImageCache = new ManagedImageCache(localFileIndex, {
  // Absolute cache URLs can outlive an iOS app-container replacement. Treat
  // those stale records as cache misses, and never try to delete outside the
  // currently owned cache directory.
  exists: async (uri) => isOwnedFile(uri) && ownedFile(uri).exists,
  remove: async (uri) => {
    if (!isOwnedFile(uri)) return;
    const file = ownedFile(uri);
    if (file.exists) file.delete();
  },
  clearAll: async () => {
    const directory = cacheDirectory();
    if (directory.exists) directory.delete();
  },
  download: async ({ url, sha, size: variantSize }, signal, validateReplacement) => {
    const controller = new AbortController();
    const cancel = () => controller.abort();
    signal?.addEventListener('abort', cancel, { once: true });
    if (signal?.aborted) controller.abort();
    const timeout = setTimeout(() => controller.abort(), 30_000);
    try {
      const badgeHeaders = badgeRequestHeaders(url, 'native');
      const headers = url.startsWith('https://badges.clashk.ing/')
        ? badgeHeaders
        : { 'Cache-Control': 'no-cache', ...badgeHeaders };
      const response = await fetch(url, {
        signal: controller.signal,
        ...(headers ? { headers } : {}),
      });
      if (!response.ok || !response.headers.get('content-type')?.startsWith('image/'))
        throw new Error('Image download failed');
      const declaredBytes = Number(response.headers.get('content-length'));
      if (declaredBytes > MAX_IMAGE_BYTES) throw new Error('Image exceeds cache limit');
      const reader = response.body?.getReader();
      if (!reader) throw new Error('Missing image body');
      const directory = cacheDirectory();
      const source = new URL(url);
      const extension = source.pathname.split('.').pop()!;
      const header =
        !validateReplacement && variantSize !== undefined && extension === 'avif'
          ? new Uint8Array(
              Math.min(declaredBytes > 0 ? declaredBytes : AVIF_HEADER_BYTES, AVIF_HEADER_BYTES),
            )
          : undefined;
      const file = new File(directory, randomUUID() + '.' + extension);
      try {
        directory.create({ intermediates: true, idempotent: true });
        file.create();
        const handle = file.open(FileMode.WriteOnly);
        let length = 0;
        try {
          for (;;) {
            const next = await reader.read();
            if (next.done) break;
            if (header && length < header.length)
              header.set(next.value.subarray(0, header.length - length), length);
            length += next.value.length;
            if (length > MAX_IMAGE_BYTES) throw new Error('Image exceeds cache limit');
            await handle.writeBytes(next.value);
          }
        } finally {
          handle.close();
        }
        if (!length) throw new Error('Empty image');
        let pixels = header ? avifPixelBound(header.subarray(0, length)) : undefined;

        // First installs are decoded by the image view. Only a replacement can
        // displace a good file, so only it needs an eager native decode.
        if (validateReplacement) {
          const limit = variantSize ?? 1024;
          const image = await Image.loadAsync(
            { uri: file.uri },
            { maxWidth: limit, maxHeight: limit },
          );
          try {
            pixels = Math.round(Math.max(image.width, image.height) * image.scale);
            if (!Number.isFinite(pixels) || pixels < 1) throw new Error('Invalid image');
          } finally {
            image.release();
          }
        }
        if (controller.signal.aborted) throw new Error('Image download was cancelled');

        // The converted bytes differ from the manifest source. The Worker does
        // not expose a source-SHA header, so this is the requested source version.
        // If the header is unknown, reuse only at or below the requested bucket.
        if (variantSize !== undefined && pixels !== undefined && pixels > variantSize)
          pixels = undefined;
        const fullSize =
          variantSize === undefined || (pixels !== undefined && pixels < variantSize);
        return { file: file.uri, sha, bytes: length, pixels, fullSize };
      } catch (error) {
        await reader.cancel().catch(() => undefined);
        if (file.exists) file.delete();
        throw error;
      } finally {
        reader.releaseLock();
      }
    } finally {
      clearTimeout(timeout);
      signal?.removeEventListener('abort', cancel);
    }
  },
});
