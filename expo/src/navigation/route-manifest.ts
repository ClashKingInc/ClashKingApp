import type { MessageKey } from '../i18n';

export type FeatureGate =
  | 'notifications'
  | 'posts'
  | 'home_announcements'
  | 'leaderboards'
  | 'global_stats'
  | 'calculators'
  | 'subscription_support'
  | 'upgrade_tracker'
  | 'bases_armies'
  | 'game_assets'
  | 'war_widgets';

export type AppRouteId =
  | 'home'
  | 'players'
  | 'clans'
  | 'war'
  | 'search'
  | 'posts'
  | 'rankings'
  | 'stats'
  | 'calculators'
  | 'subscription'
  | 'todo'
  | 'ranked'
  | 'upgradeTracker'
  | 'basesArmies'
  | 'gameAssets'
  | 'accounts'
  | 'settings'
  | 'achievements';

export interface AppRouteDefinition {
  id: AppRouteId;
  href: string;
  labelKey: MessageKey;
  icon: RouteIconName;
  selectedIcon?: RouteIconName;
  feature?: FeatureGate;
  primaryTab?: boolean;
  mobileDrawer?: boolean;
  desktopSidebar?: boolean;
}

export type RouteIconName =
  | 'house'
  | 'house-filled'
  | 'user-round'
  | 'user-round-filled'
  | 'users-round'
  | 'users-round-filled'
  | 'swords'
  | 'search'
  | 'newspaper'
  | 'chart-no-axes-combined'
  | 'chart-pie'
  | 'calculator'
  | 'heart'
  | 'list-checks'
  | 'trophy'
  | 'arrow-up-circle'
  | 'shield'
  | 'images'
  | 'user-cog'
  | 'settings'
  | 'goal';

export type FeatureState = Partial<Record<FeatureGate, boolean>>;

/**
 * One source of truth for navigation without erasing existing platform drift.
 * Flutter deliberately omits Subscription and Bases/Armies from its desktop
 * sidebar while exposing them in the mobile drawer; parity keeps that behavior.
 */
