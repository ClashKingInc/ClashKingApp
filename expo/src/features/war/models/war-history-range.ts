export type WarHistoryRange =
  'lifetime' | 'wars:25' | 'wars:50' | 'wars:100' | 'days:30' | 'days:60' | 'days:90';

export const WAR_HISTORY_RANGES: readonly WarHistoryRange[] = [
  'wars:25',
  'wars:50',
  'wars:100',
  'days:30',
  'days:60',
  'days:90',
];

export function warHistoryRangeFilter(range: WarHistoryRange, now = new Date()) {
  // Lifetime deliberately uses the user-approved 500 recorded-war cap.
  if (range === 'lifetime') return { limit: 500, startDate: null, endDate: null };
  const [unit, raw] = range.split(':');
  const count = Number(raw);
  return {
    // Date windows must not inherit the default 50-war cap.
    limit: unit === 'days' ? 500 : count,
    startDate: unit === 'days' ? new Date(now.getTime() - count * 86_400_000) : null,
    endDate: unit === 'days' ? now : null,
  };
}
