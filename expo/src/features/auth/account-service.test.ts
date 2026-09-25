import { createContractTestApi, readContractRequest } from '../../core/api/contract-api.testing';
import type { StringStore } from '../../services/storage/auth-storage';
import { AccountHttpException, CocAccountService } from './account-service';
import { ResponseDecodeError } from '@clashking/api-client';

class MemoryPreferences implements StringStore {
  readonly values = new Map<string, string>();

  async getItem(key: string) {
    return this.values.get(key) ?? null;
  }

  async setItem(key: string, value: string) {
    this.values.set(key, value);
  }

  async removeItem(key: string) {
    this.values.delete(key);
  }
}

type Request = { path: string; method: string; body: unknown };

function deferred<T>() {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((done) => {
    resolve = done;
  });
  return { promise, resolve };
}

function harness(
  responder: (request: Request) => Response | Promise<Response>,
  reportError = jest.fn(),
) {
  const requests: Request[] = [];
  const api = createContractTestApi({
    baseUrl: 'https://api.example/v2',
    environment: 'production',
    tokenProvider: { getAccessToken: async () => 'access' },
    fetchImplementation: jest.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const parsed = await readContractRequest(input, init);
      const url = parsed.url;
      const body = parsed.init.body ? JSON.parse(String(parsed.init.body)) : undefined;
      const request = {
        path: `${url.pathname}${url.search}`,
        method: parsed.init.method!,
        body,
      };
      requests.push(request);
      return responder(request);
    }) as typeof fetch,
  });
  const preferences = new MemoryPreferences();
  const service = new CocAccountService(api, preferences, reportError);
  service.setCurrentUserId(' user/id ');
  return { service, preferences, requests, reportError };
}

function account(playerTag: string, overrides: Record<string, unknown> = {}) {
  return {
    player_tag: playerTag,
    tag: playerTag,
    user_id: 'user/id',
    order_index: 0,
    added_at: '2026-01-01T00:00:00Z',
    last_login: null,
    hidden: false,
    is_verified: false,
    name: `Player ${playerTag}`,
    townHallLevel: 17,
    ...overrides,
  };
}

