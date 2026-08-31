import {
  STORAGE_KEYS,
  WIDGET_STORAGE_KEYS,
  playerClanTagStorageKey,
  warWidgetInfoStorageKey,
} from '../../core/storage/storage';
import { APP_FEATURE_FLAGS, defaultFeatureFlagValue } from '../../core/feature-flags/feature-flags';
import type {
  WarWidgetBookmarkedClan,
  WarWidgetClanOption,
  WarWidgetPlayerProfile,
  WarWidgetServiceOptions,
  WidgetMigrationResult,
  WidgetPinRequestResult,
} from './contracts';
import {
  buildNotInClanWidgetPayload,
  buildWarWidgetErrorPayload,
  buildWarWidgetPayload,
} from './war-widget-payload';

export const WAR_WIDGET_BACKGROUND_TASK = 'simplePeriodicTask';
export const WAR_WIDGET_MANUAL_TASK = 'refreshWarWidget';
export const WAR_WIDGET_REFRESH_ACTION = 'warWidget://refreshClicked';
const PERIODIC_REFRESH_MINUTES = 15;
const LEGACY_WIDGET_MIGRATION_MARKER = 'legacy_home_widget_migration_v1';

export function normalizedClanTag(tag: string): string {
  return tag.replaceAll('#', '').toUpperCase();
}

export function warInfoKeyForClan(tag: string): string {
  return warWidgetInfoStorageKey(normalizedClanTag(tag));
}

export function clanOptionsFromProfiles(
  profiles: readonly WarWidgetPlayerProfile[],
  bookmarkedClans: readonly WarWidgetBookmarkedClan[] = [],
): WarWidgetClanOption[] {
  const byTag = new Map<string, WarWidgetClanOption>();
  for (const player of profiles) {
    const clan = player.clanOverview;
    if (!clan.tag || !clan.name) continue;
    byTag.set(normalizedClanTag(clan.tag), {
      tag: clan.tag,
      name: clan.name,
      ...(clan.badgeUrls.small || clan.badgeUrls.medium || clan.badgeUrls.large
        ? { badgeUrl: clan.badgeUrls.small || clan.badgeUrls.medium || clan.badgeUrls.large }
        : undefined),
    });
  }
  for (const clan of bookmarkedClans) {
    if (!clan.tag || !clan.name) continue;
    const key = normalizedClanTag(clan.tag);
    if (!byTag.has(key)) {
      byTag.set(key, {
        tag: clan.tag,
        name: clan.name,
        ...(clan.badgeUrl ? { badgeUrl: clan.badgeUrl } : undefined),
      });
    }
  }
  return [...byTag.values()].sort((left, right) => compareNames(left.name, right.name));
}

export function selectedClanTagFromProfiles(
  profiles: readonly WarWidgetPlayerProfile[],
  selectedPlayerTag: string | null,
): string | null {
  if (!selectedPlayerTag) return null;
  const selected = selectedPlayerTag.replaceAll('#', '');
  return (
    profiles.find(
      (player) => player.tag.replaceAll('#', '') === selected && Boolean(player.clanOverview.tag),
    )?.clanOverview.tag ?? null
  );
}

export class WarWidgetService {
  private readonly summaryLoads = new Map<string, Promise<string>>();

  constructor(private readonly options: WarWidgetServiceOptions) {}

  async areWarWidgetsEnabled(): Promise<boolean> {
    try {
      await this.options.featureFlags.refresh();
    } catch {
      // Flutter deliberately fails open when remote config is unavailable.
    }
    return this.options.featureFlags.isEnabled(
      APP_FEATURE_FLAGS.warWidgets,
      defaultFeatureFlagValue(APP_FEATURE_FLAGS.warWidgets),
    );
  }

  async registerPeriodicRefresh(): Promise<void> {
    if (this.options.platform !== 'android') return;
    if (this.options.backgroundScheduler === undefined) {
      throw new Error('Android war-widget background scheduler is not configured.');
    }
    await this.options.backgroundScheduler.registerPeriodicTask(
      WAR_WIDGET_BACKGROUND_TASK,
      PERIODIC_REFRESH_MINUTES,
    );
  }

  async executeBackgroundTask(taskName: string): Promise<boolean> {
    try {
      if (taskName !== WAR_WIDGET_BACKGROUND_TASK && taskName !== WAR_WIDGET_MANUAL_TASK) {
        return true;
      }
      if (!(await this.areWarWidgetsEnabled())) return true;
      if (taskName === WAR_WIDGET_MANUAL_TASK) await this.handleWidgetRefresh();
      else await this.updateWarWidget();
      return true;
    } catch (error) {
      await this.report('widget.background', error);
      return false;
    }
  }

  async initializeFromBackground(_data: string): Promise<void> {
    await this.updateWidgets();
  }

  async updateWidgets(): Promise<void> {
    if (this.options.platform === 'ios' || this.options.platform === 'android') {
      await this.updateWarWidget();
    }
  }

