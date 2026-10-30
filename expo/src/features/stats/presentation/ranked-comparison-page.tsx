import { useEffect, useMemo, useState, useRef, useId, type ReactNode } from 'react';
import { ActivityIndicator, Animated, Easing, Pressable, StyleSheet, View } from 'react-native';
import { Image as ExpoImage } from 'expo-image';
import { RotateCw } from 'lucide-react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';
import type { ContractApiService } from '../../../core/api/contract-api';
import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  ErrorState,
  SelectionPicker,
  MobileWebImage,
  ckColors,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { StatsRepository, type LegendDayPerformance } from '../data/stats-repository';
import { loadObservedRankedRange, totalLegendDays } from '../data/ranked-comparison-data';
import {
  StatsDateFilter,
  StatsLegendCohort,
  StatsLegendQuery,
  type StatsLegendResponse,
} from '../models';
import { Effect } from 'effect';
import { LegendRankCurveEndpoint, type EndpointResponse } from '@clashking/api-contracts/expo';
import { RankedTrendChart } from './ranked-trend-chart';
import { useCKAccessibility } from '../../../ui/accessibility';

type Data = { performance: LegendDayPerformance; battles?: StatsLegendResponse };
type ArtSource = string | number;
const airArt = require('../../../../assets/clashking/ranked/air-wing.png');
const groundArt = require('../../../../assets/clashking/ranked/ground-boot.png');
type Tier = 'all' | 'top1000' | 'top200';
const tiers: Tier[] = ['all', 'top1000', 'top200'];
const accents = [ckColors.warGold, ckColors.legendBlue, ckColors.capitalPurple];
const sum = (values: readonly number[]) => values.reduce((a, b) => a + b, 0);

