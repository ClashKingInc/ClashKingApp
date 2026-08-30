import type { ApiClient, ApiResponse } from '../../../core/api/client';
import { gameDataState } from '../../../core/game-data/game-data-state';
import {
  STORAGE_KEYS,
  upgradeTrackerPreferencesStorageKey,
  upgradeTrackerSnapshotStorageKey,
} from '../../../core/storage/storage';
import type { StringStore } from '../../../services/storage/auth-storage';
import { UpgradePlanPreferences, type UpgradeTrackerSnapshot } from '../models';
import { UpgradeTrackerParser } from './upgrade-tracker-parser';

const ALL_HTTP_STATUSES = Array.from({ length: 500 }, (_, index) => index + 100);

export interface SavedUpgradeSnapshotAccount {
  readonly tag: string;
  readonly name: string;
  readonly townHallLevel: string;
  readonly builderHallLevel: string;
  readonly capturedAt: string;
}

export class UpgradeTrackerFormatError extends Error {
  constructor(
    message: string,
    readonly reason: 'invalid-account-json' | 'unlinked-account' = 'invalid-account-json',
  ) {
    super(message);
    this.name = 'UpgradeTrackerFormatError';
  }
}

export class UpgradeTrackerRepository {
  private readonly snapshotCache = new Map<string, UpgradeTrackerSnapshot>();
  private readonly snapshotLoads = new Map<string, Promise<UpgradeTrackerSnapshot | null>>();
  private remoteAccountId: string | null = null;
  private verifiedRemoteTags = new Set<string>();
  private cacheGeneration = 0;

  constructor(
    private readonly api: ApiClient,
    private readonly storage: StringStore,
    private readonly parser = new UpgradeTrackerParser(),
    private readonly bundleProvider: () => Record<string, unknown> = () => gameDataState.bundleData,
  ) {}

  configureRemote(options: { accountId: string | null; verifiedPlayerTags: Iterable<string> }) {
    const id = options.accountId?.trim() ?? '';
    this.remoteAccountId = id || null;
    this.verifiedRemoteTags = new Set(
      [...options.verifiedPlayerTags].map(UpgradeTrackerRepository.normalizeTag).filter(Boolean),
    );
  }

  clearCache() {
    this.snapshotCache.clear();
    this.snapshotLoads.clear();
    this.remoteAccountId = null;
    this.verifiedRemoteTags.clear();
    this.cacheGeneration += 1;
  }

  peekCached(playerTag: string) {
    return this.snapshotCache.get(UpgradeTrackerRepository.normalizeTag(playerTag)) ?? null;
  }

  async load(playerTag: string, forceRefresh = false): Promise<UpgradeTrackerSnapshot | null> {
    this.ensureStaticData();
    const normalized = UpgradeTrackerRepository.normalizeTag(playerTag);
    if (!forceRefresh) {
      const cached = this.snapshotCache.get(normalized);
      if (cached) return cached;
    }
    const pending = this.snapshotLoads.get(normalized);
    if (pending) return pending;
    const generation = this.cacheGeneration;
    const load = this.loadOnce(normalized, generation);
    this.snapshotLoads.set(normalized, load);
    try {
      return await load;
    } finally {
      if (this.snapshotLoads.get(normalized) === load) this.snapshotLoads.delete(normalized);
    }
  }

  private async loadOnce(normalized: string, generation: number) {
    const remote = await this.tryLoadRemoteSnapshot(normalized, generation);
    if (remote) return remote;
    const cached = this.snapshotCache.get(normalized);
    return cached ?? this.loadPersistedSnapshot(normalized, generation);
  }

  private async tryLoadRemoteSnapshot(normalized: string, generation: number) {
    if (!this.remoteAccountId || !this.verifiedRemoteTags.has(normalized)) return null;
    try {
      const remote = await this.loadRemoteSnapshot(normalized);
      if (!remote) return null;
      const parsed = this.parser.parse(remote, { staticData: this.bundleProvider() });
      if (generation === this.cacheGeneration) {
        await this.saveRawSnapshotLocally(normalized, remote, parsed);
      }
      return parsed;
    } catch {
      return null;
    }
  }

  private async loadPersistedSnapshot(normalized: string, generation: number) {
    const saved = await this.storage.getItem(upgradeTrackerSnapshotStorageKey(normalized));
    if (!saved) return null;
    const decoded: unknown = JSON.parse(saved);
    if (!isRecord(decoded)) return null;
    const parsed = this.parser.parse(decoded, { staticData: this.bundleProvider() });
    if (generation === this.cacheGeneration) this.snapshotCache.set(normalized, parsed);
    return parsed;
  }

