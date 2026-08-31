import { ApiClient, NotFoundException } from './client';

describe('ApiClient observability', () => {
  it('records response breadcrumbs and reports failures with a sanitized operation', async () => {
    const addHttpBreadcrumb = jest.fn();
    const reportException = jest.fn();
    const api = new ApiClient({
      baseUrl: 'https://api.test',
      environment: 'production',
      fetchImplementation: jest.fn(
        async () => new Response('{"detail":"missing"}', { status: 404 }),
      ) as typeof fetch,
      observability: { addHttpBreadcrumb, reportException },
    });

    await expect(api.get('/links/42?token=secret')).rejects.toBeInstanceOf(NotFoundException);
    expect(addHttpBreadcrumb).toHaveBeenCalledWith(
      expect.objectContaining({ method: 'GET', statusCode: 404 }),
    );
    expect(reportException).toHaveBeenCalledWith(
      expect.objectContaining({
        message: 'API request failed with status 404 for /links/:user_id.',
        name: 'NotFoundException',
      }),
      'GET /links/:user_id',
      expect.any(NotFoundException),
    );
    const captured = reportException.mock.calls[0]?.[0] as Error;
    expect(captured.message).not.toContain('42');
    expect(captured.message).not.toContain('secret');
    expect(captured.message).not.toContain('missing');
    expect(reportException).toHaveBeenCalledTimes(1);
  });

  it('reports response decoding failures through the same exception boundary', async () => {
    const reportException = jest.fn();
    const api = new ApiClient({
      baseUrl: 'https://api.test',
      environment: 'production',
      fetchImplementation: jest.fn(
        async () => new Response('not-json', { status: 200 }),
      ) as typeof fetch,
      observability: { addHttpBreadcrumb: jest.fn(), reportException },
    });

    await expect(api.requestRecord('/player')).rejects.toThrow('Invalid JSON response');
    expect(reportException).toHaveBeenCalledWith(
      expect.objectContaining({ message: 'API request failed for /player.' }),
      'GET /player',
      expect.any(Error),
    );
  });

  it('keeps a server detail on the thrown user-facing error but never captures it', async () => {
    const reportException = jest.fn();
    const api = new ApiClient({
      baseUrl: 'https://api.test',
      environment: 'production',
      fetchImplementation: jest.fn(
        async () => new Response('{"detail":"private backend detail"}', { status: 400 }),
      ) as typeof fetch,
      observability: { addHttpBreadcrumb: jest.fn(), reportException },
    });

    await expect(api.get('/links/42?token=secret')).rejects.toThrow('private backend detail');
    const captured = reportException.mock.calls[0]?.[0] as Error;
    expect(captured.message).toBe('API request failed with status 400 for /links/:user_id.');
    expect(captured.message).not.toContain('private backend detail');
    expect(captured.message).not.toContain('secret');
  });
});
