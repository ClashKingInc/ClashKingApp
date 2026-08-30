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
});
