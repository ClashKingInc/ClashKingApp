import { ApiClient, ServerException } from '../../../core/api/client';
import { WarCwlService } from './war-cwl-service';

interface RouteResponse {
  body: unknown;
  status?: number;
}
type Route = RouteResponse | (() => Promise<Response>);

function reply(body: unknown, status = 200): Response {
  return new Response(typeof body === 'string' ? body : JSON.stringify(body), { status });
}

function harness(routes: Record<string, Route>) {
  const calls = new Map<string, number>();
  const requests: { path: string; init?: RequestInit }[] = [];
  const fetchImplementation = jest.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    const url = new URL(String(input));
    const path = `${url.pathname}${url.search}`;
    requests.push({ path, init });
    calls.set(path, (calls.get(path) ?? 0) + 1);
    const route = routes[path];
    if (typeof route === 'function') return route();
    return route ? reply(route.body, route.status ?? 200) : reply({}, 404);
  }) as typeof fetch;
  const api = new ApiClient({
    baseUrl: 'https://api.test',
    proxyUrl: 'https://proxy.test',
    environment: 'development',
    tokenProvider: { getAccessToken: async () => 'token' },
    fetchImplementation,
  });
  return { api, service: new WarCwlService(api), calls, requests };
}

const officialWar = (left: string, right: string, warTag?: string) => ({
  war_tag: warTag,
  state: 'inWar',
  teamSize: 1,
  attacksPerMember: 2,
  clan: { tag: left, name: left, members: [] },
  opponent: { tag: right, name: right, members: [] },
});

