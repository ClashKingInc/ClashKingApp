import { ApiClient } from '../api/client';
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

describe('RemoteFeatureFlagService', () => {
  it('fetches the public config and applies platform, version, dates, and rollout', async () => {
    const preferences = new MemoryStore();
    let seedCalls = 0;
    const api = new ApiClient({
      baseUrl: 'https://api.example/v2',
      environment: 'production',
      fetchImplementation: async () =>
        new Response(
          JSON.stringify({
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
        ),
    });
    const service = new RemoteFeatureFlagService({
      api,
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
    expect(preferences.values.get('remoteFeatureFlagSeed')).toBe('42');
    expect(seedCalls).toBe(1);
  });

  it('reuses the persisted installation seed and preserves fail-open defaults', async () => {
    const preferences = new MemoryStore();
    await preferences.setItem('remoteFeatureFlagSeed', '99');
    const service = new RemoteFeatureFlagService({
      api: new ApiClient({
        baseUrl: 'https://api.example/v2',
        environment: 'production',
        fetchImplementation: async () => new Response(JSON.stringify({ flags: [] })),
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
  });
});
