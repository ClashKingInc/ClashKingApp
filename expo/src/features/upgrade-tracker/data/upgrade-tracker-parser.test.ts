import {
  UpgradeCategory,
  UpgradeCost,
  UpgradePlanStrategy,
  UpgradeQueue,
  UpgradeStep,
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
  UpgradeVillage,
  UpgradeBoosts,
  UpgradeCollectionType,
  UpgradePlanPreferences,
  normalizeUpgradePlanPreferencesForQueue,
} from '../models';
import { UpgradeTrackerParser } from './upgrade-tracker-parser';

const bundle = {
  buildings: [
    {
      _id: 1,
      name: 'Town Hall',
      village: 'home',
      type: 'Town Hall',
      upgrade_resource: 'Gold',
      levels: [{ level: 18, build_cost: 1, build_time: 1, required_townhall: 18 }],
    },
    {
      _id: 2,
      name: "Builder's Hut",
      village: 'home',
      type: 'Worker',
      upgrade_resource: 'Gold',
      levels: [{ level: 1, build_cost: 1, build_time: 1 }],
    },
    {
      _id: 3,
      name: 'Gold Mine',
      village: 'home',
      type: 'Resource',
      upgrade_resource: 'Elixir',
      levels: [
        { level: 16, build_cost: 2_000_000, build_time: 86_400, required_townhall: 15 },
        {
          level: 17,
          build_cost: 8_000_000,
          build_time: 172_800,
          required_townhall: 16,
          supercharge: {
            upgrade_resource: 'Elixir',
            levels: [
              { level: 1, build_cost: 1_700_000, build_time: 172_800 },
              { level: 2, build_cost: 1_500_000, build_time: 259_200 },
            ],
          },
        },
      ],
    },
    {
      _id: 4,
      name: 'Builder Hall',
      village: 'builderBase',
      type: 'Town Hall',
      upgrade_resource: 'Builder Gold',
      levels: [{ level: 6, build_cost: 1, build_time: 1 }],
    },
  ],
  troops: [
    {
      _id: 5,
      name: 'Barbarian',
      village: 'home',
      production_building: 'Laboratory',
      upgrade_resource: 'Elixir',
      warden_weight: 0.5,
      healer_weight: 0,
      levels: [
        { level: 11, upgrade_cost: 8_000_000, upgrade_time: 345_600, required_townhall: 15 },
        { level: 12, upgrade_cost: 0, upgrade_time: 0, required_townhall: 16 },
      ],
    },
  ],
  equipment: [
    {
      _id: 6,
      name: 'Barbarian Puppet',
      village: 'home',
      levels: [
        { level: 1, upgrade_cost: { shiny_ore: 120 }, required_townhall: 8 },
        { level: 2, upgrade_cost: { shiny_ore: 0 }, required_townhall: 8 },
      ],
    },
  ],
  helpers: [
    {
      _id: 20,
      name: 'Builder Apprentice',
      village: 'home',
      upgrade_resource: 'Gems',
      levels: [
        { level: 1, upgrade_cost: 100 },
        { level: 2, upgrade_cost: 900 },
        { level: 3, upgrade_cost: 0 },
      ],
    },
  ],
  sceneries: [{ _id: 8, name: 'Epic Scenery', thumbnail: 'sceneries/epic/thumbnail.webp' }],
  decorations: [{ _id: 9, name: 'Torch', village: 'home', max_count: 4 }],
};

test('parses buildings, troop direction, equipment weights, scenery, builders, and captured timers', () => {
  const capturedAt = new Date('2026-07-11T10:00:00.000Z');
  const snapshot = new UpgradeTrackerParser().parse(
    {
      tag: '#TEST',
      name: 'Chief',
      timestamp: capturedAt.getTime() / 1000,
      buildings: [
        { data: 1, lvl: 18 },
        { data: 2, lvl: 1, cnt: 5 },
        { data: 3, lvl: 16, cnt: 2, timer: 3600, supercharge: 1 },
      ],
      buildings2: [{ data: 4, lvl: 6 }],
      units: [{ data: 5, lvl: 11 }],
      equipment: [{ data: 6, lvl: 1 }],
      helpers: [{ data: 20, lvl: 2 }],
      sceneries: [8],
      decos: [{ data: 9, cnt: 3 }],
      boosts: { builder_cost_reduction: 20, builder_time_reduction: 20 },
    },
    { staticData: bundle, now: capturedAt },
  );

  expect(snapshot.homeBuilderCount).toBe(5);
  expect(snapshot.builderBaseBuilderCount).toBe(2);
  const mine = snapshot.items.find((item) => item.name === 'Gold Mine')!;
  expect(mine.steps[0]).toMatchObject({ seconds: 172800, costs: [{ amount: 8000000 }] });
  expect(snapshot.remainingActiveSeconds(mine, new Date('2026-07-11T10:15:00.000Z'))).toBe(2700);
  expect(snapshot.items.find((item) => item.name === 'Barbarian')).toMatchObject({
    wardenWeight: 0.5,
    healerWeight: 0,
  });
  expect(snapshot.items.find((item) => item.isSupercharge)).toMatchObject({
    currentLevel: 1,
    targetLevel: 2,
  });
  expect(
    snapshot.collections.find((item) => item.type === UpgradeCollectionType.sceneries)?.owned,
  ).toBe(true);
  expect(
    snapshot.collections.find((item) => item.type === UpgradeCollectionType.decorations),
  ).toMatchObject({ count: 3, maxCount: 4 });
  const adjusted = snapshot.adjustStep(mine, mine.steps[0]!, capturedAt);
  expect(adjusted).toMatchObject({ seconds: 138240, costs: [{ amount: 6400000 }] });
});

