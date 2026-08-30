import { clanWarStatsFilterForRange } from './clan-war-stats-range';

describe('clanWarStatsFilterForRange', () => {
  const now = new Date('2026-08-30T12:00:00.000Z');

  it('maps recent-war mode to Flutter’s fixed API limit without dates', () => {
    expect(clanWarStatsFilterForRange('wars', 75, 90, now).toJson()).toEqual({
      limit: 75,
      same_th: false,
    });
  });

  it('maps recent-day mode to dated history with Flutter’s 500-war ceiling', () => {
    expect(clanWarStatsFilterForRange('days', 50, 30, now).toJson()).toEqual({
      limit: 500,
      same_th: false,
      timestamp_start: Math.floor(new Date('2026-07-31T12:00:00.000Z').getTime() / 1000),
      timestamp_end: Math.floor(now.getTime() / 1000),
    });
  });
});
