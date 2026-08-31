import { ApiClient, ResponseFormatException } from '@/core/api/client';
import { canonicalTag } from '@/core/domain/tags';
import { playerClanTagStorageKey, STORAGE_KEYS, type StringStorage } from '@/core/storage/storage';
import { mapWithConcurrencyLimit } from '@/core/utils/bounded-concurrency';
import { Player } from '../models/player';
import {
  PlayerActivityFeed,
  PlayerCwlHistory,
  PlayerJoinLeavePage,
  PlayerJoinLeaveTotal,
  PlayerTimers,
  type PlayerHistoryTypeValue,
} from '../models/player-history';
import { PlayerBattlelogData, PlayerBattlelogEntry } from '../models/player-battlelog';
import {
  RankedLeagueData,
  RankedLeagueGroup,
  RankedLeagueHistoryEntry,
  RankedLeagueTier,
} from '../models/player-ranked';
import { buildPlayerWarStatsFromHistory, PlayerWarStats } from '../models/player-war';
import { WarStatsFilter } from '../models/war-stats-filter';
import { int, isRecord, record, records, string, type JsonRecord } from '../models/parsing';

const ALL_HTTP_STATUSES = Array.from({ length: 500 }, (_, index) => index + 100);
export type ClanRoleTranslationKey =
  'clanRoleLeader' | 'clanRoleCoLeader' | 'clanRoleElder' | 'clanRoleMember';
export type ClanRoleTranslator = (key: ClanRoleTranslationKey, fallback: string) => string;
export type PlayerErrorReporter = (operation: string, error: unknown) => void;

