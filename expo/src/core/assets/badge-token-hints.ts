const tokens = new Map<string, string>();
const listeners = new Set<() => void>();
let notificationQueued = false;
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
  const badges =
    data.badgeUrls && typeof data.badgeUrls === 'object'
      ? (data.badgeUrls as Record<string, unknown>)
      : data;
  if (!token) {
    for (const value of [badges.small, badges.medium, badges.large, data.badgeUrl, data.badge]) {
      if (typeof value !== 'string') continue;
      try {
        const url = new URL(value);
        if (
          url.origin !== 'https://api-assets.clashofclans.com' ||
          url.username ||
          url.password ||
          url.search ||
          url.hash
        )
          continue;
        const match = /^\/badges\/(70|200|512)\/([A-Za-z0-9_-]+)\.png$/.exec(url.pathname);
        if (match && validToken(match[2])) {
          token = match[2];
          break;
        }
      } catch {
        /* No hint for malformed URLs. */
      }
    }
  }
  if (!token) return;
  if (tokens.get(normalized) === token) return;
  tokens.delete(normalized);
  tokens.set(normalized, token);
  if (tokens.size > 2048) tokens.delete(tokens.keys().next().value!);
  // Models may register badge data while rendering. Notify after that render,
  // so already-mounted tag-only images can refresh without a React render update.
  if (!notificationQueued) {
    notificationQueued = true;
    queueMicrotask(() => {
      notificationQueued = false;
      listeners.forEach((listener) => listener());
    });
  }
}

export function subscribeBadgeTokens(listener: () => void): () => void {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}

export function badgeTokenForUrl(url: string): string | undefined {
  try {
    const parsed = new URL(url);
    if (parsed.origin !== 'https://badges.clashk.ing' || parsed.username || parsed.password) return;
    const match = /^\/([A-Z0-9]+)\.(avif|png)$/.exec(parsed.pathname);
    return match ? tokens.get(match[1]!) : undefined;
  } catch {
    return;
  }
}

export function badgeRequestHeaders(
  url: string,
  platform: string,
): Record<string, string> | undefined {
  if (platform === 'web') return;
  const token = badgeTokenForUrl(url);
  return token ? { 'X-ClashKing-Badge-Token': token, 'Cache-Control': 'no-cache' } : undefined;
}

export function badgeImageSource(url: string, platform: string) {
  const token = badgeTokenForUrl(url);
  // Browser image elements cannot attach the native hint header. Use the same
  // official token through our existing asset proxy, not a private query string.
  if (platform === 'web' && token) {
    return { uri: `https://assets-proxy.clashk.ing/badges/512/${token}.png` };
  }
  const headers = badgeRequestHeaders(url, platform);
  // A cached default shield is a successful image response. Version the local
  // image cache by badge identity so learning the token does not reuse it.
  return { uri: url, ...(headers ? { headers, cacheKey: `${url}:badge:${token}` } : {}) };
}