  async updateWarWidget(): Promise<void> {
    try {
      const cachedClans = await this.getCachedClanOptions();
      if (cachedClans.length > 0) {
        await this.prepareClanWidgets(cachedClans);
        return;
      }
      const clanTag = await this.getCurrentPlayerClanTag();
      if (clanTag) await this.refreshWarInfoForClan(clanTag, true);
      await this.options.native.reloadWidgets();
    } catch (error) {
      await this.report('widget.update', error);
    }
  }

  async handleWidgetRefresh(): Promise<void> {
    try {
      const cachedClans = await this.getCachedClanOptions();
      if (cachedClans.length > 0) {
        await Promise.all(cachedClans.map((clan) => this.refreshWarInfoForClan(clan.tag)));
        await this.options.native.reloadWidgets();
        return;
      }
      const clanTag = await this.getCurrentPlayerClanTag();
      if (!clanTag) return;
      await this.refreshWarInfoForClan(clanTag, true);
      await this.options.native.reloadWidgets();
    } catch (error) {
      await this.report('widget.refresh', error);
    }
  }

  async consumePendingWidgetAction(): Promise<boolean> {
    if (this.options.platform !== 'android') return false;
    const action = await this.options.native.consumePendingWidgetAction();
    if (action === null) return false;
    return this.handleWidgetAction(action);
  }

  async handleWidgetAction(action: string): Promise<boolean> {
    try {
      const uri = new URL(action);
      if (
        uri.protocol.toLowerCase() !== 'warwidget:' ||
        uri.hostname.toLowerCase() !== 'refreshclicked'
      ) {
        return false;
      }
      if (!(await this.areWarWidgetsEnabled())) return true;
      await this.initializeFromBackground(action);
      return true;
    } catch (error) {
      await this.report('widget.action', error);
      return false;
    }
  }

  async seedClanOptionsFromProfiles(
    profiles: readonly WarWidgetPlayerProfile[],
    options: {
      bookmarkedClans?: readonly WarWidgetBookmarkedClan[];
      selectedPlayerTag?: string | null;
      refreshWarData?: boolean;
    } = {},
  ): Promise<void> {
    const clans = clanOptionsFromProfiles(profiles, options.bookmarkedClans);
    if (clans.length === 0) return;
    const selected =
      selectedClanTagFromProfiles(profiles, options.selectedPlayerTag ?? null) ?? clans[0]!.tag;
    if (options.refreshWarData) await this.prepareClanWidgets(clans, selected);
    else {
      await this.cacheClanOptions(clans, selected);
      await this.options.native.reloadWidgets();
    }
  }

  async getCachedClanOptions(): Promise<WarWidgetClanOption[]> {
    try {
      await this.migrateLegacyWidgetValues();
      const raw = await this.options.mirror.getItem(WIDGET_STORAGE_KEYS.warClans);
      if (!raw) return [];
      const decoded: unknown = JSON.parse(raw);
      if (!Array.isArray(decoded)) return [];
      return decoded.flatMap((value) => {
        if (!isRecord(value)) return [];
        const tag = String(value.tag ?? '');
        if (!tag) return [];
        const badgeUrl = value.badgeUrl == null ? undefined : String(value.badgeUrl);
        return [
          {
            tag,
            name: String(value.name ?? ''),
            ...(badgeUrl ? { badgeUrl } : undefined),
          },
        ];
      });
    } catch (error) {
      this.options.log?.(`Error reading widget clan options: ${String(error)}`);
      return [];
    }
  }

  async migrateLegacyWidgetValues(): Promise<WidgetMigrationResult> {
    if ((await this.options.mirror.getItem(LEGACY_WIDGET_MIGRATION_MARKER)) === 'true') {
      return { migratedKeys: [], sourceValuesRetained: true };
    }
    const legacyValues = await this.options.native.readLegacyWidgetValues();
    const migratedKeys: string[] = [];
    for (const [key, value] of Object.entries(legacyValues)) {
      if ((await this.options.mirror.getItem(key)) !== null) continue;
      await this.options.mirror.setItem(key, value);
      migratedKeys.push(key);
    }
    await this.options.mirror.setItem(LEGACY_WIDGET_MIGRATION_MARKER, 'true');
    return { migratedKeys, sourceValuesRetained: true };
  }

  async cacheClanOptions(
    clans: readonly WarWidgetClanOption[],
    selectedClanTag?: string | null,
    syncConfig = true,
  ): Promise<void> {
    if (syncConfig) await this.syncWidgetProxyConfig();
    const deduped = new Map<string, WarWidgetClanOption>();
    for (const clan of clans) if (clan.tag) deduped.set(normalizedClanTag(clan.tag), clan);
    const options = [...deduped.values()].sort((left, right) =>
      compareNames(left.name, right.name),
    );
    await this.writeWidgetValue(WIDGET_STORAGE_KEYS.warClans, JSON.stringify(options));
    const selected = selectedClanTag ?? options[0]?.tag ?? (await this.getCurrentPlayerClanTag());
    if (selected) await this.writeWidgetValue(WIDGET_STORAGE_KEYS.warSelectedClan, selected);
  }

