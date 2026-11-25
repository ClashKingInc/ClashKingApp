import { ASSET_ORIGIN, assetPath, resolveAssetUrl } from './asset-origin';

interface OfflineGameImage {
  readonly source: number;
  readonly sha: string;
  readonly pixels: number;
  readonly fullSize: boolean;
}

// Source SHA from the Assets manifest. WebP previews are capped at 128 pixels.
const images = new Map<string, OfflineGameImage>([
  [
    'icons/Icon_Unknown_Troop.png',
    {
      source: require('../../../assets/generated/clashking/offline/unknown-troop.webp'),
      sha: '9fec87f16ce2391b2f1d815d724e32fc6dc4d4d1c984b56c693b02cbc8f8f64e',
      pixels: 128,
      fullSize: false,
    },
  ],
  [
    'icons/Icon_HV_Shield.png',
    {
      source: require('../../../assets/generated/clashking/offline/default-clan-badge.webp'),
      sha: '9816c716948026bcd07cc7f869c7ae382c55ec0a5d266b6934dd56b0a830e20b',
      pixels: 128,
      fullSize: false,
    },
  ],
]);

export function offlineGameImage(url: string): OfflineGameImage | undefined {
  const resolved = resolveAssetUrl(url);
  if (!resolved.startsWith(ASSET_ORIGIN + '/')) return undefined;
  if (__DEV__ && process.env.EXPO_PUBLIC_CK_ASSET_ORIGIN) return undefined;
  try {
    return images.get(assetPath(resolved));
  } catch {
    return undefined;
  }
}

export const unknownTroopSource = images.get('icons/Icon_Unknown_Troop.png')!.source;
export const defaultClanBadgeSource = images.get('icons/Icon_HV_Shield.png')!.source;
