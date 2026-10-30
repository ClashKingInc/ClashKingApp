import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { StyleSheet, View } from 'react-native';
import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import { CKText, EmptyState, MobileWebImage, ResponsiveGrid, Surface, ckRadius } from '../../../ui';
import type { PlayerLegendHistoryEntry } from '../../player/models';
import { legendSeasonFinish } from '../../player/models/legend-season-window';

function historyBadge(season: PlayerLegendHistoryEntry): string {
  const finish = legendSeasonFinish(season.season);
  // A finish on the migration boundary still belongs to the system that just ended.
  // Old API rows may carry today's reused league ID, so dates take priority here.
  if (finish <= Date.parse('2025-10-06T05:00:00Z')) return ImageAssets.originalLegendLeague;
  if (finish <= Date.parse('2026-04-27T05:00:00Z')) return ImageAssets.legacyLegendLeague;
  if (
    season.leagueName &&
    /^(?:legend league|legend)\s+(?:[123]|i{1,3})$/iu.test(season.leagueName.trim())
  )
    return ImageAssets.getLeagueImage(season.leagueName);
  return ImageAssets.legendLeagueOne;
}

export function LegendHistoryList({
  history,
}: {
  readonly history: readonly PlayerLegendHistoryEntry[];
}) {
  const { t, locale } = useI18n();
  const layout = useAdaptiveLayout();
  return history.length ? (
    <ResponsiveGrid minItemWidth={layout.isExpanded ? 320 : 430} maxColumns={2} gap={12}>
      {history.map((season) => (
        <LegendHistoryRow key={season.season} season={season} locale={locale} />
      ))}
    </ResponsiveGrid>
  ) : (
    <EmptyState showSticker={false} title={t('generalNoDataAvailable')} style={styles.empty} />
  );
}

export function legendHistoryTopPercent(rank: number, population: number | null) {
  if (
    population === null ||
    !Number.isFinite(population) ||
    !Number.isFinite(rank) ||
    population <= 0 ||
    rank <= 0 ||
    rank > population
  )
    return null;
  return Math.ceil((rank / population) * 1000) / 10;
}

function LegendHistoryRow({
  season,
  locale,
}: {
  readonly season: PlayerLegendHistoryEntry;
  readonly locale: string;
}) {
  const { t } = useI18n();
  const format = new Intl.NumberFormat(toIntlLocale(locale));
  const topPercent = legendHistoryTopPercent(season.rank, season.population);
  return (
    <Surface radius={ckRadius.tile} style={styles.seasonCard}>
      <View style={styles.historyHeader}>
        <MobileWebImage imageUrl={historyBadge(season)} style={styles.historyBadge} />
        <CKText role="titleMedium" style={styles.grow}>
          {formatSeason(season.season, locale)}
        </CKText>
        <View style={styles.historyRank}>
          <CKText role="rowTitle">{season.rank ? `#${format.format(season.rank)}` : '—'}</CKText>
          {topPercent === null ? null : (
            <CKText muted role="metadata">
              {t('rankingsTopCount', { count: `${format.format(topPercent)}%` })}
            </CKText>
          )}
        </View>
      </View>
      <View style={styles.historyMetrics}>
        <HistoryMetric
          imageUrl={ImageAssets.trophies}
          label={t('rankedLeagueTrophies')}
          value={format.format(season.trophies)}
        />
        <HistoryMetric
          imageUrl={ImageAssets.sword}
          label={t('rankedLeagueAttacks')}
          value={format.format(season.attackWins)}
        />
        <HistoryMetric
          imageUrl={ImageAssets.shieldWithArrow}
          // The source field counts successful zero-star defenses, not all defenses taken.
          label={t('legendHistoryZeroStars')}
          value={format.format(season.defenseWins)}
        />
      </View>
    </Surface>
  );
}

function HistoryMetric({
  imageUrl,
  label,
  value,
}: {
  readonly imageUrl: string;
  readonly label: string;
  readonly value: string;
}) {
  return (
    <View style={styles.historyMetric}>
      <MobileWebImage imageUrl={imageUrl} style={styles.historyMetricImage} />
      <View style={styles.grow}>
        <CKText muted numberOfLines={1} role="metadata">
          {label}
        </CKText>
        <CKText role="rowTitle">{value}</CKText>
      </View>
    </View>
  );
}

function formatSeason(season: string, locale: string) {
  const value = season.startsWith('v2-')
    ? season.slice(3)
    : season.length === 7
      ? `${season}-01T00:00:00Z`
      : season;
  const date = new Date(value);
  if (!Number.isFinite(date.getTime())) return season;
  return new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'long',
    year: 'numeric',
    ...(season.length === 7 ? {} : { day: 'numeric' as const }),
    timeZone: 'UTC',
  }).format(date);
}

const styles = StyleSheet.create({
  grow: { flex: 1 },
  empty: { minHeight: 88, paddingVertical: 16 },
  seasonCard: { padding: 14, gap: 8 },
  historyHeader: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  historyRank: { alignItems: 'flex-end', gap: 3 },
  historyBadge: { width: 40, height: 40 },
  historyMetrics: { flexDirection: 'row', gap: 8 },
  historyMetric: { flex: 1, minWidth: 0, flexDirection: 'row', alignItems: 'center', gap: 6 },
  historyMetricImage: { width: 24, height: 24 },
});
