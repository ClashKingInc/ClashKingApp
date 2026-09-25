import { expoEndpoints } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../core/api/contract-api';
import { PersonalBasesService, personalBaseImageUrl, type PersonalBasesState } from './personal-bases-service';

const state: PersonalBasesState = { items: [] };

function setup() {
  const execute = jest.fn(() => Effect.succeed(state)) as unknown as jest.MockedFunction<
    ContractApiService['execute']
  >;
  const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
  return { execute, service: new PersonalBasesService({ execute, executeStatus }, 'https://local-api.clashk.ing/v2') };
}

test('resolves canonical base media against the configured API without rewriting external assets', () => {
  expect(personalBaseImageUrl('https://api.clashk.ing/v2/media/base.png', 'https://local-api.clashk.ing/v2')).toBe('https://local-api.clashk.ing/v2/media/base.png');
  expect(personalBaseImageUrl('https://api.clashk.ing/v2/media/base.png', 'http://192.168.1.2:8787/v2')).toBe('http://192.168.1.2:8787/v2/media/base.png');
  for (const url of ['https://assets.clashk.ing/base.png', 'https://example.com/v2/media/base.png', 'invalid']) {
    expect(personalBaseImageUrl(url, 'https://local-api.clashk.ing/v2')).toBe(url);
  }
});

test('loads the authenticated personal base library', async () => {
  const { execute, service } = setup();
  await expect(service.load()).resolves.toEqual(state);
  expect(execute).toHaveBeenCalledWith(expoEndpoints.personalBases, {
    path: {},
    query: {},
    body: {},
  });
});

test('saves and unsaves canonical shared bases using decimal string IDs', async () => {
  const { execute, service } = setup();
  await service.save('9223372036854775807');
  expect(execute).toHaveBeenLastCalledWith(expoEndpoints.savePersonalBase, {
    path: { baseId: '9223372036854775807' },
    query: {},
    body: {},
  });
  await service.unsave('9223372036854775807');
  expect(execute).toHaveBeenLastCalledWith(expoEndpoints.unsavePersonalBase, {
    path: { baseId: '9223372036854775807' },
    query: {},
    body: {},
  });
});

test('cleans up saved bases older than 90 days through the fixed endpoint', async () => {
  const { execute, service } = setup();
  await service.deleteOld();
  expect(execute).toHaveBeenLastCalledWith(expoEndpoints.deleteOldPersonalBases, {
    path: {},
    query: {},
    body: {},
  });
});
