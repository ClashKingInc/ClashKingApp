/** v2 official season IDs encode the end of a 28-day tournament (Tracking's season contract). */
export function currentLegendSeasonStart(seasons: readonly string[], today: string): string | null {
  const anchor = seasons.filter(value => value.startsWith('v2-')).map(value => Date.parse(value.slice(3)))
    .filter(Number.isFinite).sort((a, b) => b - a)[0];
  if (anchor === undefined) return null;
  const now = Date.parse(`${today}T05:10:00Z`);
  const period = 28 * 86_400_000;
  return new Date(anchor + Math.floor((now - anchor) / period) * period).toISOString().slice(0, 10);
}
