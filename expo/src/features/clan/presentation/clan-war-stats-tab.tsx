import { ResponsiveGrid } from '../../../ui/responsive-grid';
import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { ClanAdaptiveCards, FilterPill } from './clan-tab-components';
import { useEffect, useMemo, useRef, useState } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { canonicalTag } from '../../../core/domain/tags';
import { useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  SkeletonContent,
  MobileWebImage,
  SelectionPicker,
  Surface,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { PlayerWarStats, PlayerWarTypeStats } from '../../player/models/player-war';
import type { ClanWarStats } from '../models';
import { ClanWarStatsFilter } from '../models/clan-war-stats-filter';
import { warHistoryRangeFilter, type WarHistoryRange } from '../../war/models/war-history-range';
import { WarRangePicker } from '../../war/presentation/war-range-picker';
import type { ClanInfoPresentationActions, ClanInfoPresentationModel } from './clan-info-contracts';

type WarType = 'cwl' | 'random' | 'friendly';
type SortKey = 'hitrate' | 'stars' | 'missed';
type Attacker = { player: PlayerWarStats; value: PlayerWarTypeStats; hitrate: number };
const ALL_TYPES: readonly WarType[] = ['cwl', 'random', 'friendly'];
export function ClanStatisticsTab({
  model,
  actions,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
}) {
  const { t } = useI18n();
  const layout = useAdaptiveLayout();
  const clan = model.clan;
  const requestId = useRef(0);
  const [stats, setStats] = useState<ClanWarStats | null>(clan.clanWarStats);
  const [loading, setLoading] = useState(!clan.clanWarStats?.players.length);
  const [error, setError] = useState(false);
  const [range, setRange] = useState<WarHistoryRange>('wars:50');
  const [sameTownHall, setSameTownHall] = useState(false);
  const [currentOnly, setCurrentOnly] = useState(true);
  const [types, setTypes] = useState<readonly WarType[]>(ALL_TYPES);
  const [sort, setSort] = useState<SortKey>('hitrate');

  useEffect(() => {
    if (clan.clanWarStats?.players.length) return;
    const id = ++requestId.current;
    void actions
      .loadWarStats(clan, new ClanWarStatsFilter())
      .then((result) => {
        if (id === requestId.current) setStats(result);
      })
      .catch(() => {
        if (id === requestId.current) setError(true);
      })
      .finally(() => {
        if (id === requestId.current) setLoading(false);
      });
    return () => {
      requestId.current += 1;
    };
    // The initial snapshot is service-owned; later loads come from the controls.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [clan.tag]);

  const load = async (nextRange: WarHistoryRange, nextSameTownHall: boolean) => {
    const id = ++requestId.current;
    setLoading(true);
    setError(false);
    setStats(null);
    try {
      const result = await actions.loadWarStats(
        clan,
        new ClanWarStatsFilter({
          ...warHistoryRangeFilter(nextRange),
          sameTownHall: nextSameTownHall,
        }),
      );
      if (id === requestId.current) setStats(result);
    } catch {
      if (id === requestId.current) setError(true);
    } finally {
      if (id === requestId.current) setLoading(false);
    }
  };
  const memberTags = useMemo(
    () => new Set(clan.memberList.map((member) => canonicalTag(member.tag))),
    [clan.memberList],
  );
  const linkedTags = useMemo(
    () => new Set([...model.activeUserTags].map(canonicalTag)),
    [model.activeUserTags],
  );
  const selectedTypes = useMemo(() => (types.length === ALL_TYPES.length ? [] : types), [types]);
  const attackers = useMemo(
    () =>
      (stats?.players ?? [])
        .filter((player) => !currentOnly || memberTags.has(canonicalTag(player.tag)))
        .map((player) => {
          const value = player.getStatsForTypes(selectedTypes);
          const hitrate = value.totalAttacks
            ? (100 * (value.starsCount['3'] ?? 0)) / value.totalAttacks
            : 0;
          return { player, value, hitrate };
        })
        .filter(({ value }) => value.totalAttacks > 0 || value.missedAttacks > 0)
        .sort((a, b) => {
          const metric =
            sort === 'hitrate'
              ? b.hitrate - a.hitrate
              : sort === 'stars'
                ? b.value.averageStars - a.value.averageStars
                : b.value.missedAttacks - a.value.missedAttacks;
          return (
            metric ||
            b.value.totalAttacks - a.value.totalAttacks ||
            a.player.name.localeCompare(b.player.name)
          );
        }),
    [stats, currentOnly, memberTags, selectedTypes, sort],
  );
  const rankedAttackers = attackers.map((item, index) => ({ ...item, rank: index + 1 }));
  const attacks = attackers.reduce((sum, { value }) => sum + value.totalAttacks, 0);
  const triples = attackers.reduce((sum, { value }) => sum + (value.starsCount['3'] ?? 0), 0);
  const missed = attackers.reduce((sum, { value }) => sum + value.missedAttacks, 0);
  const hitrate = attacks ? (100 * triples) / attacks : 0;
  const averageStars = attacks
    ? attackers.reduce((sum, { value }) => sum + value.averageStars * value.totalAttacks, 0) /
      attacks
    : 0;
  const changeRange = (next: WarHistoryRange) => {
    if (next === range) return;
    setRange(next);
    void load(next, sameTownHall);
  };
  const toggleType = (type: WarType) =>
    setTypes((current) =>
      current.includes(type)
        ? current.length > 1
          ? current.filter((value) => value !== type)
          : current
        : [...current, type],
    );
  const sortControl = (
    <View style={styles.dropdown} testID="clan-war-stats-sort-control">
      <SelectionPicker
        accessibilityLabel={t('statsSortBy')}
        title={t('statsSortBy')}
        options={[
          { key: 'hitrate', label: t('legendsHitrate') },
          { key: 'stars', label: t('warStarsAverage') },
          { key: 'missed', label: t('warAttacksMissedShort') },
        ]}
        selectedKey={sort}
        onSelect={setSort}
      />
    </View>
  );

  return (
    <View style={styles.tab}>
      {loading || stats ? (
        <SkeletonContent loading={loading && !stats}>
          <Surface radius={22} style={styles.overview} testID="clan-war-stats-overview">
            <Metric
              value={loading && !stats ? '100.0%' : `${hitrate.toFixed(1)}%`}
              label={t('legendsHitrate')}
            />
            <Metric
              value={loading && !stats ? '3.00' : averageStars.toFixed(2)}
              label={t('warStarsAverage')}
            />
            <Metric
              value={loading && !stats ? '10' : String(missed)}
              label={t('warAttacksMissedShort')}
            />
          </Surface>
        </SkeletonContent>
      ) : null}
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.filters}
        testID="clan-war-stats-advanced-filters"
      >
        <FilterPill
          label={t('warStatsCurrentMembers')}
          imageUrl={ImageAssets.clanCastle}
          selected={currentOnly}
          onPress={() => setCurrentOnly((value) => !value)}
        />
        <FilterPill
          label={t('warStatsSameTownHall')}
          imageUrl={ImageAssets.townHall(1)}
          selected={sameTownHall}
          onPress={() => {
            setSameTownHall((value) => !value);
            void load(range, !sameTownHall);
          }}
        />
        <FilterPill
          label={t('cwlTitle')}
          imageUrl={ImageAssets.cwlSwordsNoBorder}
          selected={types.includes('cwl')}
          onPress={() => toggleType('cwl')}
        />
        <FilterPill
          label={t('warFiltersRandom')}
          imageUrl={ImageAssets.sword}
          selected={types.includes('random')}
          onPress={() => toggleType('random')}
        />
        <FilterPill
          label={t('warFiltersFriendly')}
          imageUrl={ImageAssets.warClan}
          selected={types.includes('friendly')}
          onPress={() => toggleType('friendly')}
        />
      </ScrollView>
      <View style={styles.toolbar}>
        <View style={styles.dropdown}>
          <WarRangePicker value={range} onChange={changeRange} />
        </View>
        {sortControl}
      </View>
      {loading && !stats ? (
        <SkeletonContent loading style={{ gap: 12 }}>
          <View style={styles.list}>
            {(clan.memberList.length
              ? clan.memberList.slice(0, 3)
              : [{ name: 'Player name', tag: '', townHallLevel: 16 }]
            ).map((member, index) => {
              const value = new PlayerWarTypeStats(10, 10, 10, 0, 0, { '3': 10 }, {}, {}, {});
              const player = new PlayerWarStats(
                member.name,
                member.tag,
                member.townHallLevel,
                {},
                { all: value },
                [],
              );
              return (
                <AttackerRow
                  key={index}
                  item={{ player, value, hitrate: 100, rank: index + 1 }}
                  linked={false}
                  sort={sort}
                />
              );
            })}
          </View>
        </SkeletonContent>
      ) : error && !stats ? (
        <EmptyState
          title={t('generalError')}
          body={t('generalTryAgain')}
          actionLabel={t('generalTryAgain')}
          onAction={() => void load(range, sameTownHall)}
        />
      ) : !stats || !attackers.length ? (
        <EmptyState title={t('generalNoDataAvailable')} />
      ) : (
        <View style={layout.isExpanded ? styles.expandedResults : { display: 'contents' }}>
          <View style={[styles.list, layout.isExpanded && { width: '100%' }]}>
            <WarStatsCards>
              {rankedAttackers.map((item) => (
                <AttackerRow
                  key={item.player.tag}
                  item={item}
                  sort={sort}
                  linked={linkedTags.has(canonicalTag(item.player.tag))}
                />
              ))}
            </WarStatsCards>
          </View>
        </View>
      )}
    </View>
  );
}

function WarStatsCards({ children }: { children: React.ReactNode }) {
  const layout = useAdaptiveLayout();
  if (!layout.isExpanded) return <ClanAdaptiveCards>{children}</ClanAdaptiveCards>;
  return (
    <ResponsiveGrid minItemWidth={400} maxColumns={2} gap={14}>
      {children}
    </ResponsiveGrid>
  );
}

function Metric({ value, label }: { value: string; label: string }) {
  return (
    <View style={styles.metric}>
      <CKText role="titleMedium">{value}</CKText>
      <CKText skeleton={false} muted role="labelSmall">
        {label}
      </CKText>
    </View>
  );
}

function AttackerRow({
  item,
  linked,
  sort,
}: {
  item: Attacker & { rank: number };
  linked: boolean;
  sort: 'hitrate' | 'stars' | 'missed';
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const { player, value, hitrate, rank } = item;
  return (
    <Surface
      radius={20}
      style={[
        styles.attacker,
        layout.isExpanded && styles.expandedAttacker,
        { borderColor: linked ? '#22A35AB3' : colorWithAlpha(theme.outlineVariant, 0.32) },
      ]}
      testID={`war-attacker-${canonicalTag(player.tag)}`}
    >
      <View style={styles.playerLine}>
        <CKText muted role="labelMedium" style={styles.rank}>
          #{rank}
        </CKText>
        <MobileWebImage
          imageUrl={ImageAssets.townHall(player.townhallLevel)}
          style={styles.townHall}
        />
        <View style={styles.grow}>
          <CKText role="rowTitle" numberOfLines={1}>
            {player.name}
          </CKText>
          <CKText muted role="labelLarge">
            {value.totalAttacks} {t('warAttacksTitle')}
            {sort !== 'missed' ? ` · ${value.missedAttacks} ${t('warAttacksMissedShort')}` : null}
          </CKText>
        </View>
        <View style={styles.rate}>
          <CKText role="titleSmall">
            {sort === 'stars'
              ? value.averageStars.toFixed(2)
              : sort === 'missed'
                ? value.missedAttacks
                : `${hitrate.toFixed(1)}%`}
          </CKText>
          <CKText muted role="labelSmall">
            {t(
              sort === 'stars'
                ? 'warStarsAverage'
                : sort === 'missed'
                  ? 'warAttacksMissedShort'
                  : 'legendsHitrate',
            )}
          </CKText>
        </View>
      </View>
    </Surface>
  );
}

const styles = StyleSheet.create({
  tab: { paddingHorizontal: 16, paddingTop: 16, paddingBottom: 28, gap: 14 },
  toolbar: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  grow: { flex: 1 },
  expandedResults: { gap: 18 },
  expandedAttacker: { padding: 18, minHeight: 96 },
  filters: { flexDirection: 'row', gap: 8 },
  loading: { minHeight: 200, alignItems: 'center', justifyContent: 'center' },
  overview: { flexDirection: 'row', paddingHorizontal: 8, paddingVertical: 16 },
  metric: { flex: 1, alignItems: 'center', gap: 4 },
  dropdown: { flex: 1, minWidth: 0 },
  list: { gap: 10 },
  attacker: { padding: 12 },
  playerLine: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  rank: { width: 30 },
  townHall: { width: 40, height: 40, resizeMode: 'contain' },
  rate: { minWidth: 82, alignItems: 'flex-end', gap: 2 },
});
