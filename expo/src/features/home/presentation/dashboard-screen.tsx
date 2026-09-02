import { useEffect, useState } from 'react';
import {
  Platform,
  Pressable,
  RefreshControl,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { EyeOff, GripVertical, RefreshCw, UserCircle } from 'lucide-react-native';
import {
  NestableDraggableFlatList,
  NestableScrollContainer,
  ScaleDecorator,
} from 'react-native-draggable-flatlist';
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
  const { t } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width: windowWidth } = useWindowDimensions();
  const [contentWidth, setContentWidth] = useState(windowWidth);
  const desktop = isDesktopHome(platform, windowWidth);
  const maxContent = desktop ? homeContentWidth(windowWidth) : 840;
  const horizontal = centeredContentPadding(contentWidth, maxContent);
  const [refreshing, setRefreshing] = useState(false);
  const refresh = async () => {
    setRefreshing(true);
    try {
      await actions.refresh();
    } catch (error) {
      actions.showRefreshError(t('generalRefreshFailed', { error: String(error) }));
    } finally {
      setRefreshing(false);
    }
  };
  const cards = visibleHomeCards(model);
  let body;
  if (model.loading && model.linkedAccountCount === 0)
    body = (
      <>
        <HomeCardSkeleton rows={1} />
        <View style={styles.mobileGap} />
        <HomeCardSkeleton rows={2} />
      </>
    );
  else if (model.linkedAccountCount === 0)
    body = (
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
    body = (
      <EmptyState
        title={t('dashboardTodoHiddenTitle')}
        body={t('dashboardTodoHiddenBody')}
        icon={<EyeOff color={theme.onSurfaceVariant} />}
        style={styles.empty}
      />
    );
  else
    body = (
      <View
        style={[
          styles.recap,
          desktop && { maxWidth: homeRecapWidth(windowWidth), alignSelf: 'center' },
        ]}
      >
        <NestableDraggableFlatList
          activationDistance={8}
          data={cards}
          keyExtractor={(card) => card}
          onDragEnd={({ data }) => actions.reorderCards(data)}
          scrollEnabled={false}
          renderItem={({ item: card, drag, isActive, getIndex }) => {
            const title = homeCardTitle(card, t);
            const index = getIndex() ?? 0;
            return (
              <ScaleDecorator activeScale={1.015}>
                <View
                  style={[
                    index > 0 ? { marginTop: desktop ? ckSpacing.lg : ckSpacing.md } : undefined,
                    isActive && styles.activeCard,
                  ]}
                >
                  <View style={styles.cardHeading}>
                    {desktop ? (
                      <CKText role="titleMedium" style={styles.sectionTitle}>
                        {title}
                      </CKText>
                    ) : (
                      <View style={styles.grow} />
                    )}
                    <Pressable
                      accessibilityLabel={t('upgradeTrackerPlanReorder', { category: title })}
                      accessibilityRole="button"
                      delayLongPress={180}
                      disabled={isActive}
                      onLongPress={drag}
                      style={({ pressed }) => [
                        styles.dragHandle,
                        pressed && styles.dragHandlePressed,
                      ]}
                      testID={`home-card-drag-${card}`}
                    >
                      <GripVertical color={theme.onSurfaceVariant} size={20} />
                    </Pressable>
                  </View>
                  {desktop ? <View style={styles.sectionGap} /> : null}
                  {card === 'todo' && model.todo ? (
                    <HomeTodoCard model={model.todo} desktop={desktop} actions={actions} />
                  ) : card === 'ranked' && model.ranked ? (
                    <HomeRankedCard model={model.ranked} desktop={desktop} actions={actions} />
                  ) : card === 'upgrade' && model.upgrade ? (
                    <HomeUpgradeCard model={model.upgrade} desktop={desktop} actions={actions} />
                  ) : null}
                </View>
              </ScaleDecorator>
            );
          }}
        />
      </View>
    );
  return (
    <SafeAreaView
      edges={['left', 'right']}
      onLayout={(event) => setContentWidth(event.nativeEvent.layout.width)}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      <NestableScrollContainer
        alwaysBounceVertical
        contentContainerStyle={{
          paddingHorizontal: horizontal,
          paddingBottom: homeBottomPadding(desktop, insets.bottom),
        }}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={() => void refresh()}
            tintColor={theme.primary}
          />
        }
      >
        {model.lastRefresh ? (
          <LastRefresh lastRefresh={model.lastRefresh} onRefresh={() => void refresh()} />
        ) : null}
        <View style={styles.refreshGap} />
        <HomeEventBanner
          announcements={model.announcements}
          desktop={desktop}
          onOpen={actions.openAnnouncement}
        />
        <View style={{ height: desktop ? 24 : 16 }} />
        {body}
      </NestableScrollContainer>
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

function LastRefresh({ lastRefresh, onRefresh }: { lastRefresh: Date; onRefresh: () => void }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [, setMinute] = useState(0);
  useEffect(() => {
    const timer = setInterval(() => setMinute((value) => value + 1), 60000);
    return () => clearInterval(timer);
  }, []);
  const label = t('generalLastRefresh', {
    time: formatLastRefresh(lastRefresh, new Date(), t, locale),
  });
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onRefresh}
      style={styles.refreshRow}
    >
      <RefreshCw size={12} color={theme.onSurfaceVariant} />
      <CKText muted role="bodySmall">
        {label}
      </CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  refreshRow: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  refreshGap: { height: 12 },
  recap: { width: '100%' },
  grow: { flex: 1 },
  cardHeading: { minHeight: 28, flexDirection: 'row', alignItems: 'center' },
  dragHandle: {
    width: 40,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
  },
  dragHandlePressed: { opacity: 0.56, transform: [{ scale: 0.96 }] },
  activeCard: { opacity: 0.94 },
  sectionTitle: { fontWeight: '900' },
  sectionGap: { height: ckSpacing.sm },
  mobileGap: { height: 16 },
  empty: { paddingHorizontal: 24, paddingVertical: 52 },
});
