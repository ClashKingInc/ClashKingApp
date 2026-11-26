import { MorphFilterSheet, type FilterChoicePage } from '../../ui/morph-filter-sheet';
import { scheduleOnRN } from 'react-native-worklets';
import { getSearchFieldOrigin, clearSearchFieldOrigin } from '../../ui/search-transition';
import Reanimated, {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
  Easing,
} from 'react-native-reanimated';
import { classifySearchQuery, type SearchRequestState } from './search-state';
import type { TextInputInstance } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAdaptiveLayout } from '../../ui/adaptive-layout';
import { ResponsiveGrid } from '../../ui/responsive-grid';
import {
  createContext,
  useContext,
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
  useSyncExternalStore,
  type ReactNode,
  type ComponentRef,
} from 'react';
import { SlidingSegmentControl } from '../../ui/sliding-segment-control';
import {
  Keyboard,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
  useWindowDimensions,
} from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import {
  ChevronLeft,
  ChevronRight,
  CornerUpLeft,
  Globe2,
  Search,
  Shield,
  SlidersHorizontal,
  Swords,
} from 'lucide-react-native';

import { ImageAssets } from '../../core/assets/image-assets';
import { getMaxTownHallLevel } from '../../core/game-data/game-data-service';
import { gameDataState, subscribeToGameDataRevision } from '../../core/game-data/game-data-state';
import { GlobalSearchHeaderFrame, globalSearchHeaderLayout } from '../../ui/header';
import { materialBackLabel, useI18n } from '../../i18n';
import { primaryTabBarClearance } from '../../shell/contracts';
import {
  CKText,
  ckSpacing,
  GlassControlSurface,
  LoadingIndicator,
  SkeletonContent,
  MobileWebImage,
  PressableSurface,
  SelectionPicker,
  useCKTheme,
  useCKAccessibility,
} from '../../ui';
import {
  emptyClanSearchFilters,
  emptyPlayerSearchFilters,
  isClanSearchFiltersEmpty,
  isPlayerSearchFiltersEmpty,
  numberValue,
  recordValue,
  stringValue,
  type ClanSearchFilters,
  type JsonRecord,
  type PlayerSearchFilters,
  type RecentSearchItem,
  type SearchLeague,
  type SearchLocation,
  type SearchMode,
} from './models';

interface FilterOptionsFeedbackProps {
  readonly filterOptionsStatus: 'loading' | 'ready' | 'error';
  readonly onRetryFilterOptions: () => void;
}

export interface SearchScreenProps extends FilterOptionsFeedbackProps {
  readonly overlay?: boolean;
  readonly autofocus?: boolean;
  readonly query: string;
  readonly mode: SearchMode;
  readonly filtersExpanded: boolean;
  readonly playerFilters: PlayerSearchFilters;
  readonly clanFilters: ClanSearchFilters;
  readonly results: readonly JsonRecord[];
  readonly recents: readonly RecentSearchItem[];
  readonly locations: readonly SearchLocation[];
  readonly leagues: readonly SearchLeague[];
  readonly searchStatus: SearchRequestState['status'];
  readonly hasMoreResults: boolean;
  readonly paginationStatus: SearchRequestState['paginationStatus'];
  readonly onQueryChange: (value: string) => void;
  readonly onSubmit: () => void;
  readonly onLoadMore: () => void;
  readonly onModeChange: (mode: SearchMode) => void;
  readonly onFiltersExpandedChange: (expanded: boolean) => void;
  readonly onPlayerFiltersChange: (filters: PlayerSearchFilters) => void;
  readonly onClanFiltersChange: (filters: ClanSearchFilters) => void;
  readonly onOpenResult: (result: JsonRecord, mode: SearchMode) => void;
  readonly onOpenRecent: (item: RecentSearchItem) => void;
  readonly onCancel?: () => void;
}

