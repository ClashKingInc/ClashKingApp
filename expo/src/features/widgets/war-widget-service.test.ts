import type { StringStore } from '../../services/storage/auth-storage';
import { WIDGET_STORAGE_KEYS } from '../../core/storage/storage';
import type { NativeWidgetBridge, WarWidgetServiceOptions, WidgetFeatureFlags } from './contracts';
import {
  clanOptionsFromProfiles,
  normalizedClanTag,
  selectedClanTagFromProfiles,
  WarWidgetService,
  WAR_WIDGET_BACKGROUND_TASK,
  warInfoKeyForClan,
} from './war-widget-service';
import {
  buildNotInClanWidgetPayload,
  buildWarWidgetErrorPayload,
  buildWarWidgetPayload,
} from './war-widget-payload';

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

function harness(overrides: Partial<WarWidgetServiceOptions> = {}) {
  const mirror = new MemoryStore();
  const preferences = new MemoryStore();
  const native: jest.Mocked<NativeWidgetBridge> = {
    setWidgetValue: jest.fn(async (_key, _value) => undefined),
    reloadWidgets: jest.fn(async () => undefined),
    consumePendingWidgetAction: jest.fn(async () => null),
    readLegacyWidgetValues: jest.fn(async () => ({})),
    requestPinWarWidget: jest.fn(async () => ({ supported: true, requested: true })),
  };
  const featureFlags: jest.Mocked<WidgetFeatureFlags> = {
    refresh: jest.fn(async () => undefined),
    isEnabled: jest.fn((_key: string, _fallback?: boolean) => true),
  };
  const reportError = jest.fn(async () => undefined);
  const options: WarWidgetServiceOptions = {
    platform: 'android',
    native,
    mirror,
    preferences,
    featureFlags,
    backgroundScheduler: { registerPeriodicTask: jest.fn(async () => undefined) },
    proxyUrl: 'https://api.clashk.ing/proxy/v1',
    apiV2Url: 'https://api.clashk.ing/v2',
    loadWarSummary: jest.fn(async () => ({ war_info: { state: 'notInWar' } })),
    getFirstAvailableAccount: jest.fn(async () => null),
    loadPlayerClanTag: jest.fn(async () => null),
    now: () => new Date(2026, 0, 2, 12, 34),
    reportError,
    ...overrides,
  };
  return {
    service: new WarWidgetService(options),
    options,
    native,
    mirror,
    preferences,
    featureFlags,
    reportError,
  };
}

