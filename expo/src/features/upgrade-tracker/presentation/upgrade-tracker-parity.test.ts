import { Platform } from 'react-native';

import { UpgradeCategory, UpgradePlanPreferences, UpgradeQueue, UpgradeVillage } from '../models';
import { trackerFixture } from './upgrade-tracker-logic.test';
import {
  planQueueOrder,
  priorityTierForOrder,
  replacePlanQueueOrder,
} from './upgrade-tracker-plan-editor';
import { shareTrackerCaptures, trackerShareFilename } from './upgrade-tracker-share';
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
