import { ApiClient, ResponseFormatException } from '../../../core/api/client';
import { canonicalTag } from '../../../core/domain/tags';
import { mapWithConcurrencyLimit } from '../../../core/utils/bounded-concurrency';
import {
  CapitalHistoryItems,
  buildClanWarStatsFromWars,
  Clan,
  ClanJoinLeave,
  ClanLeaderboardHistory,
  ClanLeaderboardHistorySummary,
  ClanLegendHistory,
  ClanLegendHistorySummary,
  ClanMember,
  ClanProfileHistory,
  ClanRecords,
  ClanWarLog,
  ClanWarStats,
  ClanWarStatsFilter,
  CwlRankingHistoryEntry,
  analyzeWarLogs,
  clanLeaderboardApiValue,
  isRecord,
  record,
  records,
  string,
  type ClanLeaderboardTypeValue,
  type JsonRecord,
  type WarCwlLike,
} from '../models';

const ALL_HTTP_STATUSES = Array.from({ length: 500 }, (_, index) => index + 100);

export type ClanServiceListener = () => void;

export class ClanService {
  private readonly clanMap = new Map<string, Clan>();
  private loading = false;
  private disposed = false;
  private readonly listeners = new Set<ClanServiceListener>();
  private readonly officialClanLoads = new Map<string, Promise<Clan | null>>();
  private readonly memberLoads = new Map<string, Promise<ClanMember | null>>();

  fetchedClans: Clan[] = [];
  joinLeaveList: ClanJoinLeave[] = [];
  capitalHistory: CapitalHistoryItems[] = [];
  warLogList: ClanWarLog[] = [];
  warStatsList: ClanWarStats[] = [];

  constructor(private readonly api: ApiClient) {}

  get isLoading(): boolean {
    return this.loading;
  }

  get clans(): ReadonlyMap<string, Clan> {
    return this.clanMap;
  }