  async refreshWarInfoForClan(clanTag: string, makeDefault = false): Promise<void> {
    const warInfo = await this.loadWarSummary(clanTag);
    await this.writeWidgetValue(warInfoKeyForClan(clanTag), warInfo);
    if (makeDefault) {
      await this.writeWidgetValue(WIDGET_STORAGE_KEYS.warDefaultInfo, warInfo);
      await this.writeWidgetValue(WIDGET_STORAGE_KEYS.warSelectedClan, clanTag);
    }
  }

  async prepareClanWidgets(
    clans: readonly WarWidgetClanOption[],
    selectedClanTag?: string | null,
  ): Promise<void> {
    await this.syncWidgetProxyConfig();
    await this.cacheClanOptions(clans, selectedClanTag, false);
    const selectedKey = selectedClanTag ? normalizedClanTag(selectedClanTag) : null;
    const byTag = new Map<string, WarWidgetClanOption>();
    for (const clan of clans) if (clan.tag) byTag.set(normalizedClanTag(clan.tag), clan);
    await Promise.all(
      [...byTag.entries()].map(([key, clan]) =>
        this.refreshWarInfoForClan(clan.tag, key === selectedKey),
      ),
    );
    if (selectedKey && !byTag.has(selectedKey)) {
      await this.refreshWarInfoForClan(selectedClanTag!, true);
    }
    await this.options.native.reloadWidgets();
  }

  async getCurrentPlayerClanTag(): Promise<string | null> {
    try {
      let selectedPlayerTag: string | null = null;
      for (const key of [STORAGE_KEYS.selectedTag, 'selected_player_tag', 'selectedPlayerTag']) {
        selectedPlayerTag = await this.options.preferences.getItem(key);
        if (selectedPlayerTag) break;
      }
      if (!selectedPlayerTag) {
        selectedPlayerTag = await this.options.getFirstAvailableAccount();
        if (!selectedPlayerTag) return null;
        await this.options.preferences.setItem(STORAGE_KEYS.selectedTag, selectedPlayerTag);
      }
      const cacheKey = playerClanTagStorageKey(selectedPlayerTag);
      const cached = await this.options.preferences.getItem(cacheKey);
      if (cached) return cached;
      const clanTag = await this.options.loadPlayerClanTag(selectedPlayerTag);
      if (!clanTag) return null;
      await this.options.preferences.setItem(cacheKey, clanTag);
      return clanTag;
    } catch (error) {
      this.options.log?.(`Error getting current player clan tag: ${String(error)}`);
      return null;
    }
  }

  async requestPinnedWarWidget(): Promise<WidgetPinRequestResult> {
    if (this.options.platform !== 'android') return { supported: false, requested: false };
    return this.options.native.requestPinWarWidget();
  }

  async syncWidgetProxyConfig(): Promise<void> {
    await this.writeWidgetValue(WIDGET_STORAGE_KEYS.warProxyUrl, this.options.proxyUrl);
    await this.writeWidgetValue(WIDGET_STORAGE_KEYS.warApiV2Url, this.options.apiV2Url);
    await this.writeWidgetValue(WIDGET_STORAGE_KEYS.legacyWarAuthToken, null);
  }

  private loadWarSummary(clanTag: string): Promise<string> {
    const key = normalizedClanTag(clanTag);
    const existing = this.summaryLoads.get(key);
    if (existing !== undefined) return existing;
    const load = (async () => {
      try {
        if (!clanTag) return buildNotInClanWidgetPayload(this.now());
        const response = await this.options.loadWarSummary(clanTag);
        return buildWarWidgetPayload(response, clanTag, this.now());
      } catch (error) {
        await this.report('widget.fetch_war_summary', error);
        return buildWarWidgetErrorPayload(this.now());
      }
    })();
    this.summaryLoads.set(key, load);
    void load.finally(() => {
      if (this.summaryLoads.get(key) === load) this.summaryLoads.delete(key);
    });
    return load;
  }

  private async writeWidgetValue(key: string, value: string | null): Promise<void> {
    await this.options.native.setWidgetValue(key, value);
    if (value === null) await this.options.mirror.removeItem(key);
    else await this.options.mirror.setItem(key, value);
  }

  private now(): Date {
    return this.options.now?.() ?? new Date();
  }

  private async report(
    operation: Parameters<NonNullable<WarWidgetServiceOptions['reportError']>>[0]['operation'],
    error: unknown,
  ): Promise<void> {
    try {
      await this.options.reportError?.({ operation, error });
    } catch {
      // Reporting cannot change widget refresh completion semantics.
    }
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function compareNames(left: string, right: string): number {
  const normalizedLeft = left.toLowerCase();
  const normalizedRight = right.toLowerCase();
  return normalizedLeft < normalizedRight ? -1 : normalizedLeft > normalizedRight ? 1 : 0;
}
