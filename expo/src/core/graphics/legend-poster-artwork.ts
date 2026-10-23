import { Asset } from 'expo-asset';
import { File } from 'expo-file-system';
import * as Font from 'expo-font';
import { fetch } from 'expo/fetch';
import { Platform } from 'react-native';
import { badgeRequestHeaders } from '../assets/badge-token-hints';
import { mobileWebImageCandidates } from '../../ui/mobile-web-image';
import { legendPosterAssets } from './legend-poster-assets';
import type { LegendPosterArtwork } from './legend-poster-layout';

let fonts: Promise<void> | undefined;
const bundled = new Map<number, Promise<string>>();

function base64(bytes: Uint8Array) {
  let binary = '';
  for (let offset = 0; offset < bytes.length; offset += 8192)
    binary += String.fromCharCode(...bytes.subarray(offset, offset + 8192));
  return btoa(binary);
}

async function bundledImage(module: number) {
  let pending = bundled.get(module);
  if (!pending) {
    pending = (async () => {
      const asset = await Asset.fromModule(module).downloadAsync();
      const uri = asset.localUri ?? asset.uri;
      const encoded =
        Platform.OS !== 'web' && uri.startsWith('file:')
          ? await new File(uri).base64()
          : base64(new Uint8Array(await (await fetch(uri)).arrayBuffer()));
      return 'data:image/png;base64,' + encoded;
    })().catch((error) => {
      bundled.delete(module);
      throw error;
    });
    bundled.set(module, pending);
  }
  return pending;
}

export async function loadLegendPosterArtwork(townHall: number): Promise<LegendPosterArtwork> {
  fonts ??= Font.loadAsync({
    'Blogger Sans': require('../../../assets/clashking/legend-poster/blogger.ttf'),
    'Supercell-Magic': require('../../../assets/clashking/legend-poster/clash.ttf'),
  }).catch((error) => {
    fonts = undefined;
    throw error;
  });
  const keys = {
    sword: legendPosterAssets.sword,
    shield: legendPosterAssets.shield,
    trophy: legendPosterAssets.trophy,
    league: legendPosterAssets.legend,
    star: legendPosterAssets.star,
    logo: legendPosterAssets.clashking,
    prince: legendPosterAssets['league-prince'],
    heart: legendPosterAssets.heart,
  };
  const [entries, hallImage] = await Promise.all([
    Promise.all(
      Object.entries(keys).map(async ([key, module]) => [key, await bundledImage(module)] as const),
    ),
    Number.isInteger(townHall) && townHall >= 1 && townHall <= 18
      ? bundledImage(legendPosterAssets[`th${townHall}` as keyof typeof legendPosterAssets])
      : Promise.resolve(undefined),
    fonts,
  ]);
  return { ...Object.fromEntries(entries), hallImage, favoriteImages: {} } as LegendPosterArtwork;
}

/** Embed optional network artwork so a later image capture cannot race its download. */
export async function optionalLegendPosterImage(
  url: string | undefined,
): Promise<string | undefined> {
  if (!url) return undefined;
  for (const candidate of mobileWebImageCandidates(url, [])) {
    try {
      const response = await fetch(candidate, {
        signal: AbortSignal.timeout(4000),
        headers: badgeRequestHeaders(candidate, Platform.OS),
      });
      const type = response.headers.get('content-type')?.split(';')[0] ?? '';
      if (
        !response.ok ||
        !/^image\/(png|webp|jpeg|avif)$/.test(type) ||
        Number(response.headers.get('content-length')) > 4_000_000
      )
        continue;
      const bytes = new Uint8Array(await response.arrayBuffer());
      if (bytes.length > 4_000_000) continue;
      return `data:${type};base64,${base64(bytes)}`;
    } catch {
      /* A missing optional badge/favorite must not block the poster. */
    }
  }
  return undefined;
}
