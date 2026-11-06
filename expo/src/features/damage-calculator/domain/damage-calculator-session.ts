import { DamageCatalog } from '../data/damage-catalog';
import {
  type BuildingDefinition,
  type DamageStackEntry,
  DamageSourceKind,
  DamageTarget,
  BuildingLevelDefinition,
} from './damage-calculator-engine';

export interface DamageAccountPreset {
  readonly tag: string;
  readonly name: string;
  readonly townHall: number;
  readonly league?: string;
  readonly ownedLevels?: ReadonlyMap<DamageSourceKind, number>;
}

export interface SelectedBuilding {
  readonly buildingId: string;
  readonly level: number;
  readonly supercharge?: number;
}

export interface SelectedDamageSource {
  readonly kind: DamageSourceKind;
  readonly level: number;
  readonly count: number;
}

export class DamageCalculatorSession {
  readonly catalog: DamageCatalog;
  townHall: number;
  targetTownHall?: number;
  private spellCapacityOverride?: number;
  selectedAccountTag?: string;
  readonly targets: SelectedBuilding[] = [];
  readonly sources = new Map<DamageSourceKind, SelectedDamageSource>();

  constructor(catalog: DamageCatalog, options: { townHall?: number } = {}) {
    this.catalog = catalog;
    this.townHall = clamp(options.townHall ?? catalog.maxTownHall, 1, catalog.maxTownHall);
    this.repairSources();
  }

  get availableBuildings(): readonly BuildingDefinition[] {
    return this.catalog.buildingsForTownHall(this.targetTownHall ?? this.townHall);
  }

  get spellCapacity(): number {
    // Account/max-level changes follow their TH capacity until the user edits
    // this value. Preserve a manual budget across presets, but never allow it
    // to exceed the selected TH's real capacity, including Clan Castle spells.
    const maximum = this.catalog.spellCapacityForTownHall(this.townHall);
    return Math.min(this.spellCapacityOverride ?? maximum, maximum);
  }

  get availableSources() {
    return this.catalog.sources.filter(
      (source) => source.levelsForTownHall(this.townHall).length > 0,
    );
  }

  setTownHall(value: number): void {
    this.townHall = clamp(value, 1, this.catalog.maxTownHall);
    this.repairTargets();
    this.repairSources();
  }

  setTargetTownHall(value: number): void {
    this.targetTownHall = clamp(value, 1, this.catalog.maxTownHall);
    this.repairTargets();
  }

  setTargetSupercharge(buildingId: string, supercharge: number): void {
    const index = this.targets.findIndex((target) => target.buildingId === buildingId);
    const target = this.targets[index];
    if (target) this.targets[index] = { ...target, supercharge };
  }

  addTarget(buildingId: string): boolean {
    if (this.targets.some((target) => target.buildingId === buildingId)) return false;
    const building = this.availableBuilding(buildingId);
    if (!building) return false;
    const levels = building.levelsForTownHall(this.targetTownHall ?? this.townHall);
    const last = levels.at(-1);
    if (!last) return false;
    this.targets.push({ buildingId, level: last.level });
    return true;
  }

  removeTarget(buildingId: string): void {
    const index = this.targets.findIndex((target) => target.buildingId === buildingId);
    if (index >= 0) this.targets.splice(index, 1);
  }

  setTargetLevel(buildingId: string, level: number): void {
    const building = this.availableBuilding(buildingId);
    if (!building) return;
    const valid = building.levelsForTownHall(this.targetTownHall ?? this.townHall);
    if (!valid.some((candidate) => candidate.level === level)) return;
    const index = this.targets.findIndex((target) => target.buildingId === buildingId);
    if (index >= 0) this.targets[index] = { buildingId, level };
  }

  setSourceLevel(kind: DamageSourceKind, level: number): void {
    const definition = this.catalog.source(kind);
    if (!definition) return;
    const valid = definition.levelsForTownHall(this.townHall);
    if (!valid.some((candidate) => candidate.level === level)) return;
    this.sources.set(kind, {
      kind,
      level,
      count: this.sources.get(kind)?.count ?? 0,
    });
  }

  setSourceCount(kind: DamageSourceKind, count: number): void {
    const current = this.sources.get(kind);
    if (!current) return;
    this.sources.set(kind, { ...current, count: clamp(count, 0, 99) });
  }

  setSpellCapacity(value: number): void {
    // Zero is valid for an equipment-only attack; arbitrary 16–20 budgets are not.
    this.spellCapacityOverride = clamp(Math.trunc(value), 0, this.catalog.spellCapacityForTownHall(this.townHall));
  }

  applyPreset(preset: DamageAccountPreset): void {
    this.selectedAccountTag = preset.tag;
    this.setTownHall(preset.townHall);
    for (const [kind, ownedLevel] of preset.ownedLevels ?? []) {
      const definition = this.catalog.source(kind);
      if (!definition) continue;
      const valid = definition.levelsForTownHall(this.townHall);
      if (valid.length === 0) continue;
      const chosen = [...valid].reverse().find((level) => level.level <= ownedLevel) ?? valid[0]!;
      this.setSourceLevel(kind, chosen.level);
    }
  }

  resolvedTargets(): readonly DamageTarget[] {
    const resolved: DamageTarget[] = [];
    for (const selected of this.targets) {
      const building = this.availableBuilding(selected.buildingId);
      const level = building?.level(selected.level);
      if (building && level)
        resolved.push(
          new DamageTarget({
            building,
            level: new BuildingLevelDefinition({
              ...level,
              hitpoints:
                level.superchargeHitpoints[(selected.supercharge ?? 0) - 1] ?? level.hitpoints,
            }),
          }),
        );
    }
    return resolved;
  }

  resolvedStack(): readonly DamageStackEntry[] {
    const resolved: DamageStackEntry[] = [];
    for (const selected of this.sources.values()) {
      const source = this.catalog.source(selected.kind);
      const level = source?.level(selected.level);
      if (source && level && selected.count > 0) {
        resolved.push({ source, level, count: selected.count });
      }
    }
    return resolved;
  }

  private repairTargets(): void {
    for (let index = this.targets.length - 1; index >= 0; index -= 1) {
      const selected = this.targets[index]!;
      const building = this.availableBuilding(selected.buildingId);
      const valid = building?.levelsForTownHall(this.targetTownHall ?? this.townHall) ?? [];
      const last = valid.at(-1);
      if (!last) {
        this.targets.splice(index, 1);
      } else if (!valid.some((level) => level.level === selected.level)) {
        this.targets[index] = { ...selected, level: last.level };
      }
    }
  }

  private repairSources(): void {
    const validKinds = new Set<DamageSourceKind>();
    for (const source of this.catalog.sources) {
      const valid = source.levelsForTownHall(this.townHall);
      const last = valid.at(-1);
      if (!last) continue;
      validKinds.add(source.kind);
      const current = this.sources.get(source.kind);
      const currentValid =
        current !== undefined && valid.some((level) => level.level === current.level);
      this.sources.set(source.kind, {
        kind: source.kind,
        level: currentValid ? current.level : last.level,
        count: current?.count ?? 0,
      });
    }
    for (const kind of this.sources.keys()) {
      if (!validKinds.has(kind)) this.sources.delete(kind);
    }
  }

  private availableBuilding(id: string): BuildingDefinition | undefined {
    return this.availableBuildings.find((building) => building.id === id);
  }
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.min(maximum, Math.max(minimum, value));
}
