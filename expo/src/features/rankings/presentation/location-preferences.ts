import type { StringStorage } from '../../../core/storage/storage';
import type { RankingLocation } from '../models';

const key = 'rankings_location_preferences_v1';

export interface LocationPreferences {
  readonly starred: readonly string[];
  readonly recent: readonly string[];
}

export const emptyLocationPreferences: LocationPreferences = { starred: [], recent: [] };

function uniqueValid(values: unknown, valid: ReadonlySet<string>): string[] {
  if (!Array.isArray(values)) return [];
  return [
    ...new Set(
      values.filter((value): value is string => typeof value === 'string' && valid.has(value)),
    ),
  ];
}

export function normalizeLocationPreferences(
  value: unknown,
  locations: readonly RankingLocation[],
): LocationPreferences {
  const valid = new Set(
    locations
      .filter((location) => location.isWorldwide || location.hasValidCountryCode)
      .map((location) => location.apiPath),
  );
  if (!value || typeof value !== 'object' || Array.isArray(value)) return emptyLocationPreferences;
  const stored = value as Record<string, unknown>;
  const starred = uniqueValid(stored.starred, valid);
  const recent = uniqueValid(stored.recent, valid)
    .filter((id) => !starred.includes(id))
    .slice(0, 5);
  return { starred, recent };
}

export function orderedLocations(
  locations: readonly RankingLocation[],
  preferences: LocationPreferences,
): RankingLocation[] {
  const available = new Map(
    locations
      .filter((location) => location.isWorldwide || location.hasValidCountryCode)
      .map((location) => [location.apiPath, location]),
  );
  const ordered = [...preferences.starred, ...preferences.recent, ...available.keys()];
  return [...new Set(ordered)]
    .map((id) => available.get(id))
    .filter((location): location is RankingLocation => Boolean(location));
}

export function selectRecentLocation(
  preferences: LocationPreferences,
  location: RankingLocation,
): LocationPreferences {
  const id = location.apiPath;
  if (preferences.starred.includes(id)) return preferences;
  return {
    ...preferences,
    recent: [id, ...preferences.recent.filter((value) => value !== id)].slice(0, 5),
  };
}

export function toggleStarredLocation(
  preferences: LocationPreferences,
  location: RankingLocation,
): LocationPreferences {
  const id = location.apiPath;
  const starred = preferences.starred.includes(id)
    ? preferences.starred.filter((value) => value !== id)
    : [...preferences.starred, id];
  return { starred, recent: preferences.recent.filter((value) => value !== id) };
}

export async function readLocationPreferences(
  storage: Pick<StringStorage, 'getString'>,
  locations: readonly RankingLocation[],
): Promise<LocationPreferences> {
  try {
    const raw = await storage.getString(key);
    return normalizeLocationPreferences(raw ? JSON.parse(raw) : null, locations);
  } catch {
    return emptyLocationPreferences;
  }
}

export async function writeLocationPreferences(
  storage: Pick<StringStorage, 'setString'>,
  preferences: LocationPreferences,
): Promise<void> {
  await storage.setString(key, JSON.stringify(preferences));
}
