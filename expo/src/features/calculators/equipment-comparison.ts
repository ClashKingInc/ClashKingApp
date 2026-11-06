import { gameAbilitiesFor, isRecord, type JsonRecord } from '../../core/game-data/game-data-state';

export interface ComparisonItem {
  id: string;
  name: string;
  hero?: string;
  levels: readonly JsonRecord[];
  raw: JsonRecord;
}
export interface Loadout {
  id: string;
  heroLevel: number;
  equipment: readonly { id: string; level: number }[];
}
export interface ComparisonMetric {
  id: string;
  label: string;
  field?: string;
  equipmentId?: string;
  abilityIndex?: number;
  sources?: readonly { equipmentId: string; abilityIndex: number }[];
}
export function records(value: unknown): JsonRecord[] {
  if (Array.isArray(value)) return value.filter(isRecord);
  if (isRecord(value)) return records(value.items ?? Object.values(value));
  return [];
}
export function comparisonItems(value: unknown): ComparisonItem[] {
  return records(value).flatMap((raw) =>
    typeof raw.name === 'string' && records(raw.levels).length
      ? [
          {
            id: String(raw._id ?? raw.name),
            name: raw.name,
            hero: typeof raw.hero === 'string' ? raw.hero : undefined,
            levels: records(raw.levels).sort((a, b) => Number(a.level) - Number(b.level)),
            raw,
          },
        ]
      : [],
  );
}
export function abilitiesFor(item: ComparisonItem) {
  return gameAbilitiesFor(item.id, item.name);
}
export function levelRow(item: ComparisonItem, level: number) {
  return item.levels.find((row) => row.level === level);
}
export function equipmentMetrics(items: readonly ComparisonItem[]): ComparisonMetric[] {
  const metrics = items.flatMap((item) =>
    abilitiesFor(item).flatMap((ability, abilityIndex) => {
      const keys = new Set(
        ability.levels.flatMap((level) => Object.keys(level).filter((key) => key !== 'level')),
      );
      return [...keys].map((field) => ({
        id: `${item.id}:${abilityIndex}:${field}`,
        label: `${item.name} · ${ability.name} · ${field}`,
        equipmentId: item.id,
        abilityIndex,
        field,
      }));
    }),
  );
  const groups = new Map<string, ComparisonMetric[]>();
  for (const metric of metrics) {
    const item = items.find((entry) => entry.id === metric.equipmentId)!;
    const ability = abilitiesFor(item)[metric.abilityIndex ?? 0]!;
    // A shared field name alone is not a shared mechanic: the ability and its
    // activation condition must match, so passive healing never becomes an aura.
    const key = `${ability.name}:${'trigger' in ability ? ability.trigger : 'passive'}:${metric.field}`;
    groups.set(key, [...(groups.get(key) ?? []), metric]);
  }
  return [...groups.entries()].flatMap(([key, group]) => {
    const equipmentCount = new Set(group.map((metric) => metric.equipmentId)).size;
    // Repeated stages from one piece are not interchangeable with each other.
    if (equipmentCount < 2 || equipmentCount !== group.length) return group;
    const first = group[0]!;
    return [
      {
        id: `shared:${key}`,
        label: key,
        field: first.field,
        sources: group.map((metric) => ({
          equipmentId: metric.equipmentId!,
          abilityIndex: metric.abilityIndex!,
        })),
      },
    ];
  });
}
export function compareMetric(
  hero: ComparisonItem,
  items: readonly ComparisonItem[],
  row: Loadout,
  metric: ComparisonMetric,
): unknown {
  const base = levelRow(hero, row.heroLevel);
  if (!base) return undefined;
  const gear = row.equipment.flatMap((selection) => {
    const item = items.find((item) => item.id === selection.id),
      level = item && levelRow(item, selection.level);
    return item && level ? [{ item, level, selection }] : [];
  });
  if (metric.sources) {
    const values = metric.sources.flatMap((source) => {
      const chosen = gear.find((entry) => entry.item.id === source.equipmentId);
      if (!chosen) return [];
      const value = records(abilitiesFor(chosen.item)[source.abilityIndex]?.levels).find(
        (level) => Number(level.level) === chosen.selection.level,
      )?.[metric.field!];
      return value == null ? [] : [value];
    });
    // Durations, radii and percentages are separate effects, not additive stats.
    return values.length === 1 ? values[0] : values.length > 1 ? values : undefined;
  }
  if (metric.equipmentId) {
    const chosen = gear.find((entry) => entry.item.id === metric.equipmentId);
    if (!chosen) return undefined;
    const ability = abilitiesFor(chosen.item)[metric.abilityIndex ?? 0];
    // Do not sum unlike effects (clones, healing and hero stats). Each ability
    // field keeps its equipment identity and activation condition.
    return records(ability?.levels).find((level) => level.level === chosen.selection.level)?.[
      metric.field!
    ];
  }
  const total = (key: string) =>
    gear.reduce(
      (value, entry) =>
        value + (typeof entry.level[key] === 'number' ? Number(entry.level[key]) : 0),
      0,
    );
  if (metric.id === 'dps' || metric.id === 'hitpoints')
    return typeof base[metric.id] === 'number'
      ? Number(base[metric.id]) + total(metric.id)
      : undefined;
  if (metric.id === 'healing') return total('heal_on_activation');
  if (metric.id === 'attackSpeed')
    return typeof hero.raw.attack_speed === 'number' ? hero.raw.attack_speed : undefined;
  if (metric.id === 'regeneration')
    return gear.reduce(
      (sum, entry) =>
        sum +
        abilitiesFor(entry.item).reduce((part, ability) => {
          const current = ability.levels.find((level) => level.level === entry.selection.level);
          // Activated Healing Tome is an aura, not always-on personal regeneration.
          return (
            part +
            (!('trigger' in ability) && current && 'healing_per_second' in current
              ? Number(current.healing_per_second)
              : 0)
          );
        }, 0),
      0,
    );
  return undefined;
}

export function makePairs(
  items: readonly ComparisonItem[],
  levels: Readonly<Record<string, number>>,
  heroLevel: number,
): Loadout[] {
  if (items.length === 1)
    return [
      {
        id: items[0]!.id,
        heroLevel,
        equipment: [{ id: items[0]!.id, level: levels[items[0]!.id]! }],
      },
    ];
  return items.flatMap((item, index) =>
    items.slice(index + 1).map((other) => ({
      id: `${item.id}-${other.id}`,
      heroLevel,
      equipment: [
        { id: item.id, level: levels[item.id]! },
        { id: other.id, level: levels[other.id]! },
      ],
    })),
  );
}
