import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { RefreshControl, ScrollView, StyleSheet, View } from 'react-native';
import { History, Repeat2 } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useI18n } from '../../../i18n';
import { ImageAssets } from '../../../core/assets/image-assets';
import { MobileWebImage, ProfileTabs, SkeletonContent, useCKTheme } from '../../../ui';
import { useSectionScroll, useSectionSelection } from '../../../ui/use-section-selection';
import { RetainedSection } from '../../../ui/retained-section';
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
  const selection = useSectionSelection<PlayerDetailTabKey>(initialTabKey, ['home', initialTabKey]);
  const requestedTab = selection.selectedKey;
  // Shared history links wait on availability without exposing an empty page option.
  const tab = tabs.some((item) => item.key === requestedTab) ? requestedTab : 'home';
  const contentTab = tabs.some((item) => item.key === selection.contentKey)
    ? selection.contentKey
    : 'home';
  const {
    attachScroll,
    onViewportLayout,
    onHeaderLayout,
    onTabsLayout,
    recordScroll,
    prepareSwitch,
    minimumContentHeight,
  } = useSectionScroll(contentTab);
  const [refreshing, setRefreshing] = useState<
    Partial<
      Record<
        PlayerDetailTabKey,
        {
          playerTag: string;
          generation: number;
        }
      >
    >
  >({});
  const refreshGeneration = useRef(0);
  const mounted = useRef(true);
  useEffect(() => {
    mounted.current = true;
    return () => {
      mounted.current = false;
      refreshGeneration.current += 1;
    };
  }, []);
  const [visibleBattles, setVisibleBattles] = useState(20);
  const farmingAttacks = useMemo(
    () => (model.battlelog?.forMode('farming') ?? []).filter((entry) => entry.attack),
    [model.battlelog],
  );
  const [lootGridScrubbing, setLootGridScrubbing] = useState(false);
  const [battlelogShareVisible, setBattlelogShareVisible] = useState(false);
  const current = tabs.find((item) => item.key === tab) ?? tabs[0]!;
  const labelFor = (item: (typeof tabs)[number]) =>
    item.labelKey ? t(item.labelKey) : item.flutterLabel!;
  const loadTab = actions.loadTab;
  const canRefresh = isPlayerDetailTabRefreshable(contentTab);
  const refreshVisibleSection = useCallback(async () => {
    if (!isPlayerDetailTabRefreshable(contentTab)) return;
    const generation = ++refreshGeneration.current;
    setRefreshing((current) => ({
      ...current,
      [contentTab]: { playerTag: model.player.tag, generation },
    }));
    try {
      await refreshPlayerDetailTab(contentTab, actions);
    } finally {
      // Each section owns its refresh. A completion from the section we left
      // must not stop another section or a newer refresh of this same section.
      if (mounted.current)
        setRefreshing((current) => {
          if (current[contentTab]?.generation !== generation) return current;
          const next = { ...current };
          delete next[contentTab];
          return next;
        });
    }
  }, [contentTab, model.player.tag, actions]);

  useEffect(() => {
    void loadTab(tab);
  }, [loadTab, tab]);

  useEffect(() => {
    // This one availability request is necessary to expose a retained-history
    // tab. Other sections load on selection, without a background response train
    // rebuilding the detail screen while the user is changing sections.
    void loadTab('legendHistory');
  }, [loadTab]);

  const selectTab = (next: PlayerDetailTabKey) => {
    const nextIndex = tabs.findIndex((item) => item.key === next);
    if (nextIndex < 0 || next === tab) return;
    prepareSwitch();
    setLootGridScrubbing(false);
    selection.select(next);
  };

  // Reuse the committed body during the urgent selection render. Rebuilding it
  // here would put every retained card back on the critical path of a tab tap.
  const body = useMemo(
    () =>
      tabs.map((item) =>
        selection.retainedKeys.includes(item.key) ? (
          <RetainedSection
            key={item.key}
            testID={`player-retained-tab-${item.key}`}
            active={item.key === contentTab}
            render={() => (
              <TabState model={model} tab={item.key} actions={actions}>
                {renderTab(
                  item.key,
                  playerLoadingModel(model, item.key),
                  actions,
                  visibleBattles,
                  setLootGridScrubbing,
                )}
              </TabState>
            )}
          />
        ) : null,
      ),
    [tabs, selection.retainedKeys, contentTab, model, actions, visibleBattles],
  );

  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      <ScrollView
        ref={attachScroll}
        onLayout={onViewportLayout}
        testID="player-detail-scroll"
        scrollEnabled={!(contentTab === 'battles' && lootGridScrubbing)}
        stickyHeaderIndices={[1]}
        scrollEventThrottle={16}
        onScroll={(event) => {
          const { contentOffset, contentSize, layoutMeasurement } = event.nativeEvent;
          recordScroll(contentOffset.y);
          if (
            contentTab === 'battles' &&
            contentSize.height - layoutMeasurement.height - contentOffset.y <= 500
          ) {
            if (visibleBattles < farmingAttacks.length) {
              setVisibleBattles((count) => Math.min(farmingAttacks.length, count + 20));
            }
          }
          if (
            contentTab === 'joinLeave' &&
            contentSize.height - layoutMeasurement.height - contentOffset.y <= 500
          )
            void actions.loadMoreJoinLeave();
        }}
        contentContainerStyle={{ paddingBottom: insets.bottom + 20 }}
        // Keep this element mounted on every section. React Native changes the
        // ScrollView's native ancestry when refreshControl is added or removed,
        // remounting retained bodies and resetting their scroll/layout state.
        refreshControl={
          <RefreshControl
            enabled={canRefresh}
            tintColor={canRefresh ? theme.onSurface : 'transparent'}
            refreshing={refreshing[contentTab]?.playerTag === model.player.tag}
            onRefresh={refreshVisibleSection}
          />
        }
      >
        <View testID="player-detail-header-scroll-child" onLayout={onHeaderLayout}>
          <PlayerDetailHeader
            model={model}
            actions={actions}
            selectedTab={contentTab}
            onBattlelogExport={() => setBattlelogShareVisible(true)}
            safeTop={insets.top}
            loading={loading}
          />
        </View>
        <View
          testID="player-detail-navigation"
          onLayout={onTabsLayout}
          style={[styles.navigation, { backgroundColor: theme.background }]}
        >
          <View
            style={[
              styles.navigationContent,
              layout.isExpanded && { maxWidth: layout.contentMaxWidth, paddingHorizontal: 24 },
            ]}
          >
            <ProfileTabs
              variant="underline"
              overflow="scroll"
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
        <View style={{ minHeight: minimumContentHeight }}>
          <SkeletonContent
            loading={loading}
            testID="player-detail-body"
            style={[styles.tabBody, layout.isExpanded && { maxWidth: layout.contentMaxWidth }]}
          >
            {body}
          </SkeletonContent>
        </View>
      </ScrollView>
      {battlelogShareVisible ? (
        <PlayerBattlelogShareModal
          items={farmingAttacks}
          mode="farming"
          onClose={() => setBattlelogShareVisible(false)}
          playerName={model.player.name}
          visible
        />
      ) : null}
    </SafeAreaView>
  );
}

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
});
