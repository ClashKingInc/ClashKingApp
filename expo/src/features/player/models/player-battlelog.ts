import { ImageAssets } from '@/core/assets/image-assets';
import { localizedNameForItem } from '@/core/game-data/game-data-localization';
import { gameDataState } from '@/core/game-data/game-data-state';
import { apiDate, int, isRecord, record, records, string, type JsonRecord } from './parsing';

export type PlayerBattlelogMode = 'ranked' | 'farming';
export type PlayerBattlelogSource = 'official' | 'history';
export class PlayerBattlelogEntry {
  constructor(
    readonly id: string,
    readonly mode: PlayerBattlelogMode,
    readonly source: PlayerBattlelogSource,
    readonly attack: boolean,
    readonly opponentTag: string,
    readonly opponentName: string,
    readonly opponentTownHall: number,
    readonly stars: number,
    readonly destructionPercentage: number,
    readonly gold: number,
    readonly elixir: number,
    readonly darkElixir: number,
    readonly timestamp: Date | null,
    readonly duration: number,
    readonly armyShareCode: string,
    readonly armyCounts: Readonly<Record<string, number>>,
  ) {}
  get totalLoot() {
    return this.gold + this.elixir + this.darkElixir;
  }
  get mergeKey() {
    return `${this.attack ? 1 : 0}|${this.opponentTag.toUpperCase()}|${this.timestamp?.getTime() ?? 0}`;
  }
  static fromOfficial(json: JsonRecord) {
    const resources: Record<string, number> = {};
    for (const item of records(json.lootedResources)) {
      resources[string(item.name).toLowerCase().replace(/[\s_]/g, '')] = int(item.amount);
    }
    const share = string(json.armyShareCode);
    return new PlayerBattlelogEntry(
      '',
      battlelogMode(json.battleType),
      'official',
      json.attack === true,
      string(json.opponentPlayerTag),
      string(json.opponentName),
      int(json.opponentTownHallLevel),
      int(json.stars),
      int(json.destructionPercentage),
      resources.gold ?? 0,
      resources.elixir ?? 0,
      resources.darkelixir ?? 0,
      apiDate(json.battleTimestamp),
      int(json.battleTime),
      share,
      parseArmyCounts(share),
    );
  }
  static fromHistory(json: JsonRecord) {
    const share = string(json.army_share_code);
    const stored = Object.fromEntries(
      Object.entries(record(json.army_counts)).map(([key, value]) => [key, int(value)]),
    );
    return new PlayerBattlelogEntry(
      string(json.battle_id),
      battlelogMode(json.battle_type),
      'history',
      json.attack === true,
      string(json.opponent_tag),
      string(json.opponent_name),
      int(json.opponent_townhall),
      int(json.stars),
      int(json.destruction_percentage),
      int(json.gold),
      int(json.elixir),
      int(json.dark_elixir),
      apiDate(json.timestamp),
      int(json.duration),
      share,
      Object.keys(stored).length ? stored : parseArmyCounts(share),
    );
  }
}
export class PlayerBattlelogData {
  constructor(
    readonly items: readonly PlayerBattlelogEntry[],
    readonly officialAvailable: boolean,
    readonly historyAvailable: boolean,
  ) {}
  forMode(mode: PlayerBattlelogMode) {
    return this.items.filter((item) => item.mode === mode);
  }
  static merge(input: {
    official: Iterable<PlayerBattlelogEntry>;
    history: Iterable<PlayerBattlelogEntry>;
    officialAvailable: boolean;
    historyAvailable: boolean;
  }) {
    const merged = new Map<string, PlayerBattlelogEntry>();
    for (const item of input.official) merged.set(item.mergeKey, item);
    for (const item of input.history) merged.set(item.mergeKey, item);
    return new PlayerBattlelogData(
      [...merged.values()].sort(
        (a, b) => (b.timestamp?.getTime() ?? 0) - (a.timestamp?.getTime() ?? 0),
      ),
      input.officialAvailable,
      input.historyAvailable,
    );
  }
  popularTroops(mode: PlayerBattlelogMode, options: { limit?: number; attack?: boolean } = {}) {
    const uses = new Map<string, number>();
    for (const battle of this.items.filter(
      (item) => item.mode === mode && item.attack === (options.attack ?? true),
    ))
      for (const code of Object.keys(battle.armyCounts).filter(
        (code) => code.startsWith('u_') || code.startsWith('i_'),
      ))
        uses.set(code, (uses.get(code) ?? 0) + 1);
    return [...uses]
      .map(
        ([code, count]) =>
          new PlayerPopularArmyItem(PlayerBattlelogArmyCatalog.resolve(code), count),
      )
      .sort((a, b) => b.uses - a.uses || a.item.name.localeCompare(b.item.name))
      .slice(0, options.limit ?? 3);
  }
}
export class PlayerPopularArmyItem {
  constructor(
    readonly item: PlayerBattlelogArmyItem,
    readonly uses: number,
  ) {}
}
export class PlayerBattlelogArmyItem {
  constructor(
    readonly code: string,
    readonly name: string,
    readonly imageUrl: string,
  ) {}
}
export class PlayerBattlelogArmyCatalog {
  static resolve(code: string) {
    const [prefix = '', rawId] = code.split('_');
    const id = rawId === undefined ? null : Number.parseInt(rawId, 10);
    const item = id === null || Number.isNaN(id) ? null : findItem(prefix, id);
    const translated = localizedNameForItem(item).trim();
    const name = translated || code;
    const image =
      prefix === 's' || prefix === 'd'
        ? ImageAssets.getSpellImage(name)
        : prefix === 'h'
          ? ImageAssets.getHeroImage(name)
          : prefix === 'p'
            ? ImageAssets.getPetImage(name)
            : prefix === 'e'
              ? ImageAssets.getGearImage(name)
              : ImageAssets.getTroopImage(name);
    return new PlayerBattlelogArmyItem(code, name, image);
  }
}
function findItem(prefix: string, id: number): JsonRecord | null {
  const section =
    prefix === 's' || prefix === 'd'
      ? 'spells'
      : prefix === 'h'
        ? 'heroes'
        : prefix === 'p'
          ? 'pets'
          : prefix === 'e'
            ? 'equipment'
            : 'troops';
  const normalized =
    section === 'spells'
      ? gameDataState.spellsData.spells
      : section === 'heroes'
        ? gameDataState.heroesData.heroes
        : section === 'pets'
          ? gameDataState.petsData.pets
          : section === 'equipment'
            ? gameDataState.gearsData.gears
            : gameDataState.troopsData.troops;
  for (const source of [gameDataState.bundleData[section], normalized])
    for (const item of sectionItems(source)) {
      const raw = int(item._id);
      if (raw === id || raw % 1_000_000 === id) return item;
    }
  return null;
}
function sectionItems(value: unknown): JsonRecord[] {
  if (Array.isArray(value)) return value.filter(isRecord);
  return isRecord(value) ? Object.values(value).filter(isRecord) : [];
}
function battlelogMode(value: unknown): PlayerBattlelogMode {
  const normalized = string(value)
    .trim()
    .toLowerCase()
    .replace(/[^a-z]/g, '');
  return normalized === 'ranked' || normalized === 'legend' ? 'ranked' : 'farming';
}
export function parseArmyCounts(shareCode: string): Record<string, number> {
  let payload = shareCode;
  try {
    payload = new URL(shareCode).searchParams.get('army') ?? shareCode;
  } catch {
    const query = shareCode.match(/[?&]army=([^&]+)/)?.[1];
    if (query) payload = decodeURIComponent(query);
  }
  const counts: Record<string, number> = {};
  for (const section of payload.matchAll(/([hidsu])([^hidsu]*)/g)) {
    const prefix = section[1]!;
    if (prefix === 'h') continue;
    for (const rawItem of section[2]!.split('-')) {
      const match = /^(\d+)x(\d+)$/.exec(rawItem);
      if (!match) continue;
      const quantity = Number(match[1]),
        id = Number(match[2]);
      if (quantity <= 0) continue;
      const key = `${prefix}_${id}`;
      counts[key] = (counts[key] ?? 0) + quantity;
    }
  }
  return counts;
}
