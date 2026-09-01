import * as Font from 'expo-font';

import { CLASHKING_FONT_FAMILY, CLASHKING_FONT_SOURCE } from './clashking-font-contract';

let fontLoad: Promise<boolean> | null = null;

export function loadClashKingFont(): Promise<boolean> {
  fontLoad ??= loadOnce();
  return fontLoad;
}

async function loadOnce(): Promise<boolean> {
  try {
    await Font.loadAsync(CLASHKING_FONT_FAMILY, CLASHKING_FONT_SOURCE);
    return true;
  } catch (error) {
    console.warn('ClashKing bundled font load failed; using system fallback', error);
    return false;
  }
}
