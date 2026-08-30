import { ClanBadgeUrls } from '../../clan/models';
import {
  CwlAttackStats,
  CwlClan,
  CwlLeague,
  CwlMember,
  MiniMember,
  WarAttack,
  WarClan,
  WarCwl,
  WarInfo,
  WarMember,
} from '.';

const member = (tag: string, attacks: WarAttack[] = []) =>
  new WarMember(tag, `Player ${tag}`, 16, 1, 0, attacks);
const clan = (tag: string, members: WarMember[] = [], stars = 0, destruction = 0) =>
  new WarClan(tag, tag, ClanBadgeUrls.empty(), 10, 0, stars, destruction, members);
const war = (state: string, left: string, right: string, endTime?: Date) =>
  new WarInfo(state, null, null, 2, clan(left), clan(right), null, endTime ?? null);

describe('war and CWL model contracts', () => {
  test('WarAttack parses nested mini members and serializes only Flutter wire fields', () => {
    const attack = WarAttack.fromJson({
      attackerTag: '#A',
      defenderTag: '#D',
      stars: 3,
      destructionPercentage: 99.5,
      order: 2,
      duration: 180,
      defender: { tag: '#D', townhallLevel: 16, mapPosition: 1 },
    });
    expect(attack.defender).toEqual(new MiniMember('#D', '', 16, 1, null));
    expect(attack.toJson()).toEqual({
      attackerTag: '#A',
      defenderTag: '#D',
      stars: 3,
      destructionPercentage: 99.5,
      order: 2,
      duration: 180,
    });
  });

  test('WarMember preserves null attacks but empty() uses an empty list', () => {
    expect(WarMember.fromJson({ tag: '#P' }).attacks).toBeNull();
    expect(WarMember.empty().attacks).toEqual([]);
  });

  test('WarClan computes average duration only from attacks with duration', () => {
    const first = WarAttack.fromJson({ duration: 100 });
    const second = WarAttack.fromJson({ duration: 200 });
    const missing = WarAttack.fromJson({});
    expect(clan('#C', [member('#P', [first, second, missing])]).getAverageAttackTime()).toBe(150);
    expect(clan('#C').getAverageAttackTime()).toBeNull();
  });

  test('WarInfo parses compact official dates and CWL effective attack rules', () => {
    const info = WarInfo.fromJson({
      state: 'inWar',
      warType: 'cwl',
      attacksPerMember: 2,
      startTime: '20260829T000000.000Z',
    });
    expect(info.startTime?.toISOString()).toBe('2026-08-29T00:00:00.000Z');
    expect(info.effectiveAttacksPerMember).toBe(1);
  });

  test('WarInfo result, lookup, and reorientation preserve both perspectives', () => {
    const p = member('#P');
    const info = new WarInfo(
      'warEnded',
      '#WAR',
      15,
      2,
      clan('#A', [], 10, 90),
      clan('#B', [p], 10, 80),
    );
    expect(info.getWarResult('#A')).toBe('won');
    expect(info.getWarResult('#B')).toBe('lost');
    expect(info.reorderForUser('#P').clan?.tag).toBe('#B');
    expect(info.reorderForClan('B').clan?.tag).toBe('#B');
  });

  test('both perfect sides are reported as perfectWar before star comparison', () => {
    const info = new WarInfo(
      'warEnded',
      null,
      null,
      null,
      clan('#A', [], 30, 100),
      clan('#B', [], 29, 100),
    );
    expect(info.getWarResult('#A')).toBe('perfectWar');
  });

  test('CWL attack stats preserve underscore keys, averages, and fallback missed attacks', () => {
    const stats = CwlAttackStats.fromJson({
      stars: 5,
      '3_stars': { '16': 1 },
      total_destruction: 180,
      attack_count: 2,
      missed_attacks: 1,
    });
    expect(stats.averageStars).toBe(2.5);
    expect(stats.averageDestruction).toBe(90);
    expect(stats.calculatedMissedAttacks).toBe(1);
    expect(stats.toJson()['3_stars']).toEqual({ '16': 1 });
  });

  test('CwlClan weights attack and defense averages by played attempts', () => {
    const parsed = CwlClan.fromJson({
      members: [
        {
          attacks: { stars: 3, attack_count: 1, total_destruction: 100 },
          defense: { stars: 3, defense_count: 1, total_destruction: 100 },
        },
        {
          attacks: { stars: 2, attack_count: 2, total_destruction: 150 },
          defense: { stars: 1, defense_count: 2, total_destruction: 110 },
        },
      ],
    });
    expect(parsed.averageStars).toBeCloseTo(5 / 3);
    expect(parsed.averageDestruction).toBeCloseTo(250 / 3);
    expect(parsed.defAverageStars).toBeCloseTo(4 / 3);
    expect(parsed.defAverageDestruction).toBe(70);
  });

  test('CwlMember exposes attack and defense star-bucket totals', () => {
    const parsed = CwlMember.fromJson({
      attacks: { '3_stars': { '16': 2 } },
      defense: { '0_star': { '16': 3 } },
    });
    expect(parsed.threeStars).toBe(2);
    expect(parsed.zeroStarDef).toBe(3);
  });

  test('CwlLeague removes #0-only rounds while preserving original round numbers', () => {
    const league = CwlLeague.fromJson({
      rounds: [{ warTags: ['#0'] }, { warTags: ['#W2'] }, { warTags: ['#W3'] }],
    });
    expect(league.rounds.map((round) => round.roundNumber)).toEqual([2, 3]);
    expect(league.getCurrentRounds()?.roundNumber).toBe(2);
  });

  test('CwlLeague rank gaps use nearest rank when exact target is absent', () => {
    const league = new CwlLeague(
      'ended',
      '2026-08',
      [
        new CwlClan('#A', 'A', ClanBadgeUrls.empty(), 1, 0, 20, 0, 0, [], 1, 0, {}),
        new CwlClan('#B', 'B', ClanBadgeUrls.empty(), 1, 0, 10, 0, 0, [], 3, 0, {}),
      ],
      [],
    );
    expect(league.getStarsGapFromRank('#B', 2)).toBe(10);
  });

  test('WarCwl bulk wrapper ignores null wars and derives lineup team size', () => {
    const parsed = WarCwl.fromJson({
      clan_tag: '#C',
      isInCwl: true,
      war_info: { state: 'notInWar' },
      war_league_infos: [
        null,
        { state: 'inWar', clan: { tag: '#C', members: [{ tag: '#P' }] }, opponent: { tag: '#O' } },
      ],
    });
    expect(parsed.warLeagueInfos).toHaveLength(1);
    expect(parsed.teamSize).toBe(1);
  });

  test('WarCwl active selection prefers live, then prep, then latest ended and reorders', () => {
    const wars = [
      war('warEnded', '#O', '#C', new Date('2026-01-01Z')),
      war('preparation', '#O', '#C'),
      war('inWar', '#O', '#C'),
    ];
    const summary = new WarCwl('#C', false, true, new WarInfo('notInWar'), null, wars);
    expect(summary.getActiveWarByTag('C')?.state).toBe('inWar');
    expect(summary.getActiveWarByTag('C')?.clan?.tag).toBe('#C');
  });

  test('active CWL clan lookup preserves Flutter case-sensitive tag matching', () => {
    const summary = new WarCwl('#ABC', false, true, new WarInfo('notInWar'), null, [
      war('inWar', '#ABC', '#OTHER'),
    ]);
    expect(summary.getActiveWarByTag('abc')).toBeNull();
  });

  test('member presence appears only for an inWar CWL day', () => {
    const summary = new WarCwl('#C', false, true, new WarInfo('notInWar'), null, [
      new WarInfo('preparation', null, null, 1, clan('#C', [member('#P')]), clan('#O')),
    ]);
    expect(summary.getMemberPresence('#P', '#C').isInWar).toBe(false);
  });
});
