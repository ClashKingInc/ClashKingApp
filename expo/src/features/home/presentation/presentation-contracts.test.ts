import { createTranslator } from '../../../i18n';
import {
  homeComparisonCardWidth,
  homeComparisonNeedsNavigation,
  homeContentWidth,
  homeRecapWidth,
  isDesktopHome,
  normalizedProgress,
  visibleHomeCards,
  type HomeDashboardModel,
} from './contracts';
import { formatLastRefresh, homeBottomPadding } from './dashboard-screen';
import { buildHomeBannerItems } from './event-banner';
import { clampHomePageIndex, formatHomeDuration } from './home-cards';

const base: HomeDashboardModel = {
  loading: false,
  linkedAccountCount: 1,
  announcements: [],
  upgradeTrackerEnabled: true,
};

describe('home presentation contracts', () => {
  it('preserves Flutter card order and removes the gated Upgrade Tracker card', () => {
    const model: HomeDashboardModel = {
      ...base,
      todo: {
        accounts: [
          {
            account: { tag: '#ONE', name: 'One', subtitle: '#ONE', imageUrl: 'town-hall' },
            status: 'Active now',
            metrics: [],
            done: 0,
            total: 0,
          },
        ],
      },
      ranked: { state: 'empty', configuredCount: 1 },
      upgrade: { state: 'empty', configuredCount: 1 },
    };
    expect(visibleHomeCards(model)).toEqual(['todo', 'ranked', 'upgrade']);
    expect(visibleHomeCards({ ...model, upgradeTrackerEnabled: false })).toEqual([
      'todo',
      'ranked',
    ]);
  });

  it('keeps the web-only desktop breakpoint and bounded content canvases', () => {
    expect(isDesktopHome('web', 899)).toBe(false);
    expect(isDesktopHome('web', 900)).toBe(true);
    expect(isDesktopHome('ios', 1600)).toBe(false);
    expect(homeContentWidth(1599)).toBe(1320);
    expect(homeContentWidth(1600)).toBe(1680);
    expect(homeRecapWidth(1599)).toBe(1120);
    expect(homeRecapWidth(1600)).toBe(1560);
    expect(homeComparisonCardWidth(1120, 1)).toBe(552);
    expect(homeComparisonCardWidth(1120, 4)).toBeLessThanOrEqual(360);
    expect(homeComparisonNeedsNavigation(1120, 4)).toBe(true);
    expect(homeComparisonNeedsNavigation(1560, 4)).toBe(false);
  });

  it('clamps a selected account when refreshed data shrinks', () => {
    expect(clampHomePageIndex(3, 4)).toBe(3);
    expect(clampHomePageIndex(3, 1)).toBe(0);
    expect(clampHomePageIndex(3, 0)).toBe(0);
  });

  it('keeps the bottom overlay clear without double-counting safe area', () => {
    expect(homeBottomPadding(false, 34)).toBe(130);
    expect(homeBottomPadding(true, 34)).toBe(32);
  });

  it('formats metric and event timing with Flutter boundary rules', () => {
    expect(normalizedProgress(3, 2)).toBe(1);
    expect(normalizedProgress(3, null)).toBeNull();
    expect(formatHomeDuration(0)).toBe('Done');
    expect(formatHomeDuration(61)).toBe('1m');
    expect(formatHomeDuration(3600)).toBe('1h');
    expect(formatHomeDuration(86400)).toBe('1d');
    expect(
      formatLastRefresh(
        new Date('2026-08-29T11:42:00.000Z'),
        new Date('2026-08-29T12:00:00.000Z'),
        createTranslator('en'),
      ),
    ).toBe('18 minutes ago');

    const items = buildHomeBannerItems(
      new Date('2026-08-29T12:00:00.000Z'),
      [],
      createTranslator('en'),
      false,
    );
    expect(items[0]?.id).toBe('creator-code');
    expect(items.map(({ id }) => id)).toEqual(
      expect.arrayContaining(['clan-games', 'cwl', 'season', 'league-reset', 'raid']),
    );
  });
});
