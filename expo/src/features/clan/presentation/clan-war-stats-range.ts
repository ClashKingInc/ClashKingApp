import { ClanWarStatsFilter } from '../models/clan-war-stats-filter';
import type { WarStatsRangeMode } from './clan-war-stats-range-modal';

export function clanWarStatsFilterForRange(
  mode: WarStatsRangeMode,
  wars: number,
  days: number,
  now = new Date(),
): ClanWarStatsFilter {
  return new ClanWarStatsFilter({
    startDate: mode === 'days' ? new Date(now.getTime() - days * 86_400_000) : null,
    endDate: mode === 'days' ? now : null,
    limit: mode === 'wars' ? wars : 500,
  });
}
