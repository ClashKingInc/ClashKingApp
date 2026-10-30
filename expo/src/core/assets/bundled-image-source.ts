import { Asset } from 'expo-asset';

const sources = new Map<string, number>();

/** Preserve the module identity when an existing image API needs a URL.
 * Native OTA assets must resolve through their module, not fetch the original
 * packager/build URL returned by Asset.uri. */
export function bundledImageUrl(source: number): string {
  const asset = Asset.fromModule(source);
  // In an OTA launch uri can be empty while localUri holds the installed file.
  // Never register an empty key: unrelated bundled modules would collide.
  const uri = asset.localUri || asset.uri || `bundled-asset:${source}`;
  sources.set(uri, source);
  return uri;
}
export function bundledImageSource(uri: string): number | undefined {
  return sources.get(uri);
}
