import {
  normalizeUpgradePlanPreferencesForQueue,
  UpgradeBoosts,
  UpgradeCategory,
  UpgradeCollectionItem,
  UpgradeCollectionType,
  UpgradeCost,
  UpgradeEventModifier,
  UpgradePlanGoal,
  UpgradePlanPreferences,
  UpgradePlanStrategy,
  UpgradeProgressBasis,
  UpgradeQueue,
  UpgradeStep,
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
  UpgradeVillage,
  UpgradeWallResourcePreference,
} from './upgrade-tracker-models';

const capturedAt = new Date('2026-08-30T12:00:00.000Z');

function item(overrides: Partial<ConstructorParameters<typeof UpgradeTrackerItem>[0]> = {}) {
  return new UpgradeTrackerItem({
    id: 1,
    name: 'Cannon',
    imageUrl: 'cannon.png',
    village: UpgradeVillage.home,
    category: UpgradeCategory.defenses,
    queue: UpgradeQueue.builders,
    currentLevel: 1,
    targetLevel: 3,
    count: 1,
    steps: [
      new UpgradeStep(2, [new UpgradeCost('gold', 100)], 100),
      new UpgradeStep(3, [new UpgradeCost('gold', 200), new UpgradeCost('elixir', 50)], 200),
    ],
    completedUpgradeSeconds: 50,
    totalUpgradeSeconds: 350,
    ...overrides,
  });
}

function snapshot(
  items: readonly UpgradeTrackerItem[],
  overrides: Partial<ConstructorParameters<typeof UpgradeTrackerSnapshot>[0]> = {},
) {
  return new UpgradeTrackerSnapshot({
    tag: '#TEST',
    name: 'Chief',
    townHallLevel: 18,
    builderHallLevel: 10,
    homeBuilderCount: 2,
    builderBaseBuilderCount: 2,
    items,
    collections: [],
    boosts: new UpgradeBoosts(),
    events: [],
    capturedAt,
    ...overrides,
  });
}

test('item completion metrics clamp bad inputs and aggregate resource costs', () => {
  const upgrade = item();
  expect(upgrade.planKey).toBe('1:defenses');
  expect(upgrade.levelsRemaining).toBe(2);
  expect(upgrade.totalSeconds).toBe(300);
  expect(upgrade.totalCosts).toEqual({ gold: 300, elixir: 50 });
  expect(upgrade.progressCompletion).toBeCloseTo(1 / 7);

  expect(
    item({
      progressBasis: UpgradeProgressBasis.resources,
      completedResourceWeight: 150,
      totalResourceWeight: 100,
    }).resourceCompletion,
  ).toBe(1);
  expect(item({ currentLevel: 3 }).resourceCompletion).toBe(1);
  expect(item({ currentLevel: 0, targetLevel: 0, totalUpgradeSeconds: 0 }).progressCompletion).toBe(
    1,
  );
  expect(item({ currentLevel: 0, targetLevel: 1, totalUpgradeSeconds: 0 }).progressCompletion).toBe(
    0,
  );
});

test('plan preferences parse legacy values, reject malformed entries, and serialize canonically', () => {
  const preferences = UpgradePlanPreferences.fromJson({
    category_order: [UpgradeCategory.resources, 'invalid', UpgradeCategory.resources],
    builder_base_category_order: [UpgradeCategory.defenses],
    category_targets: { resources: '120', defenses: 0, invalid: 40 },
    home_category_shares: { resources: 40 },
    prioritize_unbuilt: 'false',
    prioritize_unbuilt_laboratory: 'true',
    home_goal: UpgradePlanGoal.catchUp,
    builder_base_goal: 'invalid',
    wall_resource_preference: UpgradeWallResourcePreference.elixir,
    walls_per_week: 500,
  });

  expect(preferences.orderFor(UpgradeVillage.home)).toEqual([UpgradeCategory.resources]);
  expect(preferences.orderFor(UpgradeVillage.builderBase)).toEqual([UpgradeCategory.defenses]);
  expect(preferences.targetFor(UpgradeCategory.resources)).toBe(100);
  expect(preferences.targetFor(UpgradeCategory.defenses)).toBe(1);
  expect(preferences.shareFor(UpgradeCategory.resources)).toBe(40);
  expect(preferences.goalFor(UpgradeVillage.home)).toBe(UpgradePlanGoal.catchUp);
  expect(preferences.goalFor(UpgradeVillage.builderBase)).toBe(UpgradePlanGoal.maxCurrentHall);
  expect(preferences.prioritizeUnbuiltFor(UpgradeQueue.builders)).toBe(false);
  expect(preferences.prioritizeUnbuiltFor(UpgradeQueue.laboratory)).toBe(true);
  expect(preferences.prioritizeUnbuiltFor(UpgradeQueue.none)).toBe(false);
  expect(preferences.categoryRank(UpgradeCategory.resources)).toBe(0);
  expect(preferences.categoryRank(UpgradeCategory.builders)).toBe(999);
  expect(preferences.wallsPerWeek).toBe(100);
  expect(preferences.toJson()).toMatchObject({
    home_goal: UpgradePlanGoal.catchUp,
    wall_resource_preference: UpgradeWallResourcePreference.elixir,
    walls_per_week: 100,
    prioritize_unbuilt_builders: false,
  });
  expect(UpgradePlanPreferences.fromJson(null).homeGoal).toBe(UpgradePlanGoal.maxCurrentHall);
});

