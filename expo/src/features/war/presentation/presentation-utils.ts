import type {
  CwlClan,
  CwlLeagueRound,
  CwlMember,
  WarAttack,
  WarClan,
  WarCwl,
  WarInfo,
  WarMember,
} from '../models';
import type { useI18n } from '../../../i18n';

type Translate = ReturnType<typeof useI18n>['t'];

export function relativeWarTime(value: Date, now: Date, t: Translate): string {
  const elapsed = Math.max(0, now.getTime() - value.getTime());
  if (elapsed < 60_000) return t('timeJustNow');
  const minutes = Math.floor(elapsed / 60_000);
  if (minutes < 60)
    return minutes === 1
      ? t('timeMinuteAgo', { minute: minutes })
      : t('timeMinutesAgo', { minutes });
  const hours = Math.floor(minutes / 60);
  if (hours < 24)
    return hours === 1 ? t('timeHourAgo', { hour: hours }) : t('timeHoursAgo', { hours });
  const days = Math.floor(hours / 24);
  return days === 1 ? t('timeDayAgo', { day: days }) : t('timeDaysAgo', { days });
}

export function remainingWarTime(value: Date, now: Date, t: Translate): string {
  const minutes = Math.max(1, Math.ceil((value.getTime() - now.getTime()) / 60_000));
  if (minutes < 60)
    return t('timeDurationShort', { unit: 'other', primary: minutes, secondary: 0 });
  const hours = Math.floor(minutes / 60);
  if (hours < 24)
    return t('timeDurationShort', {
      unit: 'hoursMinutes',
      primary: hours,
      secondary: minutes % 60,
    });
  return t('timeDurationShort', {
    unit: 'daysHours',
    primary: Math.floor(hours / 24),
    secondary: hours % 24,
  });
}

export type WarMemberFilter =
  | 'all'
  | 'rattacks'
  | 'rdefenses'
  | 'bestAttacks'
  | 'bestDefenses'
  | 'bestPerformance'
  | 'noattacks'
  | 'nodefenses'
  | '3stars'
  | '2stars'
  | '1star'
  | '0star'
  | 'def_3stars'
  | 'def_2stars'
  | 'def_1star'
  | 'def_0star';

export type CwlMemberSort =
  | 'stars'
  | 'percentage'
  | 'averageStars'
  | 'averagePercentage'
  | 'attackCount'
  | 'missedAttacks'
  | '0stars'
  | '1stars'
  | '2stars'
  | '3stars'
  | 'attackLowerTH'
  | 'attackUpperTH'
  | 'defStars'
  | 'defDestruction'
  | 'defAverageStars'
  | 'defAverageDestruction'
  | 'def0stars'
  | 'def1stars'
  | 'def2stars'
  | 'def3stars'
  | 'defenseLowerTH'
  | 'defenseUpperTH';

export interface WarEvent {
  readonly attack: WarAttack;
  readonly attacker: WarMember | null;
  readonly defender: WarMember | null;
  readonly side: 'clan' | 'opponent';
}

export interface WarComparisonStats {
  readonly clanStarCounts: Readonly<Record<number, number>>;
  readonly opponentStarCounts: Readonly<Record<number, number>>;
  readonly clanAttacksRemaining: number;
  readonly opponentAttacksRemaining: number;
  readonly clanAverageAttackTime: number | null;
  readonly opponentAverageAttackTime: number | null;
  readonly leader: 'clan' | 'opponent' | 'tie';
  readonly starsToLead: number;
  readonly destructionToLead: number;
}

export type CwlRoundTiming =
  | { readonly kind: 'startsAt' | 'endsAt'; readonly time: Date }
  | { readonly kind: 'endedJustNow' }
  | { readonly kind: 'endedMinutesAgo'; readonly value: number }
  | { readonly kind: 'endedHoursAgo'; readonly value: number }
  | { readonly kind: 'endedDaysAgo'; readonly value: number }
  | { readonly kind: 'unknown' };

