import { WarStatsFilter } from '../models';
import {
  builtInWarFilters,
  selectedWarTypes,
  toggleQuickWarType,
  warFiltersEqual,
} from './player-war-filter-state';

describe('player war filter presentation state', () => {
  it('starts every Flutter quick war type selected and retains the other two', () => {
    const initial = WarStatsFilter.defaultFilter();
    expect(selectedWarTypes(initial)).toEqual(['random', 'cwl', 'friendly']);
    expect(toggleQuickWarType(initial, 'cwl').warTypes).toEqual(['random', 'friendly']);
  });
  it('builds the six Flutter preset filters', () => {
    const presets = builtInWarFilters(new Date('2026-08-30T00:00:00Z'));
    expect(presets.map(([name]) => name)).toEqual([
      'Last 30 days',
      '3 stars',
      'CWL',
      'Random',
      'Friendly',
      'Fresh',
    ]);
    expect(presets[0][1].startDate).toEqual(new Date('2026-07-31T00:00:00Z'));
    expect(presets[0][1].endDate).toEqual(new Date('2026-08-30T00:00:00Z'));
  });
  it('compares complete filter semantics independent of object identity', () => {
    expect(
      warFiltersEqual(
        new WarStatsFilter({ warTypes: ['cwl'], allowedStars: [3], limit: 50 }),
        new WarStatsFilter({ allowedStars: [3], warTypes: ['cwl'], limit: 50 }),
      ),
    ).toBe(true);
    expect(
      warFiltersEqual(
        new WarStatsFilter({ warTypes: ['cwl'], limit: 50 }),
        new WarStatsFilter({ warTypes: ['cwl'], limit: 100 }),
      ),
    ).toBe(false);
  });
});
