import { ClanBadgeUrls } from '../../clan/models';
import {
  CwlAttackStats,
  CwlClan,
  CwlDefenseStats,
  CwlLeague,
  CwlLeagueRound,
  CwlMember,
} from './cwl';
import { WarCwl } from './war-cwl';
import { WarInfo } from './war';

const clan = (tag: string, members: string[] = []) => ({
  tag,
  name: tag,
  members: members.map((member, index) => ({
    tag: member,
    name: member,
    townhallLevel: 17,
    mapPosition: index + 1,
    attacks: index === 0 ? [{ attackerTag: member, defenderTag: '#D', stars: 3 }] : [],
  })),
});
const war = (state: string, endTime: string, left = '#C', right = '#O') =>
  WarInfo.fromJson({
    state,
    endTime,
    attacksPerMember: 2,
    clan: clan(left, ['#P']),
    opponent: clan(right, ['#Q']),
  });

describe('CWL and WarCwl edge behavior', () => {
  it('covers empty and calculated attack/defense statistics and serialization', () => {
    const attack = new CwlAttackStats(
      6,
      { '17': 2 },
      { '16': 1 },
      { '15': 1 },
      { '14': 1 },
      180,
      2,
      4,
      3,
      1,
    );
    expect(attack.averageStars).toBe(3);
    expect(attack.averageDestruction).toBe(90);
    expect(attack.calculatedMissedAttacks).toBe(1);
    expect(new CwlAttackStats(0, {}, {}, {}, {}, 0, 0, 2).averageStars).toBe(0);
    expect(new CwlAttackStats(0, {}, {}, {}, {}, 0, 0, 2).averageDestruction).toBe(0);
    expect(attack.toJson()).toMatchObject({ attack_count: 2, missed_attacks: 4 });

    const defense = CwlDefenseStats.fromJson({
      stars: 4,
      '3_stars': { '17': 1 },
      '2_stars': { '16': 1 },
      '1_star': { '15': 1 },
      '0_star': { '14': 1 },
      total_destruction: 140,
      defense_count: 2,
      missed_defenses: 3,
    });
    expect(defense.averageStars).toBe(2);
    expect(defense.averageDestruction).toBe(70);
    expect(defense.toJson()).toMatchObject({ defense_count: 2, total_destruction: 140 });
    expect(CwlDefenseStats.fromJson({}).averageStars).toBe(0);
    expect(CwlDefenseStats.fromJson({}).averageDestruction).toBe(0);
  });

  it('parses all member averages, star buckets, and nullable stats', () => {
    const member = CwlMember.fromJson({
      tag: '#P',
      name: 'Player',
      townHallLevel: 17,
      avgMapPosition: 1.5,
      avgOpponentPosition: 2,
      avgAttackOrder: 3,
      avgTownHallLevel: 17,
      avgOpponentTownHallLevel: 16,
      avgAttackerPosition: 4,
      avgDefenseOrder: 5,
      avgAttackerTownHallLevel: 17,
      attackLowerTHLevel: 1,
      defenseLowerTHLevel: 2,
      attackUpperTHLevel: 3,
      defenseUpperTHLevel: 4,
      attacks: {
        stars: 6,
        attack_count: 3,
        missed_attacks: 1,
        '3_stars': { '17': 2 },
        '2_stars': { '16': 1 },
        '1_star': { '15': 1 },
        '0_star': { '14': 1 },
      },
      defense: {
        stars: 5,
        defense_count: 3,
        missed_defenses: 2,
        '3_stars': { '17': 1 },
        '2_stars': { '16': 2 },
        '1_star': { '15': 3 },
        '0_star': { '14': 4 },
      },
    });
    expect(member).toMatchObject({ avgMapPosition: 1.5, defenseUpperTHLevel: 4 });
    expect([
      member.threeStars,
      member.twoStars,
      member.oneStar,
      member.zeroStar,
      member.threeStarsDef,
      member.twoStarsDef,
      member.oneStarDef,
      member.zeroStarDef,
    ]).toEqual([2, 1, 1, 1, 1, 2, 3, 4]);
    expect(member.toJson()).toMatchObject({ tag: '#P', townHallLevel: 17 });
    expect(CwlMember.fromJson({ tag: '#E' }).toJson()).toMatchObject({
      attacks: null,
      defense: null,
    });
  });

  it('computes every clan aggregate and supports empty clan fallbacks', () => {
    const member = CwlMember.fromJson({
      attacks: {
        stars: 5,
        attack_count: 2,
        missed_attacks: 1,
        total_destruction: 180,
        '3_stars': { a: 1 },
        '2_stars': { a: 1 },
        '1_star': { a: 1 },
        '0_star': { a: 1 },
      },
      defense: {
        stars: 3,
        defense_count: 2,
        missed_defenses: 2,
        total_destruction: 120,
        '3_stars': { a: 1 },
        '2_stars': { a: 1 },
        '1_star': { a: 1 },
        '0_star': { a: 1 },
      },
    });
    const cwlClan = new CwlClan(
      '#C',
      'Clan',
      ClanBadgeUrls.empty(),
      20,
      2,
      5,
      90,
      60,
      [member],
      1,
      7,
      { '17': 1 },
    );
    expect(cwlClan.missedAttacks).toBe(1);
    expect([
      cwlClan.totalThreeStars,
      cwlClan.totalTwoStars,
      cwlClan.totalOneStar,
      cwlClan.totalZeroStar,
    ]).toEqual([1, 1, 1, 1]);
    expect([cwlClan.threeStars, cwlClan.twoStars, cwlClan.oneStar, cwlClan.zeroStar]).toEqual([
      1, 1, 1, 1,
    ]);
    expect(cwlClan.averageStars).toBe(2.5);
    expect(cwlClan.averageDestruction).toBe(90);
    expect(cwlClan.defenseCount).toBe(2);
    expect(cwlClan.defStars).toBe(3);
    expect(cwlClan.defAverageStars).toBe(1.5);
    expect(cwlClan.defAverageDestruction).toBe(60);
    expect(cwlClan.missedDefenses).toBe(2);
    expect([
      cwlClan.threeStarsDef,
      cwlClan.twoStarsDef,
      cwlClan.oneStarDef,
      cwlClan.zeroStarDef,
    ]).toEqual([1, 1, 1, 1]);
    expect(cwlClan.toJson()).toMatchObject({ tag: '#C', members: [expect.any(Object)] });

    const empty = CwlClan.empty();
    expect([
      empty.averageStars,
      empty.averageDestruction,
      empty.defAverageStars,
      empty.defAverageDestruction,
    ]).toEqual([0, 0, 0, 0]);
    expect(CwlClan.fromJson(null)).toMatchObject({ tag: 'No tag', name: 'No name' });
  });

  it('sorts clans, finds rounds and gaps, and applies current-round rules', () => {
    const first = new CwlClan('#A', 'A', ClanBadgeUrls.empty(), 1, 0, 5, 99, 0, [], 1, 0, {});
    const second = new CwlClan('#B', 'B', ClanBadgeUrls.empty(), 1, 0, 10, 80, 0, [], 2, 0, {});
    const rounds = Array.from(
      { length: 7 },
      (_, index) => new CwlLeagueRound(index + 1, index === 1 ? ['#0'] : [`#W${index}`]),
    );
    const league = new CwlLeague('ended', '2026-08', [first, second], rounds);

    expect(league.getStarsGapFromRank('#MISSING', 1)).toBeNull();
    expect(new CwlLeague('ended', '', [], []).getStarsGapFromRank('#A', 1)).toBeNull();
    expect(league.getStarsGapFromRank('#A', 2)).toBe(5);
    expect(league.getClanDetails('#A')).toBe(first);
    expect(league.getClanDetails('#MISSING')).toBeNull();
    league.sortClans('stars');
    expect(league.clans[0]).toBe(second);
    league.sortClans('percentage');
    expect(league.clans[0]).toBe(first);
    expect(league.getRounds()).toHaveLength(6);
    expect(league.getCurrentRounds()?.roundNumber).toBe(7);
    expect(new CwlLeague('', '', [], []).getCurrentRounds()).toBeNull();
    expect(new CwlLeague('', '', [], [rounds[0]!]).getCurrentRounds()).toBe(rounds[0]);
    expect(new CwlLeague('', '', [], rounds.slice(0, 3)).getCurrentRounds()).toBe(rounds[1]);
    expect(rounds[0]!.containsWar(null)).toBe(false);
    expect(rounds[0]!.containsWar('#W0')).toBe(true);
  });

  it('parses current war/league wrappers and falls back through team-size sources', () => {
    const parsed = WarCwl.fromJson({
      clan_tag: '#C',
      isInWar: true,
      isInCwl: true,
      war_info: {
        state: 'inWar',
        currentWarInfo: { state: 'inWar', teamSize: 15, clan: clan('#C'), opponent: clan('#O') },
      },
      league_info: {
        state: 'inWar',
        season: '2026-08',
        rounds: [{ warTags: ['#W'] }],
      },
      war_league_infos: [
        { state: 'unknown' },
        { state: 'inWar', clan: clan('#C', ['#P']), opponent: clan('#O') },
      ],
    });
    expect(parsed).toMatchObject({ tag: '#C', isInWar: true, isInCwl: true });
    expect(parsed.warInfo.state).toBe('inWar');
    expect(parsed.leagueInfo?.season).toBe('2026-08');
    expect(parsed.warLeagueInfos).toHaveLength(1);
    expect(parsed.teamSize).toBe(15);
    expect(WarCwl.fromJson({ clan_tag: '#C', war_info: { state: 'notInWar' } }).warInfo.state).toBe(
      'notInWar',
    );

    const direct = new WarCwl('#C', false, true, new WarInfo('notInWar'), null, [
      new WarInfo(
        'inWar',
        null,
        null,
        null,
        WarInfo.fromJson({ clan: clan('#C', ['#P', '#X']) }).clan,
        null,
      ),
    ]);
    expect(direct.teamSize).toBe(2);
    expect(new WarCwl('#C', false, false, new WarInfo('notInWar'), null, []).teamSize).toBe(0);
  });

  it('selects active and ended wars by clan/player and reports presence and lookups', () => {
    const endedOld = war('warEnded', '2026-08-01T00:00:00Z');
    const endedNew = war('warEnded', '2026-08-02T00:00:00Z');
    const summary = new WarCwl(
      '#C',
      false,
      true,
      new WarInfo('notInWar'),
      new CwlLeague('', '', [], [new CwlLeagueRound(2, ['#WAR'])]),
      [endedOld, endedNew],
    );
    expect(summary.getActiveWarByTag('#C')?.endTime?.toISOString()).toContain('2026-08-02');
    expect(summary.getActiveWarByPlayerTag('#P')?.endTime?.toISOString()).toContain('2026-08-02');
    expect(summary.getActiveWarByTag('#MISSING')).toBeNull();
    expect(summary.getActiveWarByPlayerTag('#MISSING')).toBeNull();
    expect(summary.getRoundForWarTag('#WAR').roundNumber).toBe(2);
    expect(summary.getRoundForWarTag('#NO').roundNumber).toBe(-1);
    expect(summary.getWarInfoFromTag('#NO').state).toBe('unknown');
    expect(summary.getActiveWarForClan('#NO').state).toBe('notInCwl');

    const live = new WarCwl('#C', true, true, war('inWar', '2026-08-03T00:00:00Z'), null, [
      war('inWar', '2026-08-03T00:00:00Z'),
    ]);
    expect(live.getMemberPresence('#P', '#C')).toMatchObject({
      isInWar: true,
      attacksDone: 1,
      attacksAvailable: 2,
    });
    expect(live.getMemberPresence('#MISSING', '#C').isInWar).toBe(false);
    expect(summary.getMemberPresence('#P', '#C').isInWar).toBe(false);
  });
});