test('snapshot derives helper state, cached filters, mixed summaries, and collection metadata', () => {
  const helper = item({
    id: 2,
    name: 'Builder Apprentice',
    category: UpgradeCategory.builders,
    queue: UpgradeQueue.none,
    currentLevel: 2,
    targetLevel: 2,
    steps: [],
    completedUpgradeSeconds: 0,
    totalUpgradeSeconds: 0,
    cooldownSeconds: 900,
  });
  const timed = item({ activeSeconds: 180, helperSeconds: 120 });
  const wall = item({
    id: 3,
    name: 'Wall',
    category: UpgradeCategory.walls,
    queue: UpgradeQueue.none,
    progressBasis: UpgradeProgressBasis.resources,
    completedResourceWeight: 25,
    totalResourceWeight: 100,
    steps: [new UpgradeStep(2, [new UpgradeCost('gold', 1000)], 0)],
    completedUpgradeSeconds: 0,
    totalUpgradeSeconds: 0,
  });
  const collection = new UpgradeCollectionItem({
    id: 10,
    name: 'Scenery',
    imageUrl: 'scene.png',
    type: UpgradeCollectionType.sceneries,
    owned: true,
  });
  const data = snapshot([timed, wall, helper], { collections: [collection] });
  const afterMinute = new Date('2026-08-30T12:01:00.000Z');

  expect(data.builderCount).toBe(2);
  expect(data.buildersFor(UpgradeVillage.builderBase)).toBe(2);
  expect(data.remainingCapturedSeconds(180, afterMinute)).toBe(120);
  expect(data.remainingCapturedSeconds(-1, afterMinute)).toBe(0);
  expect(data.activeElapsedSeconds(timed, afterMinute)).toBe(0);
  expect(data.activeElapsedSeconds(timed, new Date('2026-08-30T12:02:00.000Z'))).toBe(40);
  expect(data.remainingHelperSeconds(timed, afterMinute)).toBe(60);
  expect(data.remainingCooldownSeconds(helper, afterMinute)).toBe(840);
  expect(data.helperNameFor(timed)).toBe('Builder Apprentice');
  expect(data.itemsFor({ village: UpgradeVillage.home, remainingOnly: true })).toHaveLength(2);
  expect(data.itemsFor({ village: UpgradeVillage.home, remainingOnly: true })).toBe(
    data.itemsFor({ village: UpgradeVillage.home, remainingOnly: true }),
  );
  expect(data.overallSummary().basis).toBe(UpgradeProgressBasis.mixed);
  expect(data.summaryFor(UpgradeCategory.walls).completion).toBe(0.25);
  expect(data.summaryFor(UpgradeCategory.walls)).toBe(data.summaryFor(UpgradeCategory.walls));
  expect(collection).toMatchObject({ count: 0, maxCount: 1, village: null, subtitle: null });
});

test('event modifiers combine with account perks and planning honors filters and lane reservations', () => {
  const start = capturedAt;
  const event = new UpgradeEventModifier(
    'Hammer Jam',
    new Date('2026-08-30T11:00:00.000Z'),
    new Date('2026-08-31T11:00:00.000Z'),
    50,
    20,
    new Set(['gold']),
    new Set([UpgradeCategory.defenses]),
  );
  const long = item({ id: 1, name: 'Long', activeSeconds: 50 });
  const cheap = item({
    id: 2,
    name: 'Cheap',
    currentLevel: 0,
    targetLevel: 1,
    steps: [new UpgradeStep(1, [new UpgradeCost('gold', 10)], 10)],
    completedUpgradeSeconds: 0,
    totalUpgradeSeconds: 10,
  });
  const data = snapshot([long, cheap], {
    homeBuilderCount: 1,
    boosts: new UpgradeBoosts({ builderCostReductionPercent: 10, builderTimeReductionPercent: 10 }),
    events: [event],
  });

  expect(event.appliesAt(start, long, 'gold')).toBe(true);
  expect(event.appliesAt(start, long, 'elixir')).toBe(false);
  expect(data.adjustStep(long, long.steps[0]!, start)).toMatchObject({
    seconds: 72,
    costs: [{ resource: 'gold', amount: 45 }],
  });
  const plan = data.buildPlan({
    queue: UpgradeQueue.builders,
    strategy: UpgradePlanStrategy.cheapest,
    startsAt: start,
    includedItemKeys: new Set([cheap.planKey]),
  });
  expect(plan).toHaveLength(1);
  expect(plan[0]?.reservedUntil).toEqual(new Date('2026-08-30T12:00:50.000Z'));
  expect(plan[0]?.upgrades.map((upgrade) => upgrade.item.name)).toEqual(['Cheap']);
  expect(plan[0]?.finishesAt).toEqual(new Date('2026-08-30T12:00:57.000Z'));

  const normalized = normalizeUpgradePlanPreferencesForQueue(
    data,
    new UpgradePlanPreferences({
      homeCategoryOrder: [UpgradeCategory.resources, UpgradeCategory.defenses],
    }),
    UpgradeVillage.home,
    UpgradeQueue.builders,
  );
  expect(normalized.homeCategoryOrder).toEqual([UpgradeCategory.defenses]);
});