export function RankedComparisonPage({
  api,
  dates,
  onDates,
}: {
  api: ContractApiService;
  dates: StatsDateFilter;
  onDates: (dates: StatsDateFilter) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const repository = useMemo(() => new StatsRepository(api), [api]);
  const first = StatsDateFilter.formatDate(dates.start),
    last = StatsDateFilter.formatDate(dates.end),
    key = `${first}:${last}`;
  const [selectedMetric, setSelectedMetric] = useState<
    number | 'averageStars' | 'destruction' | 'duration'
  >(3);
  const [curveResult, setCurve] = useState<{
    key: string;
    data: EndpointResponse<typeof LegendRankCurveEndpoint>;
  }>();
  const curve = curveResult?.key === key ? curveResult.data : undefined;
  const [result, setResult] = useState<{
    key: string;
    values: Partial<Record<Tier, Data>>;
    prior?: LegendDayPerformance;
    error?: unknown;
  }>();
  const [armyState, setArmyState] = useState<{
    key: string;
    status: 'loading' | 'ready' | 'error';
  }>({ key: '', status: 'loading' });
  const [retry, setRetry] = useState(0),
    [defense, setDefense] = useState(false),
    [trophyTier, setTrophyTier] = useState<Tier>('all');
  const [priorRanks, setPriorRanks] = useState<{
    key: string;
    values: Partial<Record<Tier, LegendDayPerformance>>;
  }>();
  useEffect(() => {
    let active = true;
    const selectedDates = new StatsDateFilter(
      new Date(`${first}T12:00:00`),
      new Date(`${last}T12:00:00`),
    );
    const save = (tier: Tier, data: Data) => {
      if (active)
        setResult((p) => ({
          key,
          // A fast cached detail response may beat the basic response. Never
          // replace already-loaded army details with the later basic payload.
          values: {
            ...(p?.key === key ? p.values : {}),
            [tier]:
              tier === 'all' &&
              p?.key === key &&
              p.values.all?.performance.items.some((d) => d.offense.attackTypes) &&
              !data.performance.items.some((d) => d.offense.attackTypes)
                ? p.values.all
                : data,
          },
          prior: p?.key === key ? p.prior : undefined,
        }));
    };
    void Effect.runPromise(
      api.execute(LegendRankCurveEndpoint, { path: {}, query: { day: last }, body: {} }),
    )
      .then((data) => {
        if (active) setCurve({ key, data });
      })
      .catch(() => {});
    void loadObservedRankedRange(repository, selectedDates, true)
      .then((performance) => {
        save('all', { performance });
        if (active) setArmyState({ key: `${key}:${retry}`, status: 'ready' });
      })
      .catch(() => {
        if (active) setArmyState({ key: `${key}:${retry}`, status: 'error' });
      });
    void (async () => {
      const basic = await loadObservedRankedRange(repository, selectedDates, false);
      if (!active) return;
      save('all', { performance: basic });
      // Secondary views load independently; unavailable ranks never replace All.
      for (const tier of ['top1000', 'top200'] as const) {
        const cohort = tier === 'top1000' ? StatsLegendCohort.top1000 : StatsLegendCohort.top200;
        void Promise.all([
          repository.loadLegendPerformance(
            new StatsLegendQuery(selectedDates, cohort),
            false,
            false,
            false,
          ),
          repository.loadItems(new StatsLegendQuery(selectedDates, cohort)),
        ])
          .then(([performance, battles]) => save(tier, { performance, battles }))
          .catch(() => {});
      }
      const priorEnd = new Date(selectedDates.start);
      priorEnd.setDate(priorEnd.getDate() - 1);
      const priorStart = new Date(priorEnd);
      priorStart.setDate(priorStart.getDate() - selectedDates.inclusiveDays + 1);
      for (const tier of ['top1000', 'top200'] as const) {
        void repository
          .loadLegendPerformance(
            new StatsLegendQuery(
              new StatsDateFilter(priorStart, priorEnd),
              tier === 'top1000' ? StatsLegendCohort.top1000 : StatsLegendCohort.top200,
            ),
            false,
            false,
            false,
          )
          .then((data) => {
            if (active)
              setPriorRanks((p) => ({
                key,
                values: { ...(p?.key === key ? p.values : {}), [tier]: data },
              }));
          })
          .catch(() => {});
      }
      void loadObservedRankedRange(repository, new StatsDateFilter(priorStart, priorEnd), false)
        .then((prior) => {
          if (active) setResult((p) => (p?.key === key ? { ...p, prior } : p));
        })
        .catch(() => {});
    })().catch((error) => {
      if (active) setResult({ key, values: {}, error });
    });
    return () => {
      active = false;
    };
  }, [repository, first, last, key, retry, api]);
  const current = result?.key === key ? result : undefined;
  const labels = [
    t('generalAll'),
    t('rankingsTopCount', { count: 1000 }),
    t('rankingsTopCount', { count: 200 }),
  ];
  const number = new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 1 });
  const pct = (n: number | null | undefined) => (n == null ? '—' : `${number.format(n * 100)}%`);
  const dec = (n: number | null | undefined) => (n == null ? '—' : number.format(n));
  function metrics(tier: Tier) {
    const data = current?.values[tier];
    if (!data) return undefined;
    const p = data.performance.periods.find((p) => p.kind === 'selected');
    if (!p) return undefined;
    if (data.battles) {
      const days = data.battles.items,
        attacks = sum(days.map((d) => d.attacks));
      const stars = [0, 1, 2, 3].map((i) => sum(days.map((d) => d.starCounts[i] ?? 0)));
      return {
        p,
        attacks,
        stars,
        averageStars: attacks ? sum(stars.map((n, i) => n * i)) / attacks : null,
        destruction: attacks
          ? sum(days.map((d) => (d.averageDestruction ?? 0) * d.attacks)) / attacks
          : null,
        duration: attacks
          ? sum(days.map((d) => (d.averageDuration ?? 0) * d.attacks)) / attacks
          : null,
      };
    }
    const closed = p.offense,
      today = data.performance.currentDay?.offense,
      attacks = closed.observedBattles + (today?.battles ?? 0),
      stars = [0, 1, 2, 3].map(
        (i) => (closed.starCounts?.[i] ?? 0) + (today?.starCounts?.[i] ?? 0),
      );
    const weighted = (field: 'averageStars' | 'averageDestruction' | 'averageDuration') => {
      const count =
        (closed[field] != null ? closed.observedBattles : 0) +
        (today?.[field] != null ? today.battles : 0);
      return count
        ? ((closed[field] ?? 0) * closed.observedBattles +
            (today?.[field] ?? 0) * (today?.battles ?? 0)) /
            count
        : null;
    };
    return {
      p,
      attacks,
      stars,
      averageStars: weighted('averageStars'),
      destruction: weighted('averageDestruction'),
      duration: weighted('averageDuration'),
    };
  }
  const all = metrics('all'),
    side = defense ? 'defense' : 'offense';
  const tierValues = (
    value: (tier: Tier) => string,
    large = false,
    compact = false,
    select?: (tier: Tier) => void,
  ) => (
    <View style={s.comparison}>
      {tiers.map((tier, i) => (
        <Pressable
          key={tier}
          style={s.column}
          disabled={!select}
          onPress={() => select?.(tier)}
          accessibilityRole={select ? 'button' : undefined}
          accessibilityLabel={select ? `${labels[i]} ${value(tier)}` : undefined}
          accessibilityState={select ? { selected: trophyTier === tier } : undefined}
        >
          <CKText
            role={large ? 'heroMetric' : 'titleSmall'}
            numberOfLines={1}
            adjustsFontSizeToFit
            style={{
              color: accents[i],
              fontWeight: '700',
              fontVariant: ['tabular-nums'],
              ...(large ? { fontSize: compact ? 32.4 : 36 } : {}),
            }}
          >
            {value(tier)}
          </CKText>
        </Pressable>
      ))}
    </View>
  );
  const tierLabels = (select?: (tier: Tier) => void, gutter = false) => (
    <View style={[s.comparison, gutter && { marginLeft: 32 }]}>
      {labels.map((label, i) => (
        <Pressable
          key={label}
          disabled={!select}
          onPress={() => select?.(tiers[i]!)}
          accessibilityRole={select ? 'button' : undefined}
          accessibilityState={select ? { selected: trophyTier === tiers[i] } : undefined}
          style={[
            s.column,
            select && {
              paddingVertical: 6,
              borderRadius: 10,
              backgroundColor:
                trophyTier === tiers[i] ? colorWithAlpha(accents[i]!, 0.14) : 'transparent',
            },
          ]}
        >
          <CKText role="labelSmall" muted={!select || trophyTier !== tiers[i]}>
            {label}
          </CKText>
        </Pressable>
      ))}
    </View>
  );
  const panel = (
    title: string | undefined,
    icon: ArtSource,
    color: string,
    body: ReactNode,
    action?: ReactNode,
    back?: ReactNode,
  ) => (
    <FlipRankedPanel
      title={title}
      icon={icon}
      color={color}
      action={action}
      front={body}
      back={back}
    />
  );
  const metricTitle =
    typeof selectedMetric === 'number'
      ? selectedMetric === 3
        ? t('statsThreeStarRate')
        : `${selectedMetric} ★`
      : selectedMetric === 'averageStars'
        ? t('statsAverageStars')
        : selectedMetric === 'destruction'
          ? t('statsAverageDestruction')
          : t('warAttacksDetailsDuration');
  const starSeries = tiers.map((tier, i) => {
    const data = current?.values[tier];
    const points = data?.battles
      ? data.battles.items.map((d) => ({
          day: d.day,
          value:
            typeof selectedMetric === 'number'
              ? d.attacks
                ? (d.starCounts[selectedMetric]! / d.attacks) * 100
                : null
              : selectedMetric === 'averageStars'
                ? d.attacks
                  ? d.starCounts.reduce((n, c, i) => n + c * i, 0) / d.attacks
                  : null
                : selectedMetric === 'destruction'
                  ? d.averageDestruction
                  : d.averageDuration,
          weight: d.attacks,
        }))
      : (data?.performance.items.map((d) => ({
          day: d.day,
          value:
            typeof selectedMetric === 'number'
              ? d.offense.observedBattles && d.offense.starCounts
                ? (d.offense.starCounts[selectedMetric]! / d.offense.observedBattles) * 100
                : null
              : selectedMetric === 'averageStars'
                ? (d.offense.averageStars ?? null)
                : selectedMetric === 'destruction'
                  ? (d.offense.averageDestruction ?? null)
                  : (d.offense.averageDuration ?? null),
          weight: d.offense.observedBattles,
        })) ?? []);
    const today = data?.performance.currentDay;
    if (!data?.battles && today)
      points.push({
        day: today.day,
        value:
          typeof selectedMetric === 'number'
            ? today.offense.battles && today.offense.starCounts
              ? (today.offense.starCounts[selectedMetric]! / today.offense.battles) * 100
              : null
            : selectedMetric === 'averageStars'
              ? (today.offense.averageStars ?? null)
              : selectedMetric === 'destruction'
                ? (today.offense.averageDestruction ?? null)
                : (today.offense.averageDuration ?? null),
        weight: today.offense.battles,
      });
    return {
      key: tier,
      label: labels[i]!,
      color: accents[i],
      aggregation: 'weightedMean' as const,
      points,
    };
  });
  if (current?.error)
    return (
      <ErrorState
        title={t('sideStatsLoadError')}
        body={t('statsNoDataBody')}
        actionLabel={t('generalRetry')}
        onAction={() => setRetry((v) => v + 1)}
      />
    );
  if (!all) return <ActivityIndicator color={theme.primary} />;
  const allPerformance = current!.values.all!.performance;
  const totalTypes = totalLegendDays(allPerformance.items.map((d) => d.offense)).attackTypes;
  const todayTypes = allPerformance.currentDay?.offense.attackTypes;
  const types = totalTypes
    ? {
        air: totalTypes.air + (todayTypes?.air ?? 0),
        ground: totalTypes.ground + (todayTypes?.ground ?? 0),
        mixed: totalTypes.mixed + (todayTypes?.mixed ?? 0),
        unknown: totalTypes.unknown + (todayTypes?.unknown ?? 0),
      }
    : undefined;
  const classified = types ? types.air + types.ground + types.mixed : 0;
  const prior =
    trophyTier === 'all'
      ? current?.prior?.periods[0]?.offense
      : priorRanks?.key === key
        ? priorRanks.values[trophyTier]?.periods[0]?.offense
        : undefined;
  const trophy = metrics(trophyTier)?.p.offense ?? totalLegendDays([]);
  const previousAvailable = prior != null && prior.completePlayerDays > 0;
  // Crop only the plot; shares retain all complete days as their denominator.
  const distributionPoints = (buckets: typeof trophy.buckets) =>
    buckets
      .filter((bucket) => bucket.minimum >= 140)
      .map((bucket) => ({
        day: String(bucket.minimum + 10),
        value: bucket.share == null ? null : bucket.share * 100,
      }));
  const parts = [
    {
      key: 'air',
      label: t('gameItemTargetsAir'),
      color: ckColors.legendBlue,
      icon: airArt,
    },
    {
      key: 'ground',
      label: t('gameItemTargetsGround'),
      color: ckColors.warGold,
      icon: groundArt,
    },
    {
      key: 'mixed',
      label: `${t('gameItemTargetsAir')} + ${t('gameItemTargetsGround')}`,
      color: ckColors.capitalPurple,
      icon: airArt,
    },
  ] as const;
  return (
    <View style={s.root}>
      <SelectionPicker
        title={t('statsLeagueTier')}
        fillWidth
        selectedKey="legend_i"
        onSelect={() => {}}
        options={[
          {
            key: 'legend_i',
            label: t('statsLegendLeagueOne'),
            icon: (
              <MobileWebImage
                imageUrl={ImageAssets.legendLeagueOne}
                contentFit="contain"
                style={{ width: 28, height: 28 }}
              />
            ),
          },
        ]}
      />
      {!all.attacks && allPerformance.availability ? (
        <Pressable
          onPress={() => {
            const end = new Date(`${allPerformance.availability!.lastDay}T12:00:00`);
            const start = new Date(end);
            start.setDate(start.getDate() - 6);
            onDates(new StatsDateFilter(start, end));
          }}
        >
          <CKText style={{ color: theme.primary }}>{t('statsViewLatestData')}</CKText>
        </Pressable>
      ) : null}
      {panel(
        undefined,
        ImageAssets.attackStar,
        ckColors.warGold,
        <>
          {tierLabels(undefined, true)}
          {[3, 2, 1, 0].map((star) => (
            <Pressable
              key={star}
              accessibilityRole="button"
              onPress={() => setSelectedMetric(star)}
              style={[
                s.starRow,
                {
                  borderRadius: 10,
                  backgroundColor:
                    selectedMetric === star
                      ? colorWithAlpha(ckColors.warGold, 0.035)
                      : 'transparent',
                },
              ]}
            >
              <CKText role="bodySmall" style={{ width: 28 }}>
                {star} ★
              </CKText>
              <View style={s.grow}>
                {tierValues(
                  (tier) => {
                    const m = metrics(tier);
                    return pct(m?.attacks ? m.stars[star]! / m.attacks : null);
                  },
                  star === 3,
                  true,
                )}
              </View>
            </Pressable>
          ))}
          <View style={[s.track, { backgroundColor: colorWithAlpha(theme.onSurface, 0.06) }]}>
            {[3, 2, 1, 0].map((star, i) => (
              <View
                key={star}
                style={{
                  flex: all.stars[star] ?? 0,
                  backgroundColor: [
                    ckColors.warGold,
                    ckColors.legendBlue,
                    ckColors.capitalPurple,
                    theme.onSurfaceVariant,
                  ][i],
                }}
              />
            ))}
          </View>
          <View style={s.averages}>
            {[
              {
                metric: 'averageStars' as const,
                label: t('statsAverageStars'),
                value:
                  all.averageStars == null
                    ? '—'
                    : new Intl.NumberFormat(toIntlLocale(locale), {
                        maximumFractionDigits: 2,
                      }).format(all.averageStars),
                icon: ImageAssets.attackStar,
              },
              {
                metric: 'destruction' as const,
                label: t('statsAverageDestruction'),
                value: all.destruction == null ? '—' : `${dec(all.destruction)}%`,
                icon: ImageAssets.sword,
              },
              {
                metric: 'duration' as const,
                label: t('warAttacksDetailsDuration'),
                value:
                  all.duration == null
                    ? '—'
                    : `${Math.floor(Math.round(all.duration) / 60)}:${String(Math.round(all.duration) % 60).padStart(2, '0')}`,
                icon: ImageAssets.iconClock,
              },
            ].map((item) => (
              <Pressable
                key={item.label}
                onPress={() => setSelectedMetric(item.metric)}
                style={s.average}
              >
                <MobileWebImage
                  imageUrl={item.icon}
                  contentFit="contain"
                  style={{ width: 22, height: 22 }}
                />
                <CKText role="titleSmall">{item.value}</CKText>
                <CKText role="labelSmall" muted>
                  {item.label}
                </CKText>
              </Pressable>
            ))}
          </View>
          <CKText role="labelSmall" muted>
            {metricTitle}
          </CKText>
          <RankedTrendChart
            series={starSeries}
            percent={typeof selectedMetric === 'number' || selectedMetric === 'destruction'}
            formatValue={
              selectedMetric === 'duration'
                ? (n) => `${Math.floor(n / 60)}:${String(Math.round(n) % 60).padStart(2, '0')}`
                : undefined
            }
          />
        </>,
      )}
      {panel(
        t(defense ? 'rankedFullDefenseDays' : 'rankedFullOffenseDays'),
        `${ImageAssets.baseUrl}/equipment/fireball.webp`,
        ckColors.capitalOrange,
        <>
          {tierLabels()}
          {tierValues((tier) => pct(metrics(tier)?.p[side].perfectDayRate), true)}
        </>,
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t(defense ? 'capitalDetailsOffense' : 'capitalDetailsDefense')}
          onPress={() => setDefense((v) => !v)}
          style={[s.action, { backgroundColor: colorWithAlpha(ckColors.capitalPurple, 0.16) }]}
        >
          <MobileWebImage
            imageUrl={defense ? ImageAssets.shield : ImageAssets.sword}
            contentFit="contain"
            style={{ width: 24, height: 24 }}
          />
        </Pressable>,
        <RankedTrendChart
          showLegend
          percent
          formatPointDetail={(tier, day) => {
            const value = current?.values[tier as Tier]?.performance.items.find(
              (item) => item.day === day,
            )?.[side].perfectPlayerDays;
            return value == null ? undefined : number.format(value);
          }}
          series={tiers.map((tier, i) => ({
            key: tier,
            label: labels[i]!,
            color: accents[i],
            points:
              current?.values[tier]?.performance.items.map((d) => ({
                day: d.day,
                value: d[side].perfectDayRate == null ? null : d[side].perfectDayRate! * 100,
              })) ?? [],
          }))}
        />,
      )}
      {panel(
        `${t('rankedLeagueAverage')} ${t('capitalDetailsOffense')}`,
        ImageAssets.trophies,
        ckColors.warGold,
        <>
          {tierLabels(setTrophyTier)}
          {tierValues(
            (tier) => dec(metrics(tier)?.p.offense.meanTrophies),
            true,
            false,
            setTrophyTier,
          )}
          <View style={s.legend}>
            <CKText role="labelSmall" style={{ color: ckColors.warGold }}>
              {t('rankedLeagueCurrentPeriod')}
            </CKText>
            {previousAvailable ? (
              <CKText role="labelSmall" style={{ color: ckColors.legendBlue }}>
                {t('upgradeTrackerPreviousPeriod')}
              </CKText>
            ) : null}
          </View>
          {trophy.completePlayerDays === 0 ? (
            <CKText role="bodySmall" muted style={{ textAlign: 'center' }}>
              {t('statsNoDataTitle')}
            </CKText>
          ) : (
            <RankedTrendChart
              percent
              xKind="number"
              xDomain={[140, 320]}
              formatPointLabel={(value) => {
                const minimum = Number(value) - 10;
                return `${minimum}–${minimum === 300 ? 320 : minimum + 19}`;
              }}
              series={[
                {
                  key: 'current',
                  label: t('rankedLeagueCurrentPeriod'),
                  color: ckColors.warGold,
                  points: distributionPoints(trophy.buckets),
                },
                ...(previousAvailable
                  ? [
                      {
                        key: 'previous',
                        label: t('upgradeTrackerPreviousPeriod'),
                        color: ckColors.legendBlue,
                        points: distributionPoints(prior.buckets),
                      },
                    ]
                  : []),
              ]}
            />
          )}
        </>,
        undefined,
        <RankedTrendChart
          showLegend
          series={tiers.map((tier, i) => ({
            key: tier,
            label: labels[i]!,
            color: accents[i],
            points:
              current?.values[tier]?.performance.items.map((d) => ({
                day: d.day,
                value: d.offense.meanTrophies,
              })) ?? [],
          }))}
        />,
      )}
      {curve?.items.length
        ? panel(
            t('rankedTrophiesByRank'),
            ImageAssets.trophies,
            ckColors.legendBlue,
            <>
              <RankedTrendChart
                xKind="rank"
                series={[
                  {
                    key: 'ranks',
                    label: t('gameTrophies'),
                    color: ckColors.legendBlue,
                    points: curve.items.map((p) => ({ day: String(p.rank), value: p.trophies })),
                  },
                ]}
              />
            </>,
          )
        : null}
      {panel(
        t('statsArmyTypes'),
        airArt,
        ckColors.legendBlue,
        <>
          {classified ? (
            <>
              <View style={s.track}>
                {parts.map((p) => (
                  <View key={p.key} style={{ flex: types![p.key], backgroundColor: p.color }} />
                ))}
              </View>
              <View style={s.averages}>
                {parts.map((p) => (
                  <View key={p.key} style={s.average}>
                    {p.key === 'mixed' ? (
                      <View style={{ width: 50, height: 42 }}>
                        <RankedArtwork
                          source={airArt}
                          size={31}
                          style={{ position: 'absolute', left: 0, top: 0 }}
                        />
                        <RankedArtwork
                          source={groundArt}
                          size={31}
                          style={{ position: 'absolute', right: 0, bottom: 0 }}
                        />
                      </View>
                    ) : (
                      <RankedArtwork source={p.icon} size={42} />
                    )}
                    <CKText role="titleLarge" style={{ color: p.color }}>
                      {pct(types![p.key] / classified)}
                    </CKText>
                    <CKText role="labelSmall" muted>
                      {p.label}
                    </CKText>
                  </View>
                ))}
              </View>
              <RankedTrendChart
                percent
                formatPointDetail={(part, day) => {
                  const counts =
                    allPerformance.currentDay?.day === day
                      ? allPerformance.currentDay.offense.attackTypes
                      : allPerformance.items.find((item) => item.day === day)?.offense.attackTypes;
                  if (!counts) return undefined;
                  const total = counts.air + counts.ground + counts.mixed;
                  const count = counts[part as 'air' | 'ground' | 'mixed'];
                  return `${number.format(count)} / ${number.format(total)}`;
                }}
                series={parts.map((p) => ({
                  key: p.key,
                  label: p.label,
                  color: p.color,
                  points: [
                    ...allPerformance.items.map((d) => ({
                      day: d.day,
                      types: d.offense.attackTypes,
                    })),
                    ...(allPerformance.currentDay
                      ? [
                          {
                            day: allPerformance.currentDay.day,
                            types: allPerformance.currentDay.offense.attackTypes,
                          },
                        ]
                      : []),
                  ].map((d) => {
                    const count = d.types ? d.types.air + d.types.ground + d.types.mixed : 0;
                    return {
                      day: d.day,
                      value: d.types && count ? (d.types[p.key] / count) * 100 : null,
                    };
                  }),
                }))}
              />
            </>
          ) : armyState.key !== `${key}:${retry}` || armyState.status === 'loading' ? (
            <ActivityIndicator color={ckColors.legendBlue} />
          ) : (
            <Pressable accessibilityRole="button" onPress={() => setRetry((v) => v + 1)}>
              <CKText role="bodySmall" muted>
                {t(armyState.status === 'error' ? 'generalRetry' : 'statsNoDataTitle')}
              </CKText>
            </Pressable>
          )}
        </>,
      )}
    </View>
  );
}
const s = StyleSheet.create({
  root: { gap: 16, paddingBottom: 24 },
  league: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 6,
    paddingBottom: 4,
  },
  panel: { borderRadius: 26, padding: 20, gap: 16, overflow: 'hidden' },
  heading: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  icon: { width: 28, height: 28 },
  grow: { flex: 1 },
  action: {
    width: 38,
    height: 38,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  comparison: { flexDirection: 'row', gap: 8 },
  column: { flex: 1, minWidth: 0, alignItems: 'center', gap: 6 },
  dot: { width: 18, height: 3, borderRadius: 2 },
  starRow: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  track: { height: 8, borderRadius: 4, overflow: 'hidden', flexDirection: 'row' },
  averages: { flexDirection: 'row', gap: 12, paddingTop: 4 },
  average: { flex: 1, alignItems: 'center', gap: 6 },
  legend: { flexDirection: 'row', justifyContent: 'space-between', gap: 12 },
});