export type WarAnalysisState =
  | {
      readonly kind: 'notStarted';
      readonly clanRemaining: number;
      readonly opponentRemaining: number;
    }
  | { readonly kind: 'perfectDraw' }
  | { readonly kind: 'secured' }
  | {
      readonly kind: 'open';
      readonly canSecure: boolean;
      readonly opponentName: string;
      readonly starsGoal: number;
      readonly destructionGoal: number;
    };

export function filterWarMembers(
  source: readonly WarMember[],
  filter: WarMemberFilter,
  query = '',
): WarMember[] {
  const members = [...source];
  const byPosition = (left: WarMember, right: WarMember) =>
    left.mapPosition - right.mapPosition || left.name.localeCompare(right.name);
  let filtered: WarMember[];
  if (filter === 'rattacks') {
    filtered = members.filter((member) => (member.attacks?.length ?? 0) > 0);
    filtered.sort((left, right) => compareAttack(bestAttack(right), bestAttack(left)));
  } else if (filter === 'rdefenses') {
    filtered = members.filter((member) => member.opponentAttacks > 0 && member.bestOpponentAttack);
    filtered.sort((left, right) =>
      compareAttack(left.bestOpponentAttack, right.bestOpponentAttack),
    );
  } else if (filter === 'noattacks') {
    filtered = members.filter((member) => !(member.attacks?.length ?? 0)).sort(byPosition);
  } else if (filter === 'nodefenses') {
    filtered = members.filter((member) => member.opponentAttacks === 0).sort(byPosition);
  } else if (/^[0-3]stars?$/.test(filter)) {
    const stars = Number(filter[0]);
    filtered = members
      .filter((member) => member.attacks?.some((attack) => attack.stars === stars))
      .sort(byPosition);
  } else if (/^def_[0-3]stars?$/.test(filter)) {
    const stars = Number(filter[4]);
    filtered = members
      .filter((member) => member.bestOpponentAttack?.stars === stars)
      .sort(byPosition);
  } else if (filter === 'bestAttacks') {
    filtered = members
      .filter((member) => member.attacks?.length)
      .sort((left, right) => {
        const leftStars = sum(left.attacks ?? [], (attack) => attack.stars);
        const rightStars = sum(right.attacks ?? [], (attack) => attack.stars);
        return (
          rightStars - leftStars ||
          sum(right.attacks ?? [], (attack) => attack.destructionPercentage) -
            sum(left.attacks ?? [], (attack) => attack.destructionPercentage)
        );
      });
  } else if (filter === 'bestDefenses') {
    filtered = members
      .filter((member) => member.bestOpponentAttack)
      .sort((left, right) => compareAttack(left.bestOpponentAttack, right.bestOpponentAttack));
  } else if (filter === 'bestPerformance') {
    const score = (member: WarMember) =>
      sum(member.attacks ?? [], (attack) => attack.stars * 100 + attack.destructionPercentage) -
      ((member.bestOpponentAttack?.stars ?? 0) * 100 +
        (member.bestOpponentAttack?.destructionPercentage ?? 0));
    filtered = members
      .filter((member) => member.attacks?.length || member.bestOpponentAttack)
      .sort((left, right) => score(right) - score(left));
  } else filtered = members.sort(byPosition);

  const needle = query.trim().toLowerCase();
  if (!needle) return filtered;
  return filtered.filter(
    (member) =>
      member.name.toLowerCase().includes(needle) ||
      member.tag.toLowerCase().includes(needle) ||
      `#${member.mapPosition}`.includes(needle) ||
      `th${member.townhallLevel}`.includes(needle) ||
      String(member.townhallLevel).includes(needle),
  );
}

