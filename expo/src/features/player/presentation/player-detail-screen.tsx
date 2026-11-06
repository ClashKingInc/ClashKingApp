import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import type { ScrollViewInstance } from 'react-native';
import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { RefreshControl, ScrollView, StyleSheet, View } from 'react-native';
import { History, Repeat2 } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useI18n } from '../../../i18n';
import { ImageAssets } from '../../../core/assets/image-assets';
import { MobileWebImage, ProfileTabs, SkeletonContent, useCKTheme } from '../../../ui';
import { retainRecentSections } from '../../../ui/retained-sections';
import type {
  PlayerDetailPresentationActions,
  PlayerDetailPresentationModel,
  PlayerDetailTabKey,
} from './player-detail-contracts';
import {
  PLAYER_DETAIL_TABS,
  PlayerActivityTab,
  PlayerBaseTab,
  PlayerBattlelogTab,
  PlayerCwlTab,
  PlayerDetailHeader,
  PlayerJoinLeaveTab,
  PlayerWarTab,
  TabState,
} from './player-detail-components';
import { LegendHistoryList } from '../../legends/presentation/legend-history';
import { PlayerAchievementsTab } from './player-achievements-tab';
import { useLinkParameters } from '../../../core/deep-links/link-parameters';
import { PlayerBattlelogShareModal } from './player-battlelog-share';
import { playerLoadingModel } from './player-loading-model';

