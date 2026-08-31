import { ApiClient } from '../../core/api/client';
import { emptyClanSearchFilters } from './models';
import { SearchService } from './search-service';

function reply(body: unknown, status = 200): Response {
  return {
    status,
    url: '',
    headers: { get: () => null },
    text: async () => JSON.stringify(body),
  } as unknown as Response;
}

function setup(routes: Record<string, { body: unknown; status?: number }>) {
  const fetchMock = jest.fn(async (input: RequestInfo | URL, _init?: RequestInit) => {
    const url = new URL(String(input));
    const route = routes[`${url.host}${url.pathname}${url.search}`];
    return reply(route?.body ?? {}, route?.status ?? (route ? 200 : 404));
  });
  const api = new ApiClient({
    baseUrl: 'https://api.test',
    proxyUrl: 'https://proxy.test',
    environment: 'development',
    tokenProvider: { getAccessToken: async () => 'token' },
    fetchImplementation: fetchMock as typeof fetch,
  });
  return { service: new SearchService(api), fetchMock };
}

describe('SearchService', () => {
  it('loads authenticated recent searches from the exact user route', async () => {
    const { service, fetchMock } = setup({
      'api.test/links/user%2F1/searches': {
        body: { players: [{ tag: '#P', created_at: '2026-01-01T00:00:00Z' }] },
      },
    });
    await expect(service.loadRecents('user/1')).resolves.toMatchObject([{ tag: '#P' }]);
    expect(fetchMock.mock.calls[0]?.[1]).toMatchObject({
      headers: expect.objectContaining({ Authorization: 'Bearer token' }),
    });
    await expect(service.loadRecents(null)).resolves.toEqual([]);
  });

  it('uses the exact official clan search route, filters, limit, and member-list flag', async () => {
    const endpoint =
      'proxy.test/clans?name=Red%20Dragons&warFrequency=always&minMembers=20&limit=20&memberList=false';
    const { service } = setup({ [endpoint]: { body: { items: [{ tag: '#C' }] } } });
    await expect(
      service.searchClans('Red Dragons', {
        ...emptyClanSearchFilters,
        warFrequency: 'always',
        minMembers: 20,
        minClanPoints: 30000,
      }),
    ).resolves.toEqual([{ tag: '#C' }]);
  });

  it('treats recent and clan HTTP misses as Flutter best-effort empty results', async () => {
    const { service } = setup({
      'api.test/links/u/searches': { body: {}, status: 500 },
      'proxy.test/clans?name=abc&limit=20&memberList=false': { body: {}, status: 404 },
    });
    await expect(service.loadRecents('u')).resolves.toEqual([]);
    await expect(service.searchClans('abc', emptyClanSearchFilters)).resolves.toEqual([]);
  });

  it('retains Flutter SearchPage direct clan fallback with tracking headers', async () => {
    const { service, fetchMock } = setup({
      'proxy.test/clans/%23ABC': { body: { tag: '#ABC', name: 'Fallback Clan' } },
    });

    await expect(service.loadClanFallback('#ABC', { 'x-ck-user-id': 'user-1' })).resolves.toEqual({
      tag: '#ABC',
      name: 'Fallback Clan',
    });
    expect(fetchMock.mock.calls[0]?.[1]).toMatchObject({
      headers: expect.objectContaining({ 'x-ck-user-id': 'user-1' }),
    });
  });
});
