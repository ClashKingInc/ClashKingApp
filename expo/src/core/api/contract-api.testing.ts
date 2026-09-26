import { createApiClient, httpTransport } from '@clashking/api-client';

import { withBearerToken, type ApiEnvironment, type ContractApiService } from './contract-api';

export interface ContractTestApiOptions {
  readonly baseUrl: string;
  readonly environment?: ApiEnvironment;
  readonly proxyUrl?: string;
  readonly fetchImplementation?: typeof fetch;
  readonly platform?: 'web' | 'native';
  readonly tokenProvider?: { getAccessToken(): Promise<string | null> };
}

export function createContractTestApi(options: ContractTestApiOptions): ContractApiService {
  const baseUrl = options.baseUrl.replace(/\/(?:v2|proxy\/v1)\/?$/, '');
  const client = createApiClient({
    baseUrl,
    transport: httpTransport(options.fetchImplementation),
    ...(options.platform === 'web' ? { credentials: 'include' as const } : {}),
  });
  return options.tokenProvider === undefined
    ? client
    : withBearerToken(client, options.tokenProvider);
}

export async function readContractRequest(input: RequestInfo | URL, init?: RequestInit) {
  const request = new Request(input, init);
  const body = await request.clone().text();
  return {
    url: new URL(request.url),
    init: {
      method: request.method,
      headers: Object.fromEntries(request.headers.entries()),
      ...(body.length === 0 ? {} : { body }),
    } satisfies RequestInit,
  };
}
