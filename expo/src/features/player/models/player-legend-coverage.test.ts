import { gameDataState } from '@/core/game-data/game-data-state';
import type { PlayerEquipment } from './player-items';
import {
  LegendHeroGear,
  PlayerLegendAttack,
  PlayerLegendClan,
  PlayerLegendDay,
  PlayerLegendRanking,
  PlayerLegendSeason,
  PlayerLegendStats,
  SpotData,
} from './player-legend';

const seasonJson = {
  season_start: '2026-08-01T00:00:00Z',
  season_end: '2026-08-31T00:00:00Z',
  season_duration: 31,
  season_days_in_legend: 2,
  season_end_trophies: 5100,
  season_trophies_gained_total: 80,
  season_trophies_lost_total: 40,
  season_trophies_net: 40,
  season_trophies_net_revised: -100,
  season_total_attacks: 3,
  season_total_defenses: 2,
  season_average_trophies_gained_per_attack: 26.7,
  season_average_trophies_lost_per_defense: 20,
  season_total_attacks_defenses_possible: 16,
  season_total_gained_lost_possible: 640,
  season_trophies_gained_ratio: 0.5,
  season_trophies_lost_ratio: 0.25,
  season_total_attacks_ratio: 0.375,
  season_total_defenses_ratio: 0.25,
  season_stars_distribution_attacks: { '3': 2 },
  season_stars_distribution_defenses: { '2': 1 },
  season_stars_distribution_attacks_percentages: { '3': 66.7 },
  season_stars_distribution_defenses_percentages: { '2': 50 },
  days: {
    '2026-08-01': {
      attacks: [40, 30],
      defenses: [-20],
      trophies_gained_total: 70,
      trophies_lost_total: 20,
      trophies_total: 5050,
      num_attacks: 2,
      num_defenses: 1,
      start_trophies: 5000,
      end_trophies: 5050,
      new_attacks: [
        {
          change: 40,
          trophies: 5040,
          time: 1,
          hero_gear: [
            { name: 'Giant Arrow', level: 18 },
            { name: 'Fireball', level: 12 },
          ],
        },
        { change: 30, hero_gear: [{ name: 'Giant Arrow', level: 18 }] },
      ],
      new_defenses: [{ change: -20 }],
    },
  },
};

describe('legend model behavior', () => {
  it('parses attacks and days, calculates remaining attacks, usage, and profile-backed gear', () => {
    gameDataState.gearsData.gears = {
      Fireball: { maxLevel: 27, levels: [{ level: 12 }] },
    };
    const profileArrow = { name: 'Giant Arrow', level: 20 } as PlayerEquipment;
    const day = PlayerLegendDay.fromJson(seasonJson.days['2026-08-01']);

    expect(day.remainingAttacks).toBe(6);
    expect(day.newAttacks[0]).toEqual(
      new PlayerLegendAttack(40, 5040, 1, [
        new LegendHeroGear('Giant Arrow', 18),
        new LegendHeroGear('Fireball', 12),
      ]),
    );
    expect(day.usageCount).toEqual({ 'Giant Arrow': 2, Fireball: 1 });
    const gear = day.gearCountsFlatFromProfile([profileArrow]);
    expect(gear['Giant Arrow']).toBe(profileArrow);
    expect(gear.Fireball).toMatchObject({ name: 'Fireball', level: 12, maxLevel: 27 });
  });

  it('parses seasons, caps elapsed days, and resolves season membership boundaries', () => {
    const parsed = PlayerLegendSeason.fromJson(seasonJson);
    const capped = new PlayerLegendSeason(
      parsed.start,
      parsed.end,
      5,
      parsed.daysInLegend,
      parsed.endTrophies,
      parsed.trophiesGainedTotal,
      parsed.trophiesLostTotal,
      parsed.trophiesNet,
      parsed.trophiesNetRevised,
      parsed.totalAttacks,
      parsed.totalDefenses,
      parsed.avgGainedPerAttack,
      parsed.avgLostPerDefense,
      parsed.totalPossible,
      parsed.gainedLostPossible,
      parsed.gainedRatio,
      parsed.lostRatio,
      parsed.attackRatio,
      parsed.defenseRatio,
      parsed.days,
      parsed.attackStarsDistribution,
      parsed.defenseStarsDistribution,
      parsed.attackStarsDistributionPercentages,
      parsed.defenseStarsDistributionPercentages,
      new Date('2026-09-20T00:00:00Z'),
    );
    expect(parsed.trophiesNetRevised).toBe(5100);
    expect(parsed.attackStarsDistribution.get(3)).toBe(2);
    expect(capped.dayOfSeason).toBe(5);

    const stats = PlayerLegendStats.fromJson({ august: seasonJson });
    expect(stats.allSeasons).toHaveLength(1);
    expect(stats.currentSeasonAt(new Date('2026-08-15T00:00:00Z'))).toBe(
      parsed === stats.allSeasons[0] ? parsed : stats.allSeasons[0],
    );
    expect(stats.currentSeasonAt(new Date('2026-10-01T00:00:00Z'))).toBeNull();
    expect(stats.getSpecificSeason(new Date('2026-08-31T00:00:00Z'))).not.toBeNull();
    expect(stats.getSpecificSeason(new Date('2026-07-01T00:00:00Z'))).toBeNull();
  });

  it('parses ranking clans and builds sorted chart ranges and axis helpers', () => {
    const first = PlayerLegendRanking.fromJson({
      tag: '#A',
      name: 'A',
      expLevel: 200,
      trophies: 5500,
      attackWins: 200,
      defenseWins: 10,
      rank: 20,
      season: '2026-08',
      clan: { tag: '#C', name: 'Clan', badgeUrls: { small: 'small.png' } },
    });
    const second = PlayerLegendRanking.fromJson({ season: '2026-07-15', trophies: 5400 });
    expect(first.clan).toEqual(new PlayerLegendClan('#C', 'Clan', { small: 'small.png' }));

    const spots = SpotData.fromLegendRankings([first, second]);
    expect(spots.spots.map((spot) => spot.y)).toEqual([5400, 5500]);
    expect(spots.rangeX).toBeGreaterThan(1);
    expect(spots.rangeY).toBe(20);
    expect(SpotData.fromLegendRankings([])).toEqual(new SpotData([], 0, 0, 0, 0, 1, 1));
    expect([49, 99, 199, 200].map((max) => SpotData.getYAxisInterval(0, max))).toEqual([
      10, 20, 50, 100,
    ]);
    expect(SpotData.roundUpToNext100(501)).toBe(600);
  });
});
