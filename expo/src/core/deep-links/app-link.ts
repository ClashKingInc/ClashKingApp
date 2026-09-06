import { appRoutes, type AppRouteId } from '../../navigation/route-manifest';

export type AppLinkParams = Readonly<Record<string, string>>;
export type AppLink =
  | { kind: 'page'; page: AppRouteId; params: AppLinkParams }
  | {
      kind: 'player' | 'clan' | 'capital' | 'war' | 'cwl';
      tag: string;
      warId?: string;
      params: AppLinkParams;
    };

const hosts = new Set(['app.clashk.ing', 'staging-app.clashk.ing', 'dev-app.clashk.ing']);
const queryKeys = new Set([
  'tab',
  'player',
  'clan',
  'q',
  'type',
  'season',
  'day',
  'round',
  'audience',
  'section',
  'start',
  'end',
  'mode',
  'category',
  'format',
  'asset',
  'package',
  'question',
  'language',
  'location',
  'board',
  'period',
  'league',
  'townHall',
  'filter',
]);
const settingsSections = new Set(['notifications', 'faq', 'translation', 'privacy', 'licenses']);

export function appLinkTag(value: string | null | undefined): string | null {
  if (!value) return null;
  const tag = value.trim().replace(/^#/, '').toUpperCase();
  return /^[A-Z0-9]{1,20}$/.test(tag) ? `#${tag}` : null;
}

/** Public navigation only. Authentication URLs are owned by their existing handlers. */
export function parseAppLink(input: string): AppLink | null {
  try {
    const relative = input.startsWith('/') && !input.startsWith('//');
    const url = new URL(input, relative ? 'https://app.clashk.ing' : undefined);
    if (
      !relative &&
      url.protocol !== 'clashking:' &&
      !(url.protocol === 'https:' && hosts.has(url.hostname))
    )
      return null;
    if (url.username || url.password || url.port || url.hash) return null;
    const path = url.protocol === 'clashking:' ? `/${url.hostname}${url.pathname}` : url.pathname;
    const segments = path.split('/').filter(Boolean).map(decodeURIComponent);
    if (segments.some((part) => part.includes('/') || part.length > 200)) return null;
    if (segments[0] === 'auth' || segments[0] === 'oauth') return null;
    const params: Record<string, string> = {};
    for (const [key, value] of url.searchParams) {
      if (!queryKeys.has(key)) continue;
      if (value.length > 500 || /[\u0000-\u001f]/.test(value)) return null;
      params[key] = value;
    }
    for (const key of ['player', 'clan']) {
      if (params[key] !== undefined) {
        const tag = appLinkTag(params[key]);
        if (!tag) return null;
        params[key] = tag;
      }
    }
    for (const key of ['day', 'start', 'end']) {
      if (
        params[key] &&
        (!/^\d{4}-\d{2}-\d{2}$/.test(params[key]) ||
          Number.isNaN(Date.parse(params[key])) ||
          new Date(params[key]).toISOString().slice(0, 10) !== params[key])
      )
        return null;
    }
    if (params.season && !/^\d{4}-(0[1-9]|1[0-2])$/.test(params.season)) return null;
    if (params.round && !/^[1-7]$/.test(params.round)) return null;
    const [head, tagPart, detail, warId] = segments;
    if (head === 'player' || head === 'clan' || head === 'war') {
      // /war alone is the overview; old query-tag links remain supported.
      const rawTag =
        tagPart ??
        url.searchParams.get('tag') ??
        url.searchParams.get('player_tag') ??
        url.searchParams.get('clan_tag');
      if (head === 'war' && !rawTag && segments.length === 1)
        return { kind: 'page', page: 'war', params };
      const tag = appLinkTag(rawTag);
      if (!tag) return null;
      if (head !== 'clan') return segments.length <= 2 ? { kind: head, tag, params } : null;
      if (!detail) return { kind: 'clan', tag, params };
      if (detail !== 'capital' && detail !== 'war' && detail !== 'cwl') return null;
      if (warId && !/^\d{8}T\d{6}\.000Z$/.test(warId)) return null;
      if (segments.length > (detail === 'war' ? 4 : 3)) return null;
      return { kind: detail, tag, ...(warId ? { warId } : {}), params };
    }
    if (head === 'posts' && segments.length === 2)
      return { kind: 'page', page: 'posts', params: { ...params, postId: tagPart! } };
    if (head === 'settings' && segments.length === 2 && settingsSections.has(tagPart!))
      return { kind: 'page', page: 'settings', params: { ...params, section: tagPart! } };
    const route = appRoutes.find((route) => route.href === `/${segments.join('/')}`);
    return route ? { kind: 'page', page: route.id, params } : null;
  } catch {
    return null;
  }
}

export function appLinkPath(link: AppLink): string {
  let path: string;
  const params = { ...link.params };
  if (link.kind === 'page') {
    path = appRoutes.find((route) => route.id === link.page)!.href;
    if (link.page === 'posts' && params.postId) {
      path += `/${encodeURIComponent(params.postId)}`;
      delete params.postId;
    }
    if (link.page === 'settings' && params.section) {
      path += `/${encodeURIComponent(params.section)}`;
      delete params.section;
    }
  } else {
    const tag = encodeURIComponent(link.tag.replace(/^#/, ''));
    path =
      link.kind === 'player'
        ? `/player/${tag}`
        : `/clan/${tag}${link.kind === 'clan' ? '' : `/${link.kind}`}`;
    if (link.warId) path += `/${encodeURIComponent(link.warId)}`;
  }
  const query = new URLSearchParams(params).toString();
  return path + (query ? `?${query}` : '');
}
