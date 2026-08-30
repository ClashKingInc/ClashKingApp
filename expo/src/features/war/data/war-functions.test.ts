import { ClanBadgeUrls, WarLogDetails } from '../../clan/models';
import { WarAttack, WarClan, WarMember } from '../models';
import { analyzeWarLogs, countStars, getMemberByTag } from './war-functions';

describe('war data helpers', () => {
  test('countStars counts only the four star buckets', () => {
    const attacks = [0, 1, 2, 3, 4].map((stars) => new WarAttack('', '', stars, 0, 0));
    const members = [new WarMember('#P', 'P', 16, 1, 0, attacks)];
    expect(countStars(members)).toEqual({ 0: 1, 1: 1, 2: 1, 3: 1 });
  });

  test('analyzeWarLogs preserves Flutter denominator quirk for one-attack wars', () => {
    const logs = [
      {
        attacksPerMember: 2,
        result: 'win',
        teamSize: 10,
        clan: { stars: 20, destructionPercentage: 80 },
        opponent: { stars: 10, destructionPercentage: 60 },
      },
      {
        attacksPerMember: 1,
        result: 'lose',
        teamSize: 20,
        clan: { stars: 30, destructionPercentage: 90 },
        opponent: { stars: 25, destructionPercentage: 85 },
      },
    ] as unknown as WarLogDetails[];
    expect(analyzeWarLogs(logs)).toMatchObject({
      totalWins: '1',
      totalLosses: '0',
      averageMembers: '5',
      averageClanDestruction: '40',
    });
  });

  test('getMemberByTag-compatible clan fixtures retain exact tag lookup', () => {
    const clan = new WarClan('#C', 'C', ClanBadgeUrls.empty(), 1, 0, 0, 0, [
      new WarMember('#P', 'P', 16, 1, 0),
    ]);
    expect(getMemberByTag('#P', clan)?.name).toBe('P');
    expect(getMemberByTag('#p', clan)).toBeNull();
  });
});
