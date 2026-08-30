import type { MessageKey } from '../../../i18n';
import type { StringStore } from '../../../services/storage/auth-storage';
import {
  UpgradeBoosts,
  UpgradeCategory,
  UpgradeQueue,
  UpgradeStep,
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
  UpgradeVillage,
} from '../models';
import { UpgradeWidgetSyncService } from './upgrade-widget-sync-service';

class MemoryStore implements StringStore {
  readonly values = new Map<string, string>();
  async getItem(key: string) {
    return this.values.get(key) ?? null;
  }
  async setItem(key: string, value: string) {
    this.values.set(key, value);
  }
  async removeItem(key: string) {
    this.values.delete(key);
  }
}

function harness(platform: 'ios' | 'android' | 'web' = 'android') {
  const values = new Map<string, string | null>(),
    mirror = new MemoryStore();
  const native = {
    setWidgetValue: jest.fn(async (key: string, value: string | null) => {
      values.set(key, value);
    }),
    reloadWidgets: jest.fn(async () => undefined),
  };
  const service = new UpgradeWidgetSyncService({
    platform,
    native,
    mirror,
    now: () => new Date('2026-07-11T10:00:00.000Z'),
    translate: (key: MessageKey, values) => `${key}${values?.percent ?? ''}`,
  });
  return { service, native, values, mirror };
}
function snapshot(tag = '#A') {
  const capturedAt = new Date('2026-07-11T09:30:00.000Z');
  return new UpgradeTrackerSnapshot({
    tag,
    name: 'Snapshot Name',
    townHallLevel: 18,
    builderHallLevel: 6,
    homeBuilderCount: 5,
    builderBaseBuilderCount: 2,
    items: [
      new UpgradeTrackerItem({
        id: 1,
        name: 'Gold Mine',
        imageUrl: 'mine.png',
        village: UpgradeVillage.home,
        category: UpgradeCategory.resources,
        queue: UpgradeQueue.builders,
        currentLevel: 16,
        targetLevel: 17,
        count: 2,
        steps: [new UpgradeStep(17, [], 7200)],
        completedUpgradeSeconds: 1,
        totalUpgradeSeconds: 7201,
        activeSeconds: 7200,
      }),
    ],
    collections: [],
    boosts: new UpgradeBoosts({ builderCostReductionPercent: 20 }),
    events: [],
    capturedAt,
  });
}

test('sync writes canonical accounts, per-account payload, Android selection, and reloads', async () => {
  const { service, values, native, mirror } = harness();
  await service.sync([snapshot()], {
    selectedTag: '#A',
    linkedAccounts: [{ tag: '#A', name: 'Linked Name', townHallLevel: 17, builderHallLevel: 5 }],
  });
  expect(JSON.parse(values.get('upgradeWidgetAccounts')! as string)).toEqual([
    { tag: '#A', name: 'Linked Name', townHallLevel: 17, builderHallLevel: 5 },
  ]);
  const payload = JSON.parse(values.get('upgradeWidget_A')! as string);
  expect(payload).toMatchObject({
    tag: '#A',
    name: 'Linked Name',
    hasStaleData: false,
    homeBuilders: { capacity: 5, activeCount: 1, remainingCount: 2 },
  });
  expect(payload.homeBuilders.tasks[0]).toMatchObject({
    name: 'Gold Mine',
    fromLevel: 16,
    toLevel: 17,
    finishesAt: '2026-07-11T11:30:00.000Z',
  });
  expect(payload.boosts).toContainEqual(
    expect.objectContaining({ kind: 'builderPerk', label: 'widgetBuilderCostPerk20' }),
  );
  expect(values.get('upgradeWidgetData')).toBe(values.get('upgradeWidget_A'));
  expect(values.get('upgradeWidgetSelectedTag')).toBe('A');
  expect(await mirror.getItem('upgradeWidget_A')).toBe(values.get('upgradeWidget_A'));
  expect(native.reloadWidgets).toHaveBeenCalledTimes(1);
});

test('sync excludes snapshots without a matching verified link and clears empty Android state', async () => {
  const { service, values } = harness();
  await service.sync([snapshot('#OTHER')], { linkedAccounts: [{ tag: '#A' }] });
  expect(values.get('upgradeWidgetAccounts')).toBe('[]');
  expect(values.get('upgradeWidgetData')).toBe('');
  expect(values.get('upgradeWidgetSelectedTag')).toBe('');
});

test('syncSelectedTag reuses mirrored per-account payloads with Flutter fallback semantics', async () => {
  const { service, mirror, values } = harness();
  await mirror.setItem('upgradeWidgetAccounts', JSON.stringify([{ tag: '#A' }, { tag: '#B' }]));
  await mirror.setItem('upgradeWidget_A', 'payload-a');
  await mirror.setItem('upgradeWidget_B', 'payload-b');
  await service.syncSelectedTag('#B');
  expect(values.get('upgradeWidgetData')).toBe('payload-b');
  expect(values.get('upgradeWidgetSelectedTag')).toBe('B');
  await service.syncSelectedTag(null);
  expect(values.get('upgradeWidgetData')).toBe('payload-a');
  expect(values.get('upgradeWidgetSelectedTag')).toBe('A');
});

test('web sync and clear are no-ops', async () => {
  const { service, native } = harness('web');
  await service.sync([snapshot()], { linkedAccounts: [{ tag: '#A' }] });
  await service.clear();
  expect(native.setWidgetValue).not.toHaveBeenCalled();
  expect(native.reloadWidgets).not.toHaveBeenCalled();
});

