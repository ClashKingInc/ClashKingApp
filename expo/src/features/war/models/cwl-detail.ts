import { CwlLeague } from './cwl';
import { records, string, type JsonRecord } from './parsing';
import type { WarAttack, WarInfo, WarMember } from './war';

/** Presentation aggregates from the complete group, never the home card's partial wars. */
export function enrichCwlDetail(group: JsonRecord, wars: readonly WarInfo[]): CwlLeague {
  const clans = records(group.clans).map((clan) => {
    const tag = string(clan.tag);
    const played = wars
      .filter(
        (war) =>
          (war.state === 'inWar' || war.state === 'warEnded') &&
          (war.clan?.tag === tag || war.opponent?.tag === tag),
      )
      .map((war) => war.reorderForClan(tag));
    const members = records(clan.members).map((member) => {
      const appearances = played.flatMap((war) => {
        const own = war.clan?.members.find((candidate) => candidate.tag === member.tag);
        return own ? [{ war, own }] : [];
      });
      const attacks = appearances.flatMap(({ war, own }) =>
        (own.attacks ?? []).map((hit) => ({
          hit,
          own,
          other: war.opponent?.members.find((opponent) => opponent.tag === hit.defenderTag),
        })),
      );
      const defenses = appearances.flatMap(({ war, own }) =>
        own.bestOpponentAttack
          ? [
              {
                hit: own.bestOpponentAttack,
                own,
                other: war.opponent?.members.find(
                  (opponent) => opponent.tag === own.bestOpponentAttack?.attackerTag,
                ),
              },
            ]
          : [],
      );
      const missed = appearances.reduce(
        (total, { war, own }) =>
          total +
          (war.state === 'warEnded'
            ? Math.max(0, war.effectiveAttacksPerMember - (own.attacks?.length ?? 0))
            : 0),
        0,
      );
      return {
        ...member,
        avgMapPosition: average(appearances.map(({ own }) => own.mapPosition)),
        avgTownHallLevel: average(appearances.map(({ own }) => own.townhallLevel)),
        avgOpponentPosition: average(
          attacks.flatMap(({ other }) => (other ? [other.mapPosition] : [])),
        ),
        avgOpponentTownHallLevel: average(
          attacks.flatMap(({ other }) => (other ? [other.townhallLevel] : [])),
        ),
        avgAttackOrder: average(attacks.map(({ hit }) => hit.order)),
        avgAttackerPosition: average(
          defenses.flatMap(({ other }) => (other ? [other.mapPosition] : [])),
        ),
        avgAttackerTownHallLevel: average(
          defenses.flatMap(({ other }) => (other ? [other.townhallLevel] : [])),
        ),
        avgDefenseOrder: average(defenses.map(({ hit }) => hit.order)),
        attackLowerTHLevel: attacks.filter(
          ({ own, other }) => other && other.townhallLevel < own.townhallLevel,
        ).length,
        attackUpperTHLevel: attacks.filter(
          ({ own, other }) => other && other.townhallLevel > own.townhallLevel,
        ).length,
        defenseLowerTHLevel: defenses.filter(
          ({ own, other }) => other && other.townhallLevel < own.townhallLevel,
        ).length,
        defenseUpperTHLevel: defenses.filter(
          ({ own, other }) => other && other.townhallLevel > own.townhallLevel,
        ).length,
        attacks: { ...score(attacks), attack_count: attacks.length, missed_attacks: missed },
        defense: {
          ...score(defenses),
          defense_count: defenses.length,
          missed_defenses: appearances.filter(
            ({ war, own }) => war.state === 'warEnded' && !own.bestOpponentAttack,
          ).length,
        },
      };
    });
    const levels: Record<string, number> = {};
    for (const member of records(clan.members)) {
      const level = Number(member.townHallLevel);
      if (level > 0) levels[level] = (levels[level] ?? 0) + 1;
    }
    return {
      ...clan,
      tag,
      members,
      town_hall_levels: levels,
      wars_played: played.length,
      total_stars: played.reduce((sum, war) => sum + (war.clan?.stars ?? 0), 0),
      attack_count: played.reduce((sum, war) => sum + (war.clan?.attacks ?? 0), 0),
      total_destruction: members.reduce((sum, member) => sum + member.defense.total_destruction, 0),
      total_destruction_inflicted: members.reduce(
        (sum, member) => sum + member.attacks.total_destruction,
        0,
      ),
    };
  });
  // Match the API's mobile season aggregates: raw stars, then destruction inflicted.
  const ranked = [...clans].sort(
    (a, b) =>
      b.total_stars - a.total_stars ||
      b.total_destruction_inflicted - a.total_destruction_inflicted ||
      string(a.tag).localeCompare(string(b.tag)),
  );
  return CwlLeague.fromJson({
    ...group,
    clans: clans.map((clan) => ({
      ...clan,
      rank: clan.wars_played ? ranked.indexOf(clan) + 1 : 0,
    })),
  });
}

function average(values: number[]): number | null {
  return values.length ? values.reduce((sum, value) => sum + value, 0) / values.length : null;
}

function score(hits: { hit: WarAttack; other: WarMember | undefined }[]) {
  const buckets: Record<string, Record<string, number>> = {
    '3_stars': {},
    '2_stars': {},
    '1_star': {},
    '0_star': {},
  };
  for (const { hit, other } of hits) {
    if (!other || other.townhallLevel <= 0) continue;
    const bucket = buckets[['0_star', '1_star', '2_stars', '3_stars'][hit.stars]!]!;
    bucket[other.townhallLevel] = (bucket[other.townhallLevel] ?? 0) + 1;
  }
  return {
    ...buckets,
    stars: hits.reduce((sum, { hit }) => sum + hit.stars, 0),
    total_destruction: hits.reduce((sum, { hit }) => sum + hit.destructionPercentage, 0),
  };
}
