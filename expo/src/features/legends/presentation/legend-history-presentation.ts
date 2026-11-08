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
  // Bounds are used for historical calculations, not the card heading. Keep
  // monthly IDs as month/year and dated season IDs as a single finish date.
  const monthly = /^\d{4}-\d{2}$/u.test(season.season);
  const value = monthly
    ? `${season.season}-01T00:00:00Z`
    : season.season.replace(/^v2-/u, '');
  const date = new Date(value);
  if (!Number.isFinite(date.valueOf())) return season.season;
  return new Intl.DateTimeFormat(locale, {
    month: 'long', year: 'numeric', ...(monthly ? {} : { day: 'numeric' }), timeZone: 'UTC',
  }).format(date);
}
