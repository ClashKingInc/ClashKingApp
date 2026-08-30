import {
  applyGameTranslations,
  hasTranslationsForLocale,
  localizedInfoForItem,
  localizedNameForItem,
  localizedNameForItemOrFallback,
  localizedNameForTidOrFallback,
} from './game-data-localization';
import {
  applyGameDataBundle,
  normalizeGameDataBundle,
  warLeaguesByApiId,
} from './game-data-normalization';
import { getMaxTownHallLevel, isPet, isSiegeMachine, isSuperTroop } from './game-data-service';
import {
  gameDataState,
  resetGameDataStateForTesting,
  subscribeToGameDataRevision,
} from './game-data-state';

beforeEach(resetGameDataStateForTesting);

describe('Flutter GameDataService normalization parity', () => {
  test('prefers a non-seasonal duplicate troop for the base item key', () => {
    applyGameDataBundle({
      troops: [
        {
          name: 'Meteor Golem',
          village: 'home',
          is_seasonal: true,
          levels: [{ level: 1 }],
        },
        {
          name: 'Meteor Golem',
          village: 'home',
          levels: [{ level: 1 }],
        },
      ],
    });

    const troops = gameDataState.troopsData.troops as Record<string, Record<string, unknown>>;
    expect(troops['Meteor Golem']?.is_seasonal).not.toBe(true);
    expect(troops['Meteor Golem']?.url).toBe(
      'https://assets.clashk.ing/troops/meteor_golem/icon.webp',
    );
    expect(troops['Meteor Golem 2']?.is_seasonal).toBe(true);
  });

  test('uses official game translations for supported UI locales', () => {
    applyGameDataBundle({
      war_leagues: [
        {
          _id: 48_000_007,
          name: 'Gold League III',
          TID: { name: 'TID_LEAGUE_GOLD3' },
        },
      ],
    });
    applyGameTranslations(
      {
        TID_LEAGUE_GOLD3: { DE: 'Gold-Liga III' },
        TID_GOLD: { DE: 'Gold' },
      },
      'DE',
    );

    const leagues = gameDataState.warLeagueData.leagues as Record<string, Record<string, unknown>>;
    expect(
      localizedNameForItemOrFallback(
        leagues['Gold League III'],
        { languageCode: 'de' },
        'Gold III',
      ),
    ).toBe('Gold-Liga III');
    expect(localizedNameForTidOrFallback('TID_GOLD', { languageCode: 'de' }, 'Goldvorrat')).toBe(
      'Gold',
    );
  });

  test('indexes war leagues using one-less public API IDs', () => {
    applyGameDataBundle({
      war_leagues: [
        { _id: 48_000_007, name: 'Gold League III' },
        { _id: 48_000_019, name: 'Titan League III' },
      ],
    });
    expect(warLeaguesByApiId().get(48_000_006)?.name).toBe('Gold League III');
    expect(warLeaguesByApiId().get(48_000_018)?.name).toBe('Titan League III');
  });

  test('keeps the ARB fallback when Clash lacks the app locale', () => {
    applyGameTranslations({ TID_LEAGUE_GOLD3: { EN: 'Gold League III' } }, 'EN');
    const locale = { languageCode: 'cs' };
    expect(hasTranslationsForLocale(locale)).toBe(false);
    expect(
      localizedNameForItemOrFallback(
        {
          name: 'Gold League III',
          TID: { name: 'TID_LEAGUE_GOLD3' },
        },
        locale,
        'Zlato III',
      ),
    ).toBe('Zlato III');
  });

  test('preserves a raw legacy bundle if any legacy section is present', () => {
    const raw = { pets_data: { pets: { LASSI: { name: 'LASSI' } } }, troops: [] };
    expect(normalizeGameDataBundle(raw)).toBe(raw);
    applyGameDataBundle(raw);
    expect(gameDataState.petsData).toEqual(raw.pets_data);
    expect(gameDataState.troopsData).toEqual({});
  });

  test('derives max levels, item types, URLs, categories, and helper results', () => {
    applyGameDataBundle({
      buildings: [{ name: 'Town Hall', levels: [{ level: 15 }, { level: 17.9 }] }],
      pets: [{ name: 'L.A.S.S.I', levels: [{ level: 10 }] }],
      troops: [
        { name: 'Super Wizard', levels: [{ level: 12 }] },
        { name: 'Battle Drill', production_building: 'Workshop' },
        { name: 'Raged Barbarian', village: 'builderBase' },
      ],
      heroes: [{ name: 'Battle Machine', village: 'builderBase' }],
      spells: [{ name: 'Rage Spell' }],
      equipment: [{ name: 'Giant Gauntlet' }],
    });

    const troops = gameDataState.troopsData.troops as Record<string, Record<string, unknown>>;
    expect(troops['Super Wizard']).toMatchObject({
      maxLevel: 12,
      type: 'super-troop',
    });
    expect(isSuperTroop('Super Wizard')).toBe(true);
    expect(isSiegeMachine('Battle Drill')).toBe(true);
    expect(isPet('L.A.S.S.I')).toBe(true);
    expect(getMaxTownHallLevel()).toBe(17);
    expect(gameDataState.gameData.categories).toEqual([
      'buildings',
      'pets',
      'troops',
      'heroes',
      'spells',
      'equipment',
    ]);
    const pets = gameDataState.petsData.pets as Record<string, { url: string }>;
    expect(pets['L.A.S.S.I']?.url).toBe('https://assets.clashk.ing/pets/lassi/icon.webp');
  });

  test('notifies revision subscribers on every applied bundle', () => {
    const revisions: number[] = [];
    const unsubscribe = subscribeToGameDataRevision((revision) => revisions.push(revision));
    applyGameDataBundle({ troops: [] });
    applyGameDataBundle({ troops: [] });
    unsubscribe();
    applyGameDataBundle({ troops: [] });
    expect(revisions).toEqual([1, 2]);
    expect(gameDataState.revision).toBe(3);
  });

  test('localization helpers preserve item fallbacks and ignore blank catalog values', () => {
    const item = {
      name: 'Archer Queen',
      info: 'Original info',
      TID: { name: 'NAME', info: 'INFO' },
    };
    applyGameTranslations({ NAME: { DE: 'Bogenschützenkönigin' }, INFO: '' }, 'DE');
    expect(localizedNameForItem(item)).toBe('Bogenschützenkönigin');
    expect(localizedInfoForItem(item)).toBe('');
    expect(localizedNameForTidOrFallback('INFO', { languageCode: 'de' }, 'Info')).toBe('Info');
  });
});
