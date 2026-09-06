import { ApiResponseError } from '@clashking/api-client';

import { createContractTestApi, readContractRequest } from '../../../core/api/contract-api.testing';
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
    const parsed = await readContractRequest(input, init);
    const url = parsed.url;
    const path = `${url.pathname}${url.search}`;
    requests.push({ path, init: parsed.init });
    calls.set(path, (calls.get(path) ?? 0) + 1);
    const route = routes[path];
    if (typeof route === 'function') return route();
    return route ? reply(route.body, route.status ?? 200) : reply({}, 404);
  }) as typeof fetch;
  const api = createContractTestApi({
    baseUrl: 'https://api.test',
    proxyUrl: 'https://proxy.test',
    environment: 'development',
    tokenProvider: { getAccessToken: async () => 'token' },
    fetchImplementation,
  });
  return { api, service: new WarCwlService(api), calls, requests };
}

const officialWar = (left: string, right: string, warTag?: string) => ({
  ...(warTag === undefined ? {} : { tag: warTag }),
  state: 'inWar',
  teamSize: 1,
  attacksPerMember: 2,
  preparationStartTime: '20260808T123456.000Z',
  endTime: '20260809T123456.000Z',
  clan: warClan(left),
  opponent: warClan(right),
});

function warClan(tag: string) {
  return {
    tag,
    name: tag,
    badgeUrls: { small: '', medium: '', large: '' },
    clanLevel: 1,
    attacks: 0,
    stars: 0,
    destructionPercentage: 0,
    members: [],
  };
}

function basicWar(overrides: Record<string, unknown> = {}) {
  return {
    type: 'regular',
    clan: { tag: '#CLAN', publicWarLog: true },
    opponent: { tag: '#OTHER', publicWarLog: true },
    preparationStartTime: '20260808T123456.000Z',
    endTime: '20260809T123456.000Z',
    ...overrides,
  };
}

