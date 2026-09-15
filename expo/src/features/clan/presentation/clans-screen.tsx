import { PullRefreshHint, usePullRefreshHint } from '../../../ui/pull-refresh-hint';
import { useEffect, useMemo, useRef, useState } from 'react';
import {
  Platform,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { Users } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useI18n } from '../../../i18n';
import { EmptyState, ResponsiveGrid, Surface, ckRadius, useCKTheme } from '../../../ui';
import { ClanRosterCard } from './clan-card';
import {
  buildClanRoster,
  type ClansPresentationActions,
  type ClansPresentationModel,
} from './contracts';
import { formatClanLastRefresh } from './presentation-utils';
import { useLinkParameters } from '../../../core/deep-links/link-parameters';

export function ClansScreen({
  model,
  actions,
}: {
  model: ClansPresentationModel;
  actions: ClansPresentationActions;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const desktop = Platform.OS === 'web' && width >= 900;
  const horizontal = Math.max(16, (width - (desktop ? 1320 : 840)) / 2);
  const [refreshing, setRefreshing] = useState(false);
  const pullRefresh = usePullRefreshHint();
  const requestedBookmarks = useRef(new Set<string>());
  const link = useLinkParameters();
  const roster = useMemo(() => {
    const result = buildClanRoster(model);
    if (link.tab === 'linked')
      return { ...result, items: result.items.filter((item) => item.accountCount > 0) };
    if (link.tab === 'bookmarks') {
      const bookmarked = new Set(model.bookmarks.map((item) => item.tag));
      return { ...result, items: result.items.filter((item) => bookmarked.has(item.tag)) };
    }
    return result;
  }, [model, link.tab]);
  useEffect(() => {
    const missing = roster.missingBookmarkTags.filter(
      (tag) => !requestedBookmarks.current.has(tag),
    );
    if (missing.length === 0) return;
    missing.forEach((tag) => requestedBookmarks.current.add(tag));
    void actions.hydrateBookmarkedClans(missing);
  }, [actions, roster.missingBookmarkTags]);
  const refresh = async () => {
    setRefreshing(true);
    try {
      await actions.refresh();
    } catch (error) {
      if (actions.isNetworkError(error)) {
        actions.openNetworkError(actions.refresh);
      } else {
        actions.showMessage(t('generalRefreshFailed', { error: String(error) }));
      }
    } finally {
      setRefreshing(false);
    }
  };
  const open = async (index: number) => {
    const item = roster.items[index];
    if (!item) return;
    if (item.clan) {
      actions.openClan(item.clan);
      return;
    }
    try {
      actions.openClan(await actions.loadClan(item.tag));
    } catch {
      // Flutter intentionally leaves an unavailable bookmark in place.
    }
  };
  const cards = roster.items.map((item, index) => (
    <ClanRosterCard
      key={`${item.bookmarked ? 'bookmark' : 'linked'}:${item.tag}`}
      item={item}
      onOpen={() => void open(index)}
    />
  ));
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      <ScrollView
        onScroll={pullRefresh.onScroll}
        onScrollBeginDrag={pullRefresh.onScrollBeginDrag}
        onScrollEndDrag={pullRefresh.onScrollEndDrag}
        scrollEventThrottle={16}
        contentContainerStyle={{
          paddingHorizontal: horizontal,
          paddingBottom: desktop ? 32 : insets.bottom + 96,
        }}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={() => void refresh()}
            tintColor={theme.primary}
          />
        }
      >
        <View style={styles.roster}>
          {roster.items.length === 0 ? (
            <Surface radius={ckRadius.control}>
              <EmptyState
                title={t('clanNone')}
                body={t('clanJoinToUnlock')}
                icon={<Users color={theme.onSurfaceVariant} />}
                style={styles.empty}
              />
            </Surface>
          ) : desktop ? (
            <ResponsiveGrid minItemWidth={420} maxColumns={3} gap={12}>
              {cards}
            </ResponsiveGrid>
          ) : (
            <View style={styles.list}>{cards}</View>
          )}
        </View>
      </ScrollView>
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
  list: { gap: 10 },
  empty: { padding: 0 },
});
