import { CwlLeague, CwlLeagueRound } from './cwl';
import { normalizeWarTag, record, records, string, type JsonRecord } from './parsing';
import { WarInfo, WarMemberPresence } from './war';

export class WarCwl {
  constructor(
    readonly tag: string,
    readonly isInWar: boolean,
    readonly isInCwl: boolean,
    readonly warInfo: WarInfo,
    readonly leagueInfo: CwlLeague | null,
    readonly warLeagueInfos: readonly WarInfo[],
  ) {}

  static fromJson(json: JsonRecord, fallbackTag: string | null = null): WarCwl {
    try {
      const warInfoData = record(json.war_info);
      const warState = string(warInfoData.state, 'notInWar');
      const leagueInfoData = record(json.league_info);
      const warLeagueInfos = records(json.war_league_infos)
        .map(WarInfo.fromJson)
        .filter((war) => war.state !== 'unknown' || war.clan !== null || war.opponent !== null);
      return new WarCwl(
        string(json.clan_tag, fallbackTag ?? ''),
        json.isInWar === true,
        json.isInCwl === true,
        warState !== 'notInWar'
          ? WarInfo.fromJson(warInfoData.currentWarInfo)
          : new WarInfo('notInWar'),
        Object.keys(leagueInfoData).length ? CwlLeague.fromJson(leagueInfoData) : null,
        warLeagueInfos,
      );
    } catch {
      return new WarCwl(
        string(json.clan_tag, fallbackTag ?? ''),
        false,
        false,
        new WarInfo('unknown'),
        null,
        [],
      );
    }
  }

  get teamSize(): number {
    for (const war of this.warLeagueInfos) if ((war.teamSize ?? 0) > 0) return war.teamSize!;
    if ((this.warInfo.teamSize ?? 0) > 0) return this.warInfo.teamSize!;
    for (const war of [...this.warLeagueInfos, this.warInfo]) {
      const size = lineupSizeForClan(war, this.tag);
      if (size > 0) return size;
    }
    return 0;
  }

  getActiveWarByTag(tag: string): WarInfo | null {
    try {
      const normalized = ensureHashPrefix(tag);
      const matches = (war: WarInfo) =>
        (war.clan !== null && ensureHashPrefix(war.clan.tag) === normalized) ||
        (war.opponent !== null && ensureHashPrefix(war.opponent.tag) === normalized);
      for (const state of ['inWar', 'preparation'] as const) {
        const found = this.warLeagueInfos.find((war) => war.state === state && matches(war));
        if (found) return found.reorderForClan(normalized);
      }
      const ended = this.warLeagueInfos
        .filter((war) => war.state === 'warEnded' && matches(war))
        .sort((left, right) =>
          (right.endTime?.toISOString() ?? '').localeCompare(left.endTime?.toISOString() ?? ''),
        );
      return ended[0]?.reorderForClan(normalized) ?? null;
    } catch {
      return null;
    }
  }

  getRoundForWarTag(warTag: string | null): CwlLeagueRound {
    return (
      this.leagueInfo?.rounds.find((round) => round.containsWar(warTag)) ??
      new CwlLeagueRound(-1, [])
    );
  }

  getWarInfoFromTag(tag: string): WarInfo {
    return this.warLeagueInfos.find((war) => war.tag === tag) ?? new WarInfo('unknown');
  }

  getActiveWarForClan(clanTag: string): WarInfo {
    return this.getActiveWarByTag(clanTag) ?? new WarInfo('notInCwl');
  }

  getMemberPresence(memberTag: string, clanTag: string): WarMemberPresence {
    try {
      const war = this.getActiveWarForClan(clanTag);
      if (war.state !== 'inWar') return new WarMemberPresence(false);
      const member = war.getMemberByTag(memberTag);
      return member
        ? new WarMemberPresence(true, member.attacks?.length ?? 0, war.effectiveAttacksPerMember)
        : new WarMemberPresence(false);
    } catch {
      return new WarMemberPresence(false);
    }
  }

  getActiveWarByPlayerTag(playerTag: string): WarInfo | null {
    try {
      const contains = (war: WarInfo) =>
        war.clan?.members.some((member) => member.tag === playerTag) === true ||
        war.opponent?.members.some((member) => member.tag === playerTag) === true;
      for (const state of ['inWar', 'preparation'] as const) {
        const found = this.warLeagueInfos.find((war) => war.state === state && contains(war));
        if (found) return found.reorderForUser(playerTag);
      }
      const ended = this.warLeagueInfos
        .filter((war) => war.state === 'warEnded' && contains(war))
        .sort((left, right) =>
          (right.endTime?.toISOString() ?? '').localeCompare(left.endTime?.toISOString() ?? ''),
        );
      return ended[0]?.reorderForUser(playerTag) ?? null;
    } catch {
      return null;
    }
  }
}

function lineupSizeForClan(war: WarInfo, clanTag: string): number {
  const normalized = normalizeWarTag(clanTag);
  if (normalizeWarTag(war.clan?.tag) === normalized) return war.clan?.members.length ?? 0;
  if (normalizeWarTag(war.opponent?.tag) === normalized) return war.opponent?.members.length ?? 0;
  return 0;
}

function ensureHashPrefix(tag: string): string {
  return tag.startsWith('#') ? tag : `#${tag}`;
}
