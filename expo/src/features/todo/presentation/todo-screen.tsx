import { useEffect, useMemo, useState, type ReactNode } from 'react';
import {
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  ArrowLeft,
  Bookmark,
  Check,
  CheckCircle2,
  ChevronDown,
  Info,
  Search,
  X,
} from 'lucide-react-native';
import Svg, {
  Circle,
  Defs,
  LinearGradient as SvgLinearGradient,
  Rect,
  Stop,
} from 'react-native-svg';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { materialBackLabel, toIntlLocale, useI18n, type I18nValue } from '../../../i18n';
import {
  CKText,
  EmptyState,
  GlassSurface,
  HeaderIconButton,
  MobileWebImage,
  ResponsiveGrid,
  Surface,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  statColors,
  useCKTheme,
  useCKThemeMode,
} from '../../../ui';
import type { Player, PlayerTimer, PlayerTimers, TodoProgressMetric } from '../../player/models';
import { formatPlayerActivity } from '../../player/presentation/presentation-utils';
import type { TodoAccountFilter, TodoHeaderSummary, TodoScreenModel } from '../data';

export interface TodoScreenProps {
  readonly model: TodoScreenModel;
  readonly query: string;
  readonly filter: TodoAccountFilter;
  readonly isBookmarked: (tag: string) => boolean;
  readonly presenceFor: (player: Player) => { attacksAvailable: number; attacksDone: number };
  readonly loadTimers: (tag: string) => Promise<PlayerTimers>;
  readonly onQueryChange: (query: string) => void;
  readonly onFilterChange: (filter: TodoAccountFilter) => void;
  readonly onBack: () => void;
  readonly openPlayer: (player: Player) => void;
  readonly now?: Date;
}

const FILTERS: readonly TodoAccountFilter[] = ['all', 'mine', 'needs_action', 'done', 'bookmarked'];

