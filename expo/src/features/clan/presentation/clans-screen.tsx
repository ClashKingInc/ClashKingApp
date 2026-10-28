import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { InlineReorderGrid } from '../../../ui/inline-reorder-grid';
import { useNativePrimaryNavigation } from '../../../ui/native-primary-navigation';
import { PullRefreshHint, usePullRefreshHint } from '../../../ui/pull-refresh-hint';
import { DragJiggle } from '../../../ui/drag-jiggle';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Platform,
  RefreshControl,
  ScrollView,
  type ScrollViewInstance,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { Users } from 'lucide-react-native';
import DraggableFlatList, {
  ScaleDecorator,
  type RenderItemParams,
} from 'react-native-draggable-flatlist';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useI18n } from '../../../i18n';
import {
  EmptyState,
  ResponsiveGrid,
  SkeletonContent,
  Surface,
  ckRadius,
  useCKTheme,
} from '../../../ui';
import { PlayerRosterControl } from '../../player/presentation/players-screen';
import { ClanRosterCard } from './clan-card';
import type { ClanSpringOrigin } from './clan-spring-transition';
import { ImageAssets } from '../../../core/assets/image-assets';
import { prefetchMobileImage, headerArtworkSize } from '../../../ui/mobile-web-image';
import {
  buildClanRoster,
  type ClansPresentationActions,
  type ClansPresentationModel,
} from './contracts';
import { formatClanLastRefresh } from './presentation-utils';
import { useLinkParameters, linkChoice } from '../../../core/deep-links/link-parameters';