export class PlayerService {
  private loading = false;
  private playerProfiles: Player[] = [];
  private readonly playerClans: JsonRecord[] = [];
  private disposed = false;
  private readonly listeners = new Set<() => void>();
  private readonly officialLoads = new Map<string, Promise<Player>>();
  private readonly battlelogCache = new Map<string, PlayerBattlelogData>();
  private readonly activityCache = new Map<string, PlayerActivityFeed>();
  private readonly cwlCache = new Map<string, PlayerCwlHistory>();
  private readonly cwlLoads = new Map<string, Promise<PlayerCwlHistory>>();
  private readonly rankedCache = new Map<string, RankedLeagueData>();
  private readonly rankedLoads = new Map<string, Promise<RankedLeagueData>>();
  private leagueTiersLoad: Promise<ReadonlyMap<number, RankedLeagueTier> | null> | null = null;
  private leagueTiersCache: ReadonlyMap<number, RankedLeagueTier> | null = null;
  private rankedGeneration = 0;
  constructor(
    private readonly api: ApiClient,
    private readonly storage?: StringStorage,
    readonly apiV2Url = '',
    private readonly reportError?: PlayerErrorReporter,
  ) {}
  get isLoading() {
    return this.loading;
  }
  get profiles() {
    return this.playerProfiles as readonly Player[];
  }
  get clans() {
    return this.playerClans as readonly JsonRecord[];
  }
  subscribe(listener: () => void) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }
  dispose() {
    this.disposed = true;
    this.listeners.clear();
  }
  private notify() {
    if (!this.disposed) for (const listener of this.listeners) listener();
  }
  getSelectedProfile(selectedTag: string | null | undefined) {
    return selectedTag
      ? (this.playerProfiles.find((item) => item.tag === selectedTag) ?? null)
      : null;
  }
  async searchPlayers(
    query: string,
    options: {
      limit?: number;
      clanTags?: readonly string[];
      leagueIds?: readonly number[];
      townHallLevels?: readonly number[];
      extraHeaders?: Readonly<Record<string, string>>;
    } = {},
  ): Promise<readonly JsonRecord[]> {
    const normalized = query.trim();
    if (!normalized) return [];
    const pairs: [string, string][] = [
      ['query', normalized],
      ['limit', String(options.limit ?? 20)],
    ];
    if (options.clanTags?.length) pairs.push(['clanTags', options.clanTags.join(',')]);
    if (options.leagueIds?.length) pairs.push(['leagueIds', options.leagueIds.join(',')]);
    if (options.townHallLevels?.length)
      pairs.push(['townhallLevels', options.townHallLevels.join(',')]);
    const endpoint = `/player/search?${pairs.map(([k, v]) => `${k}=${encodeURIComponent(v)}`).join('&')}`;
    const response = await this.api.request(endpoint, {
      timeoutMs: 10_000,
      headers: options.extraHeaders,
      acceptedStatuses: ALL_HTTP_STATUSES,
    });
    if (response.status !== 200) return [];
    const decoded: unknown = JSON.parse(response.bodyText);
    return isRecord(decoded) && Array.isArray(decoded.items) ? records(decoded.items) : [];
  }
  loadPublicPlayerData(tags: readonly string[], notify = true) {
    return this.loadOfficialPlayerData(tags, { notify });
  }
  async loadOfficialPlayerData(
    tags: readonly string[],
    options: {
      notify?: boolean;
      throwOnError?: boolean;
      extraHeaders?: Readonly<Record<string, string>>;
    } = {},
  ): Promise<Record<string, string>> {
    this.loading = true;
    if (options.notify ?? true) this.notify();
    const clanTags: Record<string, string> = {};
    let firstError: unknown = null;
    try {
      const normalized = uniqueTags(tags);
      const loaded = await mapWithConcurrencyLimit(normalized, async (tag) => {
        try {
          const player = await this.fetchOfficialPlayer(tag, options.extraHeaders);
          if (player.clanOverview.tag) {
            clanTags[player.tag] = player.clanOverview.tag;
            await this.storage?.setString(
              playerClanTagStorageKey(player.tag),
              player.clanOverview.tag,
            );
          }
          return player;
        } catch (error) {
          if (options.throwOnError) firstError ??= error;
          return null;
        }
      });
      const profiles = loaded.filter((item): item is Player => item !== null);
      const loadedTags = new Set(profiles.map((item) => item.tag));
      this.playerProfiles = [
        ...profiles,
        ...this.playerProfiles.filter((item) => !loadedTags.has(item.tag)),
      ];
      if (!profiles.length && firstError) throw firstError;
      return clanTags;
    } catch (error) {
      this.reportError?.('player.load_official', error);
      if (options.throwOnError) throw error;
      return clanTags;
    } finally {
      this.loading = false;
      if (options.notify ?? true) this.notify();
    }
  }
  private fetchOfficialPlayer(tag: string, headers?: Readonly<Record<string, string>>) {
    const key = `${tag}|${headers?.['x-ck-user-id'] ?? ''}`,
      existing = this.officialLoads.get(key);
    if (existing) return existing;
    const load = this.fetchOfficialPlayerOnce(tag, headers).finally(() => {
      if (this.officialLoads.get(key) === load) this.officialLoads.delete(key);
    });
    this.officialLoads.set(key, load);
    return load;
  }
  private async fetchOfficialPlayerOnce(tag: string, headers?: Readonly<Record<string, string>>) {
    const json = await proxyRecord(this.api, `/players/${encodeURIComponent(tag)}`, headers);
    const responseTag = string(json.tag);
    if (!responseTag || canonicalTag(responseTag) !== canonicalTag(tag))
      throw new ResponseFormatException(
        'Official player response omitted or mismatched the player tag.',
      );
    return Player.fromJson(json);
  }
  async loadPlayerBattlelog(rawTag: string, forceRefresh = false) {
    const tag = canonicalTag(rawTag);
    if (!forceRefresh && this.battlelogCache.has(tag)) return this.battlelogCache.get(tag)!;
    const encoded = encodeURIComponent(tag);
    let official: PlayerBattlelogEntry[] = [],
      history: PlayerBattlelogEntry[] = [],
      officialError: unknown = null,
      historyError: unknown = null;
    await Promise.all([
      (async () => {
        try {
          const json = await proxyRecord(this.api, `/players/${encoded}/battlelog`);
          official = records(json.items).map(PlayerBattlelogEntry.fromOfficial);
        } catch (e) {
          officialError = e;
        }
      })(),
      (async () => {
        try {
          const json = await this.api.requestRecord(
            `/player/${encoded}/battlelog/history?limit=100&days=30`,
            { requiresAuth: true },
          );
          history = records(json.items).map(PlayerBattlelogEntry.fromHistory);
        } catch (e) {
          historyError = e;
        }
      })(),
    ]);
    if (officialError && historyError) throw officialError;
    const result = PlayerBattlelogData.merge({
      official,
      history,
      officialAvailable: !officialError,
      historyAvailable: !historyError,
    });
    this.battlelogCache.set(tag, result);
    return result;
  }
  async loadPlayerActivity(
    rawTag: string,
    type: PlayerHistoryTypeValue = 'troop_level',
    forceRefresh = false,
  ) {
    const tag = canonicalTag(rawTag),
      key = `${tag}|${type}`;
    if (!forceRefresh && this.activityCache.has(key)) return this.activityCache.get(key)!;
    const json = await this.api.requestRecord(
      `/player/${encodeURIComponent(tag)}/history/changes?type=${type}&limit=500`,
    );
    const result = PlayerActivityFeed.fromJson(json);
    this.activityCache.set(key, result);
    return result;
  }
  loadPlayerCwlHistory(rawTag: string, forceRefresh = false) {
    const tag = canonicalTag(rawTag);
    if (!forceRefresh) {
      const cached = this.cwlCache.get(tag);
      if (cached) return Promise.resolve(cached);
      const pending = this.cwlLoads.get(tag);
      if (pending) return pending;
    }
    const load = this.api
      .requestRecord(`/player/${encodeURIComponent(tag)}/cwl/history?limit=100`)
      .then(PlayerCwlHistory.fromJson)
      .then((value) => {
        this.cwlCache.set(tag, value);
        return value;
      })
      .finally(() => {
        if (this.cwlLoads.get(tag) === load) this.cwlLoads.delete(tag);
      });
    this.cwlLoads.set(tag, load);
    return load;
  }
  async loadPlayerTimers(rawTag: string) {
    return PlayerTimers.fromJson(
      await this.api.requestRecord(`/player/${encodeURIComponent(canonicalTag(rawTag))}/timers`),
    );
  }
  async loadPlayerJoinLeave(rawTag: string, before?: Date | null) {
    let endpoint = `/player/${encodeURIComponent(canonicalTag(rawTag))}/join-leave?limit=50`;
    if (before) endpoint += `&time%5Bbefore%5D=${encodeURIComponent(before.toISOString())}`;
    return PlayerJoinLeavePage.fromJson(
      await this.api.requestRecord(endpoint, { requiresAuth: true }),
    );
  }
  async loadPlayerJoinLeaveTotals(rawTag: string) {
    const json = await this.api.requestRecord(
      `/player/${encodeURIComponent(canonicalTag(rawTag))}/join-leave/totals`,
      { requiresAuth: true },
    );
    return records(json.items).map(PlayerJoinLeaveTotal.fromJson);
  }
  initPlayerData(
    tags: readonly string[],
    options: { notify?: boolean; throwOnError?: boolean } = {},
  ) {
    return this.loadOfficialPlayerData(tags, options);
  }
  async loadPlayerData(
    tags: readonly string[],
    _clanTags: Readonly<Record<string, string>>,
    options: { notify?: boolean; throwOnError?: boolean } = {},
  ) {
    await this.loadOfficialPlayerData(tags, options);
  }
  async getPlayerAndClanData(rawTag: string, extraHeaders?: Readonly<Record<string, string>>) {
    this.loading = true;
    this.notify();
    try {
      const tag = canonicalTag(rawTag);
      await this.loadOfficialPlayerData([tag], { notify: false, throwOnError: true, extraHeaders });
      const result = this.playerProfiles.find((item) => item.tag === tag);
      if (!result) throw new Error(`Player not loaded: ${tag}`);
      return result;
    } finally {
      this.loading = false;
      this.notify();
    }
  }
  async loadCachedClanTag(rawTag: string) {
    return (await this.storage?.getString(playerClanTagStorageKey(canonicalTag(rawTag)))) ?? '';
  }
  clearRankedLeagueCache() {
    this.rankedCache.clear();
    this.rankedLoads.clear();
    this.rankedGeneration += 1;
  }
  async prefetchRankedLeagueData(tags: Iterable<string>, forceRefresh = false) {
    await mapWithConcurrencyLimit(uniqueTags(tags), async (tag) => {
      try {
        await this.loadRankedLeagueData(tag, forceRefresh);
      } catch {
        return;
      }
    });
  }
  async loadRankedLeagueData(rawTag: string, forceRefresh = false, notifyOnChange = false) {
    const tag = canonicalTag(rawTag);
    if (!forceRefresh && this.rankedCache.has(tag)) return this.rankedCache.get(tag)!;
    const pending = this.rankedLoads.get(tag);
    if (pending) return pending;
    const generation = this.rankedGeneration,
      load = this.fetchRankedLeagueData(tag);
    this.rankedLoads.set(tag, load);
    try {
      const data = await load;
      if (generation === this.rankedGeneration) {
        this.rankedCache.set(tag, data);
        // Flutter recomputes its mounted Home Ranked card after returning from
        // detail. Detail owners opt into this notification; background Home
        // loads do not, preventing their own subscription from reloading.
        if (notifyOnChange) this.notify();
      }
      return data;
    } finally {
      if (this.rankedLoads.get(tag) === load) this.rankedLoads.delete(tag);
    }
  }
  private async fetchRankedLeagueData(tag: string) {
    const player = await proxyRecord(this.api, `/players/${encodeURIComponent(tag)}`),
      tierJson = isRecord(player.leagueTier)
        ? player.leagueTier
        : isRecord(player.league)
          ? player.league
          : null,
      currentTag =
        typeof player.currentLeagueGroupTag === 'string' ? player.currentLeagueGroupTag : null,
      currentSeason = int(player.currentLeagueSeasonId),
      previousTag =
        typeof player.previousLeagueGroupTag === 'string' ? player.previousLeagueGroupTag : null,
      previousSeason = int(player.previousLeagueSeasonId);
    const tiersLoad = this.loadLeagueTiers();
    const requests = [
      this.api.proxyGet(`/players/${encodeURIComponent(tag)}/leaguehistory`, {
        acceptedStatuses: ALL_HTTP_STATUSES,
      }),
    ];
    if (currentTag && currentSeason > 0)
      requests.push(
        this.api.proxyGet(
          `/leaguegroup/${encodeURIComponent(currentTag)}/${currentSeason}?playerTag=${encodeURIComponent(tag)}`,
          { acceptedStatuses: ALL_HTTP_STATUSES },
        ),
      );
    if (previousTag && previousSeason > 0)
      requests.push(
        this.api.proxyGet(
          `/leaguegroup/${encodeURIComponent(previousTag)}/${previousSeason}?playerTag=${encodeURIComponent(tag)}`,
          { acceptedStatuses: ALL_HTTP_STATUSES },
        ),
      );
    const responses = await Promise.all(requests),
      historyJson = responses[0]?.status === 200 ? parseResponse(responses[0].bodyText) : {},
      tiers = await tiersLoad;
    let index = 1;
    const currentIndex = currentTag && currentSeason > 0 ? index++ : null,
      previousIndex = previousTag && previousSeason > 0 ? index : null,
      currentResponse = currentIndex === null ? null : responses[currentIndex],
      previousResponse = previousIndex === null ? null : responses[previousIndex],
      current =
        currentTag && currentResponse?.status === 200
          ? RankedLeagueGroup.fromJson(
              parseResponse(currentResponse.bodyText),
              currentTag,
              currentSeason,
            )
          : null,
      previous =
        previousTag && previousResponse?.status === 200
          ? RankedLeagueGroup.fromJson(
              parseResponse(previousResponse.bodyText),
              previousTag,
              previousSeason,
            )
          : null,
      history = records(historyJson.items)
        .map(RankedLeagueHistoryEntry.fromJson)
        .sort((a, b) => b.leagueSeasonId - a.leagueSeasonId);
    return new RankedLeagueData(
      string(player.tag, tag),
      string(player.name),
      int(player.townHallLevel),
      int(player.trophies),
      int(player.bestTrophies),
      tierJson ? RankedLeagueTier.fromJson(tierJson) : null,
      tiers,
      history,
      current,
      previous,
    );
  }
  private async loadLeagueTiers() {
    if (this.leagueTiersCache) return this.leagueTiersCache;
    if (this.leagueTiersLoad) return (await this.leagueTiersLoad) ?? new Map();
    const load = this.fetchLeagueTiers();
    this.leagueTiersLoad = load;
    try {
      const tiers = await load;
      if (tiers) this.leagueTiersCache = tiers;
      return tiers ?? new Map();
    } finally {
      if (this.leagueTiersLoad === load) this.leagueTiersLoad = null;
    }
  }
  private async fetchLeagueTiers() {
    const response = await this.api.proxyGet('/leaguetiers', {
      acceptedStatuses: ALL_HTTP_STATUSES,
    });
    if (response.status !== 200) return null;
    const json = parseResponse(response.bodyText);
    return new Map(
      records(json.items).map((item) => {
        const tier = RankedLeagueTier.fromJson(item);
        return [tier.id, tier] as const;
      }),
    );
  }
  async useOfficialPlayerData(data: JsonRecord) {
    const player = Player.fromJson(data),
      index = this.playerProfiles.findIndex((item) => item.tag === player.tag);
    if (index < 0) this.playerProfiles = [player, ...this.playerProfiles];
    else this.playerProfiles[index] = player;
    if (player.clanOverview.tag)
      await this.storage?.setString(playerClanTagStorageKey(player.tag), player.clanOverview.tag);
    this.notify();
    return player;
  }
  hydrateBookmarkedPlayers(tags: readonly string[]) {
    return this.loadOfficialPlayerData(uniqueTags(tags), {
      notify: true,
      throwOnError: false,
    }).then(() => undefined);
  }
  linkClansToPlayer(players: readonly Player[], clans: readonly { tag: string }[]) {
    const byTag = new Map(clans.map((clan) => [clan.tag, clan]));
    for (const player of players)
      if (player.clanTag) player.clan = byTag.get(player.clanTag) ?? player.clan;
  }
  async loadPlayerWarStats(
    tags: readonly string[],
    options: { notify?: boolean; throwOnError?: boolean } = {},
  ) {
    try {
      const stats = await mapWithConcurrencyLimit(uniqueTags(tags), async (tag) => {
        const json = await this.api.requestRecord(playerWarHistoryEndpoint(tag, { limit: 50 }));
        return buildPlayerWarStatsFromHistory(records(json.items), tag);
      });
      const byTag = new Map(this.playerProfiles.map((player) => [player.tag, player]));
      for (const item of stats) {
        const player = byTag.get(item.tag);
        if (player) player.warStats = item;
      }
    } catch (error) {
      if (options.throwOnError) throw error;
    } finally {
      if (options.notify ?? true) this.notify();
    }
  }
  async loadPlayerWarStatsWithFilter(tag: string, filter: WarStatsFilter) {
    const normalized = canonicalTag(tag);
    const json = await this.api.requestRecord(playerWarHistoryEndpoint(normalized, filter));
    return buildPlayerWarStatsFromHistory(records(json.items), normalized, filter);
  }
  async loadWarFilterPresets() {
    const raw = await this.storage?.getString(STORAGE_KEYS.warStatsFilterPresets);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as { name: string; filter: JsonRecord }[];
    return parsed.map((preset) => ({
      name: preset.name,
      filter: WarStatsFilter.fromJson(preset.filter),
    }));
  }
  async saveWarFilterPresets(presets: readonly { name: string; filter: WarStatsFilter }[]) {
    await this.storage?.setString(
      STORAGE_KEYS.warStatsFilterPresets,
      JSON.stringify(
        presets.map((preset) => ({ name: preset.name, filter: preset.filter.toJson() })),
      ),
    );
  }
  getRoleText(role: string, translate?: ClanRoleTranslator) {
    const localized = (key: ClanRoleTranslationKey, fallback: string) =>
      translate?.(key, fallback) ?? fallback;
    return role === 'leader'
      ? localized('clanRoleLeader', 'Leader')
      : role === 'coLeader'
        ? localized('clanRoleCoLeader', 'Co-Leader')
        : role === 'admin'
          ? localized('clanRoleElder', 'Elder')
          : role === 'member'
            ? localized('clanRoleMember', 'Member')
            : 'No clan';
  }
  getMinimalisticPlayerByTag(tag: string) {
    const player = this.playerProfiles.find((item) => item.tag === tag);
    return player
      ? JSON.stringify({
          player_tag: player.tag,
          name: player.name,
          townHallLevel: player.townHallLevel,
        })
      : '{}';
  }
  processBulkPlayerData(extended: unknown[], basic: unknown[], notify = true) {
    const linked = basic.filter(isRecord).map(Player.fromJson),
      tags = new Set(linked.map((item) => item.tag));
    for (const player of linked) {
      if (player.clanOverview.tag) {
        void this.storage?.setString(playerClanTagStorageKey(player.tag), player.clanOverview.tag);
      }
    }
    this.playerProfiles = [...linked, ...this.playerProfiles.filter((item) => !tags.has(item.tag))];
    const byTag = new Map(this.playerProfiles.map((item) => [item.tag, item]));
    for (const data of extended.filter(isRecord))
      byTag.get(string(data.tag))?.enrichWithFullStats(data);
    if (notify) this.notify();
  }
  processBulkWarStats(items: unknown[], notify = true) {
    this.applyWarStats(items.filter(isRecord), null);
    if (notify) this.notify();
  }
  private applyWarStats(items: JsonRecord[], wars: unknown[] | null) {
    const byTag = new Map(this.playerProfiles.map((item) => [item.tag, item]));
    for (const item of items) {
      const tag = string(item.tag),
        player = byTag.get(tag);
      if (player)
        player.warStats = PlayerWarStats.fromJson(
          item,
          tag,
          wars ?? (Array.isArray(item.wars) ? item.wars : []),
        );
    }
  }
  notifyDataChanged() {
    this.notify();
  }
}

