import { useEffect, useId, useMemo, useState } from 'react';
import { Platform, Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';
import {
  ArrowDown,
  ArrowUp,
  Calendar,
  ChevronRight,
  Globe2,
  Handshake,
  Percent,
  Shuffle,
  SlidersHorizontal,
  Star,
  Trophy,
  Users,
} from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  LoadingIndicator,
  MobileWebImage,
  PillSurface,
  ResponsiveGrid,
  SearchField,
  SelectionPicker,
  Surface,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { ClanWarStats, CwlRankingHistoryEntry } from '../models';
import { ClanWarStatsFilter } from '../models/clan-war-stats-filter';
import type { PlayerWarStats } from '../../player/models/player-war';
import type { ClanInfoPresentationActions, ClanInfoPresentationModel } from './clan-info-contracts';
import {
  ClanFilterBar,
  ClanTabEmpty,
  FilterPill,
  SummaryChip,
  SummaryRail,
} from './clan-tab-components';
import type { WarTypes } from './clan-activity-tabs';
import { ClanWarStatsRangeModal, type WarStatsRangeMode } from './clan-war-stats-range-modal';
import { clanWarStatsFilterForRange } from './clan-war-stats-range';

type StatsSort =
  'three' | 'two' | 'one' | 'zero' | 'destruction' | 'stars' | 'participation' | 'missed';

export function ClanStatisticsTab({
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
  const [stats, setStats] = useState<ClanWarStats | null>(model.clan.clanWarStats);
  const [loading, setLoading] = useState(stats === null);
  const [query, setQuery] = useState('');
  const [sort, setSort] = useState<StatsSort>('three');
  const [currentOnly, setCurrentOnly] = useState(false);
  const [currentTownHall, setCurrentTownHall] = useState(false);
  const [rangeMode, setRangeMode] = useState<WarStatsRangeMode>('wars');
  const [warRange, setWarRange] = useState(50);
  const [dayRange, setDayRange] = useState(90);
  const [showRange, setShowRange] = useState(false);
  const selectedTypes = [
    warTypes.cwl && 'cwl',
    warTypes.random && 'random',
    warTypes.friendly && 'friendly',
  ].filter(Boolean) as string[];
  const sortOptions: readonly { key: StatsSort; label: string }[] = [
    { key: 'three', label: t('warStarsThree') },
    { key: 'two', label: t('warStarsTwo') },
    { key: 'one', label: t('warStarsOne') },
    { key: 'zero', label: t('warStarsZero') },
    { key: 'destruction', label: t('warDestructionAverage') },
    { key: 'stars', label: t('warStarsAverage') },
    { key: 'participation', label: t('warParticipation') },
    { key: 'missed', label: t('warAttacksMissed') },
  ];
  const sortLabel = sortOptions.find((option) => option.key === sort)?.label ?? sort;
  const rangeLabel =
    rangeMode === 'wars'
      ? t('warFiltersLastXwars', { number: warRange })
      : t('warStatsLastXDays', { number: dayRange });
  const load = async (mode: WarStatsRangeMode, wars: number, days: number) => {
    setLoading(true);
    try {
      setStats(
        await actions.loadWarStats(model.clan, clanWarStatsFilterForRange(mode, wars, days)),
      );
    } catch {
      // Flutter keeps the previously loaded period visible on range errors.
    } finally {
      setLoading(false);
    }
  };
  useEffect(() => {
    if (model.clan.clanWarStats) return;
    let active = true;
    void actions
      .loadWarStats(model.clan, new ClanWarStatsFilter())
      .then((value) => {
        if (active) setStats(value);
      })
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [actions, model.clan]);
  const players = useMemo(() => {
    const currentTags = new Set(
      model.clan.memberList.map((member) => member.tag.trim().toUpperCase()),
    );
    const types = [
      warTypes.cwl && 'cwl',
      warTypes.random && 'random',
      warTypes.friendly && 'friendly',
    ].filter(Boolean) as string[];
    const result = (stats?.players ?? []).filter(
      (player) =>
        (!currentOnly || currentTags.has(player.tag.trim().toUpperCase())) &&
        (!query ||
          player.name.toLowerCase().includes(query.toLowerCase()) ||
          player.tag.toLowerCase().includes(query.toLowerCase())),
    );
    result.sort((a, b) => statValue(b, sort, types) - statValue(a, sort, types));
    return result;
  }, [currentOnly, model.clan.memberList, query, sort, stats, warTypes]);
  const overview = warOverview(players, selectedTypes, currentTownHall);
  const cards = players.map((player) => (
    <WarStatsPlayerCard
      key={player.tag}
      player={player}
      selectedTypes={selectedTypes}
      currentTownHall={currentTownHall}
    />
  ));
  return (
    <View style={styles.tab}>
      <View testID="clan-war-stats-search-row">
        <SearchField
          value={query}
          onChangeText={setQuery}
          placeholder={t('warStatsSearchPlaceholder')}
        />
      </View>
      <ClanFilterBar
        middle={
          <View testID="clan-war-stats-controls-row" style={styles.statsControlPickers}>
            <SelectionPicker
              accessibilityLabel={t('filtersDateRange')}
              externallyManaged
              fillWidth
              leading={<SlidersHorizontal size={16} color={theme.onSurfaceVariant} />}
              onOpen={() => setShowRange(true)}
              onSelect={() => undefined}
              options={[{ key: 'range', label: rangeLabel }]}
              selectedKey="range"
              title={t('filtersDateRange')}
            />
            <SelectionPicker
              accessibilityLabel={sortLabel}
              fillWidth
              leading={<Star size={16} color={theme.onSurfaceVariant} />}
              onSelect={setSort}
              options={sortOptions}
              selectedKey={sort}
              title={sortLabel}
            />
          </View>
        }
        chips={
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
            <FilterPill
              label={t('warStatsCurrentTownHall')}
              selected={currentTownHall}
              onPress={() => setCurrentTownHall(!currentTownHall)}
            />
            <FilterPill
              label={t('warStatsCurrentMembers')}
              selected={currentOnly}
              onPress={() => setCurrentOnly(!currentOnly)}
            />
          </>
        }
      />
      <View testID="clan-war-stats-summary-row">
        <SummaryRail>
          <SummaryChip
            value={`${overview.activePlayers}`}
            label={t('clanMembers')}
            icon={<Users size={18} color={theme.primary} />}
          />
          <SummaryChip value={`${overview.attacks}`} label={t('warAttacksTitle')} />
          <SummaryChip
            value={overview.averageStars.toFixed(2)}
            label={t('warStarsAverage')}
            icon={<Star size={18} color={theme.primary} />}
          />
          <SummaryChip
            value={`${overview.averageDestruction.toFixed(1)}%`}
            label={t('warDestructionAverage')}
            icon={<Percent size={18} color={theme.primary} />}
          />
          <SummaryChip value={`${overview.missed}`} label={t('warAttacksMissedShort')} />
        </SummaryRail>
      </View>
      {loading ? (
        <View style={styles.center}>
          <LoadingIndicator />
        </View>
      ) : players.length === 0 ? (
        <EmptyState title={t('generalNoFilteredResults')} body={t('generalAdjustFilters')} />
      ) : (
        <View style={styles.list}>{cards}</View>
      )}
      {showRange ? (
        <ClanWarStatsRangeModal
          initialMode={rangeMode}
          initialWarRange={warRange}
          initialDayRange={dayRange}
          onClose={() => setShowRange(false)}
          onApply={(selection) => {
            setShowRange(false);
            if (
              selection.mode === rangeMode &&
              selection.wars === warRange &&
              selection.days === dayRange
            ) {
              return;
            }
            setRangeMode(selection.mode);
            setWarRange(selection.wars);
            setDayRange(selection.days);
            void load(selection.mode, selection.wars, selection.days);
          }}
        />
      ) : null}
    </View>
  );
}

function statValue(player: PlayerWarStats, sort: StatsSort, types: string[]): number {
  const stats = player.getStatsForTypes(types);
  if (sort === 'destruction') return stats.averageDestruction;
  if (sort === 'stars') return stats.averageStars;
  if (sort === 'participation') return stats.warsCounts;
  if (sort === 'missed') return stats.missedAttacks;
  const stars = sort === 'three' ? '3' : sort === 'two' ? '2' : sort === 'one' ? '1' : '0';
  return stats.starsCount[stars] ?? 0;
}
function warOverview(
  players: readonly PlayerWarStats[],
  types: string[],
  currentTownHall: boolean,
) {
  let activePlayers = 0,
    attacks = 0,
    totalStars = 0,
    missed = 0,
    destruction = 0;
  players.forEach((player) => {
    const stats = player.getStatsForTypes(types);
    const counts = currentTownHall
      ? stats.getStarsCountAgainstTh(player.townhallLevel)
      : stats.starsCount;
    const count = Object.values(counts).reduce((sum, value) => sum + value, 0);
    if (!count) return;
    activePlayers += 1;
    attacks += count;
    missed += stats.missedAttacks;
    destruction += stats.averageDestruction * count;
    Object.entries(counts).forEach(([star, value]) => (totalStars += Number(star) * value));
  });
  return {
    activePlayers,
    attacks,
    missed,
    averageStars: attacks ? totalStars / attacks : 0,
    averageDestruction: attacks ? destruction / attacks : 0,
  };
}
function WarStatsPlayerCard({
  player,
  selectedTypes,
  currentTownHall,
}: {
  player: PlayerWarStats;
  selectedTypes: string[];
  currentTownHall: boolean;
}) {
  const stats = player.getStatsForTypes(selectedTypes);
  const stars = currentTownHall
    ? stats.getStarsCountAgainstTh(player.townhallLevel)
    : stats.starsCount;
  return (
    <Surface radius={18} style={styles.playerCard}>
      <MobileWebImage
        imageUrl={ImageAssets.townHall(player.townhallLevel)}
        style={styles.playerTownHall}
      />
      <View style={styles.grow}>
        <CKText style={styles.bold}>{player.name}</CKText>
        <CKText muted role="labelMedium">
          {player.tag}
        </CKText>
      </View>
      {['3', '2', '1', '0'].map((value) => (
        <View key={value} style={styles.starMetric}>
          <CKText role="labelSmall">{value}★</CKText>
          <CKText role="labelLarge">{stars[value] ?? 0}</CKText>
        </View>
      ))}
    </Surface>
  );
}

type RankingCategory = 'activity' | 'war' | 'points';
export function ClanRankingsTab({ model }: { model: ClanInfoPresentationModel }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const { width } = useWindowDimensions();
  const desktop = Platform.OS === 'web' && width >= 900;
  const [filter, setFilter] = useState<'all' | RankingCategory>('all');
  const [season, setSeason] = useState(new Date(2026, 6, 1));
  const offset = Math.max(
    0,
    Math.min(24, (2026 - season.getFullYear()) * 12 + 7 - (season.getMonth() + 1)),
  );
  const donated = model.clan.memberList.reduce((sum, member) => sum + member.donations, 0);
  const received = model.clan.memberList.reduce((sum, member) => sum + member.donationsReceived, 0);
  const rankings = [
    ranking(t('gameDonations'), donated, 'activity', 42 + offset * 7, 3 + offset, 'up'),
    ranking(t('gameDonationsReceived'), received, 'activity', 98 + offset * 7, 8 + offset, 'down'),
    ranking(
      t('warWinsTitle'),
      model.clan.warWins,
      'war',
      118 + offset * 7,
      7 + offset,
      ImageAssets.sword,
    ),
    ranking(
      t('clanWinStreakTitle'),
      model.clan.warWinStreak,
      'war',
      210 + offset * 7,
      12 + offset,
      'fire',
    ),
    ranking(
      t('clanPointsTitle'),
      model.clan.clanPoints,
      'points',
      164 + offset * 7,
      16 + offset,
      ImageAssets.trophies,
    ),
    ranking(
      t('clanBuilderBasePoints'),
      model.clan.clanBuilderBasePoints,
      'points',
      187 + offset * 7,
      18 + offset,
      ImageAssets.builderBaseTrophy,
    ),
    ranking(
      t('clanCapitalPoints'),
      model.clan.clanCapitalPoints,
      'points',
      73 + offset * 7,
      6 + offset,
      ImageAssets.capitalTrophy,
    ),
  ];
  const shown = rankings.filter((item) => filter === 'all' || item.category === filter);
  const cards = shown.map((item) => (
    <RankingCard
      key={item.title}
      item={item}
      countryCode={model.clan.location?.countryCode ?? null}
    />
  ));
  return (
    <View style={styles.tab}>
      <ClanFilterBar
        actions={
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('clanRankingsSelectSeason')}
            onPress={() => setSeason(new Date(season.getFullYear(), season.getMonth() - 1, 1))}
            style={styles.calendar}
          >
            <Calendar size={18} color={theme.onSurfaceVariant} />
          </Pressable>
        }
        middle={
          <SummaryChip
            value={new Intl.DateTimeFormat(toIntlLocale(locale), {
              year: 'numeric',
              month: 'long',
            }).format(season)}
            label={t('clanRankingsSeason')}
          />
        }
        chips={
          <>
            <FilterPill
              label={t('generalAll')}
              selected={filter === 'all'}
              onPress={() => setFilter('all')}
            />
            <FilterPill
              label={t('clanRankingsFilterActivity')}
              selected={filter === 'activity'}
              onPress={() => setFilter('activity')}
            />
            <FilterPill
              label={t('clanRankingsFilterWar')}
              selected={filter === 'war'}
              onPress={() => setFilter('war')}
            />
            <FilterPill
              label={t('clanRankingsFilterPoints')}
              selected={filter === 'points'}
              onPress={() => setFilter('points')}
            />
          </>
        }
      />
      {desktop ? (
        <ResponsiveGrid minItemWidth={340} maxColumns={3} gap={10}>
          {cards}
        </ResponsiveGrid>
      ) : (
        <View style={styles.list}>{cards}</View>
      )}
    </View>
  );
}
type Ranking = {
  title: string;
  value: number;
  category: RankingCategory;
  globalRank: number;
  localRank: number;
  art: string;
};
function ranking(
  title: string,
  value: number,
  category: RankingCategory,
  globalRank: number,
  localRank: number,
  art: string,
): Ranking {
  return { title, value, category, globalRank, localRank, art };
}
function RankingCard({ item, countryCode }: { item: Ranking; countryCode: string | null }) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface radius={18} style={styles.rankingCard}>
      {item.art.startsWith('http') ? (
        <MobileWebImage imageUrl={item.art} style={styles.rankingArt} />
      ) : item.art === 'up' ? (
        <ArrowUp color="#22A35A" />
      ) : item.art === 'down' ? (
        <ArrowDown color="#E35D4F" />
      ) : (
        <Trophy color={theme.primary} />
      )}
      <View style={styles.grow}>
        <CKText style={styles.bold}>{item.title}</CKText>
        <CKText muted role="labelLarge">
          {item.value.toLocaleString(toIntlLocale(locale))}
        </CKText>
      </View>
      <Rank icon={<Globe2 size={17} color={theme.onSurfaceVariant} />} value={item.globalRank} />
      <Rank
        icon={
          countryCode ? (
            <MobileWebImage imageUrl={ImageAssets.flag(countryCode)} style={styles.flag} />
          ) : (
            <Trophy size={17} color={theme.onSurfaceVariant} />
          )
        }
        value={item.localRank}
      />
    </Surface>
  );
}
function Rank({ icon, value }: { icon: React.ReactNode; value: number }) {
  return (
    <View style={styles.rank}>
      {icon}
      <CKText role="labelLarge">#{value}</CKText>
    </View>
  );
}

