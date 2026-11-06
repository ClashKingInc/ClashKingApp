import { StatsRepository, type LegendDayPerformance } from './stats-repository';
import { StatsDateFilter, StatsLegendCohort, StatsLegendQuery } from '../models';

type Side = LegendDayPerformance['items'][number]['offense'];
export function totalLegendDays(rows: readonly Side[]): Side {
  const first = rows[0];
  if (!first)
    return {
      eligiblePlayerDays: 0,
      observedPlayerDays: 0,
      completePlayerDays: 0,
      partialPlayerDays: 0,
      missingPlayerDays: 0,
      invalidPlayerDays: 0,
      observedBattles: 0,
      observedTriples: 0,
      perfectPlayerDays: 0,
      tripleRate: null,
      perfectDayRate: null,
      meanTrophies: null,
      buckets: [],
    };
  const sum = (key: keyof Side) =>
    rows.reduce((n, r) => n + (typeof r[key] === 'number' ? (r[key] as number) : 0), 0);
  const battles = sum('observedBattles'),
    complete = sum('completePlayerDays');
  const average = (
    key: 'averageStars' | 'averageDestruction' | 'averageDuration' | 'meanTrophies',
    weight: 'observedBattles' | 'completePlayerDays',
  ) => {
    const valid = rows.filter((r) => r[key] != null);
    const count = valid.reduce((n, r) => n + r[weight], 0);
    return count ? valid.reduce((n, r) => n + r[key]! * r[weight], 0) / count : null;
  };
  return {
    ...first,
    eligiblePlayerDays: sum('eligiblePlayerDays'),
    observedPlayerDays: sum('observedPlayerDays'),
    completePlayerDays: complete,
    partialPlayerDays: sum('partialPlayerDays'),
    missingPlayerDays: sum('missingPlayerDays'),
    invalidPlayerDays: sum('invalidPlayerDays'),
    observedBattles: battles,
    observedTriples: sum('observedTriples'),
    perfectPlayerDays: sum('perfectPlayerDays'),
    tripleRate: battles ? sum('observedTriples') / battles : null,
    perfectDayRate: complete ? sum('perfectPlayerDays') / complete : null,
    meanTrophies: average('meanTrophies', 'completePlayerDays'),
    averageStars: average('averageStars', 'observedBattles'),
    averageDestruction: average('averageDestruction', 'observedBattles'),
    averageDuration: average('averageDuration', 'observedBattles'),
    ...(rows.every((r) => r.starCounts)
      ? {
          starCounts: [0, 1, 2, 3].map((i) =>
            rows.reduce((n, r) => n + (r.starCounts?.[i] ?? 0), 0),
          ),
        }
      : {}),
    ...(rows.every((r) => r.attackTypes)
      ? {
          attackTypes: {
            air: rows.reduce((n, r) => n + r.attackTypes!.air, 0),
            ground: rows.reduce((n, r) => n + r.attackTypes!.ground, 0),
            mixed: rows.reduce((n, r) => n + r.attackTypes!.mixed, 0),
            unknown: rows.reduce((n, r) => n + r.attackTypes!.unknown, 0),
          },
        }
      : {}),
    buckets: first.buckets.map((b, i) => {
      const playerDays = rows.reduce((n, r) => n + (r.buckets[i]?.playerDays ?? 0), 0);
      return { ...b, playerDays, share: complete ? playerDays / complete : null };
    }),
  };
}
/** Tracking stores completed days. One bounded aggregate request now covers the
 * whole selection; only today's unfinished data is calculated live by the API. */
export async function loadObservedRankedRange(
  repository: StatsRepository,
  dates: StatsDateFilter,
  armyTypes: boolean,
): Promise<LegendDayPerformance> {
  return repository.loadLegendPerformance(
    new StatsLegendQuery(dates, StatsLegendCohort.legend),
    false,
    true,
    armyTypes,
  );
}
