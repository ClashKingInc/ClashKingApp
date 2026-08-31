import { useCallback, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { Keyboard, Pressable, ScrollView, StyleSheet, TextInput, View } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { SafeAreaView } from 'react-native-safe-area-context';
import {
  ChevronLeft,
  ChevronRight,
  CornerUpLeft,
  FilterX,
  Globe2,
  Medal,
  RotateCcw,
  Search,
  Shield,
  SlidersHorizontal,
  Swords,
  X,
} from 'lucide-react-native';

import { ImageAssets } from '../../core/assets/image-assets';
import { useI18n } from '../../i18n';
import {
  CKText,
  GlassPill,
  GlassSurface,
  LoadingIndicator,
  MobileWebImage,
  PressableSurface,
  SelectionPicker,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
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

export interface SearchScreenProps {
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
  readonly isSearching: boolean;
  readonly hasSearched: boolean;
  readonly onQueryChange: (value: string) => void;
  readonly onSubmit: () => void;
  readonly onModeChange: (mode: SearchMode) => void;
  readonly onFiltersExpandedChange: (expanded: boolean) => void;
  readonly onPlayerFiltersChange: (filters: PlayerSearchFilters) => void;
  readonly onClanFiltersChange: (filters: ClanSearchFilters) => void;
  readonly onOpenResult: (result: JsonRecord, mode: SearchMode) => void;
  readonly onOpenRecent: (item: RecentSearchItem) => void;
  readonly onCancel?: () => void;
}

export function SearchScreen(props: SearchScreenProps) {
  const { t, isRtl } = useI18n();
  const theme = useCKTheme();
  const inputRef = useRef<TextInput>(null);
  const activeFilters =
    props.mode === 'clans'
      ? !isClanSearchFiltersEmpty(props.clanFilters)
      : !isPlayerSearchFiltersEmpty(props.playerFilters);
  const visibleRecents = props.recents.filter((item) =>
    props.mode === 'players' ? item.type === 'player' : item.type === 'clan',
  );

  useEffect(() => {
    if (!props.autofocus) return;
    const timer = setTimeout(() => inputRef.current?.focus(), props.overlay ? 180 : 0);
    return () => clearTimeout(timer);
  }, [props.autofocus, props.overlay]);

  const searchField = (
    <GlassPill interactive style={[styles.searchField, isRtl && styles.rowRtl]}>
      <Search size={20} color={theme.onSurfaceVariant} />
      <TextInput
        ref={inputRef}
        testID="search-input"
        accessibilityLabel={
          props.mode === 'players' ? t('playerSearchPlaceholder') : t('clanSearchPlaceholder')
        }
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
          { color: theme.onSurface, textAlign: isRtl ? 'right' : 'left' },
        ]}
        value={props.query}
      />
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t('generalFilters')}
        onPress={() => {
          const expanding = !props.filtersExpanded;
          if (expanding) {
            inputRef.current?.blur();
            Keyboard.dismiss();
          }
          props.onFiltersExpandedChange(expanding);
        }}
        hitSlop={8}
        style={styles.fieldAction}
      >
        {props.filtersExpanded ? (
          <FilterX size={22} color={activeFilters ? theme.primary : theme.onSurfaceVariant} />
        ) : (
          <SlidersHorizontal
            size={22}
            color={activeFilters ? theme.primary : theme.onSurfaceVariant}
          />
        )}
      </Pressable>
      {props.isSearching ? (
        <LoadingIndicator />
      ) : props.query.length ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('searchClear')}
          onPress={() => props.onQueryChange('')}
          hitSlop={8}
          style={styles.fieldAction}
        >
          <X size={22} color={theme.onSurfaceVariant} />
        </Pressable>
      ) : null}
    </GlassPill>
  );

  const resultContent = (
    <>
      {props.query.trim().length === 0 && visibleRecents.length ? (
        <>
          <CKText
            role="titleMedium"
            style={[
              styles.recentTitle,
              { marginTop: props.overlay ? 4 : 18 },
              props.overlay ? { color: theme.onSurfaceVariant } : undefined,
              isRtl && styles.rtlText,
            ]}
          >
            {t('searchRecent')}
          </CKText>
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
        </>
      ) : null}
      {props.query.trim().length !== 0 &&
      props.hasSearched &&
      !props.isSearching &&
      props.results.length === 0 ? (
        <CKText role="bodyLarge" muted style={styles.noResults}>
          {t('searchNoResult')}
        </CKText>
      ) : (
        props.results.map((result, index) => (
          <EntityTile
            key={`${stringValue(result.tag)}:${index}`}
            name={stringValue(result.name)}
            tag={stringValue(result.tag)}
            subtitle={resultSubtitle(result, props.mode)}
            imageUrl={resultImage(result, props.mode)}
            type={props.mode === 'players' ? 'player' : 'clan'}
            overlay={props.overlay ?? false}
            onPress={() => props.onOpenResult(result, props.mode)}
          />
        ))
      )}
    </>
  );

  if (props.overlay) {
    return (
      <SafeAreaView edges={['top']} style={[styles.screen, { backgroundColor: theme.surface }]}>
        <View style={[styles.overlayHeader, isRtl && styles.rowRtl]}>
          <View style={styles.grow}>{searchField}</View>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('generalCancel')}
            onPress={props.onCancel}
            style={styles.cancelButton}
          >
            <X size={24} color={theme.onSurface} />
          </Pressable>
        </View>
        <View style={styles.overlayMode}>
          <ModeSelector mode={props.mode} compact isRtl={isRtl} onChange={props.onModeChange} />
        </View>
        <ScrollView
          automaticallyAdjustKeyboardInsets
          keyboardDismissMode="on-drag"
          keyboardShouldPersistTaps="handled"
          style={styles.grow}
          contentContainerStyle={[
            styles.overlayResults,
            props.query.trim().length !== 0 || visibleRecents.length === 0
              ? styles.overlayResultSpacer
              : undefined,
          ]}
          testID="search-overlay-scroll"
        >
          {props.filtersExpanded ? (
            <View style={styles.overlayFilters}>{filtersPanel(props)}</View>
          ) : null}
          {resultContent}
        </ScrollView>
      </SafeAreaView>
    );
  }

  return (
    <View style={[styles.screen, { backgroundColor: theme.background }]}>
      <ScrollView
        keyboardDismissMode="on-drag"
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={styles.page}
      >
        <ModeSelector mode={props.mode} isRtl={isRtl} onChange={props.onModeChange} />
        <View style={styles.pageSearch}>{searchField}</View>
        {props.filtersExpanded ? (
          <View style={styles.pageFilters}>{filtersPanel(props)}</View>
        ) : null}
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
    </View>
  );
}

