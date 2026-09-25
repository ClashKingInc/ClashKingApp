import { PullRefreshHint, usePullRefreshHint } from '../../../ui/pull-refresh-hint';
import { useEffect, useMemo, useRef, useState } from 'react';
import { RefreshControl, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import { ShieldAlert } from 'lucide-react-native';
import DraggableFlatList, { ScaleDecorator, type RenderItemParams } from 'react-native-draggable-flatlist';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useI18n } from '../../../i18n';
import { useLinkParameters, linkChoice } from '../../../core/deep-links/link-parameters';
import { EmptyState, useCKTheme } from '../../../ui';
import { PlayerRosterControl } from '../../player/presentation/players-screen';
import type { WarCwl, WarInfo } from '../models';
import {
  buildWarRoster,
  type WarPresentationActions,
  type WarPresentationModel,
  type WarRosterItem,
} from './contracts';
import { CwlScreen } from './cwl-screen';
import { WarDetailScreen } from './war-detail-screen';
import { WarSummaryCard } from './war-components';
import { relativeWarTime } from './presentation-utils';

type Destination =
  | { readonly key: 'list' }
  | {
      readonly key: 'war';
      readonly war: WarInfo;
      readonly item: WarRosterItem;
      readonly roundNumber: number | null;
      readonly returnTo: 'list' | 'cwl';
    }
  | { readonly key: 'cwl'; readonly item: WarRosterItem; readonly summary: WarCwl };

/**
 * Expo presentation adapter for the Flutter War tab. It intentionally accepts already-owned
 * application state and navigation actions, so authenticated-root wiring can be added without
 * coupling the screen to a second service container.
 */
export function WarCwlPresentationRoot({
  model,
  actions,
  onOpenWar,
  onOpenCwl,
}: {
  model: WarPresentationModel;
  actions: WarPresentationActions;
  onOpenWar?: (
    war: WarInfo,
    roundNumber: number | null,
    cwl?: { readonly summary: WarCwl; readonly clanTag: string; readonly warLeagueName?: string },
  ) => void;
  onOpenCwl?: (summary: WarCwl, clanTag: string, warLeagueName?: string) => void;
}) {
  const [destination, setDestination] = useState<Destination>({ key: 'list' });
  if (destination.key === 'war') {
    const canOpenCwl =
      destination.item.summary?.isInCwl === true &&
      destination.item.summary.leagueInfo?.getClanDetails(destination.item.tag) !== null;
    return (
      <WarDetailScreen
        war={destination.war}
        linkedPlayerTags={model.ownedPlayerTags}
        cwlRoundNumber={destination.roundNumber}
        actions={actions}
        onBack={() =>
          destination.returnTo === 'cwl' && destination.item.summary
            ? setDestination({
                key: 'cwl',
                item: destination.item,
                summary: destination.item.summary,
              })
            : setDestination({ key: 'list' })
        }
        onOpenCwl={
          canOpenCwl
            ? () =>
                setDestination({
                  key: 'cwl',
                  item: destination.item,
                  summary: destination.item.summary!,
                })
            : undefined
        }
      />
    );
  }
  if (destination.key === 'cwl') {
    return (
      <CwlScreen
        clanTag={destination.item.tag}
        summary={destination.summary}
        warLeagueName={destination.item.clan?.warLeague?.name}
        actions={actions}
        onBack={() => setDestination({ key: 'list' })}
        onOpenWar={(war, roundNumber) =>
          setDestination({
            key: 'war',
            war,
            item: destination.item,
            roundNumber,
            returnTo: 'cwl',
          })
        }
      />
    );
  }
  return (
    <WarCwlScreen
      model={model}
      actions={actions}
      onOpenWar={(item, war) =>
        onOpenWar
          ? onOpenWar(
              war,
              item.cwlRoundNumber,
              item.summary?.isInCwl === true &&
                item.summary.leagueInfo?.getClanDetails(item.tag) !== null
                ? {
                    summary: item.summary,
                    clanTag: item.tag,
                    ...(item.clan?.warLeague?.name
                      ? { warLeagueName: item.clan.warLeague.name }
                      : {}),
                  }
                : undefined,
            )
          : setDestination({
              key: 'war',
              item,
              war,
              roundNumber: item.cwlRoundNumber,
              returnTo: 'list',
            })
      }
      onOpenCwl={(item, summary) =>
        onOpenCwl
          ? onOpenCwl(summary, item.tag, item.clan?.warLeague?.name)
          : setDestination({ key: 'cwl', item, summary })
      }
    />
  );
}