export function buildWarEvents(
  war: WarInfo,
  options: {
    query?: string;
    stars?: number | null;
    side?: 'clan' | 'opponent' | null;
    newestFirst?: boolean;
  } = {},
): WarEvent[] {
  const events: WarEvent[] = [];
  const collect = (side: 'clan' | 'opponent', clan: WarClan | null, other: WarClan | null) => {
    clan?.members.forEach((attacker) =>
      (attacker.attacks ?? []).forEach((attack) =>
        events.push({
          attack,
          attacker,
          defender: other?.members.find((member) => member.tag === attack.defenderTag) ?? null,
          side,
        }),
      ),
    );
  };
  collect('clan', war.clan, war.opponent);
  collect('opponent', war.opponent, war.clan);
  const needle = options.query?.trim().toLowerCase() ?? '';
  const filtered = events.filter(
    (event) =>
      (options.stars === null ||
        options.stars === undefined ||
        event.attack.stars === options.stars) &&
      (options.side === null || options.side === undefined || event.side === options.side) &&
      (!needle ||
        event.attacker?.name.toLowerCase().includes(needle) ||
        event.defender?.name.toLowerCase().includes(needle) ||
        event.attack.attackerTag.toLowerCase().includes(needle) ||
        event.attack.defenderTag.toLowerCase().includes(needle)),
  );
  filtered.sort((left, right) =>
    options.newestFirst === false
      ? left.attack.order - right.attack.order
      : right.attack.order - left.attack.order,
  );
  return filtered;
}

/** Mirrors the timing line on Flutter's CWL round war cards. */
export function cwlRoundTiming(war: WarInfo, now = new Date()): CwlRoundTiming {
  if (war.state === 'preparation' || war.state === 'preparationDay') {
    return war.startTime ? { kind: 'startsAt', time: war.startTime } : { kind: 'unknown' };
  }
  if (war.state === 'inWar' || war.state === 'warInWar') {
    return war.endTime ? { kind: 'endsAt', time: war.endTime } : { kind: 'unknown' };
  }
  if (!war.endTime) return { kind: 'unknown' };

  const elapsedMinutes = Math.max(0, Math.floor((now.getTime() - war.endTime.getTime()) / 60_000));
  if (elapsedMinutes < 1) return { kind: 'endedJustNow' };
  if (elapsedMinutes < 60) return { kind: 'endedMinutesAgo', value: elapsedMinutes };
  const elapsedHours = Math.floor(elapsedMinutes / 60);
  if (elapsedHours < 24) return { kind: 'endedHoursAgo', value: elapsedHours };
  return { kind: 'endedDaysAgo', value: Math.floor(elapsedHours / 24) };
}

export function warComparisonStats(war: WarInfo): WarComparisonStats {
  const clan = war.clan;
  const opponent = war.opponent;
  const capacity = (side: WarClan | null) =>
    (war.teamSize ?? side?.members.length ?? 0) * war.effectiveAttacksPerMember;
  const starCounts = (side: WarClan | null) => {
    const result: Record<number, number> = { 0: 0, 1: 0, 2: 0, 3: 0 };
    side?.members.forEach((member) =>
      member.attacks?.forEach((attack) => {
        result[attack.stars] = (result[attack.stars] ?? 0) + 1;
      }),
    );
    return result;
  };
  const clanScore = [clan?.stars ?? 0, clan?.destructionPercentage ?? 0] as const;
  const opponentScore = [opponent?.stars ?? 0, opponent?.destructionPercentage ?? 0] as const;
  const leader =
    clanScore[0] === opponentScore[0]
      ? clanScore[1] === opponentScore[1]
        ? 'tie'
        : clanScore[1] > opponentScore[1]
          ? 'clan'
          : 'opponent'
      : clanScore[0] > opponentScore[0]
        ? 'clan'
        : 'opponent';
  const behind = leader === 'clan' ? opponentScore : clanScore;
  const ahead = leader === 'clan' ? clanScore : opponentScore;
  return {
    clanStarCounts: starCounts(clan),
    opponentStarCounts: starCounts(opponent),
    clanAttacksRemaining: Math.max(0, capacity(clan) - (clan?.attacks ?? 0)),
    opponentAttacksRemaining: Math.max(0, capacity(opponent) - (opponent?.attacks ?? 0)),
    clanAverageAttackTime: clan?.getAverageAttackTime() ?? null,
    opponentAverageAttackTime: opponent?.getAverageAttackTime() ?? null,
    leader,
    starsToLead: leader === 'tie' ? 1 : Math.max(0, ahead[0] - behind[0] + 1),
    destructionToLead: ahead[0] === behind[0] ? Math.max(0, ahead[1] - behind[1] + 0.01) : 0,
  };
}

