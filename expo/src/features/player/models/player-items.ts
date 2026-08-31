import { ImageAssets } from '@/core/assets/image-assets';
import { gameDataState } from '@/core/game-data/game-data-state';
import { bool, int, isRecord, record, records, string, type JsonRecord } from './parsing';

export interface PlayerItemInput {
  name: string;
  level: number;
  maxLevel: number;
  type: string;
  imageUrl: string;
  isUnlocked: boolean;
  isActive?: boolean | null;
  meta?: JsonRecord | null;
}
export class PlayerItem {
  readonly name: string;
  readonly level: number;
  readonly maxLevel: number;
  readonly type: string;
  readonly imageUrl: string;
  readonly isMaxLevel: boolean;
  readonly isActive: boolean | null;
  readonly isUnlocked: boolean;
  readonly meta: JsonRecord | null;
  constructor(input: PlayerItemInput) {
    this.name = input.name;
    this.level = input.level;
    this.maxLevel = input.maxLevel;
    this.type = input.type;
    this.imageUrl = input.imageUrl;
    this.isUnlocked = input.isUnlocked;
    this.isActive = input.isActive ?? null;
    this.meta = input.meta ?? null;
    this.isMaxLevel = input.level === input.maxLevel;
  }
}
export interface RawPlayerItemInput {
  name: string;
  level: number;
  maxLevel: number;
  isUnlocked: boolean;
  meta?: JsonRecord | null;
  rawJson?: JsonRecord | null;
  superTroopIsActive?: boolean | null;
}
abstract class VillageItem extends PlayerItem {
  readonly village: string;
  protected constructor(input: PlayerItemInput & { village: string }) {
    super(input);
    this.village = input.village;
  }
}
export class PlayerEquippedEquipment extends VillageItem {
  static fromJson(json: JsonRecord) {
    const name = string(json.name, 'No name');
    return new PlayerEquippedEquipment({
      ...base(raw(json, true), 'equipment', ImageAssets.getGearImage(name)),
      name,
      village: string(json.village, 'home'),
    });
  }
}
export { PlayerEquippedEquipment as PlayerEquipedEquipment };
export class PlayerHero extends VillageItem {
  readonly equipment: readonly PlayerEquippedEquipment[];
  constructor(
    input: PlayerItemInput & { village: string; equipment: readonly PlayerEquippedEquipment[] },
  ) {
    super(input);
    this.equipment = input.equipment;
  }
  static fromJson(json: JsonRecord) {
    return PlayerHero.fromRaw({ ...raw(json, true), rawJson: json });
  }
  static fromRaw(input: RawPlayerItemInput) {
    return new PlayerHero({
      ...base(input, 'hero', ImageAssets.getHeroImage(input.name)),
      village: string(input.meta?.village, 'home'),
      equipment: records(input.rawJson?.equipment).map(PlayerEquippedEquipment.fromJson),
    });
  }
}
export class PlayerBuilderBaseHero extends VillageItem {
  static fromJson(json: JsonRecord) {
    return PlayerBuilderBaseHero.fromRaw({
      ...raw(json, bool(json.isUnlocked)),
      meta: { village: string(json.village, 'builderBase') },
    });
  }
  static fromRaw(input: RawPlayerItemInput) {
    return new PlayerBuilderBaseHero({
      ...base(input, 'hero', ImageAssets.getBuilderBaseHeroImage(input.name)),
      village: string(input.meta?.village, 'builderBase'),
    });
  }
}
export class PlayerTroop extends VillageItem {
  readonly superTroopIsActive: boolean;
  constructor(input: PlayerItemInput & { village: string; superTroopIsActive: boolean }) {
    super(input);
    this.superTroopIsActive = input.superTroopIsActive;
  }
  static fromJson(json: JsonRecord) {
    let name = string(json.name, 'No name');
    if (name === 'Baby Dragon' && json.village === 'builderBase') name = 'Baby Dragon 2';
    return PlayerTroop.fromRaw({
      ...raw({ ...json, name }, true),
      superTroopIsActive: bool(json.superTroopIsActive),
    });
  }
  static fromRaw(input: RawPlayerItemInput) {
    return new PlayerTroop({
      ...base(input, 'troop', ImageAssets.getTroopImage(input.name)),
      village: string(input.meta?.village, 'home'),
      superTroopIsActive: input.superTroopIsActive ?? false,
    });
  }
  toJson(): JsonRecord {
    return {
      name: this.name,
      level: this.level,
      maxLevel: this.maxLevel,
      superTroopIsActive: this.superTroopIsActive,
      village: this.village,
    };
  }
}
export class PlayerSuperTroop extends PlayerTroop {
  static override fromJson(json: JsonRecord) {
    return PlayerSuperTroop.fromRaw({
      ...raw(json, true, 'Unknown'),
      superTroopIsActive: bool(json.superTroopIsActive),
    });
  }
  static override fromRaw(input: RawPlayerItemInput) {
    return new PlayerSuperTroop({
      ...base(input, 'troop', ImageAssets.getSuperTroopImage(input.name)),
      village: string(input.meta?.village, 'home'),
      superTroopIsActive: input.superTroopIsActive ?? false,
    });
  }
}
export class PlayerBuilderBaseTroop extends PlayerTroop {
  static override fromJson(json: JsonRecord) {
    return PlayerBuilderBaseTroop.fromRaw({
      ...raw(json, true, 'Unknown'),
      superTroopIsActive: bool(json.superTroopIsActive),
    });
  }
  static override fromRaw(input: RawPlayerItemInput) {
    const level = input.isUnlocked ? validBuilderBaseLevel(input.level, input.meta) : input.level;
    return new PlayerBuilderBaseTroop({
      ...base({ ...input, level }, 'builderBase', ImageAssets.getBuilderBaseTroopImage(input.name)),
      village: string(input.meta?.village, 'home'),
      superTroopIsActive: input.superTroopIsActive ?? false,
    });
  }
}
export class PlayerSpell extends VillageItem {
  static fromJson(json: JsonRecord) {
    return PlayerSpell.fromRaw(raw(json, true));
  }
  static fromRaw(input: RawPlayerItemInput) {
    return new PlayerSpell({
      ...base(input, 'spell', ImageAssets.getSpellImage(input.name)),
      village: string(input.meta?.village, 'home'),
    });
  }
}
export class PlayerEquipment extends VillageItem {
  readonly rarity: string;
  constructor(input: PlayerItemInput & { village: string; rarity: string }) {
    super(input);
    this.rarity = input.rarity;
  }
  static fromJson(json: JsonRecord) {
    const name = string(json.name, 'No name');
    return new PlayerEquipment({
      ...base(raw(json, true), 'gear', ImageAssets.getGearImage(name)),
      name,
      village: string(json.village, 'home'),
      rarity: string(record(record(gameDataState.gearsData.gears)[name]).rarity, '1'),
    });
  }
  static fromRaw(input: RawPlayerItemInput) {
    return new PlayerEquipment({
      ...base(input, 'gear', ImageAssets.getGearImage(input.name)),
      village: string(input.meta?.village, 'home'),
      rarity: string(input.meta?.rarity, '1'),
    });
  }
}
export class PlayerPet extends VillageItem {
  static fromJson(json: JsonRecord) {
    return PlayerPet.fromRaw(raw(json, true, 'Unknown'));
  }
  static fromRaw(input: RawPlayerItemInput) {
    return new PlayerPet({
      ...base({ ...input, isUnlocked: true }, 'pet', ImageAssets.getPetImage(input.name)),
      village: string(input.meta?.village, 'home'),
    });
  }
}
export class PlayerSiegeMachine extends VillageItem {
  static fromJson(json: JsonRecord) {
    return PlayerSiegeMachine.fromRaw(raw(json, true, 'Unknown'));
  }
  static fromRaw(input: RawPlayerItemInput) {
    return new PlayerSiegeMachine({
      ...base(input, 'pet', ImageAssets.getSiegeMachineImage(input.name)),
      village: string(input.meta?.village, 'home'),
    });
  }
}
function raw(json: JsonRecord, isUnlocked: boolean, fallback = 'No name'): RawPlayerItemInput {
  return {
    name: string(json.name, fallback),
    level: int(json.level),
    maxLevel: int(json.maxLevel),
    isUnlocked,
    meta: { village: string(json.village, 'home') },
    rawJson: json,
  };
}
function base(input: RawPlayerItemInput, type: string, imageUrl: string): PlayerItemInput {
  return {
    name: input.name,
    level: input.level,
    maxLevel: input.maxLevel,
    isUnlocked: input.isUnlocked,
    meta: input.meta,
    type,
    imageUrl,
  };
}
function validBuilderBaseLevel(apiLevel: number, meta?: JsonRecord | null) {
  if (apiLevel <= 0 || !Array.isArray(meta?.levels)) return apiLevel;
  const levels = meta.levels
    .map((entry) => (isRecord(entry) ? int(entry.level, Number.NaN) : Number.NaN))
    .filter((level) => Number.isFinite(level) && level > 0);
  return levels.length === 0 ? apiLevel : Math.max(apiLevel, Math.min(...levels));
}
