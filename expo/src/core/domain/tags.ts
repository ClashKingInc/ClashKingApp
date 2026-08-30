/** Mirrors the canonical tag keys used by Flutter caches and repositories. */
export function normalizeTag(tag: string): string {
  return tag.replaceAll('#', '').trim().toUpperCase();
}

/** Produces the official API form while preserving an empty tag as empty. */
export function canonicalTag(tag: string): string {
  const normalized = normalizeTag(tag);
  return normalized.length === 0 ? '' : `#${normalized}`;
}

export function encodeTagPathSegment(tag: string): string {
  return encodeURIComponent(canonicalTag(tag));
}
