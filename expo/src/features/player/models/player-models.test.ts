import { applyGameDataBundle } from '@/core/game-data/game-data-normalization';
import { resetGameDataStateForTesting } from '@/core/game-data/game-data-state';
import {
  calculateRemainingUpgradeSummary,
  filterGameData,
  generateCompleteItemList,
  maxLevelForTH,
} from '../data/player-item-utils';
import {
  PlayerActivityFeed,
  PlayerActivityKind,
  PlayerCwlHistory,
  PlayerJoinLeavePage,
  PlayerTimers,
} from './player-history';
import {
  PlayerBattlelogArmyCatalog,
  PlayerBattlelogData,
  PlayerBattlelogEntry,
  parseArmyCounts,
} from './player-battlelog';
import { PlayerBuilderBaseTroop, PlayerTroop } from './player-items';
import { PlayerRankings } from './player-ranked';
import { Player } from './player';
import { WarStatsFilter } from './war-stats-filter';
import { buildPlayerWarStatsFromHistory, WarInfoSnapshot } from './player-war';

beforeEach(resetGameDataStateForTesting);

test('parses supported activity changes, sorts newest first, and excludes names', () => {
  const feed = PlayerActivityFeed.fromJson({
    items: [
      {
        time: '2026-08-16T12:00:00Z',
        type: 'troop_level',
        item: { id: 1, name: 'Wizard' },
        townhall_level: 17,
        previous: 11,
        current: 12,
      },
      {
        time: '2026-08-16T13:00:00Z',
        type: 'super_troop_boost',
        item: { name: 'Wizard' },
        previous: 0,
        current: 12,
      },
      { time: '2026-08-16T14:00:00Z', type: 'name', previous: 'a', current: 'b' },
    ],
  });
  expect(feed.items.map((item) => item.kind)).toEqual([
    PlayerActivityKind.superTroopBoost,
    PlayerActivityKind.troopUpgrade,
  ]);
  expect(feed.items[1]?.townHallLevel).toBe(17);
});
test('parses official battle resources/share codes and lets history win a merge', () => {
  const official = PlayerBattlelogEntry.fromOfficial({
      battleType: 'homeVillage',
      attack: true,
      opponentPlayerTag: '#OTHER',
      battleTimestamp: '20260816T120000.000Z',
      lootedResources: [{ name: 'Dark Elixir', amount: 300 }],
      armyShareCode: 'u8x5-2x6s1x1',
    }),
    history = PlayerBattlelogEntry.fromHistory({
      battle_id: 'id',
      battle_type: 'farming',
      attack: true,
      opponent_tag: '#OTHER',
      timestamp: '2026-08-16T12:00:00Z',
      army_counts: { u_5: 8 },
    }),
    merged = PlayerBattlelogData.merge({
      official: [official],
      history: [history],
      officialAvailable: true,
      historyAvailable: true,
    });
  expect(official.darkElixir).toBe(300);
  expect(parseArmyCounts('u8x5-2x6s1x1')).toEqual({ u_5: 8, u_6: 2, s_1: 1 });
  expect(merged.items).toHaveLength(1);
  expect(merged.items[0]?.source).toBe('history');
});
test('resolves army catalog IDs through current game data', () => {
  applyGameDataBundle({
    troops: [{ _id: 4000005, name: 'Wizard' }],
    spells: [{ _id: 26000001, name: 'Lightning Spell' }],
  });
  expect(PlayerBattlelogArmyCatalog.resolve('u_5').name).toBe('Wizard');
  expect(PlayerBattlelogArmyCatalog.resolve('s_1').imageUrl).toContain(
    '/spells/lightning_spell.webp',
  );
});
test('ports item completion, seasonal filtering, TH maxima, and remaining costs', () => {
  const meta = {
      name: 'Barbarian',
      maxLevel: 10,
      levels: [
        { level: 5, required_townhall: 5, upgrade_time: 100, upgrade_cost: { gold: 200 } },
        { level: 6, required_townhall: 6 },
      ],
    },
    items = generateCompleteItemList({
      jsonList: [{ name: 'Barbarian', level: 5, maxLevel: 10 }],
      gameData: { Barbarian: meta },
      factory: PlayerTroop.fromRaw,
    });
  expect(items[0]).toMatchObject({ level: 5, maxLevel: 10, isUnlocked: true });
  expect(maxLevelForTH(meta, 5, { maxTownHallLevel: 18 })).toBe(5);
  expect(
    filterGameData({ Barbarian: meta, Seasonal: { is_seasonal: true } }, () => true),
  ).toHaveProperty('Barbarian');
  const summary = calculateRemainingUpgradeSummary(items[0]!, 7);
  expect(summary).toMatchObject({
    levelsRemaining: 2,
    seconds: 100,
    resources: [{ key: 'gold', amount: 200 }],
  });
});
test('normalizes impossible builder base levels to the first static level', () => {
  expect(
    PlayerBuilderBaseTroop.fromRaw({
      name: 'Raged Barbarian',
      level: 1,
      maxLevel: 20,
      isUnlocked: true,
      meta: { levels: [{ level: 15 }, { level: 16 }] },
    }).level,
  ).toBe(15);
  expect(
    PlayerBuilderBaseTroop.fromRaw({
      name: 'Raged Barbarian',
      level: 0,
      maxLevel: 20,
      isUnlocked: false,
      meta: { levels: [{ level: 15 }] },
    }).level,
  ).toBe(0);
});
test('parses CWL, timer, join-leave, and ranking wire shapes', () => {
  const cwl = PlayerCwlHistory.fromJson({
      items: [
        {
          season: '2026-08',
          townHallLevel: 18,
          clan: { warLeague: { name: 'Master League I' } },
          attacks: [{ round: 1, stars: 3 }],
        },
      ],
    }),
    timers = PlayerTimers.fromJson({
      items: [
        { type: 'war', expiresAt: '2026-08-30T20:00:00Z', clans: ['#C'], warTag: '#W' },
        { type: 'cwl', expiresAt: '2026-09-01T20:00:00Z' },
        { type: 'capital', expiresAt: '2026-09-02T20:00:00Z' },
      ],
    }),
    join = PlayerJoinLeavePage.fromJson({
      available: 72,
      items: [
        {
          time: '2026-08-03T12:00:00Z',
          type: 'join',
          tag: '#P',
          townHallLevel: 17,
          clan: { tag: '#CLAN', name: 'Clan' },
        },
      ],
    }),
    rankings = PlayerRankings.fromJson({
      tag: '#P',
      homeVillage: { points: 5600, globalRank: 42, locationId: '32000087' },
      builderBase: { points: 5100 },
    });
  expect(cwl.items[0]?.stars).toBe(3);
  expect(timers.items.map((item) => item.type)).toEqual(['war', 'cwl', 'capital']);
  expect(join.items[0]?.clan?.badge).toBe('https://badges.clashk.ing/CLAN');
  expect(rankings.homeVillage.globalRank).toBe(42);
});
test('player parser accepts leagueTier, builds complete lists, and enriches tracked seasons', () => {
  applyGameDataBundle({
    heroes: [{ name: 'Barbarian King', village: 'home', levels: [{ level: 100 }] }],
    troops: [{ name: 'Barbarian', village: 'home', levels: [{ level: 12 }] }],
    spells: [],
    equipment: [],
    pets: [],
  });
  const player = Player.fromJson({
    tag: '#P',
    name: 'Player',
    townHallLevel: 17,
    leagueTier: { name: 'Legend League' },
    heroes: [{ name: 'Barbarian King', village: 'home', level: 90, maxLevel: 100 }],
    troops: [{ name: 'Barbarian', village: 'home', level: 11, maxLevel: 12 }],
  });
  player.enrichWithFullStats({
    gold: { '2026-08': 123 },
    donations: { '2026-08': { donated: 10 } },
    rankings: { tag: '#P', homeVillage: { locationId: '32000087' }, builderBase: {} },
  });
  expect(player.league).toBe('Legend League');
  expect(player.heroes[0]).toMatchObject({ name: 'Barbarian King', level: 90 });
  expect(player.goldBySeason['2026-08']).toBe(123);
  expect(player.rankings?.homeVillage.locationId).toBe('32000087');
});
test('full stats orient the current war to the player and parser fallback matches Flutter time', () => {
  const before = Date.now();
  const fallback = Player.empty();
  expect(fallback.lastOnline.getTime()).toBeGreaterThanOrEqual(before);

  const player = Player.fromJson({ tag: '#P', name: 'Player' });
  player.enrichWithFullStats({
    war_data: {
      currentWarInfo: {
        state: 'inWar',
        clan: { tag: '#A', members: [{ tag: '#A1' }] },
        opponent: { tag: '#B', members: [{ tag: '#P' }] },
      },
    },
  });
  expect(player.warData?.clan?.tag).toBe('#B');
  expect(player.warData?.opponent?.tag).toBe('#A');
});
test('legend extrema handle empty histories and preserve the latest matching best season', () => {
  const player = Player.empty();
  expect(player.getBestTrophiesSeason()).toBeNull();
  expect(player.getBestGlobalRankSeason()).toBeNull();
  expect(player.getBestAttackWinsSeason()).toBeNull();

  player.enrichWithFullStats({
    legend_eos_ranking: [
      { season: '2026-06', trophies: 5500, rank: 20, attackWins: 100 },
      { season: '2026-07', trophies: 5600, rank: 10, attackWins: 110 },
      { season: '2026-08', trophies: 5600, rank: 10, attackWins: 110 },
    ],
  });
  expect(player.getBestTrophiesSeason()?.season).toBe('2026-08');
  expect(player.getBestGlobalRankSeason()?.season).toBe('2026-08');
  expect(player.getBestAttackWinsSeason()?.season).toBe('2026-08');
});
test('war filter preserves exact request keys and precedence', () => {
  const filter = new WarStatsFilter({
    season: '2026-08',
    ownTownHalls: [16, 17],
    warTypes: ['random', 'cwl'],
    allowedStars: [2, 3],
    sameTownHall: true,
    limit: 50,
  });
  expect(filter.toJson()).toEqual({
    same_th: true,
    limit: 50,
    type: ['random', 'cwl'],
    season: '2026-08',
    own_th: [16, 17],
    stars: [2, 3],
  });
  expect(WarStatsFilter.fromJson(filter.toJson()).hasActiveFilters()).toBe(true);
});
test('war filter array parsing does not use map indexes as numeric fallbacks', () => {
  const filter = WarStatsFilter.fromJson({
    own_th: [16, 'invalid', 18],
    enemy_th: ['invalid', 17],
    stars: ['invalid', 3],
  });

  expect(filter.ownTownHalls).toEqual([16, 0, 18]);
  expect(filter.enemyTownHalls).toEqual([0, 17]);
  expect(filter.allowedStars).toEqual([0, 3]);
});
test('war snapshots retain dates, members, attacks, and to-do lookup behavior', () => {
  const war = WarInfoSnapshot.fromJson({
    state: 'inWar',
    warType: 'random',
    startTime: '20260816T120000.000Z',
    attacksPerMember: 2,
    clan: {
      tag: '#CLAN',
      members: [
        {
          tag: '#P',
          name: 'Player',
          townhallLevel: 17,
          attacks: [{ attackerTag: '#P', defenderTag: '#O', stars: 3 }],
        },
      ],
    },
  });
  expect(war.startTime?.toISOString()).toBe('2026-08-16T12:00:00.000Z');
  expect(war.isPlayerInWar('#P', '#CLAN')).toBe(true);
  expect(war.getAttacksDoneByPlayer('#P', '#CLAN')).toBe(1);
  expect(war.getTownhallLevelByTag('#P')).toBe(17);
});

test('completed player war history infers the ended state when the adapter payload omits it', () => {
  const stats = buildPlayerWarStatsFromHistory(
    [
      {
        type: 'random',
        startTime: '20260801T120000.000Z',
        endTime: '20260802T120000.000Z',
        player: { tag: '#P', name: 'Player', townhallLevel: 17, mapPosition: 1 },
        attacks: [
          {
            stars: 3,
            destructionPercentage: 100,
            order: 1,
            player: { tag: '#O', name: 'Opponent', townhallLevel: 16, mapPosition: 2 },
          },
        ],
        defenses: [],
      },
    ],
    '#P',
  );
  expect(stats.wars[0]?.warDetails.state).toBe('warEnded');
  expect(stats.wars[0]?.memberData.attacks[0]?.attacker?.name).toBe('Player');
  expect(stats.wars[0]?.memberData.attacks[0]?.defender?.name).toBe('Opponent');
});
