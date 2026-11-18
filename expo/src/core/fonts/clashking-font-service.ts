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
    // Wiki headings must have their final metrics before a detail transition.
    // This optional bundled face must not block startup if loading fails.
    await Font.loadAsync(
      'Supercell-Magic',
      require('../../../assets/clashking/legend-poster/clash.ttf'),
    ).catch(() => {});
    return true;
  } catch (error) {
    console.warn('ClashKing bundled font load failed; using system fallback', error);
    return false;
  }
}