function RankedPanel({ color, children }: { color: string; children: ReactNode }) {
  const theme = useCKTheme(),
    id = useId().replace(/:/g, '');
  return (
    <View style={[s.panel, { backgroundColor: theme.surface }]}>
      <View pointerEvents="none" style={StyleSheet.absoluteFill}>
        <Svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none">
          <Defs>
            <LinearGradient id={id} x1="0%" y1="0%" x2="100%" y2="100%">
              <Stop offset="0%" stopColor={color} stopOpacity={0.18} />
              <Stop offset="100%" stopColor={color} stopOpacity={0} />
            </LinearGradient>
          </Defs>
          <Rect width={100} height={100} fill={`url(#${id})`} />
        </Svg>
      </View>
      {children}
    </View>
  );
}

/** Flip only on an explicit button press; vertical scrolling stays untouched.
 * Swap faces edge-on and stop native animation on unmount. */
function FlipRankedPanel({
  title,
  icon,
  color,
  front,
  back,
  action,
}: {
  title: string | undefined;
  icon: ArtSource;
  color: string;
  front: ReactNode;
  back?: ReactNode;
  action?: ReactNode;
}) {
  const { t } = useI18n(),
    { reduceMotion } = useCKAccessibility();
  const [flipped, setFlipped] = useState(false);
  const target = useRef(false),
    alive = useRef(true),
    [rotation] = useState(() => new Animated.Value(0));
  useEffect(() => {
    alive.current = true;
    return () => {
      alive.current = false;
      rotation.stopAnimation();
    };
  }, [rotation]);
  const flip = () => {
    target.current = !target.current;
    rotation.stopAnimation();
    if (reduceMotion) {
      setFlipped(target.current);
      rotation.setValue(0);
      return;
    }
    Animated.timing(rotation, {
      toValue: 90,
      duration: 130,
      easing: Easing.in(Easing.quad),
      useNativeDriver: true,
    }).start(({ finished }) => {
      if (!finished || !alive.current) return;
      setFlipped(target.current);
      rotation.setValue(-90);
      Animated.timing(rotation, {
        toValue: 0,
        duration: 180,
        easing: Easing.out(Easing.cubic),
        useNativeDriver: true,
      }).start();
    });
  };
  return (
    <Animated.View
      style={{
        transform: [
          { perspective: 1200 },
          {
            rotateY: rotation.interpolate({
              inputRange: [-90, 90],
              outputRange: ['-90deg', '90deg'],
            }),
          },
        ],
      }}
    >
      <RankedPanel color={color}>
        {title || action || back ? (
          <View style={s.heading}>
            <RankedArtwork source={icon} size={28} />
            <CKText role="titleMedium" style={s.grow}>
              {title}
            </CKText>
            {action}
            {back ? (
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={flipped ? t('generalCancel') : t('tooltipShowChart')}
                accessibilityState={{ expanded: flipped }}
                onPress={flip}
                style={s.action}
              >
                <RotateCw size={20} color={color} />
              </Pressable>
            ) : null}
          </View>
        ) : null}
        {flipped ? back : front}
      </RankedPanel>
    </Animated.View>
  );
}

function RankedArtwork({
  source,
  size,
  style,
}: {
  source: ArtSource;
  size: number;
  style?: import('react-native').StyleProp<import('react-native').ViewStyle>;
}) {
  return (
    <View style={[{ width: size, height: size }, style]}>
      {typeof source === 'string' ? (
        <MobileWebImage
          imageUrl={source}
          contentFit="contain"
          style={{ width: size, height: size }}
        />
      ) : (
        <ExpoImage source={source} contentFit="contain" style={{ width: size, height: size }} />
      )}
    </View>
  );
}
