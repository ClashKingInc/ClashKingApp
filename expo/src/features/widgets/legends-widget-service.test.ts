import type { MessageKey } from '../../i18n';
import type { StringStore } from '../../services/storage/auth-storage';
import { Player } from '../player/models';
import {
  PlayerLegendBattle,
  PlayerLegendBattlelog,
  PlayerLegendLeagueData,
  PlayerLegendRank,
} from '../player/models/player-legend';
import {
  buildLegendsWidgetPayload,
  type LegendsWidgetTranslate,
} from './legends-widget-payload';
import {
  LEGENDS_WIDGET_PLAYERS_KEY,
  LegendsWidgetService,
  legendsWidgetKeyForPlayer,
} from './legends-widget-service';

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

const t: LegendsWidgetTranslate = (key: MessageKey, values) =>
  key === 'statsDayIndex' ? `Day ${values?.index ?? ''}` : key;

const player = (tag = '#PLAYER', name = 'Player') =>
  Player.fromJson({
    tag,
    name,
    townHallLevel: 17,
    clan: {
      tag: '#CLAN',
      name: 'Clan',
      clanLevel: 20,
      badgeUrls: { small: 'small.png', medium: 'badge.png', large: 'large.png' },
    },
  });

const legend = (
  day: PlayerLegendBattlelog | null = null,
  rank: PlayerLegendRank | null = null,
  seasonStart: string | null = null,
) =>
  new PlayerLegendLeagueData(
    '#PLAYER',
    'Player',
    17,
    0,
    0,
    day,
    [],
    day?.day ?? '2026-09-21',
    rank,
    null,
    day ? [day] : [],
    [],
    seasonStart,
  );

const battlelog = (
  day: string,
  attacks: readonly PlayerLegendBattle[],
  defenses: readonly PlayerLegendBattle[],
  attackTrophies: number,
  defenseTrophies: number,
) =>
  new PlayerLegendBattlelog(
    '#PLAYER',
    day,
    new Date(`${day}T05:10:00.000Z`),
    new Date(new Date(`${day}T05:10:00.000Z`).getTime() + 86_400_000),
    false,
    attackTrophies,
    defenseTrophies,
    attackTrophies + defenseTrophies,
    attacks,
    defenses,
  );

function nativeBridge() {
  return {
    setWidgetValue: jest.fn<Promise<void>, [string, string | null]>().mockResolvedValue(),
    reloadWidgets: jest.fn<Promise<void>, []>().mockResolvedValue(),
  };
}

describe('Legends widget payload', () => {
  test.each([
    ['2026-09-21T05:09:59.000Z', '2026-09-20'],
    ['2026-09-21T05:10:00.000Z', '2026-09-21'],
  ])('uses the 05:10 UTC cutoff at %s', (now, expectedDay) => {
    const payload = buildLegendsWidgetPayload(
      player(),
      legend(null, null, '2026-09-01T05:10:00.000Z'),
      t,
      new Date(now),
    );

    expect(payload).toMatchObject({
      legendDay: expectedDay,
      dayStartsAt: `${expectedDay}T05:10:00.000Z`,
    });
    expect(payload.dayEndsAt).toBe(
      new Date(new Date(`${expectedDay}T05:10:00.000Z`).getTime() + 86_400_000).toISOString(),
    );
  });

  it('omits unavailable values instead of fabricating zeroes', () => {
    const payload = buildLegendsWidgetPayload(
      player(),
      legend(null, null, '2026-09-01T00:00:00.000Z'),
      t,
      new Date('2026-09-21T12:00:00.000Z'),
    );

    expect(payload.legendDayIndex).toBe(21);
    expect(payload.labels.dayFormatted).toBe('Day 21');
    expect(payload.artwork).toEqual({
      attackIconUrl: expect.stringContaining('Icon_HV_Sword.png'),
      defenseIconUrl: expect.stringContaining('Icon_HV_Shield_Arrow.png'),
      trophyIconUrl: expect.stringContaining('Icon_HV_Trophy.png'),
      starFilledIconUrl: expect.stringContaining('Icon_HV_Attack_Star.png'),
      starEmptyIconUrl: expect.stringContaining('Icon_BB_Empty_Star.png'),
    });
    for (const key of [
      'trophies',
      'globalRank',
      'attackTrophies',
      'defenseTrophies',
      'netTrophies',
      'attacksUsed',
      'defensesTaken',
      'latestAttack',
      'latestDefense',
    ]) {
      expect(payload).not.toHaveProperty(key);
    }
  });

  it('keeps signed totals and selects the latest timed battles', () => {
    const older = new PlayerLegendBattle(
      20,
      false,
      new Date('2026-09-21T06:00:00.000Z'),
      0,
      17,
      '#OLD',
      'Older',
      16,
      2,
      85,
    );
    const latest = new PlayerLegendBattle(
      40,
      false,
      new Date('2026-09-21T08:00:00.000Z'),
      0,
      17,
      '#NEW',
      'Latest',
      17,
      3,
      100,
    );
    const automatic = new PlayerLegendBattle(-15, true);
    const defense = new PlayerLegendBattle(
      -40,
      false,
      new Date('2026-09-21T07:00:00.000Z'),
      0,
      17,
      '#DEF',
      'Defender',
      17,
      3,
      100,
    );
    const payload = buildLegendsWidgetPayload(
      player(),
      legend(
        battlelog('2026-09-21', [latest, older], [automatic, defense], 60, -40),
        new PlayerLegendRank('#PLAYER', 'Player', 5600, 24),
      ),
      t,
      new Date('2026-09-21T12:00:00.000Z'),
    );

    expect(payload).toMatchObject({
      trophies: 5600,
      globalRank: 24,
      attackTrophies: 60,
      defenseTrophies: -40,
      netTrophies: 20,
      attacksUsed: 2,
      defensesTaken: 2,
      latestAttack: { trophies: 40, opponentName: 'Latest', stars: 3 },
      latestDefense: { trophies: -40, opponentName: 'Defender', stars: 3 },
    });
  });

  it('normalizes a positive defense aggregate to the signed widget contract', () => {
    const payload = buildLegendsWidgetPayload(
      player(),
      legend(battlelog('2026-09-21', [], [], 60, 40)),
      t,
      new Date('2026-09-21T12:00:00.000Z'),
    );

    expect(payload.defenseTrophies).toBe(-40);
    expect(payload.netTrophies).toBe(20);
  });
});

