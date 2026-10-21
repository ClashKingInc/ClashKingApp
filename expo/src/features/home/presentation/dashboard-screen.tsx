import { useCallback, useEffect, useRef, useState } from 'react';
import {
  AppState,
  Platform,
  RefreshControl,
  StyleSheet,
  View,
  useWindowDimensions,
  type NativeTouchEvent,
  type GestureResponderEvent,
} from 'react-native';
import DraggableFlatList, { type RenderItemParams } from 'react-native-draggable-flatlist';
import { EyeOff, UserCircle } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { toIntlLocale, useI18n } from '../../../i18n';
import { EmptyState, centeredContentPadding, ckSpacing, useCKTheme } from '../../../ui';
import { PullRefreshHint, usePullRefreshHint } from '../../../ui/pull-refresh-hint';
import { CardAppearanceProvider } from '../../../ui/card-appearance';
import { CARD_REORDER_HOLD_MS, DragJiggle } from '../../../ui/drag-jiggle';
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
import { HomeCardSkeleton, HomeDragContext } from './home-components';
import { HomeRankedCard, HomeTodoCard, HomeUpgradeCard } from './home-cards';
import { HomeActivityCard } from './home-activity-card';
import { tutorials } from '../../tutorials/tutorial-service';
import { TutorialTarget } from '../../tutorials/tutorial-ui';

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
  const theme = useCKTheme(),
    insets = useSafeAreaInsets();
  const { width: windowWidth } = useWindowDimensions();
  const [contentWidth, setContentWidth] = useState(windowWidth);
  const [cardAccounts, setCardAccounts] = useState<Partial<Record<HomeCardId, string>>>({});
  const [refreshing, setRefreshing] = useState(false);
  const refreshingRef = useRef(false);
  const desktop = isDesktopHome(platform, windowWidth);
  const horizontal = centeredContentPadding(
    contentWidth,
    desktop ? homeContentWidth(windowWidth) : 840,
  );
  const cards = visibleHomeCards(model);
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
  const header = (
    <>
      <HomeEventBanner
        announcements={model.announcements}
        desktop={desktop}
        onOpen={actions.openAnnouncement}
      />
      <View style={{ height: ckSpacing.lg }} />
    </>
  );
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
  else
    emptyBody = (
      <EmptyState
        title={t('dashboardTodoHiddenTitle')}
        body={t('dashboardTodoHiddenBody')}
        icon={<EyeOff color={theme.onSurfaceVariant} />}
        style={styles.empty}
      />
    );
  const renderCard = (card: HomeCardId, index: number, isActive = false) => {
    const cardActions = {
      ...actions,
      selectAccount: (tag: string) => setCardAccounts((current) => ({ ...current, [card]: tag })),
    };
    return (
      <View
        style={[
          styles.recap,
          desktop && { maxWidth: homeRecapWidth(windowWidth), alignSelf: 'center' },
          isActive && styles.activeCard,
        ]}
        testID={`home-card-shell-${card}`}
      >
        <TutorialTarget id="home-reorder" enabled={index === 0} style={{ width: '100%' }}>
          <DragJiggle active={isActive} scale={1.015}>
            <HomeDragContext.Provider value={isActive}>
              <CardAppearanceProvider value={index === 0 ? 'glow' : 'edge'}>
                {card === 'activity' && model.activityAccounts ? (
                  <HomeActivityCard
                    accounts={model.activityAccounts}
                    refreshKey={model.lastRefresh?.toISOString()}
                  />
                ) : card === 'todo' && model.todo ? (
                  <HomeTodoCard
                    model={model.todo}
                    selectedAccountTag={cardAccounts[card] ?? model.selectedAccountTag}
                    desktop={desktop}
                    actions={cardActions}
                  />
                ) : card === 'ranked' && model.ranked ? (
                  <HomeRankedCard
                    model={model.ranked}
                    selectedAccountTag={cardAccounts[card] ?? model.selectedAccountTag}
                    desktop={desktop}
                    actions={cardActions}
                  />
                ) : card === 'upgrade' && model.upgrade ? (
                  <HomeUpgradeCard
                    model={model.upgrade}
                    selectedAccountTag={cardAccounts[card] ?? model.selectedAccountTag}
                    desktop={desktop}
                    actions={cardActions}
                  />
                ) : null}
              </CardAppearanceProvider>
            </HomeDragContext.Provider>
          </DragJiggle>
        </TutorialTarget>
      </View>
    );
  };
  return (
    <SafeAreaView
      edges={['left', 'right']}
      onLayout={(event) => setContentWidth(event.nativeEvent.layout.width)}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      <DraggableFlatList
        testID="home-scroll-view"
        data={cards}
        keyExtractor={(card) => card}
        activationDistance={8}
        alwaysBounceVertical
        contentContainerStyle={{
          paddingHorizontal: horizontal,
          paddingBottom: homeBottomPadding(desktop, insets.bottom),
        }}
        ListHeaderComponent={header}
        ListEmptyComponent={emptyBody}
        ItemSeparatorComponent={HomeCardSeparator}
        refreshControl={refreshControl}
        onScrollOffsetChange={pullRefresh.onScrollOffsetChange}
        onScrollBeginDrag={pullRefresh.onScrollBeginDrag}
        onScrollEndDrag={pullRefresh.onScrollEndDrag}
        onDragEnd={({ data, from, to }) => {
          if (from === to) return;
          // The shared list owns offsets and completes its native settling before
          // this callback. Do not keep a second JS/native transform map for Home.
          if (actions.reorderCards(data) !== false)
            requestAnimationFrame(() => tutorials.event('card-reordered'));
        }}
        renderItem={({ item, getIndex, drag, isActive }: RenderItemParams<HomeCardId>) => (
          <HomeCardHold onHold={cards.length > 1 ? drag : undefined} active={isActive}>
            {renderCard(item, getIndex() ?? 0, isActive)}
          </HomeCardHold>
        )}
      />
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

function HomeCardSeparator() {
  return <View style={{ height: ckSpacing.md }} />;
}

/** Observe bubbled touches without stealing card buttons or horizontal pagers.
 * Cancel a pending hold as soon as the user starts scrolling. The shared list
 * takes ownership only after the same 300ms hold used by Players and Clans. */
function HomeCardHold({
  onHold,
  active,
  children,
}: {
  onHold?: () => void;
  active: boolean;
  children: React.ReactNode;
}) {
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const origin = useRef<{ x: number; y: number } | null>(null);
  const callback = useRef(onHold);
  useEffect(() => {
    callback.current = onHold;
  }, [onHold]);
  const cancel = useCallback(() => {
    if (timer.current) clearTimeout(timer.current);
    timer.current = null;
    origin.current = null;
  }, []);
  useEffect(() => cancel, [cancel]);
  useEffect(() => {
    const subscription = AppState.addEventListener('change', state => {
      if (state !== 'active') cancel();
    });
    return () => subscription.remove();
  }, [cancel]);
  const start = (event: GestureResponderEvent) => {
    cancel();
    if (active || !onHold || event.nativeEvent.touches.length !== 1) return;
    origin.current = { x: event.nativeEvent.pageX, y: event.nativeEvent.pageY };
    timer.current = setTimeout(() => {
      timer.current = null;
      callback.current?.();
    }, CARD_REORDER_HOLD_MS);
  };
  const startPointer = (x: number, y: number) => {
    cancel();
    if (active || !onHold) return;
    origin.current = { x, y };
    timer.current = setTimeout(() => {
      timer.current = null;
      callback.current?.();
    }, CARD_REORDER_HOLD_MS);
  };
  const move = ({ nativeEvent }: { nativeEvent: NativeTouchEvent }) => {
    if (
      timer.current &&
      origin.current &&
      (Math.abs(nativeEvent.pageX - origin.current.x) > 8 ||
        Math.abs(nativeEvent.pageY - origin.current.y) > 8)
    )
      cancel();
  };
  return (
    <View
      collapsable={false}
      onTouchStart={start}
      onTouchMove={move}
      onTouchEnd={cancel}
      onTouchCancel={cancel}
      onPointerDown={
        Platform.OS === 'web'
          ? (event) => startPointer(event.nativeEvent.pageX, event.nativeEvent.pageY)
          : undefined
      }
      onPointerMove={
        Platform.OS === 'web'
          ? (event) => {
              if (
                timer.current &&
                origin.current &&
                (Math.abs(event.nativeEvent.pageX - origin.current.x) > 8 ||
                  Math.abs(event.nativeEvent.pageY - origin.current.y) > 8)
              )
                cancel();
            }
          : undefined
      }
      onPointerUp={Platform.OS === 'web' ? cancel : undefined}
      onPointerCancel={Platform.OS === 'web' ? cancel : undefined}
    >
      {children}
    </View>
  );
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
  recap: { width: '100%', position: 'relative' },
  activeCard: { opacity: 0.96 },
  mobileGap: { height: 16 },
  empty: { paddingHorizontal: 24, paddingVertical: 52 },
});
