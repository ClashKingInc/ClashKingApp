import type { AnyEndpoint, EndpointRequest, EndpointResponse } from '@clashking/api-contracts/expo';
import {
  TransportError,
  type ApiClientError,
  type ApiStatusResult,
  type ExecuteOptions,
} from '@clashking/api-client';
import { Effect } from 'effect';

export type ApiEnvironment = 'production' | 'development' | 'local';

export class UnauthorizedException extends Error {
  constructor(message = 'User is not authenticated.') {
    super(message);
    this.name = 'UnauthorizedException';
  }
}

export class EmailVerificationRequiredException extends Error {
  constructor(message = 'Email verification is required.') {
    super(message);
    this.name = 'EmailVerificationRequiredException';
  }
}

export interface AppExecuteOptions extends ExecuteOptions {
  /** Only call sites that handle these statuses as normal states opt out of reporting. */
  readonly expectedStatuses?: readonly number[];
  readonly retryTransientRead?: boolean;
}
export interface ContractApiService {
  readonly execute: <E extends AnyEndpoint>(
    endpoint: E,
    input: EndpointRequest<E>,
    options?: AppExecuteOptions,
  ) => Effect.Effect<EndpointResponse<E>, ApiClientError>;
  readonly executeStatus: <E extends AnyEndpoint>(
    endpoint: E,
    input: EndpointRequest<E>,
    options?: AppExecuteOptions,
  ) => Effect.Effect<ApiStatusResult<E>, ApiClientError>;
}

export function withBearerToken(
  client: ContractApiService,
  tokenProvider: { readonly sessionVersion?: number; getAccessToken(): Promise<string | null> },
): ContractApiService {
  const accessTokenForRequest = async () => {
    const version = tokenProvider.sessionVersion;
    const token = await tokenProvider.getAccessToken();
    if (version !== tokenProvider.sessionVersion) {
      throw new TransportError({
        cause: null,
        message:
          'Authentication changed while preparing this request. Retry with the current account.',
      });
    }
    return token;
  };
  return {
    execute: (endpoint, input, options) => {
      options = { timeoutMs: 15_000, ...options };
      if (endpoint.auth === 'public' || options?.auth?.bearerToken !== undefined) {
        return client.execute(endpoint, input, options);
      }
      return Effect.tryPromise({
        try: accessTokenForRequest,
        catch: (cause) =>
          new TransportError({ cause, message: 'ClashKing access-token lookup failed' }),
      }).pipe(
        Effect.flatMap((bearerToken) =>
          client.execute(endpoint, input, {
            ...options,
            ...(bearerToken === null ? {} : { auth: { ...options?.auth, bearerToken } }),
          }),
        ),
      );
    },
    executeStatus: (endpoint, input, options) => {
      options = { timeoutMs: 15_000, ...options };
      if (endpoint.auth === 'public' || options?.auth?.bearerToken !== undefined) {
        return client.executeStatus(endpoint, input, options);
      }
      return Effect.tryPromise({
        try: accessTokenForRequest,
        catch: (cause) =>
          new TransportError({ cause, message: 'ClashKing access-token lookup failed' }),
      }).pipe(
        Effect.flatMap((bearerToken) =>
          client.executeStatus(endpoint, input, {
            ...options,
            ...(bearerToken === null ? {} : { auth: { ...options?.auth, bearerToken } }),
          }),
        ),
      );
    },
  };
}