export function ClanCwlHistoryTab({
  model,
  actions,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
}) {
  const { t, locale } = useI18n();
  const { width } = useWindowDimensions();
  const desktop = Platform.OS === 'web' && width >= 900;
  const [entries, setEntries] = useState<readonly CwlRankingHistoryEntry[]>();
  const [error, setError] = useState(false);
  const load = async () => {
    setError(false);
    try {
      setEntries(await actions.loadCwlHistory(model.clan.tag));
    } catch {
      setError(true);
    }
  };
  useEffect(() => {
    let active = true;
    void actions
      .loadCwlHistory(model.clan.tag)
      .then((value) => {
        if (active) setEntries(value);
      })
      .catch(() => {
        if (active) setError(true);
      });
    return () => {
      active = false;
    };
  }, [actions, model.clan.tag]);
  if (!entries && !error)
    return (
      <View style={styles.center}>
        <LoadingIndicator />
      </View>
    );
  if (error)
    return (
      <ClanTabEmpty
        title={t('generalError')}
        body={t('generalTryAgain')}
        onRetry={() => void load()}
      />
    );
  if (!entries?.length)
    return <ClanTabEmpty title={t('cwlHistoryEmptyTitle')} body={t('cwlHistoryEmptyBody')} />;
  const cards = entries.map((entry, index) => (
    <CwlCard
      key={`${entry.season}:${index}`}
      entry={entry}
      movement={cwlMovement(entries, index, model.clan.warLeague?.id)}
      locale={locale}
    />
  ));
  return (
    <View style={styles.tab}>
      {desktop ? (
        <ResponsiveGrid minItemWidth={420} maxColumns={2} gap={10}>
          {cards}
        </ResponsiveGrid>
      ) : (
        <View style={styles.list}>{cards}</View>
      )}
    </View>
  );
}
export function cwlMovement(
  entries: readonly CwlRankingHistoryEntry[],
  index: number,
  current: number | undefined,
): 'up' | 'down' | null {
  const entry = entries[index]!;
  const month = entry.season.length >= 7 ? entry.season.slice(0, 7) : entry.season;
  let following = index === 0 ? current : undefined;
  if (index > 0) {
    for (let newerIndex = index - 1; newerIndex >= 0; newerIndex -= 1) {
      const candidate = entries[newerIndex]!;
      const candidateMonth =
        candidate.season.length >= 7 ? candidate.season.slice(0, 7) : candidate.season;
      if (candidateMonth !== month) {
        following = candidate.leagueId ?? undefined;
        break;
      }
    }
  }
  if (entry.leagueId == null || following == null || following === entry.leagueId) return null;
  return following > entry.leagueId ? 'up' : 'down';
}
export function CwlCard({
  entry,
  movement,
  locale,
}: {
  entry: CwlRankingHistoryEntry;
  movement: 'up' | 'down' | null;
  locale: string;
}) {
  const theme = useCKTheme();
  const shellGradientId = `cwl-card-shell-gradient-${useId().replace(/:/g, '')}`;
  const materialGradientId = `cwl-card-material-gradient-${useId().replace(/:/g, '')}`;
  const highlightId = `cwl-card-highlight-${useId().replace(/:/g, '')}`;
  const league = entry.league ?? 'Unranked';
  const date = new Date(`${entry.season.slice(0, 7)}-01T00:00:00`);
  const accent = cwlLeagueAccent(league);
  const surfaceContainer = mixColors(theme.surface, theme.surfaceContainerHighest, 0.375);
  return (
    <View
      testID={`clan-cwl-card-${entry.season}`}
      style={[
        styles.cwlCardShell,
        {
          shadowColor: '#000000',
          shadowOpacity: 0.16,
          shadowRadius: 10,
          shadowOffset: { width: 0, height: 4 },
        },
      ]}
    >
      <Svg
        testID={`clan-cwl-card-shell-${entry.season}`}
        pointerEvents="none"
        viewBox="0 0 100 100"
        preserveAspectRatio="none"
        style={StyleSheet.absoluteFill}
      >
        <Defs>
          <LinearGradient id={shellGradientId} x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0" stopColor="#FFFFFF" stopOpacity={0.3} />
            <Stop offset="0.333333" stopColor={theme.outlineVariant} stopOpacity={0.22} />
            <Stop offset="0.666667" stopColor="#FFFFFF" stopOpacity={0.07} />
            <Stop offset="1" stopColor={theme.outlineVariant} stopOpacity={0.18} />
          </LinearGradient>
        </Defs>
        <Rect width="100" height="100" fill={`url(#${shellGradientId})`} />
      </Svg>
      <View testID={`clan-cwl-card-inner-${entry.season}`} style={styles.cwlCardInner}>
        <Svg
          testID={`clan-cwl-card-gradient-${entry.season}`}
          pointerEvents="none"
          viewBox="0 0 100 100"
          preserveAspectRatio="none"
          style={StyleSheet.absoluteFill}
        >
          <Defs>
            <LinearGradient id={materialGradientId} x1="0%" y1="0%" x2="100%" y2="100%">
              <Stop
                offset="0"
                stopColor={alphaBlend(accent, 0.3, theme.surfaceContainerHighest, 0.46)}
              />
              <Stop offset="0.5" stopColor={colorWithAlpha(surfaceContainer, 0.34)} />
              <Stop offset="1" stopColor={alphaBlend(accent, 0.13, theme.surface, 0.28)} />
            </LinearGradient>
          </Defs>
          <Rect width="100" height="100" fill={`url(#${materialGradientId})`} />
        </Svg>
        <Svg
          testID={`clan-cwl-card-highlight-${entry.season}`}
          pointerEvents="none"
          viewBox="0 0 100 1.1"
          preserveAspectRatio="none"
          style={styles.cwlCardHighlight}
        >
          <Defs>
            <LinearGradient id={highlightId} x1="0%" y1="0%" x2="100%" y2="0%">
              <Stop offset="0" stopColor="#FFFFFF" stopOpacity={0} />
              <Stop offset="0.333333" stopColor="#FFFFFF" stopOpacity={0.42} />
              <Stop offset="0.666667" stopColor="#FFFFFF" stopOpacity={0.12} />
              <Stop offset="1" stopColor="#FFFFFF" stopOpacity={0} />
            </LinearGradient>
          </Defs>
          <Rect width="100" height="1.1" fill={`url(#${highlightId})`} />
        </Svg>
        <View style={styles.cwlCardContent}>
          <MobileWebImage
            imageUrl={ImageAssets.getWarLeagueImage(league)}
            style={styles.cwlImage}
          />
          <View testID="clan-cwl-main" style={styles.grow}>
            <CKText muted role="labelSmall">
              {league}
            </CKText>
            <View style={styles.cwlRank}>
              <CKText role="titleLarge" style={styles.cwlRankValue}>
                {entry.hasStanding && entry.rank > 0 ? `#${entry.rank}` : '—'}
              </CKText>
              {entry.hasStanding ? (
                <PillSurface style={styles.record}>
                  <CKText role="labelMedium" style={{ color: '#22A35A' }}>
                    {entry.roundsWon}W
                  </CKText>
                  <CKText role="labelMedium">{entry.roundsTied}T</CKText>
                  <CKText role="labelMedium" style={{ color: '#E35D4F' }}>
                    {entry.roundsLost}L
                  </CKText>
                </PillSurface>
              ) : null}
              {movement ? (
                <MobileWebImage
                  accessibilityLabel={movement === 'up' ? 'Promoted' : 'Demoted'}
                  imageUrl={
                    movement === 'up'
                      ? 'https://assets.clashk.ing/bot/icons/up_green_arrow.png'
                      : 'https://assets.clashk.ing/bot/icons/down_red_arrow.png'
                  }
                  style={styles.movementIcon}
                />
              ) : null}
            </View>
          </View>
          <View testID="clan-cwl-side" style={styles.cwlSide}>
            <View style={styles.cwlSeasonRow}>
              <CKText role="labelSmall" style={styles.cwlSeasonLabel}>
                {Number.isNaN(date.getTime())
                  ? entry.season
                  : new Intl.DateTimeFormat(toIntlLocale(locale), {
                      month: 'long',
                      year: 'numeric',
                    }).format(date)}
              </CKText>
              <ChevronRight size={16} color={colorWithAlpha(theme.onSurface, 0.5)} />
            </View>
            <View style={styles.cwlMetricRow}>
              <MobileWebImage
                imageUrl={ImageAssets.builderBaseStar}
                style={styles.cwlMetricImage}
              />
              <CKText role="labelSmall">{entry.hasStanding ? entry.stars : '—'}</CKText>
              <CKText muted role="labelSmall">
                ·
              </CKText>
              <Percent size={13} color={theme.onSurfaceVariant} />
              <CKText role="labelSmall">
                {entry.hasStanding ? entry.destruction.toFixed(2) : '—'}
              </CKText>
            </View>
          </View>
        </View>
      </View>
    </View>
  );
}