export function PlayerDetailScreen({
  model,
  actions,
  initialTab = 'home',
  loading = false,
}: {
  model: PlayerDetailPresentationModel;
  actions: PlayerDetailPresentationActions;
  initialTab?: PlayerDetailTabKey;
  loading?: boolean;
}) {
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const { t } = useI18n();
  const insets = useSafeAreaInsets();
  const hasLegendHistory = !!model.legendHistory?.length;
  // Availability comes from retained finishes, never from the player's current league.
  const tabs = useMemo(
    () => PLAYER_DETAIL_TABS.filter((item) => item.key !== 'legendHistory' || hasLegendHistory),
    [hasLegendHistory],
  );
  const link = useLinkParameters();
  const initialTabKey =
    PLAYER_DETAIL_TABS.find((item) => item.key === (link.tab ?? initialTab))?.key ?? 'home';
  const [requestedTab, setTab] = useState<PlayerDetailTabKey>(initialTabKey);
  // Shared history links wait on availability without exposing an empty page option.
  const tab = tabs.some((item) => item.key === requestedTab) ? requestedTab : 'home';
  const [retainedTabs, setRetainedTabs] = useState<readonly PlayerDetailTabKey[]>(() => [
    'home',
    initialTabKey,
  ]);
  const [refreshing, setRefreshing] = useState(false);
  const [visibleBattles, setVisibleBattles] = useState(20);
  const [lootGridScrubbing, setLootGridScrubbing] = useState(false);
  const [battlelogShareVisible, setBattlelogShareVisible] = useState(false);
  const scrollRef = useRef<ScrollViewInstance>(null);
  const scrollOffsets = useRef(new Map<PlayerDetailTabKey, number>());
  const current = tabs.find((item) => item.key === tab) ?? tabs[0]!;
  const labelFor = (item: (typeof tabs)[number]) =>
    item.labelKey ? t(item.labelKey) : item.flutterLabel!;
  const loadTab = actions.loadTab;

  useEffect(() => {
    void loadTab(tab);
  }, [loadTab, tab]);

  useEffect(() => {
    let cancelled = false;
    const task = requestIdleCallback(() => {
      void (async () => {
        for (const key of PLAYER_DETAIL_PRELOAD_TABS) {
          if (cancelled) return;
          try {
            await loadTab(key);
          } catch {
            // The selected tab keeps its own retry/error state; background prefetch is best-effort.
          }
        }
      })();
    });
    return () => {
      cancelled = true;
      cancelIdleCallback(task);
    };
  }, [loadTab]);

  const selectTab = (next: PlayerDetailTabKey) => {
    const nextIndex = tabs.findIndex((item) => item.key === next);
    if (nextIndex < 0) return;
    setLootGridScrubbing(false);
    setTab(next);
    setRetainedTabs((retained) => retainRecentSections(retained, next));
  };
  useEffect(() => {
    const frame = requestAnimationFrame(() => {
      scrollRef.current?.scrollTo({ y: scrollOffsets.current.get(tab) ?? 0, animated: false });
    });
    return () => cancelAnimationFrame(frame);
  }, [tab]);

  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      <ScrollView
        ref={scrollRef}
        testID="player-detail-scroll"
        scrollEnabled={!(tab === 'battles' && lootGridScrubbing)}
        stickyHeaderIndices={[1]}
        scrollEventThrottle={100}
        onScroll={(event) => {
          const { contentOffset, contentSize, layoutMeasurement } = event.nativeEvent;
          scrollOffsets.current.set(tab, contentOffset.y);
          if (
            tab === 'battles' &&
            contentSize.height - layoutMeasurement.height - contentOffset.y <= 500
          ) {
            const total =
              model.battlelog?.forMode('farming').filter((entry) => entry.attack).length ?? 0;
            setVisibleBattles((count) => Math.min(Math.max(count, total), count + 20));
          }
          if (
            tab === 'joinLeave' &&
            contentSize.height - layoutMeasurement.height - contentOffset.y <= 500
          )
            void actions.loadMoreJoinLeave();
        }}
        contentContainerStyle={{ paddingBottom: insets.bottom + 20 }}
        refreshControl={
          isPlayerDetailTabRefreshable(tab) ? (
            <RefreshControl
              refreshing={refreshing}
              onRefresh={async () => {
                setRefreshing(true);
                try {
                  await refreshPlayerDetailTab(tab, actions);
                } finally {
                  setRefreshing(false);
                }
              }}
            />
          ) : undefined
        }
      >
        <View testID="player-detail-header-scroll-child">
          <PlayerDetailHeader
            model={model}
            actions={actions}
            selectedTab={tab}
            onBattlelogExport={() => setBattlelogShareVisible(true)}
            safeTop={insets.top}
            loading={loading}
          />
        </View>
        <View
          testID="player-detail-navigation"
          style={[styles.navigation, { backgroundColor: theme.background }]}
        >
          <View
            style={[
              styles.navigationContent,
              layout.isExpanded && { maxWidth: layout.contentMaxWidth, paddingHorizontal: 24 },
            ]}
          >
            <ProfileTabs
              variant={layout.isExpanded ? 'underline' : undefined}
              overflow={layout.isExpanded ? 'scroll' : undefined}
              tabs={tabs.map((item) => ({
                key: item.key,
                label: labelFor(item),
                icon: tabIcon(item.key, model, theme.onSurfaceVariant),
              }))}
              selectedKey={current.key}
              onSelect={(key) => selectTab(key as PlayerDetailTabKey)}
            />
          </View>
        </View>
        <SkeletonContent
          loading={loading}
          testID="player-detail-body"
          style={[styles.tabBody, layout.isExpanded && { maxWidth: layout.contentMaxWidth }]}
        >
          {tabs.map((item) =>
            retainedTabs.includes(item.key) ? (
              <View
                key={item.key}
                testID={`player-retained-tab-${item.key}`}
                style={item.key === tab ? undefined : styles.hiddenTab}
              >
                <TabState model={model} tab={item.key} actions={actions}>
                  {renderTab(
                    item.key,
                    playerLoadingModel(model, item.key),
                    actions,
                    visibleBattles,
                    setLootGridScrubbing,
                  )}
                </TabState>
              </View>
            ) : null,
          )}
        </SkeletonContent>
      </ScrollView>
      <PlayerBattlelogShareModal
        items={(model.battlelog?.forMode('farming') ?? []).filter((item) => item.attack)}
        mode="farming"
        onClose={() => setBattlelogShareVisible(false)}
        playerName={model.player.name}
        visible={battlelogShareVisible}
      />
    </SafeAreaView>
  );
}

const PLAYER_DETAIL_PRELOAD_TABS: readonly PlayerDetailTabKey[] = [
  // Availability depends on retained finishes. Load them before filtering the
  // picker, or its hidden tab can never be selected to trigger its own request.
  'legendHistory',
  'battles',
  'history',
  'war',
  'cwl',
  'joinLeave',
];

