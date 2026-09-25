import { normalizeTag } from '@/core/domain/tags';
import { STORAGE_KEYS, type StringStorage } from '@/core/storage/storage';
import { PlayerCardOptions } from '../models/player-support';
import { isRecord } from '../models/parsing';

export class PlayerCardPreferencesService {
  private loadedValue = false;
  private readonly options = new Map<string, PlayerCardOptions>();
  private readonly listeners = new Set<() => void>();
  private homeIncluded: readonly string[] | null = null;
  private homeWrite = Promise.resolve();
  constructor(private readonly storage: StringStorage) {}
  get loaded() {
    return this.loadedValue;
  }
  subscribe(listener: () => void) {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }
  private notify() {
    for (const listener of this.listeners) listener();
  }
  optionsFor(tag: string) {
    return this.options.get(normalizeTag(tag)) ?? new PlayerCardOptions();
  }
  isShownInWarTab(tag: string) {
    return this.optionsFor(tag).showInWarTab;
  }
  isShownInTodoPage(tag: string) {
    return this.optionsFor(tag).showInTodoPage;
  }
  isUpgradeTrackerShownOnHome(tag: string) {
    return this.optionsFor(tag).showUpgradeTrackerOnHome;
  }
  isRankedShownOnHome(tag: string) {
    return this.optionsFor(tag).showRankedOnHome;
  }
  clear() {
    this.options.clear();
    this.homeIncluded = null;
    this.loadedValue = false;
    this.notify();
  }
  async load() {
    const [raw, homeRaw] = await Promise.all([
      this.storage.getString(STORAGE_KEYS.playerCardOptions),
      this.storage.getString(STORAGE_KEYS.homeIncludedAccounts),
    ]);
    this.options.clear();
    if (raw)
      try {
        const decoded: unknown = JSON.parse(raw);
        if (isRecord(decoded))
          for (const [tag, value] of Object.entries(decoded))
            if (isRecord(value)) this.options.set(tag, PlayerCardOptions.fromJson(value));
      } catch {
        /* malformed preferences are intentionally ignored */
      }
    this.homeIncluded = null;
    if (homeRaw)
      try {
        const decoded: unknown = JSON.parse(homeRaw);
        if (Array.isArray(decoded))
          this.homeIncluded = decoded.filter((tag): tag is string => typeof tag === 'string');
      } catch {
        /* malformed Home preferences fall back to verified accounts */
      }
    this.loadedValue = true;
    this.notify();
  }
  homeIncludedTags(
    verifiedTags: readonly string[],
    selectedTag?: string | null,
  ): readonly string[] {
    const storedHasNoCurrentAccount =
      this.homeIncluded !== null &&
      this.homeIncluded.length > 0 &&
      !this.homeIncluded.some((tag) =>
        verifiedTags.some((verified) => normalizeTag(verified) === normalizeTag(tag)),
      );
    return normalizeHomeIncludedTags(
      this.homeIncluded === null || storedHasNoCurrentAccount ? verifiedTags : this.homeIncluded,
      verifiedTags,
      selectedTag,
      this.homeIncluded === null ||
        storedHasNoCurrentAccount ||
        this.homeIncluded.length > MAX_HOME_ACCOUNTS,
    );
  }
  isShownOnHome(
    tag: string,
    verifiedTags: readonly string[],
    selectedTag?: string | null,
  ): boolean {
    return this.homeIncludedTags(verifiedTags, selectedTag).includes(normalizeTag(tag));
  }
  async reconcileHomeIncluded(
    verifiedTags: readonly string[],
    selectedTag?: string | null,
  ): Promise<void> {
    if (verifiedTags.length === 0) return;
    const normalized = this.homeIncludedTags(verifiedTags, selectedTag);
    if (this.homeIncluded !== null && arraysEqual(this.homeIncluded, normalized)) return;
    this.homeIncluded = normalized;
    this.notify();
    await this.persistHomeIncluded();
  }
  async setShownOnHome(
    tag: string,
    enabled: boolean,
    verifiedTags: readonly string[],
    selectedTag?: string | null,
  ): Promise<void> {
    const key = normalizeTag(tag);
    const available = new Set(verifiedTags.map(normalizeTag).filter(Boolean));
    if (!available.has(key)) return;
    const current = this.homeIncludedTags(verifiedTags, selectedTag);
    if ((enabled && current.includes(key)) || (!enabled && !current.includes(key))) return;
    if (enabled && current.length >= MAX_HOME_ACCOUNTS) throw new HomeAccountLimitError();
    this.homeIncluded = enabled ? [...current, key] : current.filter((item) => item !== key);
    this.notify();
    await this.persistHomeIncluded();
  }
  private persistHomeIncluded(): Promise<void> {
    const value = JSON.stringify(this.homeIncluded);
    this.homeWrite = this.homeWrite
      .catch(() => undefined)
      .then(() => this.storage.setString(STORAGE_KEYS.homeIncludedAccounts, value));
    return this.homeWrite;
  }
  setShowInWarTab(tag: string, value: boolean) {
    return this.update(tag, (item) => item.copyWith({ showInWarTab: value }));
  }
  setShowInTodoPage(tag: string, value: boolean) {
    return this.update(tag, (item) => item.copyWith({ showInTodoPage: value }));
  }
  setShowUpgradeTrackerOnHome(tag: string, value: boolean) {
    return this.update(tag, (item) => item.copyWith({ showUpgradeTrackerOnHome: value }));
  }
  setShowRankedOnHome(tag: string, value: boolean) {
    return this.update(tag, (item) => item.copyWith({ showRankedOnHome: value }));
  }
  private async update(tag: string, transform: (value: PlayerCardOptions) => PlayerCardOptions) {
    const key = normalizeTag(tag),
      updated = transform(this.options.get(key) ?? new PlayerCardOptions());
    if (updated.isDefault) this.options.delete(key);
    else this.options.set(key, updated);
    this.notify();
    await this.storage.setString(
      STORAGE_KEYS.playerCardOptions,
      JSON.stringify(
        Object.fromEntries([...this.options].map(([key, value]) => [key, value.toJson()])),
      ),
    );
  }
}

export const MAX_HOME_ACCOUNTS = 5;

export class HomeAccountLimitError extends Error {
  constructor() {
    super('Home can include at most five accounts.');
    this.name = 'HomeAccountLimitError';
  }
}

export function normalizeHomeIncludedTags(
  stored: unknown,
  verifiedTags: readonly string[],
  selectedTag?: string | null,
  prioritizeSelected = false,
): string[] {
  const available = new Set(verifiedTags.map(normalizeTag).filter(Boolean));
  const normalized: string[] = [];
  if (Array.isArray(stored))
    for (const value of stored) {
      if (typeof value !== 'string') continue;
      const key = normalizeTag(value);
      if (available.has(key) && !normalized.includes(key)) normalized.push(key);
    }
  const selected = selectedTag ? normalizeTag(selectedTag) : '';
  if (
    prioritizeSelected &&
    selected &&
    available.has(selected) &&
    normalized.includes(selected) &&
    normalized.indexOf(selected) >= MAX_HOME_ACCOUNTS
  ) {
    normalized.splice(MAX_HOME_ACCOUNTS - 1, 1, selected);
  }
  return normalized.slice(0, MAX_HOME_ACCOUNTS);
}

function arraysEqual(left: readonly string[], right: readonly string[]): boolean {
  return left.length === right.length && left.every((value, index) => value === right[index]);
}
