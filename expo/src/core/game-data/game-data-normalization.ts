import {
  bumpGameDataRevision,
  gameDataState,
  isRecord,
  replaceGameDataSection,
  type JsonRecord,
} from './game-data-state';

export const GAME_ASSET_BASE_URL = 'https://assets.clashk.ing';

const SUPER_TROOP_NAMES = new Set([
  'Sneaky Goblin',
  'Rocket Balloon',
  'Inferno Dragon',
  'Super Valkyrie',
  'Ice Hound',
  'Super Witch',
  'Super Bowler',
  'Super Dragon',
  'Super Wizard',
  'Super Minion',
  'Super Hog Rider',
  'Super Yeti',
]);

export function applyGameDataBundle(rawBundle: JsonRecord): JsonRecord {
  const bundle = normalizeGameDataBundle(rawBundle);
  replaceGameDataSection(gameDataState.bundleData, bundle);
  replaceGameDataSection(gameDataState.petsData, bundle.pets_data);
  replaceGameDataSection(gameDataState.heroesData, bundle.heroes_data);
  replaceGameDataSection(gameDataState.troopsData, bundle.troops_data);
  replaceGameDataSection(gameDataState.spellsData, bundle.spells_data);
  replaceGameDataSection(gameDataState.gearsData, bundle.gears_data);
  replaceGameDataSection(gameDataState.leagueData, bundle.league_data);
  replaceGameDataSection(gameDataState.warLeagueData, bundle.war_leagues_data);
  replaceGameDataSection(gameDataState.playerLeagueData, bundle.player_league_data);
  replaceGameDataSection(gameDataState.gameData, bundle.game_data);
  bumpGameDataRevision();
  return bundle;
}

export function normalizeGameDataBundle(rawBundle: JsonRecord): JsonRecord {
  if (
    Object.hasOwn(rawBundle, 'pets_data') ||
    Object.hasOwn(rawBundle, 'heroes_data') ||
    Object.hasOwn(rawBundle, 'troops_data')
  ) {
    return rawBundle;
  }

  return {
    ...rawBundle,
    pets_data: {
      pets: itemsByName(rawBundle.pets, {
        urlResolver: (name) => assetUrl(['pets', assetSlug(name), 'icon.webp']),
      }),
    },
    heroes_data: {
      heroes: itemsByName(rawBundle.heroes, {
        typeResolver: (item) => (item.village === 'builderBase' ? 'bb-hero' : 'hero'),
        urlResolver: (name) => assetUrl(['heroes', assetSlug(name), 'icon.webp']),
      }),
    },
    troops_data: {
      troops: itemsByName(rawBundle.troops, {
        typeResolver: troopType,
        urlResolver: (name) => assetUrl(['troops', assetSlug(name), 'icon.webp']),
      }),
    },
    spells_data: {
      spells: itemsByName(rawBundle.spells, {
        urlResolver: (name) => assetUrl(['spells', `${assetSlug(name)}.webp`]),
      }),
    },
    gears_data: {
      gears: itemsByName(rawBundle.equipment, {
        urlResolver: (name) => assetUrl(['equipment', `${assetSlug(name)}.webp`]),
      }),
    },
    league_data: { leagues: itemsByName(rawBundle.league_tiers) },
    war_leagues_data: { leagues: itemsByName(rawBundle.war_leagues) },
    player_league_data: { leagues: itemsByName(rawBundle.league_tiers) },
    game_data: deriveGameData(rawBundle),
  };
}

export interface ItemNormalizationOptions {
  readonly typeResolver?: (item: JsonRecord) => string | null;
  readonly urlResolver?: (name: string, item: JsonRecord) => string;
}

export function itemsByName(section: unknown, options: ItemNormalizationOptions = {}): JsonRecord {
  if (isRecord(section)) return { ...section };
  if (!Array.isArray(section)) return {};

  const items: JsonRecord = {};
  const nameCounts = new Map<string, number>();
  for (const rawItem of section) {
    if (!isRecord(rawItem)) continue;
    const item = { ...rawItem };
    if (item.name === undefined || item.name === null) continue;
    const name = String(item.name);
    if (name.trim().length === 0) continue;

    const maximumLevel = maxLevel(item.levels);
    if (maximumLevel > 0) item.maxLevel = maximumLevel;
    const type = options.typeResolver?.(item);
    if (type !== undefined && type !== null) item.type = type;
    const url = options.urlResolver?.(name, item);
    if (url !== undefined && url.length > 0) item.url = url;

    const existingBaseItem = items[name];
    const seasonal = item.is_seasonal === true;
    if (isRecord(existingBaseItem) && existingBaseItem.is_seasonal === true && !seasonal) {
      items[nextDuplicateKey(name, nameCounts)] = existingBaseItem;
      items[name] = item;
      continue;
    }

    const key = Object.hasOwn(items, name) ? nextDuplicateKey(name, nameCounts) : name;
    if (!nameCounts.has(name)) nameCounts.set(name, 1);
    items[key] = item;
  }
  return items;
}

export function maxLevel(levels: unknown): number {
  if (!Array.isArray(levels)) return 0;
  let maximum = 0;
  for (const level of levels) {
    if (!isRecord(level) || typeof level.level !== 'number') continue;
    const value = Math.trunc(level.level);
    if (value > maximum) maximum = value;
  }
  return maximum;
}

export function troopType(item: JsonRecord): string {
  const name = item.name === undefined ? '' : String(item.name);
  if (item.production_building === 'Workshop') return 'siege-machine';
  if (item.village === 'builderBase') return 'bb-troop';
  if (SUPER_TROOP_NAMES.has(name) || name.startsWith('Super ')) {
    return 'super-troop';
  }
  return 'troop';
}

export function assetSlug(name: string): string {
  return name.trim().toLowerCase().replaceAll(' ', '_').replaceAll('.', '');
}

export function assetUrl(segments: readonly string[]): string {
  return `${GAME_ASSET_BASE_URL}/${segments.map(encodeURIComponent).join('/')}`;
}

export function warLeaguesByApiId(): ReadonlyMap<number, JsonRecord> {
  const leagues = gameDataState.warLeagueData.leagues;
  if (!isRecord(leagues)) return new Map();
  const indexed = new Map<number, JsonRecord>();
  for (const league of Object.values(leagues)) {
    if (!isRecord(league) || typeof league._id !== 'number') continue;
    indexed.set(Math.trunc(league._id) - 1, { ...league });
  }
  return indexed;
}

function nextDuplicateKey(name: string, nameCounts: Map<string, number>): string {
  const count = (nameCounts.get(name) ?? 1) + 1;
  nameCounts.set(name, count);
  return `${name} ${count}`;
}

function deriveGameData(rawBundle: JsonRecord): JsonRecord {
  return {
    max_TownHall: maxTownHallLevel(rawBundle.buildings),
    categories: Object.keys(rawBundle),
  };
}

function maxTownHallLevel(buildings: unknown): number {
  if (!Array.isArray(buildings)) return 0;
  for (const building of buildings) {
    if (isRecord(building) && building.name === 'Town Hall') {
      return maxLevel(building.levels);
    }
  }
  return 0;
}