describe('WarCwlService', () => {
  test('normalizes bulk state, skips malformed items, and controls notification', () => {
    const { service } = harness({});
    const listener = jest.fn();
    service.subscribe(listener);
    service.processBulkWarData([
      'bad',
      { clan_tag: ' clan ', isInWar: false, war_info: { state: 'notInWar' } },
    ]);
    expect(service.getWarCwlByTag('CLAN')?.tag).toBe('#CLAN');
    expect(listener).toHaveBeenCalledTimes(1);
    service.processBulkWarData([], { notify: true });
    expect(listener).toHaveBeenCalledTimes(1);
  });

  test('falls back to public current war when live basic is empty', async () => {
    const { service } = harness({
      '/war/%23CLAN/basic': { body: 'null' },
      '/clans/%23CLAN/currentwar': { body: officialWar('#CLAN', '#OTHER') },
    });
    await service.loadAllWarData(['clan'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')).toMatchObject({ isInWar: true });
  });

  test('scheduled private clan uses public opponent and reorders requested side', async () => {
    const { service, calls } = harness({
      '/war/%23CLAN/basic': {
        body: {
          type: 'regular',
          clan: { tag: '#CLAN', publicWarLog: false },
          opponent: { tag: '#OTHER', publicWarLog: true },
        },
      },
      '/clans/%23OTHER/currentwar': { body: officialWar('#OTHER', '#CLAN') },
    });
    await service.loadAllWarData(['#CLAN'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')?.warInfo.clan?.tag).toBe('#CLAN');
    expect(calls.get('/clans/%23CLAN/currentwar')).toBeUndefined();
  });

  test('scheduled war becomes accessDenied when neither side is public', async () => {
    const { service } = harness({
      '/war/%23CLAN/basic': {
        body: {
          type: 'regular',
          clan: { tag: '#CLAN', publicWarLog: false },
          opponent: { tag: '#OTHER', publicWarLog: false },
        },
      },
    });
    await service.loadAllWarData(['#CLAN'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')?.warInfo.state).toBe('accessDenied');
  });

  test('manual probes resolve notInWar after regular and CWL misses', async () => {
    const { service } = harness({
      '/war/%23CLAN/basic': { body: 'null' },
      '/clans/%23CLAN/currentwar': { body: { state: 'notInWar' } },
      '/clans/%23CLAN/currentwar/leaguegroup': { body: {}, status: 404 },
    });
    await service.loadAllWarData(['#CLAN'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')?.warInfo.state).toBe('notInWar');
  });

  test('scheduled CWL preferred war loads even when league group is private', async () => {
    const { service } = harness({
      '/war/%23CLAN/basic': { body: { type: 'cwl', warTag: '#WAR' } },
      '/clans/%23CLAN/currentwar/leaguegroup': { body: { reason: 'accessDenied' }, status: 403 },
      '/clanwarleagues/wars/%23WAR': { body: officialWar('#OTHER', '#CLAN', '#WAR') },
    });
    await service.loadAllWarData(['#CLAN'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')).toMatchObject({ isInCwl: true, leagueInfo: null });
    expect(service.getWarCwlByTag('#CLAN')?.warLeagueInfos[0]?.warType).toBe('cwl');
  });

  test('manual CWL scans rounds newest-first and keeps all full wars in matching round', async () => {
    const { service, requests } = harness({
      '/war/%23CLAN/basic': { body: 'null' },
      '/clans/%23CLAN/currentwar': { body: { state: 'notInWar' } },
      '/clans/%23CLAN/currentwar/leaguegroup': {
        body: { rounds: [{ warTags: ['#OLD'] }, { warTags: ['#NEW', '#OTHER'] }] },
      },
      '/clanwarleagues/wars/%23NEW': { body: officialWar('#CLAN', '#A') },
      '/clanwarleagues/wars/%23OTHER': { body: officialWar('#B', '#C') },
    });
    await service.loadAllWarData(['#CLAN'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')?.warLeagueInfos).toHaveLength(2);
    expect(requests.some(({ path }) => path.includes('%23OLD'))).toBe(false);
  });

  test('partial failures preserve successful tags and strict callers receive first error', async () => {
    const { service } = harness({
      '/war/%23GOOD/basic': { body: 'null' },
      '/clans/%23GOOD/currentwar': { body: officialWar('#GOOD', '#O') },
      '/war/%23BAD/basic': { body: 'null' },
      '/clans/%23BAD/currentwar': { body: {}, status: 503 },
    });
    await expect(
      service.loadAllWarData(['#GOOD', '#BAD'], { notify: false, throwOnError: true }),
    ).rejects.toBeInstanceOf(ServerException);
    expect(service.getWarCwlByTag('#GOOD')?.isInWar).toBe(true);
    expect(service.getWarCwlByTag('#BAD')).toBeNull();
  });

  test('identical sorted tag sets coalesce and a later caller can escalate notification', async () => {
    let release!: () => void;
    const pending = new Promise<void>((resolve) => (release = resolve));
    const { service, calls } = harness({
      '/war/%23A/basic': async () => {
        await pending;
        return reply('null');
      },
      '/war/%23B/basic': async () => {
        await pending;
        return reply('null');
      },
      '/clans/%23A/currentwar': { body: officialWar('#A', '#O') },
      '/clans/%23B/currentwar': { body: officialWar('#B', '#O') },
    });
    const listener = jest.fn();
    service.subscribe(listener);
    const first = service.loadAllWarData(['#A', '#B'], { notify: false });
    const second = service.loadAllWarData(['#B', '#A'], { notify: true });
    release();
    await Promise.all([first, second]);
    expect(calls.get('/war/%23A/basic')).toBe(1);
    expect(calls.get('/war/%23B/basic')).toBe(1);
    expect(listener).toHaveBeenCalledTimes(1);
  });

  test('previous-war lookup uses the live end-time path contract', async () => {
    const end = new Date('2026-08-09T12:34:56Z');
    const { api, requests } = harness({
      '/war/%23ABC/previous/20260809T123456.000Z': {
        body: { war_tag: '#WAR', state: 'warEnded' },
      },
    });
    const result = await WarCwlService.fetchWarDataFromTime(api, '#ABC', end);
    expect(result?.tag).toBe('#WAR');
    expect(requests[0]?.init?.headers).not.toHaveProperty('Authorization');
  });

  test('previous-war lookup maps live 404 to no war', async () => {
    const end = new Date('2026-08-09T12:34:56Z');
    const { api } = harness({
      '/war/%23ABC/previous/20260809T123456.000Z': {
        body: { detail: 'not found' },
        status: 404,
      },
    });
    await expect(WarCwlService.fetchWarDataFromTime(api, '#ABC', end)).resolves.toBeNull();
  });
});