function alphaBlend(
  foreground: string,
  foregroundAlpha: number,
  background: string,
  backgroundAlpha: number,
): string {
  const foregroundRgb = parseHexColor(foreground);
  const backgroundRgb = parseHexColor(background);
  if (!foregroundRgb || !backgroundRgb) return foreground;

  const outputAlpha = foregroundAlpha + backgroundAlpha * (1 - foregroundAlpha);
  const channel = (foregroundChannel: number, backgroundChannel: number) =>
    Math.round(
      (foregroundChannel * foregroundAlpha +
        backgroundChannel * backgroundAlpha * (1 - foregroundAlpha)) /
        outputAlpha,
    );
  const red = channel(foregroundRgb[0], backgroundRgb[0]);
  const green = channel(foregroundRgb[1], backgroundRgb[1]);
  const blue = channel(foregroundRgb[2], backgroundRgb[2]);
  const alpha = Math.round(outputAlpha * 255);
  return `#${[red, green, blue, alpha]
    .map((value) => value.toString(16).padStart(2, '0'))
    .join('')}`;
}

function parseHexColor(color: string): readonly [number, number, number] | null {
  const match = /^#([\da-f]{2})([\da-f]{2})([\da-f]{2})$/i.exec(color);
  if (!match) return null;
  return [
    Number.parseInt(match[1]!, 16),
    Number.parseInt(match[2]!, 16),
    Number.parseInt(match[3]!, 16),
  ];
}

