import { RecentSearchesEndpoint } from '@clashking/api-contracts/expo';
import {
  ProxyClanEndpoint,
  ProxyClanSearchEndpoint,
  ProxyLeagueTiersEndpoint,
  ProxyLocationsEndpoint,
} from '../../core/api/proxy-contracts';
import { Effect, Schema } from 'effect';

import type { ContractApiService } from '../../core/api/contract-api';
import {
  decodeRecentSearches,
  decodeSearchLeagues,
  decodeSearchLocations,
  isRecord,
  type ClanSearchFilters,
  type JsonRecord,
  type RecentSearchItem,
  type SearchLeague,
  type SearchLocation,
} from './models';
import { SEARCH_PAGE_SIZE, type SearchPage } from './search-state';

// The released endpoint already decodes paging.cursors. Extend its query to
// accept the forward cursor from the Clash clan search contract.
const paginatedClanSearchEndpoint = {
  ...ProxyClanSearchEndpoint,
  query: Schema.Struct({
    ...ProxyClanSearchEndpoint.query.fields,
    after: Schema.optionalKey(Schema.String),
  }),
};

export class SearchService {
  constructor(private readonly api: ContractApiService) {}

  async loadRecents(userId: string | null): Promise<readonly RecentSearchItem[]> {
    if (!userId) return [];
    try {
      return decodeRecentSearches(
        await Effect.runPromise(
          this.api.execute(RecentSearchesEndpoint, { path: { userId }, query: {}, body: {} }),
        ),
      );
    } catch {
      return [];
    }
  }

  async searchClans(
    query: string,
    filters: ClanSearchFilters,
    after: string | null,
  ): Promise<SearchPage> {
    const request = this.api.execute(
      paginatedClanSearchEndpoint,
      {
        path: {},
        body: {},
        query: {
          name: query,
          limit: SEARCH_PAGE_SIZE,
          memberList: false,
          ...(after === null ? {} : { after }),
          ...(filters.warFrequency === null ? {} : { warFrequency: filters.warFrequency }),
          ...(filters.locationId === null ? {} : { locationId: filters.locationId }),
          ...(filters.minMembers === null ? {} : { minMembers: filters.minMembers }),
          ...(filters.maxMembers === null ? {} : { maxMembers: filters.maxMembers }),
          ...(filters.minClanLevel === null ? {} : { minClanLevel: filters.minClanLevel }),
        },
      },
      { timeoutMs: 10_000, expectedStatuses: after === null ? undefined : [400] },
    );
    const result = await Effect.runPromise(Effect.result(request));
    if (result._tag === 'Failure') throw result.failure;
    return {
      results: result.success.items,
      nextCursor: result.success.paging?.cursors?.after || null,
    };
  }

  async loadClanByTag(
    tag: string,
    extraHeaders?: Readonly<Record<string, string>>,
  ): Promise<JsonRecord> {
    const result = await Effect.runPromise(
      Effect.result(
        this.api.execute(
          ProxyClanEndpoint,
          { path: { clanTag: tag }, query: {}, body: {} },
          { headers: extraHeaders, timeoutMs: 10_000, expectedStatuses: [404] },
        ),
      ),
    );
    if (result._tag === 'Failure') throw result.failure;
    if (!isRecord(result.success)) throw new TypeError('Invalid clan response');
    return result.success;
  }

  async loadLocations(): Promise<readonly SearchLocation[]> {
    const decoded = await Effect.runPromise(
      this.api.execute(
        ProxyLocationsEndpoint,
        { path: {}, query: {}, body: {} },
        { timeoutMs: 10_000 },
      ),
    );
    return decodeSearchLocations(decoded);
  }

  async loadLeagues(): Promise<readonly SearchLeague[]> {
    const decoded = await Effect.runPromise(
      this.api.execute(
        ProxyLeagueTiersEndpoint,
        { path: {}, query: {}, body: {} },
        { timeoutMs: 10_000 },
      ),
    );
    return decodeSearchLeagues(decoded);
  }
}
