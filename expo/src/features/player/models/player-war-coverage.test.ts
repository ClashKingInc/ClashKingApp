import {
  buildPlayerWarStatsFromHistory,
  ClanInfo,
  EnemyTownhallStats,
  MiniWarMember,
  PlayerWarStats,
  PlayerWarStatsData,
  PlayerWarStatsDetails,
  PlayerWarTypeStats,
  WarAttackSnapshot,
  WarMemberData,
} from './player-war';

const attack = (overrides: Record<string, unknown> = {}) => ({
  stars: 3,
  destructionPercentage: 100,
  fresh: true,
  player: { tag: '#O', name: 'Opponent', townhallLevel: 16, mapPosition: 2 },
  ...overrides,
});
const history = (overrides: Record<string, unknown> = {}) => ({
  type: 'random',
  state: 'warEnded',
  endTime: '2026-08-02T12:00:00Z',
  attacksPerMember: 2,
  player: { tag: '#P', name: 'Player', townhallLevel: 17, mapPosition: 1 },
  attacks: [attack()],
  defenses: [attack({ stars: 2, destructionPercentage: 80 })],
  ...overrides,
});

describe('player war aggregation contracts', () => {
  it('merges enemy Town Hall buckets without mutating copies', () => {
    const left = new EnemyTownhallStats(2, 70, 2, { '2': 2 });
    const copy = left.copy();
    left.merge(new EnemyTownhallStats(3, 100, 1, { '2': 0, '3': 1 }));
    expect(left.count).toBe(3);
    expect(left.averageDestruction).toBe(80);
    expect(left.starsCount).toEqual({ '2': 2 });
    expect(copy).toEqual(new EnemyTownhallStats(2, 70, 2, { '2': 2 }));

    const empty = new EnemyTownhallStats(0, 0, 0, {});
    empty.merge(new EnemyTownhallStats(0, 0, 0, {}));
    expect(empty.averageDestruction).toBe(0);
    expect(empty.starsCountDef).toEqual({});
  });

  it('computes averages and combines selected types with Town Hall filters', () => {
    const random = new PlayerWarTypeStats(
      1,
      2,
      1,
      0,
      0,
      { '2': 1, '3': 1 },
      { '1': 1 },
      {
        '17vs16': new EnemyTownhallStats(0, 90, 2, { '2': 1, '3': 1 }),
        invalid: new EnemyTownhallStats(0, 50, 1, { '1': 1 }),
      },
      { '16vs17': new EnemyTownhallStats(0, 75, 1, { '1': 1 }) },
    );
    const cwl = new PlayerWarTypeStats(
      1,
      1,
      1,
      1,
      1,
      { '3': 1 },
      { '2': 1 },
      { '17vs17': new EnemyTownhallStats(0, 100, 1, { '3': 1 }) },
      { '17vs17': new EnemyTownhallStats(0, 90, 1, { '2': 1 }) },
    );
    const stats = new PlayerWarStats('Player', '#P', 17, {}, { all: random, random, cwl }, []);

    expect(random.averageStars).toBe(2.5);
    expect(random.averageStarsDef).toBe(1);
    expect(random.averageDestruction).toBeCloseTo(230 / 3);
    expect(random.getStarsCountAgainstTh(null)).toBe(random.starsCount);
    expect(random.getStarsCountAgainstTh(16)).toEqual({ '0': 0, '1': 0, '2': 1, '3': 1 });
    expect(stats.getSpecificStats('missing').totalAttacks).toBe(0);
    expect(stats.getStatsForTypes([])).toBe(random);

    const equalOnly = stats.getStatsForTypes(['random', 'cwl'], {
      attackerThFilter: [17],
      defenderThFilter: [17],
      equalThSelected: true,
    });
    expect(equalOnly).toMatchObject({ totalAttacks: 1, totalDefenses: 1, missedAttacks: 1 });
    expect(equalOnly.averageDestruction).toBe(100);
    expect(equalOnly.averageDestructionDef).toBe(90);
  });

  it('aggregates history into per-type and all stats with missing-attack accounting', () => {
    const values = [
      history(),
      history({
        type: 'cwl',
        endTime: '2026-08-03T12:00:00Z',
        attacksPerMember: 1,
        attacks: [attack({ stars: 1, destructionPercentage: 40, fresh: false })],
        defenses: [],
      }),
      history({ type: 'friendly', endTime: '2026-07-01T12:00:00Z' }),
    ];
    const all = buildPlayerWarStatsFromHistory(values, '#P');
    expect(all.timeRange).toEqual({
      start: Date.parse('2026-07-01T12:00:00Z') / 1000,
      end: Date.parse('2026-08-03T12:00:00Z') / 1000,
    });
    expect(all.statsByType).toHaveProperty('friendly');
    expect(all.getSpecificStats('random')).toMatchObject({
      warsCounts: 1,
      totalAttacks: 1,
      totalDefenses: 1,
      missedAttacks: 1,
      missedDefenses: 1,
    });
    expect(all.wars).toHaveLength(3);

    const filtered = buildPlayerWarStatsFromHistory(values, '#P', {
      startDate: new Date('2026-08-01T00:00:00Z'),
      endDate: new Date('2026-08-04T00:00:00Z'),
      warTypes: ['random', 'cwl'],
      ownTownHalls: [17],
      enemyTownHalls: [16],
      sameTownHall: false,
      freshAttacksOnly: true,
      allowedStars: [2, 3],
      minDestruction: 70,
      maxDestruction: 100,
      minMapPosition: 1,
      maxMapPosition: 3,
    });
    expect(filtered.statsByType.all).toMatchObject({ totalAttacks: 1, totalDefenses: 0 });

    const none = buildPlayerWarStatsFromHistory(values, '#P', {
      warType: 'cwl',
      minStars: 3,
      maxStars: 3,
      minDestruction: 90,
      maxMapPosition: 1,
    });
    expect(none.statsByType.all!.totalAttacks).toBe(0);
    expect(none.statsByType.all!.totalDefenses).toBe(0);
  });

  it('parses history snapshots and detail helper models with safe empty members', () => {
    const parsed = PlayerWarStats.fromJson(
      {
        name: 'Player',
        tag: '#P',
        townhallLevel: 17,
        stats: { random: { totalAttacks: 1, starsCount: { '3': 1 } } },
      },
      '#P',
      [
        {
          war_data: { state: 'warEnded' },
          members: [
            {
              tag: '#P',
              name: 'Player',
              attacks: [{ attackerTag: '#P', defenderTag: '#O', duration: 120 }],
            },
          ],
        },
      ],
    );
    expect(parsed.timeRange).toEqual({ start: 0, end: 0 });
    expect(parsed.wars[0]?.memberData.attacks[0]?.duration).toBe(120);

    const missing = PlayerWarStatsData.fromJson(
      { war_data: { state: 'unknown' }, members: [] },
      '#P',
    );
    expect(missing.memberData).toEqual(WarMemberData.empty());
    expect(MiniWarMember.fromJson({ tag: '#M', opponentAttacks: 2 })).toMatchObject({
      tag: '#M',
      opponentAttacks: 2,
    });
    expect(MiniWarMember.fromJson({}).opponentAttacks).toBeNull();

    const snapshot = WarAttackSnapshot.fromJson({
      attackerTag: '#A',
      defenderTag: '#D',
      stars: 2,
      destructionPercentage: 75,
      attacker: { tag: '#A' },
      defender: { tag: '#D' },
    });
    expect(snapshot.toJson()).toMatchObject({ attackerTag: '#A', duration: null });

    const clan = ClanInfo.fromJson({ tag: '#C', badgeUrls: { small: 'badge.png' }, attacks: 10 });
    expect(clan).toMatchObject({ tag: '#C', attacks: 10, badgeUrls: { small: 'badge.png' } });
    const details = PlayerWarStatsDetails.fromJson({
      state: 'warEnded',
      teamSize: 15,
      clan: { tag: '#C' },
      opponent: { tag: '#O' },
      type: 'random',
    });
    expect(details).toMatchObject({ state: 'warEnded', teamSize: 15, type: 'random' });
  });
});
