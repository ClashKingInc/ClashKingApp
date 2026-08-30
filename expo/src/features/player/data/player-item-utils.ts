import { getMaxTownHallLevel } from '@/core/game-data/game-data-service';
import { isRecord, type JsonRecord } from '../models/parsing';
import type { PlayerItem, RawPlayerItemInput } from '../models/player-items';

export function generateCompleteItemList<T>(input: {
  jsonList?: unknown[] | null;
  gameData: JsonRecord;
  factory: (value: RawPlayerItemInput) => T;
  nameMatcher?: (itemName: string, jsonItem: JsonRecord) => boolean;
}): T[] {
  return Object.entries(input.gameData)
    .filter((entry): entry is [string, JsonRecord] => isRecord(entry[1]))
    .map(([key, meta]) => {
      const name = meta.name == null ? key : String(meta.name);
      const owned = input.jsonList?.find(
        (item) =>
          isRecord(item) &&
          (input.nameMatcher?.(key, item) ?? input.nameMatcher?.(name, item) ?? item.name === name),
      );
      const raw = isRecord(owned) ? owned : null;
      return input.factory({
        name,
        level: typeof raw?.level === 'number' ? Math.trunc(raw.level) : 0,
        maxLevel:
          typeof raw?.maxLevel === 'number'
            ? Math.trunc(raw.maxLevel)
            : typeof meta.maxLevel === 'number'
              ? Math.trunc(meta.maxLevel)
              : 0,
        isUnlocked: raw !== null,
        meta,
        rawJson: raw,
        superTroopIsActive: raw?.superTroopIsActive === true,
      });
    });
}
export function filterGameData(
  data: unknown,
  predicate: (key: string, value: JsonRecord) => boolean,
): JsonRecord {
  if (!isRecord(data)) return {};
  return Object.fromEntries(
    Object.entries(data).filter(
      (entry): entry is [string, JsonRecord] =>
        isRecord(entry[1]) && entry[1].is_seasonal !== true && predicate(entry[0], entry[1]),
    ),
  );
}
export const filterSpellGameData = (data: unknown) => filterGameData(data, () => true);
export function maxLevelForTH(
  meta: JsonRecord | null | undefined,
  thLevel: number,
  options: { maxTownHallLevel?: number; itemMaxLevel?: number } = {},
): number {
  if (!meta || thLevel <= 0 || !Array.isArray(meta.levels) || meta.levels.length === 0) return 0;
  let max = 0;
  for (const entry of meta.levels)
    if (
      isRecord(entry) &&
      typeof entry.required_townhall === 'number' &&
      typeof entry.level === 'number' &&
      entry.required_townhall <= thLevel
    )
      max = Math.max(max, Math.trunc(entry.level));
  const declared =
      options.itemMaxLevel ?? (typeof meta.maxLevel === 'number' ? Math.trunc(meta.maxLevel) : 0),
    maxTh = options.maxTownHallLevel ?? getMaxTownHallLevel();
  return maxTh > 0 && thLevel >= maxTh && declared > max ? declared : max;
}
export function maxLevelForItemAtTH(item: PlayerItem, thLevel: number, maxTownHallLevel?: number) {
  return (
    maxLevelForTH(item.meta, thLevel, { maxTownHallLevel, itemMaxLevel: item.maxLevel }) ||
    item.maxLevel
  );
}
export interface UpgradeResourceAmount {
  key: string;
  amount: number;
}
export interface UpgradeRemainingSummary {
  targetLevel: number;
  levelsRemaining: number;
  seconds: number;
  resources: readonly UpgradeResourceAmount[];
  isComplete: boolean;
}
export function calculateRemainingUpgradeSummary(
  item: PlayerItem,
  targetLevel: number,
): UpgradeRemainingSummary {
  if (!item.meta || targetLevel <= 0 || item.level >= targetLevel)
    return { targetLevel, levelsRemaining: 0, seconds: 0, resources: [], isComplete: true };
  const stats = new Map<number, JsonRecord>();
  if (Array.isArray(item.meta.levels))
    for (const entry of item.meta.levels)
      if (isRecord(entry) && typeof entry.level === 'number')
        stats.set(Math.trunc(entry.level), entry);
  let seconds = 0;
  const costs: Record<string, number> = {};
  for (let level = item.level <= 0 ? 1 : item.level; level < targetLevel; level++) {
    const row = stats.get(level);
    if (!row) continue;
    seconds += typeof row.upgrade_time === 'number' ? Math.trunc(row.upgrade_time) : 0;
    if (isRecord(row.upgrade_cost)) {
      for (const [key, value] of Object.entries(row.upgrade_cost)) {
        const amount = typeof value === 'number' ? value : 0;
        if (amount > 0) {
          const normalized = normalizeResource(key);
          costs[normalized] = (costs[normalized] ?? 0) + amount;
        }
      }
    } else {
      const amount = typeof row.upgrade_cost === 'number' ? row.upgrade_cost : 0;
      if (amount > 0) {
        const key = normalizeResource(String(item.meta.upgrade_resource ?? 'resource'));
        costs[key] = (costs[key] ?? 0) + amount;
      }
    }
  }
  const resources = Object.entries(costs)
    .map(([key, amount]) => ({ key, amount }))
    .sort((a, b) => resourceSortWeight(a.key) - resourceSortWeight(b.key));
  const levelsRemaining = Math.max(0, Math.min(targetLevel, targetLevel - item.level));
  return { targetLevel, levelsRemaining, seconds, resources, isComplete: levelsRemaining <= 0 };
}
export function findLevelStats(
  meta: JsonRecord | null | undefined,
  level: number,
): JsonRecord | null {
  if (!Array.isArray(meta?.levels)) return null;
  return (
    (meta.levels.find((entry) => isRecord(entry) && entry.level === level) as
      JsonRecord | undefined) ?? null
  );
}
export const normalizeResource = (value: string) =>
  value.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
export function resourceSortWeight(key: string) {
  if (key.includes('gold') && !key.includes('builder')) return 0;
  if (key.includes('elixir') && !key.includes('dark')) return 1;
  if (key.includes('dark')) return 2;
  if (key.includes('builder') && key.includes('gold')) return 3;
  if (key.includes('builder') && key.includes('elixir')) return 4;
  if (key.includes('shiny')) return 5;
  if (key.includes('glowy')) return 6;
  if (key.includes('starry')) return 7;
  return 99;
}
