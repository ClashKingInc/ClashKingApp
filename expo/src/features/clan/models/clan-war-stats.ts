import {
  buildPlayerWarStatsFromHistory,
  PlayerWarStats,
  WarInfoSnapshot,
  WarMemberData,
  type WarHistoryFilter,
} from '../../player/models';
import { canonicalTag } from '../../../core/domain/tags';
import { int, record, records, string, type JsonRecord } from './parsing';

export class ClanWarStatsData {
  constructor(
    readonly warDetails: WarInfoSnapshot,
    readonly membersData: readonly WarMemberData[],
  ) {}
  static fromJson(json: JsonRecord) {
    try {
      return new ClanWarStatsData(
        WarInfoSnapshot.fromJson(record(json.war_data)),
        records(json.members).map(WarMemberData.fromJson),
      );
    } catch {
      return new ClanWarStatsData(WarInfoSnapshot.fromJson({}), []);
    }
  }
}

export class ClanWarStats {
  constructor(
    readonly players: readonly PlayerWarStats[],
    readonly clanTag: string,
    readonly wars: readonly ClanWarStatsData[],
  ) {}
  static fromJson(json: JsonRecord) {
    try {
      return new ClanWarStats(
        records(json.players).map((player) => PlayerWarStats.fromJson(player, null, null)),
        string(json.clan_tag),
        records(json.wars).map(ClanWarStatsData.fromJson),
      );
    } catch {
      return ClanWarStats.empty();
    }
  }
  static empty() {
    return new ClanWarStats([], '', []);
  }
}

export function buildClanWarStatsFromWars(
  values: readonly unknown[],
  clanTag: string,
  filter: WarHistoryFilter = {},
): ClanWarStats {
  const normalizedTag = canonicalTag(clanTag);
  const wars = records(values);
  const historyByPlayer = new Map<string, JsonRecord[]>();
  const warData: ClanWarStatsData[] = [];
  for (const war of wars) {
    const left = record(war.clan);
    const right = record(war.opponent);
    const own = canonicalTag(string(left.tag)) === normalizedTag ? left : right;
    const opponent = own === left ? right : left;
    const opponents = new Map(
      records(opponent.members).map((member) => [string(member.tag), member]),
    );
    const allOpponentAttacks = records(opponent.members).flatMap((member) =>
      records(member.attacks).map((attack) => ({ attack, attacker: member })),
    );
    const members: WarMemberData[] = [];
    for (const member of records(own.members)) {
      const tag = string(member.tag);
      const attacks = records(member.attacks).map((attack) => ({
        ...attack,
        fresh: firstAttackOrder(war, string(attack.defenderTag)) === int(attack.order),
        player: opponents.get(string(attack.defenderTag)) ?? {},
      }));
      const defenses = allOpponentAttacks
        .filter(({ attack }) => string(attack.defenderTag) === tag)
        .map(({ attack, attacker }) => ({
          ...attack,
          fresh: firstAttackOrder(war, tag) === int(attack.order),
          player: attacker,
        }));
      const history = {
        ...war,
        player: {
          tag,
          name: member.name,
          townhallLevel: member.townhallLevel,
          mapPosition: member.mapPosition,
        },
        clan: own,
        opponent,
        attacks,
        defenses,
      };
      historyByPlayer.set(tag, [...(historyByPlayer.get(tag) ?? []), history]);
      const playerStats = buildPlayerWarStatsFromHistory([history], tag, filter);
      members.push(playerStats.wars[0]?.memberData ?? WarMemberData.empty());
    }
    warData.push(new ClanWarStatsData(WarInfoSnapshot.fromJson(war), members));
  }
  return new ClanWarStats(
    [...historyByPlayer].map(([tag, history]) =>
      buildPlayerWarStatsFromHistory(history, tag, filter),
    ),
    normalizedTag,
    warData,
  );
}

function firstAttackOrder(war: JsonRecord, defenderTag: string): number {
  const attacks = [record(war.clan), record(war.opponent)].flatMap((side) =>
    records(side.members).flatMap((member) => records(member.attacks)),
  );
  const orders = attacks
    .filter((attack) => string(attack.defenderTag) === defenderTag)
    .map((attack) => int(attack.order))
    .filter((order) => order > 0);
  return orders.length ? Math.min(...orders) : -1;
}
