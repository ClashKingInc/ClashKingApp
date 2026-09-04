import type { AppConfigResponse } from '@clashking/api-contracts/expo';

export const APP_FEATURE_FLAGS = {
  notifications: 'notifications',
  posts: 'posts',
  homeAnnouncements: 'home_announcements',
  leaderboards: 'leaderboards',
  globalStats: 'global_stats',
  calculators: 'calculators',
  subscriptionSupport: 'subscription_support',
  upgradeTracker: 'upgrade_tracker',
  basesArmies: 'bases_armies',
  gameAssets: 'game_assets',
  warWidgets: 'war_widgets',
} as const;

export type KnownFeatureFlag = (typeof APP_FEATURE_FLAGS)[keyof typeof APP_FEATURE_FLAGS];
export type FeaturePlatform = 'ios' | 'android' | 'web';

export const FEATURE_FLAG_DEFAULTS: Readonly<Record<KnownFeatureFlag, boolean>> = {
  notifications: true,
  posts: true,
  home_announcements: true,
  leaderboards: true,
  global_stats: true,
  calculators: true,
  subscription_support: true,
  upgrade_tracker: true,
  bases_armies: false,
  game_assets: true,
  war_widgets: true,
};

export interface RemoteFeatureFlag {
  readonly key: string;
  readonly enabled: boolean;
  readonly rolloutPercentage: number;
  readonly platforms: readonly string[];
  readonly minAppVersion?: string;
  readonly startsAt?: Date;
  readonly endsAt?: Date;
}

export interface FeatureFlagEvaluation {
  readonly platform: FeaturePlatform;
  readonly appVersion: string;
  readonly installationSeed: number;
  readonly now?: Date;
}

export interface RequiredAppUpdate {
  readonly minimumVersion: string;
  readonly storeUrl: string;
  readonly message: string;
}

export function defaultFeatureFlagValue(key: string): boolean {
  return (FEATURE_FLAG_DEFAULTS as Readonly<Record<string, boolean>>)[key] ?? true;
}

export function remoteFeatureFlag(value: AppConfigResponse['flags'][number]): RemoteFeatureFlag {
  return {
    key: value.key,
    enabled: value.enabled,
    rolloutPercentage: Math.trunc(value.rollout_percentage),
    platforms: value.platforms,
    ...(value.min_app_version === undefined ? {} : { minAppVersion: value.min_app_version.trim() }),
    startsAt: parseOptionalDate(value.starts_at),
    endsAt: parseOptionalDate(value.ends_at),
  };
}

export function featureFlagsFromConfig(
  config: AppConfigResponse,
): ReadonlyMap<string, RemoteFeatureFlag> {
  const flags = new Map<string, RemoteFeatureFlag>();
  for (const raw of config.flags) {
    const flag = remoteFeatureFlag(raw);
    if (flag.key.length > 0) flags.set(flag.key, flag);
  }
  return flags;
}

export function requiredAppUpdate(
  config: AppConfigResponse,
  platform: FeaturePlatform,
  currentVersion: string,
): RequiredAppUpdate | null {
  if (platform === 'web') return null;
  const policy = config.updates[platform];
  if (meetsMinimumVersion(currentVersion, policy.minimum_version)) return null;
  return {
    minimumVersion: policy.minimum_version,
    storeUrl: policy.store_url,
    message: policy.message,
  };
}

export function isFeatureFlagEnabled(
  flag: RemoteFeatureFlag | undefined,
  key: string,
  evaluation: FeatureFlagEvaluation,
  fallback = true,
): boolean {
  if (flag === undefined) return fallback;
  const now = evaluation.now ?? new Date();
  if (!flag.enabled) return false;
  if (flag.startsAt !== undefined && flag.startsAt > now) return false;
  if (flag.endsAt !== undefined && flag.endsAt <= now) return false;
  if (flag.platforms.length > 0 && !flag.platforms.includes(evaluation.platform)) {
    return false;
  }
  if (
    flag.minAppVersion !== undefined &&
    flag.minAppVersion.length > 0 &&
    !meetsMinimumVersion(evaluation.appVersion, flag.minAppVersion)
  ) {
    return false;
  }
  if (flag.rolloutPercentage >= 100) return true;
  if (flag.rolloutPercentage <= 0) return false;
  return stableFeatureBucket(key, evaluation.installationSeed) < flag.rolloutPercentage;
}

export function meetsMinimumVersion(current: string, minimum: string): boolean {
  const currentParts = numericVersionParts(current);
  const minimumParts = numericVersionParts(minimum);
  const length = Math.max(currentParts.length, minimumParts.length);
  for (let index = 0; index < length; index += 1) {
    const currentPart = currentParts[index] ?? 0;
    const minimumPart = minimumParts[index] ?? 0;
    if (currentPart !== minimumPart) return currentPart > minimumPart;
  }
  return true;
}

/** Exact FNV-style Flutter implementation, including UTF-16 code units. */
export function stableFeatureBucket(key: string, installationSeed: number): number {
  let hash = (2166136261 ^ installationSeed) >>> 0;
  for (let index = 0; index < key.length; index += 1) {
    hash = Math.imul(hash ^ key.charCodeAt(index), 16777619) & 0x7fffffff;
  }
  return hash % 100;
}

export function generateInstallationSeed(
  cryptoImplementation: Pick<Crypto, 'getRandomValues'> = globalThis.crypto,
): number {
  const range = 0x7fffffff;
  const unbiasedLimit = Math.floor(0x1_0000_0000 / range) * range;
  const value = new Uint32Array(1);
  do {
    cryptoImplementation.getRandomValues(value);
  } while ((value[0] ?? 0) >= unbiasedLimit);
  return (value[0] ?? 0) % range;
}

function numericVersionParts(value: string): number[] {
  return value
    .split('+', 1)[0]!
    .split('.')
    .map((part) => Number.parseInt(part.match(/^\d+/)?.[0] ?? '', 10) || 0);
}

function parseOptionalDate(value: unknown): Date | undefined {
  if (typeof value !== 'string') return undefined;
  const milliseconds = Date.parse(value);
  return Number.isNaN(milliseconds) ? undefined : new Date(milliseconds);
}
