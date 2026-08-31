import { ClanBadgeUrls } from '../../clan/models';
import {
  CwlAttackStats,
  CwlClan,
  CwlDefenseStats,
  CwlMember,
  WarAttack,
  WarClan,
  WarCwl,
  WarInfo,
  WarMember,
} from '../models';
import {
  analyzeWarState,
  buildWarEvents,
  calculateFastWarResult,
  calculateRequiredDestruction,
  cwlRoundTiming,
  filterWarMembers,
  formatDuration,
  orderCwlRounds,
  relativeWarTime,
  remainingWarTime,
  sortCwlClans,
  sortCwlMembers,
  warComparisonStats,
} from './presentation-utils';

const badge = new ClanBadgeUrls('', '', '');
const attack = (
  attacker: string,
  defender: string,
  stars: number,
  destruction: number,
  order: number,
) => new WarAttack(attacker, defender, stars, destruction, order, 120);
const alpha = new WarMember('#A', 'Alpha', 17, 1, 0, [attack('#A', '#X', 3, 100, 2)], null);
const beta = new WarMember(
  '#B',
  'Beta',
  16,
  2,
  1,
  [attack('#B', '#Y', 2, 80, 1)],
  attack('#Y', '#B', 1, 60, 3),
);
const xray = new WarMember(
  '#X',
  'Xray',
  17,
  1,
  1,
  [attack('#X', '#A', 0, 20, 4)],
  attack('#A', '#X', 3, 100, 2),
);
const yankee = new WarMember(
  '#Y',
  'Yankee',
  16,
  2,
  1,
  [attack('#Y', '#B', 1, 60, 3)],
  attack('#B', '#Y', 2, 80, 1),
);
const war = new WarInfo(
  'inWar',
  '#WAR',
  2,
  2,
  new WarClan('#C', 'Clan', badge, 1, 2, 5, 90, [alpha, beta]),
  new WarClan('#O', 'Opponent', badge, 1, 2, 1, 40, [xray, yankee]),
  new Date(),
  new Date(),
  new Date(),
  'random',
);

