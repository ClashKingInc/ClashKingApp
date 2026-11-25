import { ASSET_ORIGIN, resolveAssetUrl, assetPath } from './asset-origin';
export const ASSET_MANIFEST_URL = `${ASSET_ORIGIN}/manifest.json`;
export interface ManifestImage { readonly sha: string; readonly animated: boolean }
export interface ManifestDataEntry { path: string; sha: string }
export function isManifestSha(sha: unknown): sha is string {
  return typeof sha === 'string' && /^[a-f0-9]{64}$/.test(sha);
}

function validImagePath(path: unknown): path is string {
  return typeof path === 'string' && path.split('/').every((part) => part && part !== '.' && part !== '..');
}

export function manifestTranslations(entries: unknown): ManifestDataEntry[] {
  return manifestEntries(entries, /^translations\/[A-Z]{2,8}\.json$/);
}

function manifestEntries(entries: unknown, pattern: RegExp): ManifestDataEntry[] {
  if (!Array.isArray(entries)) throw new Error('Invalid manifest data index');
  const seen = new Set<string>();
  for (const item of entries) {
    if (!item || typeof item.path !== 'string' || !pattern.test(item.path) || seen.has(item.path) ||
      !isManifestSha(item.sha)) throw new Error('Invalid manifest data index');
    seen.add(item.path);
  }
  return entries;
}

export function manifestData(value: Record<string, unknown>): { stats: ManifestDataEntry[]; translations: ManifestDataEntry[] } {
  const data = value.data as Record<string, unknown> | undefined;
  if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('Invalid manifest data index');
  const stats = manifestEntries(data.stats, /^static_data\/[a-z_]+\.json$/);
  if (!stats.length) throw new Error('Empty static data index');
  return { stats, translations: manifestTranslations(data.translations) };
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
      if (!item || !validImagePath(item.path) || !isManifestSha(item.sha) ||
        typeof item.animated !== 'boolean' ||
      (item.path.includes('/') ? item.path.split('/')[0] : 'other') !== category || next.has(item.path))
      throw new Error('Invalid manifest image');
    next.set(item.path, { sha: item.sha, animated: item.animated });
    }
  }
  manifestData(value);
  return next;
}

export function applyAssetManifest(value: Record<string, unknown>): void {
  installImageManifest(validateAssetManifest(value));
}

export function readImageCatalog(value: Record<string, unknown>): Map<string, ManifestImage> {
  if (!Array.isArray(value.images)) throw new Error('Invalid image catalog');
  const next = new Map<string, ManifestImage>();
  for (const entry of value.images) {
    if (!Array.isArray(entry) || !validImagePath(entry[0]) || !isManifestSha(entry[1]) ||
      (entry.length !== 2 && (entry.length !== 3 || entry[2] !== 1)) || next.has(entry[0]))
      throw new Error('Invalid image catalog entry');
    next.set(entry[0], { sha: entry[1], animated: entry[2] === 1 });
  }
  return next;
}

export function installImageManifest(next: Map<string, ManifestImage>): void {
  if (next.size === images.size && [...next].every(([key, item]) =>
    images.get(key)?.sha === item.sha && images.get(key)?.animated === item.animated)) return;
  images = next;
  revision += 1;
  for (const listener of listeners) listener();
}

export function manifestImage(url: string): ManifestImage | undefined {
  url = resolveAssetUrl(url);
  if (!url.startsWith(`${ASSET_ORIGIN}/`)) return undefined;
  try { return images.get(assetPath(url)); }
  catch { return undefined; }
}

export function manifestImageVersion(path: string): string | undefined {
  return images.get(path)?.sha;
}

export function changedImagePaths(previous: Record<string, unknown>, next: Record<string, unknown>): string[] {
  const before = validateAssetManifest(previous);
  const after = validateAssetManifest(next);
  return [...before].filter(([path, image]) => after.get(path)?.sha !== image.sha ||
    after.get(path)?.animated !== image.animated).map(([path]) => path);
}
