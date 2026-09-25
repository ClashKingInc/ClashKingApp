import { useEffect, useMemo, useState, useSyncExternalStore } from 'react';
import {
  Animated,
  Easing,
  FlatList,
  Modal,
  Pressable,
  RefreshControl,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  ChevronRight,
  Globe2,
  History,
  ChartNoAxesColumnIncreasing,
  Star,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import {
  gameDataState,
  subscribeToGameDataRevision,
} from '../../../core/game-data/game-data-state';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  CalendarPicker,
  DateNavigator,
  EmptyState,
  ErrorState,
  MobileWebImage,
  ProfilePageHeader,
  SelectionPicker,
  SkeletonLoadingDialog,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { orderedLocations, type LocationPreferences } from './location-preferences';
import type { RankingsProvider } from '../data';
import {
  isRankingSnapshotDate,
  nextRankingDate,
  previousRankingDate,
} from '../models/ranking-dates';
import {
  RankingAudience,
  RankingBoard,
  RankingPeriod,
  rankingBoardArtwork,
  type RankingBoardValue,
  type RankingEntry,
  type RankingLocation,
} from '../models';

type RankingListItem =
  { readonly kind: 'content' } | { readonly kind: 'entry'; readonly entry: RankingEntry };

export function RankingsScreen({
  provider,
  revision,
  onBack,
  onOpenEntry,
  onMessage,
  locationPreferences,
  onSelectLocation,
  onToggleStar,
}: {
  provider: RankingsProvider;
  /** Changes whenever the mutable provider publishes a new snapshot. */
  revision: number;
  onBack: () => void;
  onOpenEntry: (entry: RankingEntry) => Promise<void>;
  onMessage: (message: string) => void;
  locationPreferences: LocationPreferences;
  onSelectLocation: (location: RankingLocation) => void;
  onToggleStar: (location: RankingLocation) => void;
}) {
  'use no memo';
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const horizontal = Math.max(16, (width - 1120) / 2);
  const gameDataRevision = useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => gameDataState.revision,
  );
  const [dateOpen, setDateOpen] = useState(false);
  const [opening, setOpening] = useState(false);
  const entries = useMemo(() => provider.result?.entries ?? [], [provider.result]);
  const listItems = useMemo<readonly RankingListItem[]>(
    () => [{ kind: 'content' }, ...entries.map((entry) => ({ kind: 'entry' as const, entry }))],
    [entries],
  );
  const open = async (entry: RankingEntry) => {
    setOpening(true);
    try {
      await onOpenEntry(entry);
    } catch {
      onMessage(
        entry.audience === RankingAudience.players
          ? t('rankingsPlayerLoadFailed')
          : t('rankingsClanLoadFailed'),
      );
    } finally {
      setOpening(false);
    }
  };
  const hasFilter =
    provider.board === RankingBoard.playerTownHall || provider.board === RankingBoard.playerRanked;
  const today = provider.today;
  const displayedDate = provider.period === RankingPeriod.current ? today : provider.historyDate;
  const previousDate = previousRankingDate(provider.board, displayedDate);
  const nextDate = nextRankingDate(provider.board, displayedDate, today);

  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.fill, { backgroundColor: theme.background }]}
    >
      <FlatList
        testID="rankings-list"
        data={listItems}
        extraData={`${revision}:${gameDataRevision}`}
        refreshControl={
          <RefreshControl
            refreshing={provider.isLoading}
            onRefresh={() => void provider.reload()}
            tintColor={theme.primary}
          />
        }
        keyExtractor={(item) =>
          item.kind === 'entry'
            ? `${provider.board.name}-${item.entry.tag}`
            : `${provider.board.name}-${item.kind}`
        }
        contentContainerStyle={{ paddingBottom: insets.bottom + 24 }}
        ListHeaderComponent={
          <ProfilePageHeader
            testID="rankings-profile-header"
            title={boardLabel(provider.board, t)}
            imageUrl={rankingBoardArtwork(provider.board)}
            backgroundUrl={rankingBackground(provider.board)}
            onBack={onBack}
            backLabel={materialBackLabel(locale)}
            safeTop={insets.top}
            bottomPadding={0}
          >
            {provider.board.supportsLocation ? (
              <RankingLocationPicker
                provider={provider}
                locationPreferences={locationPreferences}
                onSelectLocation={onSelectLocation}
                onToggleStar={onToggleStar}
              />
            ) : null}
          </ProfilePageHeader>
        }
        renderItem={({ item }) => {
          if (item.kind === 'content') {
            return (
              <View
                style={{
                  paddingHorizontal: horizontal,
                  paddingTop: hasFilter || provider.board.supportsHistory ? 0 : 4,
                }}
              >
                {provider.board.supportsHistory ? (
                  <DateNavigator
                    label={
                      provider.period === RankingPeriod.current
                        ? t('rankingsCurrent')
                        : formatLongDate(displayedDate, locale)
                    }
                    onPrevious={() => void provider.selectDate(previousDate)}
                    onNext={() => void provider.selectDate(nextDate)}
                    onPressLabel={() => setDateOpen(true)}
                    previousDisabled={previousDate < provider.earliestHistoryDate}
                    nextDisabled={displayedDate >= today}
                    accessibilityLabel={t('rankingsSnapshotDate')}
                  />
                ) : null}
                {hasFilter ? <RankingControls provider={provider} /> : null}
                {provider.isLoading ? (
                  <IndeterminateProgressBar horizontalInset={horizontal} />
                ) : null}
                {provider.error ? (
                  <ErrorState
                    title={t('sideRankingsLoadError')}
                    body={String(provider.error)}
                    actionLabel={t('generalRetry')}
                    onAction={() => void provider.reload()}
                    style={styles.feedback}
                  />
                ) : null}
                {!provider.isLoading && !provider.error && entries.length === 0 ? (
                  <EmptyState
                    title={
                      provider.period === RankingPeriod.history
                        ? t('rankingsNoSnapshotTitle')
                        : t('sideRankingsEmptyTitle')
                    }
                    body={
                      provider.period === RankingPeriod.history
                        ? t('rankingsNoSnapshotBody', {
                            date: formatDate(provider.historyDate, locale),
                          })
                        : t('sideRankingsEmptyBody')
                    }
                    icon={
                      provider.period === RankingPeriod.history ? (
                        <History color={theme.onSurfaceVariant} />
                      ) : (
                        <ChartNoAxesColumnIncreasing color={theme.onSurfaceVariant} />
                      )
                    }
                    style={styles.empty}
                  />
                ) : null}
              </View>
            );
          }
          return (
            <View style={{ paddingHorizontal: horizontal }}>
              <RankingRow entry={item.entry} onPress={() => void open(item.entry)} />
            </View>
          );
        }}
      />
      {dateOpen ? (
        <RankingDateSheet provider={provider} onClose={() => setDateOpen(false)} />
      ) : null}
      <SkeletonLoadingDialog visible={opening} />
    </SafeAreaView>
  );
}

