import { PullRefreshHint, usePullRefreshHint } from '../../../ui/pull-refresh-hint';
import { useCallback, useRef, useState, type ReactNode } from 'react';
import {
  Animated,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
  type LayoutChangeEvent,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { EyeOff, GripVertical, UserCircle } from 'lucide-react-native';
import DraggableFlatList, { ScaleDecorator } from 'react-native-draggable-flatlist';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  centeredContentPadding,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
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

type HomeCardLayout = { y: number; height: number };

const homeCardTranslations = () => ({
  todo: new Animated.Value(0),
  ranked: new Animated.Value(0),
  upgrade: new Animated.Value(0),
});

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
  const [draggingCard, setDraggingCard] = useState<HomeCardId | null>(null);
  const draggingCardRef = useRef<HomeCardId | null>(null);
  const dragTargetIndexRef = useRef<number | null>(null);
  const [cardLayouts, setCardLayouts] = useState<Partial<Record<HomeCardId, HomeCardLayout>>>({});
  const [cardTranslations] = useState(homeCardTranslations);
  const recordCardLayout = useCallback((card: HomeCardId, layout: HomeCardLayout) => {
    setCardLayouts((current) => ({ ...current, [card]: layout }));
  }, []);

  const resetCardTranslations = useCallback(
    (animated: boolean) => {
      Object.values(cardTranslations).forEach((translation) => {
        translation.stopAnimation();
        if (animated) {
          Animated.spring(translation, {
            toValue: 0,
            useNativeDriver: true,
            speed: 28,
            bounciness: 1,
          }).start();
        } else {
          translation.setValue(0);
        }
      });
    },
    [cardTranslations],
  );

  const startAndroidDrag = useCallback(
    (card: HomeCardId) => {
      const index = cards.indexOf(card);
      if (index < 0) return;
      resetCardTranslations(false);
      draggingCardRef.current = card;
      dragTargetIndexRef.current = index;
      setDraggingCard(card);
    },
    [cards, resetCardTranslations],
  );

  const updateAndroidDrag = useCallback(
    (card: HomeCardId, translationY: number) => {
      if (draggingCardRef.current !== card) return;
      const source = cards.indexOf(card);
      const sourceLayout = cardLayouts[card];
      if (source < 0 || !sourceLayout) return;

      cardTranslations[card].setValue(translationY);
      const activeCenter = sourceLayout.y + sourceLayout.height / 2 + translationY;
      let target = source;
      if (translationY > 0) {
        for (let index = source + 1; index < cards.length; index += 1) {
          const layout = cardLayouts[cards[index]!];
          if (layout && activeCenter > layout.y + layout.height / 2) target = index;
        }
      } else if (translationY < 0) {
        for (let index = source - 1; index >= 0; index -= 1) {
          const layout = cardLayouts[cards[index]!];
          if (layout && activeCenter < layout.y + layout.height / 2) target = index;
        }
      }

      if (dragTargetIndexRef.current === target) return;
      dragTargetIndexRef.current = target;
      const nextLayout = cards[source + 1] ? cardLayouts[cards[source + 1]!] : undefined;
      const previousLayout = cards[source - 1] ? cardLayouts[cards[source - 1]!] : undefined;
      const gap = nextLayout
        ? Math.max(0, nextLayout.y - sourceLayout.y - sourceLayout.height)
        : previousLayout
          ? Math.max(0, sourceLayout.y - previousLayout.y - previousLayout.height)
          : 0;
      const displacement = sourceLayout.height + gap;

      cards.forEach((item, index) => {
        if (item === card) return;
        const toValue =
          source < target && index > source && index <= target
            ? -displacement
            : source > target && index >= target && index < source
              ? displacement
              : 0;
        Animated.spring(cardTranslations[item], {
          toValue,
          useNativeDriver: true,
          speed: 24,
          bounciness: 2,
        }).start();
      });
    },
    [cardLayouts, cardTranslations, cards],
  );

  const finishAndroidDrag = useCallback(
    (card: HomeCardId, translationY: number) => {
      updateAndroidDrag(card, translationY);
      if (draggingCardRef.current !== card) return;
      const source = cards.indexOf(card);
      const target = dragTargetIndexRef.current ?? source;
      draggingCardRef.current = null;
      dragTargetIndexRef.current = null;
      setDraggingCard(null);
      resetCardTranslations(false);
      if (source < 0 || target === source) return;
      const next = [...cards];
      next.splice(source, 1);
      next.splice(target, 0, card);
      actions.reorderCards(next);
    },
    [actions, cards, resetCardTranslations, updateAndroidDrag],
  );

  const cancelAndroidDrag = useCallback(
    (card: HomeCardId) => {
      if (draggingCardRef.current !== card) return;
      draggingCardRef.current = null;
      dragTargetIndexRef.current = null;
      setDraggingCard(null);
      resetCardTranslations(true);
    },
    [resetCardTranslations],
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
    dragHandle?: ReactNode,
    isActive = false,
    animatedStyle?: StyleProp<ViewStyle>,
    onLayout?: (event: LayoutChangeEvent) => void,
  ) => {
    const title = homeCardTitle(card, t);
    return (
      <Animated.View
        key={card}
        onLayout={onLayout}
        style={[
          styles.recap,
          desktop && { maxWidth: homeRecapWidth(windowWidth), alignSelf: 'center' },
          index > 0 ? { marginTop: desktop ? ckSpacing.lg : ckSpacing.md } : undefined,
          isActive && styles.activeCard,
          animatedStyle,
        ]}
        testID={`home-card-shell-${card}`}
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
          <HomeTodoCard model={model.todo} desktop={desktop} actions={actions} />
        ) : card === 'ranked' && model.ranked ? (
          <HomeRankedCard model={model.ranked} desktop={desktop} actions={actions} />
        ) : card === 'upgrade' && model.upgrade ? (
          <HomeUpgradeCard model={model.upgrade} desktop={desktop} actions={actions} />
        ) : null}
        {dragHandle}
      </Animated.View>
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
          scrollEnabled={draggingCard === null}
          scrollEventThrottle={16}
          testID="home-scroll-view"
        >
          {header}
          {cards.length
            ? cards.map((card, index) =>
                renderCard(
                  card,
                  index,
                  cards.length > 1 ? (
                    <AndroidHomeCardDragHandle
                      card={card}
                      label={t('upgradeTrackerPlanReorder', {
                        category: homeCardTitle(card, t),
                      })}
                      onCancel={cancelAndroidDrag}
                      onEnd={finishAndroidDrag}
                      onStart={startAndroidDrag}
                      onUpdate={updateAndroidDrag}
                    />
                  ) : undefined,
                  draggingCard === card,
                  {
                    transform: [{ translateY: cardTranslations[card] }],
                    zIndex: draggingCard === card ? 2 : 0,
                  },
                  (event) => recordCardLayout(card, event.nativeEvent.layout),
                ),
              )
            : emptyContent}
        </ScrollView>
      ) : (
        <DraggableFlatList
          activationDistance={4}
          alwaysBounceVertical
          contentContainerStyle={contentContainerStyle}
          data={cards}
          keyExtractor={(card) => card}
          ListEmptyComponent={emptyContent}
          ListHeaderComponent={header}
          onDragEnd={({ data }) => actions.reorderCards(data)}
          onScrollBeginDrag={pullRefresh.onScrollBeginDrag}
          onScrollEndDrag={pullRefresh.onScrollEndDrag}
          onScrollOffsetChange={pullRefresh.onScrollOffsetChange}
          refreshControl={refreshControl}
          renderItem={({ item: card, drag, isActive, getIndex }) => (
            <ScaleDecorator activeScale={1.012}>
              {renderCard(
                card,
                getIndex() ?? 0,
                cards.length > 1 ? (
                  <HomeCardDragHandle
                    label={t('upgradeTrackerPlanReorder', {
                      category: homeCardTitle(card, t),
                    })}
                    onLongPress={drag}
                    testID={`home-card-drag-${card}`}
                  />
                ) : undefined,
                isActive,
              )}
            </ScaleDecorator>
          )}
          scrollEnabled
          testID="home-draggable-list"
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

function HomeCardDragHandle({
  label,
  onLongPress,
  testID,
}: {
  label: string;
  onLongPress?: () => void;
  testID: string;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityLabel={label}
      accessibilityRole="button"
      delayLongPress={140}
      hitSlop={8}
      onLongPress={onLongPress}
      onPress={(event) => event.stopPropagation()}
      style={({ pressed }) => [
        styles.dragHandle,
        pressed && { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.8) },
      ]}
      testID={testID}
    >
      <GripVertical color={theme.onSurfaceVariant} opacity={0.58} size={14} strokeWidth={2.2} />
    </Pressable>
  );
}