describe('war presentation helpers', () => {
  it('matches member filters, search, and best-attack ordering', () => {
    expect(filterWarMembers([beta, alpha], 'rattacks').map((member) => member.name)).toEqual([
      'Alpha',
      'Beta',
    ]);
    expect(filterWarMembers([alpha, beta], '3stars')).toEqual([alpha]);
    expect(filterWarMembers([alpha, beta], 'all', 'th16')).toEqual([beta]);
    expect(filterWarMembers([alpha, beta], 'def_1star')).toEqual([beta]);
  });

  it('builds one chronological attack stream across both clans', () => {
    expect(buildWarEvents(war, { newestFirst: false }).map((event) => event.attack.order)).toEqual([
      1, 2, 3, 4,
    ]);
    expect(buildWarEvents(war, { stars: 3 })).toHaveLength(1);
    expect(buildWarEvents(war, { side: 'opponent' })).toHaveLength(2);
    expect(buildWarEvents(war, { query: 'xray' })).toHaveLength(2);
  });

  it('derives remaining attacks, leader state, and bounded calculator output', () => {
    expect(warComparisonStats(war)).toMatchObject({
      clanAttacksRemaining: 2,
      opponentAttacksRemaining: 2,
      leader: 'clan',
    });
    expect(calculateRequiredDestruction(180, 2, 2, 90)).toBe(180);
    expect(calculateRequiredDestruction(180, 2, 0, 90)).toBeNull();
  });

  it('preserves Flutter fast-calculator math and invalid-input fallback', () => {
    expect(calculateFastWarResult('15', '2.01')).toBeCloseTo(30.15);
    expect(calculateFastWarResult('bad', '2.01')).toBe(0);
  });

  it('formats attack durations exactly like the Flutter details sheet', () => {
    expect(formatDuration(null)).toBe('—');
    expect(formatDuration(0)).toBe('0s');
    expect(formatDuration(45)).toBe('45s');
    expect(formatDuration(135)).toBe('2m 15s');
  });

  it('formats relative labels without requiring Intl.RelativeTimeFormat in Hermes', () => {
    const now = new Date('2026-08-30T15:00:00.000Z');
    const t = ((key: string, values?: Record<string, unknown>) => {
      if (key === 'timeJustNow') return 'Just Now';
      if (key === 'timeMinutesAgo') return `${String(values?.minutes)} minutes ago`;
      if (key === 'timeDurationShort') return `${String(values?.primary)}m`;
      return key;
    }) as never;
    const descriptor = Object.getOwnPropertyDescriptor(Intl, 'RelativeTimeFormat');
    Object.defineProperty(Intl, 'RelativeTimeFormat', { configurable: true, value: undefined });
    try {
      expect(relativeWarTime(new Date('2026-08-30T14:59:50.000Z'), now, t)).toBe('Just Now');
      expect(relativeWarTime(new Date('2026-08-30T14:30:00.000Z'), now, t)).toBe('30 minutes ago');
      expect(remainingWarTime(new Date('2026-08-30T15:30:00.000Z'), now, t)).toBe('30m');
    } finally {
      if (descriptor) Object.defineProperty(Intl, 'RelativeTimeFormat', descriptor);
      else delete (Intl as { RelativeTimeFormat?: unknown }).RelativeTimeFormat;
    }
  });

  it('uses base-improvement potential when determining whether a result is secured', () => {
    const secured = new WarInfo(
      'inWar',
      '#W',
      1,
      1,
      new WarClan('#C', 'Clan', badge, 1, 1, 3, 100, [alpha]),
      new WarClan('#O', 'Opponent', badge, 1, 1, 0, 0, [xray]),
    );
    expect(analyzeWarState(secured)).toEqual({ kind: 'secured' });

    const waiting = new WarInfo(
      'inWar',
      '#W',
      2,
      2,
      new WarClan('#C', 'Clan', badge, 1, 0, 0, 0, [alpha, beta]),
      new WarClan('#O', 'Opponent', badge, 1, 0, 0, 0, [xray, yankee]),
    );
    expect(analyzeWarState(waiting)).toEqual({
      kind: 'notStarted',
      clanRemaining: 4,
      opponentRemaining: 4,
    });
  });

  it('orders CWL preparation, current, then prior playable rounds like Flutter', () => {
    const summary = WarCwl.fromJson(
      {
        clan_tag: '#C',
        league_info: {
          rounds: [{ warTags: ['#OLD'] }, { warTags: ['#CURRENT'] }, { warTags: ['#PREP'] }],
        },
        war_league_infos: [
          { war_tag: '#OLD', state: 'warEnded', clan: { tag: '#C' }, opponent: { tag: '#O' } },
          { war_tag: '#CURRENT', state: 'inWar', clan: { tag: '#C' }, opponent: { tag: '#O' } },
          { war_tag: '#PREP', state: 'preparation', clan: { tag: '#C' }, opponent: { tag: '#O' } },
        ],
      },
      '#C',
    );
    expect(orderCwlRounds(summary).map((round) => round.roundNumber)).toEqual([3, 2, 1]);
  });

  it('preserves Flutter CWL round timing for preparation, live, and ended wars', () => {
    const start = new Date('2026-08-30T12:30:00.000Z');
    const end = new Date('2026-08-30T13:30:00.000Z');
    const now = new Date('2026-08-30T15:00:00.000Z');
    expect(
      cwlRoundTiming(new WarInfo('preparationDay', null, null, null, null, null, start), now),
    ).toEqual({
      kind: 'startsAt',
      time: start,
    });
    expect(
      cwlRoundTiming(new WarInfo('warInWar', null, null, null, null, null, null, end), now),
    ).toEqual({
      kind: 'endsAt',
      time: end,
    });
    expect(
      cwlRoundTiming(new WarInfo('warEnded', null, null, null, null, null, null, end), now),
    ).toEqual({
      kind: 'endedHoursAgo',
      value: 1,
    });
    expect(cwlRoundTiming(new WarInfo('warEnded'), now)).toEqual({ kind: 'unknown' });
  });

  it('supports every CWL member sort family and Flutter town-hall composition ordering', () => {
    const low = new CwlMember(
      '#LOW',
      'Low',
      16,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      1,
      2,
      3,
      4,
      new CwlAttackStats(2, {}, {}, { 16: 2 }, {}, 90, 2, 3),
      new CwlDefenseStats(3, { 16: 1 }, {}, {}, {}, 100, 1, 0),
    );
    const high = new CwlMember(
      '#HIGH',
      'High',
      17,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      null,
      5,
      6,
      7,
      8,
      new CwlAttackStats(6, { 17: 2 }, {}, {}, {}, 200, 2, 0),
      new CwlDefenseStats(1, {}, {}, { 17: 1 }, {}, 50, 1, 0),
    );
    expect(sortCwlMembers([low, high], 'attackUpperTH').map((member) => member.tag)).toEqual([
      '#HIGH',
      '#LOW',
    ]);
    expect(sortCwlMembers([low, high], 'def3stars').map((member) => member.tag)).toEqual([
      '#LOW',
      '#HIGH',
    ]);

    const lowThClan = new CwlClan('#L', 'Low', badge, 1, 1, 1, 1, 1, [low], 2, 1, {
      16: 15,
    });
    const highThClan = new CwlClan('#H', 'High', badge, 1, 1, 1, 1, 1, [high], 1, 1, {
      17: 1,
      16: 14,
    });
    expect(sortCwlClans([lowThClan, highThClan], 'townHallLevel')).toEqual([highThClan, lowThClan]);
  });
});
