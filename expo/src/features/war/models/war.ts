import { ClanBadgeUrls } from '../../clan/models/clan-core';
import {
  apiDate,
  int,
  nullableInt,
  number,
  record,
  records,
  string,
  type JsonRecord,
} from './parsing';

export class MiniMember {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly townhallLevel: number,
    readonly mapPosition: number,
    readonly opponentAttacks: number | null,
  ) {}
  static fromJson(json: JsonRecord): MiniMember {
    return new MiniMember(
      string(json.tag),
      string(json.name),
      int(json.townhallLevel),
      int(json.mapPosition),
      nullableInt(json.opponentAttacks),
    );
  }
}

export class WarAttack {
  constructor(
    readonly attackerTag: string,
    readonly defenderTag: string,
    readonly stars: number,
    readonly destructionPercentage: number,
    readonly order: number,
    readonly duration: number | null = null,
    readonly defender: MiniMember | null = null,
    readonly attacker: MiniMember | null = null,
  ) {}
  static fromJson(json: JsonRecord): WarAttack {
    return new WarAttack(
      string(json.attackerTag),
      string(json.defenderTag),
      int(json.stars),
      number(json.destructionPercentage),
      int(json.order),
      nullableInt(json.duration),
      Object.keys(record(json.defender)).length ? MiniMember.fromJson(record(json.defender)) : null,
      Object.keys(record(json.attacker)).length ? MiniMember.fromJson(record(json.attacker)) : null,
    );
  }
  toJson(): JsonRecord {
    return {
      attackerTag: this.attackerTag,
      defenderTag: this.defenderTag,
      stars: this.stars,
      destructionPercentage: this.destructionPercentage,
      order: this.order,
      duration: this.duration,
    };
  }
}

export class WarMember {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly townhallLevel: number,
    readonly mapPosition: number,
    readonly opponentAttacks: number,
    readonly attacks: readonly WarAttack[] | null = null,
    readonly bestOpponentAttack: WarAttack | null = null,
  ) {}
  static fromJson(value: unknown): WarMember {
    const json = record(value);
    return new WarMember(
      string(json.tag),
      string(json.name),
      int(json.townhallLevel),
      int(json.mapPosition),
      int(json.opponentAttacks),
      Array.isArray(json.attacks) ? records(json.attacks).map(WarAttack.fromJson) : null,
      Object.keys(record(json.bestOpponentAttack)).length
        ? WarAttack.fromJson(record(json.bestOpponentAttack))
        : null,
    );
  }
  static empty(): WarMember {
    return new WarMember('', '', 0, 0, 0, [], null);
  }
  toJson(): JsonRecord {
    return {
      tag: this.tag,
      name: this.name,
      townhallLevel: this.townhallLevel,
      mapPosition: this.mapPosition,
      opponentAttacks: this.opponentAttacks,
      attacks: this.attacks?.map((attack) => attack.toJson()) ?? null,
      bestOpponentAttack: this.bestOpponentAttack?.toJson() ?? null,
    };
  }
}

export class WarClan {
  constructor(
    readonly tag: string,
    readonly name: string,
    readonly badgeUrls: ClanBadgeUrls,
    readonly clanLevel: number,
    readonly attacks: number,
    readonly stars: number,
    readonly destructionPercentage: number,
    readonly members: readonly WarMember[],
  ) {}
  static fromJson(value: unknown): WarClan {
    try {
      const json = record(value);
      return new WarClan(
        string(json.tag, 'No tag'),
        string(json.name, 'No name'),
        ClanBadgeUrls.fromJson(json.badgeUrls),
        int(json.clanLevel),
        int(json.attacks),
        int(json.stars),
        number(json.destructionPercentage),
        records(json.members).map(WarMember.fromJson),
      );
    } catch {
      return WarClan.empty();
    }
  }
  static empty(): WarClan {
    return new WarClan('No tag', 'No name', ClanBadgeUrls.empty(), 0, 0, 0, 0, []);
  }
  getAverageAttackTime(): number | null {
    const durations = this.members.flatMap((member) =>
      (member.attacks ?? [])
        .map((attack) => attack.duration)
        .filter((value): value is number => value !== null),
    );
    return durations.length
      ? durations.reduce((total, duration) => total + duration, 0) / durations.length
      : null;
  }
  toJson(): JsonRecord {
    return {
      tag: this.tag,
      name: this.name,
      clanLevel: this.clanLevel,
      attacks: this.attacks,
      stars: this.stars,
      destructionPercentage: this.destructionPercentage,
      members: this.members.map((member) => member.toJson()),
    };
  }
}

