import { WarStatsFilter } from '../models';
import { buildPlayerWarExportBody, playerWarExportFileName } from './player-war-export';

describe('player war export parity', () => {
  it('sends only player tags for the default filter', () => {
    expect(buildPlayerWarExportBody('#P1', WarStatsFilter.defaultFilter())).toEqual({
      player_tags: ['#P1'],
    });
  });

  it('maps only the fields supported by the Flutter export endpoint', () => {
    const filter = new WarStatsFilter({
      season: '2026-08',
      startDate: new Date('2026-08-01T00:00:00Z'),
      endDate: new Date('2026-08-31T00:00:00Z'),
      warTypes: ['cwl'],
      ownTownHalls: [16, 17],
      enemyTownHalls: [17],
      allowedStars: [2, 3],
      minDestruction: 50,
      maxDestruction: 100,
      minMapPosition: 1,
      maxMapPosition: 15,
      freshAttacksOnly: true,
      sameTownHall: true,
      limit: 25,
    });
    expect(buildPlayerWarExportBody('#P1', filter)).toEqual({
      player_tags: ['#P1'],
      season: '2026-08',
      timestamp_start: 1785542400,
      timestamp_end: 1788134400,
      type: ['cwl'],
      own_th: [16, 17],
      enemy_th: [17],
      stars: [2, 3],
      min_destruction: 50,
      max_destruction: 100,
      map_position_min: 1,
      map_position_max: 15,
      fresh_only: true,
    });
  });

  it('matches Flutter local timestamp and player-name sanitization', () => {
    expect(playerWarExportFileName('Matt! King', new Date(2026, 7, 29, 9, 5, 4))).toBe(
      'war_stats_Matt King_2026-08-29_09-05-04.xlsx',
    );
  });
});
