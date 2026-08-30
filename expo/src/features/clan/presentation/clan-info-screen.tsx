import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { BarChart3, List, Repeat2, Trophy, Users } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import { DestinationPicker, MobileWebImage, useCKTheme } from '../../../ui';
import { retainRecentSections } from '../../../ui/retained-sections';
import { ClanLeaderboardType } from '../models';
import { ClanJoinLeaveTab, ClanWarLogTab, type WarTypes } from './clan-activity-tabs';
import {
  type ClanInfoPresentationActions,
  type ClanInfoPresentationModel,
  type ClanInfoTabKey,
  visibleClanInfoTabs,
} from './clan-info-contracts';
import { ClanInfoHeader } from './clan-info-header';
import {
  ClanLeaderboardHistoryTab,
  ClanLegendHistoryTab,
  ClanRecordsHistoryTab,
} from './clan-history-tabs';
import { ClanMembersTab } from './clan-members-tab';
import { ClanCwlHistoryTab, ClanRankingsTab, ClanStatisticsTab } from './clan-statistics-tabs';

export function ClanInfoScreen({
  model,
  actions,
  initialTab = 0,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
  initialTab?: number;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const tabs = useMemo(() => visibleClanInfoTabs(model.featureFlags), [model.featureFlags]);
  const initialIndex = Math.max(0, Math.min(initialTab, tabs.length - 1));
  const [selectedIndex, setSelectedIndex] = useState(initialIndex);
  const [retainedTabs, setRetainedTabs] = useState<readonly ClanInfoTabKey[]>(() => [
    tabs[initialIndex] ?? 'members',
  ]);
  const [warTypes, setWarTypes] = useState<WarTypes>({ cwl: true, random: true, friendly: true });
  const [joinLeaveLoadSignal, setJoinLeaveLoadSignal] = useState(0);
  const joinLeaveEndArmed = useRef(false);
  const scrollRef = useRef<ScrollView>(null);
  const scrollOffsets = useRef(new Map<ClanInfoTabKey, number>());
  const activeIndex = Math.max(0, Math.min(selectedIndex, tabs.length - 1));
  const active = tabs[activeIndex] ?? 'members';
  const historyActions = useMemo<ClanInfoPresentationActions>(() => {
    const cache = new Map<string, Promise<unknown>>();
    const cached = <T,>(key: string, loader: () => Promise<T>): Promise<T> => {
      const existing = cache.get(key) as Promise<T> | undefined;
      if (existing) return existing;
      const pending = loader().catch((error) => {
        cache.delete(key);
        throw error;
      });
      cache.set(key, pending);
      return pending;
    };
    return {
      ...actions,
      loadCwlHistory: (tag) => cached(`cwl:${tag}`, () => actions.loadCwlHistory(tag)),
      loadLeaderboardSummary: (tag, type) =>
        cached(`leaderboard:${tag}:${type}`, () => actions.loadLeaderboardSummary(tag, type)),
      loadLegendSummary: (tag) => cached(`legend:${tag}`, () => actions.loadLegendSummary(tag)),
      loadRecords: (tag) => cached(`records:${tag}`, () => actions.loadRecords(tag)),
      loadProfileHistory: (tag) => cached(`profile:${tag}`, () => actions.loadProfileHistory(tag)),
    };
  }, [actions]);
  const destinations = tabs.map((key) => tabDestination(key, t, theme.onSurfaceVariant));
  const selectTab = (nextIndex: number) => {
    const next = tabs[nextIndex];
    if (!next) return;
    setSelectedIndex(nextIndex);
    setRetainedTabs((retained) => retainRecentSections(retained, next));
    joinLeaveEndArmed.current = false;
  };
  useEffect(() => {
    const frame = requestAnimationFrame(() => {
      scrollRef.current?.scrollTo({ y: scrollOffsets.current.get(active) ?? 0, animated: false });
    });
    return () => cancelAnimationFrame(frame);
  }, [active]);
  useEffect(() => {
    const tag = model.clan.tag;
    void Promise.all([
      historyActions.loadCwlHistory(tag),
      historyActions.loadLeaderboardSummary(tag, ClanLeaderboardType.homeVillage),
      historyActions.loadLegendSummary(tag),
      historyActions.loadRecords(tag),
      historyActions.loadProfileHistory(tag),
    ]).catch(() => undefined);
  }, [historyActions, model.clan.tag]);
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      <ScrollView
        ref={scrollRef}
        testID="clan-info-scroll"
        stickyHeaderIndices={[1]}
        scrollEventThrottle={100}
        onScroll={(event) => {
          const { contentOffset, contentSize, layoutMeasurement } = event.nativeEvent;
          scrollOffsets.current.set(active, contentOffset.y);
          if (active !== 'joinLeave') return;
          const nearEnd = contentSize.height - layoutMeasurement.height - contentOffset.y <= 500;
          if (nearEnd && !joinLeaveEndArmed.current) {
            joinLeaveEndArmed.current = true;
            setJoinLeaveLoadSignal((value) => value + 1);
          } else if (!nearEnd) {
            joinLeaveEndArmed.current = false;
          }
        }}
        contentContainerStyle={{ paddingBottom: insets.bottom + 16 }}
      >
        <View testID="clan-info-header-scroll-child">
          <ClanInfoHeader model={model} actions={actions} />
        </View>
        <View
          testID="clan-destination-bar"
          style={[styles.navigation, { backgroundColor: theme.background }]}
        >
          <View style={styles.navigationControl}>
            <DestinationPicker
              accessibilityLabel={destinations[activeIndex]?.label}
              onSelect={(key) => {
                const nextIndex = tabs.indexOf(key as ClanInfoTabKey);
                if (nextIndex >= 0) selectTab(nextIndex);
              }}
              options={destinations}
              selectedKey={active}
              showPositionHint
            />
          </View>
        </View>
        <View testID="clan-detail-body" style={styles.tabBody}>
          {tabs.map((key) =>
            retainedTabs.includes(key) ? (
              <View
                key={key}
                testID={`clan-retained-tab-${key}`}
                style={key === active ? undefined : styles.hiddenTab}
              >
                {renderTab(key, model, historyActions, warTypes, setWarTypes, joinLeaveLoadSignal)}
              </View>
            ) : null,
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function renderTab(
  key: ClanInfoTabKey,
  model: ClanInfoPresentationModel,
  actions: ClanInfoPresentationActions,
  warTypes: WarTypes,
  setWarTypes: (value: WarTypes) => void,
  joinLeaveLoadSignal: number,
) {
  if (key === 'members') return <ClanMembersTab model={model} actions={actions} />;
  if (key === 'warLog')
    return (
      <ClanWarLogTab
        model={model}
        actions={actions}
        warTypes={warTypes}
        setWarTypes={setWarTypes}
      />
    );
  if (key === 'joinLeave')
    return (
      <ClanJoinLeaveTab model={model} actions={actions} loadMoreSignal={joinLeaveLoadSignal} />
    );
  if (key === 'statistics')
    return (
      <ClanStatisticsTab
        model={model}
        actions={actions}
        warTypes={warTypes}
        setWarTypes={setWarTypes}
      />
    );
  if (key === 'rankings') return <ClanRankingsTab model={model} />;
  if (key === 'cwlHistory') return <ClanCwlHistoryTab model={model} actions={actions} />;
  if (key === 'leaderboardHistory')
    return <ClanLeaderboardHistoryTab model={model} actions={actions} />;
  if (key === 'legendHistory') return <ClanLegendHistoryTab model={model} actions={actions} />;
  return <ClanRecordsHistoryTab model={model} actions={actions} />;
}

function tabDestination(
  key: ClanInfoTabKey,
  t: ReturnType<typeof useI18n>['t'],
  iconColor: string,
): { key: ClanInfoTabKey; label: string; icon: ReactNode } {
  if (key === 'members')
    return { key, label: t('clanMembers'), icon: <Users size={20} color={iconColor} /> };
  if (key === 'warLog')
    return {
      key,
      label: t('warLog'),
      icon: <MobileWebImage imageUrl={ImageAssets.war} style={styles.tabImage} />,
    };
  if (key === 'joinLeave')
    return {
      key,
      label: t('clanJoinLeaveTab'),
      icon: <Repeat2 size={20} color={iconColor} />,
    };
  if (key === 'statistics')
    return { key, label: t('warStats'), icon: <BarChart3 size={20} color={iconColor} /> };
  if (key === 'rankings')
    return { key, label: t('clanRankingsTab'), icon: <List size={20} color={iconColor} /> };
  if (key === 'cwlHistory')
    return { key, label: t('cwlHistoryTitle'), icon: <Trophy size={20} color={iconColor} /> };
  if (key === 'leaderboardHistory')
    return {
      key,
      label: t('clanLeaderboardHistoryTab'),
      icon: <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.tabImage} />,
    };
  if (key === 'legendHistory')
    return {
      key,
      label: t('clanLegendHistoryTab'),
      icon: <MobileWebImage imageUrl={ImageAssets.legendBlazon} style={styles.tabImage} />,
    };
  return {
    key,
    label: `${t('clanRecordsTab')} & ${t('generalHistory')}`,
    icon: <MobileWebImage imageUrl={ImageAssets.bestTrophies} style={styles.tabImage} />,
  };
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  navigation: {
    minHeight: 54,
    paddingTop: 8,
    paddingBottom: 2,
    paddingHorizontal: 12,
    justifyContent: 'center',
  },
  navigationControl: { width: '100%', maxWidth: 520, alignSelf: 'center' },
  tabImage: { width: 20, height: 20, resizeMode: 'contain' },
  tabBody: { minHeight: 360 },
  hiddenTab: { display: 'none' },
});
