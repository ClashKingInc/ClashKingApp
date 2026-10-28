import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import type { ScrollViewInstance } from 'react-native';
import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import { BarChart3, List, Repeat2, Users } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import {
  DestinationPicker,
  ProfileTabs,
  MobileWebImage,
  SkeletonContent,
  useCKTheme,
} from '../../../ui';
import { retainRecentSections } from '../../../ui/retained-sections';
import { ClanJoinLeaveTab, ClanWarLogTab } from './clan-activity-tabs';
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
import { ClanCompetitiveTab } from './clan-competitive-tab';
import { hasCompetitiveMembers } from '../models/clan-competitive';
import { ClanLeaderboardType, type ClanLeaderboardTypeValue } from '../models';
import { ClanCwlHistoryTab, ClanRankingsTab } from './clan-statistics-tabs';
import { ClanStatisticsTab } from './clan-war-stats-tab';
import { useLinkParameters } from '../../../core/deep-links/link-parameters';
import { TutorialScrollView } from '../../tutorials/tutorial-ui';

export function ClanInfoScreen({
  model,
  actions,
  initialTab = 0,
  loading = false,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
  initialTab?: number;
  loading?: boolean;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const insets = useSafeAreaInsets();
  const [historyTypes, setHistoryTypes] = useState<readonly ClanLeaderboardTypeValue[] | null>(
    null,
  );
  const tabs = useMemo(
    () =>
      visibleClanInfoTabs(model.featureFlags).filter(
        (tab) =>
          (tab !== 'competitive' || hasCompetitiveMembers(model.clan.memberList)) &&
          (tab !== 'leaderboardHistory' || (historyTypes?.length ?? 0) > 0),
      ),
    [model.featureFlags, model.clan.memberList, historyTypes],
  );
  const link = useLinkParameters();
  const linkedIndex = tabs.findIndex((tab) => tab === link.tab);
  const initialIndex = Math.max(
    0,
    Math.min(linkedIndex >= 0 ? linkedIndex : initialTab, tabs.length - 1),
  );
  const [selectedTab, setSelectedTab] = useState<ClanInfoTabKey>(
    visibleClanInfoTabs(model.featureFlags).includes(link.tab as ClanInfoTabKey)
      ? (link.tab as ClanInfoTabKey)
      : (tabs[initialIndex] ?? 'members'),
  );
  const [retainedTabs, setRetainedTabs] = useState<readonly ClanInfoTabKey[]>(() => [
    tabs[initialIndex] ?? 'members',
  ]);
  const [joinLeaveLoadSignal, setJoinLeaveLoadSignal] = useState(0);
  const joinLeaveEndArmed = useRef(false);
  const scrollRef = useRef<ScrollViewInstance>(null);
  const scrollOffsets = useRef(new Map<ClanInfoTabKey, number>());
  const activeIndex = Math.max(0, tabs.indexOf(selectedTab));
  const active = tabs[activeIndex] ?? 'members';
  const [historyCache] = useState(() => new Map<string, Promise<unknown>>());
  const historyActions = useMemo<ClanInfoPresentationActions>(() => {
    // Service updates recreate actions. Keep pending tab requests across those
    // renders so a background update cannot restart the same history fetch.
    const cache = historyCache;
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
      loadWarLog: (clan) => cached(`warlog:${clan.tag}`, () => actions.loadWarLog(clan)),
      loadCwlHistory: (tag) => cached(`cwl:${tag}`, () => actions.loadCwlHistory(tag)),
      loadLeaderboardSummary: (tag, type) =>
        cached(`leaderboard:${tag}:${type}`, () => actions.loadLeaderboardSummary(tag, type)),
      loadLegendSummary: (tag) => cached(`legend:${tag}`, () => actions.loadLegendSummary(tag)),
      loadRecords: (tag) => cached(`records:${tag}`, () => actions.loadRecords(tag)),
      loadProfileHistory: (tag) => cached(`profile:${tag}`, () => actions.loadProfileHistory(tag)),
    };
  }, [actions, historyCache]);
  useEffect(() => {
    if (loading) return;
    let active = true;
    const types = Object.values(ClanLeaderboardType);
    // Only fetch the tiny availability summaries here. Retain these promises so
    // opening the tab does not fetch them again. A failed check is not no data.
    void Promise.allSettled(
      types.map((type) => historyActions.loadLeaderboardSummary(model.clan.tag, type)),
    ).then((results) => {
      if (active)
        setHistoryTypes(
          types.filter((_, index) => {
            const result = results[index]!;
            return result.status === 'rejected' || result.value.seasons.length > 0;
          }),
        );
    });
    return () => {
      active = false;
    };
  }, [historyActions, loading, model.clan.tag]);
  const destinations = tabs.map((key) => tabDestination(key, t, theme.onSurfaceVariant));
  const selectTab = (nextIndex: number) => {
    const next = tabs[nextIndex];
    if (!next) return;
    setSelectedTab(next);
    setRetainedTabs((retained) => retainRecentSections(retained, next));
    joinLeaveEndArmed.current = false;
  };
  useEffect(() => {
    const frame = requestAnimationFrame(() => {
      scrollRef.current?.scrollTo({ y: scrollOffsets.current.get(active) ?? 0, animated: false });
    });
    return () => cancelAnimationFrame(frame);
  }, [active]);
  // Each retained tab fetches its own data on first use. Do not compete with
  // the visible war log by eagerly fetching every unrelated history endpoint.
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      <TutorialScrollView
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
          <ClanInfoHeader model={model} actions={actions} selectedTab={active} loading={loading} />
        </View>
        <View
          testID="clan-destination-bar"
          style={[styles.navigation, { backgroundColor: theme.background }]}
        >
          <View
            style={[
              styles.navigationControl,
              layout.isExpanded && { maxWidth: layout.contentMaxWidth, paddingHorizontal: 24 },
            ]}
          >
            {layout.isExpanded ? (
              <ProfileTabs
                variant="underline"
                overflow="scroll"
                tabs={destinations}
                selectedKey={active}
                onSelect={(key) => {
                  const index = tabs.indexOf(key as ClanInfoTabKey);
                  if (index >= 0) selectTab(index);
                }}
              />
            ) : (
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
            )}
          </View>
        </View>
        <SkeletonContent
          loading={loading}
          testID="clan-detail-body"
          style={[styles.tabBody, layout.isExpanded && { maxWidth: layout.contentMaxWidth }]}
        >
          {tabs.map((key) =>
            key === active || retainedTabs.includes(key) ? (
              <View
                key={key}
                testID={`clan-retained-tab-${key}`}
                style={key === active ? undefined : styles.hiddenTab}
              >
                {renderTab(key, model, historyActions, joinLeaveLoadSignal, historyTypes ?? [])}
              </View>
            ) : null,
          )}
        </SkeletonContent>
      </TutorialScrollView>
    </SafeAreaView>
  );
}

