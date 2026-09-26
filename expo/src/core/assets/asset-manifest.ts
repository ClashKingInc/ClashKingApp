export const ASSET_MANIFEST_URL = 'https://assets.clashk.ing/manifest.json';
export interface ManifestImage { readonly sha: string; readonly animated: boolean }
export interface ManifestDataEntry { path: string; sha: string }
export function manifestData(value: Record<string, unknown>): { stats: ManifestDataEntry[]; translations: ManifestDataEntry[] } {
  const data = value.data as Record<string, unknown> | undefined;
  if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('Invalid manifest data index');
  for (const [group, pattern] of Object.entries({ stats: /^static_data\/[a-z_]+\.json$/, translations: /^translations\/[A-Z]{2,8}\.json$/ })) {
    const entries = data[group];
    const seen = new Set<string>();
    if (!Array.isArray(entries) || (group === 'stats' && !entries.length)) throw new Error('Invalid manifest data index');
    for (const item of entries) {
      if (!item || typeof item.path !== 'string' || !pattern.test(item.path) || seen.has(item.path) ||
        typeof item.sha !== 'string' || !/^[a-f0-9]{64}$/.test(item.sha)) throw new Error('Invalid manifest data index');
      seen.add(item.path);
    }
  }
  return data as { stats: ManifestDataEntry[]; translations: ManifestDataEntry[] };
}
let images = new Map<string, ManifestImage>();
let revision = 0;
const listeners = new Set<() => void>();
export const subscribeAssetManifest = (listener: () => void) => {
  listeners.add(listener);
  return () => { listeners.delete(listener); };
};
export const assetManifestRevision = () => revision;

export function validateAssetManifest(value: Record<string, unknown>): Map<string, ManifestImage> {
  if (value.version !== 2 || !value.assets || typeof value.assets !== 'object' || Array.isArray(value.assets))
    throw new Error('Invalid asset manifest');
  const next = new Map<string, ManifestImage>();
  for (const [category, entries] of Object.entries(value.assets)) {
    if (!Array.isArray(entries)) throw new Error('Invalid manifest category');
    for (const item of entries) {
    if (!item || typeof item.path !== 'string' || typeof item.sha !== 'string' || !/^[a-f0-9]{64}$/.test(item.sha) ||
      typeof item.animated !== 'boolean' || item.path.split('/').some((part: string) => !part || part === '.' || part === '..') ||
      (item.path.includes('/') ? item.path.split('/')[0] : 'other') !== category || next.has(item.path))
      throw new Error('Invalid manifest image');
    next.set(item.path, { sha: item.sha, animated: item.animated });
    }
  }
  manifestData(value);
  return next;
}

export function applyAssetManifest(value: Record<string, unknown>): void {
  const next = validateAssetManifest(value);
  if (next.size === images.size && [...next].every(([key, item]) =>
    images.get(key)?.sha === item.sha && images.get(key)?.animated === item.animated)) return;
  images = next;
  revision += 1;
  for (const listener of listeners) listener();
}

export function manifestImage(url: string): ManifestImage | undefined {
  if (!url.startsWith('https://assets.clashk.ing/')) return undefined;
  try { return images.get(decodeURIComponent(new URL(url).pathname.slice(1))); }
  catch { return undefined; }
}

export function changedImagePaths(previous: Record<string, unknown>, next: Record<string, unknown>): string[] {
  const before = validateAssetManifest(previous);
  const after = validateAssetManifest(next);
  return [...before].filter(([path, image]) => after.get(path)?.sha !== image.sha ||
    after.get(path)?.animated !== image.animated).map(([path]) => path);
}
