import {
  DamageCalculatorEngine,
  DamageSourceKind,
  type DamageSourceDefinition,
  type DamageStackEntry,
  type DamageTarget,
} from '../damage-calculator';
import { records } from './equipment-comparison';
import type { JsonRecord } from '../../core/game-data/game-data-state';

export interface DamageCombination {
  entries: readonly DamageStackEntry[];
  housing: number;
  equipment: number;
  damage: number;
}
export function equipmentLevelPenalty(
  bundle: JsonRecord,
  modifier: string,
  source: DamageSourceDefinition,
): number {
  const definition = records(bundle.battle_modifiers).find((item) => item.name === modifier);
  // This calculator models spell/direct equipment damage, not hero attacks.
  // Hero DPS and defending-building DPS modifiers must not scale these hits.
  // Apply only attacker equipment level penalties from the authoritative data.
  const type = source.rarity?.toLowerCase() === 'epic' ? 'epic_equipment' : 'common_equipment';
  const value = records(definition?.modifiers).find(
    (item) => item.type === type && item.attacker === true,
  )?.minus_levels;
  return typeof value === 'number' ? value : 0;
}

/** Non-dominated combinations: never suggest spending an extra source unnecessarily. */
export function damageCombinations(
  target: DamageTarget,
  sources: readonly DamageStackEntry[],
  capacity: number,
): DamageCombination[] {
  const engine = new DamageCalculatorEngine();
  const spells = sources.filter(
      (entry) =>
        entry.source.housingSpace > 0 &&
        (entry.source.kind !== DamageSourceKind.Lightning || target.building.zapQuakeEligible) &&
        (entry.source.kind !== DamageSourceKind.Earthquake || target.building.earthquakeEligible),
    ),
    equipment = sources.filter((entry) => entry.source.hero);
  const candidates: DamageCombination[] = [];
  const visit = (
    index: number,
    entries: DamageStackEntry[],
    housing: number,
    heroSlots: Map<string, number>,
  ) => {
    if (index === equipment.length) {
      const cast = (at: number, stack: DamageStackEntry[], used: number) => {
        if (at === spells.length) {
          if (!stack.length) return;
          const result = engine.evaluate(target, stack);
          if (result.destroyed)
            candidates.push({
              entries: stack,
              housing: used,
              equipment: entries.length,
              damage: stack.reduce(
                (sum, e) =>
                  sum +
                  (e.source.kind === DamageSourceKind.Earthquake
                    ? engine.earthquakeDamage({
                        hitpoints: target.hitpoints,
                        basePercent: e.level.earthquakePercent ?? 0,
                        count: e.count,
                      })
                    : (e.level.damage ?? 0) * e.count),
                0,
              ),
            });
          return;
        }
        const source = spells[at]!;
        for (
          let count = 0;
          count <= Math.floor((capacity - used) / source.source.housingSpace);
          count++
        )
          cast(
            at + 1,
            count ? [...stack, { ...source, count }] : stack,
            used + count * source.source.housingSpace,
          );
      };
      cast(0, entries, housing);
      return;
    }
    visit(index + 1, entries, housing, heroSlots);
    const entry = equipment[index]!,
      hero = entry.source.hero!,
      slots = heroSlots.get(hero) ?? 0;
    // One activation per item and two pieces per hero. Selecting several items
    // is a pool of alternatives, not permission to equip them all together.
    if (slots < 2 && (slots > 0 || heroSlots.size < 4)) {
      const next = new Map(heroSlots);
      next.set(hero, slots + 1);
      visit(index + 1, [...entries, { ...entry, count: 1 }], housing, next);
    }
  };
  visit(0, [], 0, new Map());
  candidates.sort(
    (a, b) => a.housing - b.housing || a.equipment - b.equipment || a.damage - b.damage,
  );
  const best: DamageCombination[] = [];
  for (const candidate of candidates) {
    if (
      best.some((other) =>
        other.entries.every(
          (entry) =>
            entry.count <=
            (candidate.entries.find((value) => value.source.kind === entry.source.kind)?.count ??
              0),
        ),
      )
    )
      continue;
    best.push(candidate);
  }
  return best;
}
