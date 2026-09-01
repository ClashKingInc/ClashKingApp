import { ApiClient, ResponseFormatException } from '../../../core/api/client';
import {
  CONNECTED_APPLICATION_GRANTS_ENDPOINT,
  ConnectedApplicationsService,
} from './connected-applications-service';

function response(body: unknown, status = 200): Response {
  return {
    status,
    url: '',
    headers: new Headers(),
    text: async () => (body === '' ? '' : JSON.stringify(body)),
  } as Response;
}

function setup(responses: readonly Response[]) {
  const calls: { url: string; init?: RequestInit }[] = [];
  let index = 0;
  const fetchImplementation = jest.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
    calls.push({ url: String(input), init });
    return responses[index++] ?? response({}, 500);
  });
  const api = new ApiClient({
    baseUrl: 'https://api.test/v2',
    environment: 'development',
    platform: 'native',
    tokenProvider: { getAccessToken: async () => 'user-session-token' },
    fetchImplementation: fetchImplementation as typeof fetch,
  });
  return { service: new ConnectedApplicationsService(api), calls };
}

describe('ConnectedApplicationsService', () => {
  it('decodes the authoritative grant list and authenticates with the user session', async () => {
    const { service, calls } = setup([
      response({
        items: [
          {
            application: { id: 'app-1', name: 'War Planner', developer_name: 'Example Studio' },
            grant: {
              access_mode: 'selected',
              selected_player_tags: ['#ONE', '#TWO'],
              connected_at: '2026-08-31T12:00:00Z',
              updated_at: '2026-09-01T12:00:00Z',
            },
          },
          {
            application: { id: 'app-2', name: 'Clan Tools' },
            grant: {
              access_mode: 'all_current_and_future',
              selected_player_tags: [],
              connected_at: '2026-08-30T12:00:00Z',
              updated_at: '2026-08-30T12:00:00Z',
            },
          },
        ],
      }),
    ]);

    await expect(service.load()).resolves.toEqual([
      {
        application: { id: 'app-1', name: 'War Planner', developerName: 'Example Studio' },
        grant: {
          accessMode: 'selected',
          selectedPlayerTags: ['#ONE', '#TWO'],
          connectedAt: '2026-08-31T12:00:00Z',
          updatedAt: '2026-09-01T12:00:00Z',
        },
      },
      {
        application: { id: 'app-2', name: 'Clan Tools' },
        grant: {
          accessMode: 'all_current_and_future',
          selectedPlayerTags: [],
          connectedAt: '2026-08-30T12:00:00Z',
          updatedAt: '2026-08-30T12:00:00Z',
        },
      },
    ]);
    expect(calls[0]?.url).toBe(`https://api.test/v2${CONNECTED_APPLICATION_GRANTS_ENDPOINT}`);
    expect(calls[0]?.init?.method).toBe('GET');
    expect((calls[0]?.init?.headers as Record<string, string>).Authorization).toBe(
      'Bearer user-session-token',
    );
  });

  it('requires the current response shape instead of accepting legacy fields', async () => {
    const { service } = setup([
      response({
        items: [
          {
            application: { id: 'app-1', name: 'Legacy' },
            grant: { accessMode: 'selected', selectedPlayerTags: ['#ONE'] },
          },
        ],
      }),
    ]);
    await expect(service.load()).rejects.toBeInstanceOf(ResponseFormatException);
  });

  it('revokes by encoded application id only after an authenticated 204', async () => {
    const { service, calls } = setup([response('', 204)]);
    await expect(service.revoke('app/id')).resolves.toBeUndefined();
    expect(calls[0]?.url).toBe(
      `https://api.test/v2${CONNECTED_APPLICATION_GRANTS_ENDPOINT}/app%2Fid`,
    );
    expect(calls[0]?.init?.method).toBe('DELETE');
    expect((calls[0]?.init?.headers as Record<string, string>).Authorization).toBe(
      'Bearer user-session-token',
    );
  });

  it('rejects a non-204 revoke response', async () => {
    const { service } = setup([response({}, 200)]);
    await expect(service.revoke('app-1')).rejects.toThrow();
  });
});
