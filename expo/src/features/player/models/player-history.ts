import { ImageAssets } from '@/core/assets/image-assets';
import {
  date,
  int,
  nullableInt,
  nullableString,
  record,
  records,
  string,
  strings,
  type JsonRecord,
} from './parsing';

export const PlayerHistoryType = {
  troopLevel: 'troop_level',
  superTroopBoost: 'super_troop_boost',
  heroLevel: 'hero_level',
  spellLevel: 'spell_level',
  petLevel: 'pet_level',
  equipmentLevel: 'equipment_level',
  townHallLevel: 'townhall_level',
  experienceLevel: 'exp_level',
  bestTrophies: 'best_trophies',
  bestBuilderBaseTrophies: 'best_builder_base_trophies',
  warPreference: 'war_preference',
} as const;
export type PlayerHistoryTypeValue = (typeof PlayerHistoryType)[keyof typeof PlayerHistoryType];
export const PlayerActivityKind = {
  townHallUpgrade: 'townHallUpgrade',
  troopUpgrade: 'troopUpgrade',
  heroUpgrade: 'heroUpgrade',
  spellUpgrade: 'spellUpgrade',
  petUpgrade: 'petUpgrade',
  equipmentUpgrade: 'equipmentUpgrade',
  superTroopBoost: 'superTroopBoost',
  itemUnlocked: 'itemUnlocked',
  experienceLevelChange: 'experienceLevelChange',
  trophyRecord: 'trophyRecord',
  builderTrophyRecord: 'builderTrophyRecord',
  warPreferenceChange: 'warPreferenceChange',
} as const;
export type PlayerActivityKindValue = (typeof PlayerActivityKind)[keyof typeof PlayerActivityKind];
export type PlayerActivityItemType =
  'townHall' | 'troop' | 'hero' | 'spell' | 'pet' | 'equipment' | 'trophy' | 'profile';
export interface PlayerActivityEvent {
  time: Date;
  kind: PlayerActivityKindValue;
  itemType: PlayerActivityItemType;
  name: string;
  itemId: number | null;
  townHallLevel: number | null;
  previousLevel: number | null;
  currentLevel: number | null;
  previousValue: string | null;
  currentValue: string | null;
}
export class PlayerActivityFeed {
  constructor(readonly items: readonly PlayerActivityEvent[]) {}
  static fromJson(json: JsonRecord) {
    const items = records(json.items)
      .map(activityEvent)
      .filter((item): item is PlayerActivityEvent => item !== null)
      .sort((a, b) => b.time.getTime() - a.time.getTime());
    return new PlayerActivityFeed(items);
  }
}
function activityEvent(change: JsonRecord): PlayerActivityEvent | null {
  const time = date(change.time);
  const type = string(change.type);
  if (!time || type === 'name') return null;
  const item = record(change.item);
  const previousLevel = nullableInt(change.previous);
  const currentLevel = nullableInt(change.current);
  const upgradeKind: Record<string, PlayerActivityKindValue> = {
    troop_level: previousLevel === 0 ? 'itemUnlocked' : 'troopUpgrade',
    super_troop_boost: 'superTroopBoost',
    hero_level: previousLevel === 0 ? 'itemUnlocked' : 'heroUpgrade',
    spell_level: previousLevel === 0 ? 'itemUnlocked' : 'spellUpgrade',
    pet_level: previousLevel === 0 ? 'itemUnlocked' : 'petUpgrade',
    equipment_level: previousLevel === 0 ? 'itemUnlocked' : 'equipmentUpgrade',
    townhall_level: 'townHallUpgrade',
    exp_level: 'experienceLevelChange',
    best_trophies: 'trophyRecord',
    best_builder_base_trophies: 'builderTrophyRecord',
    war_preference: 'warPreferenceChange',
  };
  const kind = upgradeKind[type];
  if (!kind) return null;
  const itemTypes: Record<string, PlayerActivityItemType> = {
    troop_level: 'troop',
    super_troop_boost: 'troop',
    hero_level: 'hero',
    spell_level: 'spell',
    pet_level: 'pet',
    equipment_level: 'equipment',
    townhall_level: 'townHall',
    best_trophies: 'trophy',
    best_builder_base_trophies: 'trophy',
  };
  return {
    time,
    kind,
    itemType: itemTypes[type] ?? 'profile',
    name: string(item.name),
    itemId: nullableInt(item.id),
    townHallLevel: nullableInt(change.townhall_level),
    previousLevel,
    currentLevel,
    previousValue: nullableString(change.previous),
    currentValue: nullableString(change.current),
  };
}

