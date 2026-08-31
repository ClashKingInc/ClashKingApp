import { ApiClient } from '../../core/api/client';
import type { StringStore } from '../../services/storage/auth-storage';
import { AccountHttpException, CocAccountService } from './account-service';

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

function harness(
  responder: (request: Request) => Response | Promise<Response>,
  reportError = jest.fn(),
) {
  const requests: Request[] = [];
  const api = new ApiClient({
    baseUrl: 'https://api.example/v2',
    environment: 'production',
    tokenProvider: { getAccessToken: async () => 'access' },
    fetchImplementation: jest.fn(async (input: RequestInfo | URL, init?: RequestInit) => {
      const url = new URL(String(input));
      const body = init?.body ? JSON.parse(String(init.body)) : undefined;
      const request = {
        path: `${url.pathname}${url.search}`,
        method: init?.method ?? 'GET',
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

  test('adds accounts with and without verification and preserves detail error accounts', async () => {
    const { service, requests, reportError } = harness(({ body }) => {
      const requestBody = body as Record<string, unknown>;
      if (requestBody.player_tag === '#ERROR') {
        return new Response(
          JSON.stringify({
            detail: {
              message: 'Already linked',
              account: account('#ERROR', { is_verified: true }),
            },
          }),
          { status: 409 },
        );
      }
      return new Response(
        JSON.stringify({
          account: account(String(requestBody.player_tag), {
            is_verified: requestBody.api_token !== undefined,
          }),
        }),
      );
    });

    await expect(service.addAccount('#ONE')).resolves.toMatchObject({
      code: 200,
      account: { playerTag: '#ONE', isVerified: false },
    });
    await expect(service.addAccountWithVerification('#TWO', 'token')).resolves.toMatchObject({
      code: 200,
      account: { playerTag: '#TWO', isVerified: true },
    });
    await expect(service.addAccountWithVerification('#ERROR', 'token')).resolves.toEqual({
      code: 409,
      message: 'Already linked',
      account: null,
    });
    expect(service.accounts.map(({ playerTag }) => playerTag)).toEqual(['#ONE', '#TWO']);
    expect(requests[0]?.body).toEqual({ player_tag: '#ONE' });
    expect(requests[1]?.body).toEqual({ player_tag: '#TWO', api_token: 'token' });
    expect(reportError).toHaveBeenCalledWith('coc_account.add', expect.any(AccountHttpException));
  });

  test('adds with a token, refreshes links, and uses returned profile metadata', async () => {
    let postComplete = false;
    const { service } = harness(({ method }) => {
      if (method === 'POST') {
        postComplete = true;
        return new Response(
          JSON.stringify({
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
    const { service } = harness(() => new Response('{}', { status }));
    await expect(service.addAccountWithToken('#ONE', 'token')).resolves.toEqual({
      success: false,
      message,
    });
  });

  test('verifies, hides, reorders, removes, and persists selection through successful mutations', async () => {
    const { service, preferences, requests } = harness(({ method }) => {
      if (method === 'GET') {
        return new Response(
          JSON.stringify({ items: [account('#ONE'), account('#TWO'), account('#THREE')] }),
        );
      }
      return new Response('{}');
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

  test('normalizes an empty user id and reports authentication and malformed payload failures', async () => {
    const { service, reportError } = harness(() => new Response('{}'));
    service.setCurrentUserId('   ');
    await expect(service.fetchAccounts()).rejects.toThrow('User not authenticated');
    await expect(service.addAccount('#ONE')).resolves.toEqual({
      code: 401,
      message: 'User not authenticated',
      account: null,
    });
    expect(reportError).toHaveBeenCalledWith('accounts.fetch', expect.any(Error));
    expect(reportError).toHaveBeenCalledTimes(1);

    service.setCurrentUserId('user');
    await expect(service.fetchAccounts()).rejects.toThrow('Invalid CoC accounts payload');
    expect(reportError).toHaveBeenLastCalledWith('accounts.fetch', expect.any(TypeError));
  });

  test('maps verification errors without reporting expected authentication failures', async () => {
    const { service, reportError } = harness(() => new Response('{}', { status: 403 }));
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