export function TodoScreen(props: TodoScreenProps) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const [filterOpen, setFilterOpen] = useState(false);
  const [infoOpen, setInfoOpen] = useState(false);
  const horizontal = 16;
  const now = props.now ?? new Date();
  const emptyTitle = props.query.trim()
    ? t('todoNoMatchingAccounts')
    : props.filter === 'mine'
      ? t('todoNoLinkedAccounts')
      : props.filter === 'needs_action'
        ? t('todoNoAccountsNeedAction')
        : props.filter === 'done'
          ? t('todoNoCompletedAccounts')
          : props.filter === 'bookmarked'
            ? t('todoNoBookmarkedAccounts')
            : t('todoNoConfiguredAccounts');
  return (
    <SafeAreaView edges={['left', 'right']} style={{ flex: 1, backgroundColor: theme.background }}>
      <ScrollView
        contentContainerStyle={{ paddingBottom: insets.bottom + 24 }}
        keyboardShouldPersistTaps="handled"
      >
        <View style={{ minHeight: insets.top + 224, overflow: 'hidden' }}>
          <MobileWebImage
            imageUrl={ImageAssets.homeBaseBackground}
            style={StyleSheet.absoluteFill}
            contentFit="cover"
            contentPosition="bottom center"
          />
          <View style={[StyleSheet.absoluteFill, { backgroundColor: '#00000080' }]} />
          <Svg pointerEvents="none" style={StyleSheet.absoluteFill}>
            <Defs>
              <SvgLinearGradient id="todo-hero-scrim" x1="0" y1="0" x2="0" y2="1">
                <Stop offset="0" stopColor="#000" stopOpacity={mode === 'dark' ? 0.36 : 0.2} />
                <Stop offset="0.5" stopColor="#000" stopOpacity={mode === 'dark' ? 0.64 : 0.4} />
                <Stop offset="1" stopColor="#000" stopOpacity={mode === 'dark' ? 0.92 : 0.65} />
              </SvgLinearGradient>
            </Defs>
            <Rect width="100%" height="100%" fill="url(#todo-hero-scrim)" />
          </Svg>
          <View style={{ paddingTop: insets.top }}>
            <View style={styles.headerActions}>
              <HeaderIconButton
                glass={false}
                icon={<ArrowLeft color="#FFF" />}
                label={materialBackLabel(locale)}
                onPress={props.onBack}
              />
              <HeaderIconButton
                glass={false}
                icon={<Info color="#FFF" />}
                label={t('todoExplanationTitle')}
                onPress={() => setInfoOpen(true)}
              />
            </View>
            <TodoIdentity summary={props.model.header} />
            <TodoHeaderStats summary={props.model.header} locale={locale} />
          </View>
        </View>
        <View style={{ maxWidth: 1120, width: '100%', alignSelf: 'center' }}>
          <View style={{ paddingHorizontal: horizontal, paddingTop: 12 }}>
            <View style={styles.controls}>
              <GlassSurface cornerRadius={22} style={styles.searchField}>
                <Search size={20} color={theme.onSurfaceVariant} />
                <TextInput
                  accessibilityLabel={t('todoSearchAccountsHint')}
                  autoCapitalize="none"
                  autoCorrect={false}
                  onChangeText={props.onQueryChange}
                  placeholder={t('todoSearchAccountsHint')}
                  placeholderTextColor={theme.onSurfaceVariant}
                  returnKeyType="search"
                  style={[styles.searchInput, { color: theme.onSurface }]}
                  value={props.query}
                />
                {props.query ? (
                  <Pressable
                    accessibilityLabel={t('generalClearSearch')}
                    accessibilityRole="button"
                    hitSlop={8}
                    onPress={() => props.onQueryChange('')}
                  >
                    <X size={18} color={theme.onSurfaceVariant} />
                  </Pressable>
                ) : null}
              </GlassSurface>
              <Pressable accessibilityRole="button" onPress={() => setFilterOpen(true)}>
                <GlassSurface cornerRadius={22} interactive style={styles.filterButton}>
                  <CKText role="labelLarge" numberOfLines={1}>
                    {filterLabel(props.filter, props.model)}
                  </CKText>
                  <ChevronDown size={16} color={theme.onSurfaceVariant} />
                </GlassSurface>
              </Pressable>
            </View>
            <View style={{ paddingTop: 10 }}>
              {props.model.visiblePlayers.length ? (
                <ResponsiveGrid minItemWidth={330} maxColumns={3} gap={12}>
                  {props.model.visiblePlayers.map((player) => (
                    <TodoPlayerCard
                      key={player.tag}
                      player={player}
                      bookmarked={props.isBookmarked(player.tag)}
                      presence={props.presenceFor(player)}
                      loadTimers={props.loadTimers}
                      now={now}
                      onPress={() => props.openPlayer(player)}
                    />
                  ))}
                </ResponsiveGrid>
              ) : (
                <EmptyState
                  title={emptyTitle}
                  body={t('todoTryAnotherSearchOrFilter')}
                  icon={<Search size={28} color={theme.onSurfaceVariant} />}
                  style={styles.empty}
                />
              )}
            </View>
          </View>
        </View>
      </ScrollView>
      <FilterPopover
        visible={filterOpen}
        selected={props.filter}
        model={props.model}
        top={insets.top + 280}
        right={Math.max(16, (width - 1120) / 2) + 16}
        onSelect={(filter) => {
          props.onFilterChange(filter);
          setFilterOpen(false);
        }}
        onClose={() => setFilterOpen(false)}
      />
      <InfoDialog
        visible={infoOpen}
        title={t('todoExplanationTitle')}
        onClose={() => setInfoOpen(false)}
      >
        <CKText>{t('todoExplanationIntro')}</CKText>
        <Explanation title={t('todoExplanationLegendsTitle')} body={t('todoExplanationLegends')} />
        <Explanation
          title={t('todoExplanationClanWarsTitle')}
          body={t('todoExplanationClanWars')}
        />
        <Explanation title={t('todoExplanationCwlTitle')} body={t('todoExplanationCwl')} />
        <Explanation
          title={t('todoExplanationPassAndGamesTitle')}
          body={t('todoExplanationPassAndGames')}
        />
        <CKText>{t('todoExplanationConclusion')}</CKText>
      </InfoDialog>
    </SafeAreaView>
  );
}

function TodoIdentity({ summary }: { summary: TodoHeaderSummary }) {
  const { t } = useI18n();
  return (
    <View style={styles.identity}>
      <MobileWebImage imageUrl={ImageAssets.iconBuilderPotion} style={styles.identityImage} />
      <View style={styles.identityCopy}>
        <CKText numberOfLines={1} style={styles.heroTitle}>
          {t('todoTitle')}
        </CKText>
        <CKText numberOfLines={1} style={styles.heroSubtitle}>
          {t('todoAccountsNumber', { number: summary.totalAccounts })}
        </CKText>
      </View>
    </View>
  );
}

