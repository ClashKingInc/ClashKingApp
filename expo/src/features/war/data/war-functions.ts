import { type WarLogDetails } from '../../clan/models';
import { WarClan, WarMember } from '../models';

export function countStars(members: readonly WarMember[]): Record<number, number> {
  const counts: Record<number, number> = { 0: 0, 1: 0, 2: 0, 3: 0 };
  for (const member of members)
    for (const attack of member.attacks ?? [])
      if ([0, 1, 2, 3].includes(attack.stars))
        counts[attack.stars] = (counts[attack.stars] ?? 0) + 1;
  return counts;
}

export function analyzeWarLogs(warLogs: readonly WarLogDetails[]): Record<string, string> {
  let wins = 0,
    losses = 0,
    ties = 0,
    members = 0,
    clanDestruction = 0,
    clanStars = 0,
    opponentDestruction = 0,
    opponentStars = 0;
  for (const log of warLogs) {
    if (log.attacksPerMember !== 2) continue;
    if (log.result === 'win') wins += 1;
    if (log.result === 'lose') losses += 1;
    if (log.result === 'tie') ties += 1;
    members += log.teamSize;
    clanDestruction += log.clan.destructionPercentage;
    clanStars += log.clan.stars;
    opponentDestruction += log.opponent.destructionPercentage;
    opponentStars += log.opponent.stars;
  }
  const count = warLogs.length;
  return {
    totalWins: String(wins),
    totalLosses: String(losses),
    totalTies: String(ties),
    averageMembers: (count ? members / count : 0).toFixed(0),
    averageClanDestruction: (count ? clanDestruction / count : 0).toFixed(0),
    averageClanStarsPerMember: (members ? clanStars / members : 0).toFixed(1),
    averageOpponentDestruction: (count ? opponentDestruction / count : 0).toFixed(0),
    averageOpponentStarsPerMember: (members ? opponentStars / members : 0).toFixed(1),
  };
}

export function getMemberByTag(tag: string, clan: WarClan): WarMember | null {
  return clan.members.find((member) => member.tag === tag) ?? null;
}
