import { createContractTestApi } from '../../core/api/contract-api.testing';
import { emptyClanSearchFilters } from './models';
import { SearchService } from './search-service';
import { TransportError } from '@clashking/api-client';

function reply(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status });
}

function clan(tag: string, name = 'Clan') {
  return {
    tag,
    name,
    type: 'open',
    description: '',
    isFamilyFriendly: true,
    badgeUrls: { small: '', medium: '', large: '' },
    clanLevel: 1,
    clanPoints: 0,
    clanBuilderBasePoints: 0,
    clanCapitalPoints: 0,
    requiredTrophies: 0,
    warFrequency: 'always',
    warWinStreak: 0,
    warWins: 0,
    isWarLogPublic: true,
    members: 0,
    memberList: [],
    labels: [],
  };
}

function setup(routes: Record<string, { body: unknown; status?: number }>) {
  const fetchMock = jest.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = new URL((input as Request).url);
    const route = routes[`${url.host}${url.pathname}${url.search}`];
    return reply(route?.body ?? {}, route?.status ?? (route ? 200 : 404));
  });
  const api = createContractTestApi({
    baseUrl: 'https://api.test',
    proxyUrl: 'https://proxy.test',
    environment: 'development',
    tokenProvider: { getAccessToken: async () => 'token' },
    fetchImplementation: fetchMock as typeof fetch,
  });
  return { service: new SearchService(api), fetchMock };
}

describe('SearchService', () => {
  it('does not report an offline clan search as an empty result', async () => {
    const { service, fetchMock } = setup({});
    fetchMock.mockRejectedValueOnce(new TypeError('offline'));
    await expect(service.searchClans('Clan', emptyClanSearchFilters)).rejects.toBeInstanceOf(
      TransportError,
    );
  });
  it('loads authenticated recent searches from the exact user route', async () => {
    const { service, fetchMock } = setup({
      'api.test/v2/links/user%2F1/searches': {
        body: { players: [{ tag: '#P', created_at: '2026-01-01T00:00:00Z' }], clans: [] },
      },
    });
    await expect(service.loadRecents('user/1')).resolves.toMatchObject([{ tag: '#P' }]);
    expect((fetchMock.mock.calls[0]![0] as Request).headers.get('authorization')).toBe(
      'Bearer token',
    );
    await expect(service.loadRecents(null)).resolves.toEqual([]);
  });

  it('uses the exact official clan search route, filters, limit, and member-list flag', async () => {
    const endpoint =
      'api.test/proxy/v1/clans?name=Red+Dragons&warFrequency=always&minMembers=20&limit=20&memberList=false';
    const { description: _description, memberList: _memberList, ...searchClan } = clan('#C');
    const { service } = setup({ [endpoint]: { body: { items: [searchClan] } } });
    await expect(
      service.searchClans('Red Dragons', {
        ...emptyClanSearchFilters,
        warFrequency: 'always',
        minMembers: 20,
        minClanPoints: 30000,
      }),
    ).resolves.toEqual([searchClan]);
  });

  it('treats recent and clan HTTP misses as Flutter best-effort empty results', async () => {
    const { service } = setup({
      'api.test/v2/links/u/searches': { body: {}, status: 500 },
      'api.test/proxy/v1/clans?name=abc&limit=20&memberList=false': { body: {}, status: 404 },
    });
    await expect(service.loadRecents('u')).resolves.toEqual([]);
    await expect(service.searchClans('abc', emptyClanSearchFilters)).resolves.toEqual([]);
  });

  it('retains Flutter SearchPage direct clan fallback with tracking headers', async () => {
    const { service, fetchMock } = setup({
      'api.test/proxy/v1/clans/%23ABC': { body: clan('#ABC', 'Fallback Clan') },
    });

    await expect(
      service.loadClanFallback('#ABC', { 'x-ck-user-id': 'user-1' }),
    ).resolves.toMatchObject({
      tag: '#ABC',
      name: 'Fallback Clan',
    });
    expect((fetchMock.mock.calls[0]![0] as Request).headers.get('x-ck-user-id')).toBe('user-1');
  });
});
