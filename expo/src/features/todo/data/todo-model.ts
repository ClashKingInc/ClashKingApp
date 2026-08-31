import { canonicalTag } from '../../../core/domain/tags';
import {
  isInClanGamesWindow,
  requiredClanGamesPoints,
  requiredSeasonPassPoints,
  type Player,
  type TodoProgressMetric,
  type WarMemberPresenceLike,
} from '../../player/models';

export type TodoAccountFilter = 'all' | 'mine' | 'needs_action' | 'done' | 'bookmarked';

export interface TodoFilterCounts {
  readonly all: number;
  readonly mine: number;
  readonly needsAction: number;
  readonly done: number;
  readonly bookmarked: number;
}

export interface TodoHeaderSummary {
  readonly totalAccounts: number;
  readonly openTasks: number;
  readonly completedTasks: number;
  readonly progressRatio: number;
  readonly metrics: ReadonlyMap<string, { readonly done: number; readonly total: number }>;
}

export interface TodoScreenModel {
  readonly searchedPlayers: readonly Player[];
  readonly visiblePlayers: readonly Player[];
  readonly filterCounts: TodoFilterCounts;
  readonly header: TodoHeaderSummary;
}

export interface BuildTodoScreenModelInput {
  readonly players: readonly Player[];
  readonly linkedTags: ReadonlySet<string>;
  readonly bookmarkedTags: ReadonlySet<string>;
  readonly isShown: (tag: string) => boolean;
  readonly presenceFor: (player: Player) => WarMemberPresenceLike;
  readonly query: string;
  readonly filter: TodoAccountFilter;
  readonly now?: Date;
}

export function buildTodoScreenModel(input: BuildTodoScreenModelInput): TodoScreenModel {
  const linkedTags = normalizedSet(input.linkedTags);
  const bookmarkedTags = normalizedSet(input.bookmarkedTags);
  const configured = input.players.filter((player) => {
    const tag = canonicalTag(player.tag);
    return (linkedTags.has(tag) || bookmarkedTags.has(tag)) && input.isShown(player.tag);
  });
  const query = input.query.trim().toLocaleLowerCase();
  const searchedPlayers = configured.filter((player) => matchesSearch(player, query));
  const state = searchedPlayers.map((player) => ({
    player,
    presence: input.presenceFor(player),
    linked: linkedTags.has(canonicalTag(player.tag)),
    bookmarked: bookmarkedTags.has(canonicalTag(player.tag)),
  }));
  const filterCounts: TodoFilterCounts = {
    all: state.length,
    mine: state.filter((entry) => entry.linked).length,
    needsAction: state.filter((entry) => entry.player.getTodoProgressRatio(entry.presence) < 1)
      .length,
    done: state.filter((entry) => entry.player.getTodoProgressRatio(entry.presence) >= 1).length,
    bookmarked: state.filter((entry) => entry.bookmarked).length,
  };
  const visiblePlayers = state
    .filter((entry) => {
      if (input.filter === 'all') return true;
      if (input.filter === 'mine') return entry.linked;
      if (input.filter === 'bookmarked') return entry.bookmarked;
      const needsAction = entry.player.getTodoProgressRatio(entry.presence) < 1;
      return input.filter === 'needs_action' ? needsAction : !needsAction;
    })
    .map((entry) => entry.player)
    .sort((left, right) => right.lastOnline.getTime() - left.lastOnline.getTime());
  return {
    searchedPlayers,
    visiblePlayers,
    filterCounts,
    header: buildTodoHeaderSummary(searchedPlayers, input.presenceFor, input.now ?? new Date()),
  };
}

export function buildTodoHeaderSummary(
  players: readonly Player[],
  presenceFor: (player: Player) => WarMemberPresenceLike,
  now = new Date(),
): TodoHeaderSummary {
  const totals = new Map<
    string,
    { done: number; total: number; progressDone: number; progressTotal: number }
  >();
  const displayMetrics = new Map<string, { done: number; total: number }>();
  let openTasks = 0;
  let completedTasks = 0;
  for (const player of players) {
    for (const metric of player.getTodoProgressMetrics(presenceFor(player), now)) {
      mergeMetric(totals, metric);
    }
    countHeaderTasks(player, presenceFor(player), displayMetrics, now, (complete) => {
      if (complete) completedTasks += 1;
      else openTasks += 1;
    });
  }
  const progressDone = [...totals.values()].reduce(
    (sum, metric) => sum + Math.max(0, Math.min(metric.progressDone, metric.progressTotal)),
    0,
  );
  const progressTotal = [...totals.values()].reduce((sum, metric) => sum + metric.progressTotal, 0);
  return {
    totalAccounts: players.length,
    openTasks,
    completedTasks,
    progressRatio:
      totals.size === 0 || progressTotal === 0
        ? 1
        : Math.max(0, Math.min(1, progressDone / progressTotal)),
    metrics: displayMetrics,
  };
}