describe('war widget payloads', () => {
  const now = new Date(2026, 0, 2, 12, 34);

  test('builds exact no-clan, error, access-denied, and idle payloads', () => {
    expect(JSON.parse(buildNotInClanWidgetPayload(now))).toEqual({
      updatedAt: 'Updated at 12:34',
      timeState: '',
      state: 'notInClan',
      mode: 'war',
    });
    expect(JSON.parse(buildWarWidgetErrorPayload(now))).toEqual(
      expect.objectContaining({ state: 'error', primaryText: 'Unable to load war data' }),
    );
    expect(
      JSON.parse(buildWarWidgetPayload({ war_info: { state: 'accessDenied' } }, '#A', now)),
    ).toEqual(expect.objectContaining({ state: 'accessDenied', statusIcon: '🔒' }));
    expect(JSON.parse(buildWarWidgetPayload({}, '#A', now))).toEqual(
      expect.objectContaining({ state: 'notInWar', primaryText: 'Not in War' }),
    );
  });

  test('builds the retained regular-war contract', () => {
    const payload = JSON.parse(
      buildWarWidgetPayload(
        {
          isInWar: true,
          war_info: {
            currentWarInfo: {
              state: 'inWar',
              teamSize: 15,
              endTime: new Date(2026, 0, 2, 14, 4).toISOString(),
              clan: {
                name: 'Home',
                stars: 20,
                attacks: 12,
                destructionPercentage: 88.1,
                badgeUrls: { medium: 'home.png' },
              },
              opponent: {
                name: 'Away',
                stars: 18,
                attacks: 11,
                destructionPercentage: 80,
                badgeUrls: { medium: 'away.png' },
              },
            },
          },
        },
        '#HOME',
        now,
      ),
    );
    expect(payload).toEqual({
      state: 'inWar',
      mode: 'war',
      updatedAt: 'Updated at 12:34',
      timeState: '1h 30m left',
      score: '20 - 18',
      statusIcon: '⚔️',
      primaryText: '1h 30m left',
      secondaryText: '20 - 18',
      colorTheme: 'winning',
      clan: {
        name: 'Home',
        badgeUrlMedium: 'home.png',
        percent: '88.10%',
        attacks: '12/30',
        stars: 20,
        maxStars: 45,
      },
      opponent: {
        name: 'Away',
        badgeUrlMedium: 'away.png',
        percent: '80.00%',
        attacks: '11/30',
        stars: 18,
        maxStars: 45,
      },
    });
  });

  test('selects and reorders the active CWL war for the requested clan', () => {
    const payload = JSON.parse(
      buildWarWidgetPayload(
        {
          isInCwl: true,
          league_info: { season: '2026-01', clans: [{ tag: '#OURS', rank: 2 }] },
          war_league_infos: [
            {
              state: 'inWar',
              teamSize: 15,
              clan: { tag: '#THEIRS', name: 'Theirs', stars: 10, badgeUrls: {} },
              opponent: { tag: '#OURS', name: 'Ours', stars: 12, badgeUrls: {} },
            },
          ],
        },
        '#OURS',
        now,
      ),
    );
    expect(payload).toEqual(
      expect.objectContaining({
        state: 'cwl',
        mode: 'cwl',
        score: '12 - 10',
        cwlRank: 2,
        cwlLeague: '2026-01',
        clan: expect.objectContaining({ name: 'Ours', stars: 12, attacks: '0/15' }),
        opponent: expect.objectContaining({ name: 'Theirs', stars: 10 }),
      }),
    );
  });

  test('formats preparation and ended wars with the correct timing, result, and fallbacks', () => {
    const preparation = JSON.parse(
      buildWarWidgetPayload(
        {
          war_info: {
            currentWarInfo: {
              state: 'preparation',
              teamSize: 5,
              startTime: new Date(2026, 0, 2, 13, 49).toISOString(),
              clan: { stars: 0 },
              opponent: { stars: 0 },
            },
          },
        },
        '#HOME',
        now,
      ),
    );
    expect(preparation).toMatchObject({
      state: 'preparation',
      primaryText: 'Starts in 1h 15m',
      colorTheme: 'preparation',
      clan: { name: 'Unknown', badgeUrlMedium: expect.stringContaining('clashkinglogo') },
    });

    const victory = JSON.parse(
      buildWarWidgetPayload(
        {
          war_info: {
            currentWarInfo: {
              state: 'warEnded',
              teamSize: 10,
              clan: { stars: 29, badgeUrls: { small: 'small.png', large: 'large.png' } },
              opponent: { stars: 28 },
            },
          },
        },
        '#HOME',
        now,
      ),
    );
    expect(victory).toMatchObject({
      primaryText: 'Victory!',
      score: '29 - 28',
      statusIcon: '🏆',
      clan: { badgeUrlMedium: 'small.png' },
    });

    const soon = JSON.parse(
      buildWarWidgetPayload(
        {
          isInWar: true,
          war_info: {
            currentWarInfo: {
              state: 'inWar',
              endTime: new Date(2026, 0, 2, 12, 49).toISOString(),
              clan: { stars: 1 },
              opponent: { stars: 2 },
            },
          },
        },
        '#HOME',
        now,
      ),
    );
    expect(soon).toMatchObject({ primaryText: 'Ends at 12:49', colorTheme: 'losing' });
  });

  test('uses the latest completed CWL war and returns a neutral payload when none match', () => {
    const completed = JSON.parse(
      buildWarWidgetPayload(
        {
          isInCwl: true,
          league_info: { clans: [{ tag: '#OURS', rank: Number.NaN }] },
          war_league_infos: [
            {
              state: 'warEnded',
              endTime: '2026-01-01T00:00:00Z',
              clan: { tag: '#OURS', stars: 1 },
              opponent: { tag: '#OLD', stars: 2 },
            },
            {
              state: 'warEnded',
              endTime: '2026-01-02T00:00:00Z',
              clan: { tag: '#OURS', stars: 3 },
              opponent: { tag: '#NEW', stars: 2 },
            },
          ],
        },
        'OURS',
        now,
      ),
    );
    expect(completed).toMatchObject({
      primaryText: 'CWL Victory!',
      score: '3 - 2',
      cwlRank: null,
      cwlLeague: 'unknown',
      clan: { badgeUrlMedium: null },
    });

    const empty = JSON.parse(
      buildWarWidgetPayload(
        { isInCwl: true, league_info: {}, war_league_infos: [{ state: 'unknown' }] },
        '#OURS',
        now,
      ),
    );
    expect(empty).toMatchObject({ state: 'cwl', score: '-', secondaryText: 'No active wars' });
  });
});

