import { useEffect, useMemo, useRef, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Filter, Search, X } from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { canonicalTag } from '../../../core/domain/tags';
import { useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  GlassControlSurface,
  PageSkeleton,
  MobileWebImage,
  SearchField,
  SelectionPicker,
  Surface,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { PlayerWarStats, PlayerWarTypeStats } from '../../player/models/player-war';
import type { ClanWarStats } from '../models';
import { ClanWarStatsFilter } from '../models/clan-war-stats-filter';
import { FilterPill } from './clan-tab-components';
import type { ClanInfoPresentationActions, ClanInfoPresentationModel } from './clan-info-contracts';

type WarType = 'cwl' | 'random' | 'friendly';
type SortKey = 'hitrate' | 'stars' | 'missed';
type Attacker = { player: PlayerWarStats; value: PlayerWarTypeStats; hitrate: number };
const ALL_TYPES: readonly WarType[] = ['cwl', 'random', 'friendly'];
const WAR_RANGES = [25, 50, 100] as const;
type WarRange = (typeof WAR_RANGES)[number];

export function ClanStatisticsTab({
  model,
  actions,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const clan = model.clan;
  const requestId = useRef(0);
  const [stats, setStats] = useState<ClanWarStats | null>(clan.clanWarStats);
  const [loading, setLoading] = useState(!clan.clanWarStats?.players.length);
  const [error, setError] = useState(false);
  const [range, setRange] = useState<WarRange>(50);
  const [sameTownHall, setSameTownHall] = useState(false);
  const [currentOnly, setCurrentOnly] = useState(true);
  const [types, setTypes] = useState<readonly WarType[]>(ALL_TYPES);
  const [sort, setSort] = useState<SortKey>('hitrate');
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [searchOpen, setSearchOpen] = useState(false);
  const [query, setQuery] = useState('');

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

  const load = async (nextRange: WarRange, nextSameTownHall: boolean) => {
    const id = ++requestId.current;
    setLoading(true);
    setError(false);
    try {
      const result = await actions.loadWarStats(
        clan,
        new ClanWarStatsFilter({ limit: nextRange, sameTownHall: nextSameTownHall }),
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
  const shown = attackers
    .map((item, index) => ({ ...item, rank: index + 1 }))
    .filter(({ player }) =>
      `${player.name} ${player.tag}`.toLowerCase().includes(query.trim().toLowerCase()),
    );
  const attacks = attackers.reduce((sum, { value }) => sum + value.totalAttacks, 0);
  const triples = attackers.reduce((sum, { value }) => sum + (value.starsCount['3'] ?? 0), 0);
  const missed = attackers.reduce((sum, { value }) => sum + value.missedAttacks, 0);
  const hitrate = attacks ? (100 * triples) / attacks : 0;
  const averageStars = attacks
    ? attackers.reduce((sum, { value }) => sum + value.averageStars * value.totalAttacks, 0) /
      attacks
    : 0;
  const changeRange = (key: string) => {
    const next = Number(key) as WarRange;
    if (!WAR_RANGES.includes(next) || next === range) return;
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

  return (
    <View style={styles.tab}>
      <View style={styles.toolbar}>
        <View style={styles.grow}>
          <SelectionPicker
            accessibilityLabel={t('filtersDateRange')}
            options={WAR_RANGES.map((value) => ({
              key: String(value),
              label: t('warStatsRangeWarsCompact', { number: value }),
            }))}
            selectedKey={String(range)}
            onSelect={changeRange}
            title={t('filtersDateRange')}
          />
        </View>
        <IconButton
          label={t('warStatsSearchPlaceholder')}
          testID="clan-war-stats-search-trigger"
          expanded={searchOpen}
          onPress={() => setSearchOpen((value) => !value)}
          icon={<Search size={19} color={theme.onSurface} />}
        />
        <IconButton
          label={t('generalFilters')}
          testID="clan-war-stats-filter-trigger"
          expanded={filtersOpen}
          onPress={() => setFiltersOpen((value) => !value)}
          icon={<Filter size={19} color={theme.onSurface} />}
        />
      </View>
      {searchOpen ? (
        <View style={styles.toolbar}>
          <SearchField
            value={query}
            onChangeText={setQuery}
            placeholder={t('warStatsSearchPlaceholder')}
            style={styles.grow}
          />
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('generalClearSearch')}
            onPress={() => {
              setQuery('');
              setSearchOpen(false);
            }}
            style={styles.iconButton}
          >
            <X size={20} color={theme.onSurfaceVariant} />
          </Pressable>
        </View>
      ) : null}
      {filtersOpen ? (
        <View testID="clan-war-stats-advanced-filters" style={styles.filters}>
          <FilterPill
            label={t('warStatsCurrentMembers')}
            selected={currentOnly}
            onPress={() => setCurrentOnly((value) => !value)}
          />
          <FilterPill
            label={t('filtersSameTownHallOnly')}
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
            selected={types.includes('random')}
            onPress={() => toggleType('random')}
          />
          <FilterPill
            label={t('warFiltersFriendly')}
            selected={types.includes('friendly')}
            onPress={() => toggleType('friendly')}
          />
        </View>
      ) : null}
      {loading ? (
        <View style={styles.loading}>
          <PageSkeleton kind="stats" />
        </View>
      ) : error ? (
        <EmptyState
          title={t('generalError')}
          body={t('generalTryAgain')}
          actionLabel={t('generalTryAgain')}
          onAction={() => void load(range, sameTownHall)}
        />
      ) : !stats || !attackers.length ? (
        <EmptyState title={t('generalNoDataAvailable')} />
      ) : (
        <>
          <Surface radius={22} style={styles.overview} testID="clan-war-stats-overview">
            <Metric value={`${hitrate.toFixed(1)}%`} label={t('legendsHitrate')} />
            <Metric value={averageStars.toFixed(2)} label={t('warStarsAverage')} />
            <Metric value={String(missed)} label={t('warAttacksMissedShort')} />
          </Surface>
          <View style={styles.sortRow}>
            <View style={styles.sortPicker} testID="clan-war-stats-sort-control">
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
          </View>
          <View style={styles.list}>
            {shown.length ? (
              shown.map((item) => (
                <AttackerRow
                  key={item.player.tag}
                  item={item}
                  sort={sort}
                  linked={linkedTags.has(canonicalTag(item.player.tag))}
                />
              ))
            ) : (
              <EmptyState title={t('generalNoFilteredResults')} />
            )}
          </View>
        </>
      )}
    </View>
  );
}

function IconButton({
  label,
  testID,
  expanded,
  onPress,
  icon,
}: {
  label: string;
  testID: string;
  expanded: boolean;
  onPress: () => void;
  icon: React.ReactNode;
}) {
  return (
    <GlassControlSurface style={styles.control}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={label}
        accessibilityState={{ expanded }}
        testID={testID}
        onPress={onPress}
        style={styles.iconButton}
      >
        {icon}
      </Pressable>
    </GlassControlSurface>
  );
}

function Metric({ value, label }: { value: string; label: string }) {
  return (
    <View style={styles.metric}>
      <CKText role="titleMedium">{value}</CKText>
      <CKText muted role="labelSmall">
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
  const { player, value, hitrate, rank } = item;
  return (
    <Surface
      radius={20}
      style={[
        styles.attacker,
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
            {value.totalAttacks} {t('warAttacksTitle')} · {value.missedAttacks}{' '}
            {t('warAttacksMissedShort')}
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
  control: { width: 44, height: 44 },
  iconButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  filters: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  loading: { minHeight: 200, alignItems: 'center', justifyContent: 'center' },
  overview: { flexDirection: 'row', paddingHorizontal: 8, paddingVertical: 16 },
  metric: { flex: 1, alignItems: 'center', gap: 4 },
  sortRow: { flexDirection: 'row', justifyContent: 'flex-end' },
  sortPicker: { width: 168, maxWidth: '100%' },
  list: { gap: 10 },
  attacker: { padding: 12 },
  playerLine: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  rank: { width: 30 },
  townHall: { width: 40, height: 40, resizeMode: 'contain' },
  rate: { minWidth: 82, alignItems: 'flex-end', gap: 2 },
});
