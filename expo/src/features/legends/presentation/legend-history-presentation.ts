import type { PlayerLegendHistoryEntry } from '../../player/models/player-legend-history';

export type LegendHistoryBadge =
  | { readonly kind: 'source'; readonly imageUrl: string }
  | { readonly kind: 'tier'; readonly name: string }
  | null;

export function legendHistoryBadge(season: PlayerLegendHistoryEntry): LegendHistoryBadge {
  for (const size of ['medium', 'large', 'small', 'tiny']) {
    const imageUrl = season.leagueIconUrls?.[size];
    if (imageUrl?.trim()) return { kind: 'source', imageUrl };
  }
  // A recorded tier name may resolve to the matching game asset. A date or
  // reused legacy category cannot identify today's Legend I/II badge.
  const name = season.leagueNamespace === 'tier' ? season.leagueName?.trim() : null;
  return name ? { kind: 'tier', name } : null;
}

export function formatLegendHistorySeason(season: PlayerLegendHistoryEntry, locale: string): string {
  const start = season.seasonStart;
  const end = season.seasonEnd;
  if (!start || !end || !Number.isFinite(start.valueOf()) || !Number.isFinite(end.valueOf()))
    return season.season;
  const format = new Intl.DateTimeFormat(locale, {
    month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC',
  });
  return typeof format.formatRange === 'function'
    ? format.formatRange(start, end)
    : `${format.format(start)} – ${format.format(end)}`;
}
