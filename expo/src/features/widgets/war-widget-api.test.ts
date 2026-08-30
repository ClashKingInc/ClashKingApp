import { ApiClient } from '../../core/api/client';
import { fetchWarWidgetSummary } from './war-widget-api';
import { buildWarWidgetPayload } from './war-widget-payload';

function setup(response: (url: string) => { status: number; body: unknown }) {
  const fetchImplementation = jest.fn(async (input: string | URL | Request) => {
    const url = String(input);
    const { status, body } = response(url);
    return {
      status,
      url: '',
      headers: new Headers(),
      text: async () => (body === null ? 'null' : JSON.stringify(body)),
    } as Response;
  });
  const api = new ApiClient({
    baseUrl: 'https://api.test/v2',
    proxyUrl: 'https://api.test/proxy/v1',
    environment: 'production',
    tokenProvider: { getAccessToken: async () => 'token' },
    fetchImplementation: fetchImplementation as typeof fetch,
  });
  return { api, fetchImplementation };
}

test('uses the live basic-war resolver and preserves the regular widget payload', async () => {
  const currentWar = {
    state: 'inWar',
    teamSize: 15,
    attacksPerMember: 2,
    clan: {
      tag: '#CLAN',
      name: 'Clan',
      badgeUrls: { small: 'small', medium: 'medium', large: 'large' },
      clanLevel: 20,
      attacks: 10,
      stars: 25,
      destructionPercentage: 88.5,
      members: [],
    },
    opponent: {
      tag: '#RIVAL',
      name: 'Rival',
      badgeUrls: { small: 'r-small', medium: 'r-medium', large: 'r-large' },
      clanLevel: 18,
      attacks: 9,
      stars: 23,
      destructionPercentage: 82,
      members: [],
    },
  };
  const { api, fetchImplementation } = setup((url) => {
    if (url.endsWith('/v2/war/%23CLAN/basic')) {
      return {
        status: 200,
        body: {
          type: 'regular',
          clan: { tag: '#CLAN', publicWarLog: true },
          opponent: { tag: '#RIVAL', publicWarLog: true },
        },
      };
    }
    if (url.endsWith('/proxy/v1/clans/%23CLAN/currentwar')) {
      return { status: 200, body: currentWar };
    }
    throw new Error(`Unexpected request: ${url}`);
  });
  const summary = await fetchWarWidgetSummary(api, 'clan');
  expect(summary).toMatchObject({
    clan_tag: '#CLAN',
    isInWar: true,
    isInCwl: false,
    war_info: {
      state: 'inWar',
      currentWarInfo: {
        state: 'inWar',
        clan: { tag: '#CLAN', badgeUrls: { medium: 'medium' } },
        opponent: { tag: '#RIVAL', badgeUrls: { medium: 'r-medium' } },
      },
    },
    league_info: null,
    war_league_infos: [],
  });
  expect(
    JSON.parse(buildWarWidgetPayload(summary, '#CLAN', new Date('2026-08-30T12:00:00Z'))),
  ).toEqual(
    expect.objectContaining({
      state: 'inWar',
      mode: 'war',
      score: '25 - 23',
      clan: expect.objectContaining({ name: 'Clan', badgeUrlMedium: 'small' }),
      opponent: expect.objectContaining({ name: 'Rival', badgeUrlMedium: 'r-small' }),
    }),
  );
  expect(fetchImplementation).toHaveBeenCalledWith(
    'https://api.test/v2/war/%23CLAN/basic',
    expect.objectContaining({ method: 'GET' }),
  );
  expect(fetchImplementation).toHaveBeenCalledWith(
    'https://api.test/proxy/v1/clans/%23CLAN/currentwar',
    expect.objectContaining({
      method: 'GET',
      headers: expect.objectContaining({ Authorization: 'Bearer token' }),
    }),
  );
});

test('uses live league-group and league-war routes and preserves the CWL widget payload', async () => {
  const { api, fetchImplementation } = setup((url) => {
    if (url.endsWith('/v2/war/%23CLAN/basic')) {
      return { status: 200, body: { type: 'cwl', warTag: '#WAR' } };
    }
    if (url.endsWith('/proxy/v1/clans/%23CLAN/currentwar/leaguegroup')) {
      return {
        status: 200,
        body: {
          state: 'inWar',
          season: '2026-08',
          clans: [{ tag: '#CLAN', name: 'Home', rank: 2, badgeUrls: {} }],
          rounds: [{ warTags: ['#WAR'] }],
        },
      };
    }
    if (url.endsWith('/proxy/v1/clanwarleagues/wars/%23WAR')) {
      return {
        status: 200,
        body: {
          state: 'inWar',
          teamSize: 15,
          clan: { tag: '#RIVAL', name: 'Rival', stars: 10, badgeUrls: {}, members: [] },
          opponent: { tag: '#CLAN', name: 'Home', stars: 12, badgeUrls: {}, members: [] },
        },
      };
    }
    throw new Error(`Unexpected request: ${url}`);
  });

  const summary = await fetchWarWidgetSummary(api, '#CLAN');
  expect(JSON.parse(buildWarWidgetPayload(summary, '#CLAN'))).toEqual(
    expect.objectContaining({
      state: 'cwl',
      mode: 'cwl',
      score: '12 - 10',
      cwlRank: 2,
      cwlLeague: '2026-08',
      clan: expect.objectContaining({ name: 'Home', stars: 12 }),
      opponent: expect.objectContaining({ name: 'Rival', stars: 10 }),
    }),
  );
  expect(fetchImplementation.mock.calls.map(([url]) => String(url))).toEqual([
    'https://api.test/v2/war/%23CLAN/basic',
    'https://api.test/proxy/v1/clans/%23CLAN/currentwar/leaguegroup',
    'https://api.test/proxy/v1/clanwarleagues/wars/%23WAR',
  ]);
});

test('surfaces API failures so the widget service emits its established error payload', async () => {
  const { api } = setup(() => ({ status: 500, body: {} }));
  await expect(fetchWarWidgetSummary(api, '#CLAN')).rejects.toThrow(
    'Unexpected API status 500 for /war/%23CLAN/basic.',
  );
});
