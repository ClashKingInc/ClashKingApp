import { expoEndpoints } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../core/api/contract-api';
import { PersonalArmiesService, type PersonalArmiesState } from './personal-armies-service';

const state: PersonalArmiesState = { items: [] };

function setup() {
  const execute = jest.fn(() => Effect.succeed(state)) as unknown as jest.MockedFunction<
    ContractApiService['execute']
  >;
  const executeStatus = jest.fn() as unknown as ContractApiService['executeStatus'];
  return { execute, service: new PersonalArmiesService({ execute, executeStatus }) };
}

test('loads, saves, and removes personal armies by canonical share code', async () => {
  const { execute, service } = setup();
  await service.load();
  expect(execute).toHaveBeenLastCalledWith(expoEndpoints.personalArmies, {
    path: {},
    query: {},
    body: {},
  });

  await service.save('u1x0');
  expect(execute).toHaveBeenLastCalledWith(expoEndpoints.savePersonalArmy, {
    path: { shareCode: 'u1x0' },
    query: {},
    body: {},
  });

  await service.remove('u1x0');
  expect(execute).toHaveBeenLastCalledWith(expoEndpoints.deletePersonalArmy, {
    path: { shareCode: 'u1x0' },
    query: {},
    body: {},
  });
});