export function calculateRequiredDestruction(
  currentDestruction: number,
  attacksUsed: number,
  attacksRemaining: number,
  targetAverage: number,
): number | null {
  if (attacksRemaining <= 0 || targetAverage < 0 || targetAverage > 100) return null;
  const targetTotal = targetAverage * (attacksUsed + attacksRemaining);
  return Math.max(0, Math.min(100 * attacksRemaining, targetTotal - currentDestruction));
}

/** Flutter's fast calculator is deliberately a simple percentage-points × team-size helper. */
export function calculateFastWarResult(teamSize: string, percentNeeded: string): number {
  const team = Number.parseFloat(teamSize);
  const percent = Number.parseFloat(percentNeeded);
  return (Number.isFinite(team) ? team : 0) * (Number.isFinite(percent) ? percent : 0);
}

/** Mirrors the active-war secure-result analysis in WarStatisticsTab. */
export function analyzeWarState(war: WarInfo): WarAnalysisState | null {
  const clan = war.clan;
  const opponent = war.opponent;
  if (!clan || !opponent || (war.state !== 'inWar' && war.state !== 'warInWar')) return null;
  const teamSize = war.teamSize ?? 15;
  const maxStars = teamSize * 3;
  const maxAttacks = teamSize * war.effectiveAttacksPerMember;
  const clanState = sideState(clan, opponent, maxAttacks, maxStars);
  const opponentState = sideState(opponent, clan, maxAttacks, maxStars);
  if (
    clan.stars === 0 &&
    opponent.stars === 0 &&
    clan.destructionPercentage === 0 &&
    opponent.destructionPercentage === 0
  ) {
    return {
      kind: 'notStarted',
      clanRemaining: clanState.remainingAttacks,
      opponentRemaining: opponentState.remainingAttacks,
    };
  }
  if (clanState.isPerfect && opponentState.isPerfect) return { kind: 'perfectDraw' };
  if (compareScore(clanState.current, opponentState.potential) >= 0) return { kind: 'secured' };

  const canSecure = compareScore(clanState.potential, opponentState.potential) > 0;
  if (!canSecure) {
    return {
      kind: 'open',
      canSecure: false,
      opponentName: opponent.name,
      starsGoal: 0,
      destructionGoal: 0,
    };
  }
  const starsForWin = clamp(
    opponentState.potential.stars + 1 - clanState.current.stars,
    0,
    maxStars,
  );
  if (clanState.potential.stars > opponentState.potential.stars && starsForWin > 0) {
    return {
      kind: 'open',
      canSecure: true,
      opponentName: opponent.name,
      starsGoal: starsForWin,
      destructionGoal: 0,
    };
  }
  const starsForTie = clamp(opponentState.potential.stars - clanState.current.stars, 0, maxStars);
  const destructionGoal = Math.max(
    0,
    opponentState.potential.destruction - clanState.current.destruction + 0.01,
  );
  const canWinByDestruction =
    clanState.potential.stars >= opponentState.potential.stars &&
    clanState.potential.destruction > opponentState.potential.destruction;
  return {
    kind: 'open',
    canSecure: true,
    opponentName: opponent.name,
    starsGoal: starsForTie,
    destructionGoal: canWinByDestruction && destructionGoal > 0.004 ? destructionGoal : 0,
  };
}

interface Score {
  readonly stars: number;
  readonly destruction: number;
}

