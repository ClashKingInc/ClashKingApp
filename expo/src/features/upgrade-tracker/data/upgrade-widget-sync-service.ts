import { ImageAssets } from '../../../core/assets/image-assets';
import {
  localizedNameForItem,
  translationForTid,
} from '../../../core/game-data/game-data-localization';
import { WIDGET_STORAGE_KEYS, upgradeWidgetStorageKey } from '../../../core/storage/storage';
import type { MessageKey } from '../../../i18n';
import type { StringStore } from '../../../services/storage/auth-storage';
import type { NativeWidgetBridge, WidgetPlatform } from '../../widgets/contracts';
import {
  UpgradeCategory,
  UpgradeQueue,
  UpgradeVillage,
  type UpgradeTrackerItem,
  type UpgradeTrackerSnapshot,
  type UpgradeVillageValue,
  type UpgradeQueueValue,
} from '../models';

export interface UpgradeWidgetAccount {
  readonly tag?: unknown;
  readonly name?: unknown;
  readonly townHallLevel?: unknown;
  readonly builderHallLevel?: unknown;
}
interface ResolvedUpgradeWidgetAccount {
  readonly tag: string;
  readonly name: string;
  readonly townHallLevel: number;
  readonly builderHallLevel: number;
}

export interface UpgradeWidgetSyncOptions {
  readonly platform: WidgetPlatform;
  readonly native: Pick<NativeWidgetBridge, 'setWidgetValue' | 'reloadWidgets'>;
  readonly mirror: StringStore;
  readonly translate: (key: MessageKey, values?: Record<string, string | number>) => string;
  readonly now?: () => Date;
}

export class UpgradeWidgetSyncService {
  constructor(private readonly options: UpgradeWidgetSyncOptions) {}

  async sync(
    linkedSnapshots: readonly UpgradeTrackerSnapshot[],
    options: { linkedAccounts: readonly UpgradeWidgetAccount[]; selectedTag?: string | null },
  ) {
    if (this.options.platform === 'web') return;
    const byTag = new Map(linkedSnapshots.map((snapshot) => [normalized(snapshot.tag), snapshot]));
    const accounts = widgetAccounts(linkedSnapshots, options.linkedAccounts);
    await this.write(WIDGET_STORAGE_KEYS.upgradeAccounts, JSON.stringify(accounts));
    const selectedTag = normalized(options.selectedTag ?? '');
    let selectedPayload: string | null = null,
      firstPayload: string | null = null,
      firstTag = '';
    for (const account of accounts) {
      const tag = normalized(account.tag);
      const snapshot = byTag.get(tag)!;
      const payload = JSON.stringify(this.widgetPayload(snapshot, account));
      firstPayload ??= payload;
      firstTag ||= tag;
      if (tag === selectedTag) selectedPayload = payload;
      await this.write(upgradeWidgetStorageKey(tag), payload);
    }
    if (accounts.length === 0) {
      await this.clearCurrentSelection();
      await this.options.native.reloadWidgets();
      return;
    }
    if (this.options.platform === 'android') {
      await this.write(
        WIDGET_STORAGE_KEYS.upgradeAndroidData,
        selectedPayload ?? (selectedTag ? '' : (firstPayload ?? '')),
      );
      await this.write(WIDGET_STORAGE_KEYS.upgradeAndroidSelectedTag, selectedTag || firstTag);
    }
    await this.options.native.reloadWidgets();
  }

  async syncSelectedTag(selectedTag: string | null) {
    if (this.options.platform !== 'android') return;
    const rawAccounts = await this.options.mirror.getItem(WIDGET_STORAGE_KEYS.upgradeAccounts);
    const decoded: unknown = rawAccounts ? JSON.parse(rawAccounts) : [];
    const accounts = Array.isArray(decoded) ? decoded.filter(isRecord) : [];
    const requested = normalized(selectedTag ?? '');
    let selectedPayload: string | null = null,
      firstPayload: string | null = null,
      firstTag = '';
    for (const account of accounts) {
      const tag = normalized(String(account.tag ?? ''));
      if (!tag) continue;
      const payload = await this.options.mirror.getItem(upgradeWidgetStorageKey(tag));
      if (!payload) continue;
      firstPayload ??= payload;
      firstTag ||= tag;
      if (tag === requested) {
        selectedPayload = payload;
        break;
      }
    }
    await this.write(
      WIDGET_STORAGE_KEYS.upgradeAndroidData,
      selectedPayload ?? (requested ? '' : (firstPayload ?? '')),
    );
    await this.write(WIDGET_STORAGE_KEYS.upgradeAndroidSelectedTag, requested || firstTag);
    await this.options.native.reloadWidgets();
  }

