export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE' | 'QUERY';
export type ApiEnvironment = 'production' | 'staging' | 'development' | 'local';

export class ApiException extends Error {
  readonly status?: number;

  constructor(message: string, status?: number) {
    super(message);
    this.status = status;
    this.name = new.target.name;
  }
}

export class BadRequestException extends ApiException {}
export class UnauthorizedException extends ApiException {}
export class ForbiddenException extends ApiException {}
export class NotFoundException extends ApiException {}
export class RateLimitException extends ApiException {}
export class ServerException extends ApiException {}
export class EmailVerificationRequiredException extends ApiException {}
export class ResponseFormatException extends ApiException {}
export class RequestTimeoutException extends ApiException {}

export interface TokenProvider {
  getAccessToken(): Promise<string | null>;
}

export interface ApiObservability {
  addHttpBreadcrumb(input: {
    url: string;
    method: string;
    statusCode: number;
    durationMs: number;
    responseBodySize: number;
  }): void;
  reportException(error: unknown, operation: string, dedupeKey?: unknown): void;
}

export interface ApiClientOptions {
  readonly baseUrl: string;
  readonly proxyUrl?: string;
  readonly environment: ApiEnvironment;
  readonly tokenProvider?: TokenProvider;
  readonly fetchImplementation?: typeof fetch;
  readonly platform?: 'web' | 'native';
  readonly defaultTimeoutMs?: number;
  readonly observability?: ApiObservability;
}

export interface ApiRequestOptions {
  readonly method?: HttpMethod;
  readonly body?: unknown;
  readonly requiresAuth?: boolean;
  readonly url?: string;
  readonly timeoutMs?: number;
  readonly headers?: Readonly<Record<string, string>>;
  /** Flutter's map helpers accept 200/201; endpoints must opt into 204/404. */
  readonly acceptedStatuses?: readonly number[];
}

export interface ApiResponse {
  readonly status: number;
  readonly headers: Headers;
  readonly bodyText: string;
  readonly url: string;
}

export class ApiClient {
  private readonly options: ApiClientOptions;
  private readonly fetchImplementation: typeof fetch;
  private readonly defaultTimeoutMs: number;

  constructor(options: ApiClientOptions) {
    this.options = options;
    this.fetchImplementation = options.fetchImplementation ?? fetch;
    this.defaultTimeoutMs = options.defaultTimeoutMs ?? 15_000;
  }

  get(endpoint: string, options: Omit<ApiRequestOptions, 'method'> = {}) {
    return this.request(endpoint, { ...options, method: 'GET' });
  }

  post(endpoint: string, options: Omit<ApiRequestOptions, 'method'> = {}) {
    return this.request(endpoint, { ...options, method: 'POST' });
  }

  put(endpoint: string, options: Omit<ApiRequestOptions, 'method'> = {}) {
    return this.request(endpoint, { ...options, method: 'PUT' });
  }

  patch(endpoint: string, options: Omit<ApiRequestOptions, 'method'> = {}) {
    return this.request(endpoint, { ...options, method: 'PATCH' });
  }

  delete(endpoint: string, options: Omit<ApiRequestOptions, 'method'> = {}) {
    return this.request(endpoint, { ...options, method: 'DELETE' });
  }

  /** Sends an RFC 9110 QUERY request with a JSON body; there is no POST alias. */
  query(endpoint: string, options: Omit<ApiRequestOptions, 'method'> = {}) {
    return this.request(endpoint, { ...options, method: 'QUERY' });
  }

  proxyGet(
    pathAndQuery: string,
    options: Omit<ApiRequestOptions, 'method' | 'url' | 'requiresAuth'> = {},
  ) {
    if (this.options.proxyUrl === undefined) {
      throw new TypeError('ApiClient proxyUrl is required for proxy requests.');
    }
    const path = pathAndQuery.startsWith('/') ? pathAndQuery : `/${pathAndQuery}`;
    return this.request(path, {
      ...options,
      method: 'GET',
      url: joinUrl(this.options.proxyUrl, path),
      requiresAuth: true,
    });
  }

  async request(endpoint: string, requestOptions: ApiRequestOptions = {}): Promise<ApiResponse> {
    const method = requestOptions.method ?? 'GET';
    const url = requestOptions.url ?? joinUrl(this.options.baseUrl, endpoint);
    const controller = new AbortController();
    const timeoutMs = requestOptions.timeoutMs ?? this.defaultTimeoutMs;
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    const startedAt = Date.now();
    const operation = `${method} ${sanitizedOperationTarget(endpoint)}`;

    try {
      const headers = await this.buildHeaders(requestOptions);
      const response = await this.fetchImplementation(url, {
        method,
        headers,
        body: method === 'GET' ? undefined : encodeBody(requestOptions.body),
        credentials: this.options.platform === 'web' ? 'include' : undefined,
        signal: controller.signal,
      });
      const bodyText = await response.text();
      this.options.observability?.addHttpBreadcrumb({
        url: response.url || url,
        method,
        statusCode: response.status,
        durationMs: Date.now() - startedAt,
        responseBodySize: new TextEncoder().encode(bodyText).byteLength,
      });
      const acceptedStatuses = requestOptions.acceptedStatuses ?? [200, 201];
      if (!acceptedStatuses.includes(response.status)) {
        throw errorForResponse(response.status, endpoint, bodyText);
      }
      return {
        status: response.status,
        headers: response.headers,
        bodyText,
        url: response.url || url,
      };
    } catch (error) {
      if (controller.signal.aborted) {
        const timeout = new RequestTimeoutException('Request timeout.');
        this.reportApiException(timeout, operation, endpoint);
        throw timeout;
      }
      this.reportApiException(error, operation, endpoint);
      throw error;
    } finally {
      clearTimeout(timer);
    }
  }

