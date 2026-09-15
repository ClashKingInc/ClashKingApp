import { expoEndpoints } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../core/api/contract-api';
import { PersonalBasesService, type PersonalBasesState } from './personal-bases-service';

const state: PersonalBasesState = { items: [] };

function setup() {
  const execute = jest.fn(() => Effect.succeed(state)) as unknown as jest.MockedFunction<
    ContractApiService['execute']
  >;
  const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
  return { execute, service: new PersonalBasesService({ execute, executeStatus }) };
}

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
  await service.save('9223372036854775807', 'legend');
  expect(execute).toHaveBeenLastCalledWith(expoEndpoints.savePersonalBase, {
    path: { baseId: '9223372036854775807' },
    query: {},
    body: { kind: 'legend' },
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
