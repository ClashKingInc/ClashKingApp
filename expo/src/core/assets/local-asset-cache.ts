import { badgeRequestHeaders } from './badge-token-hints';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { Directory, File, Paths } from 'expo-file-system';
import { fetch } from 'expo/fetch';
import { randomUUID } from 'expo-crypto';
import { FileUpdateIndex } from './file-update-index';
import { ManagedImageCache } from './managed-image-cache';

export const localFileIndex = new FileUpdateIndex({
  getKeys: () => AsyncStorage.getAllKeys(),
  getMany: (keys) => AsyncStorage.multiGet([...keys]),
  removeString: (key) => AsyncStorage.removeItem(key),
  getString: (key) => AsyncStorage.getItem(key),
  setString: (key, value) => AsyncStorage.setItem(key, value),
});
function cacheDirectory() {
  return new Directory(Paths.cache, 'clashking-images-v2');
}
function ownedFile(uri: string): File {
  if (!uri.startsWith(cacheDirectory().uri.replace(/\/$/, '') + '/'))
    throw new Error('Invalid image cache path');
  return new File(uri);
}
const MAX_IMAGE_BYTES = 16 * 1024 * 1024;
export const localImageCache = new ManagedImageCache(localFileIndex, {
  exists: async (uri) => ownedFile(uri).exists,
  remove: async (uri) => {
    const file = ownedFile(uri);
    if (file.exists) file.delete();
  },
  download: async (url, expectedSha) => {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 30_000);
    try {
      const response = await fetch(url, {
        signal: controller.signal,
        headers: { 'Cache-Control': 'no-cache', ...badgeRequestHeaders(url, 'native') },
      });
      if (!response.ok || !response.headers.get('content-type')?.startsWith('image/'))
        throw new Error('Image download failed');
      if (Number(response.headers.get('content-length')) > MAX_IMAGE_BYTES)
        throw new Error('Image exceeds cache limit');
      const reader = response.body?.getReader();
      if (!reader) throw new Error('Missing image body');
      const parts: Uint8Array[] = [];
      let length = 0;
      for (;;) {
        const next = await reader.read();
        if (next.done) break;
        length += next.value.length;
        if (length > MAX_IMAGE_BYTES) {
          await reader.cancel();
          throw new Error('Image exceeds cache limit');
        }
        parts.push(next.value);
      }
      if (!length) throw new Error('Empty image');
      const bytes = new Uint8Array(length);
      let offset = 0;
      for (const part of parts) {
        bytes.set(part, offset);
        offset += part.length;
      }
      // The manifest identifies the source version. Converted bytes deliberately
      // differ from that source; the Worker does not expose a source-SHA header.
      const directory = cacheDirectory();
      directory.create({ intermediates: true, idempotent: true });
      const extension = new URL(url).pathname.split('.').pop()!;
      const file = new File(directory, randomUUID() + '.' + extension);
      try {
        file.write(bytes);
      } catch (error) {
        if (file.exists) file.delete();
        throw error;
      }
      return { file: file.uri, sha: expectedSha, bytes: length };
    } finally {
      clearTimeout(timeout);
    }
  },
});
