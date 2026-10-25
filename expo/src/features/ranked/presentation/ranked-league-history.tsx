import { useState } from 'react';
import { View } from 'react-native';
import Svg, { Circle, G, Line, Path, Text as SvgText } from 'react-native-svg';
import { gameDataState } from '../../../core/game-data/game-data-state';
import { rankedGroupCutoffs } from '../../player/models/player-ranked';
import {
  CKText,
  EmptyState,
  MobileWebImage,
  Surface,
  Skeleton,
  useSkeletonContent,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import { toIntlLocale, useI18n } from '../../../i18n';
import type { RankedPeriod } from '../data';

function tierMetadata(id: number | undefined) {
  return Object.values(gameDataState.playerLeagueData.leagues ?? {}).find(
    (value) =>
      value && typeof value === 'object' && Number((value as Record<string, unknown>)._id) === id,
  ) as Record<string, unknown> | undefined;
}

export function rankedCutoffs(period: RankedPeriod) {
  return rankedGroupCutoffs(period.tier?.id, period.group?.members.length ?? 0);
}

export function rankedTierColor(name: string) {
  // Accent samples from the actual ranked badges in assets/leagues/league-tier,
  // not the retired Bronze–Titan palette. Keep all numbered tiers in a family
  // consistent across graph strokes, selected labels and history records.
  const accents: Record<string, string> = {
    skeleton: '#C69760',
    barbarian: '#D8990A',
    archer: '#E3579E',
    wizard: '#318FBD',
    valkyrie: '#E86430',
    witch: '#806FE6',
    golem: '#B26CBD',
    pekka: '#8694C9',
    titan: '#5DB3C5',
    dragon: '#8F6FD9',
    electro: '#4D9EC9',
    legend: '#DD2C01',
  };
  const family = (name.trim().toLowerCase().split(/\s+/u)[0] ?? '').replace(/[^a-z]/gu, '');
  return accents[family] ?? '#8A929E';
}

export function RankedLeagueHistory({
  periods,
  locale,
}: {
  periods: readonly RankedPeriod[];
  locale: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const loading = useSkeletonContent();
  const [width, setWidth] = useState(0);
  const [selection, setSelection] = useState<number | null>(null);
  const points = [...periods]
    .filter((period) => period.tier)
    .sort((a, b) => a.seasonId - b.seasonId);
  const selected = points.find((point) => point.seasonId === selection) ?? points.at(-1);
  const order = (period: RankedPeriod) =>
    Number(tierMetadata(period.tier?.id)?.league_tier ?? period.tier!.id - 105000000);
  const levels = [...new Map(points.map((point) => [order(point), point])).values()].sort(
    (a, b) => order(a) - order(b),
  );
  const low = levels.length ? order(levels[0]!) : 0;
  const high = levels.length ? order(levels.at(-1)!) : 1;
  const left = 94,
    right = 18,
    top = 14,
    bottom = 28,
    height = 205;
  const x = (point: RankedPeriod) =>
    left +
    (points.length === 1
      ? 0.5
      : (point.seasonId - points[0]!.seasonId) /
        Math.max(1, points.at(-1)!.seasonId - points[0]!.seasonId)) *
      Math.max(1, width - left - right);
  const y = (point: RankedPeriod) =>
    top + (high === low ? 0.5 : (high - order(point)) / (high - low)) * (height - top - bottom);
  const date = (point: RankedPeriod) =>
    new Intl.DateTimeFormat(toIntlLocale(locale), {
      month: 'short',
      day: 'numeric',
      timeZone: 'UTC',
    }).format(point.startsAt);
  return (
    <Surface testID="ranked-league-history-chart" style={{ padding: 16, gap: 12, borderWidth: 0 }}>
      <CKText skeleton={false} role="titleSmall">
        {t('rankedLeagueOverTime')}
      </CKText>
      {selected || loading ? (
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
          <MobileWebImage
            imageUrl={selected?.tier?.iconUrl ?? ''}
            style={{ width: 34, height: 34 }}
          />
          <View>
            <CKText role="rowTitle" style={{ color: rankedTierColor(selected?.tier?.name ?? '') }}>
              {selected?.tier?.name ?? 'League name'}
            </CKText>
            <CKText muted role="metadata">
              {selected ? date(selected) : '1 Jan'}
            </CKText>
          </View>
        </View>
      ) : (
        <EmptyState title={t('generalNoDataAvailable')} />
      )}
      <View onLayout={(event) => setWidth(event.nativeEvent.layout.width)} style={{ height }}>
        {loading ? (
          <Skeleton height={height} />
        ) : width > 0 && points.length > 0 ? (
          <Svg width={width} height={height}>
            {levels
              .filter(
                (_, index) =>
                  index % Math.max(1, Math.ceil(levels.length / 5)) === 0 ||
                  index === levels.length - 1,
              )
              .map((point) => (
                <G key={point.tier!.id}>
                  <Line
                    x1={left}
                    x2={width - right}
                    y1={y(point)}
                    y2={y(point)}
                    stroke={colorWithAlpha(rankedTierColor(point.tier!.name), 0.16)}
                  />
                  <SvgText
                    x={left - 8}
                    y={y(point) + 3}
                    fontSize={9}
                    fill={theme.onSurfaceVariant}
                    textAnchor="end"
                  >
                    {point.tier!.name}
                  </SvgText>
                </G>
              ))}
            {points.slice(1).map((point, index) => {
              const previous = points[index]!;
              // League membership is discrete; do not imply intermediate tiers.
              // Missing seasons stay disconnected instead of inventing a history.
              if (point.seasonId - previous.seasonId > 8 * 86400) return null;
              return (
                <Path
                  key={point.seasonId}
                  d={`M ${x(previous)} ${y(previous)} H ${x(point)} V ${y(point)}`}
                  fill="none"
                  stroke={rankedTierColor(point.tier!.name)}
                  strokeWidth={2.5}
                  strokeDasharray={point.isCurrent ? '4 3' : undefined}
                />
              );
            })}
            {points.map((point, index) => (
              <G key={point.seasonId}>
                <Circle
                  cx={x(point)}
                  cy={y(point)}
                  r={selection === point.seasonId ? 5 : 3.5}
                  fill={rankedTierColor(point.tier!.name)}
                />
                <Circle
                  cx={x(point)}
                  cy={y(point)}
                  r={13}
                  fill="transparent"
                  onPress={() => setSelection(point.seasonId)}
                  accessibilityLabel={`${date(point)}, ${point.tier!.name}`}
                />
                {index % Math.max(1, Math.ceil(points.length / 4)) === 0 ||
                index === points.length - 1 ? (
                  <SvgText
                    x={x(point)}
                    y={height - 7}
                    fill={theme.onSurfaceVariant}
                    fontSize={9}
                    textAnchor="middle"
                  >
                    {date(point)}
                  </SvgText>
                ) : null}
              </G>
            ))}
          </Svg>
        ) : null}
      </View>
    </Surface>
  );
}
