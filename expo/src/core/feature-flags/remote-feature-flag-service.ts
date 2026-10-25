import { AppConfigResponse } from '@clashking/api-contracts/expo';
import { Schema } from 'effect';

import { STORAGE_KEYS } from '../storage/storage';
import type { StringStore } from '../../services/storage/auth-storage';
import type { ApiEnvironment } from '../config/api-config';
import {
  defaultFeatureFlagValue,
  featureFlagsFromConfig,
  isFeatureFlagEnabled,
  type FeatureFlagEvaluation,
  type FeaturePlatform,
  type RemoteFeatureFlag,
} from './feature-flags';

export interface RemoteFeatureFlagServiceOptions {
  readonly environment?: ApiEnvironment;
  readonly loadConfig: () => Promise<AppConfigResponse>;
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

  async refresh(forceRefresh = false): Promise<void> {
    [this.installationSeed, this.appVersion] = await Promise.all([
      this.loadInstallationSeed(),
      this.options.appVersionProvider(),
    ]);
    const key = `appConfig:v1:${this.options.environment ?? 'production'}:${this.options.platform}:${this.appVersion}`;
    const now = (this.options.now?.() ?? new Date()).getTime();
    try {
      const raw = await this.options.preferences.getItem(key);
      const cached = raw ? JSON.parse(raw) : null;
      if (!forceRefresh && cached && typeof cached.at === 'number' && now >= cached.at && now - cached.at < 60_000) {
        this.flags = featureFlagsFromConfig(Schema.decodeUnknownSync(AppConfigResponse)(cached.value));
        return;
      }
    } catch {
      // Corrupt or unavailable local metadata must fall back to the live config.
    }
    const response = await this.options.loadConfig();
    this.flags = featureFlagsFromConfig(response);
    await this.options.preferences.setItem(key, JSON.stringify({ at: now, value: response })).catch(() => undefined);
  }

  isEnabled(key: string, fallback = defaultFeatureFlagValue(key)): boolean {
    // Calculator availability follows the normal remote rollout. The unfinished
    // Farming tool is blocked at the calculator router, including deep links.
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