export class PlayerCwlHistory {
  constructor(readonly items: readonly PlayerCwlSeason[]) {}
  static fromJson(json: JsonRecord) {
    return new PlayerCwlHistory(records(json.items).map(PlayerCwlSeason.fromJson));
  }
}
export class PlayerCwlSeason {
  constructor(
    readonly season: string,
    readonly townHallLevel: number,
    readonly teamSize: number | null,
    readonly clan: PlayerCwlClan,
    readonly attacks: readonly PlayerCwlAttack[],
    readonly clanPlacement: number | null,
    readonly groupPlacement: number | null,
    readonly missedAttacks: number,
  ) {}
  get stars() {
    return this.attacks.reduce((sum, item) => sum + item.stars, 0);
  }
  static fromJson(json: JsonRecord) {
    const placement = record(json.placement);
    return new PlayerCwlSeason(
      string(json.season),
      int(json.townHallLevel),
      nullableInt(json.teamSize),
      PlayerCwlClan.fromJson(record(json.clan)),
      records(json.attacks).map(PlayerCwlAttack.fromJson),
      nullableInt(placement.clan),
      nullableInt(placement.group),
      int(json.missedAttacks),
    );
  }
}
export class PlayerCwlClan {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly badgeUrl: string,
    readonly leagueName: string,
    readonly won: number,
    readonly lost: number,
    readonly tied: number,
    readonly totalStars: number | null,
    readonly groupPlacement: number | null,
    readonly globalPlacement: number | null,
  ) {}
  static fromJson(json: JsonRecord) {
    const badges = record(json.badgeUrls),
      league = record(json.warLeague),
      wars = record(json.wars),
      placement = record(json.placement);
    return new PlayerCwlClan(
      string(json.tag),
      string(json.name),
      string(badges.small ?? badges.medium ?? badges.large),
      string(league.name),
      int(wars.won),
      int(wars.lost),
      int(wars.tied),
      nullableInt(json.totalStars),
      nullableInt(placement.group),
      nullableInt(placement.global),
    );
  }
}
export class PlayerCwlAttack {
  constructor(
    readonly warTag: string,
    readonly round: number,
    readonly opponentName: string,
    readonly opponentTag: string,
    readonly defenderName: string,
    readonly defenderTag: string,
    readonly defenderTownHallLevel: number,
    readonly defenderMapPosition: number,
    readonly stars: number,
    readonly destructionPercentage: number,
    readonly order: number,
    readonly duration: number,
  ) {}
  static fromJson(json: JsonRecord) {
    const opponent = record(json.opponent),
      defender = record(json.defender);
    return new PlayerCwlAttack(
      string(json.warTag),
      int(json.round),
      string(opponent.name),
      string(opponent.tag),
      string(defender.name),
      string(defender.tag),
      int(defender.townHallLevel),
      int(defender.mapPosition),
      int(json.stars),
      int(json.destructionPercentage),
      int(json.order),
      int(json.duration),
    );
  }
}

export type PlayerTimerType = 'war' | 'cwl' | 'capital';
export class PlayerTimer {
  constructor(
    readonly type: PlayerTimerType,
    readonly expiresAt: Date,
    readonly clans: readonly string[],
    readonly warTag: string | null,
  ) {}
  static fromJson(json: JsonRecord) {
    const raw = string(json.type);
    return new PlayerTimer(
      raw === 'cwl' || raw === 'capital' ? raw : 'war',
      date(json.expiresAt) ?? new Date(0),
      strings(json.clans),
      nullableString(json.warTag),
    );
  }
}
export class PlayerTimers {
  constructor(readonly items: readonly PlayerTimer[]) {}
  static fromJson(json: JsonRecord) {
    return new PlayerTimers(records(json.items).map(PlayerTimer.fromJson));
  }
}

export class JoinLeaveClan {
  constructor(
    readonly name: string,
    readonly tag: string,
    readonly badge: string,
  ) {}
  static fromJson(json: JsonRecord) {
    const tag = string(json.tag);
    return new JoinLeaveClan(string(json.name), tag, ImageAssets.clanBadgeForTag(tag));
  }
}
export class JoinLeaveEvent {
  constructor(
    readonly type: string,
    readonly clan: JoinLeaveClan | null,
    readonly time: Date,
    readonly tag: string,
    readonly name: string,
    readonly th: number,
  ) {}
  static fromJson(json: JsonRecord) {
    return new JoinLeaveEvent(
      string(json.type),
      json.clan && typeof json.clan === 'object' ? JoinLeaveClan.fromJson(record(json.clan)) : null,
      date(json.time) ?? new Date(0),
      string(json.tag),
      string(json.name),
      int(json.townHallLevel, int(json.th)),
    );
  }
}
export class PlayerJoinLeavePage {
  constructor(
    readonly available: number,
    readonly items: readonly JoinLeaveEvent[],
  ) {}
  static fromJson(json: JsonRecord) {
    return new PlayerJoinLeavePage(
      int(json.available),
      records(json.items).map(JoinLeaveEvent.fromJson),
    );
  }
}
export class PlayerJoinLeaveTotal {
  constructor(
    readonly clan: JoinLeaveClan,
    readonly visits: number,
    readonly minutes: number,
  ) {}
  static fromJson(json: JsonRecord) {
    return new PlayerJoinLeaveTotal(
      JoinLeaveClan.fromJson(record(json.clan)),
      int(json.visits),
      int(json.minutes),
    );
  }
}
