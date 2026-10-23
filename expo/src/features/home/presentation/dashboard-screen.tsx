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
import type { FlatList } from 'react-native-gesture-handler';
import { runOnJS, useFrameCallback, useSharedValue } from 'react-native-reanimated';
import DraggableFlatList, {
  type DraggableFlatListProps,
  type RenderItemParams,
} from 'react-native-draggable-flatlist';
import { EyeOff, UserCircle } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { toIntlLocale, useI18n } from '../../../i18n';
import { EmptyState, centeredContentPadding, ckSpacing, useCKTheme } from '../../../ui';
import { PullRefreshHint, usePullRefreshHint } from '../../../ui/pull-refresh-hint';
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
type HomeDragValues = Parameters<
  NonNullable<DraggableFlatListProps<HomeCardId>['onAnimValInit']>
>[0];
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
  const dragValues = useRef<HomeDragValues | null>(null);
  const lastScrollOffset = useRef(0);
  const list = useRef<FlatList<HomeCardId>>(null);
  const [animationValues, setAnimationValues] = useState<HomeDragValues | null>(null);
  const [dragging, setDragging] = useState(false);
  const [dragLayoutRevision, setDragLayoutRevision] = useState(0);
  const holdPageY = useSharedValue(0);
  const listPageY = useSharedValue(0);
  const lastAutoScroll = useSharedValue(0);
  const scrollToOffset = useCallback((offset: number) => {
    list.current?.scrollToOffset({ offset, animated: false });
  }, []);
  const autoScroll = useFrameCallback((frame) => {
    // Home widgets can be taller than the viewport. Their bounds must not
    // trigger automatic scrolling while a finger is stationary in the middle.
    // Wait for deliberate movement, then use the finger's viewport position.
    if (
      !animationValues ||
      !animationValues.isTouchActiveNative.value ||
      animationValues.activeIndexAnim.value < 0 ||
      Math.abs(animationValues.touchTranslate.value) < 8
    ) {
      lastAutoScroll.value = 0;
      return;
    }
    const y = holdPageY.value + animationValues.touchTranslate.value - listPageY.value;
    const height = animationValues.containerSize.value;
    const edge = 48;
    const direction =
      y < edge
        ? -Math.min(1, (edge - y) / edge)
        : y > height - edge
          ? Math.min(1, (y - height + edge) / edge)
          : 0;
    if (!direction || height <= 0) {
      lastAutoScroll.value = 0;
      return;
    }
    if (!lastAutoScroll.value) {
      lastAutoScroll.value = frame.timestamp;
      return;
    }
    const elapsed = frame.timestamp - lastAutoScroll.value;
    if (elapsed < 32) return;
    lastAutoScroll.value = frame.timestamp;
    const offset = animationValues.scrollOffset.value;
    const maxOffset = Math.max(0, animationValues.scrollViewSize.value - height);
    const next = Math.max(
      0,
      Math.min(maxOffset, offset + (direction * 360 * Math.min(elapsed, 64)) / 1000),
    );
    if (Math.abs(next - offset) > 0.5) runOnJS(scrollToOffset)(next);
  }, false);
  useEffect(() => {
    autoScroll.setActive(dragging);
    return () => autoScroll.setActive(false);
  }, [autoScroll, dragging]);
  const holdEpoch = useRef(0);
  const cancelPendingHolds = () => {
    holdEpoch.current += 1;
  };
  const desktop = isDesktopHome(platform, windowWidth);
  const horizontal = centeredContentPadding(
    contentWidth,
    desktop ? homeContentWidth(windowWidth) : 840,
  );
  const cards = visibleHomeCards(model);
  // The native list holds translated cell positions until another onLayout.
  // On iPad, a reorder or rotation can leave equal-size cells without that
  // callback, retaining a card-sized hole. Start fresh native measurements for
  // each committed order/width, while retaining page state and scroll position.
  // Keep the established phone and web list lifecycle unchanged.
  const listLayoutKey =
    Platform.OS === 'ios' && Platform.isPad
      ? `ipad:${Math.round(contentWidth)}:${cards.join(',')}:${dragLayoutRevision}`
      : 'home';
  useEffect(() => {
    if (Platform.OS !== 'ios' || !Platform.isPad) return;
    holdEpoch.current += 1;
    const offset = lastScrollOffset.current;
    const frame = requestAnimationFrame(() => {
      setDragging(false);
      list.current?.scrollToOffset({ offset, animated: false });
    });
    return () => cancelAnimationFrame(frame);
  }, [listLayoutKey]);
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
        key={listLayoutKey}
        ref={list}
        testID="home-scroll-view"
        data={cards}
        keyExtractor={(card) => card}
        activationDistance={8}
        // Tall or partially visible widgets must not jump to fit the viewport
        // when picked up. Preserve their grabbed position, even beyond its edge.
        dragItemOverflow
        autoscrollSpeed={0}
        onAnimValInit={(values) => {
          dragValues.current = values;
          setAnimationValues(values);
        }}
        onContainerLayout={({ containerRef }) => {
          containerRef.current?.measureInWindow((_x, y) => {
            listPageY.value = y;
          });
        }}
        onDragBegin={() => setDragging(true)}
        onRelease={() => setDragging(false)}
        onTouchEnd={cancelPendingHolds}
        onTouchCancel={cancelPendingHolds}
        alwaysBounceVertical
        contentContainerStyle={{
          paddingHorizontal: horizontal,
          paddingBottom: homeBottomPadding(desktop, insets.bottom),
        }}
        ListHeaderComponent={header}
        ListEmptyComponent={emptyBody}
        ItemSeparatorComponent={HomeCardSeparator}
        refreshControl={refreshControl}
        onScrollOffsetChange={(offset) => {
          lastScrollOffset.current = offset;
          pullRefresh.onScrollOffsetChange(offset);
        }}
        onScrollBeginDrag={() => {
          cancelPendingHolds();
          pullRefresh.onScrollBeginDrag();
        }}
        onScrollEndDrag={pullRefresh.onScrollEndDrag}
        onDragEnd={({ data, from, to }) => {
          setDragging(false);
          // Also discard held transforms after a drop back in the original slot.
          if (Platform.OS === 'ios' && Platform.isPad)
            setDragLayoutRevision((revision) => revision + 1);
          if (from === to) return;
          // The shared list owns offsets and completes its native settling before
          // this callback. Do not keep a second JS/native transform map for Home.
          if (actions.reorderCards(data) !== false)
            requestAnimationFrame(() => tutorials.event('card-reordered'));
        }}
        renderItem={({ item, getIndex, drag, isActive }: RenderItemParams<HomeCardId>) => (
          <HomeCardHold
            onHold={
              cards.length > 1
                ? (position) => {
                    holdPageY.value = position.y;
                    lastAutoScroll.value = 0;
                    if (dragValues.current) dragValues.current.touchTranslate.value = 0;
                    drag();
                  }
                : undefined
            }
            active={isActive}
            getEpoch={() => holdEpoch.current}
            canStart={() =>
              Platform.OS === 'web' || dragValues.current?.isTouchActiveNative.value === true
            }
          >
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
  getEpoch,
  canStart,
  children,
}: {
  onHold?: (position: { x: number; y: number }) => void;
  active: boolean;
  getEpoch: () => number;
  canStart: () => boolean;
  children: React.ReactNode;
}) {
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const origin = useRef<{ x: number; y: number } | null>(null);
  const touchDown = useRef(false);
  const sequence = useRef(0);
  const callback = useRef(onHold);
  useEffect(() => {
    callback.current = onHold;
  }, [onHold]);
  const cancel = useCallback(() => {
    sequence.current += 1;
    touchDown.current = false;
    if (timer.current) clearTimeout(timer.current);
    timer.current = null;
    origin.current = null;
  }, []);
  useEffect(() => cancel, [cancel]);
  useEffect(() => {
    if (active) cancel();
  }, [active, cancel]);
  useEffect(() => {
    const subscription = AppState.addEventListener('change', (state) => {
      if (state !== 'active') cancel();
    });
    return () => subscription.remove();
  }, [cancel]);
  const startHold = (x: number, y: number) => {
    cancel();
    if (active || !onHold) return;
    touchDown.current = true;
    origin.current = { x, y };
    const touchSequence = sequence.current;
    const epoch = getEpoch();
    timer.current = setTimeout(() => {
      timer.current = null;
      // A delayed JS callback must never arm the list after a tap has ended.
      // Check both this exact touch and the list's native touch state. Movement,
      // release, scrolling, cancellation and a new touch invalidate the hold.
      if (
        touchSequence !== sequence.current ||
        !touchDown.current ||
        !origin.current ||
        epoch !== getEpoch() ||
        !canStart()
      )
        return;
      callback.current?.(origin.current);
    }, CARD_REORDER_HOLD_MS);
  };
  const start = (event: GestureResponderEvent) => {
    if (event.nativeEvent.touches.length !== 1) {
      cancel();
      return;
    }
    startHold(event.nativeEvent.pageX, event.nativeEvent.pageY);
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
          ? (event) => startHold(event.nativeEvent.pageX, event.nativeEvent.pageY)
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
