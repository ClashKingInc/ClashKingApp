import {
  createApiClient,
  withUnauthorizedRefresh,
  TransportError,
  type ApiTransport,
} from '@clashking/api-client';
import type { AnyEndpoint } from '@clashking/api-contracts/expo';

import type { ContractApiService } from './contract-api';

export function createAppContractClient(options: {
  baseUrl: string;
  transport: ApiTransport;
  web: boolean;
  tokens?: {
    readonly sessionVersion: number;
    getAccessToken(): Promise<string | null>;
    refreshAfterUnauthorized(rejectedAccessToken: string): Promise<string | null>;
    canReplayWithAccessToken(rejected: string, current: string): boolean;
  };
}): ContractApiService {
  const tokens = options.tokens;
  const versions = new WeakMap<Request, number>();
  const assertSameSession = (request: Request) => {
    if (versions.get(request) !== tokens?.sessionVersion) {
      throw new TransportError({
        cause: null,
        message: 'Authentication changed after this request. Retry with the current account.',
      });
    }
  };
  const transport = tokens
    ? withUnauthorizedRefresh({
        transport: options.transport,
        shouldRefresh: (request) => {
          versions.set(request, tokens.sessionVersion);
          return (
            request.headers.has('authorization') &&
            ![
              '/v2/auth/email',
              '/v2/auth/web/email',
              '/v2/auth/discord',
              '/v2/auth/web/discord',
              '/v2/auth/refresh',
              '/v2/auth/web/refresh',
            ].includes(new URL(request.url).pathname)
          );
        },
        refresh: async (request) => {
          assertSameSession(request);
          const rejected = request.headers.get('authorization')?.replace(/^Bearer\s+/i, '');
          if (rejected) await tokens.refreshAfterUnauthorized(rejected);
        },
        authorizeReplay: async (request, original) => {
          assertSameSession(original);
          const headers = new Headers(request.headers);
          const token = await tokens.getAccessToken();
          assertSameSession(original);
          const rejected = original.headers.get('authorization')?.replace(/^Bearer\s+/i, '');
          if (token !== null && (!rejected || !tokens.canReplayWithAccessToken(rejected, token))) {
            throw new TransportError({
              cause: null,
              message: 'The account for this request changed. Retry with the current account.',
            });
          }
          if (token === null) headers.delete('authorization');
          else headers.set('authorization', `Bearer ${token}`);
          return new Request(request, { headers });
        },
      })
    : options.transport;
  const authenticated = createApiClient({
    baseUrl: options.baseUrl,
    transport,
    ...(options.web ? { credentials: 'include' as const } : {}),
  });
  const publicClient = options.web
    ? createApiClient({
        baseUrl: options.baseUrl,
        transport: options.transport,
        credentials: 'omit',
      })
    : authenticated;
  // Public API responses use wildcard CORS, which browsers reject with cookies.
  // Auth endpoints are public contracts too, but must retain refresh/login cookies.
  const client = (endpoint: AnyEndpoint) =>
    endpoint.auth === 'public' && !endpoint.path.startsWith('/v2/auth/')
      ? publicClient
      : authenticated;
  return {
    execute: (endpoint, input, requestOptions) =>
      client(endpoint).execute(endpoint, input, requestOptions),
    executeStatus: (endpoint, input, requestOptions) =>
      client(endpoint).executeStatus(endpoint, input, requestOptions),
  };
}