function sideState(side: WarClan, target: WarClan, maxAttacks: number, maxStars: number) {
  const remainingAttacks = clamp(maxAttacks - side.attacks, 0, maxAttacks);
  const current = { stars: side.stars, destruction: side.destructionPercentage };
  const potential = potentialScore(side, target, remainingAttacks, maxStars);
  return {
    current,
    potential,
    remainingAttacks,
    isPerfect: current.stars >= maxStars && current.destruction >= 100,
  };
}

function potentialScore(
  side: WarClan,
  target: WarClan,
  remainingAttacks: number,
  maxStars: number,
): Score {
  if (remainingAttacks <= 0) return { stars: side.stars, destruction: side.destructionPercentage };
  if (!target.members.length)
    return { stars: Math.min(maxStars, side.stars + remainingAttacks * 3), destruction: 100 };
  const baseCount = Math.max(1, target.members.length);
  const improvements = target.members
    .map((member) => ({
      stars: Math.max(0, 3 - (member.bestOpponentAttack?.stars ?? 0)),
      destruction:
        Math.max(0, 100 - (member.bestOpponentAttack?.destructionPercentage ?? 0)) / baseCount,
    }))
    .sort((left, right) => right.stars - left.stars || right.destruction - left.destruction)
    .slice(0, remainingAttacks);
  return {
    stars: Math.min(maxStars, side.stars + improvements.reduce((sum, item) => sum + item.stars, 0)),
    destruction: Math.min(
      100,
      side.destructionPercentage + improvements.reduce((sum, item) => sum + item.destruction, 0),
    ),
  };
}

function compareScore(left: Score, right: Score): number {
  return left.stars === right.stars
    ? left.destruction - right.destruction
    : left.stars - right.stars;
}

function clamp(value: number, minimum: number, maximum: number): number {
  return Math.min(maximum, Math.max(minimum, value));
}

export function sortCwlClans(clans: readonly CwlClan[], key: string): CwlClan[] {
  const result = [...clans];
  result.sort((left, right) => {
    if (key === 'percentage')
      return right.destructionPercentageInflicted - left.destructionPercentageInflicted;
    if (key === 'townHallLevel') return compareTownHallComposition(left, right);
    if (key === 'missedAttacks') return right.missedAttacks - left.missedAttacks;
    if (key === 'averageStars') return right.averageStars - left.averageStars;
    if (key === '0stars') return right.zeroStar - left.zeroStar;
    if (key === '1stars') return right.oneStar - left.oneStar;
    if (key === '2stars') return right.twoStars - left.twoStars;
    if (key === '3stars') return right.threeStars - left.threeStars;
    if (key === 'defStars') return right.defStars - left.defStars;
    if (key === 'defDestruction') return right.destructionPercentage - left.destructionPercentage;
    if (key === 'defAverageStars') return right.defAverageStars - left.defAverageStars;
    if (key === 'defAverageDestruction')
      return right.defAverageDestruction - left.defAverageDestruction;
    if (key === 'def0stars') return right.zeroStarDef - left.zeroStarDef;
    if (key === 'def1stars') return right.oneStarDef - left.oneStarDef;
    if (key === 'def2stars') return right.twoStarsDef - left.twoStarsDef;
    if (key === 'def3stars') return right.threeStarsDef - left.threeStarsDef;
    return (
      right.stars - left.stars ||
      right.destructionPercentageInflicted - left.destructionPercentageInflicted
    );
  });
  return result;
}

/** Preparation round first, active round second, then playable rounds newest-first. */
export function orderCwlRounds(summary: WarCwl): CwlLeagueRound[] {
  const rounds = summary.leagueInfo?.rounds ?? [];
  const current = summary.leagueInfo?.getCurrentRounds() ?? null;
  if (!current) return [];
  const playable = rounds.filter((round) => round.warTags.some((tag) => tag !== '#0'));
  const wars = (round: CwlLeagueRound) =>
    round.warTags
      .filter((tag) => tag !== '#0')
      .map((tag) => summary.getWarInfoFromTag(tag))
      .filter((war) => war.clan !== null && war.opponent !== null);
  const preparation = [...playable]
    .reverse()
    .find(
      (round) =>
        round.roundNumber !== current.roundNumber &&
        wars(round).some((war) => war.state === 'preparation' || war.state === 'preparationDay'),
    );
  const ordered: CwlLeagueRound[] = [];
  for (const round of [preparation, current, ...[...playable].reverse()]) {
    if (round && !ordered.some((item) => item.roundNumber === round.roundNumber))
      ordered.push(round);
  }
  return ordered;
}

