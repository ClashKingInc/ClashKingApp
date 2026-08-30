import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

import type {
  PlayerActivityFeed,
  PlayerBattlelogData,
  PlayerCwlHistory,
  PlayerJoinLeavePage,
  PlayerJoinLeaveTotal,
  PlayerHistoryTypeValue,
  PlayerWarStats,
  WarStatsFilter,
} from '../models';
import { WarStatsFilter as WarStatsFilterModel } from '../models';
import { canonicalTag } from '../../../core/domain/tags';
import type {
  PlayerDetailPresentationActions,
  PlayerDetailRootProps,
  PlayerDetailTabKey,
} from './player-detail-contracts';
import { PlayerDetailScreen } from './player-detail-screen';
import { exportPlayerWarStats } from './player-war-export';
import { mergeJoinLeavePages } from './player-join-leave-state';

export function PlayerDetailRoot(props: PlayerDetailRootProps) {
  return <PlayerDetailRootState key={canonicalTag(props.player.tag)} {...props} />;
}

function PlayerDetailRootState({
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
  const [activity, setActivity] = useState<PlayerActivityFeed | null>(null);
  const [cwlHistory, setCwlHistory] = useState<PlayerCwlHistory | null>(null);
  const [warStats, setWarStats] = useState<PlayerWarStats | null>(player.warStats);
  const [isBookmarked, setIsBookmarked] = useState(bookmarked);
  const [cachedClanTag, setCachedClanTag] = useState<string | null>(null);
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
  const activityTypeRef = useRef<PlayerHistoryTypeValue>('troop_level');

  const loadTab = useCallback(
    async (tab: PlayerDetailTabKey, force = false) => {
      if (!force && loadedTabsRef.current.has(tab)) return;
      if (!force && loadingTabsRef.current.has(tab)) return;
      loadingTabsRef.current = new Set(loadingTabsRef.current).add(tab);
      setLoadingTabs((current) => new Set(current).add(tab));
      setErrorByTab((current) => ({ ...current, [tab]: undefined }));
      try {
        if (tab === 'battles') setBattlelog(await service.loadPlayerBattlelog(player.tag, force));
        else if (tab === 'history')
          setActivity(await service.loadPlayerActivity(player.tag, activityTypeRef.current, force));
        else if (tab === 'cwl')
          setCwlHistory(await service.loadPlayerCwlHistory(player.tag, force));
        else if (tab === 'war')
          setWarStats(
            await service.loadPlayerWarStatsWithFilter(
              player.tag,
              WarStatsFilterModel.defaultFilter(),
            ),
          );
        else if (tab === 'joinLeave') {
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
        setErrorByTab((current) => ({
          ...current,
          [tab]: error instanceof Error ? error.message : String(error),
        }));
      } finally {
        const loading = new Set(loadingTabsRef.current);
        loading.delete(tab);
        loadingTabsRef.current = loading;
        setLoadingTabs((current) => {
          const next = new Set(current);
          next.delete(tab);
          return next;
        });
      }
    },
    [player.tag, service],
  );

  useEffect(() => {
    // Flutter keeps each profile page attached, so its stateful history tabs
    // begin loading as soon as the player opens. Warm the equivalent Expo
    // datasets here so switching destinations never starts a cold request.
    for (const tab of ['battles', 'history', 'cwl', 'joinLeave'] as const) void loadTab(tab);
  }, [loadTab]);

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
      setLoadingTabs((current) => new Set(current).add('war'));
      try {
        setWarStats(await service.loadPlayerWarStatsWithFilter(player.tag, filter));
        setErrorByTab((current) => ({ ...current, war: undefined }));
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        setErrorByTab((current) => ({ ...current, war: undefined }));
        externalActions.showMessage(message);
      } finally {
        setLoadingTabs((current) => {
          const next = new Set(current);
          next.delete('war');
          return next;
        });
      }
    },
    [externalActions, player.tag, service],
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
        exportPlayerWarStats(service.apiV2Url, player.tag, player.name, filter),
      loadWarFilterPresets: () => service.loadWarFilterPresets(),
      saveWarFilterPresets: (presets) => service.saveWarFilterPresets(presets),
    }),
    [
      externalActions,
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
    <PlayerDetailScreen
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
  );
}
