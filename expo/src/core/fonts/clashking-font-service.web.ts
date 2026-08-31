import * as Font from 'expo-font';

import { CLASHKING_FONT_FAMILY, CLASHKING_FONT_URL } from './clashking-font-contract';

let fontLoad: Promise<boolean> | null = null;

export function loadClashKingFont(): Promise<boolean> {
  fontLoad ??= loadOnce();
  return fontLoad;
}

async function loadOnce(): Promise<boolean> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5_000);
  try {
    const response = await fetch(CLASHKING_FONT_URL, { signal: controller.signal });
    if (response.status !== 200) throw new Error(`HTTP ${response.status}`);
    const bytes = await response.arrayBuffer();
    if (bytes.byteLength === 0) throw new Error('Downloaded ClashKing font is empty.');
    // The injected @font-face rule keeps referencing this URL for the lifetime
    // of the page. Revoking it after load breaks later paints in WebKit.
    const objectUrl = URL.createObjectURL(new Blob([bytes], { type: 'font/ttf' }));
    await Font.loadAsync(CLASHKING_FONT_FAMILY, { uri: objectUrl });
    return true;
  } catch (error) {
    console.warn('ClashKing font download failed; using system fallback', error);
    return false;
  } finally {
    clearTimeout(timeout);
  }
}
