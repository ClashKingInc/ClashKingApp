import { RecentSearchesEndpoint } from '@clashking/api-contracts/expo';
import {
  ProxyClanEndpoint,
  ProxyClanSearchEndpoint,
  ProxyLeagueTiersEndpoint,
  ProxyLocationsEndpoint,
} from '../../core/api/proxy-contracts';
import { Effect } from 'effect';

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

  async searchClans(query: string, filters: ClanSearchFilters): Promise<readonly JsonRecord[]> {
    const decoded = await Effect.runPromise(
      this.api.execute(
        ProxyClanSearchEndpoint,
        {
          path: {},
          body: {},
          query: {
            name: query,
            limit: 20,
            memberList: false,
            ...(filters.warFrequency === null ? {} : { warFrequency: filters.warFrequency }),
            ...(filters.locationId === null ? {} : { locationId: filters.locationId }),
            ...(filters.minMembers === null ? {} : { minMembers: filters.minMembers }),
            ...(filters.maxMembers === null ? {} : { maxMembers: filters.maxMembers }),
            ...(filters.minClanLevel === null ? {} : { minClanLevel: filters.minClanLevel }),
          },
        },
        { timeoutMs: 10_000 },
      ),
    );
    return decoded.items;
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