  async clear() {
    if (this.options.platform === 'web') return;
    await this.write(WIDGET_STORAGE_KEYS.upgradeAccounts, '[]');
    await this.clearCurrentSelection();
    await this.options.native.reloadWidgets();
  }

  widgetPayload(snapshot: UpgradeTrackerSnapshot, account: ResolvedUpgradeWidgetAccount) {
    const now = this.options.now?.() ?? new Date();
    const townHallLevel = int(account.townHallLevel),
      builderHallLevel = int(account.builderHallLevel);
    return {
      tag: account.tag,
      name: account.name,
      townHallLevel,
      builderHallLevel,
      hallImageUrl:
        townHallLevel > 0
          ? ImageAssets.townHall(townHallLevel)
          : ImageAssets.builderHall(builderHallLevel),
      updatedAt: now.toISOString(),
      hasStaleData: snapshot.items.some(
        (item) =>
          !item.isComplete &&
          (item.activeSeconds ?? 0) > 0 &&
          snapshot.remainingActiveSeconds(item, now) <= 0,
      ),
      labels: this.labels(),
      boosts: this.boostPayload(snapshot, now),
      helpers: this.helperPayload(snapshot, now),
      homeBuilders: this.widgetSection(
        snapshot,
        now,
        UpgradeVillage.home,
        UpgradeQueue.builders,
        snapshot.homeBuilderCount,
        3,
      ),
      laboratory: this.widgetSection(
        snapshot,
        now,
        UpgradeVillage.home,
        UpgradeQueue.laboratory,
        1,
        2,
      ),
      pets: this.widgetSection(snapshot, now, UpgradeVillage.home, UpgradeQueue.pets, 1, 1),
      builderBase: this.widgetSection(
        snapshot,
        now,
        UpgradeVillage.builderBase,
        UpgradeQueue.builders,
        snapshot.builderBaseBuilderCount,
        2,
      ),
    };
  }

