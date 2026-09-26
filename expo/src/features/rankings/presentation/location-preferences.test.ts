import { RankingLocation } from '../models';
import {
  normalizeLocationPreferences,
  orderedLocations,
  readLocationPreferences,
  selectRecentLocation,
  toggleStarredLocation,
  writeLocationPreferences,
} from './location-preferences';

const worldwide = RankingLocation.worldwide();
const countries = Array.from(
  { length: 8 },
  (_, index) =>
    new RankingLocation(
      index + 1,
      `Country ${index + 1}`,
      true,
      String.fromCharCode(65 + index, 65 + index),
    ),
);
const locations = [worldwide, ...countries, new RankingLocation(99, 'Region', false)];

test('normalizes malformed, missing, duplicated, and invalid saved locations', () => {
  expect(normalizeLocationPreferences(null, locations)).toEqual({ starred: [], recent: [] });
  expect(
    normalizeLocationPreferences(
      {
        starred: ['1', '1', '99', 2, 'global'],
        recent: ['1', '2', '2', '3', '4', '5', '6', '7', '99'],
      },
      locations,
    ),
  ).toEqual({
    starred: ['1', 'global'],
    recent: ['2', '3', '4', '5', '6'],
  });
});

test('puts starred locations first, followed by five unique unstarred recent locations', () => {
  const preferences = normalizeLocationPreferences(
    { starred: ['4', '2'], recent: ['3', '4', '6', '5', '1', '7'] },
    locations,
  );
  expect(
    orderedLocations(locations, preferences)
      .map((location) => location.apiPath)
      .slice(0, 8),
  ).toEqual(['4', '2', '3', '6', '5', '1', '7', 'global']);
  expect(
    new Set(orderedLocations(locations, preferences).map((location) => location.apiPath)).size,
  ).toBe(9);
});

test('recent selection is bounded and starring removes a location from recent', () => {
  let preferences = normalizeLocationPreferences(
    { starred: [], recent: ['1', '2', '3', '4', '5'] },
    locations,
  );
  preferences = selectRecentLocation(preferences, countries[5]!);
  expect(preferences.recent).toEqual(['6', '1', '2', '3', '4']);
  preferences = selectRecentLocation(preferences, countries[1]!);
  expect(preferences.recent).toEqual(['2', '6', '1', '3', '4']);
  preferences = toggleStarredLocation(preferences, countries[1]!);
  expect(preferences).toEqual({ starred: ['2'], recent: ['6', '1', '3', '4'] });
  expect(selectRecentLocation(preferences, countries[1]!)).toBe(preferences);
});

test('loads and writes through the existing string preference store, ignoring corruption', async () => {
  const values = new Map<string, string>();
  const storage = {
    getString: async (key: string) => values.get(key) ?? null,
    setString: async (key: string, value: string) => {
      values.set(key, value);
    },
  };
  expect(await readLocationPreferences(storage, locations)).toEqual({ starred: [], recent: [] });
  await writeLocationPreferences(storage, { starred: ['2'], recent: ['3'] });
  expect(await readLocationPreferences(storage, locations)).toEqual({
    starred: ['2'],
    recent: ['3'],
  });
  values.set('rankings_location_preferences_v1', '{bad');
  expect(await readLocationPreferences(storage, locations)).toEqual({ starred: [], recent: [] });
});
