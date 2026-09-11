import { createApiClient, httpTransport } from '@clashking/api-client';
import { ClientErrorResponse, ClanWar } from '@clashking/clash-contract/effect';
import { Effect } from 'effect';

import { ProxyCurrentWarEndpoint, ProxyCurrentLeagueGroupEndpoint } from './proxy-contracts';

it.each([ProxyCurrentWarEndpoint, ProxyCurrentLeagueGroupEndpoint])(
  'handles a reason-only error for $path without failing decoding',
  async (endpoint) => {
    const fetcher = jest.fn(
      async () =>
        new Response(JSON.stringify({ reason: 'notFound' }), {
          status: 404,
          headers: { 'content-type': 'application/json' },
        }),
    ) as unknown as typeof fetch;
    const api = createApiClient({ baseUrl: 'https://api.test', transport: httpTransport(fetcher) });
    const result = await Effect.runPromise(
      api.executeStatus(endpoint, {
        path: { clanTag: '#CLAN' },
        query: {},
        body: {},
      }),
    );
    expect(result).toEqual({ ok: false, status: 404, body: { reason: 'notFound' } });
    expect(endpoint.errors.every((error) => error.body === ClientErrorResponse)).toBe(true);
  },
);

it('uses the released war response schema', () => {
  expect(ProxyCurrentWarEndpoint.response).toBe(ClanWar);
});