function RankingControls({ provider }: { provider: RankingsProvider }) {
  'use no memo';
  const { t } = useI18n();
  if (provider.board === RankingBoard.playerTownHall)
    return (
      <View style={styles.controls}>
        <SelectionPicker
          title={t('rankingsTownHall')}
          accessibilityLabel={`${t('rankingsTownHall')}: TH${provider.townHallLevel}`}
          selectedKey={String(provider.townHallLevel)}
          options={Array.from({ length: 12 }, (_, i) => 18 - i).map((level) => ({
            key: String(level),
            label: `TH${level}`,
            icon: (
              <MobileWebImage
                imageUrl={ImageAssets.townHall(level)}
                contentFit="contain"
                style={styles.choiceImage}
              />
            ),
          }))}
          onSelect={(key) => void provider.selectTownHall(Number(key))}
        />
      </View>
    );
  if (provider.board === RankingBoard.playerRanked)
    return (
      <View style={styles.controls}>
        <SelectionPicker
          title={t('rankingsRankedLeague')}
          accessibilityLabel={`${t('rankingsRankedLeague')}: ${provider.selectedLeague.name}`}
          selectedKey={String(provider.selectedLeague.id)}
          options={provider.leagueOptions.map((league) => ({
            key: String(league.id),
            label: league.name,
            icon: (
              <MobileWebImage
                imageUrl={league.iconUrl}
                contentFit="contain"
                style={styles.choiceImage}
              />
            ),
          }))}
          onSelect={(key) => {
            const league = provider.leagueOptions.find((candidate) => String(candidate.id) === key);
            if (league) void provider.selectLeague(league);
          }}
        />
      </View>
    );
  return null;
}

