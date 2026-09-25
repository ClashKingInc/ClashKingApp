import {
  expoEndpoints,
  LegendBattlelogEndpoint,
  LegendRanksEndpoint,
} from '@clashking/api-contracts/expo';
import { Effect } from 'effect';
import type { ContractApiService } from '../../core/api/contract-api';
import { canonicalTag } from '../../core/domain/tags';
import {
  PlayerLegendBattlelog,
  PlayerLegendLeagueData,
  PlayerLegendRank,
} from '../player/models/player-legend';

/** A widget needs three public reads, not the authenticated player-detail fan-out. */
export async function fetchLegendsWidgetData(api: ContractApiService, rawTag: string, day: string) {
  const tag = canonicalTag(rawTag);
  const [battlelog, ranks, season] = await Promise.all([
    Effect.runPromise(
      api.execute(LegendBattlelogEndpoint, {
        path: { playerTag: tag, day },
        query: {},
        body: {},
      }),
    ),
    Effect.runPromise(
      api.execute(LegendRanksEndpoint, {
        path: {},
        query: {},
        body: { tags: [tag] },
      }),
    ).catch(() => null),
    Effect.runPromise(
      api.execute(expoEndpoints.legendPlayerSeason, {
        path: { playerTag: tag },
        query: {},
        body: {},
      }),
    ).catch(() => null),
  ]);
  if (canonicalTag(battlelog.tag) !== tag || battlelog.day !== day) {
    throw new TypeError('Widget battlelog does not match the selected player and Legend day.');
  }
  const currentDay = PlayerLegendBattlelog.fromJson(battlelog);
  const rank = ranks?.items.find((item) => canonicalTag(item.tag) === tag);
  const currentRank = rank ? PlayerLegendRank.fromJson(rank) : null;
  return new PlayerLegendLeagueData(
    tag,
    currentRank?.name ?? tag,
    0,
    currentRank?.trophies ?? 0,
    0,
    currentDay,
    [],
    day,
    currentRank,
    null,
    [],
    [],
    season?.seasonStart ?? null,
    season?.seasonEnd ?? null,
  );
}