test('planner preserves pending-chain order and active grouped work consumes one instance', () => {
  const start = new Date('2026-07-11T00:00:00.000Z');
  const item = (
    id: number,
    name: string,
    durations: number[],
    count = 1,
    activeSeconds: number | null = null,
  ) =>
    new UpgradeTrackerItem({
      id,
      name,
      imageUrl: '',
      village: UpgradeVillage.home,
      category: UpgradeCategory.defenses,
      queue: UpgradeQueue.builders,
      currentLevel: 0,
      targetLevel: durations.length,
      count,
      steps: durations.map(
        (seconds, index) => new UpgradeStep(index + 1, [new UpgradeCost('gold', 1)], seconds),
      ),
      completedUpgradeSeconds: 0,
      totalUpgradeSeconds: durations.reduce((sum, value) => sum + value, 0),
      activeSeconds,
    });
  const snapshot = new UpgradeTrackerSnapshot({
    tag: '#T',
    name: 'T',
    townHallLevel: 18,
    builderHallLevel: 0,
    homeBuilderCount: 1,
    builderBaseBuilderCount: 1,
    items: [item(1, 'Long', [10, 10]), item(2, 'Short', [5, 5]), item(3, 'Grouped', [20], 2, 30)],
    collections: [],
    boosts: new UpgradeBoosts(),
    events: [],
    capturedAt: start,
  });
  const plan = snapshot.buildPlan({
    queue: UpgradeQueue.builders,
    strategy: UpgradePlanStrategy.balanced,
    village: UpgradeVillage.home,
    startsAt: start,
  });
  const planned = plan.flatMap((lane) => lane.upgrades);
  expect(planned.filter((upgrade) => upgrade.item.name === 'Grouped')).toHaveLength(1);
  expect(
    planned
      .filter((upgrade) => upgrade.item.name !== 'Grouped')
      .map((upgrade) => `${upgrade.item.name}:${upgrade.step.targetLevel}`),
  ).toEqual(['Long:1', 'Short:1', 'Long:2', 'Short:2']);
});

test('normalizes planner category order to the selected village queue', () => {
  const start = new Date('2026-07-11T00:00:00.000Z');
  const item = (
    id: number,
    category: (typeof UpgradeCategory)[keyof typeof UpgradeCategory],
    queue: (typeof UpgradeQueue)[keyof typeof UpgradeQueue],
  ) =>
    new UpgradeTrackerItem({
      id,
      name: category,
      imageUrl: '',
      village: UpgradeVillage.home,
      category,
      queue,
      currentLevel: 0,
      targetLevel: 1,
      count: 1,
      steps: [new UpgradeStep(1, [new UpgradeCost('gold', 1)], 1)],
      completedUpgradeSeconds: 0,
      totalUpgradeSeconds: 1,
    });
  const snapshot = new UpgradeTrackerSnapshot({
    tag: '#T',
    name: 'T',
    townHallLevel: 18,
    builderHallLevel: 0,
    homeBuilderCount: 1,
    builderBaseBuilderCount: 1,
    items: [
      item(1, UpgradeCategory.defenses, UpgradeQueue.builders),
      item(2, UpgradeCategory.troops, UpgradeQueue.laboratory),
      item(3, UpgradeCategory.resources, UpgradeQueue.builders),
    ],
    collections: [],
    boosts: new UpgradeBoosts(),
    events: [],
    capturedAt: start,
  });
  const normalized = normalizeUpgradePlanPreferencesForQueue(
    snapshot,
    new UpgradePlanPreferences({
      homeCategoryOrder: [
        UpgradeCategory.defenses,
        UpgradeCategory.troops,
        UpgradeCategory.resources,
      ],
      homeCategoryShares: new Map([
        [UpgradeCategory.defenses, 50],
        [UpgradeCategory.resources, 50],
      ]),
    }),
    UpgradeVillage.home,
    UpgradeQueue.builders,
  );
  expect(normalized.homeCategoryOrder).toEqual([
    UpgradeCategory.defenses,
    UpgradeCategory.resources,
  ]);
  expect(normalized.priorityTierFor(UpgradeCategory.defenses)).toBe(
    normalized.priorityTierFor(UpgradeCategory.resources),
  );
});