function playerWarHistoryEndpoint(
  tag: string,
  filter: {
    warType?: string;
    warTypes?: readonly string[] | null;
    startDate?: Date | null;
    endDate?: Date | null;
    limit: number;
  },
): string {
  const query = new URLSearchParams({ limit: String(Math.min(500, Math.max(1, filter.limit))) });
  const types = filter.warTypes?.filter((type) => type !== 'all') ?? [];
  const type =
    types.length === 1
      ? types[0]
      : filter.warType !== undefined && filter.warType !== 'all'
        ? filter.warType
        : null;
  if (type) query.set('type', type);
  if (filter.startDate) query.set('time[after]', filter.startDate.toISOString());
  if (filter.endDate) query.set('time[before]', filter.endDate.toISOString());
  return `/player/${encodeURIComponent(tag)}/war/stats?${query.toString()}`;
}

async function proxyRecord(
  api: ApiClient,
  path: string,
  headers?: Readonly<Record<string, string>>,
) {
  const response = await api.proxyGet(path, { headers }),
    parsed: unknown = JSON.parse(response.bodyText);
  if (!isRecord(parsed)) throw new ResponseFormatException(`Invalid response type for ${path}.`);
  return parsed;
}
function parseResponse(body: string): JsonRecord {
  try {
    const parsed: unknown = JSON.parse(body);
    return record(parsed);
  } catch {
    return {};
  }
}
function uniqueTags(tags: Iterable<string>) {
  return [...new Set([...tags].map(canonicalTag).filter(Boolean))];
}
