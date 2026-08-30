import {
  UpgradeBoosts,
  UpgradeCategory,
  UpgradeCollectionItem,
  UpgradeCollectionType,
  UpgradeCost,
  UpgradePlanPreferences,
  UpgradeQueue,
  UpgradeStep,
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
  UpgradeVillage,
  UpgradeWallResourcePreference,
} from '../models';
import {
  activeTrackerItems,
  buildUpgradeTrackerAccountOptions,
  buildTrackerPlanData,
  filteredUpgradeItems,
  formatTrackerDuration,
  groupPlannedUpgrades,
  groupUpgradeItems,
  planLaneLabel,
  sceneryMusicUrl,
} from './upgrade-tracker-logic';

test('account picker exposes verified linked accounts and excludes stale saved snapshots', () => {
  expect(
    buildUpgradeTrackerAccountOptions(
      [
        { tag: '#VERIFIED', name: 'Old name', townHallLevel: 15, builderHallLevel: 9 },
        { tag: '#STALE', name: 'Stale', townHallLevel: 17, builderHallLevel: 10 },
      ],
      ['#VERIFIED', '#NEW'],
      [
        { tag: '#VERIFIED', name: 'Current name', townHallLevel: 17, builderHallLevel: 10 },
        { tag: '#NEW', name: 'New link', townHallLevel: 14, builderHallLevel: 8 },
      ],
    ),
  ).toEqual([
    { tag: '#VERIFIED', name: 'Current name', townHallLevel: 17, builderHallLevel: 10 },
    { tag: '#NEW', name: 'New link', townHallLevel: 14, builderHallLevel: 8 },
  ]);
});

export function trackerFixture(now = new Date('2026-08-29T12:00:00Z')) {
  const cannon = new UpgradeTrackerItem({
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
      new UpgradeStep(2, [new UpgradeCost('gold', 100)], 3600),
      new UpgradeStep(3, [new UpgradeCost('gold', 200)], 7200),
    ],
    completedUpgradeSeconds: 100,
    totalUpgradeSeconds: 10_900,
    activeSeconds: 1800,
  });
  const lab = new UpgradeTrackerItem({
    id: 2,
    name: 'Barbarian',
    imageUrl: 'barbarian.png',
    village: UpgradeVillage.home,
    category: UpgradeCategory.troops,
    queue: UpgradeQueue.laboratory,
    currentLevel: 2,
    targetLevel: 3,
    count: 1,
    steps: [new UpgradeStep(3, [new UpgradeCost('elixir', 300)], 5400)],
    completedUpgradeSeconds: 0,
    totalUpgradeSeconds: 5400,
  });
  return new UpgradeTrackerSnapshot({
    tag: '#TEST',
    name: 'Tester',
    townHallLevel: 17,
    builderHallLevel: 10,
    homeBuilderCount: 2,
    builderBaseBuilderCount: 2,
    items: [cannon, lab],
    collections: [
      new UpgradeCollectionItem({
        id: 10,
        name: 'Forest Scenery',
        imageUrl: 'forest.png',
        type: UpgradeCollectionType.sceneries,
        owned: true,
        meta: { music: 'https://example.com/music.mp3' },
      }),
    ],
    boosts: new UpgradeBoosts(),
    events: [],
    capturedAt: now,
  });
}

describe('upgrade tracker presentation logic', () => {
  it('builds every queue without dropping costs, active reservations, or finish time', () => {
    const now = new Date('2026-08-29T12:00:00Z');
    const snapshot = trackerFixture(now);
    const plan = buildTrackerPlanData(snapshot, 0, new UpgradePlanPreferences(), now);

    expect(plan.homeBuilders).toHaveLength(2);
    expect(plan.laboratory).toHaveLength(1);
    expect(plan.upgrades.map((upgrade) => upgrade.item.name)).toEqual([
      'Cannon',
      'Barbarian',
      'Cannon',
    ]);
    expect(plan.upgrades[0]?.isOngoing).toBe(true);
    expect(plan.costs).toEqual({ elixir: 300, gold: 300 });
    expect(plan.finishesAt?.getTime()).toBeGreaterThan(now.getTime());
  });

  it('schedules the configured number of walls per week with the selected resource', () => {
    const now = new Date('2026-08-29T12:00:00Z');
    const base = trackerFixture(now);
    const wall = new UpgradeTrackerItem({
      id: 3,
      name: 'Wall',
      imageUrl: 'wall.png',
      village: UpgradeVillage.home,
      category: UpgradeCategory.walls,
      queue: UpgradeQueue.none,
      currentLevel: 1,
      targetLevel: 2,
      count: 2,
      steps: [
        new UpgradeStep(2, [new UpgradeCost('gold', 100), new UpgradeCost('elixir', 100)], 0),
      ],
      completedUpgradeSeconds: 0,
      totalUpgradeSeconds: 0,
    });
    const snapshot = new UpgradeTrackerSnapshot({
      ...base,
      items: [...base.items, wall],
    });
    const plan = buildTrackerPlanData(
      snapshot,
      0,
      new UpgradePlanPreferences({
        wallsPerWeek: 1,
        wallResourcePreference: UpgradeWallResourcePreference.elixir,
      }),
      now,
    );

    expect(plan.walls).toHaveLength(2);
    expect(plan.walls.map((upgrade) => upgrade.costs[0]?.resource)).toEqual(['elixir', 'elixir']);
    expect(plan.walls[1]?.startsAt.getTime()).toBe(now.getTime() + 7 * 86_400_000);

    const sameDay = buildTrackerPlanData(
      snapshot,
      0,
      new UpgradePlanPreferences({
        wallsPerWeek: 2,
        wallResourcePreference: UpgradeWallResourcePreference.elixir,
      }),
      now,
    );
    const groups = groupPlannedUpgrades(sameDay.walls);
    expect(groups).toHaveLength(1);
    expect(groups[0]?.upgrades).toHaveLength(2);
    expect(groups[0]?.costs).toEqual([{ resource: 'elixir', amount: 200 }]);
  });

  it('applies village, remaining, search, category, active and scenery rules', () => {
    const now = new Date('2026-08-29T12:00:00Z');
    const snapshot = trackerFixture(now);
    expect(activeTrackerItems(snapshot, now).map((item) => item.name)).toEqual(['Cannon']);
    expect(filteredUpgradeItems(snapshot, UpgradeVillage.home, 'barb', true)).toHaveLength(1);
    expect(groupUpgradeItems(snapshot.items).map(([category]) => category)).toEqual([
      UpgradeCategory.defenses,
      UpgradeCategory.troops,
    ]);
    expect(sceneryMusicUrl(snapshot.collections[0]!)).toBe('https://example.com/music.mp3');
    expect(
      sceneryMusicUrl({
        type: UpgradeCollectionType.sceneries,
        meta: { thumbnail: 'sceneries/forest/thumbnail.webp' },
      }),
    ).toBe('https://assets.clashk.ing/sceneries/forest/music.ogg');
    expect(
      sceneryMusicUrl({ type: UpgradeCollectionType.skins, meta: { music: 'music.ogg' } }),
    ).toBeNull();
    expect(formatTrackerDuration(90_000)).toBe('1d 1h');
    expect(formatTrackerDuration(86_400)).toBe('1d');
    expect(formatTrackerDuration(3_600)).toBe('1h');
    expect(formatTrackerDuration(30)).toBe('1m');
    expect(formatTrackerDuration(0)).toBe('Now');
    expect(planLaneLabel(UpgradeQueue.builders, 2, 2)).toBe('Goblin Builder');
  });
});
