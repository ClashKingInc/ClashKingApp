import { isRecord, type JsonRecord } from '../../core/game-data/game-data-state';

/** Zero at one level can be real. An all-zero/missing combat mechanic should
 * occupy no card, table column or bar; costs and requirements are separate. */
export function wikiItemHasStat(
  levels: unknown,
  key: string,
  metadata?: JsonRecord | null,
): boolean {
  // Town Hall weapons only exist at some levels. Keep this building's Wiki
  // focused on its shared stats instead of adding an intermittent DPS mechanic.
  if (key === 'dps' && (metadata?._id === 1000001 || metadata?.name === 'Town Hall')) return false;
  return (
    Array.isArray(levels) &&
    levels.some(
      (level) =>
        isRecord(level) &&
        typeof (level[key] ?? metadata?.[key]) === 'number' &&
        Number.isFinite(level[key] ?? metadata?.[key]) &&
        (level[key] ?? metadata?.[key]) !== 0,
    )
  );
}

export const wikiCombatStats = {
  DPS: 'dps',
  HP: 'hitpoints',
  Damage: 'damage',
  Healing: 'heal_on_activation',
  'Attack range': 'attack_range',
  'Minimum range': 'min_range',
  'Effect range': 'effect_range',
  'Trigger radius': 'trigger_radius',
  'Damage radius': 'damage_radius',
  'Movement speed': 'movement_speed',
} as const;

export function wikiIsSuperTroop(metadata: JsonRecord | null | undefined): boolean {
  return (
    !!metadata &&
    (isRecord(metadata.super_troop) ||
      [metadata.super_troop, metadata.is_super_troop, metadata.is_super].some(
        (value) => value === true || value === 1 || value === 'true',
      ) ||
      metadata.type === 'super_troop' ||
      metadata.category === 'super_troop')
  );
}

/** Super and seasonal forms have combat levels, but no research upgrades.
 * Do not mistake their exported zero costs for a free upgrade. */
export function wikiHasResearchUpgrades(metadata: JsonRecord | null | undefined): boolean {
  return (
    !metadata ||
    !(wikiIsSuperTroop(metadata) || [true, 1, 'true'].includes(metadata.is_seasonal as never))
  );
}