test('clear removes Android selection while iOS keeps Android-only keys untouched', async () => {
  const android = harness();
  await android.service.clear();
  expect(android.values.get('upgradeWidgetAccounts')).toBe('[]');
  expect(android.values.get('upgradeWidgetData')).toBe('');
  expect(android.values.get('upgradeWidgetSelectedTag')).toBe('');
  expect(android.native.reloadWidgets).toHaveBeenCalledTimes(1);

  const ios = harness('ios');
  await ios.service.clear();
  expect(ios.values.get('upgradeWidgetAccounts')).toBe('[]');
  expect(ios.values.has('upgradeWidgetData')).toBe(false);
  expect(ios.native.reloadWidgets).toHaveBeenCalledTimes(1);
  await ios.service.syncSelectedTag('#A');
  expect(ios.native.reloadWidgets).toHaveBeenCalledTimes(1);
});

test('payload exposes stale work, hidden completion, helpers, and every active boost kind', () => {
  const work = (id: number, name: string, seconds: number, helperSeconds?: number) =>
    new UpgradeTrackerItem({
      id,
      name,
      imageUrl: `${id}.png`,
      village: UpgradeVillage.home,
      category: UpgradeCategory.defenses,
      queue: UpgradeQueue.builders,
      currentLevel: 1,
      targetLevel: 2,
      count: 1,
      steps: [new UpgradeStep(2, [], seconds)],
      completedUpgradeSeconds: 0,
      totalUpgradeSeconds: seconds,
      activeSeconds: seconds,
      helperSeconds,
    });
  const stale = work(1, 'Expired', 60);
  const visible = [work(2, 'Cannon', 7200), work(3, 'Archer Tower', 3600), work(4, 'Mortar', 5400)];
  const hidden = work(5, 'Tesla', 1800);
  const assistant = new UpgradeTrackerItem({
    id: 6,
    name: 'Builder Apprentice',
    imageUrl: 'helper.png',
    village: UpgradeVillage.home,
    category: UpgradeCategory.builders,
    queue: UpgradeQueue.none,
    currentLevel: 2,
    targetLevel: 2,
    count: 1,
    steps: [],
    completedUpgradeSeconds: 0,
    totalUpgradeSeconds: 0,
    cooldownSeconds: 1800,
  });
  const laboratory = new UpgradeTrackerItem({
    id: 7,
    name: 'Barbarian',
    imageUrl: 'barbarian.png',
    village: UpgradeVillage.home,
    category: UpgradeCategory.troops,
    queue: UpgradeQueue.laboratory,
    currentLevel: 1,
    targetLevel: 2,
    count: 1,
    steps: [new UpgradeStep(2, [], 3600)],
    completedUpgradeSeconds: 0,
    totalUpgradeSeconds: 3600,
    activeSeconds: 3600,
    helperSeconds: 900,
  });
  const researchAssistant = new UpgradeTrackerItem({
    id: 8,
    name: 'Research Assistant',
    imageUrl: 'research.png',
    village: UpgradeVillage.home,
    category: UpgradeCategory.builders,
    queue: UpgradeQueue.none,
    currentLevel: 1,
    targetLevel: 1,
    count: 1,
    steps: [],
    completedUpgradeSeconds: 0,
    totalUpgradeSeconds: 0,
  });
  const rich = new UpgradeTrackerSnapshot({
    tag: '#RICH',
    name: 'Rich',
    townHallLevel: 18,
    builderHallLevel: 0,
    homeBuilderCount: 4,
    builderBaseBuilderCount: 1,
    items: [stale, ...visible, hidden, assistant, laboratory, researchAssistant],
    collections: [],
    boosts: new UpgradeBoosts({
      builderBoostSeconds: 600,
      labBoostSeconds: 600,
      clockTowerBoostSeconds: 600,
      builderConsumableSeconds: 600,
      labConsumableSeconds: 600,
      petConsumableSeconds: 600,
      builderCostReductionPercent: 10,
      builderTimeReductionPercent: 15,
      labCostReductionPercent: 20,
      labTimeReductionPercent: 25,
    }),
    events: [],
    capturedAt: new Date('2026-07-11T09:59:00.000Z'),
  });
  const { service } = harness();
  const payload = service.widgetPayload(rich, {
    tag: '#RICH',
    name: 'Rich',
    townHallLevel: 0,
    builderHallLevel: 10,
  });

  expect(payload.hallImageUrl).toContain('builder_hall/level_10');
  expect(payload.hasStaleData).toBe(true);
  expect(payload.homeBuilders).toMatchObject({ activeCount: 4, capacity: 4 });
  expect(payload.homeBuilders.tasks).toHaveLength(3);
  expect(payload.homeBuilders.hiddenFinishesAt).toBe('2026-07-11T10:29:00.000Z');
  expect(payload.laboratory.tasks[0]).toMatchObject({
    helperName: 'Research Assistant',
    helperFinishesAt: '2026-07-11T10:14:00.000Z',
  });
  expect(new Set(payload.boosts.map((boost) => boost.kind))).toEqual(
    new Set([
      'builderPotion',
      'researchPotion',
      'petPotion',
      'clockTower',
      'townHallBuilder',
      'townHallLab',
      'builderPerk',
      'labPerk',
    ]),
  );
  expect(payload.helpers).toEqual(
    expect.arrayContaining([
      expect.objectContaining({ shortName: 'widgetApprenticeShort', status: 'widgetReadyIn' }),
      expect.objectContaining({ shortName: 'widgetAssistantShort', status: 'widgetHelping' }),
    ]),
  );
});