describe('CocAccountService', () => {
  test('initializes selection itself or delegates the full bootstrap to its coordinator', async () => {
    const { service, preferences, requests } = harness(
      () => new Response(JSON.stringify({ items: [account('#FIRST')] })),
    );
    await service.initializeForCurrentUser('user/id');
    expect(service.userId).toBe('user/id');
    expect(service.selectedTag).toBe('#FIRST');
    expect(preferences.values.get('selectedTag')).toBe('#FIRST');
    expect(requests[0]?.path).toBe('/v2/links/user%2Fid');

    const coordinator = jest.fn(async () => undefined);
    service.setBootstrapCoordinator(coordinator);
    await service.initializeForCurrentUser(null);
    expect(coordinator).toHaveBeenCalledWith(null);
    expect(requests).toHaveLength(1);
  });

  test('replaces a stored selection that is no longer linked', async () => {
    const { service, preferences } = harness(
      () => new Response(JSON.stringify({ items: [account('#FIRST'), account('#SECOND')] })),
    );
    await preferences.setItem('selectedTag', '#REMOVED');

    await service.initializeForCurrentUser('user/id');

    expect(service.selectedTag).toBe('#FIRST');
    expect(preferences.values.get('selectedTag')).toBe('#FIRST');
  });

  test('reconciles the selection when a refreshed link list removes it', async () => {
    let items = [account('#ONE'), account('#TWO')];
    const { service, preferences } = harness(() => new Response(JSON.stringify({ items })));
    await service.fetchAccounts();
    await service.setSelectedTag('#ONE');
    items = [account('#TWO')];

    await service.fetchAccounts();

    expect(service.selectedTag).toBe('#TWO');
    expect(preferences.values.get('selectedTag')).toBe('#TWO');
  });

  test('does not let an older empty response overwrite a newer verified account response', async () => {
    const older = deferred<Response>();
    const newer = deferred<Response>();
    let getCount = 0;
    const { service } = harness(() => {
      getCount += 1;
      return getCount === 1 ? older.promise : newer.promise;
    });

    const olderLoad = service.fetchAccounts();
    const newerLoad = service.fetchAccounts();
    newer.resolve(
      new Response(
        JSON.stringify({
          items: [account('#GCPVU8CCG', { is_verified: true, townHallLevel: 18 })],
        }),
      ),
    );
    await newerLoad;
    older.resolve(new Response(JSON.stringify({ items: [] })));
    await olderLoad;

    expect(service.verifiedAccounts).toEqual([
      expect.objectContaining({ playerTag: '#GCPVU8CCG', isVerified: true }),
    ]);
  });

  test('does not apply a prior-user response after the current session changes', async () => {
    const oldUserResponse = deferred<Response>();
    const { service } = harness(() => oldUserResponse.promise);

    const oldUserLoad = service.fetchAccounts();
    service.setCurrentUserId('new-user');
    oldUserResponse.resolve(
      new Response(JSON.stringify({ items: [account('#OLD-USER-ACCOUNT')] })),
    );
    await oldUserLoad;

    expect(service.userId).toBe('new-user');
    expect(service.accounts).toEqual([]);
  });

  test('does not let an obsolete fetch resurrect an account removed by a newer mutation', async () => {
    const obsolete = deferred<Response>();
    let getCount = 0;
    const { service } = harness(({ method }) => {
      if (method === 'DELETE') return new Response(JSON.stringify({ message: 'Removed' }));
      getCount += 1;
      if (getCount === 1) {
        return new Response(
          JSON.stringify({
            items: [
              account('#LOW'),
              account('#GCPVU8CCG', { is_verified: true, townHallLevel: 18 }),
            ],
          }),
        );
      }
      return obsolete.promise;
    });
    await service.fetchAccounts();

    const staleLoad = service.fetchAccounts();
    await expect(service.removeAccount('#LOW')).resolves.toBe(true);
    obsolete.resolve(
      new Response(
        JSON.stringify({
          items: [
            account('#LOW'),
            account('#GCPVU8CCG', { is_verified: true, townHallLevel: 18 }),
          ],
        }),
      ),
    );
    await staleLoad;

    expect(service.accounts.map((item) => item.playerTag)).toEqual(['#GCPVU8CCG']);
  });

  test('requires a token on every account-link request and reports conflicts', async () => {
    const { service, requests, reportError } = harness(({ body }) => {
      const requestBody = body as Record<string, unknown>;
      if (requestBody.player_tag === '#ERROR') {
        return new Response(
          JSON.stringify({
            code: 'conflict',
            message: 'Already linked',
            account: {
              tag: '#ERROR',
              name: 'Player #ERROR',
              townHallLevel: 17,
              is_verified: false,
              hidden: false,
            },
          }),
          { status: 409 },
        );
      }
      return new Response(
        JSON.stringify({
          message: 'Linked',
          account: account(String(requestBody.player_tag), {
            is_verified: requestBody.api_token !== undefined,
          }),
        }),
      );
    });

    await expect(service.addAccount('#ONE', 'token-one')).resolves.toMatchObject({
      code: 200,
      account: { playerTag: '#ONE', isVerified: true },
    });
    await expect(service.addAccountWithVerification('#TWO', 'token-two')).resolves.toMatchObject({
      code: 200,
      account: { playerTag: '#TWO', isVerified: true },
    });
    await expect(service.addAccount('#ERROR', 'token-error')).resolves.toMatchObject({
      code: 409,
      message: 'Already linked',
      account: null,
    });
    expect(service.accounts.map(({ playerTag }) => playerTag)).toEqual(['#ONE', '#TWO']);
    expect(requests.map(({ body }) => body)).toEqual([
      { player_tag: '#ONE', api_token: 'token-one' },
      { player_tag: '#TWO', api_token: 'token-two' },
      { player_tag: '#ERROR', api_token: 'token-error' },
    ]);
    expect(reportError).toHaveBeenCalledWith('coc_account.add', expect.any(AccountHttpException));
  });

  test('adds with a token, refreshes links, and uses returned profile metadata', async () => {
    let postComplete = false;
    const { service, requests } = harness(({ method }) => {
      if (method === 'POST') {
        postComplete = true;
        return new Response(
          JSON.stringify({
            message: 'Linked',
            account: account('#ONE', { name: 'Fresh Name', townHallLevel: 18 }),
          }),
        );
      }
      expect(postComplete).toBe(true);
      return new Response(
        JSON.stringify({
          items: [account('#ONE', { name: 'Cached Name', townHallLevel: 17 })],
        }),
      );
    });

    await expect(service.addAccountWithToken('#ONE', 'token')).resolves.toEqual({
      success: true,
      message: null,
    });
    expect(requests.find(({ method }) => method === 'POST')?.body).toEqual({
      player_tag: '#ONE',
      api_token: 'token',
    });
    expect(service.accounts[0]?.raw).toMatchObject({
      name: 'Fresh Name',
      townHallLevel: 18,
    });
  });

  test.each([
    [403, 'Invalid API token for this account'],
    [404, 'Account not found'],
    [500, 'Failed to add account. Please try again.'],
  ])('maps add-with-token HTTP %i to a stable message', async (status, message) => {
    const { service } = harness(
      () =>
        new Response(
          JSON.stringify({
            code: status === 403 ? 'forbidden' : status === 404 ? 'not_found' : 'internal_error',
            message: 'Error',
          }),
          { status },
        ),
    );
    await expect(service.addAccountWithToken('#ONE', 'token')).resolves.toEqual({
      success: false,
      message,
    });
  });

  test('does not expose decoder internals when the post-verification list is malformed', async () => {
    const { service, reportError } = harness(
      ({ method }) =>
        new Response(
          JSON.stringify(
            method === 'POST'
              ? { message: 'Linked', account: account('#ONE', { is_verified: true }) }
              : { items: [{ ...account('#ONE'), last_login: undefined }] },
          ),
        ),
    );
    await expect(service.addAccountWithToken('#ONE', 'token')).resolves.toEqual({
      success: false,
      message: 'Failed to add account. Please try again.',
    });
    expect(reportError).toHaveBeenCalledWith('accounts.fetch', expect.any(ResponseDecodeError));
  });

  test('refreshes a newly verified account with no last-login timestamp', async () => {
    const { service } = harness(
      ({ method }) =>
        new Response(
          JSON.stringify(
            method === 'POST'
              ? { message: 'Linked', account: account('#ONE', { is_verified: true }) }
              : {
                  items: [
                    {
                      user_id: 'user/id',
                      player_tag: '#ONE',
                      order_index: 0,
                      is_verified: true,
                      hidden: false,
                      added_at: '2026-09-05T00:00:00Z',
                      verified_at: '2026-09-05T00:00:00Z',
                      last_login: null,
                    },
                  ],
                },
          ),
        ),
    );
    await expect(service.addAccountWithToken('#ONE', 'token')).resolves.toEqual({
      success: true,
      message: null,
    });
    expect(service.accounts[0]?.isVerified).toBe(true);
  });

  test('verifies, hides, reorders, removes, and persists selection through successful mutations', async () => {
    const { service, preferences, requests } = harness(({ method }) => {
      if (method === 'GET') {
        return new Response(
          JSON.stringify({ items: [account('#ONE'), account('#TWO'), account('#THREE')] }),
        );
      }
      if (method === 'POST')
        return new Response(JSON.stringify({ message: 'Linked', account: account('#ONE') }));
      if (method === 'PATCH')
        return new Response(JSON.stringify(account('#TWO', { hidden: true })));
      return new Response('{"message":"ok"}');
    });
    await service.fetchAccounts();
    const listener = jest.fn();
    service.subscribe(listener);

    await expect(service.verifyAccount('#ONE', 'token')).resolves.toEqual({
      success: true,
      message: null,
    });
    await service.updateAccountHidden('#TWO', true);
    await expect(service.updateAccountOrder(['#three', '#ONE'])).resolves.toBe(true);
    await service.setSelectedTag('#THREE');
    await expect(service.removeAccount('#ONE')).resolves.toBe(true);

    expect(service.accounts.map(({ playerTag }) => playerTag)).toEqual(['#THREE', '#TWO']);
    expect(service.accounts.find(({ playerTag }) => playerTag === '#TWO')?.hidden).toBe(true);
    expect(preferences.values.get('selectedTag')).toBe('#THREE');
    await service.setSelectedTag(null);
    expect(preferences.values.has('selectedTag')).toBe(false);
    expect(requests.map(({ method }) => method)).toEqual(['GET', 'POST', 'PATCH', 'PUT', 'DELETE']);
    expect(listener).toHaveBeenCalledTimes(6);
  });

  test('selects the next linked account and updates dependents after removing the selection', async () => {
    const { service, preferences } = harness(({ method }) =>
      method === 'GET'
        ? new Response(JSON.stringify({ items: [account('#ONE'), account('#TWO')] }))
        : new Response('{"message":"ok"}'),
    );
    const selectionChanged = jest.fn(async () => undefined);
    service.setSelectedTagChangeHandler(selectionChanged);
    await service.fetchAccounts();
    await service.setSelectedTag('#ONE');
    selectionChanged.mockClear();

    await expect(service.removeAccount('#ONE')).resolves.toBe(true);

    expect(service.selectedTag).toBe('#TWO');
    expect(preferences.values.get('selectedTag')).toBe('#TWO');
    expect(selectionChanged).toHaveBeenCalledWith('#TWO');
  });

  test('clears the selection and updates dependents after removing the final account', async () => {
    const { service, preferences } = harness(({ method }) =>
      method === 'GET'
        ? new Response(JSON.stringify({ items: [account('#ONLY')] }))
        : new Response('{"message":"ok"}'),
    );
    const selectionChanged = jest.fn(async () => undefined);
    service.setSelectedTagChangeHandler(selectionChanged);
    await service.fetchAccounts();
    selectionChanged.mockClear();

    await expect(service.removeAccount('#ONLY')).resolves.toBe(true);

    expect(service.selectedTag).toBeNull();
    expect(preferences.values.has('selectedTag')).toBe(false);
    expect(selectionChanged).toHaveBeenCalledWith(null);
  });

  test('reconciles an already-absent stale link without removing the remaining verified account', async () => {
    let getCount = 0;
    const { service, requests, reportError } = harness(({ method }) => {
      if (method === 'GET') {
        getCount += 1;
        return new Response(
          JSON.stringify({
            items:
              getCount === 1
                ? [account('#LOW'), account('#GCPVU8CCG', { is_verified: true, townHallLevel: 18 })]
                : [account('#GCPVU8CCG', { is_verified: true, townHallLevel: 18 })],
          }),
        );
      }
      return new Response(JSON.stringify({ message: 'Link not found' }), { status: 404 });
    });
    await service.fetchAccounts();

    await expect(service.removeAccount('#LOW')).resolves.toBe(true);

    expect(service.accounts.map((item) => item.playerTag)).toEqual(['#GCPVU8CCG']);
    expect(service.verifiedAccounts.map((item) => item.playerTag)).toEqual(['#GCPVU8CCG']);
    expect(requests.map(({ method }) => method)).toEqual(['GET', 'DELETE', 'GET']);
    expect(reportError).not.toHaveBeenCalledWith('accounts.remove', expect.anything());
  });

  test('does not claim a failed removal succeeded or discard local links for arbitrary errors', async () => {
    const { service, requests } = harness(({ method }) =>
      method === 'GET'
        ? new Response(JSON.stringify({ items: [account('#LOW'), account('#GCPVU8CCG')] }))
        : new Response(JSON.stringify({ message: 'Unavailable' }), { status: 503 }),
    );
    await service.fetchAccounts();

    await expect(service.removeAccount('#LOW')).resolves.toBe(false);

    expect(service.accounts.map((item) => item.playerTag)).toEqual(['#LOW', '#GCPVU8CCG']);
    expect(requests.map(({ method }) => method)).toEqual(['GET', 'DELETE']);
  });

  test('normalizes an empty user id and reports authentication and malformed payload failures', async () => {
    const { service, reportError } = harness(() => new Response('{}'));
    service.setCurrentUserId('   ');
    await expect(service.fetchAccounts()).rejects.toThrow('User not authenticated');
    await expect(service.addAccount('#ONE', 'token')).resolves.toEqual({
      code: 401,
      message: 'User not authenticated',
      account: null,
    });
    expect(reportError).toHaveBeenCalledWith('accounts.fetch', expect.any(Error));
    expect(reportError).toHaveBeenCalledTimes(1);

    service.setCurrentUserId('user');
    await expect(service.fetchAccounts()).rejects.toBeInstanceOf(ResponseDecodeError);
    expect(reportError).toHaveBeenLastCalledWith('accounts.fetch', expect.any(ResponseDecodeError));
  });

  test('maps verification errors without reporting expected authentication failures', async () => {
    const { service, reportError } = harness(
      () => new Response('{"code":"forbidden","message":"Invalid token"}', { status: 403 }),
    );
    await expect(service.verifyAccount('#ONE', 'bad')).resolves.toEqual({
      success: false,
      message: 'Invalid API token for this account',
    });

    service.setCurrentUserId(null);
    await expect(service.verifyAccount('#ONE', 'bad')).resolves.toEqual({
      success: false,
      message: 'User not authenticated',
    });
    expect(reportError).not.toHaveBeenCalled();
  });
});
