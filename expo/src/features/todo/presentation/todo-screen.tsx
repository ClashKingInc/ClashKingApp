import { EntityModalViewport } from '../../war/presentation/war-panel-grid';
import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { modalOrientations } from '../../../ui/modal-orientations';
import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { bundledImageUrl } from '../../../core/assets/bundled-image-source';
import {
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
  useWindowDimensions,
  type ViewInstance,
} from 'react-native';
import { ArrowLeft, Check, CheckCircle2, ChevronDown, Info, Search, X } from 'lucide-react-native';
import Svg, { Circle } from 'react-native-svg';
import { HeroHeaderScrim } from '../../../ui/hero-header-scrim';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { materialBackLabel, useI18n, type I18nValue } from '../../../i18n';
import {
  CKText,
  EmptyState,
  GlassSurface,
  HeaderIconButton,
  ProfilePageHeader,
  MobileWebImage,
  ResponsiveGrid,
  Surface,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  statColors,
  useCKTheme,
  SkeletonContent,
  useSkeletonContent,
} from '../../../ui';
import {
  Player,
  type PlayerTimer,
  type PlayerTimers,
  type TodoProgressMetric,
} from '../../player/models';
import { formatPlayerActivity } from '../../player/presentation/presentation-utils';
import type { TodoAccountFilter, TodoHeaderSummary, TodoScreenModel } from '../data';

export interface TodoScreenProps {
  readonly model: TodoScreenModel;
  readonly query: string;
  readonly filter: TodoAccountFilter;
  readonly presenceFor: (player: Player) => { attacksAvailable: number; attacksDone: number };
  readonly loadTimers: (tag: string) => Promise<PlayerTimers>;
  readonly onQueryChange: (query: string) => void;
  readonly onFilterChange: (filter: TodoAccountFilter) => void;
  readonly onBack: () => void;
  readonly openPlayer: (player: Player) => void;
  readonly now?: Date;
  readonly pendingAccounts?: readonly { tag: string; name: string; townHallLevel: number }[];
}

const FILTERS: readonly TodoAccountFilter[] = ['all', 'needs_action', 'done'];
const TODO_HEADER_ART = bundledImageUrl(
  require('../../../../assets/clashking/todo/builder-meeting.jpg'),
);

