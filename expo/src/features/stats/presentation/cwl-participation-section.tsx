import { useState, useSyncExternalStore } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChevronDown, ChevronUp } from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { localizedNameForItemOrFallback } from '../../../core/game-data/game-data-localization';
import { warLeaguesByApiId } from '../../../core/game-data/game-data-normalization';
import { gameDataState, subscribeToGameDataRevision } from '../../../core/game-data/game-data-state';
import { formatCompactNumber, toIntlLocale, useI18n } from '../../../i18n';
import { CKText, MobileWebImage, SelectionPicker, Surface, ckRadius, ckSpacing, colorWithAlpha, townHallDisplayColor, useCKTheme } from '../../../ui';
import type { StatsCwlBucket, StatsCwlResponse } from '../models';
import { AnalyticsLineChart } from './analytics-chart';

function seasonLabel(season: string, locale: string): string {
  const date = new Date(`${season}-01T00:00:00Z`);
  return Number.isNaN(date.getTime()) ? season : new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'long', year: 'numeric', timeZone: 'UTC',
  }).format(date);
}

/** Proportional seats illustrate registered rosters; they are not observed war lineups. */
export function estimatedRosterPlaces(values: readonly { level: number; count: number }[], size: number, registeredCount?: number) {
  const knownCount = values.reduce((sum, value) => sum + Math.max(0, value.count), 0);
  const entries = registeredCount != null && registeredCount > knownCount
    ? [...values, { level: 0, count: registeredCount - knownCount }]
    : values;
  const total = entries.reduce((sum, value) => sum + Math.max(0, value.count), 0);
  if (total === 0 || size <= 0) return [];
  const rows = entries.filter((value) => value.count > 0).map((value) => ({
    level: value.level, count: value.count, share: value.count / total,
    exact: value.count * size / total, places: Math.floor(value.count * size / total),
  }));
  let remainder = size - rows.reduce((sum, row) => sum + row.places, 0);
  for (const row of [...rows].sort((a, b) => (b.exact - b.places) - (a.exact - a.places) || b.count - a.count || b.level - a.level)) {
    if (remainder <= 0) break;
    row.places += 1;
    remainder -= 1;
  }
  return rows.sort((a, b) => b.level - a.level).map(({ exact: _exact, ...row }) => row);
}

