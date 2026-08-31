import { ImageAssets } from '../../core/assets/image-assets';

export type SearchMode = 'players' | 'clans';
export type RecentSearchType = 'player' | 'clan';
export type JsonRecord = Record<string, unknown>;

export interface ClanSearchFilters {
  readonly warFrequency: string | null;
  readonly locationId: number | null;
  readonly minMembers: number | null;
  readonly maxMembers: number | null;
  readonly minClanPoints: number | null;
  readonly minClanLevel: number | null;
}

export interface PlayerSearchFilters {
  readonly leagueIds: readonly number[];
  readonly minTownHallLevel: number | null;
  readonly maxTownHallLevel: number | null;
}

export const emptyClanSearchFilters: ClanSearchFilters = Object.freeze({
  warFrequency: null,
  locationId: null,
  minMembers: null,
  maxMembers: null,
  minClanPoints: null,
  minClanLevel: null,
});

export const emptyPlayerSearchFilters: PlayerSearchFilters = Object.freeze({
  leagueIds: [],
  minTownHallLevel: null,
  maxTownHallLevel: null,
});

export function normalizeClanSearchFilters(value: ClanSearchFilters): ClanSearchFilters {
  return value.minClanPoints === null ? value : { ...value, minClanPoints: null };
}

export function isClanSearchFiltersEmpty(value: ClanSearchFilters): boolean {
  return Object.values(normalizeClanSearchFilters(value)).every((field) => field === null);
}

export function isPlayerSearchFiltersEmpty(value: PlayerSearchFilters): boolean {
  return (
    value.leagueIds.length === 0 &&
    value.minTownHallLevel === null &&
    value.maxTownHallLevel === null
  );
}

export function clanSearchQuerySuffix(value: ClanSearchFilters): string {
  return Object.entries(normalizeClanSearchFilters(value))
    .filter((entry): entry is [string, string | number] => entry[1] !== null)
    .map(([key, field]) => `&${key}=${field}`)
    .join('');
}

export function playerTownHallLevels(value: PlayerSearchFilters): readonly number[] {
  if (value.minTownHallLevel === null && value.maxTownHallLevel === null) return [];
  const minimum = value.minTownHallLevel ?? 1;
  const maximum = value.maxTownHallLevel ?? 18;
  if (minimum > maximum) return [];
  return Array.from({ length: maximum - minimum + 1 }, (_, index) => minimum + index);
}

export interface RecentSearchItem {
  readonly type: RecentSearchType;
  readonly name: string;
  readonly tag: string;
  readonly createdAt: Date;
  readonly imageUrl: string | null;
  readonly clanName: string | null;
  readonly leagueName: string | null;
  readonly members: number;
}

export function decodeRecentSearches(value: unknown): readonly RecentSearchItem[] {
  if (!isRecord(value)) return [];
  return [...decodeRecentGroup(value.players, 'player'), ...decodeRecentGroup(value.clans, 'clan')]
    .sort((left, right) => right.createdAt.getTime() - left.createdAt.getTime())
    .slice(0, 10);
}

function decodeRecentGroup(value: unknown, type: RecentSearchType): RecentSearchItem[] {
  if (!Array.isArray(value)) return [];
  return value.flatMap((item) => {
    if (!isRecord(item)) return [];
    const tag = stringValue(item.tag);
    if (!tag) return [];
    const badgeUrls = recordValue(item.badgeUrls);
    const clan = recordValue(item.clan);
    const league = recordValue(item.league);
    const townHallLevel = numberValue(item.townHallLevel, 1);
    return [
      {
        type,
        name: stringValue(item.name) || tag,
        tag,
        createdAt: validDate(item.created_at),
        imageUrl:
          type === 'clan' ? smallestBadgeUrl(badgeUrls) : ImageAssets.townHall(townHallLevel),
        clanName: type === 'player' ? nullableString(clan.name) : null,
        leagueName: type === 'player' ? nullableString(league.name) : null,
        members: type === 'clan' ? numberValue(item.members) : 0,
      },
    ];
  });
}

function smallestBadgeUrl(badgeUrls: JsonRecord): string | null {
  return (
    nullableString(badgeUrls.small) ??
    nullableString(badgeUrls.medium) ??
    nullableString(badgeUrls.large)
  );
}

export interface SearchLocation {
  readonly id: number;
  readonly name: string;
  readonly countryCode: string;
}

export interface SearchLeague {
  readonly id: number;
  readonly name: string;
}

export function decodeSearchLocations(value: unknown): readonly SearchLocation[] {
  if (!isRecord(value) || !Array.isArray(value.items)) return [];
  return value.items
    .flatMap((item) => {
      if (!isRecord(item)) return [];
      const id = numberValue(item.id);
      const countryCode = stringValue(item.countryCode).trim();
      const isCountry = item.isCountry === true;
      if (!id || !isCountry || !/^[A-Za-z]{2}$/.test(countryCode)) return [];
      return [{ id, name: stringValue(item.name).trim(), countryCode: countryCode.toUpperCase() }];
    })
    .sort((left, right) => left.name.localeCompare(right.name));
}

export function decodeSearchLeagues(value: unknown): readonly SearchLeague[] {
  if (!isRecord(value) || !Array.isArray(value.items)) return [];
  return value.items
    .flatMap((item) => {
      if (!isRecord(item)) return [];
      const id = numberValue(item.id);
      const name = stringValue(item.name);
      return id && name ? [{ id, name }] : [];
    })
    .sort((left, right) => right.id - left.id);
}

export function isRecord(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function recordValue(value: unknown): JsonRecord {
  return isRecord(value) ? value : {};
}

export function stringValue(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

export function nullableString(value: unknown): string | null {
  const result = stringValue(value);
  return result || null;
}

export function numberValue(value: unknown, fallback = 0): number {
  return typeof value === 'number' && Number.isFinite(value) ? Math.trunc(value) : fallback;
}

function validDate(value: unknown): Date {
  const date = new Date(stringValue(value));
  return Number.isNaN(date.getTime()) ? new Date(0) : date;
}