export function SearchScreen(props: SearchScreenProps) {
  const { t, isRtl, locale } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const bottomPadding = primaryTabBarClearance(Platform.OS, width, insets.bottom) + ckSpacing.lg;
  const controlBounds = (layout.isExpanded || layout.isDuo) && {
    width: '100%' as const,
    maxWidth: layout.readableMaxWidth,
    alignSelf: 'center' as const,
  };
  const resultBounds = (layout.isExpanded || layout.isDuo) && {
    width: '100%' as const,
    maxWidth: layout.contentMaxWidth,
    alignSelf: 'center' as const,
  };
  const { reduceMotion } = useCKAccessibility();
  const [fieldSettled, setFieldSettled] = useState(!props.overlay || reduceMotion);
  const inputRef = useRef<TextInputInstance>(null);
  const [fieldOrigin] = useState(() => (props.overlay ? getSearchFieldOrigin() : null));
  useEffect(() => {
    if (props.overlay) clearSearchFieldOrigin();
  }, [props.overlay]);
  const fieldSlotRef = useRef<ComponentRef<typeof View>>(null);
  const fieldProgress = useSharedValue(fieldOrigin && !reduceMotion ? 0 : 1);
  const fieldGeometry = useSharedValue({
    x: 0,
    y: 0,
    width: 0,
    height: 48,
    dx: 0,
    dy: 0,
    dw: 0,
    dh: 0,
  });
  const [fieldMeasured, setFieldMeasured] = useState(false);
  const [isClosing, setIsClosing] = useState(false);
  const closingSearch = useRef(false);
  const motionStarted = useRef(false);
  const fieldMotionStyle = useAnimatedStyle(() => {
    const g = fieldGeometry.get();
    const remaining = 1 - fieldProgress.get();
    return {
      width: g.width + g.dw * remaining,
      height: g.height + g.dh * remaining,
      transform: [{ translateX: g.dx * remaining }, { translateY: g.dy * remaining }],
    };
  });
  const fieldSurfaceStyle = useAnimatedStyle(() => {
    const g = fieldGeometry.get();
    return {
      width: Math.max(g.width, g.width + g.dw),
      height: Math.max(g.height, g.height + g.dh),
    };
  });
  const fieldGlassStyle = useAnimatedStyle(() => {
    const g = fieldGeometry.get();
    const remaining = 1 - fieldProgress.get();
    const baseWidth = Math.max(1, g.width, g.width + g.dw);
    const width = g.width + g.dw * remaining;
    // Transform only the material; text is a sibling at its natural size.
    // UIKit's glass view never receives an animated layout size.
    return { transform: [{ translateX: (width - baseWidth) / 2 }, { scaleX: width / baseWidth }] };
  });
  const screenRevealStyle = useAnimatedStyle(() => ({ opacity: fieldProgress.get() }));
  const contentExitStyle = useAnimatedStyle(() => ({
    opacity: fieldProgress.get() * fieldProgress.get(),
    transform: [{ translateY: (1 - fieldProgress.get()) * 8 }],
  }));
  const controlsMotionStyle = useAnimatedStyle(() => ({
    // Controls clear the field's return path early, before its edge reaches them.
    opacity: Math.max(0, Math.min(1, (fieldProgress.get() - 0.65) / 0.35)),
    transform: [{ translateY: (1 - fieldProgress.get()) * -6 }],
  }));
  const finishOpen = useCallback(() => setFieldSettled(true), []);
  const measureField = () => {
    fieldSlotRef.current?.measureInWindow((x, y, width, height) => {
      if (!width || !height) return;
      // Match actual field edges, not a translation-only proxy that jumps
      // when the wider home header replaces the editable field.
      fieldGeometry.set({
        x,
        y,
        width,
        height,
        dx: fieldOrigin ? fieldOrigin.x - x : 0,
        dy: fieldOrigin ? fieldOrigin.y - y : 0,
        dw: fieldOrigin ? fieldOrigin.width - width : 0,
        dh: fieldOrigin ? fieldOrigin.height - height : 0,
      });
      setFieldMeasured(true);
    });
  };
  useLayoutEffect(() => {
    if (!fieldMeasured || motionStarted.current) return;
    motionStarted.current = true;
    // Start only after the measured field is visible, so measurement/React
    // commit time cannot consume the first frames of the movement.
    fieldProgress.set(
      withTiming(
        1,
        {
          duration: reduceMotion ? 0 : 260,
          easing: Easing.bezier(0.4, 0, 0.2, 1),
        },
        (finished) => {
          if (finished) scheduleOnRN(finishOpen);
        },
      ),
    );
  }, [fieldMeasured, fieldProgress, reduceMotion, finishOpen]);
  const finishClose = () => props.onCancel?.();
  const closeSearch = () => {
    if (closingSearch.current) return;
    closingSearch.current = true;
    setIsClosing(true);
    inputRef.current?.blur();
    Keyboard.dismiss();
    if (reduceMotion || !fieldOrigin || !fieldMeasured) {
      finishClose();
      return;
    }
    // A bounded duration avoids waiting on an imperceptible spring tail before
    // returning to the home header. The field itself never fades or scales text.
    fieldProgress.set(
      withTiming(
        0,
        {
          duration: 200,
          easing: Easing.bezier(0.2, 0, 0, 1),
        },
        (finished) => {
          if (finished) scheduleOnRN(finishClose);
        },
      ),
    );
  };
  const openFilters = () => {
    inputRef.current?.blur();
    Keyboard.dismiss();
    props.onFiltersExpandedChange(true);
  };
  const [headerLaidOut, setHeaderLaidOut] = useState(!props.overlay);
  const searchQuery = classifySearchQuery(props.query);
  const activeFilters =
    !props.query.trimStart().startsWith('#') &&
    (props.mode === 'clans'
      ? !isClanSearchFiltersEmpty(props.clanFilters)
      : !isPlayerSearchFiltersEmpty(props.playerFilters));
  const isSearching = props.searchStatus === 'loading';
  const paginationFailed =
    props.paginationStatus === 'error' || props.paginationStatus === 'expired';
  const visibleRecents = props.recents.filter((item) =>
    props.mode === 'players' ? item.type === 'player' : item.type === 'clan',
  );

  useEffect(() => {
    // Keyboard layout and recent-image mounting must start after the field
    // reaches its target; doing both during the morph competes for frame time.
    if (!props.autofocus || !headerLaidOut || (props.overlay && !fieldSettled)) return;
    const frame = requestAnimationFrame(() => inputRef.current?.focus());
    return () => cancelAnimationFrame(frame);
  }, [props.autofocus, headerLaidOut, props.overlay, fieldSettled]);

  const searchFieldContent = (
    <>
      <Search size={20} color={theme.onSurfaceVariant} />
      <View style={{ flex: 1, justifyContent: 'center' }}>
        <TextInput
          ref={inputRef}
          testID="search-input"
          accessibilityLabel={
            props.mode === 'players' ? t('playerSearchPlaceholder') : t('clanSearchPlaceholder')
          }
          editable={!isClosing}
          allowFontScaling
          autoCapitalize="none"
          autoCorrect={false}
          onChangeText={props.onQueryChange}
          onSubmitEditing={props.onSubmit}
          placeholder={
            props.mode === 'players' ? t('playerSearchPlaceholder') : t('clanSearchPlaceholder')
          }
          placeholderTextColor={theme.onSurfaceVariant}
          returnKeyType="search"
          style={[
            styles.searchInput,
            props.overlay && (!fieldSettled || isClosing) && { opacity: 0 },
            { color: theme.onSurface, textAlign: isRtl ? 'right' : 'left' },
          ]}
          value={props.query}
        />
        {props.overlay && (!fieldSettled || isClosing) ? (
          <CKText muted numberOfLines={1} style={{ position: 'absolute', left: 0, right: 0 }}>
            {t('searchGlobalHint')}
          </CKText>
        ) : null}
      </View>
      {!props.overlay ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('generalFilters')}
          onPress={openFilters}
          style={styles.fieldAction}
        >
          <SlidersHorizontal
            size={22}
            color={activeFilters ? theme.primary : theme.onSurfaceVariant}
          />
        </Pressable>
      ) : null}
      {isSearching ? <LoadingIndicator /> : null}
    </>
  );
  const searchField = (
    <GlassControlSurface style={[styles.searchField, isRtl && styles.rowRtl]}>
      {searchFieldContent}
    </GlassControlSurface>
  );

  let searchFeedback: string | undefined;
  if (searchQuery.kind === 'tooShort' || (searchQuery.kind === 'empty' && activeFilters)) {
    searchFeedback = t('searchMinimumCharacters');
  } else if (searchQuery.kind === 'invalidTag') {
    searchFeedback = t('apiErrorBadRequest');
  } else if (props.searchStatus === 'error') {
    searchFeedback = t('apiErrorOperationFailed');
  } else if (props.searchStatus === 'success' && props.results.length === 0) {
    searchFeedback = t(activeFilters ? 'generalNoFilteredResults' : 'searchNoResult');
  }

  const resultContent = (
    <>
      {activeFilters ? <ActiveSearchFilters {...props} /> : null}
      {searchFeedback ? (
        <View style={styles.searchFeedback}>
          <CKText role="bodyLarge" muted accessibilityLiveRegion="polite" style={styles.noResults}>
            {searchFeedback}
          </CKText>
          {props.searchStatus === 'error' ? (
            <SearchTextAction label={t('generalRetry')} onPress={props.onSubmit} />
          ) : null}
        </View>
      ) : null}
      {searchQuery.kind === 'empty' && visibleRecents.length ? (
        <>
          <CKText
            skeleton={false}
            role="titleMedium"
            style={[
              styles.recentTitle,
              { marginTop: props.overlay ? 0 : 16 },
              props.overlay ? { color: theme.onSurfaceVariant } : undefined,
              isRtl && styles.rtlText,
            ]}
          >
            {t('searchRecent')}
          </CKText>
          <SearchResultCollection>
            {visibleRecents.slice(0, 10).map((item) => (
              <EntityTile
                key={`${item.type}:${item.tag}`}
                name={item.name}
                tag={item.tag}
                subtitle={recentSubtitle(item, t)}
                imageUrl={item.imageUrl}
                type={item.type}
                overlay={props.overlay ?? false}
                onPress={() => props.onOpenRecent(item)}
              />
            ))}
          </SearchResultCollection>
        </>
      ) : null}
      {isSearching ? (
        <SkeletonContent loading>
          <SearchResultCollection>
            {[0, 1, 2, 3, 4].map((index) => (
              <EntityTile
                key={index}
                name="ClashKing player"
                tag="#PLAYER"
                subtitle="Player information"
                imageUrl={
                  props.mode === 'players' ? ImageAssets.townHall(1) : ImageAssets.clanCastle
                }
                type={props.mode === 'players' ? 'player' : 'clan'}
                overlay={props.overlay ?? false}
                onPress={() => {}}
              />
            ))}
          </SearchResultCollection>
        </SkeletonContent>
      ) : props.results.length > 0 ? (
        <SearchResultCollection>
          {props.results.map((result, index) => (
            <EntityTile
              key={`${stringValue(result.tag)}:${index}`}
              name={stringValue(result.name)}
              tag={stringValue(result.tag)}
              subtitle={resultSubtitle(result, props.mode, t)}
              imageUrl={resultImage(result, props.mode)}
              type={props.mode === 'players' ? 'player' : 'clan'}
              overlay={props.overlay ?? false}
              onPress={() => props.onOpenResult(result, props.mode)}
            />
          ))}
        </SearchResultCollection>
      ) : null}
      {props.hasMoreResults || props.paginationStatus !== 'idle' ? (
        <View style={styles.pagination}>
          {paginationFailed ? (
            <CKText muted accessibilityLiveRegion="polite" style={styles.noResults}>
              {t('apiErrorOperationFailed')}
            </CKText>
          ) : null}
          {props.paginationStatus === 'loading' ? (
            <LoadingIndicator />
          ) : (
            <SearchTextAction
              label={t(paginationFailed ? 'generalRetry' : 'postsLoadMore')}
              onPress={props.onLoadMore}
            />
          )}
        </View>
      ) : null}
    </>
  );

  if (props.overlay) {
    return (
      <GlobalSearchHeaderFrame
        style={[
          styles.screen,
          (layout.isDuo || layout.isTablet) && {
            paddingLeft: insets.left,
            paddingRight: insets.right,
          },
        ]}
      >
        <Reanimated.View
          pointerEvents="none"
          style={[
            StyleSheet.absoluteFill,
            { backgroundColor: theme.background },
            screenRevealStyle,
          ]}
        />
        <View
          onLayout={() => setHeaderLaidOut(true)}
          style={[styles.overlayHeader, isRtl && styles.rowRtl, controlBounds]}
        >
          <Reanimated.View style={controlsMotionStyle}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={materialBackLabel(locale)}
              onPress={closeSearch}
              style={styles.cancelButton}
            >
              <ChevronLeft
                size={22}
                color={theme.onSurface}
                style={isRtl && styles.mirrorHorizontal}
              />
            </Pressable>
          </Reanimated.View>
          <View
            ref={fieldSlotRef}
            collapsable={false}
            onLayout={measureField}
            style={[styles.grow, { height: globalSearchHeaderLayout.fieldHeight, zIndex: 1 }]}
          >
            <Reanimated.View
              style={[
                {
                  position: 'absolute',
                  left: 0,
                  top: 0,
                  opacity: fieldMeasured ? 1 : 0,
                },
                fieldMotionStyle,
              ]}
            >
              <Reanimated.View
                pointerEvents="none"
                style={[StyleSheet.absoluteFill, fieldSurfaceStyle, fieldGlassStyle]}
              >
                <GlassControlSurface style={{ flex: 1 }} />
              </Reanimated.View>
              <View style={[StyleSheet.absoluteFill, styles.searchField, isRtl && styles.rowRtl]}>
                {searchFieldContent}
              </View>
            </Reanimated.View>
          </View>
          <Reanimated.View style={controlsMotionStyle}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('generalFilters')}
              accessibilityState={{ expanded: props.filtersExpanded }}
              onPress={openFilters}
              disabled={!fieldSettled || isClosing}
              style={styles.cancelButton}
            >
              <SlidersHorizontal
                size={22}
                color={activeFilters ? theme.primary : theme.onSurfaceVariant}
              />
              {activeFilters ? (
                <View style={[styles.activeFilterDot, { backgroundColor: theme.primary }]} />
              ) : null}
            </Pressable>
          </Reanimated.View>
        </View>
        <Reanimated.View style={[styles.grow, contentExitStyle]}>
          <View style={[styles.overlayMode, controlBounds]}>
            <ModeSelector mode={props.mode} compact isRtl={isRtl} onChange={props.onModeChange} />
          </View>
          <ScrollView
            keyboardDismissMode="on-drag"
            keyboardShouldPersistTaps="handled"
            style={styles.grow}
            contentContainerStyle={[
              styles.overlayResults,
              resultBounds,
              { paddingBottom: bottomPadding },
              props.query.trim().length !== 0 || visibleRecents.length === 0
                ? styles.overlayResultSpacer
                : undefined,
            ]}
            testID="search-overlay-scroll"
          >
            {fieldSettled ? resultContent : null}
          </ScrollView>
        </Reanimated.View>
        {props.filtersExpanded ? <SearchFiltersSheet {...props} /> : null}
      </GlobalSearchHeaderFrame>
    );
  }

  return (
    <View style={[styles.screen, { backgroundColor: theme.background }]}>
      <ScrollView
        keyboardDismissMode="on-drag"
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={[styles.page, resultBounds, { paddingBottom: bottomPadding }]}
      >
        {controlBounds ? (
          <View style={controlBounds}>
            <ModeSelector mode={props.mode} isRtl={isRtl} onChange={props.onModeChange} />
          </View>
        ) : (
          <ModeSelector mode={props.mode} isRtl={isRtl} onChange={props.onModeChange} />
        )}
        <View style={[styles.pageSearch, controlBounds]}>{searchField}</View>

        <View
          style={
            props.query.trim().length !== 0 || visibleRecents.length === 0
              ? styles.pageResultSpacer
              : undefined
          }
        >
          {resultContent}
        </View>
      </ScrollView>
      {props.filtersExpanded ? <SearchFiltersSheet {...props} /> : null}
    </View>
  );
}

