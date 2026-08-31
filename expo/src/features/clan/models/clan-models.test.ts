import {
  CapitalHistoryItems,
  Clan,
  ClanJoinLeave,
  ClanLeaderboardHistory,
  ClanLeague,
  ClanMember,
  ClanProfileHistory,
  ClanRecords,
  ClanWarLog,
  ClanWarStatsFilter,
  CwlRankingHistoryEntry,
  JoinLeaveEvent,
  WarLogDetails,
  analyzeWarLogs,
} from '.';

const warItem = (overrides: Record<string, unknown> = {}) => ({
  result: 'win',
  endTime: '20230615T120000.000Z',
  teamSize: 10,
  attacksPerMember: 2,
  clan: {
    tag: '#CLAN',
    attacks: 20,
    stars: 30,
    destructionPercentage: 90,
  },
  opponent: { tag: '#OPP', attacks: 20, stars: 20, destructionPercentage: 60 },
  ...overrides,
});

describe('clan model contracts', () => {
  test('Clan preserves Flutter defaults and rewrites official badge assets', () => {
    const clan = Clan.fromJson({
      tag: '#CLAN',
      name: 'Test',
      badgeUrls: { medium: 'https://api-assets.clashofclans.com/badges/a.png' },
    });
    expect(clan.type).toBe('');
    expect(clan.warFrequency).toBe('unknown');
    expect(clan.isWarLogPublic).toBe(true);
    expect(clan.memberList).toEqual([]);
    expect(clan.badgeUrls.medium).toBe('https://assets-proxy.clashk.ing/badges/a.png');
  });

  test('selects the smallest supplied clan badge with ordered fallbacks', () => {
    expect(
      Clan.fromJson({
        badgeUrls: { small: 'small.png', medium: 'medium.png', large: 'large.png' },
      }).badgeUrls.smallest,
    ).toBe('small.png');
    expect(
      Clan.fromJson({ badgeUrls: { medium: 'medium.png', large: 'large.png' } }).badgeUrls.smallest,
    ).toBe('medium.png');
    expect(Clan.fromJson({ badgeUrls: { large: 'large.png' } }).badgeUrls.smallest).toBe(
      'large.png',
    );
  });

  test('member parsing prefers leagueTier and retains the explicit league fallback', () => {
    const member = ClanMember.fromJson({
      league: { id: 1, name: 'Old' },
      leagueTier: { id: 2, name: 'New' },
    });
    expect(member.league).toMatchObject({ id: 2, name: 'New' });
    expect(ClanMember.fromJson({ league: { id: 1, name: 'Old' } }).league.id).toBe(1);
    expect(ClanMember.empty().league).toEqual(ClanLeague.unranked());
  });

  test('join/leave parses both current and Flutter-owned legacy event list keys', () => {
    const event = { type: 'join', tag: '#P', townHallLevel: 16, time: '2026-08-01Z' };
    expect(ClanJoinLeave.fromJson({ items: [event] }).joinLeaveList[0]?.th).toBe(16);
    expect(ClanJoinLeave.fromJson({ join_leave_list: [event] }).joinLeaveList).toHaveLength(1);
  });

  test('appendPage deduplicates by UTC time, type, and player tag in input order', () => {
    const event = JoinLeaveEvent.fromJson({ type: 'join', tag: '#P', time: '2026-08-01Z' });
    const original = new ClanJoinLeave('#C', 3, 2, [event]);
    const page = new ClanJoinLeave('#C', 3, 2, [
      event,
      JoinLeaveEvent.fromJson({ type: 'leave', tag: '#P', time: '2026-07-31Z' }),
    ]);
    expect(original.appendPage(page).joinLeaveList.map((item) => item.type)).toEqual([
      'join',
      'leave',
    ]);
  });

  test('leaderboard history unifies all three point wire keys and normalizes dates', () => {
    for (const item of [{ clanPoints: 1 }, { builderBasePoints: 2 }, { capitalPoints: 3 }]) {
      const result = ClanLeaderboardHistory.fromJson({
        items: [{ date: '2026-08-25', ...item }],
      });
      expect(result.items[0]?.points).toBeGreaterThan(0);
      expect(result.items[0]?.date.toISOString()).toContain('2026-08-25');
    }
  });

  test('records and profile changes retain timestamp and value types', () => {
    const records = ClanRecords.fromJson({
      clanPoints: { value: 156112, time: '2025-10-13T06:44:43Z' },
    });
    const history = ClanProfileHistory.fromJson({
      items: [{ type: 'clanLevel', previous: 31, current: 32 }],
    });
    expect(records.clanPoints?.value).toBe(156112);
    expect(history.items[0]?.current).toBe(32);
  });

  test('capital defense logs accept attacker and malformed bundles collapse to empty', () => {
    const parsed = CapitalHistoryItems.fromJson(
      {
        history: [
          {
            defenseLog: [
              { attacker: { tag: '#A' }, districts: [], attackCount: 1, districtCount: 1 },
            ],
          },
        ],
      },
      '#C',
    );
    expect(parsed.items[0]?.defenseLog[0]?.defender.tag).toBe('#A');
    expect(CapitalHistoryItems.fromJson({ history: [null] }, '#C').items).toEqual([]);
  });

  test('war log filters pre-2022 details but exposes all wire items as display wars', () => {
    const log = ClanWarLog.fromJson(
      { items: [warItem({ endTime: '20210101T000000.000Z' }), warItem()] },
      '#CLAN',
    );
    expect(log.items).toHaveLength(1);
    expect(log.wars).toHaveLength(2);
    expect(log.warLogStats.totalWars).toBe(0);
  });

  test('war log analysis only counts two-attack wars and matches Flutter rounding', () => {
    const stats = analyzeWarLogs([
      WarLogDetails.fromJson(warItem(), '#CLAN'),
      WarLogDetails.fromJson(warItem({ result: 'lose', attacksPerMember: 1 }), '#CLAN'),
    ]);
    expect(stats).toMatchObject({
      totalWars: 1,
      totalWins: 1,
      averageMembers: 10,
      averageClanStarsPerMember: 3,
      winPercentage: '100',
    });
  });

  test('war stats filters serialize precedence and Unix-second date bounds exactly', () => {
    const filter = new ClanWarStatsFilter({
      startDate: new Date('2026-01-01T00:00:00Z'),
      warType: 'random',
      warTypes: ['cwl'],
      ownTownHall: 15,
      ownTownHalls: [16, 17],
      allowedStars: [3],
      minStars: 2,
      sameTownHall: true,
    });
    expect(filter.toJson()).toEqual({
      limit: 50,
      same_th: true,
      type: ['cwl'],
      timestamp_start: 1767225600,
      own_th: [16, 17],
      stars: [3],
    });
  });

  test('war stats filter controls can clear nullable selections', () => {
    const selected = new ClanWarStatsFilter({
      ownTownHall: 16,
      minStars: 2,
      minDestruction: 75,
    });
    expect(
      selected.copyWith({ ownTownHall: null, minStars: null, minDestruction: null }),
    ).toMatchObject({ ownTownHall: null, minStars: null, minDestruction: null });
  });

  test('CWL history prefers standing data and keeps legacy league id nullable', () => {
    const current = CwlRankingHistoryEntry.fromJson({
      warLeague: { id: 48000015, name: 'Master League I' },
      standing: { groupRank: 4, stars: 333, wins: 5 },
      rank: 9,
    });
    expect(current).toMatchObject({ leagueId: 48000015, rank: 4, roundsWon: 5 });
    expect(CwlRankingHistoryEntry.fromJson({ league: 'Master League II' }).leagueId).toBeNull();
  });
});