function filtersPanel(props: SearchScreenProps): ReactNode {
  return props.mode === 'clans' ? (
    <ClanFiltersPanel
      value={props.clanFilters}
      locations={props.locations}
      onChange={props.onClanFiltersChange}
    />
  ) : (
    <PlayerFiltersPanel
      value={props.playerFilters}
      leagues={props.leagues}
      onChange={props.onPlayerFiltersChange}
    />
  );
}

function ModeSelector({
  mode,
  compact = false,
  isRtl,
  onChange,
}: {
  mode: SearchMode;
  compact?: boolean;
  isRtl: boolean;
  onChange: (mode: SearchMode) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <GlassSurface
      cornerRadius={ckRadius.card}
      testID="search-mode-selector"
      style={[styles.segment, compact && styles.compactSegment, isRtl && styles.rowRtl]}
    >
      {(['players', 'clans'] as const).map((value) => {
        const selected = value === mode;
        return (
          <Pressable
            key={value}
            accessibilityRole="tab"
            accessibilityState={{ selected }}
            onPress={() => onChange(value)}
            style={[
              styles.segmentButton,
              compact && styles.compactSegmentButton,
              selected && { backgroundColor: colorWithAlpha(theme.primary, 0.14) },
            ]}
          >
            <CKText role="labelLarge" style={selected ? { color: theme.primary } : undefined}>
              {value === 'players' ? t('searchTabPlayers') : t('searchTabClans')}
            </CKText>
          </Pressable>
        );
      })}
    </GlassSurface>
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
            style={styles.entityImage}
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

function ClanFiltersPanel({
  value,
  locations,
  onChange,
}: {
  value: ClanSearchFilters;
  locations: readonly SearchLocation[];
  onChange: (value: ClanSearchFilters) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const warOptions = [
    { value: '', label: t('generalNotSet') },
    { value: 'always', label: t('clanWarFrequencyAlways') },
    { value: 'never', label: t('clanWarFrequencyNever') },
    { value: 'oncePerWeek', label: t('clanWarFrequencyOncePerWeek') },
    { value: 'moreThanOncePerWeek', label: t('clanWarFrequencyMoreThanOncePerWeek') },
    { value: 'lessThanOncePerWeek', label: t('clanWarFrequencyRarely') },
  ];
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
      <View style={styles.labelledPicker} testID="clan-war-frequency-filter">
        <FilterLabel
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
      <View style={styles.labelledPicker} testID="clan-location-filter">
        <FilterLabel
          icon={<Globe2 size={18} color={theme.onSurfaceVariant} />}
          label={t('clanLocation')}
        />
        <OptionPicker
          accessibilityLabel={`${t('clanLocation')}: ${selectedLocation}`}
          title={t('clanLocation')}
          value={value.locationId === null ? '' : String(value.locationId)}
          options={locationOptions}
          onChange={(next) => onChange({ ...value, locationId: next ? Number(next) : null })}
        />
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
      {!isClanSearchFiltersEmpty(value) ? (
        <ResetButton onPress={() => onChange(emptyClanSearchFilters)} />
      ) : null}
    </View>
  );
}

function PlayerFiltersPanel({
  value,
  leagues,
  onChange,
}: {
  value: PlayerSearchFilters;
  leagues: readonly SearchLeague[];
  onChange: (value: PlayerSearchFilters) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const options = [
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
  const townHallOptions = [
    { value: '', label: t('generalNotSet') },
    ...Array.from({ length: 18 }, (_, index) => 18 - index).map((level) => ({
      value: String(level),
      label: t('gameTownHallLevelNumber', { level }),
      imageUrl: ImageAssets.townHall(level),
    })),
  ];
  return (
    <View style={styles.filters}>
      <View style={styles.labelledPicker}>
        <FilterLabel
          icon={<Medal size={18} color={theme.onSurfaceVariant} />}
          label={t('gameLeague')}
        />
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
      </View>
      <View style={styles.labelledPicker}>
        <FilterLabel
          icon={
            <MobileWebImage
              imageUrl={ImageAssets.townHall(selectedTownHall ?? 18)}
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
      {!isPlayerSearchFiltersEmpty(value) ? (
        <ResetButton onPress={() => onChange(emptyPlayerSearchFilters)} />
      ) : null}
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
  const { t } = useI18n();
  const selected = options.find((option) => option.value === value) ?? options[0];
  return (
    <SelectionPicker
      accessibilityLabel={accessibilityLabel ?? selected?.label}
      clearSearchAccessibilityLabel={t('searchClear')}
      fillWidth
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

function FilterLabel({ icon, label, value }: { icon?: ReactNode; label: string; value?: string }) {
  const { isRtl } = useI18n();
  return (
    <View style={[styles.filterLabel, isRtl && styles.rowRtl]}>
      {icon}
      <CKText
        numberOfLines={2}
        role="compactLabel"
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

function ResetButton({ onPress }: { onPress: () => void }) {
  const { t, isRtl } = useI18n();
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={[styles.resetButton, isRtl && styles.rowRtl]}
    >
      <RotateCcw size={18} color={theme.primary} />
      <CKText role="labelLarge" style={{ color: theme.primary }}>
        {t('generalReset')}
      </CKText>
    </Pressable>
  );
}

function recentSubtitle(item: RecentSearchItem, t: ReturnType<typeof useI18n>['t']): string {
  return item.type === 'clan'
    ? t('generalMembersCount', { count: item.members })
    : [item.clanName, item.leagueName].filter(Boolean).join(' • ');
}

function resultSubtitle(result: JsonRecord, mode: SearchMode): string {
  if (mode === 'clans') return `${numberValue(result.members)} members`;
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
  const badgeUrls = recordValue(result.badgeUrls);
  return (
    stringValue(badgeUrls.small) ||
    stringValue(badgeUrls.medium) ||
    stringValue(badgeUrls.large) ||
    null
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  grow: { flex: 1 },
  page: { padding: 16, paddingBottom: 96 },
  pageSearch: { marginTop: 12 },
  pageFilters: { marginTop: 10 },
  overlayHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    paddingTop: 10,
    paddingRight: 12,
    paddingBottom: 8,
    gap: 4,
  },
  overlayMode: { paddingHorizontal: 16, paddingBottom: 6 },
  overlayFilters: { paddingTop: 4, paddingBottom: 12 },
  cancelButton: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  searchField: {
    height: 48,
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
  segment: { height: 52, flexDirection: 'row', padding: 4 },
  compactSegment: { height: 40 },
  segmentButton: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: ckRadius.tile,
  },
  compactSegmentButton: { minHeight: 32 },
  pageResultSpacer: { paddingTop: 14 },
  overlayResults: { paddingHorizontal: 16, paddingTop: 10, paddingBottom: 20 },
  overlayResultSpacer: { paddingTop: 12 },
  recentTitle: { marginBottom: 8, fontWeight: '800' },
  noResults: { paddingTop: 24, textAlign: 'center' },
  entityCard: { marginBottom: 10, padding: 12 },
  overlayTile: { paddingVertical: 11, borderRadius: 14 },
  entityRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  entityImageBox: { width: 54, height: 54, alignItems: 'center', justifyContent: 'center' },
  overlayImageBox: { width: 48, height: 48 },
  entityImage: { width: '100%', height: '100%' },
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
