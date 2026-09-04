import type { AppConfigResponse } from '@clashking/api-contracts/expo';

import type { StringStore } from '../../services/storage/auth-storage';
import { RemoteFeatureFlagService } from './remote-feature-flag-service';

class MemoryStore implements StringStore {
  readonly values = new Map<string, string>();
  async getItem(key: string) {
    return this.values.get(key) ?? null;
  }
  async setItem(key: string, value: string) {
    this.values.set(key, value);
  }
  async removeItem(key: string) {
    this.values.delete(key);
  }
}

function config(overrides: Partial<AppConfigResponse> = {}): AppConfigResponse {
  return {
    flags: [],
    updates: {
      ios: {
        minimum_version: '0.3.5',
        store_url: 'https://apps.apple.com/app/id123',
        message: 'Update ClashKing to continue.',
      },
      android: {
        minimum_version: '0.3.5',
        store_url: 'https://play.google.com/store/apps/details?id=com.clashking',
        message: 'Update ClashKing to continue.',
      },
      web: null,
    },
    generated_at: '2026-08-29T00:00:00Z',
    ...overrides,
  };
}

describe('RemoteFeatureFlagService', () => {
  it.each([
    ['ios', '0.3.4', true],
    ['ios', '0.3.5', false],
    ['ios', '0.3.5+25', false],
    ['ios', '0.4.0', false],
    ['android', '0.3.4', true],
    ['android', '0.3.5', false],
    ['android', '0.3.5+25', false],
    ['android', '0.4.0', false],
  ] as const)(
    'applies the native minimum on %s at version %s',
    async (platform, version, gated) => {
      const policy = config();
      const service = new RemoteFeatureFlagService({
        loadConfig: async () => policy,
        preferences: new MemoryStore(),
        platform,
        appVersionProvider: async () => version,
        installationSeedProvider: async () => 42,
      });
      await service.refresh();
      expect(service.requiredUpdate()).toEqual(
        gated
          ? {
              minimumVersion: policy.updates[platform].minimum_version,
              storeUrl: policy.updates[platform].store_url,
              message: policy.updates[platform].message,
            }
          : null,
      );
    },
  );

  it('has no update requirement when the initial config request fails', async () => {
    const service = new RemoteFeatureFlagService({
      loadConfig: async () => {
        throw new Error('Config unavailable');
      },
      preferences: new MemoryStore(),
      platform: 'android',
      appVersionProvider: async () => '0.3.4',
      installationSeedProvider: async () => 42,
    });
    await expect(service.refresh()).rejects.toThrow('Config unavailable');
    expect(service.requiredUpdate()).toBeNull();
    expect(service.isEnabled('notifications')).toBe(true);
  });

  it('loads typed config and applies platform, version, dates, and rollout', async () => {
    const preferences = new MemoryStore();
    let seedCalls = 0;
    const service = new RemoteFeatureFlagService({
      loadConfig: async () =>
        config({
          flags: [
            {
              key: 'upgrade_tracker',
              enabled: true,
              rollout_percentage: 100,
              platforms: ['ios'],
              min_app_version: '0.3.5',
              starts_at: '2026-01-01T00:00:00Z',
              ends_at: '2027-01-01T00:00:00Z',
            },
            {
              key: 'game_assets',
              enabled: true,
              rollout_percentage: 100,
              platforms: ['android'],
            },
          ],
        }),
      preferences,
      platform: 'ios',
      appVersionProvider: async () => '0.3.5+25',
      installationSeedProvider: async () => {
        seedCalls += 1;
        return 42;
      },
      now: () => new Date('2026-08-29T00:00:00Z'),
    });

    await service.refresh();

    expect(service.isEnabled('upgrade_tracker')).toBe(true);
    expect(service.isEnabled('game_assets')).toBe(false);
    expect(service.requiredUpdate()).toBeNull();
    expect(preferences.values.get('remoteFeatureFlagSeed')).toBe('42');
    expect(seedCalls).toBe(1);
  });

  it('never gates web and preserves fail-open feature defaults', async () => {
    const preferences = new MemoryStore();
    await preferences.setItem('remoteFeatureFlagSeed', '99');
    const service = new RemoteFeatureFlagService({
      loadConfig: async () =>
        config({
          updates: {
            ios: { minimum_version: '9.0.0', store_url: 'https://ios', message: 'Update.' },
            android: {
              minimum_version: '9.0.0',
              store_url: 'https://android',
              message: 'Update.',
            },
            web: null,
          },
        }),
      preferences,
      platform: 'web',
      appVersionProvider: async () => '0.3.5',
      installationSeedProvider: async () => {
        throw new Error('must not generate');
      },
    });

    await service.refresh();

    expect(service.isEnabled('notifications')).toBe(true);
    expect(service.isEnabled('bases_armies')).toBe(false);
    expect(service.isEnabled('unknown-production-surface')).toBe(true);
    expect(service.requiredUpdate()).toBeNull();
  });

  it('exposes a native forced update when the installed version is below policy', async () => {
    const service = new RemoteFeatureFlagService({
      loadConfig: async () =>
        config({
          updates: {
            ios: {
              minimum_version: '0.4.0',
              store_url: 'https://apps.apple.com/app/id123',
              message: 'A newer ClashKing build is required.',
            },
            android: {
              minimum_version: '0.3.0',
              store_url: 'https://play.google.com/store/apps/details?id=com.clashking',
              message: 'Update ClashKing to continue.',
            },
            web: null,
          },
        }),
      preferences: new MemoryStore(),
      platform: 'ios',
      appVersionProvider: async () => '0.3.5+25',
      installationSeedProvider: async () => 42,
    });

    await service.refresh();

    expect(service.requiredUpdate()).toEqual({
      minimumVersion: '0.4.0',
      storeUrl: 'https://apps.apple.com/app/id123',
      message: 'A newer ClashKing build is required.',
    });
  });
});
