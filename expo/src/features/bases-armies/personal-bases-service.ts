import { expoEndpoints, type EndpointResponse } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../core/api/contract-api';

export type PersonalBasesState = EndpointResponse<typeof expoEndpoints.personalBases>;
export type PersonalBase = PersonalBasesState['items'][number];
export type PersonalBaseSlot = PersonalBasesState['slots'][number];
export type PersonalBaseSlotKind = PersonalBaseSlot['kind'];
export type PersonalBaseSlotNumber = 1 | 2 | 3;

export interface PersonalBasesServiceContract {
  load(): Promise<PersonalBasesState>;
  save(baseId: string): Promise<PersonalBasesState>;
  unsave(baseId: string): Promise<PersonalBasesState>;
  assign(
    playerTag: string,
    kind: PersonalBaseSlotKind,
    number: PersonalBaseSlotNumber,
    baseId: string,
  ): Promise<PersonalBasesState>;
  clear(
    playerTag: string,
    kind: PersonalBaseSlotKind,
    number: PersonalBaseSlotNumber,
  ): Promise<PersonalBasesState>;
}

export class PersonalBasesService implements PersonalBasesServiceContract {
  constructor(private readonly api: ContractApiService) {}

  load(): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.personalBases, { path: {}, query: {}, body: {} }),
    );
  }

  save(baseId: string): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.savePersonalBase, {
        path: { baseId },
        query: {},
        body: {},
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

  assign(
    playerTag: string,
    kind: PersonalBaseSlotKind,
    number: PersonalBaseSlotNumber,
    baseId: string,
  ): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.assignPersonalBaseSlot, {
        path: { playerTag, kind, number: String(number) as '1' | '2' | '3' },
        query: {},
        body: { baseId },
      }),
    );
  }

  clear(
    playerTag: string,
    kind: PersonalBaseSlotKind,
    number: PersonalBaseSlotNumber,
  ): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.clearPersonalBaseSlot, {
        path: { playerTag, kind, number: String(number) as '1' | '2' | '3' },
        query: {},
        body: {},
      }),
    );
  }
}
