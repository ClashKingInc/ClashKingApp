import type { ClanMember } from './clan-core';

export interface ClanLegendDayStats {
  readonly tag: string;
  readonly attackTrophies: number;
  readonly defenseTrophies: number;
  readonly netTrophies: number;
  readonly attacks: number;
  readonly defenses: number;
}
export interface ClanCompetitiveDay {
  readonly day: string;
  readonly legends: readonly {
    readonly member: ClanMember;
    readonly globalRank?: number;
    readonly trophies?: number;
    readonly stats?: ClanLegendDayStats;
  }[];
}
export function isLegendMember(member: ClanMember): boolean {
  // This clan page is for Legend I only. Use the current tier ID rather
  // than a name prefix, which also accepts Legend II/III and legacy tiers.
  return member.league.id === 105000036;
}
export function isRankedMember(member: ClanMember): boolean {
  return !isLegendMember(member) && member.league.id >= 105000001 && member.league.id <= 105000035;
}
export function hasCompetitiveMembers(members: readonly ClanMember[]): boolean {
  return members.some(isLegendMember);
}
