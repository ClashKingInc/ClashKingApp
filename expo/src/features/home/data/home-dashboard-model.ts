import { ImageAssets } from '../../../core/assets/image-assets';
import { formatCompactNumber, type I18nValue } from '../../../i18n';
import type { Player } from '../../player/models';
import type { RankedLeagueData } from '../../player/models/player-ranked';
import type { WarCwlService } from '../../war/data';
import {
  UpgradeCategory,
  UpgradePlanStrategy,
  UpgradeQueue,
  UpgradeVillage,
  type UpgradeQueueValue,
  type UpgradeTrackerItem,
  type UpgradeTrackerSnapshot,
} from '../../upgrade-tracker/models';
import type {
  HomeAccountIdentity,
  HomeMetricKind,
  HomeMetricModel,
  HomeRankedAccount,
  HomeRankedCardModel,
  HomeTodoCardModel,
  HomeTodoSummary,
  HomeUpgradeAccount,
  HomeUpgradeCardModel,
  HomeUpgradeCombined,
} from '../presentation';

type Translate = I18nValue['t'];
interface BuiltTodoSummary extends HomeTodoSummary {
  readonly progressMetrics: readonly {
    kind: HomeMetricKind;
    done: number;
    total: number;
  }[];
}

export function homeAccountIdentity(player: Player): HomeAccountIdentity {
  return {
    tag: player.tag,
    name: player.name,
    subtitle: player.clanOverview.name || player.tag,
    imageUrl: player.townHallPic,
  };
}

export function buildHomeTodoModel(
  players: readonly Player[],
  wars: Pick<WarCwlService, 'getWarCwlByTag'>,
  t: Translate,
  locale: string,
  now = new Date(),
): HomeTodoCardModel {
  const accounts = players.map((player) => todoSummary(player, wars, t, locale, now));
  return {
    accounts,
    ...(accounts.length > 1 ? { combined: combinedTodoSummary(accounts, t, locale) } : {}),
  };
}

export function buildHomeRankedModel(
  players: readonly Player[],
  loaded: ReadonlyMap<string, RankedLeagueData>,
  loading = false,
): HomeRankedCardModel {
  if (loading) return { state: 'loading', configuredCount: players.length };
  const accounts = players.flatMap((player) => {
    const data = loaded.get(normalizeTag(player.tag));
    if (!data || (data.currentTier === null && data.history.length === 0)) return [];
    const member = data.currentMember;
    const tier = data.currentTier;
    return [
      {
        ...homeAccountIdentity(player),
        name: data.playerName,
        tierIconUrl: tier?.smallIconUrl || tier?.largeIconUrl || '',
        trophies: member?.leagueTrophies ?? data.trophies,
        rank: data.currentRank,
        attacksDone: member ? member.attackWinCount + member.attackLoseCount : 0,
        defensesDone: member ? member.defenseWinCount + member.defenseLoseCount : 0,
        maxBattles: data.currentMaxBattles,
      } satisfies HomeRankedAccount,
    ];
  });
  return accounts.length
    ? { state: 'ready', configuredCount: players.length, accounts }
    : { state: 'empty', configuredCount: players.length };
}

export function buildHomeUpgradeModel(
  players: readonly Player[],
  loaded: ReadonlyMap<string, UpgradeTrackerSnapshot | null>,
  t: Translate,
  options: { loading?: boolean; now?: Date } = {},
): HomeUpgradeCardModel {
  if (options.loading) return { state: 'loading', configuredCount: players.length };
  const now = options.now ?? new Date();
  const accounts: HomeUpgradeAccount[] = [];
  const missingAccounts: HomeAccountIdentity[] = [];
  for (const player of players) {
    const snapshot = loaded.get(normalizeTag(player.tag));
    if (!snapshot) missingAccounts.push(homeAccountIdentity(player));
    else accounts.push(upgradeAccount(snapshot, now));
  }
  if (!accounts.length && !missingAccounts.length) {
    return { state: 'empty', configuredCount: players.length };
  }
  return {
    state: 'ready',
    configuredCount: players.length,
    accounts,
    missingAccounts: missingAccounts.map((account) => ({
      ...account,
      townHallLevel: players.find((player) => player.tag === account.tag)?.townHallLevel ?? 0,
    })),
    combined: combinedUpgrade(accounts, missingAccounts, t),
  };
}

