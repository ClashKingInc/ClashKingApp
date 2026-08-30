import type {
  PlayerLegendRanking,
  PlayerLegendSeason,
  RankedLeagueBattle,
  RankedLeagueData,
  RankedLeagueGroup,
  RankedLeagueTier,
} from '../../player/models';

export interface RankedPeriod {
  readonly seasonId: number;
  readonly startsAt: Date;
  readonly trophies: number;
  readonly placement: number;
  readonly attackWins: number;
  readonly attackLosses: number;
  readonly attackStars: number;
  readonly defenseWins: number;
  readonly defenseLosses: number;
  readonly defenseStars: number;
  readonly maxBattles: number;
  readonly tier: RankedLeagueTier | null;
  readonly group: RankedLeagueGroup | null;
  readonly isCurrent: boolean;
  readonly attacks: readonly RankedLeagueBattle[];
  readonly defenses: readonly RankedLeagueBattle[];
  readonly hasDetails: boolean;
  readonly attackCount: number;
  readonly defenseCount: number;
}

export interface RankedTierHighlights {
  readonly tier: RankedLeagueTier | null;
  readonly lastPeriod: RankedPeriod;
  readonly bestRankPeriod: RankedPeriod | null;
  readonly bestTrophiesPeriod: RankedPeriod;
  readonly mostAttacksPeriod: RankedPeriod;
}

export interface RankedBattleSummary {
  readonly trophyTotal: number;
  readonly trophyAverage: number | null;
  readonly remaining: number | null;
}

export function rankedHistoricalPeriods(periods: readonly RankedPeriod[]): readonly RankedPeriod[] {
  return periods.filter((period) => !period.isCurrent);
}

export function rankedBattleSummary(
  battles: readonly RankedLeagueBattle[],
  count: number,
  maxBattles: number,
): RankedBattleSummary {
  const trophyTotal = battles.reduce((sum, battle) => sum + battle.trophies, 0);
  return {
    trophyTotal,
    trophyAverage: battles.length === 0 ? null : trophyTotal / battles.length,
    remaining: maxBattles > 0 ? Math.max(0, Math.min(maxBattles, maxBattles - count)) : null,
  };
}

export function rankedPeriods(data: RankedLeagueData, now = new Date()): readonly RankedPeriod[] {
  const group = data.currentGroup;
  const member = data.currentMember;
  const currentSeasonId = group?.seasonId ?? Math.floor(now.getTime() / 1000);
  const create = (
    input: Omit<
      RankedPeriod,
      'attacks' | 'defenses' | 'hasDetails' | 'attackCount' | 'defenseCount'
    >,
  ): RankedPeriod => {
    const attacks = input.group?.attackLogs ?? [];
    const defenses = input.group?.defenseLogs ?? [];
    const hasDetails = input.group !== null;
    return {
      ...input,
      attacks,
      defenses,
      hasDetails,
      attackCount: hasDetails ? attacks.length : input.attackWins + input.attackLosses,
      defenseCount: hasDetails ? defenses.length : input.defenseWins + input.defenseLosses,
    };
  };
  const periods: RankedPeriod[] = [
    create({
      seasonId: currentSeasonId,
      startsAt: new Date(currentSeasonId * 1000),
      trophies: member?.leagueTrophies ?? data.trophies,
      placement: data.currentRank ?? 0,
      attackWins: member?.attackWinCount ?? 0,
      attackLosses: member?.attackLoseCount ?? 0,
      attackStars: (group?.attackLogs ?? []).reduce((sum, battle) => sum + battle.stars, 0),
      defenseWins: member?.defenseWinCount ?? 0,
      defenseLosses: member?.defenseLoseCount ?? 0,
      defenseStars: (group?.defenseLogs ?? []).reduce((sum, battle) => sum + battle.stars, 0),
      maxBattles: data.currentMaxBattles ?? 0,
      tier: data.currentTier,
      group,
      isCurrent: true,
    }),
  ];
  for (const entry of data.history) {
    if (entry.leagueSeasonId === currentSeasonId) continue;
    periods.push(
      create({
        seasonId: entry.leagueSeasonId,
        startsAt: entry.startsAt,
        trophies: entry.leagueTrophies,
        placement: entry.placement,
        attackWins: entry.attackWins,
        attackLosses: entry.attackLosses,
        attackStars: entry.attackStars,
        defenseWins: entry.defenseWins,
        defenseLosses: entry.defenseLosses,
        defenseStars: entry.defenseStars,
        maxBattles: entry.maxBattles,
        tier: data.tiers.get(entry.leagueTierId) ?? null,
        group: data.groupForSeason(entry.leagueSeasonId),
        isCurrent: false,
      }),
    );
  }
  return periods;
}

export function rankedTierHighlights(
  periods: readonly RankedPeriod[],
): readonly RankedTierHighlights[] {
  const byTier = new Map<number, RankedPeriod[]>();
  for (const period of periods) {
    if (period.tier === null) continue;
    const list = byTier.get(period.tier.id) ?? [];
    list.push(period);
    byTier.set(period.tier.id, list);
  }
  return [...byTier.values()]
    .map((list) => {
      const ranked = list.filter((period) => period.placement > 0);
      return {
        tier: list[0]?.tier ?? null,
        lastPeriod: latest(list),
        bestRankPeriod: ranked.length
          ? ranked.reduce((a, b) => (a.placement < b.placement ? a : b))
          : null,
        bestTrophiesPeriod: list.reduce((a, b) => (a.trophies > b.trophies ? a : b)),
        mostAttacksPeriod: list.reduce((a, b) => (a.attackCount > b.attackCount ? a : b)),
      };
    })
    .sort((a, b) => (b.tier?.id ?? 0) - (a.tier?.id ?? 0));
}

function latest(periods: readonly RankedPeriod[]) {
  return periods.reduce((a, b) => (a.seasonId > b.seasonId ? a : b));
}

export interface LegendChartPoint {
  readonly x: number;
  readonly y: number;
  readonly label: string;
}

export function legendSeasonSeries(
  season: PlayerLegendSeason,
): readonly (readonly LegendChartPoint[])[] {
  const days = Object.entries(season.days).sort(([a], [b]) => a.localeCompare(b));
  const lines: LegendChartPoint[][] = [];
  let current: LegendChartPoint[] = [];
  for (const [key, day] of days) {
    const date = new Date(`${key}T00:00:00Z`);
    const point = {
      x: Math.floor((date.getTime() - season.start.getTime()) / 86_400_000),
      y: day.endTrophies ?? 0,
      label: key,
    };
    const previous = current.at(-1);
    if (previous && point.x - previous.x !== 1) {
      lines.push(current);
      current = [];
    }
    current.push(point);
  }
  if (current.length) lines.push(current);
  return lines;
}

export function legendHistorySeries(
  rankings: readonly PlayerLegendRanking[],
): readonly LegendChartPoint[] {
  return rankings
    .map((ranking) => {
      const value =
        ranking.season.split('-').length === 2 ? `${ranking.season}-01` : ranking.season;
      return { x: new Date(value).getTime(), y: ranking.trophies, label: ranking.season };
    })
    .sort((a, b) => a.x - b.x);
}

export function rankedHistorySeries(periods: readonly RankedPeriod[]): readonly LegendChartPoint[] {
  return [...periods]
    .sort((a, b) => a.seasonId - b.seasonId)
    .map((period, index) => ({
      x: index,
      y: period.trophies,
      label: period.startsAt.toISOString(),
    }));
}
