import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Platform, Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import {
  ArrowDownToLine,
  ArrowUpFromLine,
  LogIn,
  LogOut,
  ChevronRight,
  SlidersHorizontal,
  Swords,
  Users,
} from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import {
  CKText,
  PageSkeleton,
  MobileWebImage,
  GlassControlSurface,
  ResponsiveGrid,
  SelectionPickerModal,
  Surface,
  useCKTheme,
} from '../../../ui';
import type { ClanJoinLeave, ClanWarLog, JoinLeaveEvent, WarLogDetails } from '../models';
import { relativeWarTime } from '../../war/presentation/presentation-utils';
import type { ClanInfoPresentationActions, ClanInfoPresentationModel } from './clan-info-contracts';
import {
  ClanFilterBar,
  ClanTabEmpty,
  FilterPill,
  SummaryChip,
  SummaryRail,
  relativeClanEventTime,
} from './clan-tab-components';

type WarLogFilter =
  | 'newest'
  | 'oldest'
  | 'victory'
  | 'defeat'
  | 'draw'
  | 'perfectWar'
  | '5'
  | '10'
  | '15'
  | '20'
  | '25'
  | '30'
  | '40'
  | '50';

function warLogSides(item: WarLogDetails, clanTag: string) {
  const canonical = (tag: string) => tag.trim().toUpperCase().replace(/^#?/, '#');
  const mine = canonical(item.clan.tag) === canonical(clanTag) ? item.clan : item.opponent;
  return { mine, theirs: mine === item.clan ? item.opponent : item.clan };
}

export function warLogOutcome(item: WarLogDetails, clanTag: string): 'victory' | 'defeat' | 'draw' {
  const { mine, theirs } = warLogSides(item, clanTag);
  if (mine.stars !== theirs.stars) return mine.stars > theirs.stars ? 'victory' : 'defeat';
  if (mine.destructionPercentage !== theirs.destructionPercentage)
    return mine.destructionPercentage > theirs.destructionPercentage ? 'victory' : 'defeat';
  return 'draw';
}

export function warLogOutcomeCounts(items: readonly WarLogDetails[], clanTag: string) {
  return items.reduce(
    (counts, item) => {
      counts[warLogOutcome(item, clanTag)] += 1;
      return counts;
    },
    { victory: 0, defeat: 0, draw: 0 },
  );
}

export function filterClanWarLogItems(
  log: ClanWarLog | null,
  clanTag: string,
  filter: WarLogFilter,
): readonly WarLogDetails[] {
  const items = (log?.items ?? []).filter((item) => {
    if (['cwl', 'clanwarleague', 'clanwarleagues'].includes(item.warType.toLowerCase()))
      return false;
    if (filter === 'perfectWar')
      return item.clan.destructionPercentage === 100 && item.opponent.destructionPercentage === 100;
    if (filter === 'victory' || filter === 'defeat' || filter === 'draw')
      return warLogOutcome(item, clanTag) === filter;
    if (/^\d+$/.test(filter)) return item.teamSize === Number(filter);
    return true;
  });
  return [...items].sort((left, right) =>
    filter === 'oldest'
      ? left.endTime.getTime() - right.endTime.getTime()
      : right.endTime.getTime() - left.endTime.getTime(),
  );
}

export function ClanJoinLeaveTab({
  model,
  actions,
  loadMoreSignal = 0,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
  loadMoreSignal?: number;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const { width } = useWindowDimensions();
  const desktop = Platform.OS === 'web' && width >= 900;
  const [movement, setMovement] = useState<'all' | 'joined' | 'left'>('all');
  const [data, setData] = useState<ClanJoinLeave | null>(model.clan.joinLeave);
  const [loading, setLoading] = useState(data === null);
  const [loadingMore, setLoadingMore] = useState(false);
  const consumedLoadMoreSignal = useRef(0);
  useEffect(() => {
    if (model.clan.joinLeave) return;
    let active = true;
    void actions
      .loadJoinLeave(model.clan)
      .then((value) => {
        if (active) setData(value);
      })
      .catch((error: unknown) => {
        if (active) actions.showMessage(t('generalTryAgain'));
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [actions, model.clan, t]);
  const current = data;
  const events = (current?.joinLeaveList ?? []).filter(
    (event) =>
      movement === 'all' || (movement === 'joined') === event.type.toLowerCase().includes('join'),
  );
  const loadMore = useCallback(async () => {
    if (!current || loadingMore || current.joinLeaveList.length >= current.available) return;
    setLoadingMore(true);
    try {
      setData(await actions.loadMoreJoinLeave(model.clan, current));
    } finally {
      setLoadingMore(false);
    }
  }, [actions, current, loadingMore, model.clan]);
  useEffect(() => {
    if (loadMoreSignal <= consumedLoadMoreSignal.current) return;
    consumedLoadMoreSignal.current = loadMoreSignal;
    void loadMore();
  }, [loadMore, loadMoreSignal]);
  const cards = events.map((event, index) => (
    <JoinLeaveCard key={`${event.time.toISOString()}:${event.tag}:${index}`} event={event} />
  ));
  if (loading && !current)
    return (
      <View style={styles.center}>
        <PageSkeleton kind="list" />
      </View>
    );
  return (
    <View style={styles.tab}>
      <ClanFilterBar
        middle={
          <SummaryRail>
            <SummaryChip
              value={`${current?.available ?? 0}`}
              label="Events"
              icon={<Swords size={18} color={theme.primary} />}
            />
            <SummaryChip
              value={`${current?.uniquePlayers ?? 0}`}
              label={t('joinLeaveUniquePlayers')}
              icon={<Users size={18} color={theme.primary} />}
            />
          </SummaryRail>
        }
        chips={
          <>
            <FilterPill
              label={t('generalAll')}
              selected={movement === 'all'}
              onPress={() => setMovement('all')}
            />
            <FilterPill
              label={t('joinLeaveJoin')}
              selected={movement === 'joined'}
              color="#22A35A"
              icon={<ArrowDownToLine size={15} color="#22A35A" />}
              onPress={() => setMovement('joined')}
            />
            <FilterPill
              label={t('joinLeaveLeave')}
              selected={movement === 'left'}
              color="#E35D4F"
              icon={<ArrowUpFromLine size={15} color="#E35D4F" />}
              onPress={() => setMovement('left')}
            />
          </>
        }
      />
      {events.length === 0 ? (
        <ClanTabEmpty
          title={
            movement !== 'all'
              ? t('generalNoFilteredResults')
              : (current?.available ?? 0) === 0
                ? t('clanJoinLeaveNoDataTitle')
                : t('clanJoinLeaveNoRecentMovementTitle')
          }
          body={
            movement !== 'all'
              ? ''
              : (current?.available ?? 0) === 0
                ? t('clanJoinLeaveNoDataBody')
                : t('clanJoinLeaveNoRecentMovementBody')
          }
        />
      ) : desktop ? (
        <ResponsiveGrid minItemWidth={340} maxColumns={3} gap={10}>
          {cards}
        </ResponsiveGrid>
      ) : (
        <View style={styles.list}>{cards}</View>
      )}
      {loadingMore ? <PageSkeleton kind="list" rows={1} /> : null}
    </View>
  );
}

function JoinLeaveCard({ event }: { event: JoinLeaveEvent }) {
  const { t } = useI18n();
  const joined = event.type.toLowerCase().includes('join');
  const accent = joined ? '#22A35A' : '#E35D4F';
  return (
    <Surface radius={18} style={styles.eventCard}>
      {event.th > 0 ? (
        <MobileWebImage imageUrl={ImageAssets.townHall(event.th)} style={styles.eventTownHall} />
      ) : (
        <MobileWebImage imageUrl={ImageAssets.townHall(1)} style={styles.eventTownHall} />
      )}
      <View style={styles.eventCopy}>
        <CKText numberOfLines={1} style={styles.bold}>
          {event.name}
        </CKText>
        <CKText muted role="labelMedium" numberOfLines={1}>
          {event.tag}
        </CKText>
      </View>
      <View style={styles.eventSide}>
        <View style={styles.eventType}>
          {joined ? <LogIn size={18} color={accent} /> : <LogOut size={18} color={accent} />}
          <CKText role="labelLarge" style={{ color: accent }}>
            {joined ? t('joinLeaveJoin') : t('joinLeaveLeave')}
          </CKText>
        </View>
        <CKText muted role="labelSmall">
          {relativeClanEventTime(event.time)}
        </CKText>
      </View>
    </Surface>
  );
}

export function ClanWarLogTab({
  model,
  actions,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [loadedLog, setLog] = useState<ClanWarLog | null>(model.clan.clanWarLog);
  const log = model.clan.clanWarLog ?? loadedLog;
  const [loading, setLoading] = useState(log === null);
  const [failed, setFailed] = useState(false);
  const [retry, setRetry] = useState(0);
  const [detailsFailed, setDetailsFailed] = useState(false);
  const [sort, setSort] = useState<WarLogFilter>('newest');
  const [filterOpen, setFilterOpen] = useState(false);
  useEffect(() => {
    if (model.clan.clanWarLog) {
      return;
    }
    let active = true;
    void actions
      .loadWarLog(model.clan)
      .then((value) => {
        if (active) setLog(value);
      })
      .catch(() => {
        if (active) setFailed(true);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [actions, model.clan, retry]);
  useEffect(() => {
    if (!log || log.detailsLoaded) return;
    let active = true;
    void actions
      .loadWarLogDetails(model.clan, log)
      .then((value) => {
        if (active) setLog(value);
      })
      .catch(() => {
        if (active) setDetailsFailed(true);
      });
    return () => {
      active = false;
    };
  }, [actions, model.clan, log, retry]);
  const items = useMemo(
    () => filterClanWarLogItems(log, model.clan.tag, sort),
    [log, model.clan.tag, sort],
  );
  const filterOptions: readonly { key: WarLogFilter; label: string }[] = [
    { key: 'newest', label: t('warEventsNewest') },
    { key: 'oldest', label: t('warEventsOldest') },
    { key: 'victory', label: t('warVictory') },
    { key: 'defeat', label: t('warDefeat') },
    { key: 'draw', label: t('warDraw') },
    { key: 'perfectWar', label: t('warPerfectWar') },
    ...['5', '10', '15', '20', '25', '30', '40', '50'].map((size) => ({
      key: size as WarLogFilter,
      label: `${size}v${size}`,
    })),
  ];
  return (
    <View style={styles.tab}>
      <View style={styles.warRecordRow}>
        <WarLogSummary items={items} clanTag={model.clan.tag} />
        <GlassControlSurface style={styles.warSortControl}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={`${t('generalFilters')}: ${filterOptions.find((option) => option.key === sort)?.label ?? sort}`}
            onPress={() => setFilterOpen(true)}
            style={styles.warSortButton}
            testID="clan-war-sort-trigger"
          >
            <SlidersHorizontal size={19} color={theme.onSurface} />
          </Pressable>
        </GlassControlSurface>
      </View>
      {log?.reconstructed ? (
        <Surface radius={14} style={styles.notice}>
          <CKText role="bodySmall">
            This clan has a private war log. This history was reconstructed from ClashKing data.
          </CKText>
        </Surface>
      ) : null}
      {detailsFailed ? (
        <ClanTabEmpty
          title={t('generalFailed')}
          body={t('generalTryAgain')}
          onRetry={() => {
            setDetailsFailed(false);
            setRetry((value) => value + 1);
          }}
        />
      ) : null}
      {loading && !log ? (
        <View style={styles.center}>
          <PageSkeleton kind="war" />
        </View>
      ) : failed ? (
        <ClanTabEmpty
          title={t('generalError')}
          body={t('generalTryAgain')}
          onRetry={() => {
            setLoading(true);
            setFailed(false);
            setRetry((value) => value + 1);
          }}
        />
      ) : items.length === 0 ? (
        <ClanTabEmpty title={t('generalNoDataAvailable')} />
      ) : (
        <View style={styles.list}>
          {items.map((item) => {
            const war = log?.wars.find(
              (candidate) =>
                candidate.endTime?.getTime() === item.endTime.getTime() &&
                (candidate.clan?.tag === item.opponent.tag ||
                  candidate.opponent?.tag === item.opponent.tag),
            );
            return (
              <WarLogCard
                key={`${item.endTime.toISOString()}:${item.opponent.tag}`}
                item={item}
                clanTag={model.clan.tag}
                onPress={war ? () => actions.openHistoricalWar(war) : undefined}
              />
            );
          })}
        </View>
      )}
      <SelectionPickerModal
        visible={filterOpen}
        title={t('generalFilters')}
        options={filterOptions}
        selectedKey={sort}
        onSelect={(value) => {
          setSort(value);
          setFilterOpen(false);
        }}
        onClose={() => setFilterOpen(false)}
      />
    </View>
  );
}

function WarLogSummary({ items, clanTag }: { items: readonly WarLogDetails[]; clanTag: string }) {
  const { t } = useI18n();
  const counts = warLogOutcomeCounts(items, clanTag);
  return (
    <Surface radius={18} style={styles.warRecord} testID="clan-war-record">
      {[
        { value: counts.victory, label: t('warWinsTitle'), color: '#38B56A' },
        { value: counts.defeat, label: t('warLossesTitle'), color: '#E35D4F' },
        { value: counts.draw, label: t('warDrawsTitle'), color: '#E8A524' },
      ].map((stat) => (
        <View key={stat.label} style={styles.warRecordStat}>
          <CKText role="labelLarge" style={{ color: stat.color }}>
            {stat.value}
          </CKText>
          <CKText muted role="labelSmall">
            {stat.label}
          </CKText>
        </View>
      ))}
    </Surface>
  );
}
function WarLogCard({
  item,
  clanTag,
  onPress,
}: {
  item: WarLogDetails;
  clanTag: string;
  onPress?: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const outcome = warLogOutcome(item, clanTag);
  const { mine, theirs } = warLogSides(item, clanTag);
  const resultColor =
    outcome === 'victory' ? '#22A35A' : outcome === 'defeat' ? '#E35D4F' : theme.onSurfaceVariant;
  const resultLabel =
    outcome === 'victory' ? t('warVictory') : outcome === 'defeat' ? t('warDefeat') : t('warDraw');
  return (
    <Pressable
      accessibilityRole={onPress ? 'button' : undefined}
      onPress={onPress}
      disabled={!onPress}
    >
      <Surface radius={18} style={styles.warCard}>
        <MobileWebImage imageUrl={theirs.badgeUrls.smallest} style={styles.warBadge} />
        <View style={styles.eventCopy}>
          <CKText style={styles.bold} numberOfLines={1}>
            {theirs.name}
          </CKText>
          <CKText muted role="labelSmall" numberOfLines={1}>
            {item.teamSize}v{item.teamSize} · {relativeWarTime(item.endTime, new Date(), t)}
          </CKText>
        </View>
        <View style={styles.eventSide}>
          <CKText role="labelSmall" style={{ color: resultColor, fontWeight: '700' }}>
            {resultLabel}
          </CKText>
          <View style={styles.eventType}>
            <MobileWebImage imageUrl={ImageAssets.attackStar} style={{ width: 15, height: 15 }} />
            <CKText role="titleMedium" style={styles.warScore}>
              {mine.stars} - {theirs.stars}
            </CKText>
          </View>
          <View style={styles.eventType}>
            <CKText role="labelSmall">{mine.destructionPercentage.toFixed(1)}%</CKText>
            {mine.expEarned > 0 ? (
              <CKText muted role="labelSmall">
                · {mine.expEarned} XP
              </CKText>
            ) : null}
            {onPress ? <ChevronRight size={17} color={theme.onSurfaceVariant} /> : null}
          </View>
        </View>
      </Surface>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  tab: { padding: 16, gap: 12 },
  center: { minHeight: 180, alignItems: 'center', justifyContent: 'center' },
  list: { gap: 8 },
  eventCard: {
    minHeight: 62,
    paddingHorizontal: 12,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
  },
  eventTownHall: { width: 42, height: 42, resizeMode: 'contain' },
  eventCopy: { flex: 1, marginLeft: 10 },
  eventSide: { alignItems: 'flex-end', gap: 4 },
  eventType: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  bold: { fontWeight: '800' },
  loadMore: { minHeight: 48, alignItems: 'center', justifyContent: 'center' },
  notice: { padding: 12 },
  warRecordRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  warRecord: {
    flex: 1,
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-around',
    paddingHorizontal: 8,
  },
  warRecordStat: { flexDirection: 'row', alignItems: 'baseline', gap: 3 },
  warSortControl: { width: 48, height: 48 },
  warSortButton: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  warCard: { minHeight: 84, padding: 12, flexDirection: 'row', alignItems: 'center' },
  warScore: { fontWeight: '800' },
  warBadge: { width: 48, height: 48, resizeMode: 'contain' },
});
