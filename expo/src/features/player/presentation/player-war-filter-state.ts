import { WarStatsFilter, type PlayerWarStats } from '../models';

export const allWarTypes = ['random', 'cwl', 'friendly'] as const;
export function selectedWarTypes(filter: WarStatsFilter) {
  return filter.warTypes ?? allWarTypes;
}
export function toggleQuickWarType(filter: WarStatsFilter, type: string) {
  const current = selectedWarTypes(filter);
  return new WarStatsFilter({
    ...filter,
    warTypes: current.includes(type as never)
      ? current.filter((value) => value !== type)
      : [...current, type],
  });
}
export function builtInWarFilters(now: Date) {
  const end = new Date(now);
  const start = new Date(now.getTime() - 30 * 86400000);
  return [
    ['Last 30 days', new WarStatsFilter({ startDate: start, endDate: end })],
    ['3 stars', new WarStatsFilter({ allowedStars: [3] })],
    ['CWL', new WarStatsFilter({ warTypes: ['cwl'] })],
    ['Random', new WarStatsFilter({ warTypes: ['random'] })],
    ['Friendly', new WarStatsFilter({ warTypes: ['friendly'] })],
    ['Fresh', new WarStatsFilter({ freshAttacksOnly: true })],
  ] as const;
}

export function warFiltersEqual(a: WarStatsFilter, b: WarStatsFilter) {
  return stableJson(a.toJson()) === stableJson(b.toJson());
}
export function warFilterCriteriaEqual(a: WarStatsFilter, b: WarStatsFilter) {
  const left = { ...a.toJson() },
    right = { ...b.toJson() };
  delete left.limit;
  delete right.limit;
  return stableJson(left) === stableJson(right);
}

function stableJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(',')}]`;
  if (value && typeof value === 'object')
    return `{${Object.entries(value as Record<string, unknown>)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([key, item]) => `${JSON.stringify(key)}:${stableJson(item)}`)
      .join(',')}}`;
  return JSON.stringify(value);
}

export function performanceWarFilters(data: PlayerWarStats, now: Date) {
  const stats = data.getStatsForTypes([]);
  if (stats.warsCounts < 5) return [];
  const suggestions: (readonly [string, WarStatsFilter])[] = [];
  if (stats.averageStars < 2)
    suggestions.push(['Failed Attacks (0-1 Stars)', new WarStatsFilter({ allowedStars: [0, 1] })]);
  const threeStars = stats.starsCount['3'] ?? 0;
  if (!stats.totalAttacks || threeStars / stats.totalAttacks < 0.6)
    suggestions.push(['Missed Perfect Attacks', new WarStatsFilter({ allowedStars: [2] })]);
  for (const [matchup, value] of Object.entries(stats.byEnemyTownhall)) {
    const enemy = Number(matchup.split('_')[1]);
    if (Number.isFinite(enemy) && value.count >= 3 && value.averageStars < 1.5)
      suggestions.push([
        `TH${enemy} Attack Issues`,
        new WarStatsFilter({ enemyTownHalls: [enemy] }),
      ]);
  }
  for (const [matchup, value] of Object.entries(stats.byEnemyTownhallDef)) {
    const attacker = Number(matchup.split('_')[0]);
    if (Number.isFinite(attacker) && value.count >= 3 && value.averageStars > 2)
      suggestions.push([
        `TH${attacker} Defense Issues`,
        new WarStatsFilter({ enemyTownHalls: [attacker] }),
      ]);
  }
  const cwl = data.getStatsForTypes(['cwl']);
  const random = data.getStatsForTypes(['random']);
  if (cwl.warsCounts >= 3 && random.warsCounts >= 3) {
    if (cwl.averageStars < random.averageStars - 0.5)
      suggestions.push(['CWL Performance Issues', new WarStatsFilter({ warTypes: ['cwl'] })]);
    if (random.averageStars < cwl.averageStars - 0.5)
      suggestions.push(['Random War Issues', new WarStatsFilter({ warTypes: ['random'] })]);
  }
  suggestions.push(['Fresh Attack Analysis', new WarStatsFilter({ freshAttacksOnly: true })]);
  suggestions.push([
    'Recent Performance (30 Days)',
    new WarStatsFilter({
      startDate: new Date(now.getTime() - 30 * 86400000),
      endDate: new Date(now),
    }),
  ]);
  suggestions.push(['High-Stakes Attacks', new WarStatsFilter({ maxMapPosition: 5 })]);
  suggestions.push(['Cleanup Attacks', new WarStatsFilter({ minMapPosition: 6 })]);
  return suggestions.slice(0, 6);
}