export const appRoutes = [
  {
    id: 'home',
    href: '/',
    labelKey: 'navigationHome',
    icon: 'house',
    selectedIcon: 'house-filled',
    primaryTab: true,
  },
  {
    id: 'players',
    href: '/players',
    labelKey: 'searchTabPlayers',
    icon: 'user-round',
    selectedIcon: 'user-round-filled',
    primaryTab: true,
  },
  {
    id: 'clans',
    href: '/clans',
    labelKey: 'searchTabClans',
    icon: 'users-round',
    selectedIcon: 'users-round-filled',
    primaryTab: true,
  },
  {
    id: 'war',
    href: '/war',
    labelKey: 'warTitle',
    icon: 'swords',
    selectedIcon: 'swords',
    primaryTab: true,
  },
  {
    id: 'search',
    href: '/search',
    labelKey: 'searchGlobalHint',
    icon: 'search',
  },
  {
    id: 'posts',
    href: '/posts',
    labelKey: 'postsTitle',
    icon: 'newspaper',
    feature: 'posts',
    mobileDrawer: true,
    desktopSidebar: true,
  },
  {
    id: 'rankings',
    href: '/rankings',
    labelKey: 'clanRankingsTab',
    icon: 'chart-no-axes-combined',
    feature: 'leaderboards',
    mobileDrawer: true,
    desktopSidebar: true,
  },
  {
    id: 'stats',
    href: '/stats',
    labelKey: 'generalStats',
    icon: 'chart-pie',
    feature: 'global_stats',
    mobileDrawer: true,
    desktopSidebar: true,
  },
  {
    id: 'calculators',
    href: '/calculators',
    labelKey: 'drawerCalculators',
    icon: 'calculator',
    feature: 'calculators',
    mobileDrawer: true,
    desktopSidebar: true,
  },
  {
    id: 'subscription',
    href: '/subscription',
    labelKey: 'drawerSubscription',
    icon: 'heart',
    feature: 'subscription_support',
    mobileDrawer: true,
    desktopSidebar: false,
  },
  {
    id: 'todo',
    href: '/todo',
    labelKey: 'todoTitle',
    icon: 'list-checks',
    mobileDrawer: true,
    desktopSidebar: true,
  },
  {
    id: 'ranked',
    href: '/ranked',
    labelKey: 'rankedLeagueTitle',
    icon: 'trophy',
    mobileDrawer: true,
    desktopSidebar: true,
  },
  {
    id: 'upgradeTracker',
    href: '/upgrade-tracker',
    labelKey: 'drawerUpgradeTracker',
    icon: 'arrow-up-circle',
    feature: 'upgrade_tracker',
    mobileDrawer: true,
    desktopSidebar: true,
  },
  {
    id: 'basesArmies',
    href: '/bases-armies',
    labelKey: 'drawerBasesArmies',
    icon: 'shield',
    feature: 'bases_armies',
    mobileDrawer: true,
    desktopSidebar: false,
  },
  {
    id: 'gameAssets',
    href: '/game-assets',
    labelKey: 'drawerGameAssets',
    icon: 'images',
    feature: 'game_assets',
    mobileDrawer: true,
    desktopSidebar: true,
  },
  {
    id: 'accounts',
    href: '/accounts',
    labelKey: 'drawerManageAccounts',
    icon: 'user-cog',
    mobileDrawer: true,
    desktopSidebar: true,
  },
  {
    id: 'settings',
    href: '/settings',
    labelKey: 'generalSettings',
    icon: 'settings',
    mobileDrawer: true,
    desktopSidebar: true,
  },
  {
    id: 'achievements',
    href: '/achievements',
    labelKey: 'achievementsTitle',
    icon: 'goal',
  },
] as const satisfies readonly AppRouteDefinition[];

const route = (id: string) => {
  const match = appRoutes.find((candidate) => candidate.id === id);
  if (!match) throw new Error(`Unknown app route: ${id}`);
  return match;
};

export const primaryTabRoutes = ['home', 'players', 'clans', 'war'].map(route);

export const mobileDrawerHeaderActionRoutes = ['achievements', 'accounts'].map(route);
export const mobileDrawerBodyRoutes = [
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
].map(route);
export const mobileDrawerFooterRoutes = ['settings'].map(route);
export const mobileDrawerRoutes = [...mobileDrawerBodyRoutes, ...mobileDrawerFooterRoutes];

export const desktopHeaderActionRoutes = ['achievements', 'accounts'].map(route);
export const desktopSidebarBodyRoutes = [
  'posts',
  'rankings',
  'stats',
  'calculators',
  'todo',
  'ranked',
  'upgradeTracker',
  'gameAssets',
].map(route);
export const desktopSidebarFooterRoutes = ['accounts', 'settings'].map(route);
export const desktopSidebarRoutes = [...desktopSidebarBodyRoutes, ...desktopSidebarFooterRoutes];

export function isRouteEnabled(definition: AppRouteDefinition, features: FeatureState): boolean {
  return definition.feature === undefined || features[definition.feature] === true;
}

export function filterEnabledRoutes<T extends AppRouteDefinition>(
  routes: readonly T[],
  features: FeatureState,
): T[] {
  return routes.filter((definition) => isRouteEnabled(definition, features));
}

export function playerHref(tag: string): string {
  return `/player/${encodeTag(tag)}`;
}

export function clanHref(tag: string): string {
  return `/clan/${encodeTag(tag)}`;
}

export function warHref(tag: string): string {
  return `/war/${encodeTag(tag)}`;
}

function encodeTag(tag: string): string {
  const normalized = tag.trim().replace(/^#/, '').toUpperCase();
  return encodeURIComponent(normalized);
}