  subscribe(listener: ClanServiceListener): () => void {
    if (this.disposed) return () => undefined;
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  dispose(): void {
    this.disposed = true;
    this.listeners.clear();
  }

  notifyDataChanged(): void {
    this.notify();
  }

  getClanByTag(clanTag: string): Clan | null {
    return this.clanMap.get(canonicalTag(clanTag)) ?? null;
  }

  async loadAllClanData(
    clanTags: readonly string[],
    options: { notify?: boolean; throwOnError?: boolean } = {},
  ): Promise<void> {
    if (!clanTags.length) return;
    const notify = options.notify ?? true;
    const throwOnError = options.throwOnError ?? false;
    this.loading = true;
    if (notify) this.notify();
    try {
      const tags = uniqueCanonicalTags(clanTags);
      const results = await mapWithConcurrencyLimit(tags, (tag) =>
        this.fetchOfficialClan(tag, throwOnError),
      );
      this.fetchedClans = results.filter((clan): clan is Clan => clan !== null);
      for (const clan of this.fetchedClans) this.clanMap.set(clan.tag, clan);
    } catch (error) {
      if (throwOnError) throw error;
    } finally {
      this.loading = false;
      if (notify) this.notify();
    }
  }

  async loadClanData(
    clanTag: string,
    options: { extraHeaders?: Readonly<Record<string, string>> } = {},
  ): Promise<Clan> {
    const normalizedTag = canonicalTag(clanTag);
    const cached = this.clanMap.get(normalizedTag);
    if (cached && options.extraHeaders === undefined) return cached;
    this.loading = true;
    this.notify();
    try {
      const clan = await this.fetchOfficialClan(normalizedTag, true, options.extraHeaders);
      if (!clan) throw new Error('Failed to load clan data');
      this.clanMap.set(clan.tag, clan);
      return clan;
    } finally {
      this.loading = false;
      this.notify();
    }
  }

  async getClanAndWarData(
    clanTag: string,
    options: { extraHeaders?: Readonly<Record<string, string>> } = {},
  ): Promise<Clan> {
    const clan = await this.loadClanData(clanTag, options);
    await this.enrichMissingMemberData(clan);
    return this.clanMap.get(clan.tag)!;
  }

  async getCwlRankingHistory(clanTag: string): Promise<readonly CwlRankingHistoryEntry[]> {
    // Flutter intentionally sends the caller's tag verbatim for this endpoint.
    const data = await this.getRecord(`/cwl/${encodeURIComponent(clanTag)}/seasons?limit=100`);
    return records(data.items).map(CwlRankingHistoryEntry.fromJson);
  }

  async getClanLeaderboardHistory(
    clanTag: string,
    type: ClanLeaderboardTypeValue,
    options: { after?: Date; before?: Date } = {},
  ): Promise<ClanLeaderboardHistory> {
    let endpoint = `/clan/${encodedCanonicalTag(clanTag)}/history/leaderboards?type=${clanLeaderboardApiValue(type)}&limit=250`;
    endpoint += historyRangeQuery(options);
    return ClanLeaderboardHistory.fromJson(await this.getRecord(endpoint));
  }

  async getClanLeaderboardHistorySummary(
    clanTag: string,
    type: ClanLeaderboardTypeValue,
  ): Promise<ClanLeaderboardHistorySummary> {
    const endpoint = `/clan/${encodedCanonicalTag(clanTag)}/history/leaderboards/summary?type=${clanLeaderboardApiValue(type)}`;
    return ClanLeaderboardHistorySummary.fromJson(await this.getRecord(endpoint));
  }

  async getClanLegendHistory(
    clanTag: string,
    options: { after?: Date; before?: Date } = {},
  ): Promise<ClanLegendHistory> {
    let endpoint = `/clan/${encodedCanonicalTag(clanTag)}/history/legends?limit=250`;
    endpoint += historyRangeQuery(options);
    return ClanLegendHistory.fromJson(await this.getRecord(endpoint));
  }

  async getClanLegendHistorySummary(clanTag: string): Promise<ClanLegendHistorySummary> {
    return ClanLegendHistorySummary.fromJson(
      await this.getRecord(`/clan/${encodedCanonicalTag(clanTag)}/history/legends/summary?top=10`),
    );
  }

  async getClanRecords(clanTag: string): Promise<ClanRecords> {
    return ClanRecords.fromJson(
      await this.getRecord(`/clan/${encodedCanonicalTag(clanTag)}/records`),
    );
  }

  async getClanProfileHistory(clanTag: string): Promise<ClanProfileHistory> {
    return ClanProfileHistory.fromJson(
      await this.getRecord(`/clan/${encodedCanonicalTag(clanTag)}/history/changes?limit=500`),
    );
  }

  async loadJoinLeaveForClan(clan: Clan): Promise<void> {
    if (clan.joinLeave !== null) return;
    const results = await this.loadClanJoinLeaveData([clan.tag], { notify: false });
    const joinLeave = results.find((item) => item.clanTag === clan.tag);
    if (joinLeave) clan.linkJoinLeave(joinLeave);
  }

  async loadClanJoinLeaveData(
    clanTags: readonly string[],
    options: { notify?: boolean; throwOnError?: boolean } = {},
  ): Promise<readonly ClanJoinLeave[]> {
    if (!clanTags.length) return [];
    const notify = options.notify ?? true;
    const throwOnError = options.throwOnError ?? false;
    this.loading = true;
    if (notify) this.notify();
    try {
      const results = await Promise.all(clanTags.map((tag) => this.fetchSingleClanJoinLeave(tag)));
      this.joinLeaveList = results.filter((item): item is ClanJoinLeave => item !== null);
      return this.joinLeaveList;
    } catch (error) {
      if (throwOnError) throw error;
      return [];
    } finally {
      this.loading = false;
      if (notify) this.notify();
    }
  }

  async loadMoreJoinLeaveForClan(clan: Clan): Promise<boolean> {
    const current = clan.joinLeave;
    if (
      current === null ||
      !current.joinLeaveList.length ||
      current.joinLeaveList.length >= current.available
    )
      return false;
    const before = oneMicrosecondBefore(current.joinLeaveList.at(-1)!.time);
    const page = await this.fetchSingleClanJoinLeave(clan.tag, before);
    if (!page?.joinLeaveList.length) return false;
    clan.joinLeave = current.appendPage(page);
    this.notify();
    return true;
  }

  linkJoinLeaveToClans(): void {
    const byTag = new Map(this.joinLeaveList.map((item) => [item.clanTag, item]));
    for (const clan of this.clanMap.values()) {
      const joinLeave = byTag.get(clan.tag);
      if (joinLeave) clan.joinLeave = joinLeave;
    }
  }

  async loadCapitalData(
    clanTags: readonly string[],
    limit: number,
    options: { notify?: boolean; throwOnError?: boolean } = {},
  ): Promise<readonly CapitalHistoryItems[]> {
    if (!clanTags.length) return [];
    const notify = options.notify ?? true;
    const throwOnError = options.throwOnError ?? false;
    this.loading = true;
    if (notify) this.notify();
    try {
      const results = await Promise.all(
        clanTags.map(async (tag) => {
          const response = await this.api.proxyGet(
            `/clans/${encodeURIComponent(tag)}/capitalraidseasons?limit=${limit}`,
            { acceptedStatuses: ALL_HTTP_STATUSES },
          );
          if (response.status !== 200) {
            if (throwOnError) throw new Error(`Failed to load capital data (${response.status})`);
            return null;
          }
          const data = decodeRecord(response.bodyText, response.url);
          return Array.isArray(data.items)
            ? CapitalHistoryItems.fromJson({ history: data.items }, tag)
            : null;
        }),
      );
      this.capitalHistory = results.filter((item): item is CapitalHistoryItems => item !== null);
      return this.capitalHistory;
    } catch (error) {
      if (throwOnError) throw error;
      return [];
    } finally {
      this.loading = false;
      if (notify) this.notify();
    }
  }

  linkCapitalToClans(): void {
    const byTag = new Map(this.capitalHistory.map((item) => [item.clanTag, item]));
    for (const clan of this.clanMap.values())
      clan.clanCapitalRaid = byTag.get(clan.tag) ?? CapitalHistoryItems.empty();
  }

  async loadWarLogData(
    clanTags: readonly string[],
    options: { throwOnError?: boolean } = {},
  ): Promise<readonly ClanWarLog[]> {
    if (!clanTags.length) return [];
    try {
      const warLogs = await Promise.all(
        clanTags.map(async (tag) => {
          const normalized = canonicalTag(tag);
          const endpoint = `/clan/${encodeURIComponent(normalized)}/warlog?limit=50`;
          const response = await this.api.get(endpoint, { requiresAuth: true });
          const warLog = ClanWarLog.fromJson(decodeRecord(response.bodyText, endpoint), tag);
          warLog.warLogStats = analyzeWarLogs(warLog.items);
          return warLog;
        }),
      );
      this.warLogList = warLogs;
      return warLogs;
    } catch (error) {
      if (options.throwOnError ?? false) throw error;
      return [];
    }
  }

  linkWarLogToClans(): void {
    const byTag = new Map(this.warLogList.map((item) => [item.clanTag, item]));
    for (const clan of this.clanMap.values())
      clan.clanWarLog = byTag.get(clan.tag) ?? new ClanWarLog([], '');
  }

  async loadClanWarStatsData(
    clanTags: readonly string[],
    options: { throwOnError?: boolean } = {},
  ): Promise<readonly ClanWarStats[]> {
    if (!clanTags.length) return [];
    try {
      this.warStatsList = [
        ...(await mapWithConcurrencyLimit(uniqueCanonicalTags(clanTags), (tag) =>
          this.fetchClanWarStats(tag, new ClanWarStatsFilter({ limit: 50 })),
        )),
      ];
      return this.warStatsList;
    } catch (error) {
      if (options.throwOnError ?? false) throw error;
      return [];
    }
  }

  async loadClanWarStatsWithFilter(
    clanTag: string,
    filter: ClanWarStatsFilter,
  ): Promise<ClanWarStats | null> {
    return this.fetchClanWarStats(canonicalTag(clanTag), filter);
  }

  private async fetchClanWarStats(
    clanTag: string,
    filter: ClanWarStatsFilter,
  ): Promise<ClanWarStats> {
    const configuredTypes = filter.warTypes?.filter((type) => type !== 'all') ?? [];
    const types = configuredTypes.length
      ? configuredTypes
      : filter.warType !== 'all'
        ? [filter.warType]
        : ['random', 'cwl', 'friendly'];
    const responses = await Promise.all(
      types.map(async (type) => {
        const query = new URLSearchParams({
          type,
          limit: String(Math.min(500, Math.max(1, filter.limit))),
        });
        if (filter.startDate) query.set('time[after]', filter.startDate.toISOString());
        if (filter.endDate) query.set('time[before]', filter.endDate.toISOString());
        const data = await this.getRecord(
          `/clan/${encodeURIComponent(clanTag)}/wars?${query.toString()}`,
        );
        return records(data.items).map((war): JsonRecord => ({ ...war, type }));
      }),
    );
    const unique = new Map<string, JsonRecord>();
    for (const war of responses.flat()) {
      const key = `${string(war.endTime)}:${string(record(war.clan).tag)}:${string(record(war.opponent).tag)}`;
      unique.set(key, war);
    }
    const wars = [...unique.values()]
      .sort((left, right) => string(right.endTime).localeCompare(string(left.endTime)))
      .slice(0, filter.limit);
    return buildClanWarStatsFromWars(wars, clanTag, filter);
  }

  linkWarStatsToClans(): void {
    const byTag = new Map(this.warStatsList.map((item) => [item.clanTag, item]));
    for (const clan of this.clanMap.values())
      clan.clanWarStats = byTag.get(clan.tag) ?? ClanWarStats.empty();
  }

  linkWarsToClans(clans: readonly Clan[], warCwls: readonly WarCwlLike[]): void {
    const byTag = new Map(clans.map((clan) => [clan.tag, clan]));
    for (const warCwl of warCwls) {
      const clan = byTag.get(warCwl.tag);
      if (clan) clan.warCwl = warCwl;
    }
  }

  async processBulkClanData(
    clanData: JsonRecord,
    _clanTags: readonly string[],
    options: { notify?: boolean } = {},
  ): Promise<void> {
    const clanDetails = record(clanData.clan_details);
    for (const [key, value] of Object.entries(clanDetails)) {
      try {
        this.clanMap.set(key, Clan.fromJson(record(value)));
      } catch {
        // Flutter skips malformed entries and continues the bulk response.
      }
    }

    if (Array.isArray(clanData.capital_data)) {
      this.capitalHistory = records(clanData.capital_data)
        .map((item) => {
          const clanTag = string(item.clan_tag);
          if (!clanTag) return null;
          return CapitalHistoryItems.fromJson(
            { history: Array.isArray(item.history) ? item.history : [] },
            clanTag,
            isRecord(item.stats) ? item.stats : undefined,
          );
        })
        .filter((item): item is CapitalHistoryItems => item !== null);
    }

    if (Array.isArray(clanData.war_log_data)) {
      this.warLogList = records(clanData.war_log_data)
        .map((item) => {
          try {
            const warLog = ClanWarLog.fromJson(item, string(item.clan_tag));
            warLog.warLogStats = analyzeWarLogs(warLog.items);
            return warLog;
          } catch {
            return null;
          }
        })
        .filter((item): item is ClanWarLog => item !== null);
    }

    // war_data is intentionally owned and processed by the War/CWL service.
    if (Array.isArray(clanData.clan_war_stats))
      this.warStatsList = records(clanData.clan_war_stats).map(ClanWarStats.fromJson);
    if (options.notify ?? true) this.notify();
  }

  private async fetchOfficialClan(
    clanTag: string,
    throwOnError: boolean,
    extraHeaders?: Readonly<Record<string, string>>,
  ): Promise<Clan | null> {
    const normalized = canonicalTag(clanTag);
    const key = `${normalized}|${extraHeaders?.['x-ck-user-id'] ?? ''}`;
    const existing = this.officialClanLoads.get(key);
    if (existing) return existing;
    const load = this.fetchOfficialClanOnce(normalized, throwOnError, extraHeaders);
    this.officialClanLoads.set(key, load);
    try {
      return await load;
    } finally {
      if (this.officialClanLoads.get(key) === load) this.officialClanLoads.delete(key);
    }
  }

  private async fetchOfficialClanOnce(
    clanTag: string,
    throwOnError: boolean,
    extraHeaders?: Readonly<Record<string, string>>,
  ): Promise<Clan | null> {
    try {
      const response = await this.api.proxyGet(`/clans/${encodeURIComponent(clanTag)}`, {
        headers: extraHeaders,
        acceptedStatuses: ALL_HTTP_STATUSES,
      });
      if (response.status !== 200) {
        if (throwOnError) throw new Error(`Failed to load clan data (${response.status})`);
        return null;
      }
      return Clan.fromJson(decodeRecord(response.bodyText, response.url));
    } catch (error) {
      if (throwOnError) throw error;
      return null;
    }
  }

  private async enrichMissingMemberData(clan: Clan): Promise<void> {
    const missing = clan.memberList.filter(
      (member) => member.townHallLevel <= 0 || member.league.id === 0,
    );
    if (!missing.length) return;
    const unique = new Map(missing.map((member) => [canonicalTag(member.tag), member]));
    const enriched = await mapWithConcurrencyLimit(unique.values(), (member) =>
      this.fetchPublicMemberData(member),
    );
    const byTag = new Map(
      enriched
        .filter((member): member is ClanMember => member !== null)
        .map((member) => [canonicalTag(member.tag), member]),
    );
    for (let index = 0; index < clan.memberList.length; index += 1) {
      const current = clan.memberList[index]!;
      clan.memberList[index] = byTag.get(canonicalTag(current.tag)) ?? current;
    }
  }

  private async fetchPublicMemberData(member: ClanMember): Promise<ClanMember | null> {
    const normalized = canonicalTag(member.tag);
    const existing = this.memberLoads.get(normalized);
    if (existing) return existing;
    const load = this.fetchPublicMemberDataOnce(member, normalized);
    this.memberLoads.set(normalized, load);
    try {
      return await load;
    } finally {
      if (this.memberLoads.get(normalized) === load) this.memberLoads.delete(normalized);
    }
  }

  private async fetchPublicMemberDataOnce(
    member: ClanMember,
    normalizedTag: string,
  ): Promise<ClanMember | null> {
    try {
      const response = await this.api.proxyGet(`/players/${encodeURIComponent(normalizedTag)}`);
      const data = decodeRecord(response.bodyText, response.url);
      return ClanMember.fromJson({
        ...data,
        tag: normalizedTag,
        name: data.name ?? member.name,
        role: member.role,
        donations: data.donations ?? member.donations,
        donationsReceived: data.donationsReceived ?? member.donationsReceived,
        leagueTier: data.leagueTier ?? data.league,
        league: data.leagueTier ?? data.league,
        builderBaseLeague: data.builderBaseLeague,
      });
    } catch {
      return null;
    }
  }

  private async fetchSingleClanJoinLeave(
    tag: string,
    before?: string,
  ): Promise<ClanJoinLeave | null> {
    let endpoint = `/clan/${encodeURIComponent(tag)}/join-leave?limit=50`;
    if (before) endpoint += `&time%5Bbefore%5D=${encodeURIComponent(before)}`;
    try {
      const response = await this.api.get(endpoint, {
        requiresAuth: true,
        acceptedStatuses: ALL_HTTP_STATUSES,
      });
      if (response.status !== 200) return null;
      return ClanJoinLeave.fromJson({
        clan_tag: tag,
        ...decodeRecord(response.bodyText, response.url),
      });
    } catch {
      return null;
    }
  }

  private async getRecord(endpoint: string): Promise<JsonRecord> {
    const response = await this.api.get(endpoint);
    return decodeRecord(response.bodyText, response.url);
  }

  private notify(): void {
    if (this.disposed) return;
    for (const listener of this.listeners) listener();
  }
}

function uniqueCanonicalTags(tags: readonly string[]): string[] {
  return [...new Set(tags.map(canonicalTag).filter(Boolean))];
}

function encodedCanonicalTag(tag: string): string {
  return encodeURIComponent(canonicalTag(tag));
}

function historyRangeQuery(options: { after?: Date; before?: Date }): string {
  let query = '';
  if (options.after) query += `&time%5Bafter%5D=${encodeURIComponent(options.after.toISOString())}`;
  if (options.before)
    query += `&time%5Bbefore%5D=${encodeURIComponent(options.before.toISOString())}`;
  return query;
}

function oneMicrosecondBefore(date: Date): string {
  const priorMillisecond = new Date(date.getTime() - 1).toISOString();
  return priorMillisecond.replace(/\.(\d{3})Z$/, '.$1999Z');
}

function decodeRecord(bodyText: string, endpoint: string): JsonRecord {
  let value: unknown;
  try {
    value = JSON.parse(bodyText);
  } catch {
    throw new ResponseFormatException(`Invalid JSON response for ${endpoint}.`);
  }
  if (!isRecord(value)) throw new ResponseFormatException(`Invalid response type for ${endpoint}.`);
  return value;
}