function todoSummary(
  player: Player,
  wars: Pick<WarCwlService, 'getWarCwlByTag'>,
  t: Translate,
  locale: string,
  now: Date,
): BuiltTodoSummary {
  const presence = wars
    .getWarCwlByTag(player.clanTag)
    ?.getMemberPresence(player.tag, player.clanTag);
  const source = player.getTodoProgressMetrics(
    presence ?? { attacksAvailable: 0, attacksDone: 0 },
    now,
  );
  const metrics = source.flatMap((metric, index) => {
    const kind = todoMetricKind(metric.label);
    if (!kind) return [];
    const left = Math.max(metric.total - metric.done, 0);
    const points = metric.label === 'season_pass' || metric.label === 'clan_games';
    return [
      {
        id: `${metric.label}-${index}`,
        kind,
        done: metric.done,
        total: metric.total,
        detail:
          left === 0
            ? t('todoCompleteLower')
            : points
              ? t('todoPointsLeftShort', { points: compact(left, locale) })
              : t('todoItemsLeftShort', { count: left }),
      } satisfies HomeMetricModel,
    ];
  });
  const progress = averagedProgress(
    source.map((metric) => ({ done: metric.progressDone, total: metric.progressTotal })),
  );
  return {
    account: homeAccountIdentity(player),
    status: lastActiveStatus(player, t, now),
    metrics,
    progressMetrics: source.flatMap((metric) => {
      const kind = todoMetricKind(metric.label);
      return kind ? [{ kind, done: metric.progressDone, total: metric.progressTotal }] : [];
    }),
    ...progress,
  };
}

function combinedTodoSummary(
  accounts: readonly BuiltTodoSummary[],
  t: Translate,
  locale: string,
): HomeTodoSummary {
  const order: HomeMetricKind[] = [];
  const merged = new Map<
    HomeMetricKind,
    { done: number; total: number; progressDone: number; progressTotal: number }
  >();
  for (const account of accounts) {
    for (const metric of account.metrics) {
      if (!order.includes(metric.kind)) order.push(metric.kind);
      const current = merged.get(metric.kind) ?? {
        done: 0,
        total: 0,
        progressDone: 0,
        progressTotal: 0,
      };
      current.done += Math.max(0, Math.min(metric.done, metric.total ?? metric.done));
      current.total += metric.total ?? 0;
      const progress = account.progressMetrics.find((entry) => entry.kind === metric.kind);
      current.progressDone += Math.max(
        0,
        Math.min(progress?.done ?? metric.done, progress?.total ?? metric.total ?? 0),
      );
      current.progressTotal += progress?.total ?? metric.total ?? 0;
      merged.set(metric.kind, current);
    }
  }
  const metrics = order.map((kind) => {
    const metric = merged.get(kind)!;
    const left = Math.max(metric.total - metric.done, 0);
    return {
      id: kind,
      kind,
      done: metric.done,
      total: metric.total,
      detail:
        left === 0
          ? t('todoCompleteLower')
          : metric.total > 50
            ? t('todoPointsLeftShort', { points: compact(left, locale) })
            : t('todoItemsLeftShort', { count: left }),
    } satisfies HomeMetricModel;
  });
  const progress = averagedProgress(
    order.map((kind) => {
      const metric = merged.get(kind)!;
      return { done: metric.progressDone, total: metric.progressTotal };
    }),
  );
  const incomplete = accounts.filter((account) => account.done < account.total);
  const names = incomplete
    .slice(0, 3)
    .map((account) => account.account?.name.trim() ?? '')
    .filter(Boolean);
  const subject = names.length
    ? `${names.join(', ')}${incomplete.length > names.length ? `, +${incomplete.length - names.length}` : ''}`
    : t('todoAccountsNumber', { number: incomplete.length });
  return {
    status:
      incomplete.length === 0
        ? t('todoCombinedAcrossAccounts')
        : t('todoAccountsHaveTasksLeft', { subject, count: incomplete.length }),
    metrics,
    ...progress,
  };
}

