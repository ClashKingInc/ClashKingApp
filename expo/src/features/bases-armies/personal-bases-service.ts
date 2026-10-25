import { expoEndpoints, type EndpointResponse } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';

import type { ContractApiService } from '../../core/api/contract-api';

export type PersonalBasesState = EndpointResponse<typeof expoEndpoints.personalBases>;
export type PersonalBase = PersonalBasesState['items'][number];

/** Stored media URLs are canonical; fetch their bytes from the active API environment. */
export function personalBaseImageUrl(imageUrl: string, apiV2Url: string): string {
  try {
    const image = new URL(imageUrl);
    if (image.origin !== 'https://api.clashk.ing' || !image.pathname.startsWith('/v2/media/')) return imageUrl;
    const target = new URL(apiV2Url);
    return new URL(`${image.pathname}${image.search}${image.hash}`, target.origin).toString();
  } catch {
    return imageUrl;
  }
}

export interface PersonalBasesServiceContract {
  load(): Promise<PersonalBasesState>;
  save(baseId: string): Promise<PersonalBasesState>;
  unsave(baseId: string): Promise<PersonalBasesState>;
  deleteOld(): Promise<PersonalBasesState>;
}

export class PersonalBasesService implements PersonalBasesServiceContract {
  constructor(private readonly api: ContractApiService, private readonly apiV2Url: string) {}

  private resolveImages = (state: PersonalBasesState): PersonalBasesState => ({
    ...state,
    items: state.items.map(base => ({ ...base, images: base.images.map(image => personalBaseImageUrl(image, this.apiV2Url)) })),
  });

  load(): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.personalBases, { path: {}, query: {}, body: {} }),
    ).then(this.resolveImages);
  }

  save(baseId: string): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.savePersonalBase, {
        path: { baseId },
        query: {},
        body: {},
      }),
    ).then(this.resolveImages);
  }

  unsave(baseId: string): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.unsavePersonalBase, {
        path: { baseId },
        query: {},
        body: {},
      }),
    ).then(this.resolveImages);
  }

  deleteOld(): Promise<PersonalBasesState> {
    return Effect.runPromise(
      this.api.execute(expoEndpoints.deleteOldPersonalBases, {
        path: {},
        query: {},
        body: {},
      }),
    ).then(this.resolveImages);
  }
}
