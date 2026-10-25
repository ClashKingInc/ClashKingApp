import {
  expoEndpoints,
  LegendBattlelogEndpoint,
  LegendHistoricalRanksEndpoint,
  LegendRanksEndpoint,
  PlayerBattlelogHistoryEndpoint,
  PlayerChangesEndpoint,
  PlayerCwlHistoryEndpoint,
  PlayerJoinLeaveEndpoint,
  PlayerJoinLeaveTotalsEndpoint,
  PlayerLastActivityEndpoint,
  PlayerLeagueHistoryEndpoint,
  PlayerSearchEndpoint,
  PlayerTimersEndpoint,
  PlayerWarStatsEndpoint,
  PlayerWarStatsExportEndpoint,
  RankedBattlelogEndpoint,
} from '@clashking/api-contracts/expo';
import {
  ProxyLeagueGroupEndpoint,
  ProxyLeagueTiersEndpoint,
  ProxyPlayerBattlelogEndpoint,
  ProxyPlayerEndpoint,
  ProxyPlayerLeagueHistoryEndpoint,
} from '../../../core/api/proxy-contracts';
import { ApiResponseError, TransportError } from '@clashking/api-client';
import { Effect } from 'effect';

import type { ContractApiService } from '@/core/api/contract-api';
import { canonicalTag } from '@/core/domain/tags';
import { playerClanTagStorageKey, STORAGE_KEYS, type StringStorage } from '@/core/storage/storage';
import { mapWithConcurrencyLimit } from '@/core/utils/bounded-concurrency';
import { Player } from '../models/player';
import { currentLegendSeasonStart } from '../models/legend-season-window';
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
  currentLegendDay,
  PlayerLegendBattle,
  PlayerLegendBattlelog,
  PlayerLegendHistoryEntry,
  PlayerLegendLeagueData,
  PlayerLegendOpponentInsight,
  PlayerLegendRank,
  PlayerLegendDaySummary,
} from '../models/player-legend';
import {
  RankedLeagueData,
  RankedLeagueBattlelog,
  RankedLeagueGroup,
  RankedLeagueHistoryEntry,
  RankedLeagueTier,
} from '../models/player-ranked';
import { buildPlayerWarStatsFromHistory, PlayerWarStats } from '../models/player-war';
import { WarStatsFilter } from '../models/war-stats-filter';
import { int, isRecord, records, string, type JsonRecord } from '../models/parsing';

export type ClanRoleTranslationKey =
  'clanRoleLeader' | 'clanRoleCoLeader' | 'clanRoleElder' | 'clanRoleMember';
export type ClanRoleTranslator = (key: ClanRoleTranslationKey, fallback: string) => string;
export type PlayerErrorReporter = (operation: string, error: unknown) => void;

