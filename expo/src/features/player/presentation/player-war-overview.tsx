import { useMemo } from 'react';
import { ScrollView, StyleSheet, View } from 'react-native';
import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  MobileWebImage,
  EmptyState,
  Surface,
  ckRadius,
  statColors,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { DashboardMetric, DashboardMetricGrid } from '../../../ui/dashboard-card';
import { PlayerWarFlipCard } from './player-war-flip-card';
import type { PlayerCwlHistory } from '../models/player-history';
import type { PlayerWarStats, PlayerWarStatsData, PlayerWarTypeStats } from '../models/player-war';

export type PlayerWarMode = 'random' | 'cwl' | 'friendly';

export function WarPerformanceSummary({
  data,
  sameHall,
}: {
  data: PlayerWarStats;
  sameHall: boolean;
}) {
  const { t, locale } = useI18n();
  const intl = toIntlLocale(locale);
  const theme = useCKTheme();
  return (
    <View style={styles.sections}>
      {(['random', 'cwl', 'friendly'] as const).map((type) => {
        const allStats = data.getStatsForTypes([type]);
        // A TH filter must not invent a Friendly card for players with no friendly history.
        if (
          type === 'friendly' &&
          !allStats.warsCounts &&
          !allStats.totalAttacks &&
          !allStats.totalDefenses
        )
          return null;
        const stats = data.getStatsForTypes([type], { equalThSelected: sameHall });
        const triples = stats.starsCount['3'] ?? 0;
        const stars = Object.entries(stats.starsCount).reduce(
          (sum, [value, count]) => sum + Number(value) * count,
          0,
        );
        const title = t(
          type === 'cwl'
            ? 'cwlTitle'
            : type === 'friendly'
              ? 'warFiltersFriendly'
              : 'playerWarRegularWars',
        );
        return (
          <PlayerWarFlipCard
            key={type}
            title={title}
            warCountLabel={t('warStatsRangeWarsCompact', { number: stats.warsCounts })}
            accent={theme.primary}
            front={
              <>
                <View style={styles.summaryHeading}>
                  <View style={[styles.row, styles.grow]}>
                    <MobileWebImage
                      imageUrl={
                        type === 'cwl'
                          ? ImageAssets.cwlSwordsNoBorder
                          : type === 'friendly'
                            ? ImageAssets.warClan
                            : ImageAssets.sword
                      }
                      style={styles.summaryIcon}
                    />
                    <CKText style={[styles.grow, styles.cardTitle]}>{title}</CKText>
                  </View>
                  {stats.totalAttacks ? (
                    <View style={styles.rateBlock}>
                      <CKText
                        style={styles.rate}
                      >{`${((100 * triples) / stats.totalAttacks).toLocaleString(intl, { maximumFractionDigits: 0 })}%`}</CKText>
                      <CKText muted role="metadata">
                        {t('legendsHitrate')}
                      </CKText>
                    </View>
                  ) : null}
                </View>
                {stats.totalAttacks || stats.missedAttacks ? (
                  <DashboardMetricGrid>
                    <SummaryMetric
                      label={t('warStarsTitle')}
                      value={stars.toLocaleString(intl)}
                      images={[ImageAssets.attackStar]}
                    />
                    <SummaryMetric
                      label={t('warAttacksTitle')}
                      value={stats.totalAttacks.toLocaleString(intl)}
                      images={[ImageAssets.sword]}
                    />
                    <SummaryMetric
                      label={t('esportsTriples')}
                      value={triples.toLocaleString(intl)}
                      images={[
                        ImageAssets.attackStar,
                        ImageAssets.attackStar,
                        ImageAssets.attackStar,
                      ]}
                    />
                    <SummaryMetric
                      label={t('warAttacksMissed')}
                      value={stats.missedAttacks.toLocaleString(intl)}
                      images={[ImageAssets.brokenSword]}
                      tone="missed"
                    />
                  </DashboardMetricGrid>
                ) : (
                  <CKText muted style={styles.emptyPerformance}>
                    {t('playerWarNoAttacks')}
                  </CKText>
                )}
              </>
            }
          >
            <WarMatchupChart stats={stats} />
          </PlayerWarFlipCard>
        );
      })}
    </View>
  );
}
function SummaryMetric({
  label,
  value,
  images,
  tone,
}: {
  label: string;
  value: string;
  images: string[];
  tone?: 'missed';
}) {
  return (
    <DashboardMetric
      label={label}
      value={value}
      tone={tone === 'missed' ? 'danger' : undefined}
      artwork={
        <View style={styles.metricArtwork}>
          {images.map((image, index) => (
            <MobileWebImage
              key={index}
              imageUrl={image}
              style={images.length === 1 ? styles.metricIcon : styles.tripleIcon}
            />
          ))}
        </View>
      }
    />
  );
}

