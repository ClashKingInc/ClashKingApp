/** v2 official season IDs encode the end of a 28-day tournament (Tracking's season contract). */
export function legendSeasonFinish(season: string): number {
  if (/^v2-\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z$/u.test(season))
    return Date.parse(season.slice(3));
  if (/^\d{4}-\d{2}-\d{2}$/u.test(season)) return Date.parse(`${season}T05:00:00Z`);
  if (!/^\d{4}-\d{2}$/u.test(season)) return Number.NaN;
  const [year, month] = season.split('-').map(Number) as [number, number];
  if (month < 1 || month > 12) return Number.NaN;
  const rankedStart = Date.parse('2025-10-06T05:00:00Z');
  // Match the API/clashy.go calendar, including the extended final old-system season.
  // Parsing YYYY-MM as the first of the month misclassifies transition seasons.
  if (season === '2025-09') return rankedStart;
  const offset = year * 12 + month - (2025 * 12 + 10);
  if (offset >= 0) return rankedStart + (offset + 1) * 28 * 86_400_000;
  const end = new Date(Date.UTC(year, month, 0, 5));
  end.setUTCDate(end.getUTCDate() - (end.getUTCDay() + 6) % 7);
  return end.valueOf();
}

export function currentLegendSeasonStart(seasons: readonly string[], today: string): string | null {
  const anchor = seasons.filter(value => value.startsWith('v2-')).map(value => Date.parse(value.slice(3)))
    .filter(Number.isFinite).sort((a, b) => b - a)[0];
  if (anchor === undefined) return null;
  const now = Date.parse(`${today}T05:00:00Z`);
  const period = 28 * 86_400_000;
  return new Date(anchor + Math.floor((now - anchor) / period) * period).toISOString().slice(0, 10);
}
