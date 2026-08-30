import {
  ApiClient,
  ApiException,
  ResponseFormatException,
  ServerException,
} from '../../../core/api/client';
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

const ALL_HTTP_STATUSES = Array.from({ length: 500 }, (_, index) => index + 100);
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
  private requestSequence = 0;
  private disposed = false;

  constructor(private readonly api: ApiClient) {}

  subscribe(listener: () => void): () => void {
    if (this.disposed) return () => undefined;
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  dispose(): void {
    this.disposed = true;
    this.listeners.clear();
  }

  loadAllWarData(
    clanTags: readonly string[],
    options: { notify?: boolean; throwOnError?: boolean } = {},
  ): Promise<void> {
    const tags = normalizeTags(clanTags);
    if (!tags.length) return Promise.resolve();
    const notify = options.notify ?? true;
    const throwOnError = options.throwOnError ?? false;
    const key = [...tags].sort().join(',');
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
    api: ApiClient,
    tag: string,
    end: Date,
  ): Promise<WarInfo | null> {
    const endTime = formatClashTime(end);
    const endpoint = `/war/${encodeURIComponent(tag)}/previous/${encodeURIComponent(endTime)}`;
    const response = await api.get(endpoint, { acceptedStatuses: ALL_HTTP_STATUSES });
    if (response.status === 404) return null;
    if (response.status !== 200) return null;
    const data = decodeRecord(response.bodyText, endpoint);
    return WarInfo.fromJson(data);
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
    const encoded = encodeURIComponent(clanTag);
    const endpoint = `/war/${encoded}/basic`;
    const response = await this.api.get(endpoint, { acceptedStatuses: ALL_HTTP_STATUSES });
    const basic =
      response.status === 200
        ? decodeNullableRecord(response.bodyText, endpoint)
        : response.status === 404
          ? null
          : unexpected(response.status, endpoint);

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
    const endpoint = `/clans/${encodeURIComponent(clanTag)}/currentwar`;
    const response = await this.api.proxyGet(endpoint, { acceptedStatuses: ALL_HTTP_STATUSES });
    if (response.status === 403) return new WarInfo('accessDenied');
    if (response.status === 404) return null;
    if (response.status !== 200) return unexpected(response.status, endpoint);
    const data = decodeNullableRecord(response.bodyText, endpoint);
    if (!data) return null;
    if (data.reason === 'accessDenied') return new WarInfo('accessDenied');
    return WarInfo.fromJson(data);
  }

  private async loadCwl(clanTag: string, preferredWarTag?: string | null): Promise<WarCwl | null> {
    const endpoint = `/clans/${encodeURIComponent(clanTag)}/currentwar/leaguegroup`;
    const response = await this.api.proxyGet(endpoint, { acceptedStatuses: ALL_HTTP_STATUSES });
    const group =
      response.status === 200
        ? decodeNullableRecord(response.bodyText, endpoint)
        : response.status === 403 || response.status === 404
          ? null
          : unexpected(response.status, endpoint);

    if (preferredWarTag) {
      const war = await this.fetchCwlWar(preferredWarTag);
      if (war && isFullWar(war)) return cwlResult(clanTag, group, [war.reorderForClan(clanTag)]);
    }
    if (!group || !Array.isArray(group.rounds)) return null;
    for (const round of records(group.rounds).reverse()) {
      const tags = (Array.isArray(round.warTags) ? round.warTags : [])
        .map(String)
        .filter((tag) => tag && tag !== '#0');
      if (!tags.length) continue;
      const wars = (await Promise.all(tags.map((tag) => this.fetchCwlWar(tag))))
        .filter((war): war is WarInfo => war !== null)
        .filter(isFullWar);
      const includesClan = wars.some(
        (war) =>
          normalizeWarTag(war.clan?.tag) === clanTag ||
          normalizeWarTag(war.opponent?.tag) === clanTag,
      );
      if (includesClan) return cwlResult(clanTag, group, wars);
    }
    return null;
  }

  private async fetchCwlWar(warTag: string): Promise<WarInfo | null> {
    const endpoint = `/clanwarleagues/wars/${encodeURIComponent(warTag)}`;
    const response = await this.api.proxyGet(endpoint, { acceptedStatuses: ALL_HTTP_STATUSES });
    if (response.status === 404) return null;
    if (response.status !== 200) return unexpected(response.status, endpoint);
    const data = decodeNullableRecord(response.bodyText, endpoint);
    if (!data) return null;
    return WarInfo.fromJson({ ...data, war_tag: warTag, warType: 'cwl' });
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

function unexpected(status: number, endpoint: string): never {
  const message = `Unexpected API status ${status} for ${endpoint}.`;
  if (status >= 500) throw new ServerException(message, status);
  throw new ApiException(message, status);
}

function decodeNullableRecord(body: string, endpoint: string): JsonRecord | null {
  let value: unknown;
  try {
    value = JSON.parse(body);
  } catch {
    throw new ResponseFormatException(`Invalid JSON response for ${endpoint}.`);
  }
  return isRecord(value) ? value : null;
}

function decodeRecord(body: string, endpoint: string): JsonRecord {
  const value = decodeNullableRecord(body, endpoint);
  if (!value) throw new ResponseFormatException(`Invalid response type for ${endpoint}.`);
  return value;
}

function formatClashTime(value: Date): string {
  const iso = value.toISOString();
  return `${iso.slice(0, 4)}${iso.slice(5, 7)}${iso.slice(8, 10)}T${iso.slice(11, 19).replaceAll(':', '')}.000Z`;
}