function upgradeAccount(snapshot: UpgradeTrackerSnapshot, now: Date): HomeUpgradeAccount {
  const projected = (queue: UpgradeQueueValue) => {
    let latest = now;
    for (const lane of snapshot.buildPlan({
      queue,
      strategy: UpgradePlanStrategy.balanced,
      village: UpgradeVillage.home,
      startsAt: now,
    })) {
      if (lane.finishesAt && lane.finishesAt > latest) latest = lane.finishesAt;
    }
    return Math.max(0, Math.min(0x7fffffff, Math.floor((latest.getTime() - now.getTime()) / 1000)));
  };
  const builderProjectedSeconds = projected(UpgradeQueue.builders);
  const labProjectedSeconds = projected(UpgradeQueue.laboratory);
  const petProjectedSeconds = projected(UpgradeQueue.pets);
  const builderItems = snapshot.itemsFor({
    village: UpgradeVillage.home,
    queue: UpgradeQueue.builders,
  });
  const labItems = snapshot.itemsFor({
    village: UpgradeVillage.home,
    queue: UpgradeQueue.laboratory,
  });
  const petItems = snapshot.itemsFor({
    village: UpgradeVillage.home,
    queue: UpgradeQueue.pets,
  });
  const active = (item: UpgradeTrackerItem) => snapshot.remainingActiveSeconds(item, now) > 0;
  const activeBuilders = builderItems.filter(active).length;
  const labActive = labItems.some(active);
  const petsActive = petItems.some(active);
  const idleWork = (items: readonly UpgradeTrackerItem[]) =>
    items.some((item) => !item.recurrentHelper && !item.isComplete && !active(item));
  const totalBuilders = snapshot.buildersFor(UpgradeVillage.home);
  const walls = snapshot.itemsFor({
    village: UpgradeVillage.home,
    category: UpgradeCategory.walls,
  });
  const tracked = snapshot.itemsFor({ village: UpgradeVillage.home });
  const started = tracked.filter((item) => !item.recurrentHelper && (item.activeSeconds ?? 0) > 0);
  return {
    tag: snapshot.tag,
    name: snapshot.name,
    subtitle: snapshot.tag,
    imageUrl: ImageAssets.townHall(snapshot.townHallLevel),
    completion: Math.max(0, Math.min(1, snapshot.overallSummary(UpgradeVillage.home).completion)),
    capturedAt: snapshot.capturedAt,
    needsUpdate: started.length > 0 && started.every((item) => !active(item)),
    hasActionableQueueWork:
      (activeBuilders < totalBuilders && idleWork(builderItems)) ||
      (!labActive && idleWork(labItems)) ||
      (!petsActive && idleWork(petItems)),
    builderProjectedSeconds,
    labProjectedSeconds,
    petProjectedSeconds,
    activeBuilders,
    totalBuilders,
    labActive,
    hasLab: labItems.length > 0,
    petsActive,
    hasPets: petItems.length > 0,
    wallsAtMax: walls
      .filter((item) => item.currentLevel >= item.targetLevel)
      .reduce((sum, item) => sum + item.count, 0),
    wallsTotal: walls.reduce((sum, item) => sum + item.count, 0),
  };
}

