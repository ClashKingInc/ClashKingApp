import { useEffect, useMemo, useRef, useState } from 'react';
import {
  Platform,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { RefreshCw, Users } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  ResponsiveGrid,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { ClanRosterCard } from './clan-card';
import {
  buildClanRoster,
  type ClansPresentationActions,
  type ClansPresentationModel,
} from './contracts';
import { formatClanLastRefresh } from './presentation-utils';

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
  const [, setRefreshMinute] = useState(0);
  const requestedBookmarks = useRef(new Set<string>());
  const roster = useMemo(() => buildClanRoster(model), [model]);
  useEffect(() => {
    const missing = roster.missingBookmarkTags.filter(
      (tag) => !requestedBookmarks.current.has(tag),
    );
    if (missing.length === 0) return;
    missing.forEach((tag) => requestedBookmarks.current.add(tag));
    void actions.hydrateBookmarkedClans(missing);
  }, [actions, roster.missingBookmarkTags]);
  useEffect(() => {
    if (!model.lastRefresh) return;
    const timer = setInterval(() => setRefreshMinute((value) => value + 1), 60_000);
    return () => clearInterval(timer);
  }, [model.lastRefresh]);
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
        {model.lastRefresh ? (
          <View style={styles.refresh}>
            <RefreshCw size={12} color={colorWithAlpha(theme.onSurface, 0.6)} />
            <CKText role="bodySmall" style={{ color: colorWithAlpha(theme.onSurface, 0.6) }}>
              {t('generalLastRefresh', {
                time: formatClanLastRefresh(model.lastRefresh, t, locale),
              })}
            </CKText>
          </View>
        ) : null}
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
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  refresh: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
  },
  roster: { paddingTop: 8 },
  list: { gap: 10 },
  empty: { padding: 0 },
});
