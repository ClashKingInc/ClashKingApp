import type { ApiClient } from '../../core/api/client';
import {
  clanSearchQuerySuffix,
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

const ALL_HTTP_STATUSES = Array.from({ length: 500 }, (_, index) => index + 100);

export class SearchService {
  constructor(private readonly api: ApiClient) {}

  async loadRecents(userId: string | null): Promise<readonly RecentSearchItem[]> {
    if (!userId) return [];
    try {
      const response = await this.api.get(`/links/${encodeURIComponent(userId)}/searches`, {
        requiresAuth: true,
        acceptedStatuses: ALL_HTTP_STATUSES,
      });
      if (response.status !== 200) return [];
      return decodeRecentSearches(JSON.parse(response.bodyText));
    } catch {
      return [];
    }
  }

  async searchClans(query: string, filters: ClanSearchFilters): Promise<readonly JsonRecord[]> {
    const endpoint = `/clans?name=${encodeURIComponent(query)}${clanSearchQuerySuffix(filters)}&limit=20&memberList=false`;
    const response = await this.api.proxyGet(endpoint, {
      timeoutMs: 10_000,
      acceptedStatuses: ALL_HTTP_STATUSES,
    });
    if (response.status !== 200) return [];
    const decoded: unknown = JSON.parse(response.bodyText);
    return isRecord(decoded) && Array.isArray(decoded.items) ? decoded.items.filter(isRecord) : [];
  }

  /** Mirrors SearchPage's direct official-proxy fallback when clan enrichment fails. */
  async loadClanFallback(
    tag: string,
    extraHeaders?: Readonly<Record<string, string>>,
  ): Promise<JsonRecord> {
    const response = await this.api.proxyGet(`/clans/${encodeURIComponent(tag)}`, {
      headers: extraHeaders,
      timeoutMs: 10_000,
    });
    const decoded: unknown = JSON.parse(response.bodyText);
    if (!isRecord(decoded)) throw new TypeError('Invalid clan response');
    return decoded;
  }

  async loadLocations(): Promise<readonly SearchLocation[]> {
    try {
      const response = await this.api.proxyGet('/locations');
      return decodeSearchLocations(JSON.parse(response.bodyText));
    } catch {
      return [];
    }
  }

  async loadLeagues(): Promise<readonly SearchLeague[]> {
    try {
      const response = await this.api.proxyGet('/leaguetiers');
      return decodeSearchLeagues(JSON.parse(response.bodyText));
    } catch {
      return [];
    }
  }
}
