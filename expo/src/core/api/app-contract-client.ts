import { createApiClient, type ApiTransport } from '@clashking/api-client';
import type { AnyEndpoint } from '@clashking/api-contracts/expo';

import type { ContractApiService } from './contract-api';

export function createAppContractClient(options: {
  baseUrl: string;
  transport: ApiTransport;
  web: boolean;
}): ContractApiService {
  const authenticated = createApiClient({
    baseUrl: options.baseUrl,
    transport: options.transport,
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