  async requestJson<T>(
    endpoint: string,
    requestOptions: ApiRequestOptions = {},
    decode?: (value: unknown) => T,
  ): Promise<T> {
    const response = await this.request(endpoint, requestOptions);
    try {
      let parsed: unknown;
      try {
        parsed = JSON.parse(response.bodyText);
      } catch {
        throw new ResponseFormatException(`Invalid JSON response for ${endpoint}.`);
      }
      return decode === undefined ? (parsed as T) : decode(parsed);
    } catch (error) {
      this.reportApiException(
        error,
        `${requestOptions.method ?? 'GET'} ${sanitizedOperationTarget(endpoint)}`,
        endpoint,
      );
      throw error;
    }
  }

  async requestRecord(
    endpoint: string,
    requestOptions: ApiRequestOptions = {},
  ): Promise<Record<string, unknown>> {
    return this.requestJson(endpoint, requestOptions, (value) => {
      if (!isRecord(value)) {
        throw new ResponseFormatException(`Invalid response type for ${endpoint}.`);
      }
      return value;
    });
  }

  private async buildHeaders(requestOptions: ApiRequestOptions): Promise<Record<string, string>> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };
    if (requestOptions.requiresAuth === true) {
      const token = await this.options.tokenProvider?.getAccessToken();
      if (token == null && this.options.environment !== 'local') {
        throw new UnauthorizedException('User is not authenticated.');
      }
      if (token != null) headers.Authorization = `Bearer ${token}`;
    }
    return { ...headers, ...requestOptions.headers };
  }

  private reportApiException(error: unknown, operation: string, endpoint: string): void {
    this.options.observability?.reportException(
      sanitizedApiDiagnostic(error, endpoint),
      operation,
      error,
    );
  }
}

function joinUrl(baseUrl: string, endpoint: string): string {
  const normalizedBase = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
  const normalizedEndpoint = endpoint.startsWith('/') ? endpoint : `/${endpoint}`;
  return `${normalizedBase}${normalizedEndpoint}`;
}

function sanitizedOperationTarget(endpoint: string): string {
  const path = endpoint.split(/[?#]/, 1)[0] ?? endpoint;
  return path.replace(/(\/links\/)[^/]+/g, '$1:user_id');
}

function sanitizedApiDiagnostic(error: unknown, endpoint: string): Error {
  const target = sanitizedOperationTarget(endpoint);
  const status = error instanceof ApiException ? error.status : undefined;
  const message =
    status === undefined
      ? `API request failed for ${target}.`
      : `API request failed with status ${status} for ${target}.`;
  const diagnostic = new Error(message);
  diagnostic.name = error instanceof Error ? error.name : 'ApiRequestError';
  return diagnostic;
}

function encodeBody(body: unknown): BodyInit | undefined {
  if (body === undefined || body === null) return undefined;
  return typeof body === 'string' ? body : JSON.stringify(body);
}

function errorForResponse(status: number, endpoint: string, responseBody: string): ApiException {
  switch (status) {
    case 400:
      return new BadRequestException(
        extractStringDetail(responseBody) ?? `Bad request for ${endpoint}.`,
        status,
      );
    case 401:
      return new UnauthorizedException(`Unauthorized request for ${endpoint}.`, status);
    case 403:
      return new ForbiddenException(`Forbidden request for ${endpoint}.`, status);
    case 404:
      return new NotFoundException(`Resource not found for ${endpoint}.`, status);
    case 409:
      return new EmailVerificationRequiredException('Email verification is required.', status);
    case 429:
      return new RateLimitException(`Rate limit exceeded for ${endpoint}.`, status);
    case 500:
    case 502:
    case 503:
    case 504:
      return new ServerException(`Server error ${status} for ${endpoint}.`, status);
    default:
      return new ApiException(`API error ${status}.`, status);
  }
}

function extractStringDetail(responseBody: string): string | undefined {
  try {
    const decoded: unknown = JSON.parse(responseBody);
    return isRecord(decoded) && typeof decoded.detail === 'string' ? decoded.detail : undefined;
  } catch {
    return undefined;
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
