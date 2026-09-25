import { StyleSheet, View } from 'react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  HorizontalImageShareModal,
  MobileWebImage,
  colorWithAlpha,
  horizontalImageFilename,
} from '../../../ui';
import type { PlayerLegendLeagueData } from '../../player/models';
import { popularLegendItems } from './legend-army';
import { LegendChart } from './legend-chart';

export interface LegendsShareSummary {
  readonly currentRank: number | null;
  readonly historicalRank: number | null;
  readonly favoriteArmy: string | null;
  readonly favoriteArmyUses: number;
  readonly battleChanges: readonly { readonly key: string; readonly change: number }[];
  readonly dailyContributions: readonly {
    readonly key: string;
    readonly change: number;
    readonly attackTrophies: number;
  }[];
  readonly graph: readonly { readonly label: string; readonly trophies: number }[];
}

export function legendsShareSummary(data: PlayerLegendLeagueData): LegendsShareSummary {
  const armyUses = new Map<string, number>();
  for (const shareCode of data.seasonArmyShareCodes) {
    armyUses.set(shareCode, (armyUses.get(shareCode) ?? 0) + 1);
  }
  const favorite = [...armyUses.entries()].sort(
    ([left, leftUses], [right, rightUses]) => rightUses - leftUses || left.localeCompare(right),
  )[0];
  const dailyContributions = [...data.recentDays]
    .sort((left, right) => left.day.localeCompare(right.day))
    .map((day) => ({
      key: day.day,
      change: day.trophyChange,
      attackTrophies: day.attackTrophies,
    }));
  const dailyChanges = dailyContributions.map(({ key, change }) => ({ key, change }));
  return {
    currentRank: data.currentRank?.globalRank ?? null,
    historicalRank: data.historicalRank?.globalRank ?? null,
    favoriteArmy: favorite?.[0] ?? null,
    favoriteArmyUses: favorite?.[1] ?? 0,
    battleChanges: dailyChanges,
    dailyContributions,
    graph: data.recentDays.flatMap((day) =>
      day.closingTrophies == null
        ? []
        : [{ label: day.day.slice(5), trophies: day.closingTrophies }],
    ),
  };
}

export function legendSeasonLabel(
  start: string | null,
  end: string | null,
  fallback = 'Current season',
  locale = 'en',
): string {
  if (!start || !end) return fallback;
  const formatter = new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'short',
    day: 'numeric',
    timeZone: 'UTC',
  });
  const startDate = new Date(start);
  const endDate = new Date(end);
  if (!Number.isFinite(startDate.getTime()) || !Number.isFinite(endDate.getTime())) return fallback;
  return `${formatter.format(startDate)} – ${formatter.format(endDate)}`;
}

