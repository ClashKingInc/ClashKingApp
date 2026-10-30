/** Shared by player summaries and the tracker; native Intl unit formatting is
 * inconsistent across devices. Keep explicit units and spaces between them. */
export function formatUpgradeDuration(seconds: number) {
  const value = Math.max(0, Math.round(seconds));
  if (value <= 0) return 'Now';
  const days = Math.floor(value / 86400);
  const hours = Math.floor((value % 86400) / 3600);
  const minutes = Math.floor((value % 3600) / 60);
  if (days) return hours ? `${days}d ${hours}h` : `${days}d`;
  if (hours) return minutes ? `${hours}h ${minutes}m` : `${hours}h`;
  return `${Math.max(1, Math.min(59, minutes))}m`;
}