interface HeaderWarLike {
  readonly state: string;
  readonly attacksPerMember?: number | null;
  isPlayerInWar(playerTag: string, clanTag: string): boolean;
  getAttacksDoneByPlayer(playerTag: string, clanTag: string): number;
}

interface HeaderClanLike {
  readonly warCwl?: {
    readonly isInCwl?: boolean;
    readonly warInfo?: HeaderWarLike | null;
  } | null;
}

function countHeaderTasks(
  player: Player,
  presence: WarMemberPresenceLike,
  metrics: Map<string, { done: number; total: number }>,
  now: Date,
  count: (complete: boolean) => void,
) {
  addDisplayMetric(
    metrics,
    'season_pass',
    player.currentSeasonPoints,
    requiredSeasonPassPoints(now),
  );
  count(player.seasonPassRatio >= 1);

  const legendDone = player.currentLegendSeason?.currentDay?.totalAttacks;
  if (player.league === 'Legend League' && legendDone !== undefined) {
    addDisplayMetric(metrics, 'legend_attacks', legendDone, 8);
    count(legendDone >= 8);
  }

  const clan = player.clan as HeaderClanLike | null;
  const currentWar = clan?.warCwl?.warInfo ?? (player.warData as HeaderWarLike | null);
  const isInCwl = clan?.warCwl?.isInCwl === true;
  if (currentWar?.state === 'inWar' && currentWar.isPlayerInWar(player.tag, player.clanTag)) {
    const total = currentWar.attacksPerMember ?? (isInCwl ? 1 : 2);
    const done = currentWar.getAttacksDoneByPlayer(player.tag, player.clanTag);
    if (total > 0) {
      addDisplayMetric(metrics, isInCwl ? 'cwl_attacks' : 'war_attacks', done, total);
      count(done >= total);
    }
  } else if (isInCwl && presence.attacksAvailable > 0) {
    addDisplayMetric(metrics, 'cwl_attacks', presence.attacksDone, presence.attacksAvailable);
    count(presence.attacksDone >= presence.attacksAvailable);
  }

  if (isInClanGamesWindow(now)) {
    const required = requiredClanGamesPoints(now);
    const total = required > 0 ? required : 4000;
    addDisplayMetric(metrics, 'clan_games', player.currentClanGamesPoints, total);
    count(player.clanGamesRatio >= 1);
  }
}

function addDisplayMetric(
  metrics: Map<string, { done: number; total: number }>,
  label: string,
  done: number,
  total: number,
) {
  const current = metrics.get(label) ?? { done: 0, total: 0 };
  metrics.set(label, { done: current.done + done, total: current.total + total });
}

function mergeMetric(
  totals: Map<string, { done: number; total: number; progressDone: number; progressTotal: number }>,
  metric: TodoProgressMetric,
) {
  const current = totals.get(metric.label) ?? {
    done: 0,
    total: 0,
    progressDone: 0,
    progressTotal: 0,
  };
  current.done += Math.max(0, Math.min(metric.done, metric.total));
  current.total += metric.total;
  current.progressDone += Math.max(0, Math.min(metric.progressDone, metric.progressTotal));
  current.progressTotal += metric.progressTotal;
  totals.set(metric.label, current);
}

function normalizedSet(tags: ReadonlySet<string>): ReadonlySet<string> {
  return new Set([...tags].map(canonicalTag));
}

function matchesSearch(player: Player, query: string): boolean {
  if (!query) return true;
  const clan = player.clan;
  const clanName =
    typeof clan === 'object' && clan !== null && 'name' in clan && typeof clan.name === 'string'
      ? clan.name
      : player.clanOverview.name;
  return [player.name, player.tag, player.tag.replaceAll('#', ''), clanName]
    .join(' ')
    .toLocaleLowerCase()
    .includes(query);
}
