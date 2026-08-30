import { ApiClient } from '../../../core/api/client';
import { Clan, ClanLeaderboardType, ClanWarStatsFilter } from '../models';
import { ClanService } from './clan-service';

type RequestLog = { url: string; init?: RequestInit };

function harness(responder: (url: string, init?: RequestInit) => Response | Promise<Response>) {
  const requests: RequestLog[] = [];
  const fetchImplementation = jest.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = String(input);
    requests.push({ url, init });
    return responder(url, init);
  }) as typeof fetch;
  const api = new ApiClient({
    baseUrl: 'https://api.example',
    proxyUrl: 'https://api.example/proxy/v1',
    environment: 'staging',
    tokenProvider: { getAccessToken: async () => 'token' },
    fetchImplementation,
    platform: 'native',
  });
  return { service: new ClanService(api), requests };
}

function json(value: unknown, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

describe('ClanService', () => {
  test('normalizes, deduplicates, bounds, stores, and notifies bulk official loads', async () => {
    const { service, requests } = harness((url) =>
      json({ tag: decodeURIComponent(url.split('/').at(-1)!), name: 'Clan' }),
    );
    let notifications = 0;
    service.subscribe(() => (notifications += 1));
    await service.loadAllClanData(['abc', '#ABC', ' #def ']);
    expect(requests.map((item) => item.url)).toEqual([
      'https://api.example/proxy/v1/clans/%23ABC',
      'https://api.example/proxy/v1/clans/%23DEF',
    ]);
    expect([...service.clans.keys()]).toEqual(['#ABC', '#DEF']);
    expect(notifications).toBe(2);
    expect(service.isLoading).toBe(false);
  });

  test('coalesces identical detail requests and bypasses cache for tracking headers', async () => {
    let release!: () => void;
    const pending = new Promise<void>((resolve) => (release = resolve));
    const { service, requests } = harness(async () => {
      await pending;
      return json({ tag: '#ABC', name: 'Clan' });
    });
    const first = service.loadClanData('#abc');
    const second = service.loadClanData('ABC');
    release();
    expect(await first).toBe(await second);
    await service.loadClanData('#ABC');
    await service.loadClanData('#ABC', { extraHeaders: { 'x-ck-user-id': '42' } });
    expect(requests).toHaveLength(2);
    expect(requests[1]?.init?.headers).toMatchObject({ 'x-ck-user-id': '42' });
  });

  test('history methods use canonical tags, exact endpoints, and unauthenticated GET', async () => {
    const { service, requests } = harness(() => json({ items: [] }));
    await service.getClanLeaderboardHistory(' abc ', ClanLeaderboardType.homeVillage, {
      after: new Date('2026-01-01T00:00:00Z'),
    });
    await service.getClanLegendHistorySummary('abc');
    expect(requests[0]?.url).toContain(
      '/clan/%23ABC/history/leaderboards?type=clan_home_points&limit=250&time%5Bafter%5D=',
    );
    expect(requests[1]?.url).toBe('https://api.example/clan/%23ABC/history/legends/summary?top=10');
    expect(requests[0]?.init?.headers).not.toHaveProperty('Authorization');
  });

  test('CWL history preserves the caller tag rather than canonicalizing it', async () => {
    const { service, requests } = harness(() => json({ items: [] }));
    await service.getCwlRankingHistory('abc');
    expect(requests[0]?.url).toBe('https://api.example/cwl/abc/seasons?limit=100');
  });

  test('join/leave is authenticated GET and transport failures become per-clan misses', async () => {
    const { service, requests } = harness(() => {
      throw new TypeError('offline');
    });
    await expect(service.loadClanJoinLeaveData(['#C'], { throwOnError: true })).resolves.toEqual(
      [],
    );
    expect(requests[0]?.url).toBe('https://api.example/clan/%23C/join-leave?limit=50');
    expect(requests[0]?.init?.headers).toMatchObject({ Authorization: 'Bearer token' });
  });

  test('join/leave paging subtracts one microsecond and deduplicates appended events', async () => {
    let call = 0;
    const { service, requests } = harness(() => {
      call += 1;
      return json(
        call === 1
          ? {
              available: 2,
              items: [{ type: 'join', tag: '#P', time: '2026-08-01T00:00:00.123Z' }],
            }
          : { available: 2, items: [{ type: 'leave', tag: '#Q', time: '2026-07-01Z' }] },
      );
    });
    const clan = Clan.fromJson({ tag: '#C' });
    clan.joinLeave = (await service.loadClanJoinLeaveData(['#C']))[0]!;
    await expect(service.loadMoreJoinLeaveForClan(clan)).resolves.toBe(true);
    expect(requests[1]?.url).toContain('time%5Bbefore%5D=2026-08-01T00%3A00%3A00.122999Z');
    expect(clan.joinLeave.joinLeaveList).toHaveLength(2);
  });

  test('capital uses the official proxy without tag normalization and preserves limit', async () => {
    const { service, requests } = harness(() => json({ items: [{ state: 'ended' }] }));
    const result = await service.loadCapitalData(['abc'], 10);
    expect(requests[0]?.url).toBe(
      'https://api.example/proxy/v1/clans/abc/capitalraidseasons?limit=10',
    );
    expect(result[0]?.clanTag).toBe('abc');
  });

  test('war logs use the authenticated API endpoint that handles public and private logs', async () => {
    const { service, requests } = harness(() => json({ items: [] }));
    await service.loadWarLogData(['abc']);
    await service.loadWarLogData(['def']);
    expect(requests[0]?.url).toBe('https://api.example/clan/%23ABC/warlog?limit=50');
    expect(requests[1]?.url).toBe('https://api.example/clan/%23DEF/warlog?limit=50');
    expect(requests[0]?.init?.headers).toMatchObject({ Authorization: 'Bearer token' });
    expect(requests[1]?.init?.headers).toMatchObject({ Authorization: 'Bearer token' });
  });

  test('war stats use live typed clan-war history reads and preserve the requested clan tag', async () => {
    const { service, requests } = harness((url) =>
      json({
        items: url.includes('type=random')
          ? [
              {
                state: 'warEnded',
                teamSize: 1,
                attacksPerMember: 2,
                endTime: '20260820T120000.000Z',
                clan: {
                  tag: '#C',
                  members: [
                    {
                      tag: '#P',
                      name: 'Player',
                      townhallLevel: 18,
                      mapPosition: 1,
                      attacks: [
                        {
                          attackerTag: '#P',
                          defenderTag: '#D',
                          stars: 3,
                          destructionPercentage: 100,
                          order: 1,
                        },
                      ],
                    },
                  ],
                },
                opponent: {
                  tag: '#O',
                  members: [
                    { tag: '#D', name: 'Defender', townhallLevel: 18, mapPosition: 1, attacks: [] },
                  ],
                },
              },
            ]
          : [],
      }),
    );
    await service.loadClanWarStatsData(['#C']);
    const filtered = await service.loadClanWarStatsWithFilter(
      '#C',
      new ClanWarStatsFilter({ limit: 25, sameTownHall: true }),
    );
    expect(requests.slice(0, 3).map((request) => request.url)).toEqual([
      'https://api.example/clan/%23C/wars?type=random&limit=50',
      'https://api.example/clan/%23C/wars?type=cwl&limit=50',
      'https://api.example/clan/%23C/wars?type=friendly&limit=50',
    ]);
    expect(requests.slice(3).map((request) => request.url)).toEqual([
      'https://api.example/clan/%23C/wars?type=random&limit=25',
      'https://api.example/clan/%23C/wars?type=cwl&limit=25',
      'https://api.example/clan/%23C/wars?type=friendly&limit=25',
    ]);
    expect(requests.every((request) => request.init?.method === 'GET')).toBe(true);
    expect(filtered?.clanTag).toBe('#C');
    expect(filtered?.players[0]?.getSpecificStats('random')).toMatchObject({
      warsCounts: 1,
      totalAttacks: 1,
      missedAttacks: 1,
    });
  });

  test('bulk processing ignores legacy join_leave_data and skips war_data ownership', async () => {
    const { service } = harness(() => json({}));
    let notifications = 0;
    service.subscribe(() => (notifications += 1));
    await service.processBulkClanData(
      {
        clan_details: { '#C': { tag: '#C', name: 'Clan' } },
        join_leave_data: [{ clan_tag: '#C', items: [{}] }],
        war_data: [{ tag: '#C' }],
        capital_data: [{ clan_tag: '#C', history: [] }],
      },
      ['#C'],
    );
    expect(service.getClanByTag('#C')?.name).toBe('Clan');
    expect(service.joinLeaveList).toEqual([]);
    expect(service.capitalHistory).toHaveLength(1);
    expect(notifications).toBe(1);
  });

  test('dispose makes listener notification safe and inert', () => {
    const { service } = harness(() => json({}));
    const listener = jest.fn();
    service.subscribe(listener);
    service.dispose();
    service.notifyDataChanged();
    expect(listener).not.toHaveBeenCalled();
  });

  test('decodes all clan history resources and applies both range boundaries', async () => {
    const { service, requests } = harness((url) => {
      if (url.includes('/leaderboards/summary')) return json({ seasons: [{ season: '2026-08' }] });
      if (url.includes('/history/leaderboards')) return json({ items: [{ rank: 1 }] });
      if (url.includes('/history/legends/summary')) return json({ seasons: [], topFinishes: [] });
      if (url.includes('/history/legends')) return json({ items: [{ rank: 2 }] });
      if (url.endsWith('/records')) return json({ clanPoints: { value: 123 } });
      return json({ items: [{ type: 'description', current: 'New' }] });
    });
    const after = new Date('2026-01-01T00:00:00Z');
    const before = new Date('2026-02-01T00:00:00Z');

    expect(
      (
        await service.getClanLeaderboardHistory('#C', ClanLeaderboardType.builderBase, {
          after,
          before,
        })
      ).items,
    ).toHaveLength(1);
    expect(
      (await service.getClanLeaderboardHistorySummary('#C', ClanLeaderboardType.clanCapital))
        .seasons,
    ).toHaveLength(1);
    expect((await service.getClanLegendHistory('#C', { after, before })).items).toHaveLength(1);
    expect((await service.getClanLegendHistorySummary('#C')).topFinishes).toEqual([]);
    expect((await service.getClanRecords('#C')).clanPoints?.value).toBe(123);
    expect((await service.getClanProfileHistory('#C')).items[0]?.type).toBe('description');
    expect(requests[0]?.url).toContain('time%5Bafter%5D=');
    expect(requests[0]?.url).toContain('time%5Bbefore%5D=');
  });

  test('enriches incomplete members, coalesces duplicate tags, and preserves clan role data', async () => {
    const { service, requests } = harness((url) => {
      if (url.includes('/clans/')) {
        return json({
          tag: '#C',
          name: 'Clan',
          memberList: [
            { tag: '#P', name: 'Original', role: 'admin', donations: 4 },
            { tag: '#P', name: 'Duplicate', role: 'member', donations: 1 },
          ],
        });
      }
      return json({
        tag: '#P',
        name: 'Enriched',
        townHallLevel: 18,
        leagueTier: { id: 1, name: 'League' },
        donations: 9,
      });
    });

    const clan = await service.getClanAndWarData('#C');

    expect(requests.filter(({ url }) => url.includes('/players/'))).toHaveLength(1);
    expect(clan.memberList).toHaveLength(2);
    expect(clan.memberList[0]).toMatchObject({
      name: 'Enriched',
      role: 'member',
      townHallLevel: 18,
      donations: 9,
    });
    expect(clan.memberList[1]).toMatchObject({ name: 'Enriched', role: 'member' });
  });

  test('links loaded auxiliaries and war ownership to matching clans', async () => {
    const { service } = harness(() => json({ tag: '#C', name: 'Clan' }));
    await service.loadClanData('#C');
    const clan = service.getClanByTag('#C')!;
    const war = { tag: '#C' };

    service.linkJoinLeaveToClans();
    service.linkCapitalToClans();
    service.linkWarLogToClans();
    service.linkWarStatsToClans();
    service.linkWarsToClans([clan], [war, { tag: '#OTHER' }]);

    expect(clan.clanCapitalRaid).not.toBeNull();
    expect(clan.clanWarLog).not.toBeNull();
    expect(clan.clanWarStats).not.toBeNull();
    expect(clan.warCwl).toBe(war);
  });

  test('handles empty and failed optional loads without mutating successful state', async () => {
    const { service } = harness((url) => {
      if (url.includes('capitalraidseasons')) return json({}, 500);
      if (url.includes('/warlog')) return json({}, 500);
      return json({});
    });
    const clan = Clan.fromJson({ tag: '#C' });

    await expect(service.loadCapitalData([], 10)).resolves.toEqual([]);
    await expect(service.loadCapitalData(['#C'], 10)).resolves.toEqual([]);
    await expect(service.loadCapitalData(['#C'], 10, { throwOnError: true })).rejects.toThrow(
      'Failed to load capital data',
    );
    await expect(service.loadWarLogData([])).resolves.toEqual([]);
    await expect(service.loadWarLogData(['#C'])).resolves.toEqual([]);
    await expect(service.loadMoreJoinLeaveForClan(clan)).resolves.toBe(false);
    expect(service.isLoading).toBe(false);
  });

  test('skips malformed bulk entries while retaining valid war-log and stat payloads', async () => {
    const { service } = harness(() => json({}));
    await service.processBulkClanData(
      {
        clan_details: { '#BAD': null, '#C': { tag: '#C', name: 'Clan' } },
        capital_data: [{ clan_tag: '' }, { clan_tag: '#C', history: [], stats: {} }],
        war_log_data: [null, { clan_tag: '#C', items: [] }],
        clan_war_stats: [{ clan_tag: '#C', players: [] }],
      },
      [],
    );

    expect(service.getClanByTag('#C')?.name).toBe('Clan');
    expect(service.capitalHistory).toHaveLength(1);
    expect(service.warLogList).toHaveLength(1);
    expect(service.warStatsList).toHaveLength(1);
  });
});
