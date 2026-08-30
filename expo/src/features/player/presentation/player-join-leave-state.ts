import type { PlayerJoinLeavePage, PlayerJoinLeaveTotal } from '../models';

export function filteredJoinLeaveEvents(page: PlayerJoinLeavePage, type: 'all' | 'join' | 'leave') {
  return page.items.filter((item) => type === 'all' || item.type.toLowerCase().includes(type));
}
export function sortedJoinLeaveTotals(
  totals: readonly PlayerJoinLeaveTotal[],
  sort: 'time' | 'visits',
) {
  return [...totals].sort((a, b) => {
    const primary = sort === 'time' ? b.minutes - a.minutes : b.visits - a.visits;
    return (
      primary ||
      (sort === 'time' ? b.visits - a.visits : b.minutes - a.minutes) ||
      a.clan.name.localeCompare(b.clan.name)
    );
  });
}
export function mergeJoinLeavePages(
  current: PlayerJoinLeavePage,
  next: PlayerJoinLeavePage,
): PlayerJoinLeavePage {
  const seen = new Set(
    current.items.map(
      (event) => `${event.time.toISOString()}|${event.type}|${event.clan?.tag ?? ''}`,
    ),
  );
  return {
    available: next.available,
    items: [
      ...current.items,
      ...next.items.filter(
        (event) => !seen.has(`${event.time.toISOString()}|${event.type}|${event.clan?.tag ?? ''}`),
      ),
    ],
  } as PlayerJoinLeavePage;
}
export function joinLeaveDuration(minutes: number) {
  const days = Math.floor(minutes / 1440);
  if (days >= 365) {
    const years = Math.floor(days / 365),
      months = Math.floor((days % 365) / 30);
    return months ? `${years}y ${months}mo` : `${years}y`;
  }
  if (days >= 30) {
    const months = Math.floor(days / 30),
      remaining = days % 30;
    return remaining ? `${months}mo ${remaining}d` : `${months}mo`;
  }
  if (days > 0) return `${days}d`;
  const hours = Math.floor(minutes / 60);
  return hours ? `${hours}h` : `${minutes}m`;
}