function SearchResultCollection({ children }: { children: ReactNode }) {
  const layout = useAdaptiveLayout();
  if (!layout.isExpanded) return <>{children}</>;
  return (
    <ResponsiveGrid minItemWidth={300} maxColumns={layout.columns(300, 3)} gap={16}>
      {children}
    </ResponsiveGrid>
  );
}

const FilterNavigationContext = createContext<((page: FilterChoicePage) => void) | null>(null);

function ActiveSearchFilters({
  mode,
  playerFilters,
  clanFilters,
  leagues,
  locations,
  onPlayerFiltersChange,
  onClanFiltersChange,
}: SearchScreenProps) {
  const { t, isRtl } = useI18n();
  const labels: string[] = [];
  const clear =
    mode === 'players'
      ? () => onPlayerFiltersChange(emptyPlayerSearchFilters)
      : () => onClanFiltersChange(emptyClanSearchFilters);

  if (mode === 'players') {
    const { minTownHallLevel, maxTownHallLevel, leagueIds } = playerFilters;
    if (minTownHallLevel !== null && minTownHallLevel === maxTownHallLevel) {
      labels.push(t('gameTownHallLevelNumber', { level: minTownHallLevel }));
    } else if (minTownHallLevel !== null || maxTownHallLevel !== null) {
      const range =
        minTownHallLevel === null
          ? `≤${maxTownHallLevel}`
          : maxTownHallLevel === null
            ? `≥${minTownHallLevel}`
            : `${minTownHallLevel}–${maxTownHallLevel}`;
      labels.push(`${t('filtersTownHall')} ${range}`);
    }
    for (const id of leagueIds) {
      labels.push(leagues.find((league) => league.id === id)?.name ?? t('gameLeague'));
    }
  } else {
    const { warFrequency, locationId, minMembers, maxMembers, minClanLevel } = clanFilters;
    if (warFrequency) {
      labels.push(
        warFrequencyOptions(t).find((option) => option.value === warFrequency)?.label ??
          t('warFrequency'),
      );
    }
    if (locationId !== null) {
      labels.push(locations.find((location) => location.id === locationId)?.name ?? t('clanLocation'));
    }
    if (minMembers !== null || maxMembers !== null) {
      labels.push(`${t('clanMembers')} ${minMembers ?? 0}–${maxMembers ?? 50}`);
    }
    if (minClanLevel !== null) labels.push(`${t('clanMinimumLevel')} ${minClanLevel}`);
  }

  return (
    <View style={[styles.appliedFilters, isRtl && styles.rowRtl]} testID="search-active-filters">
      <CKText
        role="bodySmall"
        muted
        accessibilityLiveRegion="polite"
        style={styles.appliedFilterValues}
      >
        {labels.join(' · ')}
      </CKText>
      <SearchTextAction label={t('generalClearFilters')} onPress={clear} />
    </View>
  );
}

