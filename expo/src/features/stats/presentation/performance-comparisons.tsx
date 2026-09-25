import { StyleSheet, View } from 'react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { formatCompactNumber, toIntlLocale, useI18n } from '../../../i18n';
import { CKText, MobileWebImage, Surface, ckRadius, ckSpacing, useCKTheme } from '../../../ui';
import { StatsSection, type StatsBreakdown, type StatsSectionValue } from '../models';

function rate(value: number, locale: string): string {
  return new Intl.NumberFormat(toIntlLocale(locale), {
    style: 'percent',
    maximumFractionDigits: 1,
  }).format(Math.abs(value) > 1 ? value / 100 : value);
}

export function PerformanceComparisons({
  section,
  comparisons,
}: {
  readonly section: StatsSectionValue;
  readonly comparisons: readonly StatsBreakdown[];
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  if (comparisons.length === 0) return null;
  const isTownHall = section === StatsSection.war || section === StatsSection.cwl;
  return (
    <View style={styles.section} testID="performance-comparisons">
      <CKText role="titleMedium">
        {isTownHall
          ? t('statsHitratesByTownHall')
          : `${t('statsThreeStarRate')} · ${t('statsLeagueTier')}`}
      </CKText>
      <View style={styles.rows}>
        {comparisons.map(({ key, metrics }) => {
          const townHall = /^TH(\d+)$/u.exec(key);
          const imageUrl =
            isTownHall && townHall
              ? ImageAssets.townHall(Number(townHall[1]))
              : ImageAssets.getLeagueImage(key);
          const sample = new Intl.NumberFormat(toIntlLocale(locale)).format(metrics.sampleSize);
          return (
            <Surface
              key={key}
              muted
              radius={ckRadius.tile}
              style={styles.row}
              accessibilityLabel={`${key}, ${metrics.available ? rate(metrics.threeStarRate, locale) : '—'}, ${sample} ${t('warAttacksTitle')}`}
              testID={`performance-comparison-${key}`}
            >
              <MobileWebImage
                imageUrl={imageUrl}
                contentFit="contain"
                accessible={false}
                style={styles.artwork}
              />
              <CKText role="rowTitle" numberOfLines={1} style={styles.label}>
                {key}
              </CKText>
              <View style={styles.values}>
                <CKText
                  role="rowTitle"
                  style={{ color: metrics.available ? theme.onSurface : theme.onSurfaceVariant }}
                >
                  {metrics.available ? rate(metrics.threeStarRate, locale) : '—'}
                </CKText>
                {metrics.available ? (
                  <CKText role="bodySmall" muted>
                    {formatCompactNumber(metrics.sampleSize, locale)} {t('warAttacksTitle')}
                  </CKText>
                ) : null}
              </View>
            </Surface>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  section: { gap: ckSpacing.md },
  rows: { gap: ckSpacing.xs },
  row: {
    minHeight: 50,
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.sm,
    paddingHorizontal: ckSpacing.md,
    paddingVertical: ckSpacing.xs,
  },
  artwork: { width: 34, height: 34 },
  label: { flex: 1, minWidth: 0 },
  values: { alignItems: 'flex-end', minWidth: 70 },
});
