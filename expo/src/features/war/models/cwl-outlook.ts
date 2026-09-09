import type { WarCwl } from './war-cwl';
import type { WarInfo } from './war';

export interface CwlStanding {
  tag: string;
  stars: number;
  destruction: number;
  wins: number;
  played: number;
  rank: number;
  firstChance: number | null;
  topTwoChance: number | null;
}
/** Season standings include completed-win bonuses; player attack stars remain separate. */
export function cwlStandings(summary: WarCwl): CwlStanding[] {
  const rows = (summary.leagueInfo?.clans ?? [])
    .map((clan) => {
      const wars = summary.warLeagueInfos.filter(
        (war) => involves(war, clan.tag) && (war.state === 'inWar' || war.state === 'warEnded'),
      );
      const completed = wars.filter((war) => war.state === 'warEnded');
      const wins = completed.filter((war) => winner(war) === clan.tag).length;
      return {
        tag: clan.tag,
        stars: wars.reduce((sum, war) => sum + side(war, clan.tag)!.stars, 0) + wins * 10,
        destruction: wars.reduce((sum, war) => sum + side(war, clan.tag)!.destructionPercentage, 0),
        wins,
        played: completed.length,
        rank: 0,
        firstChance: null,
        topTwoChance: null,
      } as CwlStanding;
    })
    .sort(
      (a, b) => b.stars - a.stars || b.destruction - a.destruction || a.tag.localeCompare(b.tag),
    );
  rows.forEach((row, index) => {
    const previous = rows[index - 1];
    const started = summary.warLeagueInfos.some(
      (war) => war.state === 'inWar' || war.state === 'warEnded',
    );
    row.rank = !started
      ? 0
      : previous && previous.stars === row.stars && previous.destruction === row.destruction
        ? previous.rank
        : index + 1;
  });
  return rows;
}

/** Bootstrap outlook, not calibrated promotion odds. Only enabled with two finished wars per clan. */
export function cwlOutlook(summary: WarCwl): CwlStanding[] {
  const standings = cwlStandings(summary);
  if (standings.length < 2 || standings.some((row) => row.played < 2) || !summary.teamSize)
    return standings;
  const samples = new Map(
    standings.map((row) => [
      row.tag,
      summary.warLeagueInfos
        .filter((war) => war.state === 'warEnded' && involves(war, row.tag))
        .map((war) => ({
          attack: side(war, row.tag)!.stars / (war.teamSize ?? summary.teamSize),
          defense: other(war, row.tag)!.stars / (war.teamSize ?? summary.teamSize),
          destruction: side(war, row.tag)!.destructionPercentage,
        })),
    ]),
  );
  // Stable seed prevents the estimate jumping when the UI simply re-renders.
  let seed = 17;
  for (const char of summary.leagueInfo?.season ?? '')
    seed = (seed * 31 + char.charCodeAt(0)) >>> 0;
  const random = () => {
    seed = (1664525 * seed + 1013904223) >>> 0;
    return seed / 4294967296;
  };
  const pick = (tag: string) => {
    const values = samples.get(tag)!;
    return values[Math.floor(random() * values.length)]!;
  };
  const totals = new Map(standings.map((row) => [row.tag, [0, 0]]));
  const simulations = 1000;
  for (let iteration = 0; iteration < simulations; iteration++) {
    const scores = new Map(standings.map((row) => [row.tag, { stars: 0, destruction: 0 }]));
    for (let a = 0; a < standings.length; a++)
      for (let b = a + 1; b < standings.length; b++) {
        const left = standings[a]!.tag,
          right = standings[b]!.tag;
        const war = summary.warLeagueInfos.find(
          (war) => involves(war, left) && involves(war, right),
        );
        const size = war?.teamSize ?? summary.teamSize;
        const ls = scores.get(left)!,
          rs = scores.get(right)!;
        if (war?.state === 'warEnded') {
          const l = side(war, left)!,
            r = side(war, right)!;
          ls.stars += l.stars + (winner(war) === left ? 10 : 0);
          rs.stars += r.stars + (winner(war) === right ? 10 : 0);
          ls.destruction += l.destructionPercentage;
          rs.destruction += r.destructionPercentage;
        } else {
          const l = pick(left),
            r = pick(right);
          const estimate = (tag: string, attack: number, defense: number) => {
            const current = war?.state === 'inWar' ? side(war, tag) : null;
            const remaining = Math.max(0, size - (current?.attacks ?? 0));
            return Math.min(
              size * 3,
              (current?.stars ?? 0) +
                Math.round(remaining * Math.min(3, Math.max(0, (attack + defense) / 2))),
            );
          };
          const lStars = estimate(left, l.attack, r.defense),
            rStars = estimate(right, r.attack, l.defense);
          const lPercent = Math.max(
            war?.state === 'inWar' ? side(war, left)!.destructionPercentage : 0,
            l.destruction,
          );
          const rPercent = Math.max(
            war?.state === 'inWar' ? side(war, right)!.destructionPercentage : 0,
            r.destruction,
          );
          ls.stars +=
            lStars + (lStars > rStars || (lStars === rStars && lPercent > rPercent) ? 10 : 0);
          rs.stars +=
            rStars + (rStars > lStars || (lStars === rStars && rPercent > lPercent) ? 10 : 0);
          ls.destruction += lPercent;
          rs.destruction += rPercent;
        }
      }
    const ordered = [...scores].sort(
      ([, a], [, b]) => b.stars - a.stars || b.destruction - a.destruction,
    );
    // Split exact ties rather than deciding a probability by tag order.
    for (const [tag, value] of ordered) {
      const ahead = ordered.filter(
        ([, v]) =>
          v.stars > value.stars || (v.stars === value.stars && v.destruction > value.destruction),
      ).length;
      const tied = ordered.filter(
        ([, v]) => v.stars === value.stars && v.destruction === value.destruction,
      ).length;
      totals.get(tag)![0]! += Math.max(0, Math.min(tied, 1 - ahead)) / tied;
      totals.get(tag)![1]! += Math.max(0, Math.min(tied, 2 - ahead)) / tied;
    }
  }
  return standings.map((row) => ({
    ...row,
    firstChance: totals.get(row.tag)![0]! / simulations,
    topTwoChance: totals.get(row.tag)![1]! / simulations,
  }));
}
export function remainingCwlOpponents(summary: WarCwl, tag: string) {
  const faced = new Set(
    summary.warLeagueInfos
      .filter((war) => involves(war, tag) && war.state === 'warEnded')
      .map((war) => other(war, tag)?.tag),
  );
  return (summary.leagueInfo?.clans ?? []).filter(
    (clan) => clan.tag !== tag && !faced.has(clan.tag),
  );
}
function involves(war: WarInfo, tag: string) {
  return war.clan?.tag === tag || war.opponent?.tag === tag;
}
function side(war: WarInfo, tag: string) {
  return war.clan?.tag === tag ? war.clan : war.opponent;
}
function other(war: WarInfo, tag: string) {
  return war.clan?.tag === tag ? war.opponent : war.clan;
}
function winner(war: WarInfo) {
  if (!war.clan || !war.opponent) return null;
  const delta =
    war.clan.stars - war.opponent.stars ||
    war.clan.destructionPercentage - war.opponent.destructionPercentage;
  return delta > 0 ? war.clan.tag : delta < 0 ? war.opponent.tag : null;
}