describe('WarWidgetService', () => {
  test('deduplicates/sorts profile and bookmark clans and selects the active profile clan', () => {
    const profiles = [
      {
        tag: '#P1',
        clanOverview: { tag: '#B', name: 'Beta', badgeUrls: { medium: 'b.png' } },
      },
      {
        tag: '#P2',
        clanOverview: { tag: '#A', name: 'alpha', badgeUrls: { medium: 'a.png' } },
      },
    ];
    expect(clanOptionsFromProfiles(profiles, [{ tag: '#B', name: 'Duplicate' }])).toEqual([
      { tag: '#A', name: 'alpha', badgeUrl: 'a.png' },
      { tag: '#B', name: 'Beta', badgeUrl: 'b.png' },
    ]);
    expect(selectedClanTagFromProfiles(profiles, 'P1')).toBe('#B');
    expect(normalizedClanTag('##abc')).toBe('ABC');
    expect(warInfoKeyForClan('#abc')).toBe('warInfo_ABC');
  });

  test('fails open on feature refresh and registers the exact Android interval', async () => {
    const h = harness();
    h.featureFlags.refresh.mockRejectedValue(new Error('offline'));
    await expect(h.service.areWarWidgetsEnabled()).resolves.toBe(true);
    await h.service.registerPeriodicRefresh();
    expect(h.options.backgroundScheduler?.registerPeriodicTask).toHaveBeenCalledWith(
      WAR_WIDGET_BACKGROUND_TASK,
      15,
    );
  });

  test('writes config, options and per-clan/default payloads before one reload', async () => {
    const h = harness({
      loadWarSummary: jest.fn(async () => ({ war_info: { state: 'notInWar' } })),
    });
    await h.service.prepareClanWidgets(
      [
        { tag: '#B', name: 'Beta' },
        { tag: '#A', name: 'Alpha' },
      ],
      '#B',
    );
    expect(h.native.setWidgetValue).toHaveBeenCalledWith(
      WIDGET_STORAGE_KEYS.legacyWarAuthToken,
      null,
    );
    expect(h.native.setWidgetValue).toHaveBeenCalledWith(
      WIDGET_STORAGE_KEYS.warClans,
      JSON.stringify([
        { tag: '#A', name: 'Alpha' },
        { tag: '#B', name: 'Beta' },
      ]),
    );
    expect(h.native.setWidgetValue).toHaveBeenCalledWith('warInfo_A', expect.any(String));
    expect(h.native.setWidgetValue).toHaveBeenCalledWith('warInfo_B', expect.any(String));
    expect(h.native.setWidgetValue).toHaveBeenCalledWith(
      WIDGET_STORAGE_KEYS.warDefaultInfo,
      expect.any(String),
    );
    expect(h.native.reloadWidgets).toHaveBeenCalledTimes(1);
    expect(await h.service.getCachedClanOptions()).toEqual([
      { tag: '#A', name: 'Alpha' },
      { tag: '#B', name: 'Beta' },
    ]);
  });

  test('migrates allowlisted legacy widget values once without overwriting Expo state', async () => {
    const h = harness();
    h.native.readLegacyWidgetValues.mockResolvedValue({
      warWidgetClans: '[{"tag":"#OLD","name":"Old"}]',
      warWidgetSelectedClan: '#OLD',
      warInfo_OLD: '{"state":"notInWar"}',
      upgradeWidget_A: '{"tag":"#A"}',
    });
    await h.mirror.setItem(WIDGET_STORAGE_KEYS.warSelectedClan, '#EXPO');
    await expect(h.service.migrateLegacyWidgetValues()).resolves.toEqual({
      migratedKeys: ['warWidgetClans', 'warInfo_OLD', 'upgradeWidget_A'],
      sourceValuesRetained: true,
    });
    expect(await h.mirror.getItem(WIDGET_STORAGE_KEYS.warSelectedClan)).toBe('#EXPO');
    await expect(h.service.migrateLegacyWidgetValues()).resolves.toEqual({
      migratedKeys: [],
      sourceValuesRetained: true,
    });
    expect(h.native.readLegacyWidgetValues).toHaveBeenCalledTimes(1);
  });

  test('skips native legacy widget migration on web', async () => {
    const h = harness({ platform: 'web' });

    await expect(h.service.migrateLegacyWidgetValues()).resolves.toEqual({
      migratedKeys: [],
      sourceValuesRetained: true,
    });
    expect(h.native.readLegacyWidgetValues).not.toHaveBeenCalled();
  });

  test('returns exact pin support/request results and reports unsupported platforms', async () => {
    const h = harness();
    await expect(h.service.requestPinnedWarWidget()).resolves.toEqual({
      supported: true,
      requested: true,
    });
    expect(h.native.requestPinWarWidget).toHaveBeenCalledTimes(1);

    const ios = harness({ platform: 'ios' });
    await expect(ios.service.requestPinnedWarWidget()).resolves.toEqual({
      supported: false,
      requested: false,
    });
    expect(ios.native.requestPinWarWidget).not.toHaveBeenCalled();
  });

  test('resolves selected player aliases, account fallback and clan cache exactly', async () => {
    const h = harness({
      getFirstAvailableAccount: jest.fn(async () => '#PLAYER'),
      loadPlayerClanTag: jest.fn(async () => '#CLAN'),
    });
    await expect(h.service.getCurrentPlayerClanTag()).resolves.toBe('#CLAN');
    expect(await h.preferences.getItem('selectedTag')).toBe('#PLAYER');
    expect(await h.preferences.getItem('player_#PLAYER_clan_tag')).toBe('#CLAN');
    await expect(h.service.getCurrentPlayerClanTag()).resolves.toBe('#CLAN');
    expect(h.options.loadPlayerClanTag).toHaveBeenCalledTimes(1);
  });

  test('consumes refresh taps, gates refresh, and handles background task results', async () => {
    const h = harness();
    h.native.consumePendingWidgetAction.mockResolvedValue('warWidget://refreshClicked');
    await expect(h.service.consumePendingWidgetAction()).resolves.toBe(true);
    expect(h.native.reloadWidgets).toHaveBeenCalled();

    h.featureFlags.isEnabled.mockReturnValue(false);
    h.native.reloadWidgets.mockClear();
    await expect(h.service.executeBackgroundTask(WAR_WIDGET_BACKGROUND_TASK)).resolves.toBe(true);
    expect(h.native.reloadWidgets).not.toHaveBeenCalled();
    await expect(h.service.handleWidgetAction('clashking://player')).resolves.toBe(false);
  });

  test('stores an error payload on API failure and keeps widget update non-fatal', async () => {
    const h = harness({
      loadWarSummary: jest.fn(async () => Promise.reject(new Error('offline'))),
    });
    await h.service.refreshWarInfoForClan('#A', true);
    const call = h.native.setWidgetValue.mock.calls.find(([key]) => key === 'warInfo_A');
    expect(JSON.parse(String(call?.[1]))).toEqual(
      expect.objectContaining({ state: 'error', timeState: 'Refresh failed' }),
    );
    expect(h.reportError).toHaveBeenCalledWith(
      expect.objectContaining({ operation: 'widget.fetch_war_summary' }),
    );
  });

  test('handles platform, scheduler, empty action, and malformed action boundaries', async () => {
    const ios = harness({ platform: 'ios', backgroundScheduler: undefined });
    await expect(ios.service.registerPeriodicRefresh()).resolves.toBeUndefined();
    await expect(ios.service.consumePendingWidgetAction()).resolves.toBe(false);

    const android = harness({ backgroundScheduler: undefined });
    await expect(android.service.registerPeriodicRefresh()).rejects.toThrow('not configured');
    await expect(android.service.consumePendingWidgetAction()).resolves.toBe(false);
    await expect(android.service.handleWidgetAction('not a url')).resolves.toBe(false);
    expect(android.reportError).toHaveBeenCalledWith(
      expect.objectContaining({ operation: 'widget.action' }),
    );
    await expect(android.service.executeBackgroundTask('unrelated')).resolves.toBe(true);
  });

  test('seeds cached options, updates from fallback clan, and tolerates malformed cache data', async () => {
    const h = harness({
      getFirstAvailableAccount: jest.fn(async () => '#PLAYER'),
      loadPlayerClanTag: jest.fn(async () => '#CLAN'),
    });
    await h.service.seedClanOptionsFromProfiles([]);
    expect(h.native.reloadWidgets).not.toHaveBeenCalled();

    await h.service.seedClanOptionsFromProfiles([
      {
        tag: '#PLAYER',
        clanOverview: { tag: '#CLAN', name: 'Clan', badgeUrls: { medium: '' } },
      },
    ]);
    expect(h.native.reloadWidgets).toHaveBeenCalledTimes(1);
    expect(await h.service.getCachedClanOptions()).toEqual([{ tag: '#CLAN', name: 'Clan' }]);

    await h.mirror.setItem(WIDGET_STORAGE_KEYS.warClans, '{bad json');
    await expect(h.service.getCachedClanOptions()).resolves.toEqual([]);
    await h.mirror.removeItem(WIDGET_STORAGE_KEYS.warClans);
    h.native.reloadWidgets.mockClear();
    await h.service.updateWarWidget();
    expect(h.native.setWidgetValue).toHaveBeenCalledWith('warInfo_CLAN', expect.any(String));
    expect(h.native.reloadWidgets).toHaveBeenCalledTimes(1);
  });

  test('refreshes every cached clan, coalesces duplicate loads, and reports non-fatally', async () => {
    let release: ((value: { war_info: { state: string } }) => void) | undefined;
    const pending = new Promise<{ war_info: { state: string } }>((resolve) => {
      release = resolve;
    });
    const loadWarSummary = jest.fn(async () => pending);
    const h = harness({
      loadWarSummary,
      reportError: jest.fn(async () => Promise.reject(new Error('reporter offline'))),
    });
    await h.mirror.setItem(
      WIDGET_STORAGE_KEYS.warClans,
      JSON.stringify([
        { tag: '#A', name: 'Alpha' },
        { tag: '#A', name: 'Alpha duplicate' },
      ]),
    );
    const first = h.service.refreshWarInfoForClan('#A');
    const second = h.service.refreshWarInfoForClan('A');
    expect(loadWarSummary).toHaveBeenCalledTimes(1);
    release?.({ war_info: { state: 'notInWar' } });
    await Promise.all([first, second]);

    await h.service.handleWidgetRefresh();
    expect(h.native.reloadWidgets).toHaveBeenCalled();
  });
});
