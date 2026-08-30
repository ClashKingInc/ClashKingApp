import { ClanWarStatsFilter } from './clan-war-stats-filter';

describe('ClanWarStatsFilter complete query behavior', () => {
  it('serializes scalar filters, bounds, and exact timestamps', () => {
    const filter = new ClanWarStatsFilter({
      startDate: new Date('2026-08-01T00:00:00Z'),
      endDate: new Date('2026-08-31T23:59:59Z'),
      ownTownHall: 17,
      enemyTownHall: 16,
      warType: 'random',
      freshAttacksOnly: false,
      minStars: 1,
      maxStars: 3,
      minDestruction: 50,
      maxDestruction: 100,
      minMapPosition: 1,
      maxMapPosition: 15,
      limit: 25,
    });
    expect(filter.toJson()).toEqual({
      limit: 25,
      same_th: false,
      type: 'random',
      timestamp_start: 1785542400,
      timestamp_end: 1788220799,
      own_th: 17,
      enemy_th: 16,
      fresh_only: false,
      min_stars: 1,
      max_stars: 3,
      min_destruction: 50,
      max_destruction: 100,
      map_position_min: 1,
      map_position_max: 15,
    });
    expect(filter.hasActiveFilters()).toBe(true);
  });

  it('gives array filters precedence and omits the all war type sentinel', () => {
    const filter = new ClanWarStatsFilter({
      ownTownHall: 10,
      enemyTownHall: 10,
      ownTownHalls: [16, 17],
      enemyTownHalls: [15, 16],
      warTypes: ['all'],
      allowedStars: [2, 3],
      minStars: 1,
      maxStars: 3,
      sameTownHall: true,
    });
    expect(filter.toJson()).toEqual({
      limit: 50,
      same_th: true,
      own_th: [16, 17],
      enemy_th: [15, 16],
      stars: [2, 3],
    });
  });

  it('copyWith preserves omitted values and permits explicit nullable clears', () => {
    const original = new ClanWarStatsFilter({
      startDate: new Date('2026-01-01T00:00:00Z'),
      endDate: new Date('2026-02-01T00:00:00Z'),
      ownTownHall: 17,
      enemyTownHall: 16,
      ownTownHalls: [17],
      enemyTownHalls: [16],
      warTypes: ['cwl'],
      freshAttacksOnly: true,
      minStars: 2,
      maxStars: 3,
      allowedStars: [3],
      minDestruction: 90,
      maxDestruction: 100,
      minMapPosition: 1,
      maxMapPosition: 10,
    });
    const cleared = original.copyWith({
      startDate: null,
      endDate: null,
      ownTownHall: null,
      enemyTownHall: null,
      ownTownHalls: null,
      enemyTownHalls: null,
      warTypes: null,
      freshAttacksOnly: null,
      minStars: null,
      maxStars: null,
      allowedStars: null,
      minDestruction: null,
      maxDestruction: null,
      minMapPosition: null,
      maxMapPosition: null,
    });
    expect(cleared.toJson()).toEqual({ limit: 50, same_th: false });
    expect(cleared.hasActiveFilters()).toBe(false);
    expect(original.copyWith({ limit: 5 }).ownTownHall).toBe(17);
  });

  it('creates an exact 180-day default range', () => {
    const now = new Date('2026-08-30T12:00:00Z');
    const filter = ClanWarStatsFilter.defaultFilter(now);
    expect(filter.endDate).toBe(now);
    expect(filter.startDate?.getTime()).toBe(now.getTime() - 180 * 86_400_000);
    expect(filter.hasActiveFilters()).toBe(false);
  });

  it.each([
    [new ClanWarStatsFilter(), 'No filters applied'],
    [
      new ClanWarStatsFilter({
        ownTownHalls: [16, 17],
        enemyTownHalls: [15],
        sameTownHall: true,
        warTypes: ['random', 'cwl'],
        freshAttacksOnly: true,
        allowedStars: [2, 3],
        minDestruction: 70,
        maxDestruction: 95,
      }),
      'TH16, 17 attacks, vs TH15, Same TH only, RANDOM, CWL wars, Fresh attacks only, 2, 3 ⭐ only, 70-95% destruction',
    ],
    [
      new ClanWarStatsFilter({
        ownTownHall: 17,
        enemyTownHall: 16,
        warType: 'friendly',
        minStars: 2,
        minDestruction: 80,
      }),
      'TH17 attacks, vs TH16, FRIENDLY wars, 2+ stars, 80%+ destruction',
    ],
    [new ClanWarStatsFilter({ maxStars: 2, maxDestruction: 99.6 }), '≤2 stars, ≤100% destruction'],
  ])('summarizes user-visible filter combinations', (filter, expected) => {
    expect(filter.getFilterSummary()).toBe(expected);
  });
});