function TodoHeaderStats({
  summary,
  locale,
}: {
  summary: TodoHeaderSummary;
  locale: I18nValue['locale'];
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const totalTasks = summary.openTasks + summary.completedTasks;
  const chips: { label: string; image: string; metric: string; compact?: boolean }[] = [
    {
      label: t('legendsTitle'),
      image: ImageAssets.legendBlazonNoPadding,
      metric: 'legend_attacks',
    },
    { label: t('warTitle'), image: ImageAssets.war, metric: 'war_attacks' },
    { label: t('cwlTitle'), image: ImageAssets.cwlSwordsNoBorder, metric: 'cwl_attacks' },
    {
      label: t('gameClanGames'),
      image: ImageAssets.clanGamesMedals,
      metric: 'clan_games',
      compact: true,
    },
    {
      label: t('gameSeasonPass'),
      image: ImageAssets.iconGoldPass,
      metric: 'season_pass',
      compact: true,
    },
  ];
  return (
    <View style={styles.headerStats}>
      <View style={styles.progressSummary}>
        <ProgressRing
          progress={summary.progressRatio}
          size={52}
          color={summary.openTasks === 0 ? statColors.win : theme.primary}
        />
        <View style={styles.flex}>
          <CKText style={styles.progressTitle} numberOfLines={1}>
            {summary.openTasks === 0
              ? t('generalCompleted')
              : `${summary.openTasks} ${t('generalRemaining')}`}
          </CKText>
          <CKText style={styles.progressSubtitle} numberOfLines={1}>
            {`${summary.completedTasks}/${totalTasks} ${t('generalCompleted')} · ${t('todoAccountsNumber', { number: summary.totalAccounts })}`}
          </CKText>
        </View>
      </View>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.quickStats}
      >
        {chips.flatMap((chip) => {
          const metric = summary.metrics.get(chip.metric);
          if (!metric || (chip.metric !== 'season_pass' && metric.total <= 0)) return [];
          return [
            <View
              accessible
              accessibilityLabel={chip.label}
              key={chip.metric}
              style={[styles.quickChip, { backgroundColor: colorWithAlpha(theme.surface, 0.58) }]}
            >
              <MobileWebImage imageUrl={chip.image} style={styles.quickImage} />
              <CKText style={styles.quickValue} numberOfLines={1}>
                {formatMetric(metric.done, metric.total, locale, chip.compact)}
              </CKText>
            </View>,
          ];
        })}
      </ScrollView>
    </View>
  );
}

