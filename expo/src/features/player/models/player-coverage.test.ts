import { ImageAssets } from '@/core/assets/image-assets';
import {
  isInClanGamesWindow,
  isInCwlWindow,
  Player,
  requiredClanGamesPoints,
  requiredSeasonPassPoints,
  TodoProgressMetric,
} from './player';
import type { PlayerLegendStats } from './player-legend';

describe('Player computed progress and parsing behavior', () => {
  afterEach(() => {
    jest.useRealTimers();
  });

  it('computes ratios, current season values, and war preference assets', () => {
    jest.useFakeTimers().setSystemTime(new Date('2026-08-15T12:00:00Z'));
    const player = Player.empty();
    player.donations = 50;
    player.donationsReceived = 20;
    player.warPreference = 'in';
    player.seasonPass = [{ season: '2026-08', points: 2000 }] as never;
    player.clanGamesPoint = [{ season: '2026-08', points: 1000 }] as never;

    expect(player.donationRatio).toBe('2.50');
    expect(player.currentSeasonKey).toBe('2026-08');
    expect(player.currentSeasonPoints).toBe(2000);
    expect(player.currentClanGamesPoints).toBe(1000);
    expect(player.seasonPassRatio).toBe(1);
    expect(player.seasonPassPointLeft).toBe(0);
    expect(player.warPreferenceImage).toBe(ImageAssets.warPreferenceIn);

    player.donationsReceived = 0;
    player.warPreference = 'out';
    expect(player.donationRatio).toBe('0.0');
    expect(player.warPreferenceImage).toBe(ImageAssets.warPreferenceOut);
    expect(player.clanGamesRatio).toBeGreaterThanOrEqual(0);
    expect(player.clanGamesPointLeft).toBeGreaterThanOrEqual(0);
  });

  it('builds legend, live-war, CWL fallback, clan-games, and season-pass todo metrics', () => {
    const player = Player.empty();
    player.tag = '#P';
    player.clanTag = '#C';
    player.league = 'Legend League';
    player.seasonPass = [{ season: '2026-08', points: 1000 }] as never;
    player.clanGamesPoint = [{ season: '2026-08', points: 2000 }] as never;
    player.legendsBySeason = {
      currentSeasonAt: () => ({ currentDay: { totalAttacks: 5 } }),
    } as unknown as PlayerLegendStats;
    const war = {
      state: 'inWar',
      attacksPerMember: 2,
      isPlayerInWar: () => true,
      getAttacksDoneByPlayer: () => 1,
    };
    player.clan = { warCwl: { isInCwl: false, warInfo: war } };

    const metrics = player.getTodoProgressMetrics(
      { attacksDone: 0, attacksAvailable: 0 },
      new Date('2026-08-24T12:00:00Z'),
    );
    expect(metrics.map((metric) => metric.label)).toEqual([
      'legend_attacks',
      'war_attacks',
      'clan_games',
      'season_pass',
    ]);
    expect(metrics.find((metric) => metric.label === 'clan_games')?.progressTotal).toBe(2);
    expect(player.getTodoProgressRatio({ attacksDone: 0, attacksAvailable: 0 })).toBeGreaterThan(0);

    player.clan = { warCwl: { isInCwl: true, warInfo: { ...war, state: 'preparation' } } };
    const fallback = player.getTodoProgressMetrics(
      { attacksDone: 1, attacksAvailable: 3 },
      new Date('2026-08-05T12:00:00Z'),
    );
    expect(fallback.find((metric) => metric.label === 'cwl_attacks')).toMatchObject({
      done: 1,
      total: 3,
    });
  });

  it('clamps todo progress and treats empty or zero totals as complete', () => {
    const player = Player.empty();
    jest.spyOn(player, 'getTodoProgressMetrics').mockReturnValue([]);
    expect(player.getTodoProgressRatio({ attacksDone: 0, attacksAvailable: 0 })).toBe(1);

    jest
      .spyOn(player, 'getTodoProgressMetrics')
      .mockReturnValue([
        new TodoProgressMetric('negative', -5, 10),
        new TodoProgressMetric('overflow', 20, 10),
      ]);
    expect(player.getTodoProgressRatio({ attacksDone: 0, attacksAvailable: 0 })).toBe(0.5);
    expect(new TodoProgressMetric('zero', 0, 0).progressRatio).toBe(1);
    expect(new TodoProgressMetric('low', -1, 2).progressRatio).toBe(0);
    expect(new TodoProgressMetric('high', 3, 2).progressRatio).toBe(1);
  });

  it('recognizes exact UTC event windows and point ramps', () => {
    expect(isInClanGamesWindow(new Date('2026-08-22T07:59:59Z'))).toBe(false);
    expect(isInClanGamesWindow(new Date('2026-08-22T08:00:00Z'))).toBe(true);
    expect(isInClanGamesWindow(new Date('2026-08-27T23:59:59Z'))).toBe(true);
    expect(isInClanGamesWindow(new Date('2026-08-28T08:00:00Z'))).toBe(true);
    expect(isInClanGamesWindow(new Date('2026-08-28T09:00:00Z'))).toBe(false);
    expect(isInCwlWindow(new Date('2026-08-01T00:00:00Z'))).toBe(true);
    expect(isInCwlWindow(new Date('2026-08-12T23:59:59Z'))).toBe(true);
    expect(isInCwlWindow(new Date('2026-08-13T00:00:00Z'))).toBe(false);
    expect(requiredSeasonPassPoints(new Date(2026, 7, 31))).toBe(2600);
    expect(requiredClanGamesPoints(new Date(2026, 7, 22, 8))).toBe(0);
    expect(requiredClanGamesPoints(new Date(2026, 7, 24, 8))).toBe(Math.trunc((2 * 4000) / 6));
  });

  it('parses string counters and enriches every tracked full-stats collection', () => {
    const player = Player.fromJson({
      name: 'Player',
      tag: '#P',
      trophies: '5,500',
      bestTrophies: '5,600',
      warStars: '1,234',
      builderBaseTrophies: '4,000',
      bestBuilderBaseTrophies: '4,100',
      donations: '2,000',
      donationsReceived: '1,000',
      clanCapitalContributions: '5,000',
      builderBaseLeague: { name: 'Diamond League' },
    });
    expect(player).toMatchObject({
      trophies: 5500,
      bestTrophies: 5600,
      warStars: 1234,
      builderBaseLeague: 'Diamond League',
      donations: 2000,
    });

    player.enrichWithFullStats({
      clan_games: { '2026-08': { points: 1000 } },
      season_pass: { '2026-08': 2000 },
      last_online: 100,
      legends_by_season: {},
      rankings: { tag: '#P', homeVillage: {}, builderBase: {} },
      gold: { '2026-08': 1 },
      dark_elixir: { '2026-08': 2 },
      activity: { '2026-08': 3 },
      attack_wins: { '2026-08': 4 },
      season_trophies: { '2026-08': 5 },
      donations: { '2026-08': { donated: 6 } },
    });
    expect(player.lastOnline.toISOString()).toBe('1970-01-01T00:01:40.000Z');
    expect(player.legendsBySeason).not.toBeNull();
    expect(player.rankings).not.toBeNull();
    expect(player.darkElixirBySeason['2026-08']).toBe(2);
    expect(player.activityBySeason['2026-08']).toBe(3);
    expect(player.attackWinsBySeason['2026-08']).toBe(4);
    expect(player.seasonTrophiesBySeason['2026-08']).toBe(5);
    expect(player.donationsBySeason['2026-08']?.donated).toBe(6);
    expect(player.warData).toBeNull();
  });
});