export function CwlParticipationSection({ data, onSelectSeason }: {
  readonly data: StatsCwlResponse;
  readonly onSelectSeason?: (season: string) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  useSyncExternalStore(subscribeToGameDataRevision, () => gameDataState.revision, () => gameDataState.revision);
  const leagues = warLeaguesByApiId();
  const seasons = data.availableSeasons?.length ? data.availableSeasons : data.season ? [data.season] : [];
  const history = [...(data.history ?? [])].sort((a, b) => a.season.localeCompare(b.season));
  return <View style={styles.section} testID="cwl-participation">
    <View style={styles.totals} testID="cwl-overall-counts">
      <Count value={data.groupCount} label={t('statsCwlSeasonGroups')} />
      <Count value={data.clanCount} label={t('statsClans')} />
      <Count value={data.registeredPlayerCount} label={t('statsPlayers')} />
    </View>
    {seasons.length && data.season && onSelectSeason ? <SelectionPicker
      title={t('statsCwlSeasons')}
      accessibilityLabel={t('statsCwlSeasons')}
      options={seasons.map((season) => ({ key: season, label: seasonLabel(season, locale) }))}
      selectedKey={data.season}
      onSelect={onSelectSeason}
      fillWidth
    /> : data.season ? <CKText role="titleMedium">{seasonLabel(data.season, locale)}</CKText> : null}
    {history.length > 1 ? <AnalyticsLineChart
      title={t('statsCwlSeasonHistory')}
      series={[
        { key: 'groups', label: t('statsCwlSeasonGroups'), color: theme.primary, points: history.map((item) => ({ day: item.season, value: item.groupCount })) },
        { key: 'clans', label: t('statsClans'), color: theme.secondary, points: history.map((item) => ({ day: item.season, value: item.clanCount })) },
      ]}
      formatValue={(value) => formatCompactNumber(value, locale)}
      formatDay={(day) => seasonLabel(day, locale)}
      includeZero
    /> : null}
    {history.length > 1 ? <AnalyticsLineChart
      title={`${t('statsPlayers')} · ${t('statsCwlSeasonHistory')}`}
      series={[{ key: 'players', label: t('statsPlayers'), color: theme.secondary, points: history.map((item) => ({ day: item.season, value: item.registeredPlayerCount })) }]}
      formatValue={(value) => formatCompactNumber(value, locale)}
      formatDay={(day) => seasonLabel(day, locale)}
      includeZero
    /> : null}
    {data.items.map((item) => {
      const league = leagues.get(item.leagueId);
      const canonicalName = typeof league?.name === 'string' ? league.name : item.leagueId === 48000022 ? 'Legend League' : item.leagueId === 48000000 ? 'Unranked' : `${item.leagueId}`;
      const leagueName = league ? localizedNameForItemOrFallback(league, { languageCode: locale.split(/[-_]/, 1)[0] || 'en' }, canonicalName) : item.leagueId === 48000000 ? t('generalUnranked') : canonicalName;
      return <Bucket key={`${item.leagueId}:${item.warSize}`} item={item} leagueName={leagueName} leagueImage={ImageAssets.getWarLeagueImage(canonicalName)} />;
    })}
    {data.items.length === 0 ? <CKText muted role="bodyMedium">{t('statsNoDataBody')}</CKText> : null}
  </View>;
}

function Count({ value, label, precise = false }: { readonly value: number; readonly label: string; readonly precise?: boolean }) {
  const { locale } = useI18n();
  return <View style={styles.count}>
    <CKText role="titleSmall">{precise ? new Intl.NumberFormat(toIntlLocale(locale), { maximumFractionDigits: 1 }).format(value) : formatCompactNumber(value, locale)}</CKText>
    <CKText role="bodySmall" muted>{label}</CKText>
  </View>;
}

function Bucket({ item, leagueName, leagueImage }: {
  readonly item: StatsCwlBucket;
  readonly leagueName: string;
  readonly leagueImage: string;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState(false);
  const rows = estimatedRosterPlaces(item.townHallDistribution, item.warSize, item.registeredPlayerCount);
  const percentage = (value: number) => new Intl.NumberFormat(toIntlLocale(locale), { style: 'percent', maximumFractionDigits: 1 }).format(value);
  return <Surface radius={ckRadius.tile} style={styles.bucket} testID={`cwl-bucket-${item.leagueId}-${item.warSize}`}>
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ expanded }}
      accessibilityLabel={`${leagueName}, ${item.warSize}v${item.warSize}`}
      onPress={() => setExpanded((value) => !value)}
      style={({ pressed }) => [styles.heading, pressed && styles.pressed]}
      testID={`cwl-bucket-toggle-${item.leagueId}-${item.warSize}`}
    >
      <MobileWebImage imageUrl={leagueImage} style={styles.leagueImage} contentFit="contain" accessible={false} />
      <View style={styles.grow}>
        <CKText role="rowTitle">{leagueName}</CKText>
        <CKText role="metadata" muted>{`${item.warSize}v${item.warSize} · ${formatCompactNumber(item.groupCount, locale)} ${t('statsCwlSeasonGroups')}`}</CKText>
      </View>
      {expanded ? <ChevronUp size={20} color={theme.onSurfaceVariant} /> : <ChevronDown size={20} color={theme.onSurfaceVariant} />}
    </Pressable>
    <View style={styles.metrics}>
      <Count value={item.clanCount} label={t('statsClans')} />
      <Count value={item.registeredPlayerCount} label={t('statsPlayers')} />
    </View>
    {rows.length ? <View style={[styles.mixTrack, { backgroundColor: colorWithAlpha(theme.onSurface, 0.08) }]}>
      {rows.map((row) => <View key={row.level} testID={`cwl-th-mix-${item.leagueId}-${item.warSize}-${row.level}`} style={{ width: `${row.share * 100}%`, backgroundColor: townHallDisplayColor(row.level) }} />)}
    </View> : null}
    {rows.length ? <View style={styles.mixPeek}>
      {rows.slice(0, 3).map((row) => <CKText key={row.level} role="metadata" muted>
        {`${row.level ? `TH${row.level}` : t('generalUnknown')} ${percentage(row.share)}`}
      </CKText>)}
    </View> : null}
    {expanded ? <>
    <Count value={item.clanCount ? item.registeredPlayerCount / item.clanCount : 0} precise label={`${t('generalAverage')} · ${t('cwlRegisteredRoster')}`} />
    <CKText role="rowTitle">{t('statsTownHallDistribution')}</CKText>
    {rows.length ? <>
      <CKText role="metadata" muted>{t('statsCwlRosterNotLineup', { size: item.warSize })}</CKText>
      {rows.map((row) => <View key={row.level} style={styles.rosterRow}>
        <MobileWebImage imageUrl={row.level ? ImageAssets.townHall(row.level) : ImageAssets.defaultImage} style={styles.townHallImage} contentFit="contain" accessible={false} />
        <CKText role="bodySmall" style={styles.grow}>{row.level ? `TH${row.level}` : t('generalUnknown')}</CKText>
        <CKText role="bodySmall">{percentage(row.share)}</CKText>
        <CKText role="bodySmall" muted>{`≈${row.places}/${item.warSize}`}</CKText>
      </View>)}
    </> : <CKText role="bodySmall" muted>{t('generalNoDataAvailable')}</CKText>}
    {item.sameTownHallHitRates?.map((hit) => <View key={hit.level} style={styles.hitRow}>
      <CKText role="bodySmall">{`TH${hit.level}`}</CKText>
      <CKText role="bodySmall" muted>{`${t('statsThreeStarRate')} · ${hit.threeStarRate == null ? '—' : percentage(hit.threeStarRate)}`}</CKText>
    </View>)}
    <CKText role="metadata" muted>{`${t('statsWarsStored')} ${formatCompactNumber(item.archivedWars, locale)} / ${t('cwlWarsPlayedTitle')} ${formatCompactNumber(item.finalizedWars, locale)}`}</CKText>
    </> : null}
  </Surface>;
}

const styles = StyleSheet.create({
  section: { gap: ckSpacing.lg },
  totals: { flexDirection: 'row', justifyContent: 'space-around', gap: ckSpacing.sm },
  count: { gap: ckSpacing.xs, minWidth: 72, alignItems: 'center' },
  bucket: { padding: ckSpacing.lg, gap: ckSpacing.md },
  heading: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.md, minHeight: 48 },
  leagueImage: { width: 40, height: 40 },
  grow: { flex: 1 },
  metrics: { flexDirection: 'row', flexWrap: 'wrap', gap: ckSpacing.xl },
  mixTrack: { height: 12, flexDirection: 'row', overflow: 'hidden', borderRadius: ckRadius.pill },
  mixPeek: { flexDirection: 'row', flexWrap: 'wrap', gap: ckSpacing.md },
  rosterRow: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm, minHeight: 32 },
  townHallImage: { width: 28, height: 28 },
  hitRow: { flexDirection: 'row', justifyContent: 'space-between', gap: ckSpacing.sm },
  pressed: { opacity: 0.72 },
});
