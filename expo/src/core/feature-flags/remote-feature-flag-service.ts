import type { ApiClient } from '../api/client';
import { STORAGE_KEYS } from '../storage/storage';
import type { StringStore } from '../../services/storage/auth-storage';
import {
  defaultFeatureFlagValue,
  isFeatureFlagEnabled,
  parseFeatureFlagResponse,
  type FeatureFlagEvaluation,
  type FeaturePlatform,
  type RemoteFeatureFlag,
} from './feature-flags';

export interface RemoteFeatureFlagServiceOptions {
  readonly api: ApiClient;
  readonly preferences: StringStore;
  readonly platform: FeaturePlatform;
  readonly appVersionProvider: () => Promise<string>;
  readonly installationSeedProvider: () => Promise<number>;
  readonly now?: () => Date;
}

export class RemoteFeatureFlagService {
  private flags: ReadonlyMap<string, RemoteFeatureFlag> = new Map();
  private installationSeed = 0;
  private appVersion = '';

  constructor(private readonly options: RemoteFeatureFlagServiceOptions) {}

  async refresh(): Promise<void> {
    [this.installationSeed, this.appVersion] = await Promise.all([
      this.loadInstallationSeed(),
      this.options.appVersionProvider(),
    ]);
    const response = await this.options.api.requestRecord('/app/config', {
      requiresAuth: false,
    });
    this.flags = parseFeatureFlagResponse(response);
  }

  isEnabled(key: string, fallback = defaultFeatureFlagValue(key)): boolean {
    const evaluation: FeatureFlagEvaluation = {
      platform: this.options.platform,
      appVersion: this.appVersion,
      installationSeed: this.installationSeed,
      now: this.options.now?.(),
    };
    return isFeatureFlagEnabled(this.flags.get(key), key, evaluation, fallback);
  }

  private async loadInstallationSeed(): Promise<number> {
    const stored = await this.options.preferences.getItem(STORAGE_KEYS.remoteFeatureFlagSeed);
    const parsed = stored === null ? Number.NaN : Number.parseInt(stored, 10);
    if (Number.isInteger(parsed)) return parsed;

    const seed = await this.options.installationSeedProvider();
    if (!Number.isInteger(seed) || seed < 0 || seed >= 0x7fffffff) {
      throw new RangeError('Feature-flag installation seed must be a signed 31-bit integer.');
    }
    await this.options.preferences.setItem(STORAGE_KEYS.remoteFeatureFlagSeed, String(seed));
    return seed;
  }
}
