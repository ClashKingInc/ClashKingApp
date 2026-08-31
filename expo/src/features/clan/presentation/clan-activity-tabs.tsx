import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Platform, Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import {
  ArrowDownToLine,
  ArrowUpFromLine,
  ChevronRight,
  Handshake,
  Shuffle,
  Star,
  Swords,
  Users,
} from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import {
  CKText,
  LoadingIndicator,
  MobileWebImage,
  ResponsiveGrid,
  SearchSortBar,
  Surface,
  useCKTheme,
} from '../../../ui';
import type { ClanJoinLeave, ClanWarLog, JoinLeaveEvent, WarLogDetails } from '../models';
import { SelectionModal } from '../../war/presentation/war-components';
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

type WarTypes = { cwl: boolean; random: boolean; friendly: boolean };
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

export function filterClanWarLogItems(
  log: ClanWarLog | null,
  clanTag: string,
  warTypes: WarTypes,
  query: string,
  filter: WarLogFilter,
): readonly WarLogDetails[] {
  const selectedTypes = new Set([
    ...(warTypes.cwl ? ['cwl'] : []),
    ...(warTypes.random ? ['random'] : []),
    ...(warTypes.friendly ? ['friendly'] : []),
  ]);
  const needle = query.trim().toLowerCase();
  const canonical = (tag: string) => tag.trim().toUpperCase().replace(/^#?/, '#');
  const resultFor = (item: WarLogDetails) => {
    if (item.clan.destructionPercentage === 100 && item.opponent.destructionPercentage === 100)
      return 'perfectWar';
    const mine = canonical(item.clan.tag) === canonical(clanTag) ? item.clan : item.opponent;
    const theirs = mine === item.clan ? item.opponent : item.clan;
    if (mine.stars !== theirs.stars) return mine.stars > theirs.stars ? 'victory' : 'defeat';
    if (mine.destructionPercentage !== theirs.destructionPercentage)
      return mine.destructionPercentage > theirs.destructionPercentage ? 'victory' : 'defeat';
    return 'draw';
  };
  const items = (log?.items ?? []).filter((item) => {
    const matchingWar = log?.wars.find((war) => war.endTime?.getTime() === item.endTime.getTime());
    const type = matchingWar?.warType?.toLowerCase() ?? 'random';
    if (!selectedTypes.has(type)) return false;
    if (
      needle &&
      ![item.clan.name, item.clan.tag, item.opponent.name, item.opponent.tag].some((value) =>
        value.toLowerCase().includes(needle),
      )
    )
      return false;
    if (['victory', 'defeat', 'draw', 'perfectWar'].includes(filter))
      return resultFor(item) === filter;
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
        if (active) actions.showMessage(t('generalRefreshFailed', { error: String(error) }));
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
        <LoadingIndicator />
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
      {loadingMore ? <LoadingIndicator /> : null}
    </View>
  );
}

function JoinLeaveCard({ event }: { event: JoinLeaveEvent }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const joined = event.type.toLowerCase().includes('join');
  const accent = joined ? '#22A35A' : '#E35D4F';
  return (
    <Surface radius={18} style={styles.eventCard}>
      {event.th > 0 ? (
        <MobileWebImage imageUrl={ImageAssets.townHall(event.th)} style={styles.eventTownHall} />
      ) : (
        <Users size={34} color={theme.onSurfaceVariant} />
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
          {joined ? (
            <ArrowDownToLine size={18} color={accent} />
          ) : (
            <ArrowUpFromLine size={18} color={accent} />
          )}
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
  warTypes,
  setWarTypes,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
  warTypes: WarTypes;
  setWarTypes: (value: WarTypes) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [log, setLog] = useState<ClanWarLog | null>(model.clan.clanWarLog);
  const [loading, setLoading] = useState(log === null);
  const [query, setQuery] = useState('');
  const [sort, setSort] = useState<WarLogFilter>('newest');
  const [filterOpen, setFilterOpen] = useState(false);
  useEffect(() => {
    if (model.clan.clanWarLog) return;
    let active = true;
    void actions
      .loadWarLog(model.clan)
      .then((value) => {
        if (active) setLog(value);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [actions, model.clan]);
  const items = useMemo(
    () => filterClanWarLogItems(log, model.clan.tag, warTypes, query, sort),
    [log, model.clan.tag, query, sort, warTypes],
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
      <SearchSortBar
        value={query}
        onChangeText={setQuery}
        placeholder={t('warLogSearchPlaceholder')}
        sortLabel={filterOptions.find((option) => option.key === sort)?.label ?? sort}
        sortValue={filterOptions.find((option) => option.key === sort)?.label ?? sort}
        sortIcon={<Swords size={18} color={theme.onSurfaceVariant} />}
        onSortPress={() => setFilterOpen(true)}
      />
      <ClanFilterBar
        middle={<WarLogSummary log={log} />}
        chips={<WarTypePills warTypes={warTypes} setWarTypes={setWarTypes} />}
      />
      {log?.reconstructed ? (
        <Surface radius={14} style={styles.notice}>
          <CKText role="bodySmall">
            This clan has a private war log. This history was reconstructed from ClashKing data.
          </CKText>
        </Surface>
      ) : null}
      {loading ? (
        <View style={styles.center}>
          <LoadingIndicator />
        </View>
      ) : items.length === 0 ? (
        <ClanTabEmpty title={t('generalNoDataAvailable')} />
      ) : (
        <View style={styles.list}>
          {items.map((item) => {
            const war = log?.wars.find(
              (candidate) => candidate.endTime?.getTime() === item.endTime.getTime(),
            );
            return (
              <WarLogCard
                key={`${item.endTime.toISOString()}:${item.opponent.tag}`}
                item={item}
                onPress={war ? () => actions.openHistoricalWar(war) : undefined}
              />
            );
          })}
        </View>
      )}
      <SelectionModal
        visible={filterOpen}
        title={t('generalFilters')}
        options={filterOptions}
        selected={sort}
        onSelect={setSort}
        onClose={() => setFilterOpen(false)}
      />
    </View>
  );
}

function WarTypePills({
  warTypes,
  setWarTypes,
}: {
  warTypes: WarTypes;
  setWarTypes: (value: WarTypes) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <>
      <FilterPill
        label={t('cwlTitle')}
        imageUrl={ImageAssets.cwlSwordsNoBorder}
        selected={warTypes.cwl}
        onPress={() => setWarTypes({ ...warTypes, cwl: !warTypes.cwl })}
      />
      <FilterPill
        label={t('warFiltersRandom')}
        icon={<Shuffle size={15} color={theme.onSurfaceVariant} />}
        selected={warTypes.random}
        onPress={() => setWarTypes({ ...warTypes, random: !warTypes.random })}
      />
      <FilterPill
        label={t('warFiltersFriendly')}
        icon={<Handshake size={15} color={theme.onSurfaceVariant} />}
        selected={warTypes.friendly}
        onPress={() => setWarTypes({ ...warTypes, friendly: !warTypes.friendly })}
      />
    </>
  );
}

function WarLogSummary({ log }: { log: ClanWarLog | null }) {
  const { t } = useI18n();
  const stats = log?.warLogStats;
  return (
    <SummaryRail>
      <SummaryChip value={`${stats?.totalWins ?? 0}`} label={t('warWinsTitle')} />
      <SummaryChip value={`${stats?.totalLosses ?? 0}`} label={t('warLossesTitle')} />
      <SummaryChip value={`${stats?.totalTies ?? 0}`} label={t('warDrawsTitle')} />
    </SummaryRail>
  );
}
function WarLogCard({ item, onPress }: { item: WarLogDetails; onPress?: () => void }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const resultColor =
    item.result === 'win' ? '#22A35A' : item.result === 'lose' ? '#E35D4F' : theme.onSurfaceVariant;
  return (
    <Pressable
      accessibilityRole={onPress ? 'button' : undefined}
      onPress={onPress}
      disabled={!onPress}
    >
      <Surface radius={18} style={styles.warCard}>
        <MobileWebImage imageUrl={item.opponent.badgeUrls.smallest} style={styles.warBadge} />
        <View style={styles.eventCopy}>
          <CKText style={styles.bold}>{item.opponent.name}</CKText>
          <CKText muted role="labelMedium">
            {item.teamSize}v{item.teamSize}
          </CKText>
          <CKText muted role="labelSmall">
            {relativeWarTime(item.endTime, new Date(), t)}
          </CKText>
        </View>
        <View style={styles.eventSide}>
          <CKText style={{ color: resultColor, fontWeight: '800' }}>{item.result}</CKText>
          <View style={styles.eventType}>
            <Star size={15} color="#E8A524" />
            <CKText role="titleMedium" style={styles.warScore}>
              {item.clan.stars} - {item.opponent.stars}
            </CKText>
          </View>
          <View style={styles.eventType}>
            <CKText role="labelSmall">{item.clan.destructionPercentage.toFixed(1)}%</CKText>
            {item.clan.expEarned > 0 ? (
              <CKText muted role="labelSmall">
                · {item.clan.expEarned} XP
              </CKText>
            ) : null}
            {onPress ? <ChevronRight size={17} color={theme.onSurfaceVariant} /> : null}
          </View>
        </View>
      </Surface>
    </Pressable>
  );
}

export type { WarTypes };

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
  warCard: { minHeight: 76, padding: 10, flexDirection: 'row', alignItems: 'center' },
  warScore: { fontWeight: '800' },
  warBadge: { width: 48, height: 48, resizeMode: 'contain' },
});
