import { createContractTestApi } from '../../core/api/contract-api.testing';
import { fetchWarWidgetSummary } from './war-widget-api';
import { buildWarWidgetPayload } from './war-widget-payload';
import { ApiResponseError } from '@clashking/api-client';

const basicWar = (type = 'regular') => ({
  type,
  clan: { tag: '#CLAN', publicWarLog: true },
  opponent: { tag: '#RIVAL', publicWarLog: true },
  preparationStartTime: '20260830T120000.000Z',
  endTime: '20260831T120000.000Z',
});
const warClan = (tag: string, name: string, stars: number) => ({
  tag,
  name,
  stars,
  badgeUrls: { small: '', medium: '', large: '' },
  members: [],
  clanLevel: 1,
  attacks: 1,
  destructionPercentage: 0,
});

function setup(response: (url: string) => { status: number; body: unknown }) {
  const fetchImplementation = jest.fn(async (input: string | URL | Request) => {
    const url = (input as Request).url;
    const { status, body } = response(url);
    return new Response(body === null ? 'null' : JSON.stringify(body), { status });
  });
  const api = createContractTestApi({
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
        body: basicWar(),
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
        clan: { tag: '#CLAN', badgeUrls: { medium: 'https://badges.clashk.ing/CLAN.avif' } },
        opponent: {
          tag: '#RIVAL',
          badgeUrls: { medium: 'https://badges.clashk.ing/RIVAL.avif' },
        },
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
      clan: expect.objectContaining({
        name: 'Clan',
        badgeUrlMedium: 'https://badges.clashk.ing/CLAN',
      }),
      opponent: expect.objectContaining({
        name: 'Rival',
        badgeUrlMedium: 'https://badges.clashk.ing/RIVAL',
      }),
    }),
  );
  const requests = fetchImplementation.mock.calls.map(([input]) => input as Request);
  expect(requests.map(({ url }) => url)).toEqual([
    'https://api.test/v2/war/%23CLAN/basic',
    'https://api.test/proxy/v1/clans/%23CLAN/currentwar',
  ]);
  expect(requests.every(({ method }) => method === 'GET')).toBe(true);
  expect(requests[1]!.headers.get('authorization')).toBe('Bearer token');
});

test('uses live league-group and league-war routes and preserves the CWL widget payload', async () => {
  const { api, fetchImplementation } = setup((url) => {
    if (url.endsWith('/v2/war/%23CLAN/basic')) {
      return { status: 200, body: { ...basicWar('cwl'), warTag: '#WAR' } };
    }
    if (url.endsWith('/proxy/v1/clans/%23CLAN/currentwar/leaguegroup')) {
      return {
        status: 200,
        body: {
          state: 'inWar',
          season: '2026-08',
          clans: [
            {
              tag: '#CLAN',
              name: 'Home',
              clanLevel: 1,
              members: [],
              badgeUrls: { small: '', medium: '', large: '' },
            },
          ],
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
          clan: warClan('#RIVAL', 'Rival', 10),
          opponent: warClan('#CLAN', 'Home', 12),
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
      cwlLeague: '2026-08',
      clan: expect.objectContaining({ name: 'Home', stars: 12 }),
      opponent: expect.objectContaining({ name: 'Rival', stars: 10 }),
    }),
  );
  expect(fetchImplementation.mock.calls.map(([input]) => (input as Request).url)).toEqual([
    'https://api.test/v2/war/%23CLAN/basic',
    'https://api.test/proxy/v1/clans/%23CLAN/currentwar/leaguegroup',
    'https://api.test/proxy/v1/clanwarleagues/wars/%23WAR',
  ]);
});

test('surfaces API failures so the widget service emits its established error payload', async () => {
  const { api } = setup(() => ({ status: 500, body: {} }));
  await expect(fetchWarWidgetSummary(api, '#CLAN')).rejects.toBeInstanceOf(ApiResponseError);
});

test('prefers the current CWL battle over a preferred upcoming preparation round', async () => {
  const { api, fetchImplementation } = setup((url) => {
    if (url.endsWith('/basic'))
      return { status: 200, body: { ...basicWar('cwl'), warTag: '#PREP' } };
    if (url.endsWith('/leaguegroup'))
      return {
        status: 200,
        body: {
          state: 'inWar',
          season: '2026-09',
          clans: [],
          rounds: [{ warTags: ['#ACTIVE'] }, { warTags: ['#PREP'] }],
        },
      };
    const prep = url.endsWith('%23PREP');
    return {
      status: 200,
      body: {
        state: prep ? 'preparation' : 'inWar',
        teamSize: 15,
        clan: warClan('#CLAN', 'Our Clan', prep ? 0 : 30),
        opponent: warClan('#RIVAL', 'Rival', prep ? 0 : 25),
      },
    };
  });
  const summary = await fetchWarWidgetSummary(api, '#CLAN');
  expect(JSON.parse(buildWarWidgetPayload(summary, '#CLAN'))).toMatchObject({
    mode: 'cwl',
    score: '30 - 25',
  });
  expect(
    fetchImplementation.mock.calls.filter(([input]) => (input as Request).url.endsWith('%23PREP')),
  ).toHaveLength(1);
});
