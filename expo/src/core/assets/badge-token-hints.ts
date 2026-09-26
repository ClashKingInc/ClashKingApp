const tokens = new Map<string, string>();
const normalizeTag = (tag: string) => tag.trim().replace(/^#/, '').toUpperCase();
const validToken = (value: unknown): value is string =>
  typeof value === 'string' && value !== 'null' && /^[A-Za-z0-9_-]{1,512}$/.test(value);

/** Accept only the owning API clan's token or an exact official badge URL. */
export function rememberBadgeToken(tag: string, source: unknown): void {
  const normalized = normalizeTag(tag);
  if (!/^[A-Z0-9]+$/.test(normalized) || !source || typeof source !== 'object') return;
  const data = source as Record<string, unknown>;
  if (typeof data.tag === 'string' && normalizeTag(data.tag) !== normalized) return;
  let token = validToken(data.badgeToken) ? data.badgeToken : undefined;
  const badges = data.badgeUrls && typeof data.badgeUrls === 'object'
    ? data.badgeUrls as Record<string, unknown> : data;
  if (!token) {
    for (const value of [badges.small, badges.medium, badges.large]) {
      if (typeof value !== 'string') continue;
      try {
        const url = new URL(value);
        if (url.origin !== 'https://api-assets.clashofclans.com' || url.username || url.password || url.search || url.hash) continue;
        const match = /^\/badges\/(70|200|512)\/([A-Za-z0-9_-]+)\.png$/.exec(url.pathname);
        if (match && validToken(match[2])) { token = match[2]; break; }
      } catch { /* No hint for malformed URLs. */ }
    }
  }
  if (!token) return;
  tokens.delete(normalized);
  tokens.set(normalized, token);
  if (tokens.size > 2048) tokens.delete(tokens.keys().next().value!);
}

export function badgeRequestHeaders(url: string, platform: string): Record<string, string> | undefined {
  if (platform === 'web') return;
  try {
    const parsed = new URL(url);
    if (parsed.origin !== 'https://badges.clashk.ing' || parsed.username || parsed.password) return;
    const match = /^\/([A-Z0-9]+)\.(avif|png)$/.exec(parsed.pathname);
    const token = match ? tokens.get(match[1]!) : undefined;
    return token ? { 'X-ClashKing-Badge-Token': token } : undefined;
  } catch { return; }
}

export function badgeImageSource(url: string, platform: string) {
  const headers = badgeRequestHeaders(url, platform);
  return { uri: url, ...(headers ? { headers, cacheKey: url } : {}) };
}