/** Match CWL metadata by war identity first; never infer a round from list order. */
export function warCwlContext(war: PlayerWarStatsData, history?: PlayerCwlHistory | null) {
  if (!war.warDetails.isClanWarLeague || !history) return null;
  const tag = war.warDetails.tag?.replace(/^#/, '');
  if (tag) {
    for (const season of history.items) {
      const attack = season.attacks.find((item) => item.warTag.replace(/^#/, '') === tag);
      if (attack) return { season, round: attack.round || null };
    }
  }
  const month = war.warDetails.startTime?.toISOString().slice(0, 7);
  const sides = [war.warDetails.clan, war.warDetails.opponent];
  const seasons = history.items.filter(
    (season) =>
      season.season.slice(0, 7) === month && sides.some((clan) => clan?.tag === season.clan.tag),
  );
  if (seasons.length !== 1) return null;
  const season = seasons[0]!;
  const opponent = sides.find((clan) => clan && clan.tag !== season.clan.tag);
  const rounds = [
    ...new Set(
      season.attacks
        .filter((item) => item.opponentTag === opponent?.tag)
        .map((item) => item.round)
        .filter((round) => round > 0),
    ),
  ];
  return { season, round: rounds.length === 1 ? rounds[0]! : null };
}

export function WarMatchupChart({ stats }: { stats: PlayerWarTypeStats }) {
  const { t } = useI18n();
  return (
    <View style={styles.chartSections} testID="player-war-matchups">
      {stats.totalAttacks || stats.totalDefenses ? (
        (['attacks', 'defenses'] as const).map((direction) => (
          <MatchupMatrix key={direction} stats={stats} direction={direction} />
        ))
      ) : (
        <EmptyState title={t('generalNoDataAvailable')} body={t('statsNoDataBody')} />
      )}
    </View>
  );
}

function MatchupMatrix({
  stats,
  direction,
}: {
  stats: PlayerWarTypeStats;
  direction: 'attacks' | 'defenses';
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const source = direction === 'attacks' ? stats.byEnemyTownhall : stats.byEnemyTownhallDef;
  const levels = useMemo(() => {
    const own = new Set<number>(),
      opponent = new Set<number>();
    Object.keys(source).forEach((key) => {
      const match = /^(\d+)vs(\d+)$/.exec(key);
      if (!match) return;
      own.add(Number(match[direction === 'attacks' ? 1 : 2]));
      opponent.add(Number(match[direction === 'attacks' ? 2 : 1]));
    });
    return { own: [...own].sort((a, b) => b - a), opponent: [...opponent].sort((a, b) => b - a) };
  }, [source, direction]);
  return (
    <View style={styles.chartSections} testID={`player-war-matchups-${direction}`}>
      <View style={styles.row}>
        <MobileWebImage
          imageUrl={direction === 'attacks' ? ImageAssets.sword : ImageAssets.shield}
          style={styles.icon}
        />
        <CKText role="rowTitle">
          {t(direction === 'attacks' ? 'warAttacksTitle' : 'warDefensesTitle')}
        </CKText>
      </View>
      <Surface style={styles.chart}>
        {levels.own.length ? (
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.matrixContent}
          >
            <View>
              <View style={styles.row}>
                <View style={styles.axisCell}>
                  <CKText muted role="metadata">
                    {t('filtersTownHall')}
                  </CKText>
                </View>
                {levels.opponent.map((level) => (
                  <HallAxis key={level} level={level} />
                ))}
              </View>
              {levels.own.map((own) => (
                <View key={own} style={styles.row}>
                  <HallAxis level={own} />
                  {levels.opponent.map((opponent) => {
                    const key =
                      direction === 'attacks' ? `${own}vs${opponent}` : `${opponent}vs${own}`;
                    const value = source[key];
                    const triples = value?.starsCount['3'] ?? 0;
                    const ratio = value?.count ? triples / value.count : null;
                    const quality =
                      ratio === null ? null : direction === 'attacks' ? ratio : 1 - ratio;
                    const color =
                      quality === null
                        ? theme.onSurfaceVariant
                        : quality >= 0.7
                          ? statColors.win
                          : quality >= 0.4
                            ? statColors.warStarGold
                            : statColors.loss;
                    return (
                      <View
                        key={key}
                        accessible
                        accessibilityLabel={`${t('gameTownHallLevelShort', { level: own })} / ${t('gameTownHallLevelShort', { level: opponent })}: ${triples}/${value?.count ?? 0} ${t('esportsTriples')}`}
                        style={[
                          styles.cell,
                          {
                            backgroundColor: colorWithAlpha(color, value?.count ? 0.12 : 0.025),
                            borderColor:
                              own === opponent
                                ? colorWithAlpha(theme.onSurface, 0.25)
                                : 'transparent',
                          },
                        ]}
                      >
                        <CKText role="rowTitle" style={{ color }}>
                          {ratio === null
                            ? '—'
                            : `${(100 * ratio).toLocaleString(toIntlLocale(locale), { maximumFractionDigits: 0 })}%`}
                        </CKText>
                        {value?.count ? (
                          <CKText muted role="metadata">
                            {triples}/{value.count}
                          </CKText>
                        ) : null}
                      </View>
                    );
                  })}
                </View>
              ))}
            </View>
          </ScrollView>
        ) : (
          <CKText muted style={styles.emptyMatrix}>
            {t(direction === 'attacks' ? 'warAttacksNone' : 'warDefensesNone')}
          </CKText>
        )}
      </Surface>
    </View>
  );
}

function HallAxis({ level }: { level: number }) {
  const { t } = useI18n();
  return (
    <View style={styles.axisCell}>
      <MobileWebImage imageUrl={ImageAssets.townHall(level)} style={styles.hall} />
      <CKText muted role="metadata">
        {t('gameTownHallLevelShort', { level })}
      </CKText>
    </View>
  );
}

const styles = StyleSheet.create({
  sections: { gap: 12 },
  chartSections: { gap: 6 },
  grow: { flex: 1, minWidth: 0 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  summaryHeading: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 2 },
  summaryIcon: { width: 32, height: 32 },
  cardTitle: { fontSize: 18, lineHeight: 24, fontWeight: '700' },
  rateBlock: { alignItems: 'flex-end' },
  metricArtwork: {
    width: 28,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  metricIcon: { width: 20, height: 20 },
  tripleIcon: { width: 9, height: 13 },
  emptyPerformance: { paddingVertical: 10 },
  matrixContent: { flexGrow: 1, justifyContent: 'center' },
  emptyMatrix: { textAlign: 'center', paddingVertical: 12 },
  icon: { width: 24, height: 24 },
  rate: { fontSize: 36, lineHeight: 43, fontWeight: '700', marginTop: 4 },
  chart: { paddingVertical: 3, paddingHorizontal: 0, borderWidth: 0, borderRadius: ckRadius.card },
  axisCell: { width: 68, minHeight: 66, alignItems: 'center', justifyContent: 'center', gap: 3 },
  hall: { width: 32, height: 32 },
  cell: {
    width: 68,
    minHeight: 66,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 3,
    borderWidth: 1,
    borderRadius: 14,
    marginBottom: 6,
  },
});
