export type ApiEnvironment = 'production' | 'staging' | 'development' | 'local';

export interface ApiEnvironmentVariables {
  readonly CK_API_ENV?: string;
  readonly CK_API_BASE_URL?: string;
  readonly CK_API_V2_BASE_URL?: string;
  readonly CK_PROXY_BASE_URL?: string;
}

export interface ApiConfiguration {
  readonly environment: ApiEnvironment;
  readonly apiBaseUrl: string;
  readonly apiV2Url: string;
  readonly proxyUrl: string;
}

export const API_ASSET_URL = 'https://assets.clashk.ing';
export const COC_ASSET_PROXY_URL = 'https://assets-proxy.clashk.ing';
export const CDN_URL = 'https://cdn.clashk.ing';
export const DISCORD_URL = 'https://discord.gg/clashking';

export function apiEnvironmentForName(name: string | undefined): ApiEnvironment {
  switch ((name ?? 'prod').toLowerCase()) {
    case 'local':
      return 'local';
    case 'development':
      return 'development';
    case 'stage':
    case 'staging':
      return 'staging';
    case 'prod':
    case 'production':
    default:
      return 'production';
  }
}

export function defaultApiBaseUrl(environment: ApiEnvironment): string {
  switch (environment) {
    case 'local':
      return 'http://localhost:8000';
    case 'development':
    case 'staging':
      return 'https://dev-api.clashk.ing';
    case 'production':
      return 'https://api.clashk.ing/v2';
  }
}

export function defaultApiV2Url(environment: ApiEnvironment): string {
  if (environment === 'production') return 'https://api.clashk.ing/v2';
  return `${defaultApiBaseUrl(environment)}/v2`;
}

export function defaultProxyUrl(environment: ApiEnvironment): string {
  if (environment === 'production') return 'https://api.clashk.ing/proxy/v1';
  return `${defaultApiBaseUrl(environment)}/proxy/v1`;
}

export function resolveApiConfiguration(variables: ApiEnvironmentVariables = {}): ApiConfiguration {
  const environment = apiEnvironmentForName(variables.CK_API_ENV);
  const baseOverride = normalizeOverride(variables.CK_API_BASE_URL);
  const v2Override = normalizeOverride(variables.CK_API_V2_BASE_URL);
  const proxyOverride = normalizeOverride(variables.CK_PROXY_BASE_URL);
  const apiBaseUrl = baseOverride ?? defaultApiBaseUrl(environment);

  // Flutter intentionally lets CK_API_BASE_URL derive the local v2 URL only.
  // Other environments retain their canonical v2 host unless its dedicated
  // override is supplied.
  const apiV2Url =
    v2Override ??
    (environment === 'local' && baseOverride !== undefined
      ? `${apiBaseUrl}/v2`
      : defaultApiV2Url(environment));

  const proxyUrl =
    proxyOverride ??
    (environment === 'production' ? defaultProxyUrl(environment) : `${apiBaseUrl}/proxy/v1`);

  return { environment, apiBaseUrl, apiV2Url, proxyUrl };
}

function normalizeOverride(value: string | undefined): string | undefined {
  if (value === undefined || value.length === 0) return undefined;
  let normalized = value;
  while (normalized.endsWith('/')) normalized = normalized.slice(0, -1);
  return normalized;
}