export function ClansScreen({
  model,
  actions,
}: {
  model: ClansPresentationModel;
  actions: ClansPresentationActions;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const nativeTabs = useNativePrimaryNavigation();
  const layout = useAdaptiveLayout();
  const [gridDragging, setGridDragging] = useState(false);
  const nativeScroll = useRef<ScrollViewInstance>(null);
  const nativeScrollOffset = useRef(0);
  const { width } = useWindowDimensions();
  useEffect(() => {
    const size = headerArtworkSize(width);
    void prefetchMobileImage(ImageAssets.homeBaseBackground, size.width, size.height);
  }, [width]);
  const desktop = Platform.OS === 'web' && width >= 900;
  const horizontal = Math.max(
    16,
    ((layout.isDuo || layout.isTablet ? layout.usableWidth : width) -
      (layout.isDuo || layout.isTablet ? layout.contentMaxWidth : desktop ? 1320 : 840)) /
      2,
  );
  const [refreshing, setRefreshing] = useState(false);
  const refreshingRef = useRef(false);
  const refresh = useCallback(async () => {
    if (refreshingRef.current) return;
    refreshingRef.current = true;
    setRefreshing(true);
    try {
      await actions.refresh();
    } catch (error) {
      if (actions.isNetworkError(error)) {
        actions.openNetworkError(actions.refresh);
      } else {
        actions.showMessage(t('generalTryAgain'));
      }
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
  const requestedBookmarks = useRef(new Set<string>());
  const link = useLinkParameters();
  const [mode, setMode] = useState<'linked' | 'bookmarked'>(
    linkChoice(
      link.tab === 'bookmarks' ? 'bookmarked' : link.tab,
      ['linked', 'bookmarked'],
      'linked',
    ),
  );
  const roster = useMemo(() => buildClanRoster(model), [model]);
  const entries = roster.items.filter((item) =>
    mode === 'linked' ? !item.bookmarked : item.bookmarked,
  );
  useEffect(() => {
    const missing = roster.missingClanTags.filter((tag) => !requestedBookmarks.current.has(tag));
    if (missing.length === 0) return;
    missing.forEach((tag) => requestedBookmarks.current.add(tag));
    void actions.hydrateBookmarkedClans(missing);
  }, [actions, roster.missingClanTags]);
  const open = async (item: (typeof entries)[number], origin?: ClanSpringOrigin) => {
    if (item.clan) {
      if (origin) actions.openClan(item.clan, origin);
      else actions.openClan(item.clan);
      return;
    }
    if (actions.openClanTag) return actions.openClanTag(item.tag);
    try {
      actions.openClan(await actions.loadClan(item.tag));
    } catch {
      // Flutter intentionally leaves an unavailable bookmark in place.
    }
  };
  const cards = entries.map((item) => (
    <SkeletonContent
      key={`${item.bookmarked ? 'bookmark' : 'linked'}:${item.tag}`}
      loading={!!model.loading && !item.clan}
    >
      <ClanRosterCard
        item={item}
        notifications={model.notifications}
        onOpen={(origin) => void open(item, origin)}
        dragTestID={`clan-roster-card-${item.tag}`}
      />
    </SkeletonContent>
  ));
  const reorder = ({ data, from, to }: { data: typeof entries; from: number; to: number }) => {
    if (from === to) return;
    const operation =
      mode === 'linked'
        ? actions.reorderLinkedClans(data.map((item) => item.tag))
        : actions.reorderBookmarkedClans(data.map((item) => item.tag));
    // Return the result for the adaptive grid's optimistic-order rollback.
    // DraggableFlatList continues to ignore it and retains its existing behavior.
    return operation.then(
      () => true,
      () => {
        actions.showMessage(t('accountsErrorFailedToUpdateOrder'));
        return false;
      },
    );
  };
  const listHeader = (
    <View style={styles.segmentWrap}>
      <PlayerRosterControl
        mode={mode}
        linkedLabel={t('playersLinked')}
        bookmarkedLabel={t('playersBookmarked')}
        isRtl={isRtl}
        onChange={setMode}
      />
    </View>
  );
  const emptyRoster = model.loading ? (
    <SkeletonContent loading style={[styles.roster, { gap: 12 }]}>
      {[0, 1, 2].map((index) => (
        <ClanRosterCard
          key={index}
          item={{
            tag: '',
            name: 'Clan name',
            badgeUrl: ImageAssets.clanCastle,
            members: 50,
            warLeague: '',
            clanPoints: 10000,
            countryCode: '',
            locationName: '',
            type: '',
            accountCount: 1,
            bookmarked: mode === 'bookmarked',
          }}
          onOpen={() => undefined}
        />
      ))}
    </SkeletonContent>
  ) : (
    <Surface radius={ckRadius.control}>
      <EmptyState
        title={mode === 'linked' ? t('clanNone') : t('generalNoDataAvailable')}
        body={mode === 'linked' ? t('clanJoinToUnlock') : undefined}
        icon={<Users color={theme.onSurfaceVariant} />}
        style={styles.empty}
      />
    </Surface>
  );
  const refreshControl = (
    <RefreshControl
      refreshing={refreshing}
      onRefresh={() => void refresh()}
      tintColor={theme.primary}
    />
  );
  const draggableList = (
    <DraggableFlatList
      onScrollOffsetChange={pullRefresh.onScrollOffsetChange}
      onScrollBeginDrag={pullRefresh.onScrollBeginDrag}
      onScrollEndDrag={pullRefresh.onScrollEndDrag}
      activationDistance={8}
      alwaysBounceVertical
      data={entries}
      testID="clans-scroll-view"
      key={`${mode}-clan-roster`}
      keyExtractor={(item) => item.tag}
      onDragEnd={reorder}
      contentContainerStyle={{
        paddingHorizontal: horizontal,
        paddingBottom: insets.bottom + (nativeTabs ? 24 : 96),
      }}
      ListHeaderComponent={listHeader}
      ListEmptyComponent={emptyRoster}
      refreshControl={refreshControl}
      renderItem={(params: RenderItemParams<(typeof entries)[number]>) => (
        <ScaleDecorator activeScale={1.015}>
          <DragJiggle active={params.isActive}>
            <View style={[styles.cardItem, params.isActive && styles.activeCard]}>
              <SkeletonContent loading={!!model.loading && !params.item.clan}>
                <ClanRosterCard
                  item={params.item}
                  notifications={model.notifications}
                  onOpen={(origin) => void open(params.item, origin)}
                  onLongPress={params.drag}
                  dragTestID={`clan-roster-card-${params.item.tag}`}
                />
              </SkeletonContent>
            </View>
          </DragJiggle>
        </ScaleDecorator>
      )}
    />
  );
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      {desktop || layout.isDuo || layout.isTablet ? (
        <ScrollView
          ref={nativeScroll}
          scrollEnabled={!gridDragging}
          testID="clans-scroll-view"
          onScroll={(event) => {
            nativeScrollOffset.current = event.nativeEvent.contentOffset.y;
            pullRefresh.onScroll(event);
          }}
          onScrollBeginDrag={pullRefresh.onScrollBeginDrag}
          onScrollEndDrag={pullRefresh.onScrollEndDrag}
          scrollEventThrottle={16}
          contentContainerStyle={{
            paddingHorizontal: horizontal,
            paddingBottom: nativeTabs ? insets.bottom + 24 : 32,
          }}
          refreshControl={refreshControl}
        >
          {listHeader}
          <View style={styles.roster}>
            {entries.length === 0 ? (
              emptyRoster
            ) : layout.isDuo || layout.isTablet ? (
              <InlineReorderGrid
                key={mode}
                data={entries}
                keyExtractor={(item) => item.tag}
                columns={layout.columns(layout.isTablet ? 420 : 280, 2)}
                scrollRef={nativeScroll}
                scrollOffset={nativeScrollOffset}
                onDragStateChange={setGridDragging}
                onReorder={(data, from, to) => reorder({ data, from, to })}
                renderItem={(item, _index, active) => (
                  <DragJiggle active={active}>
                    <SkeletonContent loading={!!model.loading && !item.clan}>
                      <ClanRosterCard
                        item={item}
                        notifications={model.notifications}
                        onOpen={(origin) => void open(item, origin)}
                        dragTestID={`clan-roster-card-${item.tag}`}
                      />
                    </SkeletonContent>
                  </DragJiggle>
                )}
              />
            ) : (
              <ResponsiveGrid minItemWidth={420} maxColumns={3} gap={12}>
                {cards}
              </ResponsiveGrid>
            )}
          </View>
        </ScrollView>
      ) : (
        draggableList
      )}
      <PullRefreshHint
        distance={pullRefresh.distance}
        refreshing={refreshing}
        label={
          model.lastRefresh
            ? t('generalLastRefresh', {
                time: formatClanLastRefresh(model.lastRefresh, t, locale),
              })
            : undefined
        }
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  roster: { paddingTop: 8 },
  segmentWrap: { height: 74, paddingTop: 8, paddingBottom: 14, justifyContent: 'center' },
  cardItem: { marginBottom: 10 },
  activeCard: { opacity: 0.96 },
  empty: { padding: 0 },
});
