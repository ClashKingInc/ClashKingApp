import { expoEndpoints, type EndpointResponse } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../core/api/contract-api';

export type PersonalBasesState = EndpointResponse<typeof expoEndpoints.personalBases>;
export type PersonalBase = PersonalBasesState['items'][number];
export type PersonalBaseKind = NonNullable<PersonalBase['kind']>;

export interface PersonalBasesServiceContract {
  load(): Promise<PersonalBasesState>;
  save(baseId: string, kind: PersonalBaseKind | null): Promise<PersonalBasesState>;
  unsave(baseId: string): Promise<PersonalBasesState>;
  deleteOld(): Promise<PersonalBasesState>;
}

export class PersonalBasesService implements PersonalBasesServiceContract {
  constructor(private readonly api: ContractApiService) {}

  load(): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.personalBases, { path: {}, query: {}, body: {} }),
    );
  }

  save(baseId: string, kind: PersonalBaseKind | null): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.savePersonalBase, {
        path: { baseId },
        query: {},
        body: { kind },
      }),
    );
  }

  unsave(baseId: string): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.unsavePersonalBase, {
        path: { baseId },
        query: {},
        body: {},
      }),
    );
  }

  deleteOld(): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.deleteOldPersonalBases, {
        path: {},
        query: {},
        body: {},
      }),
    );
  }
}