describe('LegendsWidgetService', () => {
  it('removes unbookmarked payloads and retains a last good payload on refresh failure', async () => {
    const mirror = new MemoryStore();
    const native = nativeBridge();
    const retained = JSON.stringify({ schemaVersion: 1, tag: '#A', marker: 'last-good' });
    mirror.values.set(
      LEGENDS_WIDGET_PLAYERS_KEY,
      JSON.stringify([
        { tag: '#A', name: 'Alpha', townHallLevel: 17 },
        { tag: '#B', name: 'Beta', townHallLevel: 16 },
      ]),
    );
    mirror.values.set(legendsWidgetKeyForPlayer('#A'), retained);
    mirror.values.set(legendsWidgetKeyForPlayer('#B'), '{}');
    const reportError = jest.fn();
    const service = new LegendsWidgetService({
      platform: 'ios',
      native,
      mirror,
      loadPlayer: async () => player('#A', 'Alpha'),
      loadLegendData: async () => { throw new Error('offline'); },
      t,
      reportError,
    });

    await service.syncBookmarkedPlayers([{ tag: '#A', name: 'Alpha', townHallLevel: 17 }]);

    expect(mirror.values.get(legendsWidgetKeyForPlayer('#A'))).toBe(retained);
    expect(mirror.values.has(legendsWidgetKeyForPlayer('#B'))).toBe(false);
    expect(JSON.parse(mirror.values.get(LEGENDS_WIDGET_PLAYERS_KEY)!)).toEqual([
      { tag: '#A', name: 'Alpha', townHallLevel: 17 },
    ]);
    expect(reportError).toHaveBeenCalledWith(expect.objectContaining({
      operation: 'legends_widget.player',
      tag: '#A',
    }));
    expect(native.reloadWidgets).toHaveBeenCalledTimes(1);
  });

  it('refreshes cached bookmarks without requiring profile auth and preserves cached clan metadata', async () => {
    const mirror = new MemoryStore();
    const native = nativeBridge();
    mirror.values.set(
      LEGENDS_WIDGET_PLAYERS_KEY,
      JSON.stringify([{ tag: '#A', name: 'Cached', townHallLevel: 16 }]),
    );
    mirror.values.set(
      legendsWidgetKeyForPlayer('#A'),
      JSON.stringify({
        schemaVersion: 1,
        tag: '#A',
        clan: { tag: '#CLAN', name: 'Cached clan', badgeUrl: 'cached.png' },
      }),
    );
    const reportError = jest.fn();
    const loadLegendData = jest.fn(async () => legend(
      battlelog('2026-09-21', [], [], 0, 0),
      new PlayerLegendRank('#A', 'Cached', 5100, 0),
    ));
    const service = new LegendsWidgetService({
      platform: 'ios',
      native,
      mirror,
      loadPlayer: async () => { throw new Error('authentication required'); },
      loadLegendData,
      t,
      now: () => new Date('2026-09-21T12:00:00.000Z'),
      reportError,
    });

    await service.refreshCachedBookmarks();

    expect(loadLegendData).toHaveBeenCalledWith('#A', '2026-09-21');
    expect(JSON.parse(mirror.values.get(legendsWidgetKeyForPlayer('#A'))!)).toMatchObject({
      name: 'Cached',
      townHallLevel: 16,
      trophies: 5100,
      clan: { tag: '#CLAN', name: 'Cached clan', badgeUrl: 'cached.png' },
    });
    expect(reportError).toHaveBeenCalledWith(expect.objectContaining({ tag: '#A' }));
  });

  it('does not replace a last-good snapshot with an empty successful response', async () => {
    const mirror = new MemoryStore();
    const native = nativeBridge();
    const retained = JSON.stringify({
      schemaVersion: 1,
      tag: '#A',
      updatedAt: '2026-09-20T12:00:00.000Z',
      trophies: 5400,
    });
    mirror.values.set(
      LEGENDS_WIDGET_PLAYERS_KEY,
      JSON.stringify([{ tag: '#A', name: 'Alpha', townHallLevel: 17 }]),
    );
    mirror.values.set(legendsWidgetKeyForPlayer('#A'), retained);
    const reportError = jest.fn();
    const service = new LegendsWidgetService({
      platform: 'ios',
      native,
      mirror,
      loadPlayer: async () => player('#A', 'Alpha'),
      loadLegendData: async () => legend(),
      t,
      reportError,
    });

    await service.refreshCachedBookmarks();

    expect(mirror.values.get(legendsWidgetKeyForPlayer('#A'))).toBe(retained);
    expect(reportError).toHaveBeenCalledWith(expect.objectContaining({
      operation: 'legends_widget.player',
      tag: '#A',
    }));
  });

  it('caps concurrent player refreshes', async () => {
    const mirror = new MemoryStore();
    const native = nativeBridge();
    const bookmarks = ['A', 'B', 'C', 'D'].map((tag) => ({
      tag: `#${tag}`,
      name: tag,
      townHallLevel: 17,
    }));
    mirror.values.set(LEGENDS_WIDGET_PLAYERS_KEY, JSON.stringify(bookmarks));
    let active = 0;
    let maximum = 0;
    const loadLegendData = async () => {
      active += 1;
      maximum = Math.max(maximum, active);
      await new Promise((resolve) => setTimeout(resolve, 5));
      active -= 1;
      return legend();
    };
    const service = new LegendsWidgetService({
      platform: 'ios',
      native,
      mirror,
      loadPlayer: async (tag) => player(tag, tag),
      loadLegendData,
      t,
      concurrency: 2,
    });

    await service.refreshCachedBookmarks();

    expect(maximum).toBe(2);
  });

  it('lets clear invalidate an in-flight refresh', async () => {
    const mirror = new MemoryStore();
    const native = nativeBridge();
    mirror.values.set(
      LEGENDS_WIDGET_PLAYERS_KEY,
      JSON.stringify([{ tag: '#A', name: 'Alpha', townHallLevel: 17 }]),
    );
    let release!: () => void;
    const pending = new Promise<void>((resolve) => { release = resolve; });
    const service = new LegendsWidgetService({
      platform: 'ios',
      native,
      mirror,
      loadPlayer: async () => player('#A', 'Alpha'),
      loadLegendData: async () => {
        await pending;
        return legend();
      },
      t,
    });

    const refresh = service.refreshCachedBookmarks();
    await Promise.resolve();
    const clear = service.clear();
    release();
    await Promise.all([refresh, clear]);

    expect(JSON.parse(mirror.values.get(LEGENDS_WIDGET_PLAYERS_KEY)!)).toEqual([]);
    expect(mirror.values.has(legendsWidgetKeyForPlayer('#A'))).toBe(false);
    expect(native.reloadWidgets).toHaveBeenCalledTimes(1);
  });

  it('is a no-op on web', async () => {
    const mirror = new MemoryStore();
    const native = nativeBridge();
    const loadPlayer = jest.fn(async () => player());
    const service = new LegendsWidgetService({
      platform: 'web',
      native,
      mirror,
      loadPlayer,
      loadLegendData: async () => legend(),
      t,
    });

    await service.syncBookmarkedPlayers([{ tag: '#A', name: 'A', townHallLevel: 17 }]);
    await service.refreshCachedBookmarks();
    await service.clear();

    expect(loadPlayer).not.toHaveBeenCalled();
    expect(native.setWidgetValue).not.toHaveBeenCalled();
    expect(native.reloadWidgets).not.toHaveBeenCalled();
  });
});
