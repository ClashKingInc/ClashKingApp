import { normalizeTag } from '@/core/domain/tags';
import { STORAGE_KEYS, type StringStorage } from '@/core/storage/storage';
import { PlayerCardOptions } from '../models/player-support';
import { isRecord } from '../models/parsing';

export class PlayerCardPreferencesService {
  private loadedValue = false;
  private readonly options = new Map<string, PlayerCardOptions>();
  private readonly listeners = new Set<() => void>();
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
    this.notify();
  }
  async load() {
    const raw = await this.storage.getString(STORAGE_KEYS.playerCardOptions);
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
    this.loadedValue = true;
    this.notify();
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