export class PlayerService {
  downloadWarStatsExport(body: typeof PlayerWarStatsExportEndpoint.body.Type): Promise<Response> {
    return Effect.runPromise(
      this.api.execute(PlayerWarStatsExportEndpoint, { path: {}, query: {}, body }),
    );
  }
  private loading = false;
  private playerProfiles: Player[] = [];
  private readonly playerClans: JsonRecord[] = [];
  private disposed = false;
  private readonly listeners = new Set<() => void>();
  private readonly officialLoads = new Map<string, Promise<Player>>();
  private readonly profileJsonLoads = new Map<string, Promise<JsonRecord>>();
  private readonly profileJsonCache = new Map<string, { value: JsonRecord; at: number }>();
  private readonly battlelogCache = new Map<string, PlayerBattlelogData>();
  private readonly battlelogLoads = new Map<string, Promise<PlayerBattlelogData>>();
  private readonly activityCache = new Map<string, PlayerActivityFeed>();
  private readonly cwlCache = new Map<string, PlayerCwlHistory>();
  private readonly cwlLoads = new Map<string, Promise<PlayerCwlHistory>>();
  private readonly rankedCache = new Map<string, RankedLeagueData>();
  private readonly rankedLoads = new Map<string, Promise<RankedLeagueData>>();
  private readonly rankedCacheTimes = new Map<string, number>();
  private readonly rankedDetails = new Map<
    string,
    { at: number; rows: readonly PlayerBattlelogEntry[] }
  >();
  private readonly rankedDetailsLoads = new Map<string, Promise<readonly PlayerBattlelogEntry[]>>();
  private readonly rankedGroupLoads = new Map<string, Promise<JsonRecord | null>>();
  private readonly rankedGroupCache = new Map<string, { value: JsonRecord | null; at: number }>();
  private readonly legendBattlelogCache = new Map<string, PlayerLegendBattlelog | null>();
  private readonly legendBattlelogLoads = new Map<string, Promise<PlayerLegendBattlelog | null>>();
  private readonly legendLeagueCache = new Map<string, PlayerLegendLeagueData>();
  private readonly legendLeagueLoads = new Map<string, Promise<PlayerLegendLeagueData>>();
  private leagueTiersLoad: Promise<ReadonlyMap<number, RankedLeagueTier> | null> | null = null;
  private leagueTiersCache: ReadonlyMap<number, RankedLeagueTier> | null = null;
  private rankedGeneration = 0;
  constructor(
    private readonly api: ContractApiService,
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
    try {
      const decoded = await Effect.runPromise(
        this.api.execute(
          PlayerSearchEndpoint,
          {
            path: {},
            body: {},
            query: {
              query: normalized,
              limit: options.limit ?? 20,
              ...(options.clanTags?.length ? { clanTags: options.clanTags.join(',') } : {}),
              ...(options.leagueIds?.length ? { leagueIds: options.leagueIds.join(',') } : {}),
              ...(options.townHallLevels?.length
                ? { townhallLevels: options.townHallLevels.join(',') }
                : {}),
            },
          },
          { timeoutMs: 10_000, headers: options.extraHeaders },
        ),
      );
      return decoded.items;
    } catch (error) {
      if (error instanceof TransportError) throw error;
      return [];
    }
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
      forceRefresh?: boolean;
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
          const player = await this.fetchOfficialPlayer(
            tag,
            options.extraHeaders,
            options.forceRefresh,
          );
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
  private fetchOfficialPlayer(
    tag: string,
    headers?: Readonly<Record<string, string>>,
    forceRefresh = false,
  ) {
    const key = `${tag}|${JSON.stringify(Object.entries(headers ?? {}).sort())}`,
      existing = this.officialLoads.get(key);
    if (existing) return existing;
    const load = this.fetchOfficialPlayerOnce(tag, headers, forceRefresh).finally(() => {
      if (this.officialLoads.get(key) === load) this.officialLoads.delete(key);
    });
    this.officialLoads.set(key, load);
    return load;
  }
  private loadProfileJson(
    tag: string,
    headers?: Readonly<Record<string, string>>,
    forceRefresh = false,
  ): Promise<JsonRecord> {
    const key = `${tag}|${JSON.stringify(Object.entries(headers ?? {}).sort())}`;
    const pending = this.profileJsonLoads.get(key);
    if (pending) return pending;
    const cached = this.profileJsonCache.get(key);
    const age = cached ? Date.now() - cached.at : Infinity;
    if (!forceRefresh && cached && age >= 0 && age < 30_000) return Promise.resolve(cached.value);
    const generation = this.rankedGeneration;
    const load = Effect.runPromise(
      this.api.execute(
        ProxyPlayerEndpoint,
        { path: { playerTag: tag }, query: {}, body: {} },
        { headers },
      ),
    )
      .then((json) => {
        if (!string(json.tag) || canonicalTag(string(json.tag)) !== canonicalTag(tag))
          throw new TypeError('Official player response omitted or mismatched the player tag.');
        if (generation === this.rankedGeneration) {
          // Bound caches for long-running browsing sessions. Never persist credentials.
          if (this.profileJsonCache.size >= 200)
            this.profileJsonCache.delete(this.profileJsonCache.keys().next().value!);
          this.profileJsonCache.set(key, { value: json, at: Date.now() });
          if (!headers)
            void this.storage
              ?.setString(
                `rankedHint:v1:${tag}`,
                JSON.stringify({
                  at: Date.now(),
                  group: json.currentLeagueGroupTag,
                  season: json.currentLeagueSeasonId,
                }),
              )
              .catch(() => undefined);
        }
        return json;
      })
      .finally(() => {
        if (this.profileJsonLoads.get(key) === load) this.profileJsonLoads.delete(key);
      });
    this.profileJsonLoads.set(key, load);
    return load;
  }
  private async fetchOfficialPlayerOnce(
    tag: string,
    headers?: Readonly<Record<string, string>>,
    forceRefresh = false,
  ) {
    const json = await this.loadProfileJson(tag, headers, forceRefresh);
    const responseTag = string(json.tag);
    if (!responseTag || canonicalTag(responseTag) !== canonicalTag(tag))
      throw new TypeError('Official player response omitted or mismatched the player tag.');
    const player = Player.fromJson(json);
    try {
      const activity = await Effect.runPromise(
        this.api.execute(
          PlayerLastActivityEndpoint,
          {
            path: { playerTag: tag },
            query: {},
            body: {},
          },
          { headers },
        ),
      );
      if (activity.lastObservedAt) {
        const observedAt = new Date(activity.lastObservedAt);
        if (Number.isFinite(observedAt.getTime())) player.lastOnline = observedAt;
      }
    } catch {
      // Official player details remain usable when tracked activity is unavailable.
    }
    return player;
  }
  async loadPlayerBattlelog(rawTag: string, forceRefresh = false) {
    const tag = canonicalTag(rawTag);
    if (!forceRefresh && this.battlelogCache.has(tag)) return this.battlelogCache.get(tag)!;
    const pending = this.battlelogLoads.get(tag);
    if (pending) return pending;
    const load = this.fetchPlayerBattlelog(tag);
    this.battlelogLoads.set(tag, load);
    try {
      return await load;
    } finally {
      if (this.battlelogLoads.get(tag) === load) this.battlelogLoads.delete(tag);
    }
  }

  private async fetchPlayerBattlelog(tag: string) {
    let official: PlayerBattlelogEntry[] = [],
      history: PlayerBattlelogEntry[] = [],
      officialError: unknown = null,
      historyError: unknown = null;
    await Promise.all([
      (async () => {
        try {
          const json = await Effect.runPromise(
            this.api.execute(ProxyPlayerBattlelogEndpoint, {
              path: { playerTag: tag },
              query: {},
              body: {},
            }),
          );
          official = records(json.items).map(PlayerBattlelogEntry.fromOfficial);
        } catch (e) {
          officialError = e;
        }
      })(),
      (async () => {
        try {
          const json = await Effect.runPromise(
            this.api.execute(PlayerBattlelogHistoryEndpoint, {
              path: { playerTag: tag },
              query: {
                'time[after]': new Date(Date.now() - 179 * 86_400_000).toISOString().slice(0, 10),
              },
              body: {},
            }),
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
    const json = await Effect.runPromise(
      this.api.execute(PlayerChangesEndpoint, {
        path: { playerTag: tag },
        query: { type, limit: 500 },
        body: {},
      }),
    );
    const result = PlayerActivityFeed.fromJson(json);
    this.activityCache.set(key, result);
    return result;
  }
  async loadPlayerLegendHistory(rawTag: string): Promise<readonly PlayerLegendHistoryEntry[]> {
    // Finished seasons belong to the player even after they leave Legend League.
    // Do not gate this request on their current league or substitute current-season data.
    const response = await Effect.runPromise(
      this.api.execute(PlayerLeagueHistoryEndpoint, {
        path: { playerTag: canonicalTag(rawTag) },
        query: {},
        body: {},
      }),
    );
    return records(response.items)
      .filter((item) => string(item.mode) === 'legend')
      .map(PlayerLegendHistoryEntry.fromJson);
  }

  loadPlayerCwlHistory(rawTag: string, forceRefresh = false) {
    const tag = canonicalTag(rawTag);
    if (!forceRefresh) {
      const cached = this.cwlCache.get(tag);
      if (cached) return Promise.resolve(cached);
      const pending = this.cwlLoads.get(tag);
      if (pending) return pending;
    }
    const load = Effect.runPromise(
      this.api.execute(PlayerCwlHistoryEndpoint, {
        path: { playerTag: tag },
        query: { limit: 100 },
        body: {},
      }),
    )
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
      await Effect.runPromise(
        this.api.execute(PlayerTimersEndpoint, {
          path: { playerTag: canonicalTag(rawTag) },
          query: {},
          body: {},
        }),
      ),
    );
  }
  async loadPlayerJoinLeave(rawTag: string, before?: Date | null) {
    return PlayerJoinLeavePage.fromJson(
      await Effect.runPromise(
        this.api.execute(PlayerJoinLeaveEndpoint, {
          path: { playerTag: canonicalTag(rawTag) },
          query: { limit: 50, ...(before ? { 'time[before]': before.toISOString() } : {}) },
          body: {},
        }),
      ),
    );
  }
  async loadPlayerJoinLeaveTotals(rawTag: string) {
    const json = await Effect.runPromise(
      this.api.execute(PlayerJoinLeaveTotalsEndpoint, {
        path: { playerTag: canonicalTag(rawTag) },
        query: {},
        body: {},
      }),
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
    this.profileJsonCache.clear();
    this.profileJsonLoads.clear();
    this.officialLoads.clear();
    this.rankedCacheTimes.clear();
    this.rankedDetails.clear();
    this.rankedDetailsLoads.clear();
    this.rankedGroupLoads.clear();
    this.rankedGroupCache.clear();
    this.rankedCache.clear();
    this.rankedLoads.clear();
    this.legendBattlelogCache.clear();
    this.legendBattlelogLoads.clear();
    this.legendLeagueCache.clear();
    this.legendLeagueLoads.clear();
    this.rankedGeneration += 1;
  }

  async loadLegendBattlelog(rawTag: string, day: string, forceRefresh = false) {
    const tag = canonicalTag(rawTag);
    if (!/^\d{4}-\d{2}-\d{2}$/u.test(day)) {
      throw new RangeError('Legend battlelog day must use YYYY-MM-DD.');
    }
    const key = `${tag}|${day}`;
    if (!forceRefresh && this.legendBattlelogCache.has(key)) {
      return this.legendBattlelogCache.get(key)!;
    }
    const pending = this.legendBattlelogLoads.get(key);
    if (pending) return pending;
    const generation = this.rankedGeneration;
    const load = optionalApiResponse(
      Effect.runPromise(
        this.api.execute(LegendBattlelogEndpoint, {
          path: { playerTag: tag, day },
          query: {},
          body: {},
        }),
      ),
    ).then((response) => {
      if (response === null) return null;
      const battlelog = PlayerLegendBattlelog.fromJson(response as unknown as JsonRecord);
      if (canonicalTag(battlelog.tag) !== tag || battlelog.day !== day) {
        throw new TypeError('Legend battlelog response does not match the requested player day.');
      }
      return battlelog;
    });
    this.legendBattlelogLoads.set(key, load);
    try {
      const battlelog = await load;
      if (generation === this.rankedGeneration) this.legendBattlelogCache.set(key, battlelog);
      return battlelog;
    } finally {
      if (this.legendBattlelogLoads.get(key) === load) this.legendBattlelogLoads.delete(key);
    }
  }

  async loadLegendLeagueData(
    rawTag: string,
    forceRefresh = false,
    day = currentLegendDay(),
    baseline?: PlayerLegendLeagueData,
  ) {
    const tag = canonicalTag(rawTag);
    const key = `${tag}|${day}`;
    if (!forceRefresh && this.legendLeagueCache.has(key)) return this.legendLeagueCache.get(key)!;
    const pending = this.legendLeagueLoads.get(key);
    if (pending) return pending;
    const load = this.fetchLegendLeagueData(tag, day, forceRefresh, baseline);
    this.legendLeagueLoads.set(key, load);
    try {
      const data = await load;
      this.legendLeagueCache.set(key, data);
      return data;
    } finally {
      if (this.legendLeagueLoads.get(key) === load) this.legendLeagueLoads.delete(key);
    }
  }

  private async fetchLegendLeagueData(
    tag: string,
    day: string,
    forceRefresh: boolean,
    baseline?: PlayerLegendLeagueData,
  ) {
    const seriesToday = currentLegendDay();
    const seriesStart = new Date(`${seriesToday}T00:00:00.000Z`);
    seriesStart.setUTCDate(seriesStart.getUTCDate() - 27);
    const [
      player,
      historySource,
      currentDaySource,
      historicalRankSource,
      recentDaysSource,
      seasonSource,
      comparisonsSource,
    ] = await Promise.all([
      baseline
        ? Promise.resolve(null)
        : Effect.runPromise(
            this.api.execute(ProxyPlayerEndpoint, {
              path: { playerTag: tag },
              query: {},
              body: {},
            }),
          ),
      legendSource(
        Effect.runPromise(
          this.api.execute(PlayerLeagueHistoryEndpoint, {
            path: { playerTag: tag },
            query: {},
            body: {},
          }),
        ),
        null,
      ),
      legendSource(this.loadLegendBattlelog(tag, day, forceRefresh), baseline?.currentDay ?? null),
      legendSource(
        Effect.runPromise(
          this.api.execute(LegendHistoricalRanksEndpoint, {
            path: {},
            query: {},
            body: { day, tags: [tag] },
          }),
        ),
        null,
      ),
      legendSource(
        Effect.runPromise(
          this.api.execute(expoEndpoints.legendPlayerDailySeries, {
            path: { playerTag: tag },
            query: {
              'time[after]': seriesStart.toISOString().slice(0, 10),
              'time[before]': seriesToday,
            },
            body: {},
          }),
        ),
        null,
      ),
      legendSource(
        Effect.runPromise(
          this.api.execute(expoEndpoints.legendPlayerSeason, {
            path: { playerTag: tag },
            query: {},
            body: {},
          }),
        ),
        null,
      ),
      legendSource(
        Effect.runPromise(
          this.api.execute(expoEndpoints.legendPlayerComparisons, {
            path: { playerTag: tag },
            query: {},
            body: {},
          }),
        ),
        null,
      ),
    ]);
    const historyResponse = historySource.value;
    const currentDay = currentDaySource.value;
    const historicalRankResponse = historicalRankSource.value;
    const recentDays = recentDaysSource.value;
    const opponentTags = uniqueTags(
      currentDay
        ? [...currentDay.attacks, ...currentDay.defenses]
            .filter((battle) => !battle.automatic && battle.opponentTag)
            .map((battle) => battle.opponentTag)
        : [],
    ).slice(0, 99);
    const [currentRankSource, opponentDayResponse] = await Promise.all([
      legendSource(
        Effect.runPromise(
          this.api.execute(LegendRanksEndpoint, {
            path: {},
            query: {},
            body: { tags: [tag, ...opponentTags] },
          }),
        ),
        null,
      ),
      opponentTags.length
        ? Effect.runPromise(
            this.api.execute(expoEndpoints.legendDaySummaries, {
              path: {},
              query: {},
              body: { day, tags: opponentTags },
            }),
          ).catch(() => null)
        : Promise.resolve(null),
    ]);
    const currentRankResponse = currentRankSource.value;
    const anyLegendSourceAvailable =
      historySource.available ||
      currentDaySource.available ||
      historicalRankSource.available ||
      recentDaysSource.available ||
      seasonSource.available ||
      comparisonsSource.available ||
      currentRankSource.available;
    const hasStoredLegendData = Boolean(
      baseline &&
      (baseline.currentDay ||
        baseline.history.length ||
        baseline.currentRank ||
        baseline.historicalRank ||
        baseline.recentDays.length ||
        baseline.seasonStats),
    );
    if (!anyLegendSourceAvailable && !hasStoredLegendData) {
      throw new Error('Legend League data is temporarily unavailable.');
    }
    const history = historyResponse
      ? records(historyResponse.items)
          .filter((item) => string(item.mode) === 'legend')
          .map(PlayerLegendHistoryEntry.fromJson)
      : (baseline?.history ?? []);
    const currentRank =
      records(currentRankResponse?.items)
        .map(PlayerLegendRank.fromJson)
        .find((item) => canonicalTag(item.tag) === tag) ??
      baseline?.currentRank ??
      null;
    const historicalRank =
      records(historicalRankResponse?.items)
        .map(PlayerLegendRank.fromJson)
        .find((item) => canonicalTag(item.tag) === tag) ??
      baseline?.historicalRank ??
      null;
    const season = seasonSource.value;
    const seasonStart =
      season?.seasonStart.slice(0, 10) ??
      currentLegendSeasonStart(
        history.map((entry) => entry.season),
        seriesToday,
      );
    const opponentRanks = new Map(
      records(currentRankResponse?.items)
        .map(PlayerLegendRank.fromJson)
        .filter((item) => canonicalTag(item.tag) !== tag)
        .map((item) => [canonicalTag(item.tag), item] as const),
    );
    const opponentDays = new Map(
      records(opponentDayResponse?.items).map((item) => [
        canonicalTag(string(item.tag)),
        int(item.netTrophies),
      ]),
    );
    const enrichedCurrentDay = currentDay
      ? new PlayerLegendBattlelog(
          currentDay.tag,
          currentDay.day,
          currentDay.startsAt,
          currentDay.endsAt,
          currentDay.closed,
          currentDay.attackTrophies,
          currentDay.defenseTrophies,
          currentDay.trophyChange,
          currentDay.attacks.map((battle) =>
            enrichLegendOpponent(battle, opponentRanks, opponentDays),
          ),
          currentDay.defenses.map((battle) =>
            enrichLegendOpponent(battle, opponentRanks, opponentDays),
          ),
        )
      : null;
    return new PlayerLegendLeagueData(
      player ? string(player.tag, tag) : (baseline?.playerTag ?? tag),
      player ? string(player.name) : (baseline?.playerName ?? ''),
      player ? int(player.townHallLevel) : (baseline?.townHallLevel ?? 0),
      currentRank?.trophies ?? (player ? int(player.trophies) : (baseline?.trophies ?? 0)),
      player ? int(player.bestTrophies) : (baseline?.bestTrophies ?? 0),
      enrichedCurrentDay,
      history,
      day,
      currentRank,
      historicalRank,
      recentDays
        ? records(recentDays.items)
            .map(PlayerLegendDaySummary.fromJson)
            .filter((value) => seasonStart === null || value.day >= seasonStart)
        : (baseline?.recentDays ?? []),
      season?.armyShareCodes ?? baseline?.seasonArmyShareCodes ?? [],
      season?.seasonStart ?? baseline?.seasonStart ?? null,
      season?.seasonEnd ?? baseline?.seasonEnd ?? null,
      season?.stats ?? baseline?.seasonStats ?? null,
      comparisonsSource.value?.items ?? baseline?.comparisons ?? [],
      season ?? baseline?.posterSeason ?? null,
    );
  }
  async prefetchRankedLeagueData(tags: Iterable<string>, forceRefresh = false) {
    await mapWithConcurrencyLimit(uniqueTags(tags), async (tag) => {
      try {
        await this.loadRankedLeagueData(tag, forceRefresh, false, 'home');
      } catch {
        return;
      }
    });
  }
  async loadRankedLeagueData(
    rawTag: string,
    forceRefresh = false,
    notifyOnChange = false,
    scope: 'home' | 'detail' = 'detail',
  ) {
    const tag = canonicalTag(rawTag);
    const key = `${tag}:${scope}`;
    const age = Date.now() - (this.rankedCacheTimes.get(key) ?? -Infinity);
    if (!forceRefresh && age >= 0 && age < 60_000 && this.rankedCache.has(key))
      return this.rankedCache.get(key)!;
    const pending = this.rankedLoads.get(key);
    if (pending) return pending;
    const generation = this.rankedGeneration,
      load = this.fetchRankedLeagueData(tag, scope, forceRefresh);
    this.rankedLoads.set(key, load);
    try {
      const data = await load;
      if (generation === this.rankedGeneration) {
        this.rankedCache.set(key, data);
        this.rankedCacheTimes.set(key, Date.now());
        // Flutter recomputes its mounted Home Ranked card after returning from
        // detail. Detail owners opt into this notification; background Home
        // loads do not, preventing their own subscription from reloading.
        if (notifyOnChange) this.notify();
      }
      return data;
    } finally {
      if (this.rankedLoads.get(key) === load) this.rankedLoads.delete(key);
    }
  }
  loadRankedBattleDetails(rawTag: string): Promise<readonly PlayerBattlelogEntry[]> {
    const tag = canonicalTag(rawTag);
    const cached = this.rankedDetails.get(tag);
    if (cached && Date.now() - cached.at < 60_000) return Promise.resolve(cached.rows);
    const pending = this.rankedDetailsLoads.get(tag);
    if (pending) return pending;
    const generation = this.rankedGeneration;
    const load = Effect.runPromise(
      this.api.execute(ProxyPlayerBattlelogEndpoint, {
        path: { playerTag: tag },
        query: {},
        body: {},
      }),
    )
      .then((response) => {
        const rows = records(response.items)
          .map(PlayerBattlelogEntry.fromOfficial)
          .filter((entry) => entry.mode === 'ranked');
        if (generation === this.rankedGeneration) {
          if (this.rankedDetails.size >= 64)
            this.rankedDetails.delete(this.rankedDetails.keys().next().value!);
          this.rankedDetails.set(tag, { at: Date.now(), rows });
        }
        return rows;
      })
      .catch(() => [] as readonly PlayerBattlelogEntry[])
      .finally(() => {
        if (this.rankedDetailsLoads.get(tag) === load) this.rankedDetailsLoads.delete(tag);
      });
    this.rankedDetailsLoads.set(tag, load);
    return load;
  }

  async loadRankedSeasonBattlelog(
    rawTag: string,
    season: number,
    onBattlesReady?: (log: RankedLeagueBattlelog) => void,
  ): Promise<RankedLeagueBattlelog | null> {
    const tag = canonicalTag(rawTag);
    if (!Number.isSafeInteger(season) || season <= 0) return null;
    const response = await optionalApiResponse(
      Effect.runPromise(
        this.api.execute(RankedBattlelogEndpoint, {
          path: { playerTag: tag, seasonId: String(season) },
          query: {},
          body: {},
        }),
      ),
    );
    // Older history entries lack a group tag. Still validate player and week;
    // never merge a response from a different account or season.
    const log = parseRankedBattlelog(response, tag, null, season);
    if (!log) return null;
    // Armies are optional enrichment: a second endpoint must not delay the
    // selected week's valid battle records or keep its skeleton on screen.
    onBattlesReady?.(log);
    const [armies, details] = await Promise.all([
      this.loadRankedArmyHistory(tag, [season]),
      this.loadRankedBattleDetails(tag),
    ]);
    return log.withAttackArmies([...armies, ...details]);
  }
  private async loadRankedArmyHistory(tag: string, seasons: readonly number[]) {
    const valid = seasons.filter((season) => Number.isSafeInteger(season) && season > 0);
    if (!valid.length) return [];
    // This is optional enrichment. A history outage must not hide otherwise
    // valid official standings and battles.
    const response = await Effect.runPromise(
      this.api.execute(PlayerBattlelogHistoryEndpoint, {
        path: { playerTag: tag },
        query: {
          'time[after]': new Date(Math.min(...valid) * 1000).toISOString().slice(0, 10),
          'time[before]': new Date((Math.max(...valid) + 7 * 86400) * 1000)
            .toISOString()
            .slice(0, 10),
        },
        body: {},
      }),
    ).catch(() => null);
    return records(response?.items)
      .map(PlayerBattlelogEntry.fromHistory)
      .filter((entry) => entry.mode === 'ranked');
  }
  private loadRankedGroup(
    tag: string,
    group: string | null,
    season: number,
    force: boolean,
  ): Promise<JsonRecord | null> {
    if (!group || season <= 0) return Promise.resolve(null);
    const key = `${tag}:${group}:${season}`;
    const pending = this.rankedGroupLoads.get(key);
    if (pending) return pending;
    const cached = this.rankedGroupCache.get(key);
    const age = cached ? Date.now() - cached.at : Infinity;
    if (!force && cached && age >= 0 && age < 60_000) return Promise.resolve(cached.value);
    const generation = this.rankedGeneration;
    const load = optionalApiResponse(
      Effect.runPromise(
        this.api.execute(ProxyLeagueGroupEndpoint, {
          path: { leagueGroupTag: group, seasonId: season },
          query: { playerTag: tag },
          body: {},
        }),
      ),
    )
      .then((value) => {
        if (generation === this.rankedGeneration) {
          if (this.rankedGroupCache.size >= 200)
            this.rankedGroupCache.delete(this.rankedGroupCache.keys().next().value!);
          this.rankedGroupCache.set(key, { value, at: Date.now() });
        }
        return value;
      })
      .finally(() => {
        if (this.rankedGroupLoads.get(key) === load) this.rankedGroupLoads.delete(key);
      });
    this.rankedGroupLoads.set(key, load);
    return load;
  }
  private async warmRankedHint(tag: string): Promise<void> {
    const generation = this.rankedGeneration;
    try {
      const raw = await this.storage?.getString(`rankedHint:v1:${tag}`);
      if (generation !== this.rankedGeneration) return;
      const hint: unknown = raw ? JSON.parse(raw) : null;
      if (
        !isRecord(hint) ||
        typeof hint.at !== 'number' ||
        Date.now() < hint.at ||
        Date.now() - hint.at > 30 * 60_000
      )
        return;
      if (
        typeof hint.group !== 'string' ||
        !/^#[A-Z0-9]+$/u.test(hint.group) ||
        !Number.isInteger(hint.season)
      )
        return;
      await this.loadRankedGroup(tag, hint.group, int(hint.season), false);
    } catch {
      // Hints are speculative only. The fresh profile remains authoritative.
    }
  }
  private async fetchRankedLeagueData(
    tag: string,
    scope: 'home' | 'detail',
    forceRefresh: boolean,
  ) {
    if (!forceRefresh) void this.warmRankedHint(tag);
    const player = await this.loadProfileJson(tag, undefined, forceRefresh),
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
    const loadGroup = (groupTag: string | null, seasonId: number) =>
      this.loadRankedGroup(tag, groupTag, seasonId, forceRefresh);
    const loadBattlelog = (groupTag: string | null, seasonId: number) =>
      scope === 'detail' && groupTag && seasonId > 0
        ? optionalApiResponse(
            Effect.runPromise(
              this.api.execute(RankedBattlelogEndpoint, {
                path: { playerTag: tag, seasonId: String(seasonId) },
                query: {},
                body: {},
              }),
            ),
          )
        : Promise.resolve(null);
    const [
      historyResponse,
      tiers,
      currentResponse,
      previousResponse,
      currentLog,
      previousLog,
      armyHistory,
    ] = await Promise.all([
      scope === 'detail'
        ? optionalApiResponse(
            Effect.runPromise(
              this.api.execute(ProxyPlayerLeagueHistoryEndpoint, {
                path: { playerTag: tag },
                query: {},
                body: {},
              }),
            ),
          )
        : Promise.resolve(null),
      scope === 'detail' || (currentTag && currentSeason > 0)
        ? this.loadLeagueTiers()
        : Promise.resolve(new Map<number, RankedLeagueTier>()),
      loadGroup(currentTag, currentSeason),
      scope === 'detail' ? loadGroup(previousTag, previousSeason) : Promise.resolve(null),
      loadBattlelog(currentTag, currentSeason),
      loadBattlelog(previousTag, previousSeason),
      scope === 'detail'
        ? this.loadRankedArmyHistory(tag, [currentSeason, previousSeason])
        : Promise.resolve([]),
    ]);
    const historyJson: JsonRecord = historyResponse
        ? (historyResponse as unknown as JsonRecord)
        : {},
      current =
        currentTag && currentResponse
          ? RankedLeagueGroup.fromJson(currentResponse as JsonRecord, currentTag, currentSeason)
          : null,
      previous =
        previousTag && previousResponse
          ? RankedLeagueGroup.fromJson(previousResponse as JsonRecord, previousTag, previousSeason)
          : null,
      history = records(historyJson.items)
        .map(RankedLeagueHistoryEntry.fromJson)
        .sort((a, b) => b.leagueSeasonId - a.leagueSeasonId);
    const currentBattlelog =
      parseRankedBattlelog(currentLog, tag, currentTag, currentSeason) ??
      (current && currentResponse
        ? RankedLeagueBattlelog.fromOfficialGroup(
            currentResponse as JsonRecord,
            tag,
            current,
            int(tierJson?.id),
          )
        : null);
    const previousBattlelog =
      parseRankedBattlelog(previousLog, tag, previousTag, previousSeason) ??
      (previous && previousResponse
        ? RankedLeagueBattlelog.fromOfficialGroup(
            previousResponse as JsonRecord,
            tag,
            previous,
            history.find((entry) => entry.leagueSeasonId === previousSeason)?.leagueTierId ?? 0,
          )
        : null);
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
      currentBattlelog?.withAttackArmies(armyHistory) ?? null,
      previousBattlelog?.withAttackArmies(armyHistory) ?? null,
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
    const json = await Effect.runPromise(
      this.api.execute(ProxyLeagueTiersEndpoint, { path: {}, query: {}, body: {} }),
    ).catch(() => null);
    if (json === null) return null;
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
        const json = await this.playerWarHistory(tag, { limit: 50 });
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
    const json = await this.playerWarHistory(normalized, filter);
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

  private playerWarHistory(tag: string, filter: Parameters<typeof playerWarHistoryQuery>[0]) {
    return Effect.runPromise(
      this.api.execute(PlayerWarStatsEndpoint, {
        path: { playerTag: tag },
        query: playerWarHistoryQuery(filter),
        body: {},
      }),
    );
  }
}

function enrichLegendOpponent(
  battle: PlayerLegendBattle,
  ranks: ReadonlyMap<string, PlayerLegendRank>,
  days: ReadonlyMap<string, number>,
) {
  if (battle.automatic || !battle.opponentTag) return battle;
  const opponentTag = canonicalTag(battle.opponentTag);
  const rank = ranks.get(opponentTag);
  const dayNetTrophies = days.get(opponentTag) ?? null;
  if (!rank && dayNetTrophies === null) return battle;
  return new PlayerLegendBattle(
    battle.trophies,
    battle.automatic,
    battle.battleTime,
    battle.duration,
    battle.townHallLevel,
    battle.opponentTag,
    battle.opponentName,
    battle.opponentTownHallLevel,
    battle.stars,
    battle.destructionPercentage,
    battle.shareCode,
    new PlayerLegendOpponentInsight(
      rank?.trophies ?? null,
      rank?.globalRank ?? null,
      dayNetTrophies,
    ),
    battle.familyId,
  );
}

function playerWarHistoryQuery(filter: {
  warType?: string;
  warTypes?: readonly string[] | null;
  startDate?: Date | null;
  endDate?: Date | null;
  limit: number;
}) {
  const query: { limit: number; type?: string; 'time[after]'?: string; 'time[before]'?: string } = {
    limit: Math.min(500, Math.max(1, filter.limit)),
  };
  const types = filter.warTypes?.filter((type) => type !== 'all') ?? [];
  const type =
    types.length === 1
      ? types[0]
      : filter.warType !== undefined && filter.warType !== 'all'
        ? filter.warType
        : null;
  if (type) query.type = type;
  if (filter.startDate) query['time[after]'] = filter.startDate.toISOString();
  if (filter.endDate) query['time[before]'] = filter.endDate.toISOString();
  return query;
}
function uniqueTags(tags: Iterable<string>) {
  return [...new Set([...tags].map(canonicalTag).filter(Boolean))];
}

function optionalApiResponse<T>(request: Promise<T>): Promise<T | null> {
  return request.catch((error: unknown) => {
    if (error instanceof ApiResponseError && error.status === 404) return null;
    throw error;
  });
}

function legendSource<T>(request: Promise<T | null>, fallback: T | null) {
  return request.then(
    (value) => ({ available: true, value: value ?? fallback }),
    () => ({ available: false, value: fallback }),
  );
}

function parseRankedBattlelog(
  response: unknown,
  playerTag: string,
  leagueGroupId: string | null,
  seasonId: number,
): RankedLeagueBattlelog | null {
  if (!isRecord(response)) return null;
  const battlelog = RankedLeagueBattlelog.fromJson(response);
  if (
    canonicalTag(battlelog.tag) !== canonicalTag(playerTag) ||
    battlelog.seasonId !== String(seasonId) ||
    (leagueGroupId !== null &&
      canonicalTag(battlelog.leagueGroupId) !== canonicalTag(leagueGroupId))
  ) {
    throw new TypeError('Ranked battlelog response does not match the requested player period.');
  }
  return battlelog;
}
