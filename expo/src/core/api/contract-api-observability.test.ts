import { ApiResponseError, ResponseDecodeError } from '@clashking/api-client';
import { AppConfigEndpoint } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import { observedTransport, withApiDiagnostics } from './contract-api-observability';
import type { ContractApiService } from './contract-api';

describe('shared API observability', () => {
  it('records transport metadata without reading or cloning response bodies', async () => {
    const response = new Response('download', { headers: { 'content-length': '8' } });
    const text = jest.spyOn(response, 'text');
    const clone = jest.spyOn(response, 'clone');
    const addHttpBreadcrumb = jest.fn();
    const transport = observedTransport(
      { execute: () => Effect.succeed(response) },
      { addHttpBreadcrumb },
    );
    const result = await Effect.runPromise(
      transport.execute(new Request('https://api.test/v2/download')),
    );
    expect(result).toBe(response);
    expect(text).not.toHaveBeenCalled();
    expect(clone).not.toHaveBeenCalled();
    expect(addHttpBreadcrumb).toHaveBeenCalledWith(
      expect.objectContaining({ method: 'GET', statusCode: 200, responseBodySize: 8 }),
    );
  });

  it('omits unknown body size instead of fabricating a zero-byte response', async () => {
    const addHttpBreadcrumb = jest.fn();
    const transport = observedTransport(
      { execute: () => Effect.succeed(new Response('body')) },
      { addHttpBreadcrumb },
    );
    await Effect.runPromise(transport.execute(new Request('https://api.test/v2/example')));
    expect(addHttpBreadcrumb.mock.calls[0]?.[0]).not.toHaveProperty('responseBodySize');
  });

  it('reports only the endpoint template and preserves the original typed failure', async () => {
    const failure = new ApiResponseError({ status: 500, body: { token: 'secret-token' } });
    const execute = jest.fn(() => Effect.fail(failure)) as unknown as ContractApiService['execute'];
    const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
    const reportException = jest.fn();
    const client = withApiDiagnostics({ execute, executeStatus }, { reportException });
    await expect(
      Effect.runPromise(client.execute(AppConfigEndpoint, { path: {}, query: {}, body: {} })),
    ).rejects.toBe(failure);
    expect(reportException).toHaveBeenCalledWith(expect.any(Error), 'GET /v2/app/config', failure);
    const diagnostic = reportException.mock.calls[0]?.[0] as Error;
    expect(diagnostic.name).toBe('ApiResponseError');
    expect(diagnostic.message).toContain('500');
    expect(diagnostic.message).not.toContain('secret-token');
    expect(diagnostic.cause).toBeUndefined();
  });
  it('logs decode paths without leaking response values and preserves the failure', async () => {
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => {});
    try {
      const failure = new ResponseDecodeError({
        operationId: 'appConfig',
        cause: {
          _tag: 'SchemaError',
          issue: {
            _tag: 'Pointer',
            path: ['field'],
            issue: {
              _tag: 'InvalidType',
              actual: 'secret-token',
            },
          },
        },
      });
      const execute = jest.fn(() =>
        Effect.fail(failure),
      ) as unknown as ContractApiService['execute'];
      const client = withApiDiagnostics(
        { execute, executeStatus: jest.fn() as unknown as ContractApiService['executeStatus'] },
        { reportException: jest.fn() },
      );
      await expect(
        Effect.runPromise(client.execute(AppConfigEndpoint, { path: {}, query: {}, body: {} })),
      ).rejects.toBe(failure);
      const log = JSON.stringify(warn.mock.calls);
      expect(log).toContain('GET /v2/app/config');
      expect(log).toContain('field');
      expect(log).toContain('InvalidType');
      expect(log).not.toContain('secret-token');
    } finally {
      warn.mockRestore();
    }
  });
});
