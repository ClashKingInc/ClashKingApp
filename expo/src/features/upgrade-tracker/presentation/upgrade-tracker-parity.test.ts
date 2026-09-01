import { Platform } from 'react-native';

import {
  UpgradeBoosts,
  UpgradeCategory,
  UpgradePlanPreferences,
  UpgradeQueue,
  UpgradeStep,
  UpgradeTrackerItem,
  UpgradeTrackerSnapshot,
  UpgradeVillage,
} from '../models';
import { trackerFixture } from './upgrade-tracker-logic.test';
import {
  planQueueOrder,
  priorityTierForOrder,
  replacePlanQueueOrder,
} from './upgrade-tracker-plan-editor';
import {
  shareTrackerCaptures,
  trackerProgressSections,
  trackerShareFilename,
} from './upgrade-tracker-share';
import { formatSectionProgress, usesContainedUpgradeArt } from './upgrade-tracker-screen';

jest.mock('react-native-draggable-flatlist', () => ({
  ScaleDecorator: ({ children }: { children: React.ReactNode }) => children,
  NestableScrollContainer: ({ children }: { children: React.ReactNode }) => children,
  NestableDraggableFlatList: () => null,
}));

describe('upgrade tracker parity helpers', () => {
  it('formats Flutter-style section progress and uses contained art only for base tiles', () => {
    expect(formatSectionProgress(0.95)).toBe('95');
    expect(formatSectionProgress(0.955)).toBe('95.5');
    expect(formatSectionProgress(1.2)).toBe('100');
    expect(usesContainedUpgradeArt(UpgradeCategory.defenses)).toBe(true);
    expect(usesContainedUpgradeArt(UpgradeCategory.troops)).toBe(false);
    expect(usesContainedUpgradeArt(UpgradeCategory.equipment)).toBe(false);
  });

  it('normalizes priority tiers and preserves categories from other queues', () => {
    const snapshot = trackerFixture();
    const preferences = new UpgradePlanPreferences({
      homeCategoryOrder: [UpgradeCategory.troops, UpgradeCategory.defenses],
      homeCategoryShares: new Map([
        [UpgradeCategory.troops, 50],
        [UpgradeCategory.defenses, 25],
      ]),
    });
    expect(
      planQueueOrder(snapshot, preferences, UpgradeVillage.home, UpgradeQueue.builders),
    ).toEqual([UpgradeCategory.defenses]);
    expect(
      replacePlanQueueOrder(
        snapshot,
        preferences.homeCategoryOrder,
        UpgradeVillage.home,
        UpgradeQueue.builders,
        [UpgradeCategory.defenses],
      ),
    ).toEqual([UpgradeCategory.troops, UpgradeCategory.defenses]);
    expect(
      priorityTierForOrder(
        preferences.homeCategoryOrder,
        preferences.homeCategoryShares,
        UpgradeCategory.defenses,
      ),
    ).toBe(1);
  });

  it('groups the Home Village progress export into the requested eight sections', () => {
    const definitions = [
      [UpgradeCategory.walls, UpgradeQueue.builders],
      [UpgradeCategory.defenses, UpgradeQueue.builders],
      [UpgradeCategory.guardians, UpgradeQueue.builders],
      [UpgradeCategory.heroes, UpgradeQueue.builders],
      [UpgradeCategory.troops, UpgradeQueue.laboratory],
      [UpgradeCategory.pets, UpgradeQueue.pets],
      [UpgradeCategory.equipment, UpgradeQueue.none],
      [UpgradeCategory.builders, UpgradeQueue.none],
      [UpgradeCategory.craftedDefenses, UpgradeQueue.builders],
    ] as const;
    const items = definitions.map(
      ([category, queue], index) =>
        new UpgradeTrackerItem({
          id: index + 1,
          name: `${category}-${index}`,
          imageUrl: `https://example.com/${category}.png`,
          village: UpgradeVillage.home,
          category,
          queue,
          currentLevel: 0,
          targetLevel: 1,
          count: 1,
          steps: [new UpgradeStep(1, [], 60)],
          completedUpgradeSeconds: 0,
          totalUpgradeSeconds: 60,
        }),
    );
    const snapshot = new UpgradeTrackerSnapshot({
      tag: '#SECTIONS',
      name: 'Sections',
      townHallLevel: 18,
      builderHallLevel: 10,
      homeBuilderCount: 6,
      builderBaseBuilderCount: 2,
      items,
      collections: [],
      boosts: new UpgradeBoosts(),
      events: [],
      capturedAt: new Date('2026-08-29T12:00:00Z'),
    });

    const sections = trackerProgressSections(snapshot, UpgradeVillage.home);
    expect(sections.map((section) => section.key)).toEqual([
      'walls',
      'buildings',
      'heroes',
      'laboratory',
      'pets',
      'equipment',
      'helpers',
      'craftedDefenses',
    ]);
    expect(sections.find((section) => section.key === 'buildings')?.summary.levelsRemaining).toBe(
      2,
    );
    expect(
      sections
        .filter((section) => section.key !== 'buildings')
        .every((section) => section.summary.levelsRemaining === 1),
    ).toBe(true);
  });

  it('captures and shares all three exact Flutter exports on native', async () => {
    const original = Platform.OS;
    Object.defineProperty(Platform, 'OS', { configurable: true, value: 'ios' });
    const capture = jest.fn(async (_preview: string, filename: string) => `/tmp/${filename}`);
    const nativeShare = jest.fn(async () => undefined);
    try {
      const result = await shareTrackerCaptures({
        snapshot: { name: 'Tester', tag: '#TEST' },
        selected: 'home',
        all: true,
        capture,
        nativeShare,
        webDownload: jest.fn(),
      });
      expect(result.captures.map((item) => item.filename)).toEqual([
        'clashking-home-progress-test.png',
        'clashking-builder-progress-test.png',
        'clashking-collection-test.png',
      ]);
      expect(nativeShare).toHaveBeenCalledWith(
        result.captures.map((item) => item.url),
        'Tester progress and collection on ClashKing',
      );
    } finally {
      Object.defineProperty(Platform, 'OS', { configurable: true, value: original });
    }
  });

  it('downloads every captured PNG on web and uses single-export names', async () => {
    const original = Platform.OS;
    Object.defineProperty(Platform, 'OS', { configurable: true, value: 'web' });
    const webDownload = jest.fn();
    try {
      await shareTrackerCaptures({
        snapshot: { name: 'Tester', tag: '#TEST' },
        selected: 'collection',
        all: false,
        capture: async (_preview, filename) => `data:image/png;name=${filename}`,
        nativeShare: jest.fn(),
        webDownload,
      });
      expect(trackerShareFilename({ tag: '#TEST' }, 'collection', true)).toBe(
        'clashking-collection-test.png',
      );
      expect(webDownload).toHaveBeenCalledWith(
        'data:image/png;name=clashking-collection-test.png',
        'clashking-collection-test.png',
      );
    } finally {
      Object.defineProperty(Platform, 'OS', { configurable: true, value: original });
    }
  });
});