function SearchTextAction({ label, onPress }: { label: string; onPress: () => void }) {
  const theme = useCKTheme();
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.searchTextAction}>
      <CKText role="bodySmall" style={{ color: theme.primary }}>
        {label}
      </CKText>
    </Pressable>
  );
}

function FilterOptionsFeedback({
  filterOptionsStatus,
  onRetryFilterOptions,
}: FilterOptionsFeedbackProps) {
  const { t, isRtl } = useI18n();
  return (
    <View style={[styles.filterOptionsFeedback, isRtl && styles.rowRtl]}>
      <CKText muted role="bodySmall" accessibilityLiveRegion="polite">
        {t(filterOptionsStatus === 'error' ? 'generalError' : 'generalLoading')}
      </CKText>
      {filterOptionsStatus === 'error' ? (
        <SearchTextAction label={t('generalRetry')} onPress={onRetryFilterOptions} />
      ) : null}
    </View>
  );
}

function SearchFiltersSheet(props: SearchScreenProps) {
  const { t } = useI18n();
  const [players, setPlayers] = useState(props.playerFilters);
  const [clans, setClans] = useState(props.clanFilters);
  return (
    <MorphFilterSheet
      title={t('searchFilters')}
      applyLabel={t('generalApply')}
      onClose={() => props.onFiltersExpandedChange(false)}
      onReset={() =>
        props.mode === 'players'
          ? setPlayers(emptyPlayerSearchFilters)
          : setClans(emptyClanSearchFilters)
      }
      onApply={() => {
        if (props.mode === 'players') props.onPlayerFiltersChange(players);
        else props.onClanFiltersChange(clans);
      }}
    >
      {(open) => (
        <FilterNavigationContext.Provider value={open}>
          {props.mode === 'players' ? (
            <PlayerFiltersPanel
              value={players}
              leagues={props.leagues}
              onChange={setPlayers}
              filterOptionsStatus={props.filterOptionsStatus}
              onRetryFilterOptions={props.onRetryFilterOptions}
            />
          ) : (
            <ClanFiltersPanel
              value={clans}
              locations={props.locations}
              onChange={setClans}
              filterOptionsStatus={props.filterOptionsStatus}
              onRetryFilterOptions={props.onRetryFilterOptions}
            />
          )}
        </FilterNavigationContext.Provider>
      )}
    </MorphFilterSheet>
  );
}

function ModeSelector({
  mode,
  isRtl,
  onChange,
}: {
  mode: SearchMode;
  compact?: boolean;
  isRtl: boolean;
  onChange: (mode: SearchMode) => void;
}) {
  const { t } = useI18n();
  return (
    <SlidingSegmentControl
      value={mode}
      isRtl={isRtl}
      onChange={onChange}
      options={[
        { value: 'players', label: t('searchTabPlayers') },
        { value: 'clans', label: t('searchTabClans') },
      ]}
      testID="search-mode-selector"
    />
  );
}