function RankingLocationPicker({
  provider,
  locationPreferences,
  onSelectLocation,
  onToggleStar,
}: {
  provider: RankingsProvider;
  locationPreferences: LocationPreferences;
  onSelectLocation: (location: RankingLocation) => void;
  onToggleStar: (location: RankingLocation) => void;
}) {
  'use no memo';
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={styles.locationInHeader}>
      <SelectionPicker
        accessibilityLabel={`${t('sideLocation')}: ${provider.location.isWorldwide ? t('rankingsWorldwide') : provider.location.name}`}
        fillWidth
        title={t('rankingsSelectLocation')}
        selectedKey={provider.location.apiPath}
        options={orderedLocations(provider.locations, locationPreferences).map((location) => ({
          key: location.apiPath,
          label: location.isWorldwide ? t('rankingsWorldwide') : location.name,
          searchText: location.countryCode ?? '',
          disabled: location.isWorldwide && !provider.board.supportsWorldwide,
          subtitle:
            location.isWorldwide && !provider.board.supportsWorldwide
              ? t('rankingsWorldwideUnavailable')
              : undefined,
          icon: location.hasValidCountryCode ? (
            <MobileWebImage
              imageUrl={ImageAssets.flag(location.countryCode!)}
              contentFit="contain"
              style={styles.choiceImage}
            />
          ) : (
            <Globe2 color={theme.onSurfaceVariant} />
          ),
          trailingAction: {
            label: `${locationPreferences.starred.includes(location.apiPath) ? t('generalRemoveBookmark') : t('generalBookmark')} ${location.name}`,
            icon: (
              <Star
                size={20}
                color={theme.primary}
                fill={
                  locationPreferences.starred.includes(location.apiPath) ? theme.primary : 'none'
                }
              />
            ),
            onPress: () => onToggleStar(location),
          },
        }))}
        onSelect={(key) => {
          const location = provider.locations.find((candidate) => candidate.apiPath === key);
          if (location) onSelectLocation(location);
        }}
      />
      {provider.locationError ? (
        <CKText role="bodySmall" style={styles.locationError}>
          {t('rankingsLocationsLoadFailed')}
        </CKText>
      ) : null}
    </View>
  );
}

function rankingBackground(board: RankingBoardValue): string {
  if (board === RankingBoard.clanCapital) return ImageAssets.clanCapitalPageBackground;
  return board.isClan ? ImageAssets.clanPageBackground : ImageAssets.legendPageBackground;
}

function IndeterminateProgressBar({ horizontalInset }: { horizontalInset: number }) {
  const theme = useCKTheme();
  const [progress] = useState(() => new Animated.Value(0));
  const [width, setWidth] = useState(0);
  useEffect(() => {
    const loop = Animated.loop(
      Animated.timing(progress, {
        toValue: 1,
        duration: 900,
        easing: Easing.inOut(Easing.linear),
        useNativeDriver: true,
      }),
    );
    loop.start();
    return () => loop.stop();
  }, [progress]);
  const translateX = progress.interpolate({
    inputRange: [0, 1],
    outputRange: [-Math.max(1, width) * 0.35, Math.max(1, width)],
  });
  return (
    <View
      accessibilityRole="progressbar"
      testID="rankings-loading-progress"
      onLayout={(event) => setWidth(event.nativeEvent.layout.width)}
      style={[
        styles.progressTrack,
        {
          backgroundColor: colorWithAlpha(theme.primary, 0.18),
          marginHorizontal: -horizontalInset,
        },
      ]}
    >
      <Animated.View
        style={[
          styles.progressIndicator,
          { backgroundColor: theme.primary, transform: [{ translateX }] },
        ]}
      />
    </View>
  );
}

function RankingRow({ entry, onPress }: { entry: RankingEntry; onPress: () => void }) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  const formattedScore = entry.score.toLocaleString(toIntlLocale(locale));
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${entry.rank}. ${entry.name}, ${formattedScore}`}
      onPress={onPress}
      style={({ pressed }) => [
        styles.row,
        {
          backgroundColor: theme.card,
          borderColor: colorWithAlpha(theme.outlineVariant, 0.32),
          opacity: pressed ? 0.78 : 1,
        },
      ]}
    >
      <View style={styles.rank}>
        <CKText role="labelLarge" muted>{`#${entry.rank}`}</CKText>
        {entry.movement !== '=' ? (
          <CKText
            role="bodySmall"
            style={{ color: entry.movement.startsWith('+') ? '#2E7D32' : '#BA1A1A' }}
          >
            {entry.movement}
          </CKText>
        ) : null}
      </View>
      <MobileWebImage
        testID="ranking-entry-image"
        imageUrl={entry.displayImageUrl}
        style={styles.entryImage}
        contentFit="contain"
      />
      <View style={styles.entryCopy}>
        <CKText role="rowTitle" numberOfLines={1}>
          {entry.name}
        </CKText>
        {entry.subtitle || entry.clanBadgeUrl ? (
          <View style={styles.subtitle}>
            {entry.clanBadgeUrl ? (
              <MobileWebImage imageUrl={entry.clanBadgeUrl} style={styles.clanBadge} />
            ) : null}
            <CKText role="bodySmall" muted numberOfLines={1}>
              {entry.subtitle}
            </CKText>
          </View>
        ) : null}
      </View>
      <MobileWebImage imageUrl={entry.metricImageUrl} style={styles.metric} contentFit="contain" />
      <CKText role="labelLarge" numberOfLines={1} style={styles.score}>
        {formattedScore}
      </CKText>
      <ChevronRight size={20} color={theme.onSurfaceVariant} />
    </Pressable>
  );
}

