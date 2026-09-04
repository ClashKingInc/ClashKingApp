import type { ApiClientError, ApiTransport } from '@clashking/api-client';
import type { AnyEndpoint } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { HttpBreadcrumbInput } from '../observability/observability';
import type { ContractApiService } from './contract-api';

interface ApiObservability {
  addHttpBreadcrumb(input: HttpBreadcrumbInput): void;
  reportException(error: unknown, operation: string, dedupeKey?: unknown): void;
}

/** Preserve HTTP diagnostics without cloning or consuming streamed downloads. */
export function observedTransport(
  transport: ApiTransport,
  observability: Pick<ApiObservability, 'addHttpBreadcrumb'>,
): ApiTransport {
  return {
    execute: (request) =>
      Effect.suspend(() => {
        const startedAt = Date.now();
        return transport.execute(request).pipe(
          Effect.tap((response) =>
            Effect.sync(() => {
              const length = response.headers.get('content-length');
              const size = length === null ? undefined : Number(length);
              observability.addHttpBreadcrumb({
                url: response.url || request.url,
                method: request.method,
                statusCode: response.status,
                durationMs: Date.now() - startedAt,
                ...(size !== undefined && Number.isSafeInteger(size) && size >= 0
                  ? { responseBodySize: size }
                  : {}),
              });
            }),
          ),
        );
      }),
  };
}

export function withApiDiagnostics(
  client: ContractApiService,
  observability: Pick<ApiObservability, 'reportException'>,
): ContractApiService {
  const report = (endpoint: AnyEndpoint, error: ApiClientError) =>
    Effect.sync(() => {
      // Endpoint templates contain no account IDs, query values, tokens, or bodies.
      const operation = `${endpoint.method} ${endpoint.path}`;
      const diagnostic = new Error(
        error._tag === 'ApiResponseError'
          ? `API request failed with status ${error.status} for ${endpoint.path}.`
          : `API request failed for ${endpoint.path}.`,
      );
      diagnostic.name = error._tag;
      observability.reportException(diagnostic, operation, error);
    });
  return {
    execute: (endpoint, input, options) =>
      client
        .execute(endpoint, input, options)
        .pipe(Effect.tapError((error) => report(endpoint, error))),
    executeStatus: (endpoint, input, options) =>
      client
        .executeStatus(endpoint, input, options)
        .pipe(Effect.tapError((error) => report(endpoint, error))),
  };
}
