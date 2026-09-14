import { PullRefreshHint, usePullRefreshHint } from '../../../ui/pull-refresh-hint';
import { useCallback, useRef, useState } from 'react';
import {
  Platform,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { EyeOff, UserCircle } from 'lucide-react-native';
import DraggableFlatList, { ScaleDecorator } from 'react-native-draggable-flatlist';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { toIntlLocale, useI18n } from '../../../i18n';
import { CKText, EmptyState, centeredContentPadding, ckSpacing, useCKTheme } from '../../../ui';
import {
  homeContentWidth,
  homeRecapWidth,
  isDesktopHome,
  visibleHomeCards,
  type HomeCardId,
  type HomeDashboardActions,
  type HomeDashboardModel,
  type HomePlatform,
} from './contracts';
import { HomeEventBanner } from './event-banner';
import { HomeCardSkeleton } from './home-components';
import { HomeRankedCard, HomeTodoCard, HomeUpgradeCard } from './home-cards';

export const MOBILE_HOME_OVERLAY_CLEARANCE = 96;

export function homeBottomPadding(desktop: boolean, bottomInset: number): number {
  return desktop ? 32 : bottomInset + MOBILE_HOME_OVERLAY_CLEARANCE;
}

export function DashboardScreen({
  model,
  actions,
  platform = Platform.OS as HomePlatform,
}: {
  model: HomeDashboardModel;
  actions: HomeDashboardActions;
  platform?: HomePlatform;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width: windowWidth } = useWindowDimensions();
  const [contentWidth, setContentWidth] = useState(windowWidth);
  const desktop = isDesktopHome(platform, windowWidth);
  const usesNativeRefreshScroll = platform === 'android';
  const maxContent = desktop ? homeContentWidth(windowWidth) : 840;
  const horizontal = centeredContentPadding(contentWidth, maxContent);
  const [refreshing, setRefreshing] = useState(false);
  const refreshingRef = useRef(false);
  const refresh = useCallback(async () => {
    if (refreshingRef.current) return;
    refreshingRef.current = true;
    setRefreshing(true);
    try {
      await actions.refresh();
    } catch (error) {
      actions.showRefreshError(t('generalRefreshFailed', { error: String(error) }));
    } finally {
      refreshingRef.current = false;
      setRefreshing(false);
    }
  }, [actions, t]);
  const pullRefresh = usePullRefreshHint({
    onRefresh: () => void refresh(),
    refreshing,
    showOnAndroid: true,
  });
  const cards = visibleHomeCards(model);
  let emptyBody;
  if (model.loading && model.linkedAccountCount === 0)
    emptyBody = (
      <>
        <HomeCardSkeleton rows={1} />
        <View style={styles.mobileGap} />
        <HomeCardSkeleton rows={2} />
      </>
    );
  else if (model.linkedAccountCount === 0)
    emptyBody = (
      <EmptyState
        title={t('dashboardNoLinkedAccountsTitle')}
        body={t('dashboardNoLinkedAccountsBody')}
        icon={<UserCircle color={theme.onSurfaceVariant} />}
        actionLabel={t('drawerManageAccounts')}
        onAction={actions.openManageAccounts}
        style={styles.empty}
      />
    );
  else if (cards.length === 0)
    emptyBody = (
      <EmptyState
        title={t('dashboardTodoHiddenTitle')}
        body={t('dashboardTodoHiddenBody')}
        icon={<EyeOff color={theme.onSurfaceVariant} />}
        style={styles.empty}
      />
    );
  const contentContainerStyle = {
    paddingHorizontal: horizontal,
    paddingBottom: homeBottomPadding(desktop, insets.bottom),
  };
  const header = (
    <>
      <HomeEventBanner
        announcements={model.announcements}
        desktop={desktop}
        onOpen={actions.openAnnouncement}
      />
      <View style={{ height: desktop ? 24 : 16 }} />
    </>
  );
  const refreshControl = (
    <RefreshControl
      colors={[theme.primary]}
      progressBackgroundColor={theme.surface}
      progressViewOffset={insets.top}
      refreshing={refreshing}
      tintColor={theme.primary}
      onRefresh={() => void refresh()}
    />
  );
  const renderCard = (
    card: HomeCardId,
    index: number,
    isActive = false,
    dragProps?: { onLongPress: () => void; dragTestID: string },
  ) => {
    const title = homeCardTitle(card, t);
    const cardDragProps = dragProps ?? {};
    return (
      <View
        key={card}
        style={[
          styles.recap,
          desktop && { maxWidth: homeRecapWidth(windowWidth), alignSelf: 'center' },
          index > 0 ? { marginTop: desktop ? ckSpacing.lg : ckSpacing.md } : undefined,
          isActive && styles.activeCard,
        ]}
      >
        {desktop ? (
          <>
            <CKText role="titleMedium" style={styles.sectionTitle}>
              {title}
            </CKText>
            <View style={styles.sectionGap} />
          </>
        ) : null}
        {card === 'todo' && model.todo ? (
          <HomeTodoCard model={model.todo} desktop={desktop} actions={actions} {...cardDragProps} />
        ) : card === 'ranked' && model.ranked ? (
          <HomeRankedCard
            model={model.ranked}
            desktop={desktop}
            actions={actions}
            {...cardDragProps}
          />
        ) : card === 'upgrade' && model.upgrade ? (
          <HomeUpgradeCard
            model={model.upgrade}
            desktop={desktop}
            actions={actions}
            {...cardDragProps}
          />
        ) : null}
      </View>
    );
  };
  const emptyContent = (
    <View
      style={[
        styles.recap,
        desktop && { maxWidth: homeRecapWidth(windowWidth), alignSelf: 'center' },
      ]}
    >
      {emptyBody}
    </View>
  );
  return (
    <SafeAreaView
      edges={['left', 'right']}
      onLayout={(event) => setContentWidth(event.nativeEvent.layout.width)}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      {usesNativeRefreshScroll ? (
        <ScrollView
          alwaysBounceVertical
          contentContainerStyle={contentContainerStyle}
          onScroll={pullRefresh.onScroll}
          onScrollBeginDrag={pullRefresh.onScrollBeginDrag}
          onScrollEndDrag={pullRefresh.onScrollEndDrag}
          refreshControl={refreshControl}
          scrollEventThrottle={16}
          testID="home-scroll-view"
        >
          {header}
          {cards.length ? cards.map((card, index) => renderCard(card, index)) : emptyContent}
        </ScrollView>
      ) : (
        <DraggableFlatList
          onScrollOffsetChange={pullRefresh.onScrollOffsetChange}
          onScrollBeginDrag={pullRefresh.onScrollBeginDrag}
          onScrollEndDrag={pullRefresh.onScrollEndDrag}
          activationDistance={24}
          alwaysBounceVertical
          data={cards}
          keyExtractor={(card) => card}
          onDragEnd={({ data }) => actions.reorderCards(data)}
          scrollEnabled
          contentContainerStyle={contentContainerStyle}
          ListEmptyComponent={emptyContent}
          ListHeaderComponent={header}
          refreshControl={refreshControl}
          renderItem={({ item: card, drag, isActive, getIndex }) => {
            const index = getIndex() ?? 0;
            const dragProps = { onLongPress: drag, dragTestID: `home-card-${card}` };
            return (
              <ScaleDecorator activeScale={1.015}>
                {renderCard(card, index, isActive, dragProps)}
              </ScaleDecorator>
            );
          }}
        />
      )}
      <PullRefreshHint
        distance={pullRefresh.distance}
        refreshing={refreshing}
        label={
          model.lastRefresh
            ? t('generalLastRefresh', {
                time: formatLastRefresh(model.lastRefresh, new Date(), t, locale),
              })
            : undefined
        }
      />
    </SafeAreaView>
  );
}

function homeCardTitle(card: HomeCardId, t: ReturnType<typeof useI18n>['t']): string {
  if (card === 'todo') return t('todoTitle');
  if (card === 'ranked') return t('rankedLeagueTitle');
  return t('drawerUpgradeTracker');
}

export function formatLastRefresh(
  lastRefresh: Date,
  now: Date,
  t: ReturnType<typeof useI18n>['t'],
  locale?: string,
): string {
  const minutes = Math.floor((now.getTime() - lastRefresh.getTime()) / 60000);
  if (minutes < 1) return t('timeJustNow');
  if (minutes < 60) return t('timeMinutesAgo', { minutes });
  if (minutes < 1440) return t('timeHoursAgo', { hours: Math.floor(minutes / 60) });
  return lastRefresh.toLocaleString(locale ? toIntlLocale(locale) : undefined, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  });
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  recap: { width: '100%' },
  activeCard: { opacity: 0.94 },
  sectionTitle: { fontWeight: '900' },
  sectionGap: { height: ckSpacing.sm },
  mobileGap: { height: 16 },
  empty: { paddingHorizontal: 24, paddingVertical: 52 },
});