function RankingDateSheet({
  provider,
  onClose,
}: {
  provider: RankingsProvider;
  onClose: () => void;
}) {
  'use no memo';
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Modal visible transparent animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable
          style={[styles.sheet, { backgroundColor: theme.surface }]}
          onPress={() => undefined}
        >
          <View
            style={[
              styles.handle,
              { backgroundColor: colorWithAlpha(theme.onSurfaceVariant, 0.3) },
            ]}
          />
          <CKText role="titleLarge">{t('rankingsSnapshotDate')}</CKText>
          <View style={styles.sheetBody}>
            <CalendarPicker
              start={
                provider.period === RankingPeriod.current ? provider.today : provider.historyDate
              }
              minimum={provider.earliestHistoryDate}
              maximum={provider.today}
              isDateSelectable={(value) => isRankingSnapshotDate(provider.board, value)}
              onChange={(value) => {
                onClose();
                void provider.selectDate(value);
              }}
            />
          </View>
        </Pressable>
      </Pressable>
    </Modal>
  );
}
type Translate = ReturnType<typeof useI18n>['t'];
export function boardLabel(board: RankingBoardValue, t: Translate): string {
  switch (board.name) {
    case 'playerHome':
    case 'clanHome':
      return t('upgradeTrackerHomeVillage');
    case 'playerBuilder':
    case 'clanBuilder':
      return t('rankingsBuilderBase');
    case 'playerTownHall':
      return t('rankingsTownHall');
    case 'playerRanked':
      return t('rankingsRankedLeague');
    case 'clanCapital':
      return t('rankingsClanCapital');
    case 'clanDonations':
      return t('rankingsDonations');
    case 'clanWarWins':
      return t('rankingsWarWins');
    case 'clanWinStreak':
      return t('rankingsWinStreak');
  }
}
function formatDate(value: Date, locale: string): string {
  return new Intl.DateTimeFormat(toIntlLocale(locale), {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(value);
}
function formatLongDate(value: Date, locale: string): string {
  return new Intl.DateTimeFormat(toIntlLocale(locale), { dateStyle: 'long' }).format(value);
}
const styles = StyleSheet.create({
  fill: { flex: 1 },
  locationInHeader: { width: '100%', maxWidth: 560, alignSelf: 'center', gap: 6 },
  locationError: { color: '#FFF', textAlign: 'center' },
  controls: { marginBottom: 4 },
  entryCopy: { flex: 1, minWidth: 0 },
  progressTrack: { height: 2, overflow: 'hidden', marginBottom: 12 },
  progressIndicator: { width: '35%', height: 2 },
  feedback: { marginBottom: 14 },
  empty: { margin: 24 },
  row: {
    minHeight: 64,
    borderWidth: 1,
    borderRadius: 16,
    marginVertical: 4,
    paddingHorizontal: 10,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  rank: { width: 42 },
  entryImage: { width: 42, height: 42 },
  subtitle: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  clanBadge: { width: 17, height: 17 },
  metric: { width: 19, height: 19 },
  score: { maxWidth: 74 },
  overlay: { flex: 1, backgroundColor: '#0007', justifyContent: 'flex-end' },
  sheet: {
    width: '100%',
    maxWidth: 720,
    alignSelf: 'center',
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    maxHeight: '92%',
    padding: 20,
    paddingTop: 8,
    gap: 12,
  },
  handle: { width: 36, height: 4, borderRadius: 2, alignSelf: 'center' },
  sheetBody: { maxHeight: 620 },
  choiceImage: { width: 36, height: 36 },
});
