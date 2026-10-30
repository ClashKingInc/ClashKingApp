import {
  PlayerActivityFeed,
  PlayerBattlelogData,
  PlayerBattlelogEntry,
  PlayerCwlHistory,
  PlayerCwlSeason,
  PlayerJoinLeavePage,
  PlayerLegendHistoryEntry,
  PlayerWarStats,
  PlayerWarTypeStats,
} from '../models';
import { JoinLeaveClan, JoinLeaveEvent } from '../models/player-history';
import type { PlayerDetailPresentationModel, PlayerDetailTabKey } from './player-detail-contracts';

/** These values only size the real page inside SkeletonContent, never a cache. */
export function playerLoadingModel(
  model: PlayerDetailPresentationModel,
  tab: PlayerDetailTabKey,
): PlayerDetailPresentationModel {
  if (!model.loadingTabs?.has(tab) || playerTabHasContent(model, tab)) return model;
  const date = new Date(0);
  const type = new PlayerWarTypeStats(10, 10, 10, 0, 0, { '3': 10 }, { '3': 10 }, {}, {});
  return {
    ...model,
    battlelog:
      model.battlelog ??
      new PlayerBattlelogData(
        [0, 1, 2].map(
          (index) =>
            new PlayerBattlelogEntry(
              String(index),
              'farming',
              'history',
              true,
              '',
              'Opponent name',
              model.player.townHallLevel,
              3,
              100,
              100000,
              100000,
              1000,
              date,
              180,
              '',
              {},
            ),
        ),
        true,
        true,
      ),
    activity:
      model.activity ??
      new PlayerActivityFeed(
        [0, 1, 2].map(() => ({
          time: date,
          kind: 'troopUpgrade',
          itemType: 'troop',
          name: 'Barbarian',
          itemId: null,
          townHallLevel: model.player.townHallLevel,
          previousLevel: 1,
          currentLevel: 2,
          previousValue: null,
          currentValue: null,
        })),
      ),
    cwlHistory:
      model.cwlHistory ??
      new PlayerCwlHistory(
        ['2026-01', '2025-12', '2025-11'].map((season) =>
          PlayerCwlSeason.fromJson({
            season,
            townHallLevel: model.player.townHallLevel,
            teamSize: 15,
            clan: {
              name: 'Clan name',
              warLeague: { name: 'Champion League I' },
              wars: { won: 5, lost: 2 },
            },
            placement: { clan: 1, group: 1 },
            attacks: [],
            missedAttacks: 0,
          }),
        ),
      ),
    warStats:
      model.warStats ??
      new PlayerWarStats(
        model.player.name,
        model.player.tag,
        model.player.townHallLevel,
        {},
        { all: type, random: type, cwl: type, friendly: type },
        [],
      ),
    joinLeave:
      model.joinLeave ??
      new PlayerJoinLeavePage(
        3,
        [0, 1, 2].map(
          () =>
            new JoinLeaveEvent(
              'join',
              new JoinLeaveClan('Clan name', '', ''),
              date,
              model.player.tag,
              model.player.name,
              model.player.townHallLevel,
            ),
        ),
      ),
    legendHistory:
      model.legendHistory ??
      ['2026-01', '2025-12', '2025-11'].map(
        (season) => new PlayerLegendHistoryEntry(season, null, null, 5000, 100, 100, 100),
      ),
  };
}

export function playerTabHasContent(
  model: PlayerDetailPresentationModel,
  tab: PlayerDetailTabKey,
): boolean {
  if (tab === 'battles') return model.battlelog != null;
  if (tab === 'history') return model.activity != null;
  if (tab === 'cwl') return model.cwlHistory != null;
  if (tab === 'legendHistory') return model.legendHistory != null;
  if (tab === 'war') return model.warStats != null;
  if (tab === 'joinLeave') return model.joinLeave != null;
  return true;
}
