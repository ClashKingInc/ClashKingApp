import { enrichCwlDetail } from './cwl-detail';
import { WarInfo } from './war';

const group = {
  state: 'inWar',
  season: '2026-09',
  clans: [
    {
      tag: '#A',
      name: 'A',
      members: [
        { tag: '#P', name: 'P', townHallLevel: 18 },
        { tag: '#RESERVE', name: 'Reserve', townHallLevel: 16 },
      ],
    },
    { tag: '#B', name: 'B', members: [{ tag: '#E', name: 'E', townHallLevel: 17 }] },
  ],
};
const hit = {
  attackerTag: '#P',
  defenderTag: '#E',
  stars: 3,
  destructionPercentage: 100,
  order: 1,
  duration: 100,
};
function matchup(state: string, attacked: boolean) {
  return WarInfo.fromJson({
    state,
    warType: 'cwl',
    teamSize: 1,
    clan: {
      tag: '#A',
      stars: attacked ? 3 : 0,
      attacks: attacked ? 1 : 0,
      members: [
        { tag: '#P', name: 'P', townhallLevel: 18, mapPosition: 1, attacks: attacked ? [hit] : [] },
      ],
    },
    opponent: {
      tag: '#B',
      stars: 0,
      attacks: 0,
      members: [
        {
          tag: '#E',
          name: 'E',
          townhallLevel: 17,
          mapPosition: 1,
          bestOpponentAttack: attacked ? hit : null,
        },
      ],
    },
  });
}
test('aggregates all played rounds and retains reserves separately from each lineup', () => {
  const league = enrichCwlDetail(group, [
    matchup('warEnded', true),
    matchup('warEnded', false),
    matchup('inWar', false),
    matchup('preparation', false),
  ]);
  const clan = league.getClanDetails('#A')!;
  expect(clan.warsPlayed).toBe(3);
  expect(clan.stars).toBe(3);
  expect(clan.attackCount).toBe(1);
  expect(clan.missedAttacks).toBe(1); // unfinished and preparation attacks aren't missed
  expect(clan.townHallLevels).toEqual({ 18: 1, 16: 1 });
  expect(clan.members[0]?.attackStats?.threeStars).toEqual({ 17: 1 });
  expect(clan.members[0]?.avgOpponentTownHallLevel).toBe(17);
  expect(clan.members[1]?.attackStats?.missedAttacks).toBe(0);
  expect(clan.members[1]?.avgMapPosition).toBeNull();
  expect(league.getClanDetails('#B')?.members[0]?.defenseStats?.threeStars).toEqual({ 18: 1 });
});
test('preparation-only groups do not invent a rank or played wars', () => {
  const clan = enrichCwlDetail(group, [matchup('preparation', false)]).clans[0]!;
  expect(clan.rank).toBe(0);
  expect(clan.warsPlayed).toBe(0);
});