  private widgetSection(
    snapshot: UpgradeTrackerSnapshot,
    now: Date,
    village: UpgradeVillageValue,
    queue: UpgradeQueueValue,
    capacity: number,
    limit: number,
  ) {
    const items = snapshot.itemsFor({ village, queue }),
      active = items.filter((item) => snapshot.remainingActiveSeconds(item, now) > 0),
      groups: TaskGroup[] = [];
    for (const item of active) {
      const index = groups.findIndex((group) => sameTask(snapshot, group.item, item, now));
      if (index < 0) groups.push({ item, count: activeInstanceCount(item) });
      else groups[index]!.count += activeInstanceCount(item);
    }
    const activeCount = active.reduce((sum, item) => sum + activeInstanceCount(item), 0),
      visible = groups.slice(0, limit);
    let hiddenFinish: Date | null = null;
    for (const group of groups.slice(limit)) {
      const finish = addSeconds(now, snapshot.remainingActiveSeconds(group.item, now));
      if (!hiddenFinish || finish < hiddenFinish) hiddenFinish = finish;
    }
    return {
      available: items.length > 0,
      capacity: Math.max(capacity, activeCount),
      activeCount,
      remainingCount: items
        .filter((item) => !item.isComplete)
        .reduce((sum, item) => sum + instanceCount(item), 0),
      tasks: visible.map((group) => this.widgetTask(snapshot, group, now)),
      ...(hiddenFinish ? { hiddenFinishesAt: hiddenFinish.toISOString() } : null),
    };
  }
  private widgetTask(snapshot: UpgradeTrackerSnapshot, group: TaskGroup, now: Date) {
    const item = group.item,
      remaining = snapshot.remainingActiveSeconds(item, now),
      helper = snapshot.remainingHelperSeconds(item, now);
    return {
      name: localizedItemName(item),
      imageUrl: item.imageUrl,
      fromLevel: item.currentLevel,
      toLevel: clamp(item.currentLevel + 1, 0, item.targetLevel),
      ...(group.count > 1 ? { count: group.count } : null),
      finishesAt: addSeconds(now, remaining).toISOString(),
      ...(helper > 0
        ? {
            helperName: snapshot.helperNameFor(item),
            helperFinishesAt: addSeconds(now, helper).toISOString(),
          }
        : null),
    };
  }
  private boostPayload(snapshot: UpgradeTrackerSnapshot, now: Date) {
    const t = this.options.translate,
      b = snapshot.boosts,
      timed = (kind: string, label: string, shortLabel: string, raw: number, imageUrl: string) => ({
        kind,
        label,
        shortLabel,
        imageUrl,
        expiresAt: addSeconds(now, snapshot.remainingCapturedSeconds(raw, now)).toISOString(),
      });
    return [
      ...(snapshot.remainingCapturedSeconds(b.builderConsumableSeconds, now) > 0
        ? [
            timed(
              'builderPotion',
              translationForTid('TID_BOOSTER_BUILDERS') ?? t('widgetBuilderPotion'),
              t('widgetBuilderBoostShort'),
              b.builderConsumableSeconds,
              ImageAssets.builderPotion,
            ),
          ]
        : []),
      ...(snapshot.remainingCapturedSeconds(b.labConsumableSeconds, now) > 0
        ? [
            timed(
              'researchPotion',
              translationForTid('TID_BOOSTER_LAB_POTION') ?? t('widgetResearchPotion'),
              t('widgetResearchBoostShort'),
              b.labConsumableSeconds,
              ImageAssets.researchPotion,
            ),
          ]
        : []),
      ...(snapshot.remainingCapturedSeconds(b.petConsumableSeconds, now) > 0
        ? [
            timed(
              'petPotion',
              translationForTid('TID_BOOSTER_PET_POTION') ?? t('widgetPetPotion'),
              t('widgetPetBoostShort'),
              b.petConsumableSeconds,
              ImageAssets.petPotion,
            ),
          ]
        : []),
      ...(snapshot.remainingCapturedSeconds(b.clockTowerBoostSeconds, now) > 0
        ? [
            timed(
              'clockTower',
              translationForTid('TID_BUILDING_CLOCK_TOWER') ?? t('widgetClockTower'),
              t('widgetClockBoostShort'),
              b.clockTowerBoostSeconds,
              ImageAssets.clockTowerPotion,
            ),
          ]
        : []),
      ...(snapshot.remainingCapturedSeconds(b.builderBoostSeconds, now) > 0
        ? [
            timed(
              'townHallBuilder',
              t('widgetTownHallBuilderBoost'),
              t('widgetBuilderBoostShort'),
              b.builderBoostSeconds,
              ImageAssets.townHall(snapshot.townHallLevel),
            ),
          ]
        : []),
      ...(snapshot.remainingCapturedSeconds(b.labBoostSeconds, now) > 0
        ? [
            timed(
              'townHallLab',
              t('widgetTownHallLabBoost'),
              t('widgetResearchBoostShort'),
              b.labBoostSeconds,
              ImageAssets.townHall(snapshot.townHallLevel),
            ),
          ]
        : []),
      ...(b.builderCostReductionPercent > 0
        ? [
            {
              kind: 'builderPerk',
              label: t('widgetBuilderCostPerk', { percent: b.builderCostReductionPercent }),
              shortLabel: t('widgetBuilderBoostShort'),
            },
          ]
        : []),
      ...(b.builderTimeReductionPercent > 0
        ? [
            {
              kind: 'builderPerk',
              label: t('widgetBuilderTimePerk', { percent: b.builderTimeReductionPercent }),
              shortLabel: t('widgetBuilderBoostShort'),
            },
          ]
        : []),
      ...(b.labCostReductionPercent > 0
        ? [
            {
              kind: 'labPerk',
              label: t('widgetLabCostPerk', { percent: b.labCostReductionPercent }),
              shortLabel: t('widgetResearchBoostShort'),
            },
          ]
        : []),
      ...(b.labTimeReductionPercent > 0
        ? [
            {
              kind: 'labPerk',
              label: t('widgetLabTimePerk', { percent: b.labTimeReductionPercent }),
              shortLabel: t('widgetResearchBoostShort'),
            },
          ]
        : []),
    ];
  }
  private helperPayload(snapshot: UpgradeTrackerSnapshot, now: Date) {
    const t = this.options.translate;
    return snapshot.items
      .filter(
        (item) =>
          item.category === UpgradeCategory.builders &&
          ['apprentice', 'assistant', 'alchemist'].some((value) =>
            item.name.toLowerCase().includes(value),
          ),
      )
      .map((helper) => {
        const assigned = snapshot.items.find(
            (item) =>
              snapshot.helperNameFor(item) === helper.name &&
              snapshot.remainingHelperSeconds(item, now) > 0,
          ),
          cooldown = snapshot.remainingCooldownSeconds(helper, now),
          active = assigned ? snapshot.remainingHelperSeconds(assigned, now) : 0,
          statusUntil =
            active > 0
              ? addSeconds(now, active).toISOString()
              : !assigned && cooldown > 0
                ? addSeconds(now, cooldown).toISOString()
                : null;
        return {
          name: localizedItemName(helper),
          shortName: helperShortName(helper.name, t),
          imageUrl: helper.imageUrl,
          status: assigned
            ? t('widgetHelping')
            : cooldown > 0
              ? t('widgetReadyIn')
              : t('widgetReady'),
          ...(statusUntil ? { statusUntil } : null),
        };
      });
  }
  private labels() {
    const t = this.options.translate;
    return {
      title: t('widgetUpgradeProgressTitle'),
      homeVillage: t('upgradeTrackerHomeVillage').toUpperCase(),
      village: t('dashboardUpgradeTrackerVillage').toUpperCase(),
      laboratory: t('widgetLaboratory'),
      pets: t('widgetPets'),
      builderBase: t('widgetBuilderBase'),
      research: t('widgetResearch'),
      active: t('widgetActive'),
      idle: t('widgetIdle'),
      locked: t('widgetLocked'),
      maxed: t('widgetMaxed'),
      notUnlocked: t('widgetNotUnlocked'),
      fullyUpgraded: t('widgetFullyUpgraded'),
      noActiveUpgrades: t('widgetNoActiveUpgrades'),
      noActiveResearch: t('widgetNoActiveResearch'),
      staleData: t('widgetDataStale'),
      moreUpgrade: t('widgetMoreUpgrade'),
      moreUpgrades: t('widgetMoreUpgrades'),
      level: t('widgetLevelShort'),
      ready: t('widgetReady'),
    };
  }
  private async clearCurrentSelection() {
    if (this.options.platform !== 'android') return;
    await this.write(WIDGET_STORAGE_KEYS.upgradeAndroidData, '');
    await this.write(WIDGET_STORAGE_KEYS.upgradeAndroidSelectedTag, '');
  }
  private async write(key: string, value: string | null) {
    await this.options.native.setWidgetValue(key, value);
    if (value === null) await this.options.mirror.removeItem(key);
    else await this.options.mirror.setItem(key, value);
  }
}

