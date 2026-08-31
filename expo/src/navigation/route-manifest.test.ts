import {
  appRoutes,
  desktopHeaderActionRoutes,
  desktopSidebarBodyRoutes,
  desktopSidebarFooterRoutes,
  desktopSidebarRoutes,
  filterEnabledRoutes,
  mobileDrawerBodyRoutes,
  mobileDrawerFooterRoutes,
  mobileDrawerHeaderActionRoutes,
  mobileDrawerRoutes,
  primaryTabRoutes,
  playerHref,
} from './route-manifest';

describe('Flutter navigation parity manifest', () => {
  it('retains the four primary tabs in order', () => {
    expect(primaryTabRoutes.map((route) => route.id)).toEqual(['home', 'players', 'clans', 'war']);
  });

  it('preserves the intentional mobile and desktop utility difference', () => {
    expect(mobileDrawerRoutes.map((route) => route.id)).toContain('subscription');
    expect(mobileDrawerRoutes.map((route) => route.id)).toContain('basesArmies');
    expect(desktopSidebarRoutes.map((route) => route.id)).not.toContain('subscription');
    expect(desktopSidebarRoutes.map((route) => route.id)).not.toContain('basesArmies');
  });

  it('matches Flutter drawer, sidebar, and header membership exactly', () => {
    expect(mobileDrawerHeaderActionRoutes.map(({ id }) => id)).toEqual([
      'achievements',
      'accounts',
    ]);
    expect(mobileDrawerBodyRoutes.map(({ id }) => id)).toEqual([
      'posts',
      'rankings',
      'stats',
      'calculators',
      'subscription',
      'todo',
      'ranked',
      'upgradeTracker',
      'basesArmies',
      'gameAssets',
      'accounts',
    ]);
    expect(mobileDrawerFooterRoutes.map(({ id }) => id)).toEqual(['settings']);
    expect(desktopHeaderActionRoutes.map(({ id }) => id)).toEqual(['achievements', 'accounts']);
    expect(desktopSidebarBodyRoutes.map(({ id }) => id)).toEqual([
      'posts',
      'rankings',
      'stats',
      'calculators',
      'todo',
      'ranked',
      'upgradeTracker',
      'gameAssets',
    ]);
    expect(desktopSidebarFooterRoutes.map(({ id }) => id)).toEqual(['accounts', 'settings']);
  });

  it('hides gated routes unless their exact Flutter feature flag is enabled', () => {
    expect(filterEnabledRoutes(mobileDrawerBodyRoutes, {}).map(({ id }) => id)).toEqual([
      'todo',
      'ranked',
      'accounts',
    ]);
    expect(
      filterEnabledRoutes(mobileDrawerBodyRoutes, {
        posts: true,
        bases_armies: true,
      }).map(({ id }) => id),
    ).toEqual(['posts', 'todo', 'ranked', 'basesArmies', 'accounts']);
  });

  it('keeps route identifiers and hrefs unique', () => {
    expect(new Set(appRoutes.map((route) => route.id)).size).toBe(appRoutes.length);
    expect(new Set(appRoutes.map((route) => route.href)).size).toBe(appRoutes.length);
  });

  it('normalizes tags for detail paths', () => {
    expect(playerHref(' #abc123 ')).toBe('/player/ABC123');
  });
});
