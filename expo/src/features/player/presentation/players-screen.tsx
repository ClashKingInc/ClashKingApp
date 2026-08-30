import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  Animated,
  Modal,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { Bookmark, RefreshCw, UserCircle } from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  ResponsiveGrid,
  Skeleton,
  ckSpacing,
  colorWithAlpha,
  useCKAccessibility,
  useCKTheme,
} from '../../../ui';
import { AccountVerificationDialog } from '../../accounts/presentation/account-verification-dialog';
import { PlayerCardOptions } from '../models/player-support';
import type { Player } from '../models/player';
import {
  buildPlayerRosters,
  normalizeRosterTag,
  type PlayerRosterMode,
  type PlayersPresentationActions,
  type PlayersPresentationModel,
} from './contracts';
import { BookmarkedPlayerCard, PlayerDataCard } from './player-card';
import { formatLastRefresh } from './presentation-utils';

export function PlayersScreen({
  model,
  actions,
}: {
  model: PlayersPresentationModel;
  actions: PlayersPresentationActions;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const desktop = Platform.OS === 'web' && width >= 900;
  const horizontal = Math.max(16, (width - (desktop ? 1320 : 840)) / 2);
  const [mode, setMode] = useState<PlayerRosterMode>('linked');
  const [refreshing, setRefreshing] = useState(false);
  const [verification, setVerification] = useState<Player>();
  const [loadingBookmark, setLoadingBookmark] = useState(false);
  const [, setRefreshMinute] = useState(0);
  const requestedBookmarks = useRef(new Set<string>());
  const rosters = useMemo(() => buildPlayerRosters(model), [model]);
  useEffect(() => {
    const missing = rosters.missingBookmarkTags.filter(
      (tag) => !requestedBookmarks.current.has(normalizeRosterTag(tag)),
    );
    if (missing.length === 0) return;
    missing.forEach((tag) => requestedBookmarks.current.add(normalizeRosterTag(tag)));
    void actions.hydrateBookmarkedPlayers(missing);
  }, [actions, rosters.missingBookmarkTags]);
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
      actions.showMessage(t('generalRefreshFailed', { error: String(error) }));
    } finally {
      setRefreshing(false);
    }
  };
  const openBookmark = async (tag: string) => {
    setLoadingBookmark(true);
    try {
      actions.openPlayer(await actions.loadBookmarkedPlayer(tag));
    } catch {
      actions.showMessage(t('bookmarkPlayerLoadFailed'));
    } finally {
      setLoadingBookmark(false);
    }
  };
  const entries = mode === 'linked' ? rosters.linked : rosters.bookmarked;
  const cards = entries.map((entry) => {
    if (entry.kind === 'linked') {
      const key = normalizeRosterTag(entry.player.tag);
      return (
        <PlayerDataCard
          key={key}
          player={entry.player}
          link={entry.link}
          options={model.optionsByTag[key] ?? new PlayerCardOptions()}
          featureFlags={model.featureFlags}
          notificationsEnabled={model.notificationsEnabled}
          notificationActive={model.notificationAccountTags.has(key)}
          notificationUpdating={model.updatingNotificationTags.has(key)}
          actions={actions}
          onVerify={() => setVerification(entry.player)}
        />
      );
    }
    if (entry.player)
      return (
        <PlayerDataCard
          key={entry.bookmark.tag}
          player={entry.player}
          bookmarked
          options={new PlayerCardOptions()}
          featureFlags={model.featureFlags}
          notificationsEnabled={false}
          notificationActive={false}
          notificationUpdating={false}
          actions={actions}
          onVerify={() => undefined}
        />
      );
    return (
      <BookmarkedPlayerCard
        key={entry.bookmark.tag}
        bookmark={entry.bookmark}
        onPress={() => void openBookmark(entry.bookmark.tag)}
      />
    );
  });
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      <ScrollView
        alwaysBounceVertical
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
                time: formatLastRefresh(model.lastRefresh, t, locale),
              })}
            </CKText>
          </View>
        ) : null}
        <View style={styles.segmentWrap}>
          <PlayerRosterControl
            mode={mode}
            linkedLabel={t('playersLinked')}
            bookmarkedLabel={t('playersBookmarked')}
            isRtl={isRtl}
            onChange={setMode}
          />
        </View>
        {entries.length === 0 ? (
          <EmptyState
            title={
              mode === 'linked'
                ? t('dashboardNoLinkedAccountsTitle')
                : t('playersNoBookmarkedTitle')
            }
            body={mode === 'linked' ? t('playersNoLinkedBody') : t('playersNoBookmarkedBody')}
            icon={
              mode === 'linked' ? (
                <UserCircle color={theme.onSurfaceVariant} />
              ) : (
                <Bookmark color={theme.onSurfaceVariant} />
              )
            }
            actionLabel={mode === 'linked' ? t('drawerManageAccounts') : undefined}
            onAction={mode === 'linked' ? actions.openManageAccounts : undefined}
            style={styles.empty}
          />
        ) : desktop ? (
          <ResponsiveGrid minItemWidth={420} maxColumns={3} gap={12}>
            {cards}
          </ResponsiveGrid>
        ) : (
          <View style={styles.list}>{cards}</View>
        )}
      </ScrollView>
      <Modal
        transparent
        visible={loadingBookmark}
        animationType="fade"
        onRequestClose={() => undefined}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.loadingDialog, { backgroundColor: theme.card }]}>
            <Skeleton width={48} height={48} radius={24} />
            <Skeleton width={180} />
            <Skeleton width={120} height={12} />
          </View>
        </View>
      </Modal>
      <AccountVerificationDialog
        visible={verification !== undefined}
        playerTag={verification?.tag ?? ''}
        playerName={verification?.name ?? ''}
        townHallLevel={verification?.townHallLevel ?? 1}
        onVerify={(token) =>
          verification
            ? actions.verifyAccount(verification.tag, token)
            : Promise.resolve({ success: false, message: null })
        }
        onOpenSettings={actions.openGameSettings}
        onCancel={() => setVerification(undefined)}
        onVerified={() => {
          setVerification(undefined);
          void actions.refreshAccounts();
        }}
      />
    </SafeAreaView>
  );
}

