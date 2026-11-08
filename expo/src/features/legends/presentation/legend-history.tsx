import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { StyleSheet, View } from 'react-native';
import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import { CKText, EmptyState, MobileWebImage, ResponsiveGrid, Surface, ckRadius } from '../../../ui';
import type { PlayerLegendHistoryEntry } from '../../player/models';
import { formatLegendHistorySeason, legendHistoryBadge } from './legend-history-presentation';

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
  const badge = legendHistoryBadge(season);
  const badgeUrl = badge?.kind === 'source'
    ? badge.imageUrl
    : badge?.kind === 'tier' ? ImageAssets.getLeagueImage(badge.name) : null;
  return (
    <Surface radius={ckRadius.tile} style={styles.seasonCard}>
      <View style={styles.historyHeader}>
        {badgeUrl && badgeUrl !== ImageAssets.defaultImage ? <MobileWebImage imageUrl={badgeUrl} style={styles.historyBadge} /> : null}
        <CKText role="titleMedium" numberOfLines={2} style={styles.grow}>
          {formatLegendHistorySeason(season, toIntlLocale(locale))}
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
