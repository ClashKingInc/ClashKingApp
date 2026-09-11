import { AppConfigEndpoint } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import { withBearerToken, type ContractApiService } from './contract-api';

describe('contract API authentication', () => {
  it('does not load a token for public endpoints', async () => {
    const getAccessToken = jest.fn(async () => 'token');
    const execute = jest.fn(() => Effect.succeed({})) as unknown as ContractApiService['execute'];
    const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
    const client = withBearerToken({ execute, executeStatus }, { getAccessToken });

    await Effect.runPromise(client.execute(AppConfigEndpoint, { path: {}, query: {}, body: {} }));

    expect(getAccessToken).not.toHaveBeenCalled();
    expect(execute).toHaveBeenCalledWith(
      AppConfigEndpoint,
      { path: {}, query: {}, body: {} },
      { timeoutMs: 15_000 },
    );
  });

  it('injects the current bearer token into protected endpoint effects', async () => {
    const protectedEndpoint = { ...AppConfigEndpoint, auth: 'user' as const };
    const execute = jest.fn(() => Effect.succeed({})) as unknown as ContractApiService['execute'];
    const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
    const client = withBearerToken(
      { execute, executeStatus },
      { getAccessToken: async () => 'current-token' },
    );

    await Effect.runPromise(client.execute(protectedEndpoint, { path: {}, query: {}, body: {} }));

    expect(execute).toHaveBeenCalledWith(
      protectedEndpoint,
      { path: {}, query: {}, body: {} },
      { timeoutMs: 15_000, auth: { bearerToken: 'current-token' } },
    );
  });
});