  async saveRawSnapshot(
    playerTag: string,
    snapshot: Record<string, unknown>,
    parsedSnapshot?: UpgradeTrackerSnapshot,
  ) {
    const normalized = UpgradeTrackerRepository.normalizeTag(playerTag);
    if (!normalized) throw new UpgradeTrackerFormatError('Account JSON must include a player tag');
    await this.replaceRemoteSnapshot(normalized, snapshot);
    await this.saveRawSnapshotLocally(normalized, snapshot, parsedSnapshot);
  }

  private async saveRawSnapshotLocally(
    normalized: string,
    snapshot: Record<string, unknown>,
    parsedSnapshot?: UpgradeTrackerSnapshot,
  ) {
    await this.storage.setItem(
      upgradeTrackerSnapshotStorageKey(normalized),
      JSON.stringify(snapshot),
    );
    const parsed =
      parsedSnapshot ?? this.parser.parse(snapshot, { staticData: this.bundleProvider() });
    this.snapshotCache.set(normalized, parsed);
    const accounts = await this.savedSnapshotAccounts();
    const byTag = new Map(accounts.map((account) => [account.tag, account]));
    const name = String(snapshot.name ?? '').trim();
    byTag.set(normalized, {
      tag: normalized,
      name: name || 'Imported player',
      townHallLevel: String(parsed.townHallLevel),
      builderHallLevel: String(parsed.builderHallLevel),
      capturedAt: parsed.capturedAt.toISOString(),
    });
    await this.storage.setItem(
      STORAGE_KEYS.upgradeTrackerSnapshotIndex,
      JSON.stringify([...byTag.values()]),
    );
  }

  async importSnapshotBytes(
    bytes: Uint8Array | readonly number[],
    options: {
      linkedNamesByTag?: Readonly<Record<string, string>>;
      allowedTags?: ReadonlySet<string>;
    } = {},
  ) {
    let decoded: unknown;
    try {
      decoded = JSON.parse(new TextDecoder().decode(Uint8Array.from(bytes)));
    } catch {
      throw new UpgradeTrackerFormatError('Account data is not valid JSON');
    }
    if (!isRecord(decoded))
      throw new UpgradeTrackerFormatError('Account JSON must be one JSON object');
    const raw = unwrapSnapshot(decoded);
    const tag = UpgradeTrackerRepository.normalizeTag(String(raw.tag ?? ''));
    if (!tag) throw new UpgradeTrackerFormatError('Account JSON is missing its player tag');
    const allowed = new Set(
      [...(options.allowedTags ?? new Set<string>())]
        .map(UpgradeTrackerRepository.normalizeTag)
        .filter(Boolean),
    );
    if (!allowed.has(tag)) {
      throw new UpgradeTrackerFormatError(
        'This JSON does not match one of your linked accounts',
        'unlinked-account',
      );
    }
    raw.tag = tag;
    const linkedNames = new Map(
      Object.entries(options.linkedNamesByTag ?? {}).map(([key, value]) => [
        UpgradeTrackerRepository.normalizeTag(key),
        value,
      ]),
    );
    const linkedName = linkedNames.get(tag)?.trim();
    if (linkedName) raw.name = linkedName;
    this.ensureStaticData();
    let parsed: UpgradeTrackerSnapshot;
    try {
      parsed = this.parser.parse(raw, { staticData: this.bundleProvider() });
    } catch {
      throw new UpgradeTrackerFormatError('Account JSON could not be read');
    }
    if (parsed.townHallLevel === 0 && parsed.builderHallLevel === 0) {
      throw new UpgradeTrackerFormatError('This does not look like a raw Clash account snapshot');
    }
    this.cacheGeneration += 1;
    this.snapshotLoads.delete(tag);
    await this.saveRawSnapshot(tag, raw, parsed);
    return parsed;
  }

  async savedSnapshotAccounts(): Promise<SavedUpgradeSnapshotAccount[]> {
    const encoded = await this.storage.getItem(STORAGE_KEYS.upgradeTrackerSnapshotIndex);
    if (!encoded) return [];
    const decoded: unknown = JSON.parse(encoded);
    if (!Array.isArray(decoded)) return [];
    return decoded.flatMap((value) => {
      if (!isRecord(value) || !String(value.tag ?? '')) return [];
      return [
        {
          tag: String(value.tag),
          name: String(value.name ?? ''),
          townHallLevel: String(value.townHallLevel ?? ''),
          builderHallLevel: String(value.builderHallLevel ?? ''),
          capturedAt: String(value.capturedAt ?? ''),
        },
      ];
    });
  }

  async loadSavedSnapshots(playerTags: Iterable<string>) {
    const snapshots: UpgradeTrackerSnapshot[] = [];
    for (const playerTag of playerTags) {
      const normalized = UpgradeTrackerRepository.normalizeTag(playerTag);
      const cached = this.snapshotCache.get(normalized);
      if (cached) {
        snapshots.push(cached);
        continue;
      }
      const saved = await this.storage.getItem(upgradeTrackerSnapshotStorageKey(normalized));
      if (!saved) continue;
      const decoded: unknown = JSON.parse(saved);
      if (isRecord(decoded)) {
        const parsed = this.parser.parse(decoded, { staticData: this.bundleProvider() });
        this.snapshotCache.set(normalized, parsed);
        snapshots.push(parsed);
      }
    }
    return snapshots;
  }

