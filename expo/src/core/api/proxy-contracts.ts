import * as Wire from '@clashking/clash-contract/effect';
import * as Api from '@clashking/api-contracts/expo';
import { Schema } from 'effect';

// Keep ClashKing routing/auth metadata; wire bodies come from the released Clash contract.
const errors = [400, 403, 404, 429].map((status) => ({ status, body: Wire.ClientErrorResponse }));

export const ProxyPlayerEndpoint = { ...Api.ProxyPlayerEndpoint, response: Wire.Player, errors };
export const ProxyPlayerBattlelogEndpoint = {
  ...Api.ProxyPlayerBattlelogEndpoint,
  response: Wire.BattleLogResponse,
  errors,
};
export const ProxyPlayerLeagueHistoryEndpoint = {
  ...Api.ProxyPlayerLeagueHistoryEndpoint,
  response: Wire.LeagueHistoryResponse,
  errors,
};
export const ProxyLeagueGroupEndpoint = {
  ...Api.ProxyLeagueGroupEndpoint,
  response: Wire.LeagueGroup,
  errors,
};
export const ProxyLeagueTiersEndpoint = {
  ...Api.ProxyLeagueTiersEndpoint,
  response: Wire.LeagueTierListResponse,
  errors,
};
export const ProxyClanEndpoint = { ...Api.ProxyClanEndpoint, response: Wire.Clan, errors };
export const ProxyClanSearchEndpoint = {
  ...Api.ProxyClanSearchEndpoint,
  response: Wire.ClanSearchResponse,
  errors,
};
export const ProxyCapitalRaidSeasonsEndpoint = {
  ...Api.ProxyCapitalRaidSeasonsEndpoint,
  response: Wire.CapitalRaidSeasonsResponse,
  errors,
};
export const ProxyClanWarlogEndpoint = {
  ...Api.ProxyClanWarlogEndpoint,
  response: Wire.ClanWarLogResponse,
  errors,
};
export const ProxyCurrentWarEndpoint = {
  ...Api.ProxyCurrentWarEndpoint,
  response: Wire.ClanWar,
  errors,
};
export const ProxyCurrentLeagueGroupEndpoint = {
  ...Api.ProxyCurrentLeagueGroupEndpoint,
  response: Wire.ClanWarLeagueGroup,
  errors,
};
export const ProxyCwlWarEndpoint = { ...Api.ProxyCwlWarEndpoint, response: Wire.ClanWar, errors };
export const ProxyLocationsEndpoint = {
  ...Api.ProxyLocationsEndpoint,
  response: Wire.LocationListResponse,
  errors,
};
export const ProxyPlayerRankingsEndpoint = {
  ...Api.ProxyPlayerRankingsEndpoint,
  response: Wire.PlayerRankingListResponse,
  errors,
};
export const ProxyBuilderPlayerRankingsEndpoint = {
  ...Api.ProxyBuilderPlayerRankingsEndpoint,
  response: Wire.PlayerBuilderBaseRankingListResponse,
  errors,
};
// Mirror the corrected canonical contract until the next contract package is
// released. Worldwide rankings include clans with no selected country; never
// discard all 200 entries or invent a country for those rows.
const ClanRankingWithOptionalLocation = Schema.Struct({
  ...Wire.ClanRanking.fields,
  location: Schema.optionalKey(Schema.Union([Wire.Location, Schema.Null])),
});
export const ProxyClanRankingsEndpoint = {
  ...Api.ProxyClanRankingsEndpoint,
  response: Schema.Struct({
    ...Wire.ClanRankingListResponse.fields,
    items: Schema.Array(ClanRankingWithOptionalLocation),
  }),
  errors,
};
export const ProxyBuilderClanRankingsEndpoint = {
  ...Api.ProxyBuilderClanRankingsEndpoint,
  // The wire contract permits absent locations on worldwide clan rankings.
  // Do not substitute a country or discard these clans when decoding the list.
  response: Wire.ClanBuilderBaseRankingListResponse,
  errors,
};
export const ProxyCapitalRankingsEndpoint = {
  ...Api.ProxyCapitalRankingsEndpoint,
  response: Wire.ClanCapitalRankingListResponse,
  errors,
};
