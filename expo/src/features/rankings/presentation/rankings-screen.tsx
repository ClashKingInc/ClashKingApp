import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import {
  Animated,
  Easing,
  FlatList,
  Modal,
  Platform,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
} from 'react-native';
import {
  ArrowLeft,
  CalendarDays,
  Check,
  ChevronDown,
  ChevronRight,
  Globe2,
  History,
  ChartNoAxesColumnIncreasing,
  RefreshCw,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  CalendarPicker,
  EmptyState,
  ErrorState,
  GlassSurface,
  MobileWebImage,
  SelectionPickerModal,
  SkeletonLoadingDialog,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { RankingsProvider } from '../data';
import {
  RankingAudience,
  RankingBoard,
  RankingPeriod,
  type RankingBoardValue,
  type RankingEntry,
} from '../models';

type RankingListItem =
  | { readonly kind: 'navigation' }
  | { readonly kind: 'content' }
  | { readonly kind: 'entry'; readonly entry: RankingEntry };

export function RankingsScreen({
  provider,
  revision,
  onBack,
  onOpenEntry,
  onMessage,
}: {
  provider: RankingsProvider;
  /** Changes whenever the mutable provider publishes a new snapshot. */
  revision: number;
  onBack: () => void;
  onOpenEntry: (entry: RankingEntry) => Promise<void>;
  onMessage: (message: string) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const desktop = Platform.OS === 'web' && width >= 900;
  const horizontal = Math.max(16, (width - 1120) / 2);
  const availableWidth = Math.min(1120, width - horizontal * 2);
  const heroHeight = insets.top + (desktop ? 210 : 246);
  const pinOffset = heroHeight - insets.top;
  const listRef = useRef<FlatList<RankingListItem>>(null);
  const scrollOffset = useRef(0);
  const [navigationPinned, setNavigationPinned] = useState(false);
  const [sheet, setSheet] = useState<'location' | 'townHall' | 'league' | 'date' | null>(null);
  const [menu, setMenu] = useState<{
    readonly kind: 'boards' | 'period';
    readonly top: number;
  } | null>(null);
  const [opening, setOpening] = useState(false);
  const entries = useMemo(() => provider.result?.entries ?? [], [provider.result]);
  const listItems = useMemo<readonly RankingListItem[]>(
    () => [
      { kind: 'navigation' },
      { kind: 'content' },
      ...entries.map((entry) => ({ kind: 'entry' as const, entry })),
    ],
    [entries],
  );
  const prepareBodySelection = () => {
    if (scrollOffset.current <= pinOffset) return;
    scrollOffset.current = pinOffset;
    listRef.current?.scrollToOffset({ offset: pinOffset, animated: false });
  };
  const selectAudience = (value: typeof provider.audience) => {
    if (provider.audience === value) return;
    prepareBodySelection();
    void provider.selectAudience(value);
  };
  const selectBoard = (board: RankingBoardValue) => {
    if (provider.board === board) return;
    prepareBodySelection();
    void provider.selectBoard(board);
  };
  const handleScroll = (event: NativeSyntheticEvent<NativeScrollEvent>) => {
    const offset = Math.max(0, event.nativeEvent.contentOffset.y);
    scrollOffset.current = offset;
    const pinned = offset >= pinOffset;
    setNavigationPinned((current) => (current === pinned ? current : pinned));
  };
  const openMenu = (kind: 'boards' | 'period') => {
    setMenu({
      kind,
      top: Math.max(insets.top, heroHeight - scrollOffset.current) + 50,
    });
  };
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
  const controls = (
    <RankingControls
      provider={provider}
      openSheet={setSheet}
      locale={locale}
      availableWidth={availableWidth}
    />
  );

  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.fill, { backgroundColor: theme.background }]}
    >
      <FlatList
        ref={listRef}
        data={listItems}
        extraData={revision}
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
        onScroll={handleScroll}
        scrollEventThrottle={16}
        contentContainerStyle={{ paddingBottom: insets.bottom + 24 }}
        ListHeaderComponent={
          <View style={{ height: heroHeight }}>
            <MobileWebImage
              imageUrl={ImageAssets.legendPageBackground}
              contentFit="cover"
              style={styles.heroBackground}
            />
            <View style={styles.heroScrim} />
            <View
              style={[
                styles.hero,
                { paddingTop: insets.top, paddingHorizontal: desktop ? 24 : 12 },
              ]}
            >
              <View style={styles.headerRow}>
                <IconButton label={materialBackLabel(locale)} onPress={onBack}>
                  <ArrowLeft color="#FFF" />
                </IconButton>
                <IconButton label={t('sideRefresh')} onPress={() => void provider.reload()}>
                  <RefreshCw color="#FFF" />
                </IconButton>
              </View>
              <View style={styles.heroIdentity}>
                <MobileWebImage
                  imageUrl={provider.board.iconUrl}
                  style={{ width: desktop ? 44 : 58, height: desktop ? 44 : 58 }}
                  contentFit="contain"
                />
                <CKText role="screenTitle" style={styles.white}>
                  {t('sideRankingsTitle')}
                </CKText>
                <CKText role="bodySmall" style={styles.heroSubtitle} numberOfLines={2}>
                  {t('sideRankingsSubtitle')}
                </CKText>
              </View>
              <Segmented
                values={[
                  { key: RankingAudience.players, label: t('searchTabPlayers') },
                  { key: RankingAudience.clans, label: t('searchTabClans') },
                ]}
                selected={provider.audience}
                onSelect={(value) => selectAudience(value as typeof provider.audience)}
              />
            </View>
          </View>
        }
        renderItem={({ item }) => {
          if (item.kind === 'navigation') {
            return (
              <RankingDestinationBar
                provider={provider}
                onOpenBoards={() => openMenu('boards')}
                onOpenPeriod={() => openMenu('period')}
              />
            );
          }
          if (item.kind === 'content') {
            return (
              <View style={{ paddingHorizontal: horizontal, paddingTop: 14 }}>
                {controls}
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
      {navigationPinned ? (
        <View
          style={[
            styles.pinnedNavigation,
            { height: insets.top + 50, paddingTop: insets.top, backgroundColor: theme.background },
          ]}
        >
          <RankingDestinationBar
            provider={provider}
            onOpenBoards={() => openMenu('boards')}
            onOpenPeriod={() => openMenu('period')}
          />
        </View>
      ) : null}
      {sheet ? (
        <RankingSheet
          kind={sheet}
          provider={provider}
          locale={locale}
          onClose={() => setSheet(null)}
        />
      ) : null}
      {menu ? (
        <RankingMenu
          kind={menu.kind}
          provider={provider}
          top={menu.top}
          viewportWidth={width}
          onClose={() => setMenu(null)}
          onSelectBoard={selectBoard}
        />
      ) : null}
      <SkeletonLoadingDialog visible={opening} />
    </SafeAreaView>
  );
}

function RankingControls({
  provider,
  openSheet,
  locale,
  availableWidth,
}: {
  provider: RankingsProvider;
  openSheet: (sheet: 'location' | 'townHall' | 'league' | 'date') => void;
  locale: string;
  availableWidth: number;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const controls: { readonly key: string; readonly node: ReactNode }[] = [];
  if (provider.board.supportsLocation)
    controls.push({
      key: 'location',
      node: (
        <FilterButton
          label={t('sideLocation')}
          value={provider.location.isWorldwide ? t('rankingsWorldwide') : provider.location.name}
          imageUrl={
            provider.location.hasValidCountryCode
              ? ImageAssets.flag(provider.location.countryCode!)
              : undefined
          }
          icon={<Globe2 color={theme.primary} />}
          enabled={!provider.isLoadingLocations}
          onPress={() => openSheet('location')}
        />
      ),
    });
  if (provider.board === RankingBoard.playerTownHall)
    controls.push({
      key: 'townHall',
      node: (
        <FilterButton
          label={t('sideFilter')}
          value={`TH${provider.townHallLevel}`}
          imageUrl={ImageAssets.townHall(provider.townHallLevel)}
          onPress={() => openSheet('townHall')}
        />
      ),
    });
  if (provider.board === RankingBoard.playerRanked)
    controls.push({
      key: 'league',
      node: (
        <FilterButton
          label={t('sideFilter')}
          value={provider.selectedLeague.name}
          imageUrl={provider.selectedLeague.iconUrl}
          onPress={() => openSheet('league')}
        />
      ),
    });
  return (
    <View style={styles.controls}>
      {provider.period === RankingPeriod.history ? (
        <FilterButton
          label={t('rankingsSnapshotDate')}
          value={formatDate(provider.historyDate, locale)}
          icon={<CalendarDays color={theme.primary} />}
          onPress={() => openSheet('date')}
        />
      ) : null}
      {controls.length ? (
        <View
          style={[
            styles.controlGroup,
            controls.length > 1 && availableWidth >= 520 && styles.controlGroupWide,
          ]}
        >
          {controls.map((control) => (
            <View
              key={control.key}
              style={controls.length > 1 && availableWidth >= 520 ? styles.controlWide : undefined}
            >
              {control.node}
            </View>
          ))}
        </View>
      ) : null}
      {provider.locationError && provider.board.supportsLocation ? (
        <CKText role="bodySmall" style={{ color: '#B3261E' }}>
          {t('rankingsLocationsLoadFailed')}
        </CKText>
      ) : null}
    </View>
  );
}

function RankingDestinationBar({
  provider,
  onOpenBoards,
  onOpenPeriod,
}: {
  provider: RankingsProvider;
  onOpenBoards: () => void;
  onOpenPeriod: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <View
      style={[
        styles.destinationChrome,
        {
          backgroundColor: theme.background,
          borderBottomColor: colorWithAlpha(theme.outlineVariant, 0.35),
        },
      ]}
    >
      <View style={styles.destinationOuter}>
        <View
          style={[
            styles.destinationPicker,
            {
              backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.45),
              borderColor: colorWithAlpha(theme.outlineVariant, 0.32),
            },
          ]}
        >
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={boardLabel(provider.board, t)}
            onPress={onOpenBoards}
            style={styles.destinationMain}
          >
            <MobileWebImage imageUrl={provider.board.iconUrl} style={styles.destinationIcon} />
            <CKText role="rowTitle" numberOfLines={1} style={styles.destinationLabel}>
              {boardLabel(provider.board, t)}
            </CKText>
            <ChevronDown size={18} color={theme.onSurface} />
          </Pressable>
          {provider.board.supportsHistory ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={
                provider.period === RankingPeriod.current
                  ? t('rankingsCurrent')
                  : t('generalHistory')
              }
              onPress={onOpenPeriod}
              style={styles.periodButton}
            >
              <ChevronDown size={16} color={theme.onSurface} />
            </Pressable>
          ) : null}
        </View>
      </View>
    </View>
  );
}

function RankingMenu({
  kind,
  provider,
  top,
  viewportWidth,
  onClose,
  onSelectBoard,
}: {
  kind: 'boards' | 'period';
  provider: RankingsProvider;
  top: number;
  viewportWidth: number;
  onClose: () => void;
  onSelectBoard: (board: RankingBoardValue) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const controlWidth = Math.max(0, Math.min(520, viewportWidth) - 24);
  const controlLeft = Math.max(0, (viewportWidth - Math.min(520, viewportWidth)) / 2) + 12;
  const width = kind === 'boards' ? controlWidth : Math.min(160, controlWidth);
  const left =
    kind === 'boards' ? controlLeft : Math.max(controlLeft, controlLeft + controlWidth - width);
  const selectPeriod = (period: typeof provider.period) => {
    onClose();
    void provider.selectPeriod(period);
  };

  return (
    <Modal visible transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.menuOverlay} onPress={onClose}>
        <View
          accessibilityViewIsModal
          style={[
            styles.menu,
            {
              top,
              left,
              width,
              backgroundColor: theme.surface,
              borderColor: colorWithAlpha(theme.outlineVariant, 0.32),
            },
          ]}
        >
          <ScrollView bounces={false} showsVerticalScrollIndicator={false}>
            {kind === 'boards'
              ? provider.boards.map((board) => (
                  <MenuChoice
                    key={board.name}
                    label={boardLabel(board, t)}
                    selected={provider.board === board}
                    imageUrl={board.iconUrl}
                    onPress={() => {
                      onClose();
                      onSelectBoard(board);
                    }}
                  />
                ))
              : [
                  { value: RankingPeriod.current, label: t('rankingsCurrent') },
                  { value: RankingPeriod.history, label: t('generalHistory') },
                ].map(({ value, label }) => (
                  <MenuChoice
                    key={value}
                    label={label}
                    selected={provider.period === value}
                    onPress={() => selectPeriod(value)}
                  />
                ))}
          </ScrollView>
        </View>
      </Pressable>
    </Modal>
  );
}

function MenuChoice({
  label,
  selected,
  imageUrl,
  onPress,
}: {
  label: string;
  selected: boolean;
  imageUrl?: string;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="menuitem"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={[
        styles.menuChoice,
        selected && { backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.74) },
      ]}
    >
      {imageUrl ? (
        <MobileWebImage imageUrl={imageUrl} style={styles.destinationIcon} contentFit="contain" />
      ) : null}
      <CKText
        numberOfLines={1}
        style={[styles.destinationLabel, { fontWeight: selected ? '700' : '400' }]}
      >
        {label}
      </CKText>
      {selected ? <Check size={16} color={theme.onSurface} /> : null}
    </Pressable>
  );
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
      <MobileWebImage imageUrl={entry.imageUrl} style={styles.entryImage} contentFit="contain" />
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

function RankingSheet({
  kind,
  provider,
  locale,
  onClose,
}: {
  kind: 'location' | 'townHall' | 'league' | 'date';
  provider: RankingsProvider;
  locale: string;
  onClose: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const closeAnd = (action: () => Promise<void>) => {
    onClose();
    void action();
  };
  if (kind === 'location') {
    const selectedKey = provider.location.apiPath;
    return (
      <SelectionPickerModal
        visible
        title={t('rankingsSelectLocation')}
        selectedKey={selectedKey}
        options={provider.locations
          .filter((location) => location.isWorldwide || location.hasValidCountryCode)
          .map((location) => ({
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
          }))}
        onClose={onClose}
        onSelect={(key) => {
          const location = provider.locations.find((candidate) => candidate.apiPath === key);
          if (location) closeAnd(() => provider.selectLocation(location));
        }}
      />
    );
  }
  if (kind === 'townHall') {
    return (
      <SelectionPickerModal
        visible
        title={t('rankingsTownHall')}
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
        onClose={onClose}
        onSelect={(key) => closeAnd(() => provider.selectTownHall(Number(key)))}
      />
    );
  }
  if (kind === 'league') {
    return (
      <SelectionPickerModal
        visible
        title={t('rankingsRankedLeague')}
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
        onClose={onClose}
        onSelect={(key) => {
          const league = provider.leagueOptions.find((candidate) => String(candidate.id) === key);
          if (league) closeAnd(() => provider.selectLeague(league));
        }}
      />
    );
  }
  let title = '';
  let body: ReactNode = null;
  if (kind === 'date') {
    title = t('rankingsSnapshotDate');
    const yesterday = new Date();
    yesterday.setHours(0, 0, 0, 0);
    yesterday.setDate(yesterday.getDate() - 1);
    const firstDate = new Date(
      yesterday.getFullYear() - 3,
      yesterday.getMonth(),
      yesterday.getDate(),
    );
    body = (
      <CalendarPicker
        start={provider.historyDate > yesterday ? yesterday : provider.historyDate}
        minimum={firstDate}
        maximum={yesterday}
        onChange={(value) => closeAnd(() => provider.selectHistoryDate(value))}
      />
    );
  }
  return (
    <Modal visible={kind != null} transparent animationType="slide" onRequestClose={onClose}>
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
          {title ? <CKText role="titleLarge">{title}</CKText> : null}
          <View style={styles.sheetBody}>{body}</View>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function FilterButton({
  label,
  value,
  imageUrl,
  icon,
  enabled = true,
  onPress,
}: {
  label: string;
  value: string;
  imageUrl?: string;
  icon?: ReactNode;
  enabled?: boolean;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${label}: ${value}`}
      accessibilityState={{ disabled: !enabled }}
      disabled={!enabled}
      onPress={onPress}
      style={[
        styles.filter,
        {
          backgroundColor: theme.surfaceContainerHighest,
          borderColor: colorWithAlpha(theme.outlineVariant, 0.48),
        },
        !enabled && { opacity: 0.5 },
      ]}
    >
      {imageUrl ? (
        <MobileWebImage imageUrl={imageUrl} style={styles.filterImage} contentFit="contain" />
      ) : (
        icon
      )}
      <View style={styles.entryCopy}>
        <CKText role="labelSmall" muted>
          {label}
        </CKText>
        <CKText role="rowTitle" numberOfLines={1}>
          {value}
        </CKText>
      </View>
      <ChevronDown size={20} color={theme.onSurfaceVariant} />
    </Pressable>
  );
}
function Segmented({
  values,
  selected,
  onSelect,
}: {
  values: readonly { key: string; label: string }[];
  selected: string;
  onSelect: (key: string) => void;
}) {
  return (
    <GlassSurface cornerRadius={ckRadius.pill} style={styles.segmented}>
      {values.map((value) => (
        <Pressable
          key={value.key}
          accessibilityRole="tab"
          accessibilityState={{ selected: value.key === selected }}
          onPress={() => onSelect(value.key)}
          style={[styles.segment, value.key === selected && styles.segmentSelected]}
        >
          <CKText role="labelLarge" style={styles.white}>
            {value.label}
          </CKText>
        </Pressable>
      ))}
    </GlassSurface>
  );
}
function IconButton({
  label,
  onPress,
  children,
}: {
  label: string;
  onPress: () => void;
  children: ReactNode;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={styles.iconButton}
    >
      {children}
    </Pressable>
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
const styles = StyleSheet.create({
  fill: { flex: 1 },
  heroBackground: { position: 'absolute', top: 0, right: 0, bottom: 0, left: 0 },
  heroScrim: { ...StyleSheet.absoluteFill, backgroundColor: '#0008' },
  hero: { flex: 1, paddingBottom: 14 },
  headerRow: {
    height: 52,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  iconButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  heroIdentity: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 3 },
  white: { color: '#FFF' },
  heroSubtitle: { color: '#FFFFFFC7', textAlign: 'center', fontWeight: '600' },
  segmented: {
    height: 44,
    flexDirection: 'row',
    alignSelf: 'center',
    width: '100%',
    maxWidth: 520,
    padding: 4,
  },
  segment: { flex: 1, alignItems: 'center', justifyContent: 'center', borderRadius: 999 },
  segmentSelected: { backgroundColor: '#FFFFFF2E' },
  destinationChrome: {
    height: 50,
    borderBottomWidth: StyleSheet.hairlineWidth,
    alignItems: 'center',
    justifyContent: 'center',
  },
  destinationOuter: { width: '100%', maxWidth: 520, paddingHorizontal: 12 },
  destinationPicker: {
    height: 44,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: ckRadius.chip,
    borderWidth: 1,
    overflow: 'hidden',
  },
  destinationMain: {
    flex: 1,
    minWidth: 0,
    height: 44,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 10,
  },
  destinationIcon: { width: 20, height: 20 },
  destinationLabel: { flex: 1, minWidth: 0 },
  periodButton: {
    width: 24,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pinnedNavigation: { position: 'absolute', zIndex: 20, top: 0, left: 0, right: 0 },
  menuOverlay: { flex: 1 },
  menu: {
    position: 'absolute',
    maxHeight: 320,
    borderRadius: ckRadius.chip,
    borderWidth: StyleSheet.hairlineWidth,
    paddingHorizontal: 6,
    paddingVertical: 2,
    ...Platform.select({ web: { boxShadow: '0 4px 12px #00000033' }, default: {} }),
  },
  menuChoice: {
    minHeight: 40,
    borderRadius: 12,
    paddingHorizontal: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  controls: { gap: 10, paddingBottom: 10 },
  controlGroup: { gap: 10 },
  controlGroupWide: { flexDirection: 'row' },
  controlWide: { flex: 1, minWidth: 0 },
  filter: {
    minHeight: 58,
    borderRadius: 16,
    borderWidth: 1,
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 11,
  },
  filterImage: { width: 24, height: 24 },
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
  search: {
    minHeight: 54,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 14,
    borderRadius: 16,
    marginBottom: 8,
  },
  searchInput: { flex: 1, minHeight: 48, fontSize: 16 },
  choice: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 12,
    borderRadius: 14,
  },
  choiceImage: { width: 36, height: 36 },
  noResults: { padding: ckSpacing.xl, textAlign: 'center' },
});