function combinedUpgrade(
  accounts: readonly HomeUpgradeAccount[],
  missing: readonly HomeAccountIdentity[],
  t: Translate,
): HomeUpgradeCombined {
  const count = accounts.length + missing.length;
  const staleNames = [
    ...missing.map((account) => account.name),
    ...accounts.filter((account) => account.needsUpdate).map((account) => account.name),
  ]
    .map((name) => name.trim())
    .filter(Boolean);
  const visible = staleNames.slice(0, 3);
  const subject = `${visible.join(', ')}${staleNames.length > visible.length ? `, +${staleNames.length - visible.length}` : ''}`;
  return {
    completion:
      count === 0 ? 0 : accounts.reduce((sum, account) => sum + account.completion, 0) / count,
    status:
      staleNames.length === 0
        ? t('dashboardUpgradeTrackerCombinedAcrossAccounts')
        : t('dashboardUpgradeTrackerNeedsUpdate', { subject, count: staleNames.length }),
    builderProjectedSeconds: maxOf(accounts, (account) => account.builderProjectedSeconds),
    labProjectedSeconds: maxOf(accounts, (account) => account.labProjectedSeconds),
    petProjectedSeconds: maxOf(accounts, (account) => account.petProjectedSeconds),
    activeBuilders: sumOf(accounts, (account) => account.activeBuilders),
    totalBuilders: sumOf(accounts, (account) => account.totalBuilders),
    activeLabs: accounts.filter((account) => account.labActive).length,
    totalLabs: accounts.filter((account) => account.hasLab).length,
    activePets: accounts.filter((account) => account.petsActive).length,
    totalPets: accounts.filter((account) => account.hasPets).length,
  };
}

function averagedProgress(metrics: readonly { done: number; total: number }[]) {
  if (!metrics.length) return { done: 0, total: 0 };
  const done = metrics.reduce(
    (sum, metric) => sum + Math.max(0, Math.min(metric.done, metric.total)),
    0,
  );
  const total = metrics.reduce((sum, metric) => sum + metric.total, 0);
  return { done: Math.round(done * 100), total: Math.round(total * 100) };
}

function lastActiveStatus(player: Player, t: Translate, now: Date): string {
  if (player.lastOnline.getTime() === 0) return t('todoLastActiveUnavailable');
  const elapsed = now.getTime() - player.lastOnline.getTime();
  let relative: string;
  if (elapsed < 0) relative = t('todoLastActiveUnavailable');
  else if (elapsed < 60_000) relative = t('timeJustNow');
  else if (elapsed < 3_600_000) {
    const minutes = Math.floor(elapsed / 60_000);
    relative = minutes === 1 ? t('timeMinuteAgo', { minute: 1 }) : t('timeMinutesAgo', { minutes });
  } else if (elapsed < 86_400_000) {
    const hours = Math.floor(elapsed / 3_600_000);
    relative = hours === 1 ? t('timeHourAgo', { hour: 1 }) : t('timeHoursAgo', { hours });
  } else {
    const days = Math.floor(elapsed / 86_400_000);
    relative = days === 1 ? t('timeDayAgo', { day: 1 }) : t('timeDaysAgo', { days });
  }
  return t('todoActiveRelative', { time: relative });
}

function todoMetricKind(label: string): HomeMetricKind | null {
  const kinds: Readonly<Record<string, HomeMetricKind>> = {
    legend_attacks: 'legendAttacks',
    war_attacks: 'warAttacks',
    cwl_attacks: 'cwlAttacks',
    raid_attacks: 'raidAttacks',
    clan_games: 'clanGames',
    season_pass: 'seasonPass',
  };
  return kinds[label] ?? null;
}

function compact(value: number, locale: string): string {
  return formatCompactNumber(value, locale);
}

function normalizeTag(tag: string): string {
  const normalized = tag.trim().toUpperCase();
  return normalized.startsWith('#') ? normalized : `#${normalized}`;
}

function maxOf<T>(values: readonly T[], select: (value: T) => number): number {
  return values.reduce((maximum, value) => Math.max(maximum, select(value)), 0);
}

function sumOf<T>(values: readonly T[], select: (value: T) => number): number {
  return values.reduce((sum, value) => sum + select(value), 0);
}
