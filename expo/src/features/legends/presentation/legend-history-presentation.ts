import type { PlayerLegendHistoryEntry } from '../../player/models/player-legend-history';

export type LegendHistoryBadge =
  | { readonly kind: 'source'; readonly imageUrl: string }
  | { readonly kind: 'named'; readonly name: string }
  | null;

export function legendHistoryBadge(season: PlayerLegendHistoryEntry): LegendHistoryBadge {
  for (const size of ['medium', 'large', 'small', 'tiny']) {
    const imageUrl = season.leagueIconUrls?.[size];
    if (imageUrl?.trim()) return { kind: 'source', imageUrl };
  }
  // The API interprets the stored ID within its season's system. The original
  // monthly league has its own badge; it must not become today's Legend I.
  const name = season.leagueNamespace !== null ? season.leagueName?.trim() : null;
  return name ? { kind: 'named', name } : null;
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