export function TodoScreen(props: TodoScreenProps) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const filterTrigger = useRef<ViewInstance>(null);
  const [filterAnchor, setFilterAnchor] = useState<{ top: number; right: number } | null>(null);
  const [filterOpen, setFilterOpen] = useState(false);
  const [infoOpen, setInfoOpen] = useState(false);
  const horizontal = layout.isExpanded ? 24 : 16;
  const now = props.now ?? new Date();
  // These records only establish the real card geometry. They are masked,
  // noninteractive and never enter the model, cache or timer service.
  const pendingPlayers = useMemo(
    () =>
      (props.pendingAccounts ?? [])
        .filter(
          (account) =>
            !props.query.trim() ||
            `${account.name} ${account.tag}`
              .toLocaleLowerCase()
              .includes(props.query.trim().toLocaleLowerCase()),
        )
        .map((account) =>
          Player.fromJson({
            name: account.name || 'Player',
            tag: account.tag,
            townHallLevel: account.townHallLevel,
          }),
        ),
    [props.pendingAccounts, props.query],
  );
  const emptyTitle = props.query.trim()
    ? t('todoNoMatchingAccounts')
    : props.filter === 'needs_action'
      ? t('todoNoAccountsNeedAction')
      : props.filter === 'done'
        ? t('todoNoCompletedAccounts')
        : t('todoNoLinkedAccounts');
  return (
    <SafeAreaView edges={['left', 'right']} style={{ flex: 1, backgroundColor: theme.background }}>
      <ScrollView
        contentContainerStyle={{ paddingBottom: insets.bottom + 24 }}
        keyboardShouldPersistTaps="handled"
      >
        {layout.isExpanded ? (
          <ProfilePageHeader
            title={t('todoTitle')}
            subtitle={t('todoAccountsNumber', {
              number: props.model.header.totalAccounts + pendingPlayers.length,
            })}
            imageUrl={ImageAssets.todoTarget}
            backgroundUrl={TODO_HEADER_ART}
            onBack={props.onBack}
            backLabel={materialBackLabel(locale)}
            safeTop={insets.top}
            actions={
              <HeaderIconButton
                glass={false}
                icon={<Info color="#FFF" />}
                label={t('todoExplanationTitle')}
                onPress={() => setInfoOpen(true)}
              />
            }
          />
        ) : (
          <View
            style={{
              minHeight: insets.top + 224,
              paddingBottom: 24,
              overflow: 'hidden',
              backgroundColor: theme.background,
            }}
          >
            <MobileWebImage
              imageUrl={TODO_HEADER_ART}
              // Artwork and scrim cover the same content-sized header. A
              // width-based image height leaves a hard edge before the fade ends.
              style={StyleSheet.absoluteFill}
              contentFit="cover"
              contentPosition="center"
            />
            <HeroHeaderScrim />
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
              <View style={{ height: Math.min(64, Math.max(24, width * 0.08)) }} />
              <TodoIdentity
                summary={{
                  ...props.model.header,
                  totalAccounts: props.model.header.totalAccounts + pendingPlayers.length,
                }}
              />
            </View>
          </View>
        )}
        <View
          style={{
            maxWidth: layout.isExpanded ? layout.contentMaxWidth : 1120,
            width: '100%',
            alignSelf: 'center',
          }}
        >
          <View style={{ paddingHorizontal: horizontal, paddingTop: 12 }}>
            <View
              style={[
                styles.controls,
                layout.isExpanded && {
                  width: '100%',
                  maxWidth: layout.contentMaxWidth,
                  alignSelf: 'center',
                },
              ]}
            >
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
              <Pressable
                ref={filterTrigger}
                accessibilityRole="button"
                onPress={() => {
                  if (layout.isExpanded)
                    filterTrigger.current?.measureInWindow((x, y, w, h) =>
                      setFilterAnchor({ top: y + h + 8, right: Math.max(16, width - x - w) }),
                    );
                  setFilterOpen(true);
                }}
              >
                <GlassSurface cornerRadius={22} interactive style={styles.filterButton}>
                  <CKText role="labelLarge" numberOfLines={1}>
                    {filterLabel(props.filter, props.model)}
                  </CKText>
                  <ChevronDown size={16} color={theme.onSurfaceVariant} />
                </GlassSurface>
              </Pressable>
            </View>
            <View style={{ paddingTop: 10 }}>
              {props.model.visiblePlayers.length || pendingPlayers.length ? (
                <ResponsiveGrid
                  minItemWidth={330}
                  maxColumns={layout.isExpanded ? layout.columns(330, 3) : 3}
                  gap={12}
                >
                  {props.model.visiblePlayers.map((player) => (
                    <TodoPlayerCard
                      key={player.tag}
                      player={player}
                      presence={props.presenceFor(player)}
                      loadTimers={props.loadTimers}
                      now={now}
                      onPress={() => props.openPlayer(player)}
                    />
                  ))}
                  {pendingPlayers.map((player) => (
                    <SkeletonContent key={`loading-${player.tag}`}>
                      <TodoPlayerCard
                        player={player}
                        presence={{ attacksAvailable: 0, attacksDone: 0 }}
                        loadTimers={props.loadTimers}
                        now={now}
                        onPress={() => {}}
                      />
                    </SkeletonContent>
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
        top={layout.isExpanded && filterAnchor ? filterAnchor.top : insets.top + 280}
        right={
          layout.isExpanded && filterAnchor
            ? filterAnchor.right
            : Math.max(16, (width - 1120) / 2) + 16
        }
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
        <CKText skeleton={false}>{t('todoExplanationIntro')}</CKText>
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
        <CKText skeleton={false}>{t('todoExplanationConclusion')}</CKText>
      </InfoDialog>
    </SafeAreaView>
  );
}

function TodoIdentity({ summary }: { summary: TodoHeaderSummary }) {
  const { t } = useI18n();
  return (
    <View style={styles.identity}>
      <MobileWebImage
        imageUrl={ImageAssets.todoTarget}
        contentFit="contain"
        style={styles.identityImage}
      />
      <View style={styles.identityCopy}>
        <CKText skeleton={false} numberOfLines={1} style={styles.heroTitle}>
          {t('todoTitle')}
        </CKText>
        <CKText numberOfLines={1} style={styles.heroSubtitle}>
          {t('todoAccountsNumber', { number: summary.totalAccounts })}
        </CKText>
      </View>
    </View>
  );
}

function TodoPlayerCard({
  player,
  presence,
  loadTimers,
  now,
  onPress,
}: {
  player: Player;
  presence: { attacksAvailable: number; attacksDone: number };
  loadTimers: (tag: string) => Promise<PlayerTimers>;
  now: Date;
  onPress: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const timers = usePlayerTimers(player.tag, loadTimers);
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
  // Counts and deadlines describe one task, not two separate War attacks rows.
  // Match only one active deadline; retain any additional events as standalone
  // timers so merging the presentation never silently drops event data.
  const metricTimers = new Map(
    metrics.map(({ metric }) => [
      metric.label,
      timers
        .filter((timer) => timer.expiresAt > now && timerMetricLabel(timer) === metric.label)
        .sort((left, right) => left.expiresAt.getTime() - right.expiresAt.getTime())[0],
    ]),
  );
  const attachedTimers = new Set(metricTimers.values());
  return (
    <Pressable accessibilityRole="button" onPress={onPress}>
      <Surface radius={28} style={styles.playerCard}>
        <View style={styles.playerHeader}>
          <View style={styles.townHallBox}>
            <MobileWebImage imageUrl={player.townHallPic} style={styles.townHall} />
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
              <TodoMetric
                key={metric.label}
                metric={metric}
                done={done}
                now={now}
                timer={metricTimers.get(metric.label)}
              />
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
        <TimerChips timers={timers.filter((timer) => !attachedTimers.has(timer))} now={now} />
      </Surface>
    </Pressable>
  );
}

function TodoMetric({
  metric,
  done,
  timer,
  now,
}: {
  metric: TodoProgressMetric;
  done: boolean;
  timer?: PlayerTimer;
  now: Date;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const asset = metricAsset(metric.label);
  return (
    <View
      accessible
      accessibilityLabel={`${metricLabel(metric, t)}: ${metric.done}/${metric.total}${timer ? `. ${t('todoEventEndsIn', { duration: formatTimerRemaining(timer.expiresAt.getTime() - now.getTime(), t) })}` : ''}`}
      style={[
        styles.metric,
        {
          backgroundColor: colorWithAlpha(theme.surface, 0.5),
          borderColor: colorWithAlpha(theme.outlineVariant, 0.18),
        },
      ]}
    >
      <MobileWebImage skeleton={false} imageUrl={asset} style={styles.metricImage} />
      <View style={styles.flex}>
        <CKText skeleton={false} muted role="labelMedium" numberOfLines={1}>
          {metricLabel(metric, t)}
        </CKText>
        <CKText
          role="labelLarge"
          style={done ? { color: statColors.win, fontWeight: '900' } : styles.heavy}
          numberOfLines={1}
        >
          {metric.done}/{metric.total}
        </CKText>
        {timer ? (
          <CKText muted role="labelMedium" numberOfLines={1}>
            {t('todoEventEndsIn', {
              duration: formatTimerRemaining(timer.expiresAt.getTime() - now.getTime(), t),
            })}
          </CKText>
        ) : null}
      </View>
    </View>
  );
}

function usePlayerTimers(playerTag: string, loadTimers: (tag: string) => Promise<PlayerTimers>) {
  const [timers, setTimers] = useState<readonly PlayerTimer[]>([]);
  const loading = useSkeletonContent();
  useEffect(() => {
    if (loading) return;
    let current = true;
    void loadTimers(playerTag)
      .then((result) => {
        if (current) setTimers(result.items);
      })
      .catch(() => undefined);
    return () => {
      current = false;
    };
  }, [loadTimers, playerTag, loading]);
  return timers;
}

function timerMetricLabel(timer: PlayerTimer): string | undefined {
  return timer.type === 'war' ? 'war_attacks' : timer.type === 'cwl' ? 'cwl_attacks' : undefined;
}

function TimerChips({ timers, now }: { timers: readonly PlayerTimer[]; now: Date }) {
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
      <MobileWebImage skeleton={false} imageUrl={image} style={styles.metricImage} />
      <View style={styles.flex}>
        <CKText skeleton={false} muted role="labelMedium" numberOfLines={1}>
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
  labelColor,
}: {
  progress: number;
  size: number;
  color: string;
  labelColor?: string;
}) {
  const theme = useCKTheme();
  const loading = useSkeletonContent();
  const value = loading ? 0 : normalizeProgress(progress);
  const label = formatProgressRingLabel(value);
  const stroke = 4;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  return (
    <View
      accessibilityRole="progressbar"
      accessibilityValue={{ min: 0, max: 100, now: Math.round(value * 100) }}
      style={{ position: 'relative', width: size, height: size }}
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
          // Use an SVG pivot instead of origin, which leaks transform-origin
          // to React DOM on web; preserve the same noon start on native.
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </Svg>
      <View pointerEvents="none" style={styles.progressRingLabel}>
        <View
          style={[
            styles.progressRingLabelPill,
            {
              minWidth: Math.round(size * 0.52),
              minHeight: Math.round(size * 0.3),
              borderRadius: Math.round(size * 0.16),
              backgroundColor: colorWithAlpha(theme.card, 0.9),
            },
          ]}
        >
          <CKText
            role="labelSmall"
            style={[
              styles.heavy,
              { color: labelColor ?? theme.onSurface, fontSize: Math.max(11, size * 0.24) },
            ]}
          >
            {label}
          </CKText>
        </View>
      </View>
    </View>
  );
}

export function formatProgressRingLabel(progress: number): string {
  const percentage = Math.round(normalizeProgress(progress) * 100);
  return `${percentage}%`;
}

function normalizeProgress(progress: number): number {
  return Number.isFinite(progress) ? Math.max(0, Math.min(1, progress)) : 0;
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
    <Modal
      supportedOrientations={modalOrientations}
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
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
    <Modal
      supportedOrientations={modalOrientations}
      visible={visible}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <EntityModalViewport>
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
      </EntityModalViewport>
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
      : filter === 'needs_action'
        ? model.filterCounts.needsAction
        : model.filterCounts.done;
  const label =
    filter === 'all' ? 'All accounts' : filter === 'needs_action' ? 'To do' : 'Completed';
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
    width: '100%',
    alignSelf: 'center',
    alignItems: 'center',
    paddingHorizontal: 16,
    marginTop: 6,
    gap: 8,
  },
  identityImage: { width: 108, height: 108 },
  identityCopy: { alignItems: 'center', gap: 4, width: '100%' },
  heroTitle: {
    color: '#FFF',
    fontSize: 26,
    lineHeight: 27,
    fontWeight: '700',
    textAlign: 'center',
  },
  heroSubtitle: {
    color: '#FFFFFF9E',
    fontSize: 15,
    lineHeight: 16,
    fontWeight: '500',
    textAlign: 'center',
  },
  progressRingLabel: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    zIndex: 1,
    elevation: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  progressRingLabelPill: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 3,
  },
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
