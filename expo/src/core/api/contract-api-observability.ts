import { classifyClashResponse } from '@clashking/clash-contract/outcomes';
import {
  ApiResponseError,
  type ApiClientError,
  type ApiTransport,
  type ApiStatusResult,
} from '@clashking/api-client';
import type { AnyEndpoint } from '@clashking/api-contracts/expo';
import { Effect, Schedule } from 'effect';

import type { HttpBreadcrumbInput } from '../observability/observability';
import {
  classifyNetworkFailure,
  type RequestDiagnostics,
} from '../observability/request-diagnostics';

import type { ContractApiService, AppExecuteOptions } from './contract-api';

const transportFailures = new WeakMap<object, RequestDiagnostics>();

interface ApiObservability {
  addHttpBreadcrumb(input: HttpBreadcrumbInput): void;
  reportException(
    error: unknown,
    operation: string,
    dedupeKey?: unknown,
    diagnostics?: RequestDiagnostics,
  ): void;
  isOffline?(): Promise<boolean>;
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
          Effect.tapError((error) =>
            Effect.sync(() => {
              transportFailures.set(error, {
                request_stage: 'transport',
                // Fetch may reject with AbortError even when our deadline fired.
                ...classifyNetworkFailure(request.signal.aborted ? request.signal.reason : error),
                request_duration_ms: Math.min(300_000, Math.max(0, Date.now() - startedAt)),
              });
            }),
          ),
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
  observability: Pick<ApiObservability, 'reportException' | 'isOffline'>,
): ContractApiService {
  const report = (endpoint: AnyEndpoint, error: ApiClientError, options?: AppExecuteOptions) =>
    Effect.promise(async () => {
      if (options?.signal?.aborted) return;
      if (error._tag === 'ApiResponseError' && options?.expectedStatuses?.includes(error.status))
        return;
      if (error._tag === 'TransportError' && (await observability.isOffline?.().catch(() => false)))
        return;
      // Endpoint templates contain no account IDs, query values, tokens, or bodies.
      const operation = `${endpoint.method} ${endpoint.path}`;
      const diagnostic = new Error(
        error._tag === 'ApiResponseError'
          ? `API request failed with status ${error.status} for ${endpoint.path}.`
          : `API request failed for ${endpoint.path}.`,
      );
      if (__DEV__ && error._tag === 'ResponseDecodeError') {
        console.warn(
          '[API decode failure]',
          operation,
          JSON.stringify(decodeIssueDetails(error.cause)),
        );
      }
      if (__DEV__ && error._tag === 'ApiResponseError' && error.status >= 500) {
        console.warn('[API failure]', operation, error.status, error.requestId ?? '');
      }
      diagnostic.name = error._tag;
      const details: RequestDiagnostics =
        transportFailures.get(error) ??
        (error._tag === 'ApiResponseError'
          ? { request_stage: 'http_response', http_status: error.status }
          : error._tag === 'ResponseDecodeError'
            ? { request_stage: 'response_decode' }
            : error._tag === 'RequestBuildError'
              ? { request_stage: 'request_build' }
              : { request_stage: 'unknown', ...classifyNetworkFailure(error) });
      observability.reportException(diagnostic, operation, error, details);
    });
  const retry = <A>(
    effect: Effect.Effect<A, ApiClientError>,
    endpoint: AnyEndpoint,
    options?: AppExecuteOptions,
  ) =>
    endpoint.method === 'GET' && options?.retryTransientRead !== false
      ? effect.pipe(
          Effect.retry({
            times: 1,
            schedule: Schedule.exponential('500 millis'),
            while: (error) =>
              !options?.signal?.aborted &&
              (error._tag === 'TransportError' ||
                (error._tag === 'ApiResponseError' &&
                  [502, 503, 504].includes(error.status) &&
                  classifyClashResponse({
                    path: endpoint.path,
                    status: error.status,
                    body: error.body,
                  }).retryable)),
          }),
        )
      : effect;
  return {
    execute: (endpoint, input, options) =>
      retry(client.execute(endpoint, input, options), endpoint, options).pipe(
        Effect.tapError((error) => report(endpoint, error, options)),
      ),
    executeStatus: (endpoint, input, options) => {
      const failures = new WeakMap<ApiResponseError, ApiStatusResult<typeof endpoint>>();
      // Declared 5xx results must cross the same retry/report boundary as
      // thrown failures. Restore their original status result only afterwards.
      const observed = client.executeStatus(endpoint, input, options).pipe(
        Effect.flatMap((result) => {
          if ('body' in result && !result.ok && result.status >= 500) {
            const error = new ApiResponseError(result);
            failures.set(error, result);
            return Effect.fail(error);
          }
          return Effect.succeed(result);
        }),
      );
      return retry(observed, endpoint, options).pipe(
        Effect.tapError((error) => report(endpoint, error, options)),
        Effect.catch((error) => {
          const result = error._tag === 'ApiResponseError' ? failures.get(error) : undefined;
          return result === undefined ? Effect.fail(error) : Effect.succeed(result);
        }),
      );
    },
  };
}

// Keep field paths and issue kinds, but never log response values or request credentials.
function decodeIssueDetails(cause: unknown, depth = 0): unknown {
  if (!cause || typeof cause !== 'object' || depth > 12) return { kind: 'Unknown' };
  const issue = cause as Record<string, unknown>;
  return {
    kind:
      typeof issue._tag === 'string' ? issue._tag : cause instanceof Error ? cause.name : 'Unknown',
    ...(Array.isArray(issue.path) ? { path: issue.path.map(String) } : {}),
    ...(issue.issue ? { issue: decodeIssueDetails(issue.issue, depth + 1) } : {}),
    ...(Array.isArray(issue.issues)
      ? { issues: issue.issues.map((child) => decodeIssueDetails(child, depth + 1)) }
      : {}),
  };
}