function AndroidHomeCardDragHandle({
  card,
  label,
  onStart,
  onUpdate,
  onEnd,
  onCancel,
}: {
  card: HomeCardId;
  label: string;
  onStart: (card: HomeCardId) => void;
  onUpdate: (card: HomeCardId, translationY: number) => void;
  onEnd: (card: HomeCardId, translationY: number) => void;
  onCancel: (card: HomeCardId) => void;
}) {
  const theme = useCKTheme();
  const gesture = Gesture.Pan()
    .minDistance(2)
    .hitSlop(8)
    .shouldCancelWhenOutside(false)
    .runOnJS(true)
    .onStart(() => onStart(card))
    .onUpdate((event) => onUpdate(card, event.translationY))
    .onEnd((event) => onEnd(card, event.translationY))
    .onFinalize(() => onCancel(card));

  return (
    <GestureDetector gesture={gesture}>
      <Pressable
        accessibilityLabel={label}
        accessibilityRole="button"
        hitSlop={8}
        onPress={(event) => event.stopPropagation()}
        style={({ pressed }) => [
          styles.dragHandle,
          pressed && { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.8) },
        ]}
        testID={`home-card-drag-${card}`}
      >
        <GripVertical color={theme.onSurfaceVariant} opacity={0.58} size={14} strokeWidth={2.2} />
      </Pressable>
    </GestureDetector>
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
  recap: { width: '100%', position: 'relative' },
  activeCard: { opacity: 0.96 },
  sectionTitle: { fontWeight: '900' },
  sectionGap: { height: ckSpacing.sm },
  mobileGap: { height: 16 },
  dragHandle: {
    position: 'absolute',
    top: 0,
    right: 6,
    zIndex: 4,
    width: 28,
    height: 28,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
  },
  empty: { paddingHorizontal: 24, paddingVertical: 52 },
});