describe('WarCwlService', () => {
  const storedGroup = (tag = '#CLAN', season = '2026-08') => ({
    state: 'ended',
    season,
    warLeague: { id: 48000018, name: 'Champion League I' },
    clans: [warClan(tag)],
    rounds: [
      { warTags: [{ ...officialWar(tag, '#OTHER'), tag: '#WAR', season }, { tag: '#0' }] },
    ],
  });

  test('loads the requested stored CWL season and hydrated wars through the shared contract', async () => {
    const { service, calls } = harness({
      '/v2/cwl/%23CLAN/group?season=2026-08': { body: storedGroup() },
    });
    const { summary, warLeagueName } = await service.loadLinkedCwl('#CLAN', '2026-08');
    expect(summary.leagueInfo?.season).toBe('2026-08');
    expect(summary.leagueInfo?.rounds[0]?.warTags).toEqual(['#WAR', '#0']);
    expect(summary.warLeagueInfos).toHaveLength(1);
    expect(summary.warLeagueInfos[0]?.tag).toBe('#WAR');
    expect(warLeagueName).toBe('Champion League I');
    expect(calls.size).toBe(1);
  });

  test('rejects a stored CWL group for another clan', async () => {
    const { service } = harness({ '/v2/cwl/%23CLAN/group': { body: storedGroup('#OTHER') } });
    await expect(service.loadLinkedCwl('#CLAN')).rejects.toThrow('requested clan');
  });
  test('loads an exact dated CWL season without reducing it to a month', async () => {
    const { service } = harness({ '/v2/cwl/%23CLAN/group?season=2026-08-02': { body: storedGroup('#CLAN', '2026-08-02') } });
    expect((await service.loadLinkedCwl('#CLAN', '2026-08-02')).summary.leagueInfo?.season).toBe('2026-08-02');
  });

  test('rejects a different stored season without substituting live data', async () => {
    const { service, calls } = harness({
      '/v2/cwl/%23CLAN/group?season=2026-07': { body: storedGroup() },
    });
    await expect(service.loadLinkedCwl('#CLAN', '2026-07')).rejects.toThrow('season unavailable');
    expect(calls.size).toBe(1);
  });

  test('an explicitly requested missing season does not fall back to the current season', async () => {
    const { service, calls } = harness({
      '/v2/cwl/%23CLAN/group?season=2026-08': { status: 404, body: { code: 'not_found', message: 'Not found' } },
    });
    await expect(service.loadLinkedCwl('#CLAN', '2026-08')).rejects.toThrow('season unavailable');
    expect(calls.size).toBe(1);
  });

  test('only an unspecified missing season may fall back to live CWL', async () => {
    const { service, calls } = harness({
      '/v2/cwl/%23CLAN/group': { status: 404, body: { code: 'not_found', message: 'Not found' } },
      '/v2/war/%23CLAN/basic': { body: basicWar({ type: 'cwl', warTag: '#WAR' }) },
      '/proxy/v1/clans/%23CLAN/currentwar/leaguegroup': {
        body: { ...storedGroup('#CLAN', '2026-09'), rounds: [{ warTags: ['#WAR'] }] },
      },
      '/proxy/v1/clanwarleagues/wars/%23WAR': { body: officialWar('#CLAN', '#OTHER', '#WAR') },
    });
    expect((await service.loadLinkedCwl('#CLAN')).summary.leagueInfo?.season).toBe('2026-09');
    expect(calls.get('/v2/cwl/%23CLAN/group')).toBe(1);
  });

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
      '/v2/war/%23CLAN/basic': { body: 'null' },
      '/proxy/v1/clans/%23CLAN/currentwar': { body: officialWar('#CLAN', '#OTHER') },
    });
    await service.loadAllWarData(['clan'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')).toMatchObject({ isInWar: true });
  });

  test('scheduled private clan uses public opponent and reorders requested side', async () => {
    const { service, calls } = harness({
      '/v2/war/%23CLAN/basic': {
        body: basicWar({
          type: 'regular',
          clan: { tag: '#CLAN', publicWarLog: false },
          opponent: { tag: '#OTHER', publicWarLog: true },
        }),
      },
      '/proxy/v1/clans/%23OTHER/currentwar': { body: officialWar('#OTHER', '#CLAN') },
    });
    await service.loadAllWarData(['#CLAN'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')?.warInfo.clan?.tag).toBe('#CLAN');
    expect(calls.get('/proxy/v1/clans/%23CLAN/currentwar')).toBeUndefined();
  });

  test('scheduled war becomes accessDenied when neither side is public', async () => {
    const { service } = harness({
      '/v2/war/%23CLAN/basic': {
        body: basicWar({
          type: 'regular',
          clan: { tag: '#CLAN', publicWarLog: false },
          opponent: { tag: '#OTHER', publicWarLog: false },
        }),
      },
    });
    await service.loadAllWarData(['#CLAN'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')?.warInfo.state).toBe('accessDenied');
  });

  test('manual probes resolve notInWar after regular and CWL misses', async () => {
    const { service } = harness({
      '/v2/war/%23CLAN/basic': { body: 'null' },
      '/proxy/v1/clans/%23CLAN/currentwar': { body: { state: 'notInWar' } },
      '/proxy/v1/clans/%23CLAN/currentwar/leaguegroup': {
        body: { reason: 'notFound', message: 'missing' },
        status: 404,
      },
    });
    await service.loadAllWarData(['#CLAN'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')?.warInfo.state).toBe('notInWar');
  });

  test('scheduled CWL preferred war loads even when league group is private', async () => {
    const { service } = harness({
      '/v2/war/%23CLAN/basic': { body: basicWar({ type: 'cwl', warTag: '#WAR' }) },
      '/proxy/v1/clans/%23CLAN/currentwar/leaguegroup': {
        body: { reason: 'accessDenied', message: 'private' },
        status: 403,
      },
      '/proxy/v1/clanwarleagues/wars/%23WAR': { body: officialWar('#OTHER', '#CLAN', '#WAR') },
    });
    await service.loadAllWarData(['#CLAN'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')).toMatchObject({ isInCwl: true, leagueInfo: null });
    expect(service.getWarCwlByTag('#CLAN')?.warLeagueInfos[0]?.warType).toBe('cwl');
  });

  test('manual CWL scans rounds newest-first and keeps all full wars in matching round', async () => {
    const { service, requests } = harness({
      '/v2/war/%23CLAN/basic': { body: 'null' },
      '/proxy/v1/clans/%23CLAN/currentwar': { body: { state: 'notInWar' } },
      '/proxy/v1/clans/%23CLAN/currentwar/leaguegroup': {
        body: {
          state: 'inWar',
          season: '2026-08',
          clans: [],
          rounds: [{ warTags: ['#OLD'] }, { warTags: ['#NEW', '#OTHER'] }],
        },
      },
      '/proxy/v1/clanwarleagues/wars/%23NEW': { body: officialWar('#CLAN', '#A') },
      '/proxy/v1/clanwarleagues/wars/%23OTHER': { body: officialWar('#B', '#C') },
    });
    await service.loadAllWarData(['#CLAN'], { notify: false });
    expect(service.getWarCwlByTag('#CLAN')?.warLeagueInfos).toHaveLength(2);
    expect(requests.some(({ path }) => path.includes('%23OLD'))).toBe(false);
  });

  test('partial failures preserve successful tags and strict callers receive first error', async () => {
    const { service } = harness({
      '/v2/war/%23GOOD/basic': { body: 'null' },
      '/proxy/v1/clans/%23GOOD/currentwar': { body: officialWar('#GOOD', '#O') },
      '/v2/war/%23BAD/basic': { body: 'null' },
      '/proxy/v1/clans/%23BAD/currentwar': { body: {}, status: 503 },
    });
    await expect(
      service.loadAllWarData(['#GOOD', '#BAD'], { notify: false, throwOnError: true }),
    ).rejects.toBeInstanceOf(ApiResponseError);
    expect(service.getWarCwlByTag('#GOOD')?.isInWar).toBe(true);
    expect(service.getWarCwlByTag('#BAD')).toBeNull();
  });

  test('identical sorted tag sets coalesce and a later caller can escalate notification', async () => {
    let release!: () => void;
    const pending = new Promise<void>((resolve) => (release = resolve));
    const { service, calls } = harness({
      '/v2/war/%23A/basic': async () => {
        await pending;
        return reply('null');
      },
      '/v2/war/%23B/basic': async () => {
        await pending;
        return reply('null');
      },
      '/proxy/v1/clans/%23A/currentwar': { body: officialWar('#A', '#O') },
      '/proxy/v1/clans/%23B/currentwar': { body: officialWar('#B', '#O') },
    });
    const listener = jest.fn();
    service.subscribe(listener);
    const first = service.loadAllWarData(['#A', '#B'], { notify: false });
    const second = service.loadAllWarData(['#B', '#A'], { notify: true });
    release();
    await Promise.all([first, second]);
    expect(calls.get('/v2/war/%23A/basic')).toBe(1);
    expect(calls.get('/v2/war/%23B/basic')).toBe(1);
    expect(listener).toHaveBeenCalledTimes(1);
  });

  test('previous-war lookup uses the live end-time path contract', async () => {
    const end = new Date('2026-08-09T12:34:56Z');
    const { api, requests } = harness({
      '/v2/war/%23ABC/previous/20260809T123456.000Z': {
        body: { ...officialWar('#ABC', '#OTHER', '#WAR'), state: 'warEnded' },
      },
    });
    const result = await WarCwlService.fetchWarDataFromTime(api, '#ABC', end);
    expect(result?.tag).toBe('#WAR');
    expect(requests[0]?.init?.headers).not.toHaveProperty('authorization');
  });

  test('previous-war lookup maps live 404 to no war', async () => {
    const end = new Date('2026-08-09T12:34:56Z');
    const { api } = harness({
      '/v2/war/%23ABC/previous/20260809T123456.000Z': {
        body: { code: 'not_found', message: 'not found' },
        status: 404,
      },
    });
    await expect(WarCwlService.fetchWarDataFromTime(api, '#ABC', end)).resolves.toBeNull();
  });
});
