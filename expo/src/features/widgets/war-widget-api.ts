import type { ApiClient } from '../../core/api/client';
import { WarCwlService } from '../war/data/war-cwl-service';
import type { CwlLeague, WarCwl, WarInfo } from '../war/models';

/** Resolves the current regular-war/CWL state and adapts it for the native widget payload. */
export async function fetchWarWidgetSummary(api: ApiClient, clanTag: string): Promise<unknown> {
  const tag = normalizeTag(clanTag);
  const service = new WarCwlService(api);
  await service.loadAllWarData([tag], { notify: false, throwOnError: true });
  const summary = service.getWarCwlByTag(tag);
  if (summary === null) throw new Error(`No war data returned for ${tag}.`);
  return widgetSummary(summary);
}

function normalizeTag(tag: string): string {
  return `#${tag.replaceAll('#', '').toUpperCase()}`;
}

function widgetSummary(summary: WarCwl) {
  return {
    clan_tag: summary.tag,
    isInWar: summary.isInWar,
    isInCwl: summary.isInCwl,
    war_info: {
      state: summary.warInfo.state,
      currentWarInfo: widgetWar(summary.warInfo),
    },
    league_info: summary.leagueInfo === null ? null : widgetLeague(summary.leagueInfo),
    war_league_infos: summary.warLeagueInfos.map(widgetWar),
  };
}

function widgetWar(war: WarInfo) {
  return {
    state: war.state,
    war_tag: war.tag,
    teamSize: war.teamSize,
    attacksPerMember: war.attacksPerMember,
    clan: widgetWarClan(war.clan),
    opponent: widgetWarClan(war.opponent),
    startTime: war.startTime?.toISOString() ?? null,
    endTime: war.endTime?.toISOString() ?? null,
    preparationStartTime: war.preparationStartTime?.toISOString() ?? null,
    warType: war.warType,
  };
}

function widgetWarClan(clan: WarInfo['clan']) {
  if (clan === null) return null;
  return {
    ...clan.toJson(),
    badgeUrls: {
      small: clan.badgeUrls.small,
      medium: clan.badgeUrls.medium,
      large: clan.badgeUrls.large,
    },
  };
}

function widgetLeague(league: CwlLeague) {
  return {
    state: league.state,
    season: league.season,
    clans: league.clans.map((clan) => ({
      ...clan.toJson(),
      rank: clan.rank,
      badgeUrls: {
        small: clan.badgeUrls.small,
        medium: clan.badgeUrls.medium,
        large: clan.badgeUrls.large,
      },
    })),
    rounds: league.rounds.map((round) => ({ warTags: round.warTags })),
  };
}