export function LegendsShareModal({
  data,
  visible,
  onClose,
}: {
  readonly data: PlayerLegendLeagueData;
  readonly visible: boolean;
  readonly onClose: () => void;
}) {
  const { t, locale } = useI18n();
  const summary = legendsShareSummary(data);
  const favoriteItems = popularLegendItems(data.seasonArmyShareCodes);
  const location = data.currentRank?.location ?? null;
  const locationFlag = location?.countryCode ? ImageAssets.flag(location.countryCode) : null;
  const seasonNet = data.recentDays.reduce((total, day) => total + day.trophyChange, 0);
  const seasonStats = data.seasonStats;
  return (
    <HorizontalImageShareModal
      artworkUrls={[
        ImageAssets.legendLeagueOne,
        ...(locationFlag ? [locationFlag] : []),
        ...favoriteItems.map(({ item }) => item.imageUrl),
      ]}
      canvasSize={{ width: 1200, height: 675 }}
      fileName={legendsImageFileName(data.playerName)}
      message={`${data.playerName} in Legend League on ClashKing`}
      onClose={onClose}
      title={t('generalExport')}
      visible={visible}
    >
      <View style={styles.graphic}>
        <View style={styles.heading}>
          <View style={styles.identity}>
            <MobileWebImage imageUrl={ImageAssets.legendLeagueOne} style={styles.logo} />
            <View style={styles.identityCopy}>
              <CKText style={styles.playerName} numberOfLines={1}>
                {data.playerName}
              </CKText>
              <CKText style={styles.playerMeta} numberOfLines={1}>
                {data.playerTag} · {t('legendsTitle')}
              </CKText>
            </View>
          </View>
          {location ? (
            <View style={styles.location}>
              {locationFlag ? <MobileWebImage imageUrl={locationFlag} style={styles.flag} /> : null}
              <CKText style={styles.locationName} numberOfLines={1}>
                {location.name}
              </CKText>
            </View>
          ) : null}
        </View>
        <View style={styles.metrics}>
          <Metric
            label={t('rankedLeagueTrophies')}
            value={(data.currentRank?.trophies ?? data.trophies).toLocaleString()}
          />
          <Metric
            label={t('legendsGlobalRankTitle')}
            value={summary.currentRank ? `#${summary.currentRank.toLocaleString()}` : '—'}
          />
          <Metric
            label={`${t('filtersSeason')} · ${t('rankedLeagueAttacks')}`}
            value={seasonStats ? seasonStats.attacks.toLocaleString() : '—'}
          />
          <Metric
            label={t('legendsInaccurateNetGainTitle')
              .replace(/^\d+\.\s*/u, '')
              .replace(/:$/u, '')}
            value={`${seasonNet >= 0 ? '+' : ''}${seasonNet.toLocaleString()}`}
          />
        </View>
        <View style={styles.lower}>
          <View style={[styles.panel, styles.overviewPanel]}>
            <View style={styles.panelHeading}>
              <CKText style={styles.panelTitle}>{t('statsSeasonStats')}</CKText>
              <CKText style={styles.panelMeta}>
                {legendSeasonLabel(data.seasonStart, data.seasonEnd, t('filtersSeason'), locale)}
              </CKText>
            </View>
            <View style={styles.statGrid}>
              <SeasonStat label={t('rankedLeagueAttacks')} value={seasonStats?.attacks ?? null} />
              <SeasonStat
                label={`3★ ${t('rankedLeagueAttacks')}`}
                value={seasonStats?.attackTriples ?? null}
              />
              <SeasonStat
                label={t('legendsAvgOffense')}
                value={seasonStats?.averageOffense ?? null}
                signed
              />
              <SeasonStat label={t('rankedLeagueDefenses')} value={seasonStats?.defenses ?? null} />
              <SeasonStat
                label={`3★ ${t('rankedLeagueDefenses')}`}
                value={seasonStats?.defenseTriples ?? null}
              />
              <SeasonStat
                label={t('legendsAvgDefense')}
                value={seasonStats?.averageDefense ?? null}
                signed
              />
            </View>
            <CKText style={styles.subheading}>
              {t('filtersSeason')} · {t('legendsYourArmy')}
            </CKText>
            {favoriteItems.length ? (
              <View style={styles.armyRow}>
                {favoriteItems.map(({ category, item }) => (
                  <MobileWebImage
                    key={item.code}
                    accessibilityLabel={`${favoriteItemCategoryLabel(category, t)}: ${item.name}`}
                    imageUrl={item.imageUrl}
                    style={styles.armyImage}
                  />
                ))}
              </View>
            ) : (
              <CKText style={styles.emptyText}>{t('generalNoDataAvailable')}</CKText>
            )}
          </View>
          <View style={[styles.panel, styles.chartsPanel]}>
            <LegendChart
              dark
              large
              height={118}
              title={t('rankedLeagueTrophies')}
              points={data.recentDays.map((day) => ({
                day: day.day,
                value: day.closingTrophies ?? null,
              }))}
            />
            <View style={styles.chartDivider} />
            <LegendChart
              dark
              large
              rank
              height={118}
              title={t('legendsGlobalRankTitle')}
              points={data.recentDays.map((day) => ({
                day: day.day,
                value: day.globalRank ?? null,
              }))}
            />
          </View>
        </View>
      </View>
    </HorizontalImageShareModal>
  );
}

export function legendsImageFileName(playerName: string, now = new Date()) {
  return horizontalImageFilename('legends', playerName, '', now);
}