export function sortCwlMembers(
  members: readonly CwlMember[],
  key: CwlMemberSort,
  query = '',
): CwlMember[] {
  const value = (member: CwlMember): number | string => {
    if (key === 'stars') return member.attackStats?.stars ?? 0;
    if (key === 'percentage') return member.attackStats?.totalDestruction ?? 0;
    if (key === 'averageStars') return member.attackStats?.averageStars ?? 0;
    if (key === 'averagePercentage') return member.attackStats?.averageDestruction ?? 0;
    if (key === 'attackCount') return member.attackStats?.attackCount ?? 0;
    if (key === 'missedAttacks') return member.attackStats?.missedAttacks ?? 0;
    if (key === '0stars') return member.zeroStar;
    if (key === '1stars') return member.oneStar;
    if (key === '2stars') return member.twoStars;
    if (key === '3stars') return member.threeStars;
    if (key === 'attackLowerTH') return member.attackLowerTHLevel ?? 0;
    if (key === 'attackUpperTH') return member.attackUpperTHLevel ?? 0;
    if (key === 'defStars') return member.defenseStats?.stars ?? 0;
    if (key === 'defDestruction') return member.defenseStats?.totalDestruction ?? 0;
    if (key === 'defAverageStars') return member.defenseStats?.averageStars ?? 0;
    if (key === 'defAverageDestruction') return member.defenseStats?.averageDestruction ?? 0;
    if (key === 'def0stars') return member.zeroStarDef;
    if (key === 'def1stars') return member.oneStarDef;
    if (key === 'def2stars') return member.twoStarsDef;
    if (key === 'def3stars') return member.threeStarsDef;
    if (key === 'defenseLowerTH') return member.defenseLowerTHLevel ?? 0;
    return member.defenseUpperTHLevel ?? 0;
  };
  const needle = query.trim().toLowerCase();
  return [...members]
    .filter(
      (member) =>
        !needle ||
        member.name.toLowerCase().includes(needle) ||
        member.tag.toLowerCase().includes(needle),
    )
    .sort((left, right) => {
      const a = value(left);
      const b = value(right);
      return typeof a === 'string' && typeof b === 'string'
        ? a.localeCompare(b)
        : Number(b) - Number(a);
    });
}

export function formatPercent(value: number, precision = 2): string {
  return `${Number.isInteger(value) ? value.toFixed(0) : value.toFixed(precision)}%`;
}

export function formatDuration(seconds: number | null): string {
  if (seconds === null) return '—';
  if (seconds <= 0) return '0s';
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = seconds % 60;
  if (minutes <= 0) return `${remainingSeconds}s`;
  return `${minutes}m ${String(remainingSeconds).padStart(2, '0')}s`;
}

function bestAttack(member: WarMember): WarAttack | null {
  return [...(member.attacks ?? [])].sort((left, right) => compareAttack(right, left))[0] ?? null;
}

function compareAttack(left: WarAttack | null, right: WarAttack | null): number {
  if (!left && !right) return 0;
  if (!left) return -1;
  if (!right) return 1;
  return left.stars - right.stars || left.destructionPercentage - right.destructionPercentage;
}

function sum<T>(values: readonly T[], pick: (value: T) => number): number {
  return values.reduce((total, value) => total + pick(value), 0);
}

function compareTownHallComposition(left: CwlClan, right: CwlClan): number {
  for (let level = 20; level >= 1; level -= 1) {
    const difference =
      (right.townHallLevels[String(level)] ?? 0) - (left.townHallLevels[String(level)] ?? 0);
    if (difference) return difference;
  }
  return 0;
}
