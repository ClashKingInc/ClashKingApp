export const ASSET_MANIFEST_URL = 'https://assets.clashk.ing/manifest.json';
export interface ManifestImage { readonly sha: string; readonly animated: boolean }
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
  if (!Array.isArray(value.data) || value.data.length === 0 || value.data.some((item) =>
    !item || typeof item.path !== 'string' || !/^(static_data\/[a-z_]+|translations\/[A-Z]{2,8})\.json$/.test(item.path) ||
    typeof item.sha !== 'string' || !/^[a-f0-9]{64}$/.test(item.sha)))
    throw new Error('Invalid manifest data index');
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
