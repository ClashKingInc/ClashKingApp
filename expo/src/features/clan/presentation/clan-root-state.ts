import type { BookmarkedClan } from '../../../core/bookmarks';
import { canonicalTag } from '../../../core/domain/tags';
import type { CocAccountLink } from '../../auth/models';
import type { Player } from '../../player/models/player';
import type { WarCwl } from '../../war/models';
import type { ClanService } from '../data';
import { Clan, ClanJoinLeave, ClanWarLog, ClanWarStats, type ClanWarStatsFilter } from '../models';
import type { ClanInfoPresentationModel } from './clan-info-contracts';
import type { ClansPresentationModel } from './contracts';

export function buildClansPresentationModel(input: {
  readonly profiles: readonly Player[];
  readonly bookmarks: readonly BookmarkedClan[];
  readonly clans: ReadonlyMap<string, Clan>;
  readonly lastRefresh: Date | null;
}): ClansPresentationModel {
  return {
    profiles: input.profiles,
    bookmarks: input.bookmarks,
    hydratedClans: [...input.clans.values()],
    ...(input.lastRefresh ? { lastRefresh: input.lastRefresh } : {}),
  };
}

export function buildClanInfoPresentationModel(input: {
  readonly clan: Clan;
  readonly bookmarked: boolean;
  readonly accounts: readonly CocAccountLink[];
  readonly war: WarCwl | null;
}): ClanInfoPresentationModel {
  const hasCwlLeagueData = (input.war?.leagueInfo?.clans.length ?? 0) > 0;
  const ongoingWar =
    input.war && (input.war.isInCwl || hasCwlLeagueData)
      ? ('cwl' as const)
      : input.war?.isInWar
        ? ('war' as const)
        : undefined;
  return {
    clan: input.clan,
    bookmarked: input.bookmarked,
    activeUserTags: new Set(input.accounts.map((account) => canonicalTag(account.playerTag))),
    ...(ongoingWar ? { ongoingWar } : {}),
    hasCwlLeagueData,
  };
}

/** Forces all clan-detail local state and in-flight request guards to reset for a new clan. */
export function clanInfoStateKey(tag: string): string {
  return canonicalTag(tag);
}

export async function loadClanJoinLeave(service: ClanService, clan: Clan): Promise<ClanJoinLeave> {
  await service.loadJoinLeaveForClan(clan);
  return clan.joinLeave ?? ClanJoinLeave.empty();
}

export async function loadMoreClanJoinLeave(
  service: ClanService,
  clan: Clan,
  current: ClanJoinLeave,
): Promise<ClanJoinLeave> {
  if (clan.joinLeave === null) clan.joinLeave = current;
  await service.loadMoreJoinLeaveForClan(clan);
  return clan.joinLeave ?? current;
}

export async function loadClanWarLog(service: ClanService, clan: Clan): Promise<ClanWarLog | null> {
  const logs = await service.loadWarLogData([clan.tag], {
    throwOnError: false,
  });
  const log = logs.find((item) => item.clanTag === clan.tag) ?? null;
  clan.clanWarLog = log;
  return log;
}

export async function loadClanWarStats(
  service: ClanService,
  clan: Clan,
  filter: ClanWarStatsFilter,
): Promise<ClanWarStats> {
  if (isInitialWarStatsFilter(filter)) {
    const stats = await service.loadClanWarStatsData([clan.tag]);
    const value = stats.find((item) => item.clanTag === clan.tag) ?? ClanWarStats.empty();
    clan.clanWarStats = value;
    return value;
  }
  return (await service.loadClanWarStatsWithFilter(clan.tag, filter)) ?? ClanWarStats.empty();
}

export function clanGameUrl(clanTag: string, locale: string): string {
  const language = locale.split(/[-_]/)[0] || 'en';
  const query = new URLSearchParams({ action: 'OpenClanProfile', tag: clanTag });
  return `https://link.clashofclans.com/${language}?${query.toString()}`;
}

function isInitialWarStatsFilter(filter: ClanWarStatsFilter): boolean {
  const values = filter.toJson();
  return Object.keys(values).length === 2 && values.limit === 50 && values.same_th === false;
}