function EntityTile({
  name,
  tag,
  subtitle,
  imageUrl,
  type,
  overlay,
  onPress,
}: {
  name: string;
  tag: string;
  subtitle: string;
  imageUrl: string | null;
  type: 'player' | 'clan';
  overlay: boolean;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  const { isRtl } = useI18n();
  const content = (
    <View testID="search-entity-row" style={[styles.entityRow, isRtl && styles.rowRtl]}>
      <View style={[styles.entityImageBox, overlay && styles.overlayImageBox]}>
        {imageUrl ? (
          <MobileWebImage
            imageUrl={imageUrl}
            contentFit="contain"
            // Search rows already know their artwork size. Do not defer the
            // request to a percentage-size measurement inside the pressable.
            style={overlay ? styles.overlayEntityImage : styles.entityImage}
            errorFallback={
              type === 'clan' ? <Shield size={40} color={theme.onSurfaceVariant} /> : undefined
            }
          />
        ) : (
          <Shield size={40} color={theme.onSurfaceVariant} />
        )}
      </View>
      <View style={styles.grow}>
        <CKText
          role="titleMedium"
          numberOfLines={1}
          style={[overlay ? styles.overlayName : undefined, isRtl && styles.rtlText]}
        >
          {name}
        </CKText>
        <CKText
          role="labelLarge"
          muted
          numberOfLines={1}
          style={[styles.tagLine, isRtl && styles.rtlText]}
        >
          {tag}
        </CKText>
        {subtitle ? (
          <CKText
            role="bodySmall"
            muted
            numberOfLines={1}
            style={[styles.subtitle, isRtl && styles.rtlText]}
          >
            {subtitle}
          </CKText>
        ) : null}
      </View>
      {overlay ? (
        <CornerUpLeft
          size={22}
          color={theme.primary}
          style={isRtl ? styles.mirrorHorizontal : undefined}
        />
      ) : isRtl ? (
        <ChevronLeft size={22} color={theme.onSurfaceVariant} />
      ) : (
        <ChevronRight size={22} color={theme.onSurfaceVariant} />
      )}
    </View>
  );
  if (overlay) {
    return (
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${name}, ${tag}`}
        onPress={onPress}
        style={styles.overlayTile}
      >
        {content}
      </Pressable>
    );
  }
  return (
    <PressableSurface
      accessibilityRole="button"
      accessibilityLabel={`${name}, ${tag}`}
      onPress={onPress}
      radius={16}
      style={styles.entityCard}
    >
      {content}
    </PressableSurface>
  );
}

function warFrequencyOptions(t: ReturnType<typeof useI18n>['t']) {
  return [
    { value: '', label: t('generalNotSet') },
    { value: 'always', label: t('clanWarFrequencyAlways') },
    { value: 'never', label: t('clanWarFrequencyNever') },
    { value: 'oncePerWeek', label: t('clanWarFrequencyOncePerWeek') },
    { value: 'moreThanOncePerWeek', label: t('clanWarFrequencyMoreThanOncePerWeek') },
    { value: 'lessThanOncePerWeek', label: t('clanWarFrequencyRarely') },
  ];
}

function ClanFiltersPanel({
  value,
  locations,
  onChange,
  ...optionsFeedback
}: FilterOptionsFeedbackProps & {
  value: ClanSearchFilters;
  locations: readonly SearchLocation[];
  onChange: (value: ClanSearchFilters) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const warOptions = warFrequencyOptions(t);
  const locationOptions = [
    { value: '', label: t('generalNotSet') },
    ...locations.map((location) => ({
      value: String(location.id),
      label: location.name,
      imageUrl: ImageAssets.flag(location.countryCode),
    })),
  ];
  const selectedWarFrequency =
    warOptions.find((option) => option.value === (value.warFrequency ?? ''))?.label ??
    t('generalNotSet');
  const selectedLocation =
    locationOptions.find((option) => option.value === String(value.locationId ?? ''))?.label ??
    t('generalNotSet');
  return (
    <View testID="clan-search-filters" style={styles.filters}>
      <View style={styles.filterPickerRow} testID="clan-war-frequency-filter">
        <FilterLabel
          row
          icon={<Swords size={18} color={theme.onSurfaceVariant} />}
          label={t('warFrequency')}
        />
        <OptionPicker
          accessibilityLabel={`${t('warFrequency')}: ${selectedWarFrequency}`}
          title={t('warFrequency')}
          value={value.warFrequency ?? ''}
          options={warOptions}
          onChange={(next) => onChange({ ...value, warFrequency: next || null })}
        />
      </View>
      <View style={styles.filterPickerRow} testID="clan-location-filter">
        <FilterLabel
          row
          icon={<Globe2 size={18} color={theme.onSurfaceVariant} />}
          label={t('clanLocation')}
        />
        {optionsFeedback.filterOptionsStatus === 'ready' || locations.length > 0 ? (
          <OptionPicker
            accessibilityLabel={`${t('clanLocation')}: ${selectedLocation}`}
            title={t('clanLocation')}
            value={value.locationId === null ? '' : String(value.locationId)}
            options={locationOptions}
            onChange={(next) => onChange({ ...value, locationId: next ? Number(next) : null })}
          />
        ) : (
          <FilterOptionsFeedback {...optionsFeedback} />
        )}
      </View>
      <RangeFilter
        label={`${t('clanMinimumMembers')} – ${t('clanMaximumMembers')}`}
        minimum={0}
        maximum={50}
        step={1}
        lower={value.minMembers ?? 0}
        upper={value.maxMembers ?? 50}
        valueLabel={`${value.minMembers ?? 0} – ${value.maxMembers ?? 50}`}
        onChange={(lower, upper) =>
          onChange({
            ...value,
            minMembers: lower === 0 ? null : lower,
            maxMembers: upper === 50 ? null : upper,
          })
        }
      />
      <SingleFilter
        label={t('clanMinimumLevel')}
        minimum={1}
        maximum={50}
        step={1}
        value={value.minClanLevel ?? 1}
        onChange={(next) => onChange({ ...value, minClanLevel: next === 1 ? null : next })}
      />
    </View>
  );
}

function PlayerFiltersPanel({
  value,
  leagues,
  onChange,
  ...optionsFeedback
}: FilterOptionsFeedbackProps & {
  value: PlayerSearchFilters;
  leagues: readonly SearchLeague[];
  onChange: (value: PlayerSearchFilters) => void;
}) {
  const { t } = useI18n();
  const options: PickerOption[] = [
    { value: '', label: t('generalNotSet') },
    ...[...leagues]
      .sort((left, right) => right.id - left.id)
      .map((league) => ({
        value: String(league.id),
        label: league.name,
        imageUrl: ImageAssets.getLeagueImage(league.name),
      })),
  ];
  const selectedTownHall =
    value.minTownHallLevel !== null && value.minTownHallLevel === value.maxTownHallLevel
      ? value.minTownHallLevel
      : null;
  // Refresh open filters when downloaded static data changes.
  useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => gameDataState.revision,
  );
  const maxTownHall = Math.max(getMaxTownHallLevel(), selectedTownHall ?? 0);
  const townHallOptions = [
    { value: '', label: t('generalNotSet') },
    ...Array.from({ length: maxTownHall }, (_, index) => maxTownHall - index).map((level) => ({
      value: String(level),
      label: t('gameTownHallLevelNumber', { level }),
      imageUrl: ImageAssets.townHall(level),
    })),
  ];
  return (
    <View style={styles.filters}>
      <View style={styles.filterPickerRow}>
        <FilterLabel
          row
          icon={
            <MobileWebImage
              imageUrl={
                options.find((option) => option.value === String(value.leagueIds[0]))?.imageUrl ??
                ImageAssets.getLeagueImage('Unranked')
              }
              contentFit="contain"
              style={styles.filterIconImage}
            />
          }
          label={t('gameLeague')}
        />
        {optionsFeedback.filterOptionsStatus === 'ready' || leagues.length > 0 ? (
          <OptionPicker
            accessibilityLabel={`${t('gameLeague')}: ${
              options.find((option) => option.value === String(value.leagueIds[0]))?.label ??
              t('generalNotSet')
            }`}
            title={t('gameLeague')}
            value={value.leagueIds.length ? String(value.leagueIds[0]) : ''}
            options={options}
            onChange={(next) => onChange({ ...value, leagueIds: next ? [Number(next)] : [] })}
          />
        ) : (
          <FilterOptionsFeedback {...optionsFeedback} />
        )}
      </View>
      <View style={styles.filterPickerRow}>
        <FilterLabel
          row
          icon={
            <MobileWebImage
              imageUrl={ImageAssets.townHall(selectedTownHall ?? 2)}
              contentFit="contain"
              style={styles.filterIconImage}
            />
          }
          label={t('filtersTownHall')}
        />
        <OptionPicker
          accessibilityLabel={`${t('filtersTownHall')}: ${
            townHallOptions.find((option) => option.value === String(selectedTownHall ?? ''))
              ?.label ?? t('generalNotSet')
          }`}
          title={t('filtersTownHall')}
          value={selectedTownHall === null ? '' : String(selectedTownHall)}
          options={townHallOptions}
          onChange={(next) => {
            const level = next ? Number(next) : null;
            onChange({ ...value, minTownHallLevel: level, maxTownHallLevel: level });
          }}
        />
      </View>
    </View>
  );
}

interface PickerOption {
  readonly value: string;
  readonly label: string;
  readonly imageUrl?: string;
}

function OptionPicker({
  accessibilityLabel,
  icon,
  title,
  value,
  options,
  searchPlaceholder,
  onChange,
}: {
  accessibilityLabel?: string;
  icon?: ReactNode;
  title?: string;
  value: string;
  options: readonly PickerOption[];
  searchPlaceholder?: string;
  onChange: (value: string) => void;
}) {
  const { t, isRtl } = useI18n();
  const theme = useCKTheme();
  const openPage = useContext(FilterNavigationContext);
  const selected = options.find((option) => option.value === value) ?? options[0];
  if (openPage)
    return (
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={accessibilityLabel ?? `${title}: ${selected?.label}`}
        onPress={() => openPage({ title: title ?? '', value, options, onChange })}
        style={[styles.pickerValue, styles.filterValueButton, isRtl && styles.rowRtl]}
      >
        <CKText muted role="rowTitle" style={styles.filterSelectedValue}>
          {selected?.label}
        </CKText>
        <ChevronRight
          size={20}
          color={theme.onSurfaceVariant}
          style={isRtl && styles.mirrorHorizontal}
        />
      </Pressable>
    );
  return (
    <View style={styles.pickerValue}>
      <SelectionPicker
        accessibilityLabel={accessibilityLabel ?? selected?.label}
        clearSearchAccessibilityLabel={t('searchClear')}
        fillWidth
        plain
        leading={icon}
        onSelect={onChange}
        options={options.map((option) => ({
          key: option.value,
          label: option.label,
          icon: option.imageUrl ? (
            <MobileWebImage imageUrl={option.imageUrl} contentFit="contain" style={styles.flag} />
          ) : undefined,
        }))}
        searchPlaceholder={searchPlaceholder}
        selectedKey={value}
        title={title ?? selected?.label ?? ''}
      />
    </View>
  );
}

function RangeFilter({
  icon,
  label,
  valueLabel,
  minimum,
  maximum,
  step,
  lower,
  upper,
  onChange,
}: {
  icon?: ReactNode;
  label: string;
  valueLabel: string;
  minimum: number;
  maximum: number;
  step: number;
  lower: number;
  upper: number;
  onChange: (lower: number, upper: number) => void;
}) {
  return (
    <View style={styles.sliderFilter}>
      <FilterLabel icon={icon} label={label} value={valueLabel} />
      <ContinuousSlider
        key={`${minimum}:${maximum}:${lower}:${upper}`}
        accessibilityLabel={label}
        minimum={minimum}
        maximum={maximum}
        step={step}
        lower={lower}
        upper={upper}
        onChange={onChange}
      />
    </View>
  );
}

function SingleFilter(props: {
  label: string;
  minimum: number;
  maximum: number;
  step: number;
  value: number;
  onChange: (value: number) => void;
}) {
  return (
    <View style={styles.sliderFilter}>
      <FilterLabel label={props.label} value={String(props.value)} />
      <ContinuousSlider
        key={`${props.minimum}:${props.maximum}:${props.value}`}
        accessibilityLabel={props.label}
        minimum={props.minimum}
        maximum={props.maximum}
        step={props.step}
        lower={props.value}
        onChange={(value) => props.onChange(value)}
      />
    </View>
  );
}

function FilterLabel({
  icon,
  label,
  value,
  row = false,
}: {
  icon?: ReactNode;
  label: string;
  value?: string;
  row?: boolean;
}) {
  const { isRtl } = useI18n();
  return (
    <View style={[styles.filterLabel, row && styles.filterRowLabel, isRtl && styles.rowRtl]}>
      {icon}
      <CKText
        numberOfLines={row ? 1 : 2}
        role="rowTitle"
        style={[styles.grow, styles.filterName, isRtl && styles.rtlText]}
      >
        {label}
      </CKText>
      {value ? (
        <CKText numberOfLines={1} role="metadata" style={styles.filterValue}>
          {value}
        </CKText>
      ) : null}
    </View>
  );
}

function ContinuousSlider({
  accessibilityLabel,
  minimum,
  maximum,
  step,
  lower,
  upper,
  onChange,
}: {
  accessibilityLabel: string;
  minimum: number;
  maximum: number;
  step: number;
  lower: number;
  upper?: number;
  onChange: (lower: number, upper: number) => void;
}) {
  const theme = useCKTheme();
  const [sliderWidth, setSliderWidth] = useState(1);
  const [displayedValues, setDisplayedValues] = useState({
    lower,
    upper: upper ?? lower,
  });
  const valuesRef = useRef(displayedValues);
  const activeThumbRef = useRef<'lower' | 'upper'>('lower');
  const onChangeRef = useRef(onChange);
  useEffect(() => {
    onChangeRef.current = onChange;
  }, [onChange]);
  const lowerValue = displayedValues.lower;
  const upperValue = displayedValues.upper;
  const ratio = useCallback(
    (value: number) => (value - minimum) / (maximum - minimum),
    [maximum, minimum],
  );
  const updateFromX = useCallback(
    (eventX: number, thumb: 'lower' | 'upper' = activeThumbRef.current) => {
      const x = Math.max(0, Math.min(sliderWidth, eventX));
      const raw = minimum + (x / sliderWidth) * (maximum - minimum);
      const next = Math.max(
        minimum,
        Math.min(maximum, minimum + Math.round((raw - minimum) / step) * step),
      );
      if (upper === undefined) {
        if (valuesRef.current.lower === next) return;
        const values = { lower: next, upper: next };
        valuesRef.current = values;
        setDisplayedValues(values);
      } else if (thumb === 'lower') {
        const nextLower = Math.min(next, valuesRef.current.upper);
        if (valuesRef.current.lower === nextLower) return;
        const values = { ...valuesRef.current, lower: nextLower };
        valuesRef.current = values;
        setDisplayedValues(values);
      } else {
        const nextUpper = Math.max(next, valuesRef.current.lower);
        if (valuesRef.current.upper === nextUpper) return;
        const values = { ...valuesRef.current, upper: nextUpper };
        valuesRef.current = values;
        setDisplayedValues(values);
      }
    },
    [maximum, minimum, sliderWidth, step, upper],
  );
  const selectThumbAtX = useCallback(
    (eventX: number) => {
      let selected = activeThumbRef.current;
      if (upper !== undefined) {
        const tappedRatio = eventX / sliderWidth;
        selected =
          Math.abs(tappedRatio - ratio(valuesRef.current.lower)) <=
          Math.abs(tappedRatio - ratio(valuesRef.current.upper))
            ? 'lower'
            : 'upper';
        activeThumbRef.current = selected;
      }
      updateFromX(eventX, selected);
    },
    [ratio, sliderWidth, updateFromX, upper],
  );
  const commitValues = useCallback(() => {
    onChangeRef.current(valuesRef.current.lower, valuesRef.current.upper);
  }, []);
  const adjustActiveThumb = useCallback(
    (delta: number) => {
      if (upper === undefined) {
        const next = Math.max(minimum, Math.min(maximum, valuesRef.current.lower + delta));
        valuesRef.current = { lower: next, upper: next };
        onChangeRef.current(next, next);
      } else if (activeThumbRef.current === 'lower') {
        const next = Math.max(
          minimum,
          Math.min(valuesRef.current.upper, valuesRef.current.lower + delta),
        );
        valuesRef.current = { ...valuesRef.current, lower: next };
        onChangeRef.current(next, valuesRef.current.upper);
      } else {
        const next = Math.max(
          valuesRef.current.lower,
          Math.min(maximum, valuesRef.current.upper + delta),
        );
        valuesRef.current = { ...valuesRef.current, upper: next };
        onChangeRef.current(valuesRef.current.lower, next);
      }
    },
    [maximum, minimum, upper],
  );
  /* eslint-disable react-hooks/refs -- RNGH registers these closures during render but invokes them only for native gesture events. */
  const sliderGesture = useMemo(() => {
    const pan = Gesture.Pan()
      .activeOffsetX([-3, 3])
      .failOffsetY([-10, 10])
      .runOnJS(true)
      .onStart((event) => selectThumbAtX(event.x))
      .onUpdate((event) => updateFromX(event.x))
      .onEnd(commitValues);
    const tap = Gesture.Tap()
      .maxDistance(10)
      .runOnJS(true)
      .onEnd((event) => {
        selectThumbAtX(event.x);
        commitValues();
      });
    return Gesture.Race(pan, tap);
  }, [commitValues, selectThumbAtX, updateFromX]);
  /* eslint-enable react-hooks/refs */
  return (
    <GestureDetector gesture={sliderGesture}>
      <View
        testID="search-filter-slider"
        accessibilityLabel={accessibilityLabel}
        accessible
        accessibilityActions={[{ name: 'increment' }, { name: 'decrement' }]}
        accessibilityRole="adjustable"
        accessibilityValue={{
          min: minimum,
          max: maximum,
          now: lowerValue,
          text: upper === undefined ? String(lowerValue) : `${lowerValue}–${upperValue}`,
        }}
        onLayout={(event) => {
          setSliderWidth(Math.max(1, event.nativeEvent.layout.width));
        }}
        onAccessibilityAction={(event) => {
          if (event.nativeEvent.actionName === 'increment') adjustActiveThumb(step);
          else if (event.nativeEvent.actionName === 'decrement') adjustActiveThumb(-step);
        }}
        style={styles.slider}
      >
        <View style={[styles.sliderTrack, { backgroundColor: theme.surfaceContainerHighest }]} />
        <View
          style={[
            styles.sliderSelected,
            {
              backgroundColor: theme.primary,
              left: upper === undefined ? 0 : `${ratio(lowerValue) * 100}%`,
              right: `${(1 - ratio(upperValue)) * 100}%`,
            },
          ]}
        />
        <View
          style={[
            styles.sliderThumb,
            { backgroundColor: theme.primary, left: `${ratio(lowerValue) * 100}%` },
          ]}
        />
        {upper !== undefined ? (
          <View
            style={[
              styles.sliderThumb,
              { backgroundColor: theme.primary, left: `${ratio(upperValue) * 100}%` },
            ]}
          />
        ) : null}
      </View>
    </GestureDetector>
  );
}

function recentSubtitle(item: RecentSearchItem, t: ReturnType<typeof useI18n>['t']): string {
  return item.type === 'clan'
    ? t('generalMembersCount', { count: item.members })
    : [item.clanName, item.leagueName].filter(Boolean).join(' • ');
}

function resultSubtitle(
  result: JsonRecord,
  mode: SearchMode,
  t: ReturnType<typeof useI18n>['t'],
): string {
  if (mode === 'clans') return t('generalMembersCount', { count: numberValue(result.members) });
  const clan = recordValue(result.clan);
  const league = recordValue(result.league);
  return [
    stringValue(clan.name) || stringValue(result.clan_name),
    stringValue(league.name) || stringValue(result.league),
  ]
    .filter(Boolean)
    .join(' • ');
}

function resultImage(result: JsonRecord, mode: SearchMode): string | null {
  if (mode === 'players') {
    return ImageAssets.townHall(numberValue(result.townHallLevel, numberValue(result.townhall, 1)));
  }
  return ImageAssets.clanBadgeForTag(stringValue(result.tag), result) || null;
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  activeFilterDot: { position: 'absolute', top: 7, right: 7, width: 6, height: 6, borderRadius: 3 },
  filterBackdrop: { flex: 1, backgroundColor: '#00000070', alignItems: 'center' },
  filterSheet: { width: '100%', maxWidth: 560, maxHeight: '90%', overflow: 'hidden' },
  filterSheetHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingTop: 10,
    paddingBottom: 4,
    gap: 8,
  },
  filterSheetTitle: { flex: 1, minWidth: 0, textAlign: 'center' },
  filterSheetContent: { paddingHorizontal: 22, paddingVertical: 12 },
  filterSheetFooter: { flexDirection: 'row', gap: 12, padding: 18 },
  filterFooterButton: {
    flex: 1,
    minHeight: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12,
  },
  filterRowLabel: { flexGrow: 1, flexShrink: 0, minWidth: 120 },
  filterPickerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 8,
    flexWrap: 'wrap',
  },
  unsetFilterIcon: {
    width: 24,
    height: 24,
    borderRadius: 7,
    alignItems: 'center',
    justifyContent: 'center',
  },
  choiceRow: {
    minHeight: 52,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 12,
  },
  filterValueButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 8,
    minHeight: 48,
  },
  filterSelectedValue: { textAlign: 'right', flexShrink: 1 },
  pickerValue: { flexGrow: 1, flexBasis: 145, minWidth: 130, maxWidth: '100%' },
  grow: { flex: 1 },
  page: { padding: 16 },
  pageSearch: { marginTop: 12 },
  pageFilters: { marginTop: 10 },
  overlayHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    height: globalSearchHeaderLayout.height,
    paddingHorizontal: 12,
    gap: 6,
  },
  overlayMode: { paddingHorizontal: 16, paddingTop: 4, paddingBottom: 0 },
  overlayFilters: { paddingTop: 4, paddingBottom: 12 },
  cancelButton: {
    width: 44,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  searchField: {
    height: globalSearchHeaderLayout.fieldHeight,
    flexDirection: 'row',
    alignItems: 'center',
    paddingLeft: 14,
    paddingRight: 6,
    gap: 8,
  },
  searchInput: {
    minWidth: 0,
    flex: 1,
    height: 48,
    paddingVertical: 0,
    fontFamily: 'ClashKing',
    fontSize: 14,
    fontWeight: '500',
  },
  fieldAction: { width: 38, height: 44, alignItems: 'center', justifyContent: 'center' },
  pageResultSpacer: { paddingTop: 14 },
  overlayResults: { paddingHorizontal: 16, paddingTop: 16 },
  pagination: {
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 44,
    marginTop: ckSpacing.sm,
  },
  overlayResultSpacer: { paddingTop: 12 },
  recentTitle: { marginBottom: 12, fontWeight: '700' },
  searchFeedback: { paddingVertical: 16, alignItems: 'center' },
  noResults: { textAlign: 'center' },
  appliedFilters: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    columnGap: 12,
    marginBottom: 8,
  },
  appliedFilterValues: { flexGrow: 1, flexShrink: 1 },
  searchTextAction: { minHeight: 44, justifyContent: 'center' },
  filterOptionsFeedback: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  entityCard: { marginBottom: 10, padding: 12 },
  overlayTile: { paddingVertical: 11, borderRadius: 14 },
  entityRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  entityImageBox: { width: 54, height: 54, alignItems: 'center', justifyContent: 'center' },
  overlayImageBox: { width: 48, height: 48 },
  entityImage: { width: 54, height: 54 },
  overlayEntityImage: { width: 48, height: 48 },
  overlayName: { fontWeight: '700' },
  tagLine: { marginTop: 2 },
  subtitle: { marginTop: 5 },
  rtlText: { textAlign: 'right' },
  rowRtl: { flexDirection: 'row-reverse' },
  mirrorHorizontal: { transform: [{ scaleX: -1 }] },
  filters: { gap: 12 },
  labelledPicker: { gap: 5 },
  filterRow: { flexDirection: 'row', gap: 8 },
  picker: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
  },
  sliderFilter: { gap: 6 },
  filterLabel: { minHeight: 22, flexDirection: 'row', alignItems: 'center', gap: 7 },
  filterName: { minWidth: 0, flexShrink: 1 },
  filterValue: { flexShrink: 0, textAlign: 'right' },
  filterIconImage: { width: 24, height: 24 },
  slider: { height: 44, justifyContent: 'center', marginHorizontal: 10 },
  sliderTrack: { position: 'absolute', left: 0, right: 0, height: 4, borderRadius: 2 },
  sliderSelected: { position: 'absolute', height: 4, borderRadius: 2 },
  sliderThumb: { position: 'absolute', width: 20, height: 20, borderRadius: 10, marginLeft: -10 },
  resetButton: {
    minHeight: 44,
    alignSelf: 'flex-end',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 10,
  },
  modalBackdrop: { flex: 1, justifyContent: 'center', padding: 24, backgroundColor: '#00000088' },
  optionSheet: { maxHeight: '70%' },
  optionList: { padding: 8 },
  optionRow: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 12,
  },
  flag: { width: 20, height: 20 },
});