  async loadPlanPreferences(playerTag: string): Promise<Record<string, unknown> | null> {
    const normalized = UpgradeTrackerRepository.normalizeTag(playerTag);
    if (this.remoteAccountId && this.verifiedRemoteTags.has(normalized)) {
      try {
        const response = await this.api.get(
          this.remoteEndpoint(normalized, 'upgrade-preferences'),
          {
            requiresAuth: true,
            acceptedStatuses: ALL_HTTP_STATUSES,
          },
        );
        if (isSuccess(response)) {
          const decoded = parseRecord(response.bodyText);
          if (isRecord(decoded.preferences)) {
            await this.savePlanPreferencesLocally(normalized, decoded.preferences);
            return decoded.preferences;
          }
        }
      } catch {
        // The on-device preferences remain the offline fallback.
      }
    }
    const encoded = await this.storage.getItem(upgradeTrackerPreferencesStorageKey(normalized));
    if (!encoded) return null;
    const decoded: unknown = JSON.parse(encoded);
    return isRecord(decoded) ? decoded : null;
  }

  async savePlanPreferences(
    playerTag: string,
    goldPassPercent: number,
    strategy: string,
    preferences = new UpgradePlanPreferences(),
  ) {
    const normalized = UpgradeTrackerRepository.normalizeTag(playerTag);
    const value = {
      gold_pass_percent: goldPassPercent,
      strategy,
      heuristics: preferences.toJson(),
    };
    if (this.remoteAccountId) {
      this.requireVerifiedRemoteTag(normalized);
      const response = await this.api.patch(
        this.remoteEndpoint(normalized, 'upgrade-preferences'),
        {
          body: { preferences: value },
          requiresAuth: true,
          acceptedStatuses: ALL_HTTP_STATUSES,
        },
      );
      if (!isSuccess(response))
        throw new Error(`Could not save upgrade preferences (${response.status})`);
    }
    await this.savePlanPreferencesLocally(normalized, value);
  }

  private async loadRemoteSnapshot(normalized: string) {
    const response = await this.api.get(this.remoteEndpoint(normalized, 'upgrades'), {
      requiresAuth: true,
      acceptedStatuses: ALL_HTTP_STATUSES,
    });
    if (!isSuccess(response)) return null;
    const decoded = parseRecord(response.bodyText);
    return isRecord(decoded.data) && Object.keys(decoded.data).length ? decoded.data : null;
  }

  private async replaceRemoteSnapshot(normalized: string, snapshot: Record<string, unknown>) {
    if (!this.remoteAccountId) return;
    this.requireVerifiedRemoteTag(normalized);
    const response = await this.api.put(this.remoteEndpoint(normalized, 'upgrades'), {
      body: { data: snapshot },
      requiresAuth: true,
      acceptedStatuses: ALL_HTTP_STATUSES,
    });
    if (!isSuccess(response)) throw new Error(`Could not save upgrade data (${response.status})`);
  }

  private savePlanPreferencesLocally(normalized: string, value: Record<string, unknown>) {
    return this.storage.setItem(
      upgradeTrackerPreferencesStorageKey(normalized),
      JSON.stringify(value),
    );
  }
  private remoteEndpoint(tag: string, resource: string) {
    return `/links/${encodeURIComponent(this.remoteAccountId!)}/${encodeURIComponent(tag)}/${resource}`;
  }
  private requireVerifiedRemoteTag(tag: string) {
    if (!this.verifiedRemoteTags.has(tag))
      throw new Error('Upgrade data is limited to verified linked accounts');
  }
  private ensureStaticData() {
    if (Object.keys(this.bundleProvider()).length === 0)
      throw new Error('Static game data was not loaded during app startup');
  }

  static normalizeTag(value: string) {
    const tag = value.replaceAll('#', '').trim().toUpperCase();
    return tag ? `#${tag}` : '';
  }
}

function unwrapSnapshot(decoded: Record<string, unknown>) {
  if (decoded.tag != null) return { ...decoded };
  for (const key of ['player', 'account', 'data', 'snapshot']) {
    const nested = decoded[key];
    if (isRecord(nested) && nested.tag != null) return { ...nested };
  }
  return { ...decoded };
}
function isSuccess(response: ApiResponse) {
  return response.status >= 200 && response.status < 300;
}
function parseRecord(body: string) {
  const value: unknown = JSON.parse(body);
  if (!isRecord(value)) throw new TypeError('Invalid upgrade response');
  return value;
}
function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
