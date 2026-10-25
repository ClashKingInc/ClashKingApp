import { gameDataState, isRecord, type JsonRecord } from './game-data-state';

type LimitsIndex = { buildings: readonly JsonRecord[]; heroes: readonly JsonRecord[] };
const indexes = new WeakMap<JsonRecord, { revision: number; index: LimitsIndex }>();

function collection(value: unknown): readonly JsonRecord[] {
  if (Array.isArray(value)) return value.filter(isRecord);
  return isRecord(value) ? Object.values(value).filter(isRecord) : [];
}
function indexFor(bundle: JsonRecord): LimitsIndex {
  const cached = indexes.get(bundle);
  if (cached?.revision === gameDataState.revision) return cached.index;
  const index = {
    buildings: collection(
      bundle.buildings ??
        (isRecord(bundle.buildings_data) ? bundle.buildings_data.buildings : undefined),
    ),
    heroes: collection(
      bundle.heroes ??
        (isRecord(bundle.heroes_data)
          ? bundle.heroes_data.heroes
          : bundle === gameDataState.bundleData
            ? gameDataState.heroesData.heroes
            : undefined),
    ),
  };
  indexes.set(bundle, { revision: gameDataState.revision, index });
  return index;
}
function integer(value: unknown): number | null {
  if (typeof value !== 'number' && typeof value !== 'string') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? Math.trunc(parsed) : null;
}
function levels(item: JsonRecord): readonly JsonRecord[] {
  return collection(item.levels).filter((row) => (integer(row.level) ?? 0) > 0);
}
function builder(item: JsonRecord): boolean {
  return String(item.village ?? '')
    .toLowerCase()
    .includes('builder');
}
function buildingLimit(
  index: LimitsIndex,
  name: string,
  hall: number,
  isBuilder: boolean,
): number | null {
  const building = index.buildings.find(
    (item) => item.name === name && builder(item) === isBuilder,
  );
  if (!building) return null;
  return levels(building).reduce((max, row) => {
    const required = integer(row.required_townhall);
    return required === null || required <= hall ? Math.max(max, integer(row.level) ?? 0) : max;
  }, 0);
}

/** Maximum possible at this hall, including unlock buildings and a gear's hero.
 * Zero is deliberately "not available", never a request to use the global max.
 * Limits use buildings possible at the hall, not the player's current building
 * level, so a valid upgrade path within the same TH/BH remains included. */
export function maximumItemLevelAtHall(
  item: JsonRecord | null | undefined,
  hall: number,
  bundle: JsonRecord = gameDataState.bundleData,
): number {
  if (!item || hall <= 0) return 0;
  const index = indexFor(bundle);
  const isBuilder = builder(item);
  const rows = levels(item);
  if (!rows.length) return 0;
  // This is completion of the current hall, not a plan to rush every future
  // hall. Upgrading the hall changes the scope on the next imported snapshot.
  if (item.name === 'Town Hall' || item.name === 'Builder Hall')
    return Math.min(hall, Math.max(...rows.map((row) => integer(row.level) ?? 0)));
  const producer = typeof item.production_building === 'string' ? item.production_building : '';
  const requiredProducer = integer(item.production_building_level) ?? 0;
  const producerLimit = producer ? buildingLimit(index, producer, hall, isBuilder) : null;
  if (producer && requiredProducer > 0 && producerLimit === null) return 0;
  if (producerLimit !== null && producerLimit < requiredProducer) return 0;
  if (typeof item.hero === 'string') {
    const hero = index.heroes.find((candidate) => candidate.name === item.hero);
    if (!hero || maximumItemLevelAtHall(hero, hall, bundle) <= 0) return 0;
  }
  const requirements = [
    ['required_lab_level', isBuilder ? 'Star Laboratory' : 'Laboratory'],
    ['required_pet_house_level', 'Pet House'],
    ['required_hero_tavern_level', 'Hero Hall'],
    ['required_blacksmith_level', 'Blacksmith'],
  ] as const;
  let maximum = 0;
  for (const row of rows) {
    const requiredHall = integer(row.required_townhall);
    if (requiredHall !== null && requiredHall > hall) continue;
    if (
      requirements.some(([field, name]) => {
        const required = integer(row[field]);
        const available = required === null ? null : buildingLimit(index, name, hall, isBuilder);
        return required !== null && available !== null && available < required;
      })
    )
      continue;
    maximum = Math.max(maximum, integer(row.level) ?? 0);
  }
  // A training building unlocks a unit at its starting level. Its first lab
  // requirement can be higher (e.g. Barbarian before a Laboratory exists).
  if (producerLimit !== null && producerLimit >= requiredProducer && requiredProducer > 0)
    maximum = Math.max(maximum, Math.min(...rows.map((row) => integer(row.level) ?? Infinity)));
  return Number.isFinite(maximum) ? maximum : 0;
}

export function maximumBuildingLevelAtHall(
  name: string,
  hall: number,
  isBuilder = false,
  bundle: JsonRecord = gameDataState.bundleData,
): number {
  return hall > 0 ? (buildingLimit(indexFor(bundle), name, hall, isBuilder) ?? 0) : 0;
}