export function WarCwlScreen({
  model,
  actions,
  onOpenWar,
  onOpenCwl,
}: {
  model: WarPresentationModel;
  actions: WarPresentationActions;
  onOpenWar: (item: WarRosterItem, war: WarInfo) => void;
  onOpenCwl: (item: WarRosterItem, summary: WarCwl) => void;
}) {
  const { t, isRtl } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const requestedPlayers = useRef(new Set<string>());
  const requestedWars = useRef(new Set<string>());
  const [refreshing, setRefreshing] = useState(false);
  const pullRefresh = usePullRefreshHint();
  const [now, setNow] = useState(() => new Date());
  const link = useLinkParameters();
  const [mode, setMode] = useState<'linked' | 'bookmarked'>(
    linkChoice(link.tab === 'bookmarks' ? 'bookmarked' : link.tab, ['linked', 'bookmarked'], 'linked'),
  );
  const roster = useMemo(() => buildWarRoster(model), [model]);
  const entries = roster.items.filter((item) => mode === 'linked' ? !item.bookmarked : item.bookmarked);
  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 30_000);
    return () => clearInterval(timer);
  }, []);
  useEffect(() => {
    const missingPlayers = roster.missingBookmarkedPlayerTags.filter(
      (tag) => !requestedPlayers.current.has(tag),
    );
    if (!missingPlayers.length) return;
    missingPlayers.forEach((tag) => requestedPlayers.current.add(tag));
    void actions
      .hydrateBookmarkedPlayers(missingPlayers)
      .catch((error) => actions.showMessage(String(error)));
  }, [actions, roster.missingBookmarkedPlayerTags]);
  useEffect(() => {
    const missingWars = roster.missingWarClanTags.filter((tag) => !requestedWars.current.has(tag));
    if (!missingWars.length) return;
    missingWars.forEach((tag) => requestedWars.current.add(tag));
    void actions.loadWarSummaries(missingWars).catch((error) => actions.showMessage(String(error)));
  }, [actions, roster.missingWarClanTags]);

  const refresh = async () => {
    setRefreshing(true);
    try {
      await actions.refresh();
      if (roster.missingWarClanTags.length)
        await actions.loadWarSummaries(roster.missingWarClanTags);
    } catch (error) {
      if (actions.isNetworkError(error)) actions.openNetworkError(refresh);
      else actions.showMessage(t('generalRefreshFailed', { error: String(error) }));
    } finally {
      setRefreshing(false);
    }
  };
  const desktop = width >= 900;
  const reorder = ({ data, from, to }: { data: typeof entries; from: number; to: number }) => {
    if (from === to) return;
    const operation = mode === 'linked'
      ? actions.reorderLinkedClans?.(data.map((item) => item.tag))
      : actions.reorderBookmarkedClans?.(data.map((item) => item.tag));
    void operation?.catch(() => actions.showMessage(t('accountsErrorFailedToUpdateOrder')));
  };
  const listHeader = <View style={styles.segmentWrap}>
    <PlayerRosterControl
      mode={mode}
      linkedLabel={t('playersLinked')}
      bookmarkedLabel={t('playersBookmarked')}
      isRtl={isRtl}
      onChange={setMode}
    />
  </View>;
  const emptyRoster = <EmptyState
    title={mode === 'linked' ? t('warNoLinkedOrBookmarked') : t('generalNoDataAvailable')}
    icon={<ShieldAlert color={theme.onSurfaceVariant} />}
  />;
  const refreshControl = <RefreshControl
    refreshing={refreshing}
    onRefresh={() => void refresh()}
    tintColor={theme.primary}
  />;
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      {desktop ? <ScrollView
        onScroll={pullRefresh.onScroll}
        onScrollBeginDrag={pullRefresh.onScrollBeginDrag}
        onScrollEndDrag={pullRefresh.onScrollEndDrag}
        scrollEventThrottle={16}
        refreshControl={refreshControl}
        contentContainerStyle={[
          styles.scroll,
          { paddingBottom: insets.bottom + (desktop ? 32 : 96) },
        ]}
      >
        {listHeader}
        {!entries.length ? (
          emptyRoster
        ) : (
          <View style={[styles.grid, desktop && styles.desktopGrid]}>
            {entries.map((item) => (
              <View key={item.tag} style={desktop ? styles.desktopItem : styles.mobileItem}>
                <WarSummaryCard
                  item={item}
                  now={now}
                  onOpenWar={(war) => onOpenWar(item, war)}
                  onOpenCwl={() => {
                    if (item.summary) onOpenCwl(item, item.summary);
                  }}
                />
              </View>
            ))}
          </View>
        )}
      </ScrollView> : <DraggableFlatList
        onScrollOffsetChange={pullRefresh.onScrollOffsetChange}
        onScrollBeginDrag={pullRefresh.onScrollBeginDrag}
        onScrollEndDrag={pullRefresh.onScrollEndDrag}
        activationDistance={8}
        alwaysBounceVertical
        data={entries}
        key={`${mode}-war-roster`}
        keyExtractor={(item) => item.tag}
        onDragEnd={reorder}
        contentContainerStyle={[styles.scroll, { paddingBottom: insets.bottom + 96 }]}
        ListHeaderComponent={listHeader}
        ListEmptyComponent={emptyRoster}
        refreshControl={refreshControl}
        renderItem={(params: RenderItemParams<WarRosterItem>) => <ScaleDecorator activeScale={1.015}>
          <View style={[styles.mobileItem, params.isActive && styles.activeCard]}>
            <WarSummaryCard
              item={params.item}
              now={now}
              onOpenWar={(war) => onOpenWar(params.item, war)}
              onOpenCwl={() => { if (params.item.summary) onOpenCwl(params.item, params.item.summary); }}
              onLongPress={params.drag}
              dragTestID={`war-roster-card-${params.item.tag}`}
            />
          </View>
        </ScaleDecorator>}
      />}
      <PullRefreshHint
        distance={pullRefresh.distance}
        refreshing={refreshing}
        label={
          model.lastRefresh
            ? t('generalLastRefresh', { time: relativeWarTime(model.lastRefresh, now, t) })
            : undefined
        }
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  scroll: { width: '100%', maxWidth: 1360, alignSelf: 'center', paddingHorizontal: 16 },
  segmentWrap: { height: 74, paddingTop: 8, paddingBottom: 14, justifyContent: 'center' },
  grid: { gap: 10 },
  desktopGrid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center' },
  desktopItem: { width: '48%', minWidth: 420, maxWidth: 640 },
  mobileItem: { width: '100%', marginBottom: 10 },
  activeCard: { opacity: 0.96 },
});