export function isPlayerDetailTabRefreshable(tab: PlayerDetailTabKey): boolean {
  return tab === 'battles' || tab === 'history' || tab === 'cwl' || tab === 'legendHistory';
}

export function refreshPlayerDetailTab(
  tab: PlayerDetailTabKey,
  actions: Pick<PlayerDetailPresentationActions, 'loadTab'>,
): Promise<void> {
  return isPlayerDetailTabRefreshable(tab) ? actions.loadTab(tab, true) : Promise.resolve();
}

function renderTab(
  tab: PlayerDetailTabKey,
  model: PlayerDetailPresentationModel,
  actions: PlayerDetailPresentationActions,
  visibleBattles: number,
  onLootGridScrubChange: (active: boolean) => void,
) {
  if (tab === 'legendHistory')
    return (
      <View style={styles.historyContent}>
        <LegendHistoryList history={model.legendHistory ?? []} />
      </View>
    );
  if (tab === 'home') return <PlayerBaseTab player={model.player} village="home" />;
  if (tab === 'builder') return <PlayerBaseTab player={model.player} village="builder" />;
  if (tab === 'battles')
    return (
      <PlayerBattlelogTab
        data={model.battlelog}
        visibleCount={visibleBattles}
        onLootGridScrubChange={onLootGridScrubChange}
      />
    );
  if (tab === 'history') return <PlayerActivityTab data={model.activity} actions={actions} />;
  if (tab === 'war')
    return (
      <PlayerWarTab
        data={model.warStats}
        cwlHistory={model.cwlHistory}
        actions={actions}
        player={model.player}
        loading={model.loadingTabs?.has('war') === true}
      />
    );
  if (tab === 'cwl') return <PlayerCwlTab data={model.cwlHistory} actions={actions} />;
  if (tab === 'achievements') return <PlayerAchievementsTab player={model.player} />;
  return (
    <PlayerJoinLeaveTab
      page={model.joinLeave}
      totals={model.joinLeaveTotals}
      actions={actions}
      loadingMore={model.loadingTabs?.has('joinLeave') && !!model.joinLeave?.items.length}
    />
  );
}

function tabIcon(
  tab: PlayerDetailTabKey,
  model: PlayerDetailPresentationModel,
  color: string,
): ReactNode {
  if (tab === 'home')
    return (
      <MobileWebImage
        imageUrl={model.player.townHallPic || ImageAssets.townHall(model.player.townHallLevel)}
        style={styles.tabImage}
      />
    );
  if (tab === 'builder')
    return (
      <MobileWebImage
        imageUrl={ImageAssets.builderHall(model.player.builderHallLevel)}
        style={styles.tabImage}
      />
    );
  if (tab === 'battles')
    return <MobileWebImage imageUrl={ImageAssets.attacks} style={styles.tabImage} />;
  if (tab === 'legendHistory')
    return <MobileWebImage imageUrl={ImageAssets.legendLeagueOne} style={styles.tabImage} />;
  if (tab === 'history') return <History size={20} color={color} />;
  if (tab === 'war') return <MobileWebImage imageUrl={ImageAssets.war} style={styles.tabImage} />;
  if (tab === 'cwl')
    return <MobileWebImage imageUrl={ImageAssets.cwlSwordsNoBorder} style={styles.tabImage} />;
  if (tab === 'achievements')
    return <MobileWebImage imageUrl={ImageAssets.attackStar} style={styles.tabImage} />;
  return <Repeat2 size={20} color={color} />;
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  navigation: {
    minHeight: 54,
    justifyContent: 'center',
    paddingTop: 8,
    paddingBottom: 2,
    paddingHorizontal: 12,
    zIndex: 30,
  },
  navigationContent: { width: '100%', maxWidth: 520, alignSelf: 'center' },
  tabImage: { width: 24, height: 24, resizeMode: 'contain' },
  // Bound data rows independently of the full-bleed hero and sticky navigation.
  // Tablet rotation must not turn a compact phone card into a screen-wide strip.
  tabBody: { minHeight: 360, width: '100%', maxWidth: 760, alignSelf: 'center' },
  historyContent: { padding: 16, width: '100%', alignSelf: 'center' },
  hiddenTab: { display: 'none' },
});
