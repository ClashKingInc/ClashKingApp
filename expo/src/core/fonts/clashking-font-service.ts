import { Directory, File, Paths } from 'expo-file-system';
import * as Font from 'expo-font';

import {
  CLASHKING_FONT_FAMILY,
  CLASHKING_FONT_URL,
  isClashKingFontCacheStale,
} from './clashking-font-contract';

let fontLoad: Promise<boolean> | null = null;

export function loadClashKingFont(): Promise<boolean> {
  fontLoad ??= loadOnce();
  return fontLoad;
}

async function loadOnce(): Promise<boolean> {
  try {
    const directory = new Directory(Paths.document, 'fonts');
    directory.create({ intermediates: true, idempotent: true });
    const cached = new File(directory, 'clashking.ttf');
    if (cached.exists) {
      try {
        await Font.loadAsync(CLASHKING_FONT_FAMILY, cached.uri);
        if (isClashKingFontCacheStale(cached.info().modificationTime)) {
          void refresh(directory, cached).catch((error: unknown) => {
            console.warn('ClashKing font cache refresh failed', error);
          });
        }
        return true;
      } catch (error) {
        console.warn('ClashKing cached font is invalid; downloading a fresh copy', error);
        cached.delete();
      }
    }

    const refreshedUri = await refresh(directory, cached);
    await Font.loadAsync(CLASHKING_FONT_FAMILY, refreshedUri);
    return true;
  } catch (error) {
    console.warn('ClashKing font load failed; using system fallback', error);
    return false;
  }
}

async function refresh(directory: Directory, cached: File): Promise<string> {
  const pending = new File(directory, 'clashking.ttf.pending');
  if (pending.exists) pending.delete();
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5_000);
  let moved = false;
  try {
    await File.downloadFileAsync(CLASHKING_FONT_URL, pending, {
      headers: { 'User-Agent': 'ClashKing-App/1.0' },
      idempotent: true,
      signal: controller.signal,
    });
    if ((pending.size ?? 0) <= 0) throw new Error('Downloaded ClashKing font is empty.');
    await pending.move(cached, { overwrite: true });
    moved = true;
    return pending.uri;
  } finally {
    clearTimeout(timeout);
    // Expo mutates a File handle to its destination after move(). Once that
    // succeeds, `pending` points at the committed cache and must not be deleted.
    if (!moved && pending.exists) pending.delete();
  }
}
