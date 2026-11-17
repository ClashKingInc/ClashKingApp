import { formatUpgradeDuration } from '../../core/utils/upgrade-duration';

/** Wiki durations share upgrade units, but retain actual sub-minute effects. */
export function formatWikiDuration(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds < 0) return '—';
  return seconds < 60 ? `${Math.round(seconds)}s` : formatUpgradeDuration(seconds);
}