function mixColors(start: string, end: string, amount: number): string {
  const startRgb = parseHexColor(start);
  const endRgb = parseHexColor(end);
  if (!startRgb || !endRgb) return start;
  const clampedAmount = Math.max(0, Math.min(1, amount));
  return `#${startRgb
    .map((channel, index) =>
      Math.round(channel + (endRgb[index]! - channel) * clampedAmount)
        .toString(16)
        .padStart(2, '0'),
    )
    .join('')}`;
}

export function cwlLeagueAccent(league: string): string {
  const normalized = league.toLowerCase();
  if (normalized.includes('legend')) return '#8C63FF';
  if (normalized.includes('champion')) return '#FF8A2B';
  if (normalized.includes('master')) return '#1B1D23';
  if (normalized.includes('crystal')) return '#8C63FF';
  if (normalized.includes('gold')) return '#FFC83D';
  if (normalized.includes('silver')) return '#C9D1DA';
  if (normalized.includes('bronze')) return '#C9793E';
  return '#8C63FF';
}

const styles = StyleSheet.create({
  tab: { padding: 16, gap: 12 },
  center: { minHeight: 180, alignItems: 'center', justifyContent: 'center' },
  list: { gap: 8 },
  bold: { fontWeight: '800' },
  grow: { flex: 1 },
  statsControlPickers: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: 8 },
  playerCard: { minHeight: 62, flexDirection: 'row', alignItems: 'center', gap: 9, padding: 10 },
  playerTownHall: { width: 42, height: 42, resizeMode: 'contain' },
  starMetric: { alignItems: 'center', minWidth: 26 },
  calendar: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  rankingCard: { minHeight: 62, padding: 10, flexDirection: 'row', alignItems: 'center', gap: 10 },
  rankingArt: { width: 28, height: 28, resizeMode: 'contain' },
  rank: { flexDirection: 'row', alignItems: 'center', gap: 4, marginLeft: 8 },
  flag: { width: 17, height: 17 },
  cwlCardShell: {
    height: 74,
    padding: 0.8,
    borderRadius: 16,
    backgroundColor: 'transparent',
    overflow: 'hidden',
    elevation: 4,
  },
  cwlCardInner: {
    flex: 1,
    borderRadius: 15.2,
    overflow: 'hidden',
  },
  cwlCardHighlight: {
    position: 'absolute',
    top: 0,
    left: 12,
    right: 54,
    height: 1.1,
  },
  cwlCardContent: {
    flex: 1,
    paddingLeft: 9.2,
    paddingRight: 11.2,
    paddingVertical: 7.2,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  cwlImage: { width: 52, height: 52, resizeMode: 'contain' },
  cwlRank: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  cwlRankValue: { fontWeight: '900', lineHeight: 23 },
  record: { flexDirection: 'row', gap: 5, paddingHorizontal: 8, paddingVertical: 3 },
  cwlSide: { alignItems: 'flex-end', gap: 10 },
  cwlSeasonRow: { flexDirection: 'row', alignItems: 'center', gap: 2 },
  cwlSeasonLabel: { fontWeight: '800' },
  movementIcon: { width: 18, height: 18, resizeMode: 'contain' },
  cwlMetricRow: { flexDirection: 'row', alignItems: 'center', gap: 3 },
  cwlMetricImage: { width: 14, height: 14, resizeMode: 'contain' },
});