function Metric({ label, value }: { readonly label: string; readonly value: string }) {
  return (
    <View style={styles.metric}>
      <CKText style={styles.metricValue} numberOfLines={1}>
        {value}
      </CKText>
      <CKText style={styles.metricLabel} numberOfLines={1}>
        {label}
      </CKText>
    </View>
  );
}

function favoriteItemCategoryLabel(category: string, t: ReturnType<typeof useI18n>['t']): string {
  if (category === 'Troop') return t('statsTroop');
  if (category === 'Spell') return t('statsSpell');
  return t('gameSiegeMachines');
}

function SeasonStat({
  label,
  value,
  signed = false,
}: {
  readonly label: string;
  readonly value: number | null;
  readonly signed?: boolean;
}) {
  const display =
    value == null
      ? '—'
      : `${signed && value > 0 ? '+' : ''}${value.toLocaleString(undefined, { maximumFractionDigits: 1 })}`;
  return (
    <View style={styles.seasonStat}>
      <CKText style={styles.seasonStatValue}>{display}</CKText>
      <CKText style={styles.seasonStatLabel} numberOfLines={1}>
        {label}
      </CKText>
    </View>
  );
}

const styles = StyleSheet.create({
  graphic: {
    flex: 1,
    padding: 40,
    gap: 18,
    backgroundColor: '#0C0C12',
    borderTopWidth: 8,
    borderTopColor: '#B58AF2',
  },
  heading: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  identity: { flex: 1, flexDirection: 'row', alignItems: 'center', gap: 18 },
  identityCopy: { flex: 1, gap: 3 },
  playerName: { color: '#FFFFFF', fontSize: 40, lineHeight: 44, fontWeight: '800' },
  playerMeta: { color: '#C8CBD8', fontSize: 20, lineHeight: 25 },
  logo: { width: 84, height: 84 },
  location: {
    maxWidth: 310,
    minHeight: 52,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 18,
    borderRadius: 26,
    backgroundColor: '#20202B',
  },
  flag: { width: 36, height: 25, borderRadius: 5 },
  locationName: { color: '#FFFFFF', fontSize: 20, lineHeight: 24 },
  metrics: { flexDirection: 'row', gap: 14 },
  metric: {
    flex: 1,
    minHeight: 88,
    justifyContent: 'center',
    paddingHorizontal: 20,
    borderRadius: 20,
    backgroundColor: '#181820',
  },
  metricValue: { color: '#FFFFFF', fontSize: 31, lineHeight: 35, fontWeight: '800' },
  metricLabel: { color: '#B8BAC7', fontSize: 17, lineHeight: 22 },
  lower: { flex: 1, flexDirection: 'row', gap: 18 },
  panel: { padding: 22, borderRadius: 24, backgroundColor: '#181820' },
  overviewPanel: { width: 410, gap: 14 },
  chartsPanel: { flex: 1, justifyContent: 'space-between', gap: 8 },
  panelHeading: { gap: 2 },
  panelTitle: { color: '#FFFFFF', fontSize: 25, lineHeight: 29, fontWeight: '700' },
  panelMeta: { color: '#B8BAC7', fontSize: 17, lineHeight: 21 },
  statGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  seasonStat: {
    width: 116,
    minHeight: 58,
    justifyContent: 'center',
    paddingHorizontal: 11,
    borderRadius: 14,
    backgroundColor: '#23232E',
  },
  seasonStatValue: { color: '#FFFFFF', fontSize: 22, lineHeight: 25, fontWeight: '700' },
  seasonStatLabel: { color: '#B8BAC7', fontSize: 14, lineHeight: 18 },
  subheading: { color: '#FFFFFF', fontSize: 20, lineHeight: 24, fontWeight: '700' },
  armyRow: { flexDirection: 'row', alignItems: 'center', gap: 16 },
  armyImage: { width: 64, height: 64, borderRadius: 14 },
  emptyText: { color: '#B8BAC7', fontSize: 17, lineHeight: 22 },
  chartDivider: { height: 1, backgroundColor: colorWithAlpha('#C8CBD8', 0.16) },
});
