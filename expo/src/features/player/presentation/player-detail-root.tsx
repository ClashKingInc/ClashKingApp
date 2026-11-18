import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react';
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
  const loadedTabsRef = useRef<ReadonlySet<PlayerDetailTabKey>>(
    new Set(['home', 'builder', 'achievements']),
  );
  const pendingRequests = useRef(new Map<PlayerDetailTabKey, Promise<void>>());
  const requestGenerations = useRef(new Map<PlayerDetailTabKey, number>());
  const currentJoinLeave = useRef(joinLeave);
  const mounted = useRef(true);
  useLayoutEffect(() => {
    currentJoinLeave.current = joinLeave;
  }, [joinLeave]);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
    };
  }, []);
  const warFilterRef = useRef(new WarStatsFilterModel(warHistoryRangeFilter('days:90')));
  const activityTypeRef = useRef<PlayerHistoryTypeValue>('troop_level');

  // One request owner per data section. A newer filter/refresh invalidates an
  // older response, and pagination reads the latest page without making every
  // unrelated loading update recreate all of the screen's actions.
  const runRequest = useCallback(
    (
      tab: PlayerDetailTabKey,
      request: (isCurrent: () => boolean) => Promise<void>,
      replace = false,
      rethrow = false,
    ): Promise<void> => {
      if (!mounted.current) return Promise.resolve();
      const existing = pendingRequests.current.get(tab);
      if (existing && !replace) return existing;
      const generation = (requestGenerations.current.get(tab) ?? 0) + 1;
      requestGenerations.current.set(tab, generation);
      const isCurrent = () => mounted.current && requestGenerations.current.get(tab) === generation;
      setLoadingTabs((current) => (current.has(tab) ? current : new Set(current).add(tab)));
      setErrorByTab((current) =>
        current[tab] === undefined ? current : { ...current, [tab]: undefined },
      );
      const pending = (async () => {
        try {
          await request(isCurrent);
          if (isCurrent()) loadedTabsRef.current = new Set(loadedTabsRef.current).add(tab);
        } catch (error) {
          if (isCurrent()) {
            setErrorByTab((current) => ({
              ...current,
              [tab]: error instanceof Error ? error.message : String(error),
            }));
            if (rethrow) throw error;
          }
        } finally {
          if (isCurrent()) {
            pendingRequests.current.delete(tab);
            setLoadingTabs((current) => {
              if (!current.has(tab)) return current;
              const next = new Set(current);
              next.delete(tab);
              return next;
            });
          }
        }
      })();
      pendingRequests.current.set(tab, pending);
      return pending;
    },
    [],
  );

  const loadTab = useCallback(
    (tab: PlayerDetailTabKey, force = false): Promise<void> => {
      if (loading || ['home', 'builder', 'achievements'].includes(tab)) return Promise.resolve();
      if (!force && loadedTabsRef.current.has(tab)) return Promise.resolve();
      return runRequest(
        tab,
        async (isCurrent) => {
          if (tab === 'battles') {
            const value = await service.loadPlayerBattlelog(player.tag, force);
            if (isCurrent()) setBattlelog(value);
          } else if (tab === 'history') {
            const value = await service.loadPlayerActivity(
              player.tag,
              activityTypeRef.current,
              force,
            );
            if (isCurrent()) setActivity(value);
          } else if (tab === 'legendHistory') {
            const value = await service.loadPlayerLegendHistory(player.tag);
            if (isCurrent()) setLegendHistory(value);
          } else if (tab === 'cwl') {
            const value = await service.loadPlayerCwlHistory(player.tag, force);
            if (isCurrent()) setCwlHistory(value);
          } else if (tab === 'war') {
            const value = await service.loadPlayerWarStatsWithFilter(
              player.tag,
              warFilterRef.current,
            );
            if (isCurrent()) setWarStats(value);
          } else if (tab === 'joinLeave') {
            const [page, totals] = await Promise.all([
              service.loadPlayerJoinLeave(player.tag),
              service.loadPlayerJoinLeaveTotals(player.tag),
            ]);
            if (isCurrent()) {
              currentJoinLeave.current = page;
              setJoinLeave(page);
              setJoinLeaveTotals(totals);
            }
          }
        },
        force,
      );
    },
    [loading, player.tag, runRequest, service],
  );

  // PlayerDetailScreen loads the selected section and checks only legend-history
  // availability in the background. Other sections load on demand; a response
  // train for unopened sections would compete with navigation and rendering.

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
    (filter: WarStatsFilter) => {
      warFilterRef.current = filter;
      return runRequest(
        'war',
        async (isCurrent) => {
          const value = await service.loadPlayerWarStatsWithFilter(player.tag, filter);
          if (isCurrent()) setWarStats(value);
        },
        true,
        true,
      );
    },
    [player.tag, runRequest, service],
  );

  const loadMoreJoinLeave = useCallback((): Promise<void> => {
    const page = currentJoinLeave.current;
    if (!page?.items.length || page.items.length >= page.available) return Promise.resolve();
    const pending = pendingRequests.current.get('joinLeave');
    if (pending) return pending;
    return runRequest('joinLeave', async (isCurrent) => {
      const before = new Date(page.items[page.items.length - 1]!.time.getTime() - 1);
      const next = await service.loadPlayerJoinLeave(player.tag, before);
      if (isCurrent()) {
        const merged = mergeJoinLeavePages(currentJoinLeave.current ?? page, next);
        currentJoinLeave.current = merged;
        setJoinLeave(merged);
      }
    });
  }, [player.tag, runRequest, service]);

  const loadActivity = useCallback(
    (type: PlayerHistoryTypeValue, force = false) => {
      activityTypeRef.current = type;
      // Changing the filter replaces an in-flight request for the previous type.
      return runRequest(
        'history',
        async (isCurrent) => {
          const value = await service.loadPlayerActivity(player.tag, type, force);
          if (isCurrent()) setActivity(value);
        },
        true,
      );
    },
    [player.tag, runRequest, service],
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

  const model = useMemo(
    () => ({
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
    }),
    [
      player,
      isBookmarked,
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
    ],
  );

  return (
    <View style={{ flex: 1 }}>
      <PlayerDetailScreen
        loading={loading}
        initialTab={initialTab}
        actions={actions}
        model={model}
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
