import { useEffect, useState } from 'react';
import { ActivityIndicator, Modal, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { expoEndpoints, type EndpointResponse } from '@clashking/api-contracts/expo';
import { Effect } from 'effect';
import { X } from 'lucide-react-native';
import Svg, { Circle, Line, Polyline } from 'react-native-svg';

import type { ContractApiService } from '../../../core/api/contract-api';
import { materialCloseLabel, toIntlLocale, useI18n } from '../../../i18n';
import { CKText, Surface, ckRadius, colorWithAlpha, useCKTheme } from '../../../ui';
import { LegendArmy } from '../../legends/presentation/legend-army-presentation';
import type { StatsLegendCohortValue } from '../models';

type ArmyDetail = EndpointResponse<typeof expoEndpoints.armyDetail>;
type ArmyTimeline = EndpointResponse<typeof expoEndpoints.armyTimeline>;

export interface ArmyDetailModalProps {
  readonly api: ContractApiService;
  readonly shareCode: string;
  readonly cohort: StatsLegendCohortValue;
  readonly start: Date;
  readonly end: Date;
  readonly visible: boolean;
  readonly onClose: () => void;
}

export function armyDetailTimeQuery(start: Date, end: Date) {
  // Date labels are inclusive; the API owns the 05:10 UTC Legend-day boundaries.
  return {
    'time[after]': localDate(start),
    'time[before]': localDate(end),
  } as const;
}

export function armyUsageRate(attacks: number, totalLegendAttacks: number): number {
  return totalLegendAttacks > 0 ? attacks / totalLegendAttacks : 0;
}

export function formatArmyPlayerCount(
  players: number | null,
  locale: string,
  unavailable: string,
): string {
  return players === null ? unavailable : players.toLocaleString(toIntlLocale(locale));
}

export function ArmyDetailModal({
  api,
  shareCode,
  cohort,
  start,
  end,
  visible,
  onClose,
}: ArmyDetailModalProps) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [detail, setDetail] = useState<ArmyDetail | null>(null);
  const [timeline, setTimeline] = useState<ArmyTimeline | null>(null);
  const [error, setError] = useState<unknown>();
  const [loading, setLoading] = useState(false);
  const [revision, setRevision] = useState(0);

  useEffect(() => {
    if (!visible || !shareCode) return;
    let current = true;
    const query = { ...armyDetailTimeQuery(start, end), cohort, armyLink: shareCode };
    const load = async () => {
      setLoading(true);
      setError(undefined);
      setDetail(null);
      setTimeline(null);
      try {
        const [nextDetail, nextTimeline] = await Promise.all([
          Effect.runPromise(api.execute(expoEndpoints.armyDetail, { path: {}, query, body: {} })),
          Effect.runPromise(api.execute(expoEndpoints.armyTimeline, { path: {}, query, body: {} })),
        ]);
        if (!current) return;
        setDetail(nextDetail);
        setTimeline(nextTimeline);
      } catch (caught) {
        if (current) setError(caught);
      } finally {
        if (current) setLoading(false);
      }
    };
    void load();
    return () => {
      current = false;
    };
  }, [api, cohort, end, revision, shareCode, start, visible]);

  const title = detail?.name ?? timeline?.name ?? t('statsArmies');
  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={styles.overlay}>
        <Surface radius={ckRadius.card} style={styles.sheet}>
          <View style={styles.header}>
            <View style={styles.grow}>
              <CKText role="titleLarge" numberOfLines={1}>
                {title}
              </CKText>
              <CKText role="bodySmall" muted numberOfLines={1}>
                {t('statsArmyShareCode')}: {shareCode}
              </CKText>
            </View>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={materialCloseLabel(locale)}
              onPress={onClose}
              style={styles.iconButton}
            >
              <X color={theme.onSurface} />
            </Pressable>
          </View>
          <ScrollView contentContainerStyle={styles.content}>
            {loading && !detail ? <ActivityIndicator color={theme.primary} /> : null}
            {error ? (
              <View style={styles.error}>
                <CKText role="rowTitle" style={{ color: theme.error }}>
                  {t('generalError')}
                </CKText>
                <Pressable
                  accessibilityRole="button"
                  onPress={() => setRevision((value) => value + 1)}
                  style={[styles.retry, { backgroundColor: theme.surfaceContainerHighest }]}
                >
                  <CKText role="labelLarge">{t('generalRetry')}</CKText>
                </Pressable>
              </View>
            ) : null}
            {detail ? (
              <>
                <View style={styles.metrics}>
                  <DetailMetric
                    label={t('statsUsage')}
                    value={formatPercent(armyUsageRate(detail.attacks, detail.totalLegendAttacks))}
                  />
                  <DetailMetric
                    label={t('statsThreeStarRate')}
                    value={formatPercent(
                      detail.attacks ? detail.starCounts.three / detail.attacks : 0,
                    )}
                  />
                  <DetailMetric
                    label={t('statsSamples')}
                    value={detail.attacks.toLocaleString(toIntlLocale(locale))}
                  />
                  <DetailMetric
                    label={t('statsPlayers')}
                    value={formatArmyPlayerCount(detail.players, locale, t('generalUnknown'))}
                  />
                </View>
                <View style={styles.section}>
                  <CKText role="titleMedium">{t('statsExactComposition')}</CKText>
                  <LegendArmy shareCode={detail.shareCode} />
                </View>
              </>
            ) : null}
            {timeline?.items.length ? (
              <View style={styles.section}>
                <CKText role="titleMedium">{t('statsDailyTrend')}</CKText>
                <ArmyTimelineChart timeline={timeline} />
              </View>
            ) : null}
          </ScrollView>
        </Surface>
      </View>
    </Modal>
  );
}