export class WarInfo {
  constructor(
    readonly state: string,
    readonly tag: string | null = null,
    readonly teamSize: number | null = null,
    readonly attacksPerMember: number | null = null,
    readonly clan: WarClan | null = null,
    readonly opponent: WarClan | null = null,
    readonly startTime: Date | null = null,
    readonly endTime: Date | null = null,
    readonly preparationStartTime: Date | null = null,
    readonly warType: string | null = null,
  ) {}
  static fromJson(value: unknown): WarInfo {
    try {
      const json = record(value);
      return new WarInfo(
        string(json.state, 'unknown'),
        json.war_tag == null ? null : string(json.war_tag),
        nullableInt(json.teamSize),
        nullableInt(json.attacksPerMember),
        Object.keys(record(json.clan)).length ? WarClan.fromJson(json.clan) : null,
        Object.keys(record(json.opponent)).length ? WarClan.fromJson(json.opponent) : null,
        apiDate(json.startTime),
        apiDate(json.endTime),
        apiDate(json.preparationStartTime),
        string(json.warType ?? json.type, 'unknown'),
      );
    } catch {
      return new WarInfo('unknown');
    }
  }
  static empty(): WarInfo {
    return new WarInfo('unknown', null, null, null, WarClan.empty(), WarClan.empty());
  }
  get isClanWarLeague(): boolean {
    const type = this.warType?.toLowerCase() ?? '';
    return type === 'cwl' || type.includes('league') || type.includes('clanwarleague');
  }
  get effectiveAttacksPerMember(): number {
    return this.isClanWarLeague || this.attacksPerMember === null ? 1 : this.attacksPerMember;
  }
  getMemberByTag(tag: string): WarMember | null {
    return (
      [...(this.clan?.members ?? []), ...(this.opponent?.members ?? [])].find(
        (member) => member.tag === tag,
      ) ?? null
    );
  }
  getTownhallLevelByTag(tag: string): number | null {
    return this.getMemberByTag(tag)?.townhallLevel ?? null;
  }
  getMapPositionByTag(tag: string): number | null {
    return this.getMemberByTag(tag)?.mapPosition ?? null;
  }
  getNameByTag(tag: string): string | null {
    return this.getMemberByTag(tag)?.name ?? null;
  }
  getAttacksDoneByPlayer(playerTag: string, clanTag: string): number {
    const side =
      this.clan?.tag === clanTag
        ? this.clan
        : this.opponent?.tag === clanTag
          ? this.opponent
          : null;
    return side?.members.find((member) => member.tag === playerTag)?.attacks?.length ?? 0;
  }
  isPlayerInWar(playerTag: string, clanTag: string): boolean {
    const side =
      this.clan?.tag === clanTag
        ? this.clan
        : this.opponent?.tag === clanTag
          ? this.opponent
          : null;
    return side?.members.some((member) => member.tag === playerTag) ?? false;
  }
  getWarResult(clanTag: string): 'unknown' | 'perfectWar' | 'won' | 'lost' | 'tie' | 'inWar' {
    if (this.clan?.tag !== clanTag && this.opponent?.tag !== clanTag) return 'unknown';
    if (this.state !== 'warEnded') return 'inWar';
    if (this.clan?.destructionPercentage === 100 && this.opponent?.destructionPercentage === 100)
      return 'perfectWar';
    const mine = this.clan?.tag === clanTag ? this.clan : this.opponent;
    const theirs = this.clan?.tag === clanTag ? this.opponent : this.clan;
    if (!mine || !theirs) return 'unknown';
    if (mine.stars !== theirs.stars) return mine.stars > theirs.stars ? 'won' : 'lost';
    if (mine.destructionPercentage !== theirs.destructionPercentage)
      return mine.destructionPercentage > theirs.destructionPercentage ? 'won' : 'lost';
    return 'tie';
  }
  reorderForUser(playerTag: string): WarInfo {
    const inClan = this.clan?.members.some((member) => member.tag === playerTag) ?? false;
    const inOpponent = this.opponent?.members.some((member) => member.tag === playerTag) ?? false;
    return inOpponent && !inClan ? this.swapped() : this;
  }
  reorderForClan(clanTag: string): WarInfo {
    const target = clanTag.startsWith('#') ? clanTag : `#${clanTag}`;
    const left = this.clan?.tag
      ? this.clan.tag.startsWith('#')
        ? this.clan.tag
        : `#${this.clan.tag}`
      : null;
    const right = this.opponent?.tag
      ? this.opponent.tag.startsWith('#')
        ? this.opponent.tag
        : `#${this.opponent.tag}`
      : null;
    if (left === target) return this;
    return right === target ? this.swapped() : this;
  }
  private swapped(): WarInfo {
    return new WarInfo(
      this.state,
      this.tag,
      this.teamSize,
      this.attacksPerMember,
      this.opponent,
      this.clan,
      this.startTime,
      this.endTime,
      this.preparationStartTime,
      this.warType,
    );
  }
}

export class WarMemberPresence {
  constructor(
    readonly isInWar: boolean,
    readonly attacksDone = 0,
    readonly attacksAvailable = 0,
  ) {}
  static empty(): WarMemberPresence {
    return new WarMemberPresence(false);
  }
}
