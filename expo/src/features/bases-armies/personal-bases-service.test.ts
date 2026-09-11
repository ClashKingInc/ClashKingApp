import { expoEndpoints } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../core/api/contract-api';
import { PersonalBasesService, type PersonalBasesState } from './personal-bases-service';

const state: PersonalBasesState = { items: [], slots: [] };

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

test('assigns and clears bounded account slots', async () => {
  const { execute, service } = setup();
  await service.assign('#P0Y', 'legend', 3, '42');
  expect(execute).toHaveBeenLastCalledWith(expoEndpoints.assignPersonalBaseSlot, {
    path: { playerTag: '#P0Y', kind: 'legend', number: '3' },
    query: {},
    body: { baseId: '42' },
  });
  await service.clear('#P0Y', 'legend', 3);
  expect(execute).toHaveBeenLastCalledWith(expoEndpoints.clearPersonalBaseSlot, {
    path: { playerTag: '#P0Y', kind: 'legend', number: '3' },
    query: {},
    body: {},
  });
});
