import { expoEndpoints, type EndpointResponse } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../core/api/contract-api';

export type PersonalArmiesState = EndpointResponse<typeof expoEndpoints.personalArmies>;
export type PersonalArmy = PersonalArmiesState['items'][number];

export interface PersonalArmiesServiceContract {
  load(): Promise<PersonalArmiesState>;
  save(shareCode: string): Promise<PersonalArmiesState>;
  remove(shareCode: string): Promise<PersonalArmiesState>;
}

export class PersonalArmiesService implements PersonalArmiesServiceContract {
  constructor(private readonly api: ContractApiService) {}

  load(): Promise<PersonalArmiesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.personalArmies, { path: {}, query: {}, body: {} }),
    );
  }

  save(shareCode: string): Promise<PersonalArmiesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.savePersonalArmy, {
        path: { shareCode },
        query: {},
        body: {},
      }),
    );
  }

  remove(shareCode: string): Promise<PersonalArmiesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.deletePersonalArmy, {
        path: { shareCode },
        query: {},
        body: {},
      }),
    );
  }
}
