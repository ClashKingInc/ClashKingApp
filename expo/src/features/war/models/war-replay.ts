import { WarClan, WarInfo, WarMember, type WarAttack } from './war';

export type WarReplayEvent = {
  attack: WarAttack;
  side: 'clan' | 'opponent';
  attacker: WarMember;
  defender: WarMember | null;
};
export type WarReplayPoint = {
  order: number;
  clanStars: number;
  opponentStars: number;
  clanPercent: number;
  opponentPercent: number;
};

const better = (left: WarAttack, right: WarAttack) =>
  left.stars > right.stars ||
  (left.stars === right.stars && left.destructionPercentage > right.destructionPercentage);

/** Reconstruct the score from each base's best hit, never the sum of every hit.
 * Attack order is the only chronology available: it is not elapsed war time.
 * Missing orders or a mismatch with the authoritative score disable replay. */
export function buildWarReplay(war: WarInfo) {
  const events: WarReplayEvent[] = [];
  for (const side of ['clan', 'opponent'] as const) {
    const other = side === 'clan' ? war.opponent : war.clan;
    for (const attacker of war[side]?.members ?? []) {
      for (const attack of attacker.attacks ?? []) {
        events.push({
          attack,
          side,
          attacker,
          defender: other?.members.find((member) => member.tag === attack.defenderTag) ?? null,
        });
      }
    }
  }
  events.sort((a, b) => a.attack.order - b.attack.order);
  const best = { clan: new Map<string, WarAttack>(), opponent: new Map<string, WarAttack>() };
  const points: WarReplayPoint[] = [
    { order: 0, clanStars: 0, opponentStars: 0, clanPercent: 0, opponentPercent: 0 },
  ];
  const sum = (side: 'clan' | 'opponent') =>
    [...best[side].values()].reduce(
      (value, hit) => ({
        stars: value.stars + hit.stars,
        percent: value.percent + hit.destructionPercentage / (war.teamSize || 1),
      }),
      { stars: 0, percent: 0 },
    );
  let valid = !!war.clan && !!war.opponent && (war.teamSize ?? 0) > 0;
  events.forEach((event, index) => {
    const hit = event.attack;
    valid &&=
      hit.order === index + 1 &&
      !!event.defender &&
      hit.stars >= 0 &&
      hit.stars <= 3 &&
      Number.isInteger(hit.stars) &&
      Number.isFinite(hit.destructionPercentage) &&
      hit.destructionPercentage >= 0 &&
      hit.destructionPercentage <= 100;
    const previous = best[event.side].get(hit.defenderTag);
    if (!previous || better(hit, previous)) best[event.side].set(hit.defenderTag, hit);
    const clan = sum('clan'),
      opponent = sum('opponent');
    points.push({
      order: hit.order,
      clanStars: clan.stars,
      opponentStars: opponent.stars,
      clanPercent: clan.percent,
      opponentPercent: opponent.percent,
    });
  });
  const final = points[points.length - 1]!;
  const count = (side: 'clan' | 'opponent') => events.filter((event) => event.side === side).length;
  const complete =
    valid &&
    events.length > 0 &&
    count('clan') === war.clan?.attacks &&
    count('opponent') === war.opponent?.attacks &&
    final.clanStars === war.clan?.stars &&
    final.opponentStars === war.opponent?.stars &&
    Math.abs(final.clanPercent - war.clan.destructionPercentage) < 0.011 &&
    Math.abs(final.opponentPercent - war.opponent.destructionPercentage) < 0.011;
  function at(index: number): WarInfo {
    const end = Math.max(0, Math.min(events.length, index));
    const point = points[end]!;
    const included = events.slice(0, end);
    const clone = (side: 'clan' | 'opponent') => {
      const source = war[side];
      if (!source) return null;
      const outgoing = included.filter((event) => event.side === side),
        incoming = included.filter((event) => event.side !== side);
      return new WarClan(
        source.tag,
        source.name,
        source.badgeUrls,
        source.clanLevel,
        outgoing.length,
        side === 'clan' ? point.clanStars : point.opponentStars,
        side === 'clan' ? point.clanPercent : point.opponentPercent,
        source.members.map((member) => {
          const defenses = incoming
            .filter((event) => event.attack.defenderTag === member.tag)
            .map((event) => event.attack);
          const bestDefense = defenses.reduce<WarAttack | null>(
            (winner, hit) => (!winner || better(hit, winner) ? hit : winner),
            null,
          );
          return new WarMember(
            member.tag,
            member.name,
            member.townhallLevel,
            member.mapPosition,
            defenses.length,
            outgoing
              .filter((event) => event.attack.attackerTag === member.tag)
              .map((event) => event.attack),
            bestDefense,
          );
        }),
      );
    };
    return new WarInfo(
      end === events.length ? war.state : 'inWar',
      war.tag,
      war.teamSize,
      war.attacksPerMember,
      clone('clan'),
      clone('opponent'),
      war.startTime,
      war.endTime,
      war.preparationStartTime,
      war.warType,
      war.battleModifier,
    );
  }
  return {
    events,
    points,
    complete,
    at,
    clanName: war.clan?.name ?? '',
    opponentName: war.opponent?.name ?? '',
  };
}