function renderTab(
  key: ClanInfoTabKey,
  model: ClanInfoPresentationModel,
  actions: ClanInfoPresentationActions,
  joinLeaveLoadSignal: number,
  historyTypes: readonly ClanLeaderboardTypeValue[],
) {
  if (key === 'members') return <ClanMembersTab model={model} actions={actions} />;
  if (key === 'competitive') return <ClanCompetitiveTab model={model} actions={actions} />;
  if (key === 'warLog') return <ClanWarLogTab model={model} actions={actions} />;
  if (key === 'joinLeave')
    return (
      <ClanJoinLeaveTab model={model} actions={actions} loadMoreSignal={joinLeaveLoadSignal} />
    );
  if (key === 'statistics') return <ClanStatisticsTab model={model} actions={actions} />;
  if (key === 'rankings') return <ClanRankingsTab model={model} actions={actions} />;
  if (key === 'cwlHistory') return <ClanCwlHistoryTab model={model} actions={actions} />;
  if (key === 'leaderboardHistory')
    return (
      <ClanLeaderboardHistoryTab model={model} actions={actions} availableTypes={historyTypes} />
    );
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
  if (key === 'competitive')
    return {
      key,
      label: t('clanLegendsRanked'),
      icon: <MobileWebImage imageUrl={ImageAssets.legendLeagueOne} style={styles.tabImage} />,
    };
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
    return {
      key,
      label: t('cwlHistoryTitle'),
      icon: <MobileWebImage imageUrl={ImageAssets.cwlSwordsNoBorder} style={styles.tabImage} />,
    };
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
    label: t('clanRecordsChangesTab'),
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
