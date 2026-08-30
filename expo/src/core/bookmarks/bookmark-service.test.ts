import { ApiClient, UnauthorizedException } from '../api/client';
import {
  BookmarkedClan,
  BookmarkedPlayer,
  BookmarkFormatException,
  BookmarkHttpException,
  BookmarkService,
} from './bookmark-service';

type Handler = (url: URL, init?: RequestInit) => Promise<Response>;

function harness(handler: Handler) {
  const requests: { url: URL; init?: RequestInit }[] = [];
  const fetchImplementation = jest.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = new URL(String(input));
    requests.push({ url, init });
    return handler(url, init);
  }) as typeof fetch;
  const api = new ApiClient({
    baseUrl: 'https://api.test/v2',
    proxyUrl: 'https://proxy.test',
    environment: 'staging',
    tokenProvider: { getAccessToken: async () => 'access' },
    fetchImplementation,
  });
  return { service: new BookmarkService(api), requests };
}

const response = (body: unknown, status = 200) =>
  new Response(typeof body === 'string' ? body : JSON.stringify(body), { status });

describe('BookmarkService Flutter contract', () => {
  test('loads ordered player and clan caches in parallel with authenticated requests', async () => {
    const { service, requests } = harness(async (url) =>
      response(
        url.searchParams.get('type') === 'player'
          ? { items: [{ player_tag: '#P2' }, { tag: '#P1' }, 'ignored'] }
          : { items: [{ clan_tag: '#C1' }] },
      ),
    );
    const listener = jest.fn();
    service.subscribe(listener);
    service.setCurrentUserId(' user/name ');
    await service.load();

    expect(service.loaded).toBe(true);
    expect(service.players.map((item) => item.tag)).toEqual(['#P2', '#P1']);
    expect(service.clans.map((item) => item.tag)).toEqual(['#C1']);
    expect(requests.map(({ url }) => `${url.pathname}${url.search}`).sort()).toEqual([
      '/v2/links/user%2Fname/bookmarks?type=clan',
      '/v2/links/user%2Fname/bookmarks?type=player',
    ]);
    expect(requests[0]?.init?.headers).toMatchObject({ Authorization: 'Bearer access' });
    expect(listener).toHaveBeenCalledTimes(1);
  });

  test('treats either 404 collection as empty but rejects malformed and failed payloads', async () => {
    const missing = harness(async () => response({}, 404)).service;
    missing.setCurrentUserId('u');
    await missing.load();
    expect(missing.players).toEqual([]);
    expect(missing.clans).toEqual([]);
    expect(missing.loaded).toBe(true);

    const malformed = harness(async () => response({ items: {} })).service;
    malformed.setCurrentUserId('u');
    await expect(malformed.load()).rejects.toBeInstanceOf(BookmarkFormatException);

    const failed = harness(async () => response({}, 503)).service;
    failed.setCurrentUserId('u');
    await expect(failed.load()).rejects.toEqual(
      expect.objectContaining<Partial<BookmarkHttpException>>({ status: 503, action: 'load' }),
    );
  });

  test('a user change invalidates an older load without clearing the visible cache immediately', async () => {
    let releaseOld!: () => void;
    const oldPending = new Promise<void>((resolve) => (releaseOld = resolve));
    const { service } = harness(async (url) => {
      const oldUser = url.pathname.includes('/old/');
      if (oldUser) await oldPending;
      const type = url.searchParams.get('type');
      return response({ items: [{ tag: `${oldUser ? '#OLD' : '#NEW'}-${type}` }] });
    });
    service.setCurrentUserId('old');
    const oldLoad = service.load();
    service.setCurrentUserId('new');
    await service.load();
    expect(service.players[0]?.tag).toBe('#NEW-player');
    releaseOld();
    await oldLoad;
    expect(service.players[0]?.tag).toBe('#NEW-player');
  });

  test('unauthenticated load clears both caches, remains unloaded, and does not notify', async () => {
    const { service } = harness(async (url) =>
      response({ items: [{ tag: url.searchParams.get('type') === 'player' ? '#P' : '#C' }] }),
    );
    service.setCurrentUserId('u');
    await service.load();
    const listener = jest.fn();
    service.subscribe(listener);
    service.setCurrentUserId(null);
    expect(service.players).toHaveLength(1);
    await service.load();
    expect(service.loaded).toBe(false);
    expect(service.players).toEqual([]);
    expect(service.clans).toEqual([]);
    expect(listener).not.toHaveBeenCalled();
  });

  test('optimistic mutations use exact endpoints and roll back on auth or HTTP failure', async () => {
    let failDelete = true;
    const { service, requests } = harness(async (url, init) => {
      if (init?.method === 'GET') return response({ items: [] });
      if (init?.method === 'DELETE' && failDelete) return response({}, 500);
      return response({});
    });
    const player = new BookmarkedPlayer('#P', 'P', 16, '', '', '', 0, '', '');
    service.setCurrentUserId('user');
    await service.addPlayer(player);
    expect(service.players[0]).toBe(player);
    expect(JSON.parse(String(requests.at(-1)?.init?.body))).toEqual({ type: 'player', tag: '#P' });

    await expect(service.removePlayer('#P')).rejects.toBeInstanceOf(BookmarkHttpException);
    expect(service.players[0]).toBe(player);
    expect(requests.at(-1)?.url.pathname).toBe('/v2/links/user/bookmarks/player/%23P');
    failDelete = false;

    service.setCurrentUserId(null);
    await expect(service.addClan(new BookmarkedClan('#C', 'C', '', 1, 1))).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(service.clans).toEqual([]);
  });

  test('reorder preserves Flutter index validation, order body, and rollback', async () => {
    let failOrder = false;
    const { service, requests } = harness(async (_url, init) =>
      response({}, init?.method === 'PUT' && failOrder ? 409 : 200),
    );
    service.setCurrentUserId('u');
    await service.addClan(new BookmarkedClan('#A', 'A', '', 0, 0));
    await service.addClan(new BookmarkedClan('#B', 'B', '', 0, 0));
    await service.reorderClan(0, 1);
    expect(service.clans.map((item) => item.tag)).toEqual(['#A', '#B']);
    expect(JSON.parse(String(requests.at(-1)?.init?.body))).toEqual({
      type: 'clan',
      ordered_tags: ['#A', '#B'],
    });
    failOrder = true;
    await expect(service.reorderClan(0, 1)).rejects.toBeInstanceOf(BookmarkHttpException);
    expect(service.clans.map((item) => item.tag)).toEqual(['#A', '#B']);
    const before = requests.length;
    await service.reorderClan(-1, 0);
    expect(requests).toHaveLength(before);
  });

  test('reorder preserves Flutter removal-before-range-error quirk at original length', async () => {
    const { service } = harness(async () => response({}));
    service.setCurrentUserId('u');
    await service.addClan(new BookmarkedClan('#A', 'A', '', 0, 0));
    await service.addClan(new BookmarkedClan('#B', 'B', '', 0, 0));
    await expect(service.reorderClan(0, 2)).rejects.toBeInstanceOf(RangeError);
    expect(service.clans.map((item) => item.tag)).toEqual(['#A']);
  });
});