interface TaskGroup {
  item: UpgradeTrackerItem;
  count: number;
}
function widgetAccounts(
  snapshots: readonly UpgradeTrackerSnapshot[],
  linked: readonly UpgradeWidgetAccount[],
): ResolvedUpgradeWidgetAccount[] {
  const linkedByTag = new Map(
      linked
        .map((account) => [normalized(String(account.tag ?? '')), account] as const)
        .filter(([tag]) => Boolean(tag)),
    ),
    seen = new Set<string>(),
    result: ResolvedUpgradeWidgetAccount[] = [];
  for (const snapshot of snapshots) {
    const tag = normalized(snapshot.tag),
      account = linkedByTag.get(tag);
    if (!account || !tag || seen.has(tag)) continue;
    seen.add(tag);
    const town = int(account.townHallLevel),
      builder = int(account.builderHallLevel);
    result.push({
      tag: `#${tag}`,
      name: nonEmpty(account.name) ?? snapshot.name,
      townHallLevel: town > 0 ? town : snapshot.townHallLevel,
      builderHallLevel: builder > 0 ? builder : snapshot.builderHallLevel,
    });
  }
  return result;
}
function sameTask(
  snapshot: UpgradeTrackerSnapshot,
  a: UpgradeTrackerItem,
  b: UpgradeTrackerItem,
  now: Date,
) {
  return (
    a.id === b.id &&
    a.name === b.name &&
    a.village === b.village &&
    a.queue === b.queue &&
    a.currentLevel === b.currentLevel &&
    a.targetLevel === b.targetLevel &&
    snapshot.remainingActiveSeconds(a, now) === snapshot.remainingActiveSeconds(b, now) &&
    activeHelper(snapshot, a, now) === activeHelper(snapshot, b, now)
  );
}
function activeHelper(snapshot: UpgradeTrackerSnapshot, item: UpgradeTrackerItem, now: Date) {
  return snapshot.remainingHelperSeconds(item, now) > 0 ? snapshot.helperNameFor(item) : null;
}
function instanceCount(item: UpgradeTrackerItem) {
  return item.count > 0 ? item.count : 1;
}
function activeInstanceCount(item: UpgradeTrackerItem) {
  return (item.activeSeconds ?? 0) > 0 ? 1 : instanceCount(item);
}
function localizedItemName(item: UpgradeTrackerItem) {
  return localizedNameForItem(item.meta ?? undefined).trim() || item.name;
}
function helperShortName(name: string, t: UpgradeWidgetSyncOptions['translate']) {
  const lower = name.toLowerCase();
  if (lower.includes('apprentice')) return t('widgetApprenticeShort');
  if (lower.includes('assistant')) return t('widgetAssistantShort');
  if (lower.includes('alchemist'))
    return translationForTid('TID_ALCHEMIST_APPRENTICE') ?? t('widgetAlchemistShort');
  return name;
}
function normalized(tag: string) {
  return tag.replaceAll('#', '').trim().toUpperCase();
}
function int(value: unknown) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  const text = String(value ?? '');
  return /^[+-]?\d+$/.test(text) ? Number.parseInt(text, 10) : 0;
}
function nonEmpty(value: unknown) {
  const text = String(value ?? '').trim();
  return text || null;
}
function addSeconds(date: Date, seconds: number) {
  return new Date(date.getTime() + seconds * 1000);
}
function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value));
}
function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
