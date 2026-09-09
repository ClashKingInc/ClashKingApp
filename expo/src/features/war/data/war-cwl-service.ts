import {
  StoredCwlGroupEndpoint,
  WarBasicEndpoint,
  WarPreviousEndpoint,
} from '@clashking/api-contracts/expo';
import {
  ProxyCurrentLeagueGroupEndpoint,
  ProxyCurrentWarEndpoint,
  ProxyCwlWarEndpoint,
} from '../../../core/api/proxy-contracts';
import { Effect } from 'effect';

import type { ContractApiService } from '../../../core/api/contract-api';
import {
  CwlLeague,
  WarCwl,
  WarInfo,
  isRecord,
  normalizeWarTag,
  record,
  records,
  string,
  type JsonRecord,
} from '../models';

import { enrichCwlDetail } from '../models/cwl-detail';

const MAX_BATCH_SIZE = 100;

interface WarLoadOutcome {
  readonly changed: boolean;
  readonly errors: readonly unknown[];
}

interface InFlightWarLoad {
  readonly future: Promise<WarLoadOutcome>;
  shouldNotify: boolean;
}

export class WarCwlService {
  readonly summaries = new Map<string, WarCwl>();
  private readonly inFlightLoads = new Map<string, InFlightWarLoad>();
  private readonly latestRequestByTag = new Map<string, number>();
  private readonly listeners = new Set<() => void>();
  private readonly detailSnapshots = new Map<string, WarCwl>();
  private readonly detailLoads = new Map<string, Promise<WarCwl>>();
  private requestSequence = 0;
  private disposed = false;

  constructor(private readonly api: ContractApiService) {}

