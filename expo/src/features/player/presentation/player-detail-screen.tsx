import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { InteractionManager, RefreshControl, ScrollView, StyleSheet, View } from 'react-native';
import { History, Repeat2 } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useI18n } from '../../../i18n';
import { ImageAssets } from '../../../core/assets/image-assets';
import { MobileWebImage, ProfileTabs, useCKTheme } from '../../../ui';
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
import { PlayerAchievementsTab } from './player-achievements-tab';

export function PlayerDetailScreen({
  model,
  actions,
  initialTab = 'home',
}: {
  model: PlayerDetailPresentationModel;
  actions: PlayerDetailPresentationActions;
  initialTab?: PlayerDetailTabKey;
}) {
  const theme = useCKTheme();
  const { t } = useI18n();
  const insets = useSafeAreaInsets();
  const tabs = useMemo(() => PLAYER_DETAIL_TABS, []);
  const initialTabKey = tabs.some((item) => item.key === initialTab) ? initialTab : 'home';
  const [tab, setTab] = useState<PlayerDetailTabKey>(initialTabKey);
  const [retainedTabs, setRetainedTabs] = useState<readonly PlayerDetailTabKey[]>(() => [
    initialTabKey,
  ]);
  const [refreshing, setRefreshing] = useState(false);
  const scrollRef = useRef<ScrollView>(null);
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
    const task = InteractionManager.runAfterInteractions(() => {
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
      task.cancel();
    };
  }, [loadTab]);

  const selectTab = (next: PlayerDetailTabKey) => {
    const nextIndex = tabs.findIndex((item) => item.key === next);
    if (nextIndex < 0) return;
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
        stickyHeaderIndices={[1]}
        scrollEventThrottle={100}
        onScroll={(event) => {
          const { contentOffset, contentSize, layoutMeasurement } = event.nativeEvent;
          scrollOffsets.current.set(tab, contentOffset.y);
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
            safeTop={insets.top}
          />
        </View>
        <View
          testID="player-detail-navigation"
          style={[styles.navigation, { backgroundColor: theme.background }]}
        >
          <View style={styles.navigationContent}>
            <ProfileTabs
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
        <View testID="player-detail-body" style={styles.tabBody}>
          {tabs.map((item) =>
            retainedTabs.includes(item.key) ? (
              <View
                key={item.key}
                testID={`player-retained-tab-${item.key}`}
                style={item.key === tab ? undefined : styles.hiddenTab}
              >
                <TabState model={model} tab={item.key} actions={actions}>
                  {renderTab(item.key, model, actions)}
                </TabState>
              </View>
            ) : null,
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const PLAYER_DETAIL_PRELOAD_TABS: readonly PlayerDetailTabKey[] = [
  'battles',
  'history',
  'war',
  'cwl',
  'joinLeave',
];

export function isPlayerDetailTabRefreshable(tab: PlayerDetailTabKey): boolean {
  return tab === 'battles' || tab === 'history' || tab === 'cwl';
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
) {
  if (tab === 'home') return <PlayerBaseTab player={model.player} village="home" />;
  if (tab === 'builder') return <PlayerBaseTab player={model.player} village="builder" />;
  if (tab === 'battles') return <PlayerBattlelogTab data={model.battlelog} />;
  if (tab === 'history')
    return (
      <PlayerActivityTab
        data={model.activity}
        verifiedTracking={model.verifiedTracking}
        actions={actions}
      />
    );
  if (tab === 'war')
    return (
      <PlayerWarTab
        data={model.warStats}
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
  tabBody: { minHeight: 360 },
  hiddenTab: { display: 'none' },
});