function TodoPlayerCard({
  player,
  bookmarked,
  presence,
  loadTimers,
  now,
  onPress,
}: {
  player: Player;
  bookmarked: boolean;
  presence: { attacksAvailable: number; attacksDone: number };
  loadTimers: (tag: string) => Promise<PlayerTimers>;
  now: Date;
  onPress: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const metrics = useMemo(
    () =>
      player
        .getTodoProgressMetrics(presence, now)
        .map((metric) => ({
          metric,
          done:
            metric.label === 'clan_games' ? player.clanGamesRatio >= 1 : metric.progressRatio >= 1,
        }))
        .sort((left, right) =>
          left.done === right.done
            ? metricLabel(left.metric, t).localeCompare(metricLabel(right.metric, t))
            : left.done
              ? 1
              : -1,
        ),
    [now, player, presence, t],
  );
  const ratio = player.getTodoProgressRatio(presence);
  const statusColor = metrics.every((entry) => entry.done) ? statColors.win : theme.primary;
  return (
    <Pressable accessibilityRole="button" onPress={onPress}>
      <Surface radius={28} style={styles.playerCard}>
        <View style={styles.playerHeader}>
          <View style={styles.townHallBox}>
            <MobileWebImage imageUrl={player.townHallPic} style={styles.townHall} />
            {bookmarked ? (
              <View style={[styles.bookmarkBadge, { backgroundColor: theme.card }]}>
                <Bookmark size={14} fill={theme.onSurfaceVariant} color={theme.onSurfaceVariant} />
              </View>
            ) : null}
          </View>
          <View style={styles.flex}>
            <CKText role="titleSmall" style={styles.playerName} numberOfLines={1}>
              {player.name}
            </CKText>
            <CKText muted role="labelLarge" numberOfLines={1}>
              {player.tag}
            </CKText>
            <CKText muted role="labelLarge" numberOfLines={1} style={styles.lastActive}>
              {player.lastOnline.getTime() === 0
                ? t('playerNotTracked')
                : formatPlayerActivity(player.lastOnline, t, now)}
            </CKText>
          </View>
          <ProgressRing progress={ratio} size={54} color={statusColor} />
        </View>
        {metrics.length ? (
          <View style={styles.metricGrid}>
            {metrics.map(({ metric, done }) => (
              <TodoMetric key={metric.label} metric={metric} done={done} />
            ))}
          </View>
        ) : (
          <View style={[styles.quiet, { backgroundColor: colorWithAlpha(statusColor, 0.24) }]}>
            <CheckCircle2 size={18} color={statusColor} />
            <CKText style={{ flex: 1, color: statusColor, fontWeight: '800' }} numberOfLines={2}>
              {t('todoPointsLeftDescriptionNoPoints', { type: t('todoTitle') })}
            </CKText>
          </View>
        )}
        <TimerChips playerTag={player.tag} loadTimers={loadTimers} now={now} />
      </Surface>
    </Pressable>
  );
}

function TodoMetric({ metric, done }: { metric: TodoProgressMetric; done: boolean }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const asset = metricAsset(metric.label);
  return (
    <View
      accessible
      accessibilityLabel={`${metricLabel(metric, t)}: ${metric.done}/${metric.total}`}
      style={[
        styles.metric,
        {
          backgroundColor: colorWithAlpha(theme.surface, 0.5),
          borderColor: colorWithAlpha(theme.outlineVariant, 0.18),
        },
      ]}
    >
      <MobileWebImage imageUrl={asset} style={styles.metricImage} />
      <View style={styles.flex}>
        <CKText muted role="labelMedium" numberOfLines={1}>
          {metricLabel(metric, t)}
        </CKText>
        <CKText
          role="labelLarge"
          style={done ? { color: statColors.win, fontWeight: '900' } : styles.heavy}
          numberOfLines={1}
        >
          {metric.done}/{metric.total}
        </CKText>
      </View>
    </View>
  );
}

function TimerChips({
  playerTag,
  loadTimers,
  now,
}: {
  playerTag: string;
  loadTimers: (tag: string) => Promise<PlayerTimers>;
  now: Date;
}) {
  const [timers, setTimers] = useState<readonly PlayerTimer[]>([]);
  useEffect(() => {
    let current = true;
    void loadTimers(playerTag)
      .then((result) => {
        if (current) setTimers(result.items);
      })
      .catch(() => undefined);
    return () => {
      current = false;
    };
  }, [loadTimers, playerTag]);
  const active = timers
    .filter((timer) => timer.expiresAt > now)
    .sort((left, right) => left.expiresAt.getTime() - right.expiresAt.getTime());
  if (!active.length) return null;
  return (
    <View style={styles.timerGrid}>
      {active.map((timer, index) => (
        <TimerChip
          key={`${timer.type}-${timer.expiresAt.toISOString()}-${index}`}
          timer={timer}
          now={now}
        />
      ))}
    </View>
  );
}

function TimerChip({ timer, now }: { timer: PlayerTimer; now: Date }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const label =
    timer.type === 'war'
      ? t('todoWarAttacks')
      : timer.type === 'cwl'
        ? t('todoCwlAttacks')
        : t('gameClanCapital');
  const image =
    timer.type === 'war'
      ? ImageAssets.war
      : timer.type === 'cwl'
        ? ImageAssets.cwlSwordsNoBorder
        : ImageAssets.capitalThickSwords;
  const remaining = formatTimerRemaining(timer.expiresAt.getTime() - now.getTime(), t);
  return (
    <View
      accessible
      accessibilityLabel={`${label}: ${t('todoEventEndsIn', { duration: remaining })}`}
      style={[
        styles.metric,
        {
          backgroundColor: colorWithAlpha(theme.surface, 0.5),
          borderColor: colorWithAlpha(theme.outlineVariant, 0.18),
        },
      ]}
    >
      <MobileWebImage imageUrl={image} style={styles.metricImage} />
      <View style={styles.flex}>
        <CKText muted role="labelMedium" numberOfLines={1}>
          {label}
        </CKText>
        <CKText role="labelLarge" numberOfLines={1}>
          {t('todoEventEndsIn', { duration: remaining })}
        </CKText>
      </View>
    </View>
  );
}

function ProgressRing({
  progress,
  size,
  color,
}: {
  progress: number;
  size: number;
  color: string;
}) {
  const theme = useCKTheme();
  const value = Math.max(0, Math.min(1, progress));
  const stroke = 4;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  return (
    <View
      accessibilityRole="progressbar"
      accessibilityValue={{ min: 0, max: 100, now: Math.round(value * 100) }}
      style={{ width: size, height: size }}
    >
      <Svg width={size} height={size} style={StyleSheet.absoluteFill}>
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={theme.surfaceContainerHighest}
          strokeWidth={stroke}
        />
        <Circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth={stroke}
          strokeDasharray={`${circumference} ${circumference}`}
          strokeDashoffset={circumference * (1 - value)}
          strokeLinecap="round"
          rotation="-90"
          origin={`${size / 2}, ${size / 2}`}
        />
      </Svg>
    </View>
  );
}

function FilterPopover({
  visible,
  selected,
  model,
  top,
  right,
  onSelect,
  onClose,
}: {
  visible: boolean;
  selected: TodoAccountFilter;
  model: TodoScreenModel;
  top: number;
  right: number;
  onSelect: (filter: TodoAccountFilter) => void;
  onClose: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.modalBackdrop} onPress={onClose}>
        <Pressable
          accessibilityViewIsModal
          onPress={(event) => event.stopPropagation()}
          style={[
            styles.filterMenu,
            {
              top,
              right,
              backgroundColor: theme.surface,
              borderColor: colorWithAlpha(theme.outlineVariant, 0.32),
            },
          ]}
        >
          {FILTERS.map((filter) => (
            <Pressable
              accessibilityRole="button"
              key={filter}
              onPress={() => onSelect(filter)}
              style={[
                styles.choice,
                filter === selected && {
                  backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.74),
                },
              ]}
            >
              <CKText style={[styles.flex, filter === selected && styles.heavy]} numberOfLines={1}>
                {filterLabel(filter, model)}
              </CKText>
              {filter === selected ? <Check size={16} color={theme.onSurface} /> : null}
            </Pressable>
          ))}
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function InfoDialog({
  visible,
  title,
  onClose,
  children,
}: {
  visible: boolean;
  title: string;
  onClose: () => void;
  children: ReactNode;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.dialogBackdrop} onPress={onClose}>
        <Pressable style={styles.dialogPressable} onPress={(event) => event.stopPropagation()}>
          <Surface radius={ckRadius.card} style={styles.dialog} accessibilityViewIsModal>
            <CKText role="titleMedium" style={{ color: theme.primary, textAlign: 'center' }}>
              {title}
            </CKText>
            <ScrollView contentContainerStyle={styles.dialogBody}>{children}</ScrollView>
            <View style={styles.dialogActions}>
              <Pressable accessibilityRole="button" onPress={onClose} style={styles.okButton}>
                <CKText style={{ color: theme.primary, fontWeight: '700' }}>
                  {t('generalOk')}
                </CKText>
              </Pressable>
            </View>
          </Surface>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function Explanation({ title, body }: { title: string; body: string }) {
  return (
    <View style={styles.explanation}>
      <CKText style={styles.heavy}>{title}</CKText>
      <CKText>{body}</CKText>
    </View>
  );
}

function filterLabel(filter: TodoAccountFilter, model: TodoScreenModel) {
  const count =
    filter === 'all'
      ? model.filterCounts.all
      : filter === 'mine'
        ? model.filterCounts.mine
        : filter === 'needs_action'
          ? model.filterCounts.needsAction
          : filter === 'done'
            ? model.filterCounts.done
            : model.filterCounts.bookmarked;
  // Flutter intentionally hard-codes these five dropdown labels.
  const label =
    filter === 'all'
      ? 'All accounts'
      : filter === 'mine'
        ? 'My accounts'
        : filter === 'needs_action'
          ? 'To do'
          : filter === 'done'
            ? 'Completed'
            : 'Bookmarked';
  return `${label} (${count})`;
}

function metricLabel(metric: TodoProgressMetric, t: I18nValue['t']) {
  if (metric.label === 'legend_attacks') return t('todoLegendAttacks');
  if (metric.label === 'war_attacks') return t('todoWarAttacks');
  if (metric.label === 'cwl_attacks') return t('todoCwlAttacks');
  if (metric.label === 'clan_games') return t('gameClanGames');
  if (metric.label === 'season_pass') return t('gameSeasonPassShort');
  return metric.label;
}

function metricAsset(label: string) {
  if (label === 'legend_attacks') return ImageAssets.legendBlazonNoPadding;
  if (label === 'war_attacks') return ImageAssets.war;
  if (label === 'cwl_attacks') return ImageAssets.cwlSwordsNoBorder;
  if (label === 'clan_games') return ImageAssets.clanGamesMedals;
  return ImageAssets.iconGoldPass;
}

export function formatTimerRemaining(milliseconds: number, t: I18nValue['t']) {
  const totalMinutes = Math.max(0, Math.floor(milliseconds / 60_000));
  const days = Math.floor(totalMinutes / 1440);
  const hours = Math.floor(totalMinutes / 60);
  if (days > 0)
    return t('timeDurationShort', { unit: 'daysHours', primary: days, secondary: hours % 24 });
  if (hours > 0)
    return t('timeDurationShort', {
      unit: 'hoursMinutes',
      primary: hours,
      secondary: totalMinutes % 60,
    });
  return t('timeDurationShort', { unit: 'minutes', primary: totalMinutes, secondary: 0 });
}

function formatMetric(done: number, total: number, locale: I18nValue['locale'], compact = false) {
  if (!compact || total < 1000) return `${done}/${total}`;
  const formatter = new Intl.NumberFormat(toIntlLocale(locale), { notation: 'compact' });
  return `${formatter.format(done)}/${formatter.format(total)}`;
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  heavy: { fontWeight: '800' },
  headerActions: {
    paddingHorizontal: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  identity: {
    maxWidth: 360,
    alignSelf: 'center',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 4,
    marginTop: 6,
  },
  identityImage: { width: 64, height: 64 },
  identityCopy: { flexShrink: 1, marginLeft: 10 },
  heroTitle: { color: '#FFF', fontSize: 26, lineHeight: 27, fontWeight: '700' },
  heroSubtitle: { color: '#FFFFFF9E', fontSize: 15, lineHeight: 16, fontWeight: '500' },
  headerStats: { paddingTop: 11, paddingBottom: 8 },
  progressSummary: {
    paddingHorizontal: 28,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
  },
  progressTitle: { color: '#FFF', fontWeight: '800', lineHeight: 20 },
  progressSubtitle: { color: '#FFFFFFB8', fontWeight: '700', marginTop: 5 },
  quickStats: {
    flexGrow: 1,
    justifyContent: 'center',
    gap: 7,
    paddingHorizontal: 16,
    marginTop: 8,
  },
  quickChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
  },
  quickImage: { width: 19, height: 19 },
  quickValue: { marginLeft: 5, maxWidth: 132, fontWeight: '700', lineHeight: 14 },
  controls: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  searchField: {
    height: 44,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    gap: 8,
  },
  searchInput: {
    height: 44,
    flex: 1,
    paddingVertical: 0,
    fontFamily: 'ClashKing',
    fontSize: 14,
    fontWeight: '500',
  },
  filterButton: {
    height: 44,
    maxWidth: 140,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    gap: 4,
  },
  empty: { paddingHorizontal: 24, paddingTop: 28, paddingBottom: 18 },
  playerCard: { padding: 14 },
  playerHeader: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  townHallBox: { width: 66 },
  townHall: { width: 62, height: 62 },
  bookmarkBadge: {
    position: 'absolute',
    right: -1,
    top: 42,
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: 'center',
    justifyContent: 'center',
  },
  playerName: { fontSize: 17, fontWeight: '900' },
  lastActive: { marginTop: 3, fontWeight: '700' },
  metricGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 },
  metric: {
    minWidth: 140,
    flexBasis: '48%',
    flexGrow: 1,
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 16,
  },
  metricImage: { width: 28, height: 28 },
  quiet: {
    marginTop: 12,
    minHeight: 42,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 16,
  },
  timerGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 },
  modalBackdrop: {
    flex: 1,
    backgroundColor: '#00000033',
  },
  filterMenu: {
    position: 'absolute',
    width: 140,
    maxHeight: 320,
    borderRadius: ckRadius.chip,
    borderWidth: StyleSheet.hairlineWidth,
    padding: 6,
    ...Platform.select({ web: { boxShadow: '0 4px 12px #00000033' }, default: {} }),
  },
  choice: {
    minHeight: 40,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 10,
    borderRadius: 12,
  },
  dialogBackdrop: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    backgroundColor: '#00000099',
  },
  dialogPressable: { width: '100%', maxWidth: 420, maxHeight: '82%' },
  dialog: { width: '100%', height: '100%', paddingTop: 20 },
  dialogBody: { paddingHorizontal: 20, paddingTop: 16, gap: ckSpacing.md },
  dialogActions: { alignItems: 'flex-end', paddingHorizontal: 12, paddingVertical: 8 },
  okButton: { minWidth: 64, minHeight: 44, alignItems: 'center', justifyContent: 'center' },
  explanation: { gap: 4 },
});