  subscribe(listener: () => void): () => void {
    if (this.disposed) return () => undefined;
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  dispose(): void {
    this.disposed = true;
    this.listeners.clear();
    this.detailSnapshots.clear();
  }

  loadAllWarData(
    clanTags: readonly string[],
    options: { notify?: boolean; throwOnError?: boolean } = {},
  ): Promise<void> {
    const tags = normalizeTags(clanTags);
    if (!tags.length) return Promise.resolve();
    const notify = options.notify ?? true;
    const throwOnError = options.throwOnError ?? false;
    const key = [...tags].sort((left, right) => left.localeCompare(right)).join(',');
    const existing = this.inFlightLoads.get(key);
    if (existing) {
      existing.shouldNotify ||= notify;
      return this.applyErrorPolicy(existing.future, throwOnError);
    }

    const requestId = ++this.requestSequence;
    for (const tag of tags) this.latestRequestByTag.set(tag, requestId);
    let load!: InFlightWarLoad;
    const future = this.loadWarData(tags, requestId)
      .then((outcome) => {
        if (outcome.changed && load.shouldNotify) this.notify();
        return outcome;
      })
      .finally(() => {
        if (this.inFlightLoads.get(key) === load) this.inFlightLoads.delete(key);
      });
    load = { future, shouldNotify: notify };
    this.inFlightLoads.set(key, load);
    return this.applyErrorPolicy(future, throwOnError);
  }

  getWarCwlByTag(tag: string): WarCwl | null {
    const normalized = normalizeWarTag(tag);
    return normalized ? (this.summaries.get(normalized) ?? null) : null;
  }

  processBulkWarData(warData: readonly unknown[], options: { notify?: boolean } = {}): void {
    let changed = false;
    for (const item of warData) {
      const summary = parseWarSummary(item);
      if (!summary) continue;
      this.summaries.set(summary.tag, summary);
      changed = true;
    }
    if (changed && (options.notify ?? true)) this.notify();
  }

  notifyDataChanged(): void {
    this.notify();
  }

  static async fetchWarDataFromTime(
    api: ContractApiService,
    tag: string,
    end: Date,
  ): Promise<WarInfo | null> {
    const endTime = formatClashTime(end);
    const response = await Effect.runPromise(
      api.executeStatus(WarPreviousEndpoint, {
        path: { clanTag: tag, endTime },
        query: {},
        body: {},
      }),
    );
    return response.ok
      ? WarInfo.fromJson({ ...response.value, war_tag: response.value.tag })
      : null;
  }

  getCwlDetail(tag: string, season: string): WarCwl | undefined {
    return this.detailSnapshots.get(`${tag}:${season}`);
  }

  /** Detail needs every matchup; keep the home summary's small request budget separate. */
  loadCwlDetail(tag: string, season: string): Promise<WarCwl> {
    const key = `${tag}:${season}`;
    const existing = this.detailLoads.get(key);
    if (existing) return existing;
    const future = this.fetchCwlDetail(tag, season)
      .then((summary) => {
        if (!this.disposed) {
          this.detailSnapshots.delete(key);
          this.detailSnapshots.set(key, summary);
          if (this.detailSnapshots.size > 16)
            this.detailSnapshots.delete(this.detailSnapshots.keys().next().value!);
        }
        return summary;
      })
      .finally(() => this.detailLoads.delete(key));
    this.detailLoads.set(key, future);
    return future;
  }

  private async fetchCwlDetail(tag: string, season: string): Promise<WarCwl> {
    const response = await Effect.runPromise(
      this.api.executeStatus(ProxyCurrentLeagueGroupEndpoint, {
        path: { clanTag: tag },
        query: {},
        body: {},
      }),
    );
    if (!response.ok || response.value.season !== season) {
      return (await this.loadLinkedCwl(tag, season)).summary;
    }
    const group = response.value;
    const tags = [
      ...new Set(
        records(group.rounds).flatMap((round) =>
          (Array.isArray(round.warTags) ? round.warTags : [])
            .map(String)
            .filter((warTag) => warTag && warTag !== '#0'),
        ),
      ),
    ];
    if (tags.length > 64) throw new Error('CWL group contains too many wars');
    const wars: WarInfo[] = [];
    for (let index = 0; index < tags.length; index += 8) {
      const batch = await Promise.all(
        tags.slice(index, index + 8).map((warTag) => this.fetchCwlWar(warTag)),
      );
      if (batch.some((war) => !war || !isFullWar(war))) throw new Error('CWL round unavailable');
      wars.push(...(batch as WarInfo[]));
    }
    return new WarCwl(
      tag,
      false,
      true,
      new WarInfo('notInWar'),
      enrichCwlDetail(group, wars),
      wars,
    );
  }

  /** Stored groups contain hydrated wars inside each round, unlike the live proxy. */
  async loadLinkedCwl(
    tag: string,
    season?: string,
  ): Promise<{ summary: WarCwl; warLeagueName?: string }> {
    const response = await Effect.runPromise(
      this.api.executeStatus(StoredCwlGroupEndpoint, {
        path: { tag },
        query: season ? { season } : {},
        body: {},
      }),
    );
    if (!response.ok && response.status === 404 && !season) {
      await this.loadAllWarData([tag], { throwOnError: true });
      const live = this.getWarCwlByTag(tag);
      if (live?.isInCwl && live.leagueInfo) return { summary: live };
    }
    if (!response.ok) throw new Error('Requested CWL season unavailable');
    const group = response.value;
    if (season && string(group.season) !== season)
      throw new Error('Requested CWL season unavailable');
    const wars: WarInfo[] = [];
    const rounds = records(group.rounds).map((round) => ({
      warTags: records(round.warTags).map((item) => {
        if (item.clan && item.opponent)
          wars.push(WarInfo.fromJson({ ...item, war_tag: item.tag, warType: 'cwl' }));
        return string(item.tag);
      }),
    }));
    const missingTags = [...new Set(rounds.flatMap((round) => round.warTags))].filter(
      (warTag) => warTag && warTag !== '#0' && !wars.some((war) => war.tag === warTag),
    );
    if (missingTags.length) throw new Error('Stored CWL round unavailable');
    const summary = new WarCwl(
      tag,
      false,
      true,
      new WarInfo('notInWar'),
      enrichCwlDetail({ ...group, rounds }, wars),
      wars,
    );
    if (
      !summary.leagueInfo?.clans.some((clan) => normalizeWarTag(clan.tag) === normalizeWarTag(tag))
    ) {
      throw new Error('CWL group does not contain requested clan');
    }
    const warLeagueName = string(record(group.warLeague).name);
    return { summary, ...(warLeagueName ? { warLeagueName } : {}) };
  }

  private async loadWarData(tags: readonly string[], requestId: number): Promise<WarLoadOutcome> {
    let changed = false;
    const errors: unknown[] = [];
    for (let start = 0; start < tags.length; start += MAX_BATCH_SIZE) {
      const batch = tags.slice(start, Math.min(start + MAX_BATCH_SIZE, tags.length));
      const result = await this.loadWarBatch(batch);
      changed = this.applyWarBatch(result.summaries, requestId) || changed;
      errors.push(...result.errors);
    }
    return { changed, errors };
  }

  private async loadWarBatch(tags: readonly string[]) {
    const outcomes = await Promise.all(
      tags.map(async (tag) => {
        try {
          return { summary: await this.resolveCurrentWar(tag), error: null };
        } catch (error) {
          return { summary: null, error };
        }
      }),
    );
    return {
      summaries: outcomes
        .map(({ summary }) => summary)
        .filter((summary): summary is WarCwl => summary !== null),
      errors: outcomes.map(({ error }) => error).filter((error) => error !== null),
    };
  }

  private async resolveCurrentWar(clanTag: string): Promise<WarCwl> {
    const response = await Effect.runPromise(
      this.api.executeStatus(WarBasicEndpoint, { path: { clanTag }, query: {}, body: {} }),
    );
    const basic = response.ok ? response.value : null;

    if (basic && Object.keys(basic).length) {
      const type = string(basic.type).toLowerCase();
      const warTag = basic.warTag == null ? null : string(basic.warTag);
      if (type.includes('cwl') || type.includes('league')) {
        const cwl = await this.loadCwl(clanTag, warTag);
        if (cwl) return cwl;
      } else {
        return this.loadScheduledRegularWar(clanTag, basic);
      }
    }
    return this.loadManualCurrentWar(clanTag);
  }

  private async loadScheduledRegularWar(clanTag: string, basic: JsonRecord): Promise<WarCwl> {
    const left = record(basic.clan);
    const right = record(basic.opponent);
    const leftTag = normalizeWarTag(string(left.tag));
    const rightTag = normalizeWarTag(string(right.tag));
    const requestedIsRight = rightTag === clanTag;
    const requested = requestedIsRight ? right : left;
    const opponent = requestedIsRight ? left : right;
    const opponentTag = requestedIsRight ? leftTag : rightTag;
    const candidates = [
      ...(requested.publicWarLog !== false ? [clanTag] : []),
      ...(opponentTag && opponent.publicWarLog !== false ? [opponentTag] : []),
    ];
    for (const candidate of candidates) {
      const war = await this.fetchRegularWar(candidate);
      if (war && isFullWar(war)) return regularResult(clanTag, war.reorderForClan(clanTag));
    }
    return privateResult(clanTag);
  }

  private async loadManualCurrentWar(clanTag: string): Promise<WarCwl> {
    const regular = await this.fetchRegularWar(clanTag);
    if (regular && isFullWar(regular))
      return regularResult(clanTag, regular.reorderForClan(clanTag));
    const cwl = await this.loadCwl(clanTag);
    if (cwl) return cwl;
    return regular?.state === 'accessDenied' ? privateResult(clanTag) : notInWarResult(clanTag);
  }

  private async fetchRegularWar(clanTag: string): Promise<WarInfo | null> {
    const response = await Effect.runPromise(
      this.api.executeStatus(ProxyCurrentWarEndpoint, { path: { clanTag }, query: {}, body: {} }),
    );
    if (!response.ok) return response.status === 403 ? new WarInfo('accessDenied') : null;
    return WarInfo.fromJson(response.value);
  }

  private async loadCwl(clanTag: string, preferredWarTag?: string | null): Promise<WarCwl | null> {
    const response = await Effect.runPromise(
      this.api.executeStatus(ProxyCurrentLeagueGroupEndpoint, {
        path: { clanTag },
        query: {},
        body: {},
      }),
    );
    const group = response.ok ? response.value : null;

    const fetched = new Map<string, Promise<WarInfo | null>>();
    const fetchWar = (tag: string) => {
      if (!fetched.has(tag)) fetched.set(tag, this.fetchCwlWar(tag));
      return fetched.get(tag)!;
    };
    const matchesClan = (war: WarInfo) =>
      normalizeWarTag(war.clan?.tag) === clanTag || normalizeWarTag(war.opponent?.tag) === clanTag;
    let fallback: WarInfo[] = [];
    if (preferredWarTag) {
      const war = await fetchWar(preferredWarTag);
      if (war && isFullWar(war) && matchesClan(war)) {
        if (war.state === 'inWar') return cwlResult(clanTag, group, [war.reorderForClan(clanTag)]);
        fallback = [war.reorderForClan(clanTag)];
      }
    }
    if (!group || !Array.isArray(group.rounds))
      return fallback.length ? cwlResult(clanTag, group, fallback) : null;
    for (const round of records(group.rounds).reverse()) {
      const tags = (Array.isArray(round.warTags) ? round.warTags : [])
        .map(String)
        .filter((tag) => tag && tag !== '#0');
      if (!tags.length) continue;
      const wars = (await Promise.all(tags.map(fetchWar)))
        .filter((war): war is WarInfo => war !== null)
        .filter(isFullWar);
      const ourWar = wars.find(matchesClan);
      if (!ourWar) continue;
      if (ourWar.state === 'inWar') return cwlResult(clanTag, group, wars);
      if (!fallback.length) fallback = wars;
      // Once an ended round is reached there cannot be an older active round.
      if (ourWar.state === 'warEnded') break;
    }
    return fallback.length ? cwlResult(clanTag, group, fallback) : null;
  }

  private async fetchCwlWar(warTag: string): Promise<WarInfo | null> {
    const response = await Effect.runPromise(
      this.api.executeStatus(ProxyCwlWarEndpoint, { path: { warTag }, query: {}, body: {} }),
    );
    if (!response.ok) return null;
    return WarInfo.fromJson({ ...response.value, war_tag: warTag, warType: 'cwl' });
  }

  private applyWarBatch(summaries: readonly WarCwl[], requestId: number): boolean {
    let changed = false;
    for (const summary of summaries) {
      if (this.latestRequestByTag.get(summary.tag) !== requestId) continue;
      this.summaries.set(summary.tag, summary);
      changed = true;
    }
    return changed;
  }

  private async applyErrorPolicy(future: Promise<WarLoadOutcome>, throwOnError: boolean) {
    const outcome = await future;
    if (throwOnError && outcome.errors.length) throw outcome.errors[0];
  }

  private notify(): void {
    if (!this.disposed) for (const listener of this.listeners) listener();
  }
}

function normalizeTags(tags: readonly string[]): string[] {
  return [...new Set(tags.map(normalizeWarTag).filter((tag): tag is string => tag !== null))];
}

function isFullWar(war: WarInfo): boolean {
  return (
    war.state !== 'notInWar' &&
    war.state !== 'unknown' &&
    war.state !== 'accessDenied' &&
    war.clan !== null &&
    war.opponent !== null
  );
}

function regularResult(tag: string, war: WarInfo): WarCwl {
  return new WarCwl(tag, true, false, war, null, []);
}
function privateResult(tag: string): WarCwl {
  return new WarCwl(tag, false, false, new WarInfo('accessDenied'), null, []);
}
function notInWarResult(tag: string): WarCwl {
  return new WarCwl(tag, false, false, new WarInfo('notInWar'), null, []);
}
function cwlResult(tag: string, group: JsonRecord | null, wars: readonly WarInfo[]): WarCwl {
  return new WarCwl(
    tag,
    false,
    true,
    new WarInfo('notInWar'),
    group ? CwlLeague.fromJson(group) : null,
    wars,
  );
}

function parseWarSummary(value: unknown): WarCwl | null {
  if (!isRecord(value)) return null;
  try {
    const tag = normalizeWarTag(value.clan_tag == null ? null : string(value.clan_tag));
    if (!tag) return null;
    if (value.war_info != null && !isRecord(value.war_info)) return null;
    if (value.war_league_infos != null && !Array.isArray(value.war_league_infos)) return null;
    return WarCwl.fromJson({ ...value, clan_tag: tag }, tag);
  } catch {
    return null;
  }
}

function formatClashTime(value: Date): string {
  const iso = value.toISOString();
  return `${iso.slice(0, 4)}${iso.slice(5, 7)}${iso.slice(8, 10)}T${iso.slice(11, 19).replaceAll(':', '')}.000Z`;
}