function PlayerRosterControl({
  mode,
  linkedLabel,
  bookmarkedLabel,
  isRtl,
  onChange,
}: {
  mode: PlayerRosterMode;
  linkedLabel: string;
  bookmarkedLabel: string;
  isRtl: boolean;
  onChange: (mode: PlayerRosterMode) => void;
}) {
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const [segmentWidth, setSegmentWidth] = useState(0);
  const [position] = useState(() => new Animated.Value(mode === 'linked' ? 0 : 1));
  const startIndex = mode === 'linked' ? 0 : 1;
  const animateTo = useCallback(
    (index: 0 | 1) => {
      if (reduceMotion) {
        position.setValue(index);
        return;
      }
      Animated.spring(position, {
        toValue: index,
        mass: 1,
        stiffness: 420,
        damping: 41,
        useNativeDriver: true,
      }).start();
    },
    [position, reduceMotion],
  );
  useEffect(() => animateTo(mode === 'linked' ? 0 : 1), [animateTo, mode]);
  const pan = useMemo(
    () =>
      Gesture.Pan()
        .activeOffsetX([-4, 4])
        .failOffsetY([-10, 10])
        .runOnJS(true)
        .onStart(() => position.stopAnimation())
        .onUpdate((gesture) => {
          if (segmentWidth <= 0) return;
          const direction = isRtl ? -1 : 1;
          position.setValue(
            Math.max(
              0,
              Math.min(1, startIndex + direction * (gesture.translationX / segmentWidth)),
            ),
          );
        })
        .onEnd((gesture) => {
          if (segmentWidth <= 0) return;
          const direction = isRtl ? -1 : 1;
          const projected =
            startIndex +
            direction *
              (gesture.translationX / segmentWidth + (gesture.velocityX / segmentWidth) * 0.08);
          const target: 0 | 1 = projected >= 0.5 ? 1 : 0;
          animateTo(target);
          onChange(target === 0 ? 'linked' : 'bookmarked');
        })
        .onFinalize((_event, success) => {
          if (success) return;
          animateTo(startIndex);
        }),
    [animateTo, isRtl, onChange, position, segmentWidth, startIndex],
  );
  const values = [
    { value: 'linked' as const, label: linkedLabel },
    { value: 'bookmarked' as const, label: bookmarkedLabel },
  ];
  return (
    <GestureDetector gesture={pan}>
      <View
        testID="player-roster-control"
        onLayout={(event) => setSegmentWidth((event.nativeEvent.layout.width - 4) / 2)}
        style={[
          styles.segment,
          {
            backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.45),
            borderColor: colorWithAlpha(theme.outlineVariant, 0.32),
          },
        ]}
      >
        {segmentWidth > 0 ? (
          <Animated.View
            pointerEvents="none"
            style={[
              styles.segmentIndicator,
              {
                width: segmentWidth,
                backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.74),
                transform: [
                  {
                    translateX: position.interpolate({
                      inputRange: [0, 1],
                      outputRange: isRtl ? [segmentWidth, 0] : [0, segmentWidth],
                    }),
                  },
                ],
              },
            ]}
          />
        ) : null}
        {values.map(({ value, label }) => (
          <Pressable
            key={value}
            accessibilityRole="tab"
            accessibilityState={{ selected: mode === value }}
            accessibilityLabel={label}
            onPress={() => onChange(value)}
            style={styles.segmentItem}
          >
            <CKText
              style={[
                styles.segmentLabel,
                mode !== value && { color: colorWithAlpha(theme.onSurface, 0.67) },
              ]}
            >
              {label}
            </CKText>
          </Pressable>
        ))}
      </View>
    </GestureDetector>
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
  segmentWrap: { height: 74, paddingTop: 8, paddingBottom: 14, justifyContent: 'center' },
  segment: {
    height: 32,
    marginHorizontal: 16,
    flexDirection: 'row',
    padding: 2,
    borderRadius: 16,
    borderWidth: 0.8,
    overflow: 'hidden',
  },
  segmentIndicator: { position: 'absolute', left: 2, top: 2, bottom: 2, borderRadius: 14 },
  segmentItem: { flex: 1, alignItems: 'center', justifyContent: 'center', borderRadius: 14 },
  segmentLabel: { width: '100%', textAlign: 'center', fontSize: 13, fontWeight: '600' },
  list: { gap: 10 },
  empty: { padding: 0 },
  modalOverlay: {
    flex: 1,
    backgroundColor: '#00000066',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  loadingDialog: {
    width: 280,
    borderRadius: 20,
    padding: ckSpacing.xl,
    alignItems: 'center',
    gap: ckSpacing.md,
  },
});
