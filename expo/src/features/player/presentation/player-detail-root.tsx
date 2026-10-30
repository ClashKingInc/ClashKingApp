import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { View } from 'react-native';

import type {
  PlayerActivityFeed,
  PlayerBattlelogData,
  PlayerCwlHistory,
  PlayerLegendHistoryEntry,
  PlayerJoinLeavePage,
  PlayerJoinLeaveTotal,
  PlayerHistoryTypeValue,
  PlayerWarStats,
  WarStatsFilter,
} from '../models';
import { WarStatsFilter as WarStatsFilterModel } from '../models';
import { canonicalTag } from '../../../core/domain/tags';
import { ClashHandoffDialog } from '../../../ui';
import { useClashGameHandoff } from '../../../ui/use-clash-game-handoff';
import type {
  PlayerDetailPresentationActions,
  PlayerDetailRootProps,
  PlayerDetailTabKey,
} from './player-detail-contracts';
import { PlayerDetailScreen } from './player-detail-screen';
import { exportPlayerWarStats } from './player-war-export';
import { warHistoryRangeFilter } from '../../war/models/war-history-range';
import { mergeJoinLeavePages } from './player-join-leave-state';

export function PlayerDetailRoot(props: PlayerDetailRootProps) {
  return <PlayerDetailRootState key={canonicalTag(props.player.tag)} {...props} />;
}

