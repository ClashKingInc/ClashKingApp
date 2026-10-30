import { Asset } from 'expo-asset';
import { Image, type ImageRef } from 'expo-image';
import { Platform } from 'react-native';
import { ASSET_ORIGIN } from './asset-origin';

// Keep fixed page backgrounds bundled; a cached remote URL still needs URL
// resolution and a disk decode, neither of which belongs on the navigation path.
const landscapes = {
  'home-landscape.png': require('../../../assets/clashking/backgrounds/landscapes/home-landscape.webp'),
  'builder-landscape.png': require('../../../assets/clashking/backgrounds/landscapes/builder-landscape.webp'),
  'legend-landscape.png': require('../../../assets/clashking/backgrounds/landscapes/legend-landscape.webp'),
  'clan-landscape.png': require('../../../assets/clashking/backgrounds/landscapes/clan-landscape.webp'),
  'cwl-landscape.png': require('../../../assets/clashking/backgrounds/landscapes/cwl-landscape.webp'),
  'war-landscape.jpg': require('../../../assets/clashking/backgrounds/landscapes/war-landscape.webp'),
  'clan-capital-landscape.png': require('../../../assets/clashking/backgrounds/landscapes/clan-capital-landscape.webp'),
  'war-stats.png': require('../../../assets/clashking/backgrounds/landscapes/war-stats.webp'),
  'achievement-landscape.png': require('../../../assets/clashking/backgrounds/landscapes/achievement-landscape.webp'),
} satisfies Record<string, number>;

const headers: readonly number[] = [
  require('../../../assets/clashking/backgrounds/library-barbarians.webp'),
  require('../../../assets/clashking/backgrounds/assets-goblin-v2.webp'),
  require('../../../assets/clashking/backgrounds/player-electro-dragon-quiet-v3.webp'),
  require('../../../assets/clashking/backgrounds/clan-clearing-v5-dark.webp'),
  require('../../../assets/clashking/backgrounds/ranked-cloud-trophy-v1.webp'),
  require('../../../assets/clashking/backgrounds/legends-pekka-classic-v1.webp'),
  require('../../../assets/clashking/todo/builder-meeting.jpg'),
  require('../../../assets/clashking/tracker/builder-village-flat-roof.jpg'),
  require('../../../assets/clashking/war/war-wood-header.webp'),
  ...Object.values(landscapes),
  require('../../../assets/clashking/cwl/bronze.webp'),
  require('../../../assets/clashking/cwl/silver.webp'),
  require('../../../assets/clashking/cwl/gold.webp'),
  require('../../../assets/clashking/cwl/crystal.webp'),
  require('../../../assets/clashking/cwl/master.webp'),
  require('../../../assets/clashking/cwl/champion.webp'),
  require('../../../assets/clashking/cwl/titan.webp'),
  require('../../../assets/clashking/cwl/legend.webp'),
  require('../../../assets/clashking/competitive/esports-trophy-clean.png'),
  require('../../../assets/clashking/profile/profile-selected-banner.png'),
  require('../../../assets/clashking/backgrounds/blue.webp'),
  require('../../../assets/clashking/backgrounds/purple.webp'),
  require('../../../assets/clashking/backgrounds/green.webp'),
  require('../../../assets/clashking/backgrounds/red.webp'),
  require('../../../assets/clashking/backgrounds/fade-dark.png'),
  require('../../../assets/clashking/backgrounds/fade-light.png'),
  require('../../../assets/clashking/backgrounds/header-ranked.png'),
  require('../../../assets/clashking/backgrounds/header-atmosphere.png'),
  require('../../../assets/clashking/backgrounds/header-calculator.png'),
  require('../../../assets/clashking/backgrounds/header-calculator-disabled.png'),
];
const byUrl = new Map(
  headers.flatMap((source) => {
    const asset = Asset.fromModule(source);
    return [asset.localUri, asset.uri]
      .filter((uri): uri is string => Boolean(uri))
      .map((uri) => [uri, source] as const);
  }),
);
// Decode the common first destinations; fetch the remaining bundled files
// without pinning every possible page's bitmap in memory at launch.
const firstDestinations = new Set([
  ...headers.slice(2, 9),
  landscapes['home-landscape.png'],
  landscapes['clan-capital-landscape.png'],
  require('../../../assets/clashking/profile/profile-selected-banner.png'),
]);
for (const [name, source] of Object.entries(landscapes)) {
  byUrl.set(`${ASSET_ORIGIN}/landscape/${name}`, source);
  byUrl.set(`https://assets.clashk.ing/landscape/${name}`, source);
}

export function headerArtworkForUrl(url: string): number | undefined {
  return byUrl.get(url);
}

const MAX_BYTES = 48 * 1024 * 1024;
const decoded = new Map<number, { image: ImageRef; bytes: number }>();
const pending = new Map<number, Promise<void>>();
const listeners = new Set<() => void>();
let bytes = 0;
let generation = 0;
let warmup: Promise<void> | undefined;
export const subscribeHeaderArtwork = (listener: () => void) => {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
};
export const decodedHeaderArtwork = (source: number): ImageRef | undefined =>
  decoded.get(source)?.image;

export function prepareHeaderArtwork(source: number): Promise<void> {
  const cached = decoded.get(source);
  if (cached) {
    decoded.delete(source);
    decoded.set(source, cached);
    return Promise.resolve();
  }
  const existing = pending.get(source);
  if (existing) return existing;
  const expected = generation;
  const load = (async () => {
    try {
      if (Platform.OS === 'web') {
        await Image.prefetch(Asset.fromModule(source).uri);
        return;
      }
      const image = await Image.loadAsync(source, { maxWidth: 1280, maxHeight: 768 });
      if (expected !== generation) return;
      const cost = image.width * image.height * image.scale * image.scale * 4;
      // Keep decoded images ready to draw, but never retain every full-sized
      // landscape indefinitely. Evicted pages still use their bundled file.
      while (bytes + cost > MAX_BYTES && decoded.size) {
        const oldest = decoded.keys().next().value!;
        bytes -= decoded.get(oldest)!.bytes;
        decoded.delete(oldest);
      }
      if (cost <= MAX_BYTES) {
        decoded.set(source, { image, bytes: cost });
        bytes += cost;
        for (const listener of listeners) listener();
      }
    } catch {
      // Artwork warmup is optional. The view can load the bundled source and
      // a later visit may retry; a failed image must never block the app.
    }
  })().finally(() => {
    if (expected === generation) pending.delete(source);
  });
  pending.set(source, load);
  return load;
}

/** Starts during startup; never await this from navigation or the splash gate. */
export function warmHeaderArtwork(): Promise<void> {
  warmup ??= (async () => {
    let index = 0;
    const worker = async () => {
      while (index < headers.length) {
        const source = headers[index++]!;
        if (firstDestinations.has(source)) await prepareHeaderArtwork(source);
        else
          await Image.prefetch(Asset.fromModule(source).uri, { cachePolicy: 'disk' }).catch(
            () => false,
          );
      }
    };
    await Promise.all([worker(), worker()]);
  })();
  return warmup;
}

export function clearHeaderArtworkCache(): void {
  generation++;
  decoded.clear();
  pending.clear();
  warmup = undefined;
  bytes = 0;
  for (const listener of listeners) listener();
}