function ArmyTimelineChart({ timeline }: { readonly timeline: ArmyTimeline }) {
  const theme = useCKTheme();
  const { t } = useI18n();
  const [selected, setSelected] = useState<number | null>(null);
  const points = timeline.items.map((item) =>
    item.attacks ? item.starCounts.three / item.attacks : 0,
  );
  const selectedIndex = selected ?? timeline.items.length - 1;
  const selectedItem = timeline.items[selectedIndex];
  const x = (index: number) => (index * 300) / Math.max(1, timeline.items.length - 1) + 10;
  const y = (value: number) => 112 - Math.max(0, Math.min(1, value)) * 96;
  return (
    <View style={styles.timeline}>
      {selectedItem ? (
        <CKText role="bodySmall" muted>
          {selectedItem.day} · {t('statsUsage')}:{' '}
          {formatPercent(armyUsageRate(selectedItem.attacks, selectedItem.totalLegendAttacks))} ·{' '}
          {t('statsThreeStarRate')}:{' '}
          {formatPercent(
            selectedItem.attacks ? selectedItem.starCounts.three / selectedItem.attacks : 0,
          )}
        </CKText>
      ) : null}
      <View style={styles.timelineChart}>
        <Svg width="100%" height="100%" viewBox="0 0 320 128">
          {[16, 64, 112].map((value) => (
            <Line
              key={value}
              x1={10}
              x2={310}
              y1={value}
              y2={value}
              stroke={colorWithAlpha(theme.outlineVariant, 0.38)}
            />
          ))}
          {points.length > 1 ? (
            <Polyline
              points={points.map((value, index) => `${x(index)},${y(value)}`).join(' ')}
              fill="none"
              stroke={theme.primary}
              strokeWidth={3}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          ) : null}
          {points.map((value, index) => (
            <Circle
              key={timeline.items[index]!.day}
              cx={x(index)}
              cy={y(value)}
              r={index === selectedIndex ? 7 : 5}
              fill={index === selectedIndex ? theme.onSurface : theme.primary}
              stroke={theme.primary}
              strokeWidth={2}
              onPress={() => setSelected(index)}
            />
          ))}
        </Svg>
      </View>
    </View>
  );
}

function DetailMetric({ label, value }: { readonly label: string; readonly value: string }) {
  return (
    <View style={styles.metric}>
      <CKText role="titleMedium">{value}</CKText>
      <CKText role="bodySmall" muted>
        {label}
      </CKText>
    </View>
  );
}

function localDate(value: Date): string {
  return `${value.getFullYear().toString().padStart(4, '0')}-${(value.getMonth() + 1)
    .toString()
    .padStart(2, '0')}-${value.getDate().toString().padStart(2, '0')}`;
}

function formatPercent(value: number): string {
  return `${(Math.max(0, Math.min(1, value)) * 100).toFixed(value >= 0.1 ? 1 : 2)}%`;
}

const styles = StyleSheet.create({
  overlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#00000099' },
  sheet: { maxHeight: '92%', borderBottomLeftRadius: 0, borderBottomRightRadius: 0 },
  header: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 18 },
  grow: { flex: 1, minWidth: 0 },
  iconButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  content: { paddingHorizontal: 18, paddingBottom: 28, gap: 18 },
  error: { alignItems: 'center', gap: 10, paddingVertical: 24 },
  retry: { minHeight: 44, justifyContent: 'center', paddingHorizontal: 18, borderRadius: 12 },
  metrics: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  metric: {
    minWidth: 132,
    flexBasis: 132,
    flexGrow: 1,
    padding: 14,
    borderRadius: 18,
    backgroundColor: '#80808018',
  },
  section: { gap: 10 },
  timeline: { gap: 8 },
  timelineChart: { height: 160 },
});