function PlayerDetailRootState({
  loading = false,
  player,
  service,
  actions: externalActions,
  bookmarked = false,
  linkedAccount = false,
  verifiedTracking = false,
  currentWar = null,
  currentCwl = null,
  initialTab,
}: PlayerDetailRootProps) {
  const [battlelog, setBattlelog] = useState<PlayerBattlelogData | null>(null);
  const [legendHistory, setLegendHistory] = useState<readonly PlayerLegendHistoryEntry[] | null>(
    null,
  );
  const [activity, setActivity] = useState<PlayerActivityFeed | null>(null);
  const [cwlHistory, setCwlHistory] = useState<PlayerCwlHistory | null>(null);
  const [warStats, setWarStats] = useState<PlayerWarStats | null>(player.warStats);
  const [isBookmarked, setIsBookmarked] = useState(bookmarked);
  const [cachedClanTag, setCachedClanTag] = useState<string | null>(null);
  const handoff = useClashGameHandoff(externalActions.openInGame);
  const [joinLeave, setJoinLeave] = useState<PlayerJoinLeavePage | null>(null);
  const [joinLeaveTotals, setJoinLeaveTotals] = useState<readonly PlayerJoinLeaveTotal[] | null>(
    null,
  );
  const [loadingTabs, setLoadingTabs] = useState<ReadonlySet<PlayerDetailTabKey>>(new Set());
  const [errorByTab, setErrorByTab] = useState<Partial<Record<PlayerDetailTabKey, string>>>({});
  const [, setLoadedTabs] = useState<ReadonlySet<PlayerDetailTabKey>>(
    new Set(['home', 'builder', 'achievements']),
  );
  const loadedTabsRef = useRef<ReadonlySet<PlayerDetailTabKey>>(
    new Set(['home', 'builder', 'achievements']),
  );
  const loadingTabsRef = useRef<ReadonlySet<PlayerDetailTabKey>>(new Set());
  const warFilterRef = useRef(new WarStatsFilterModel(warHistoryRangeFilter('days:90')));
  const warRequestId = useRef(0);
  const activityTypeRef = useRef<PlayerHistoryTypeValue>('troop_level');

  const loadTab = useCallback(
    async (tab: PlayerDetailTabKey, force = false) => {
      if (loading) return;
      if (!force && loadedTabsRef.current.has(tab)) return;
      if (!force && loadingTabsRef.current.has(tab)) return;
      const warGeneration = tab === 'war' ? ++warRequestId.current : null;
      loadingTabsRef.current = new Set(loadingTabsRef.current).add(tab);
      setLoadingTabs((current) => new Set(current).add(tab));
      setErrorByTab((current) => ({ ...current, [tab]: undefined }));
      try {
        if (tab === 'battles') setBattlelog(await service.loadPlayerBattlelog(player.tag, force));
        else if (tab === 'history')
          setActivity(await service.loadPlayerActivity(player.tag, activityTypeRef.current, force));
        else if (tab === 'legendHistory')
          setLegendHistory(await service.loadPlayerLegendHistory(player.tag));
        else if (tab === 'cwl')
          setCwlHistory(await service.loadPlayerCwlHistory(player.tag, force));
        else if (tab === 'war') {
          const result = await service.loadPlayerWarStatsWithFilter(
            player.tag,
            warFilterRef.current,
          );
          if (warGeneration === warRequestId.current) setWarStats(result);
        } else if (tab === 'joinLeave') {
          const [page, totals] = await Promise.all([
            service.loadPlayerJoinLeave(player.tag),
            service.loadPlayerJoinLeaveTotals(player.tag),
          ]);
          setJoinLeave(page);
          setJoinLeaveTotals(totals);
        }
        setLoadedTabs((current) => {
          const next = new Set(current).add(tab);
          loadedTabsRef.current = next;
          return next;
        });
      } catch (error) {
        if (tab !== 'war' || warGeneration === warRequestId.current)
          setErrorByTab((current) => ({
            ...current,
            [tab]: error instanceof Error ? error.message : String(error),
          }));
      } finally {
        if (tab !== 'war' || warGeneration === warRequestId.current) {
          const loading = new Set(loadingTabsRef.current);
          loading.delete(tab);
          loadingTabsRef.current = loading;
          setLoadingTabs((current) => {
            const next = new Set(current);
            next.delete(tab);
            return next;
          });
        }
      }
    },
    [loading, player.tag, service],
  );

  // PlayerDetailScreen loads the visible tab first and warms remaining tabs
  // when idle. A second eager fan-out here competed with the opening screen.

  useEffect(() => {
    let active = true;
    void service
      .loadCachedClanTag(player.tag)
      .then((tag) => {
        if (active) setCachedClanTag(tag);
      })
      .catch(() => undefined);
    return () => {
      active = false;
    };
  }, [player.tag, service]);

  const updateWarFilter = useCallback(
    async (filter: WarStatsFilter) => {
      const requestId = ++warRequestId.current;
      warFilterRef.current = filter;
      setLoadingTabs((current) => new Set(current).add('war'));
      try {
        const result = await service.loadPlayerWarStatsWithFilter(player.tag, filter);
        if (requestId === warRequestId.current) {
          setWarStats(result);
          setErrorByTab((current) => ({ ...current, war: undefined }));
        }
      } catch (error) {
        if (requestId === warRequestId.current) throw error;
      } finally {
        if (requestId === warRequestId.current)
          setLoadingTabs((current) => {
            const next = new Set(current);
            next.delete('war');
            return next;
          });
      }
    },
    [player.tag, service],
  );
  const loadMoreJoinLeave = useCallback(async () => {
    if (
      !joinLeave?.items.length ||
      joinLeave.items.length >= joinLeave.available ||
      loadingTabs.has('joinLeave')
    )
      return;
    setLoadingTabs((current) => new Set(current).add('joinLeave'));
    try {
      const before = new Date(joinLeave.items[joinLeave.items.length - 1]!.time.getTime() - 1);
      const page = await service.loadPlayerJoinLeave(player.tag, before);
      setJoinLeave(mergeJoinLeavePages(joinLeave, page));
    } catch (error) {
      setErrorByTab((current) => ({
        ...current,
        joinLeave: error instanceof Error ? error.message : String(error),
      }));
    } finally {
      setLoadingTabs((current) => {
        const next = new Set(current);
        next.delete('joinLeave');
        return next;
      });
    }
  }, [joinLeave, loadingTabs, player.tag, service]);

  const loadActivity = useCallback(
    async (type: PlayerHistoryTypeValue, force = false) => {
      activityTypeRef.current = type;
      setLoadingTabs((current) => new Set(current).add('history'));
      try {
        setActivity(await service.loadPlayerActivity(player.tag, type, force));
        setErrorByTab((current) => ({ ...current, history: undefined }));
      } catch (error) {
        setErrorByTab((current) => ({
          ...current,
          history: error instanceof Error ? error.message : String(error),
        }));
      } finally {
        setLoadingTabs((current) => {
          const next = new Set(current);
          next.delete('history');
          return next;
        });
      }
    },
    [player.tag, service],
  );

  const actions = useMemo<PlayerDetailPresentationActions>(
    () => ({
      ...externalActions,
      openInGame: handoff.request,
      toggleBookmark: async (nextPlayer) => {
        const previous = isBookmarked;
        setIsBookmarked(!previous);
        try {
          await externalActions.toggleBookmark(nextPlayer);
        } catch (error) {
          setIsBookmarked(previous);
          throw error;
        }
      },
      loadTab,
      loadActivity,
      loadMoreJoinLeave,
      updateWarFilter,
      exportWarStats: (filter) =>
        exportPlayerWarStats(
          (body) => service.downloadWarStatsExport(body),
          player.tag,
          player.name,
          filter,
        ),
      loadWarFilterPresets: () => service.loadWarFilterPresets(),
      saveWarFilterPresets: (presets) => service.saveWarFilterPresets(presets),
    }),
    [
      externalActions,
      handoff.request,
      isBookmarked,
      loadActivity,
      loadMoreJoinLeave,
      loadTab,
      player.name,
      player.tag,
      service,
      updateWarFilter,
    ],
  );

  return (
    <View style={{ flex: 1 }}>
      <PlayerDetailScreen
        loading={loading}
        initialTab={initialTab}
        actions={actions}
        model={{
          player,
          bookmarked: isBookmarked,
          linkedAccount,
          verifiedTracking,
          battlelog,
          activity,
          cwlHistory,
          legendHistory,
          warStats,
          currentWar,
          currentCwl,
          cachedClanTag,
          joinLeave,
          joinLeaveTotals,
          loadingTabs,
          errorByTab,
        }}
      />
      <ClashHandoffDialog
        visible={handoff.visible}
        onCancel={handoff.cancel}
        onConfirm={handoff.confirm}
        allowRemember
      />
    </View>
  );
}
