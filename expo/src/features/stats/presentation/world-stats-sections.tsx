import { useState, useSyncExternalStore } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChevronDown, ChevronUp } from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { localizedNameForItemOrFallback } from '../../../core/game-data/game-data-localization';
import { warLeaguesByApiId } from '../../../core/game-data/game-data-normalization';
import {
  gameDataState,
  isRecord,
  subscribeToGameDataRevision,
} from '../../../core/game-data/game-data-state';
import { formatCompactNumber, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  MobileWebImage,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type {
  StatsClanCountsResponse,
  StatsGroupedCount,
  StatsPlayerCountsResponse,
} from '../models';
import { StatsChartFrame } from './stats-chart-frame';

const collapsedRowCount = 6;

export function PlayersSection({ data }: { readonly data: StatsPlayerCountsResponse }) {
  const { t, locale } = useI18n();
  const leagues = usePlayerLeagues(locale);
  const leagueCounts = new Map<number | null, number>();
  for (const item of data.leagueTiers) {
    // The old Legend League badge is a pre-ranked-league identity, not a current tier.
    const id = item.id === 29000022 ? 105000000 : item.id;
    leagueCounts.set(id, (leagueCounts.get(id) ?? 0) + item.count);
  }
  return (
    <View style={styles.section}>
      <DistributionGroup
        testID="town-halls"
        title={t('statsTownHallDistribution')}
        values={data.townHalls}
        overview="town-halls"
        describe={(id) => (id == null ? t('generalUnknown') : `TH${id}`)}
        artwork={(id) =>
          id != null && id > 0 ? ImageAssets.townHall(id) : ImageAssets.defaultImage
        }
      />
      <DistributionGroup
        testID="ranked-leagues"
        title={t('statsLeagueDistribution')}
        values={[...leagueCounts].map(([id, count]) => ({ id, count }))}
        overview="all"
        describe={(id) => playerLeague(id, leagues).label}
        artwork={(id) => playerLeague(id, leagues).imageUrl}
      />
    </View>
  );
}

export function ClansSection({ data }: { readonly data: StatsClanCountsResponse }) {
  const { t, locale } = useI18n();
  const cwlLeagues = useLocalizedCwlLeagues(locale);
  const locations = new Map(data.locationMetadata.map((location) => [location.id, location]));
  const memberBins = data.memberBins;
  return (
    <View style={styles.section}>
      <DistributionGroup
        testID="cwl-leagues"
        title={t('statsCwlLeagueDistribution')}
        values={data.cwlLeagues}
        overview="all"
        describe={(id) => cwlLeague(id, cwlLeagues, t).label}
        artwork={(id) => cwlLeague(id, cwlLeagues, t).imageUrl}
      />
      <DistributionGroup
        testID="capital-leagues"
        title={t('statsCapitalLeagueDistribution')}
        values={data.capitalLeagues}
        overview="all"
        describe={(id) => capitalLeague(id, locale, t).label}
        artwork={(id) => capitalLeague(id, locale, t).imageUrl}
      />
      {memberBins ? <DistributionGroup
        testID="clan-members"
        title={t('clanMembers')}
        values={memberBins.filter((bin) => bin.maxMembers > 0).map((bin) => ({ id: bin.minMembers, count: bin.count }))}
        overview="bins"
        describe={(id) => {
          const bin = memberBins.find((entry) => entry.minMembers === id);
          return bin ? bin.minMembers === bin.maxMembers ? `${bin.minMembers}` : `${bin.minMembers}–${bin.maxMembers}` : t('generalUnknown');
        }}
      /> : null}
      <DistributionGroup
        testID="locations"
        title={t('statsTrackedLocations')}
        values={data.locations.filter((item) => item.id != null)}
        describe={(id) => locations.get(id!)?.name ?? `${id}`}
        artwork={(id) => {
          const countryCode = id == null ? undefined : locations.get(id)?.countryCode;
          return countryCode ? ImageAssets.flag(countryCode) : ImageAssets.planet;
        }}
      />
    </View>
  );
}

function DistributionGroup({
  testID,
  title,
  values,
  describe,
  artwork,
  overview,
}: {
  readonly testID: string;
  readonly title: string;
  readonly values: readonly StatsGroupedCount[];
  readonly describe: (id: number | null) => string;
  readonly artwork?: (id: number | null) => string;
  readonly overview?: 'all' | 'town-halls' | 'bins';
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState(false);
  const ranked = [...values]
    .filter((item) => item.count > 0)
    .sort((left, right) => right.count - left.count || (right.id ?? -1) - (left.id ?? -1));
  const total = ranked.reduce((sum, item) => sum + item.count, 0);
  const barMaximum = ranked[0]?.count || 1;
  // Every Town Hall occupies the same position even when no tracked player has it.
  const maxTownHall = Math.max(
    0,
    finiteId(gameDataState.gameData.max_TownHall) ?? 0,
    ...ranked.map((item) => item.id ?? 0),
  );
  const sorted = overview === 'town-halls' && maxTownHall > 0
    ? Array.from({ length: maxTownHall }, (_, index) =>
        ranked.find((item) => item.id === index + 1) ?? { id: index + 1, count: 0 },
      )
    : overview === 'all'
      ? [...ranked].sort((left, right) => (right.id ?? -1) - (left.id ?? -1))
      : overview === 'bins'
        ? [...ranked].sort((left, right) => (left.id ?? -1) - (right.id ?? -1))
      : ranked;
  const showAll = overview != null || expanded;
  const visible = showAll ? sorted : sorted.slice(0, collapsedRowCount);
  const topShare =
    ranked.slice(0, collapsedRowCount).reduce((sum, item) => sum + item.count, 0) / (total || 1);
  return (
    <View style={styles.group} testID={`${testID}-distribution`}>
      <StatsChartFrame title={title} testID={testID}>
      <View style={styles.chart}>
      {sorted.length === 0 ? (
        <View style={styles.emptyRow}>
          <CKText role="bodySmall" muted>{t('generalNoDataAvailable')}</CKText>
        </View>
      ) : (
        <View style={styles.rows}>
          {visible.map((item) => {
            const label = describe(item.id);
            const share = total === 0 ? 0 : item.count / total;
            const shareLabel = formatShare(share, locale);
            return (
              <View
                key={`${item.id ?? 'unknown'}`}
                accessible
                accessibilityLabel={`${label}, ${formatCompactNumber(item.count, locale)}, ${shareLabel}`}
                style={styles.row}
                testID={`${testID}-row-${item.id ?? 'unknown'}`}
              >
                {artwork ? <MobileWebImage
                  imageUrl={artwork(item.id)}
                  contentFit="contain"
                  accessible={false}
                  style={styles.artwork}
                  testID={`${testID}-artwork-${item.id ?? 'unknown'}`}
                /> : null}
                <View style={styles.rowBody}>
                  <View style={styles.rowCopy}>
                    <CKText role="bodySmall" numberOfLines={1} style={styles.rowLabel}>
                      {label}
                    </CKText>
                    <CKText role="bodySmall" muted>
                      {formatCompactNumber(item.count, locale)} · {shareLabel}
                    </CKText>
                  </View>
                  <View
                      style={[
                        styles.track,
                        { backgroundColor: colorWithAlpha(theme.outlineVariant, 0.25) },
                      ]}
                    >
                      <View
                        style={[
                          styles.fill,
                          {
                            backgroundColor: theme.primary,
                            width: `${Math.max(item.count / barMaximum * 100, 0)}%`,
                            minWidth: share > 0 ? 1 : 0,
                          },
                        ]}
                      />
                  </View>
                </View>
              </View>
            );
          })}
        </View>
      )}
      {testID === 'locations' && !expanded && ranked.length > collapsedRowCount ? (
        <View style={styles.row} testID="locations-other-row">
          <MobileWebImage imageUrl={ImageAssets.planet} contentFit="contain" accessible={false} style={styles.artwork} />
          <View style={styles.rowBody}>
            <View style={styles.rowCopy}>
              <CKText role="rowTitle" style={styles.rowLabel}>{t('generalOthers')}</CKText>
              <CKText role="bodySmall" muted>
                {formatCompactNumber(total - ranked.slice(0, collapsedRowCount).reduce((sum, item) => sum + item.count, 0), locale)} · {formatShare(1 - topShare, locale)}
              </CKText>
            </View>
            <View style={[styles.track, { backgroundColor: colorWithAlpha(theme.outlineVariant, 0.25) }]}>
              <View style={[styles.fill, { backgroundColor: theme.secondary, width: `${Math.min(1, (total * (1 - topShare)) / barMaximum) * 100}%` }]} />
            </View>
          </View>
        </View>
      ) : null}
      {!overview && sorted.length > collapsedRowCount ? (
        <Pressable
          accessibilityRole="button"
          accessibilityState={{ expanded }}
          accessibilityLabel={expanded ? t('generalCollapse') : t('generalExpand')}
          onPress={() => setExpanded((value) => !value)}
          style={({ pressed }) => [styles.disclosure, pressed && styles.pressed]}
        >
          <CKText role="labelLarge" style={{ color: theme.primary }}>
            {expanded ? t('generalCollapse') : t('generalExpand')}
          </CKText>
          {expanded ? (
            <ChevronUp size={18} color={theme.primary} />
          ) : (
            <ChevronDown size={18} color={theme.primary} />
          )}
        </Pressable>
      ) : null}
      </View>
      </StatsChartFrame>
    </View>
  );
}

interface LeaguePresentation {
  readonly label: string;
  readonly canonicalName: string;
  readonly imageUrl: string;
}

function usePlayerLeagues(locale: string): ReadonlyMap<number, LeaguePresentation> {
  'use no memo';
  useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => gameDataState.revision,
  );
  const result = new Map<number, LeaguePresentation>([
    [105000000, { label: 'Unranked', canonicalName: 'Unranked', imageUrl: ImageAssets.getLeagueImage('Unranked') }],
    [
      105000036,
      { label: 'Legend League 1', canonicalName: 'Legend League 1', imageUrl: ImageAssets.legendLeagueOne },
    ],
    [
      105000035,
      { label: 'Legend League 2', canonicalName: 'Legend League 2', imageUrl: ImageAssets.legendLeagueTwo },
    ],
    [
      105000034,
      { label: 'Legend League 3', canonicalName: 'Legend League 3', imageUrl: ImageAssets.legendLeagueThree },
    ],
  ]);
  const leagues = gameDataState.playerLeagueData.leagues;
  if (!isRecord(leagues)) return result;
  for (const [fallback, raw] of Object.entries(leagues)) {
    if (!isRecord(raw)) continue;
    const id = finiteId(raw._id ?? raw.id);
    if (id == null) continue;
    const name = typeof raw.name === 'string' && raw.name.trim() ? raw.name.trim() : fallback;
    const localized = localizedNameForItemOrFallback(
      raw,
      { languageCode: locale.split(/[-_]/, 1)[0] || 'en' },
      name,
    );
    const label = id === 105000036 ? 'Legend League 1'
      : id === 105000035 ? 'Legend League 2'
      : id === 105000034 ? 'Legend League 3' : localized;
    result.set(id, { label, canonicalName: name, imageUrl: ImageAssets.getLeagueImage(name) });
  }
  return result;
}

function playerLeague(
  id: number | null,
  leagues: ReadonlyMap<number, LeaguePresentation>,
): LeaguePresentation {
  if (id == null) return { label: '—', canonicalName: '', imageUrl: ImageAssets.defaultImage };
  return (
    leagues.get(id) ?? {
      label: id >= 105000010 ? `L${id - 105000010}` : `${id}`,
      canonicalName: `${id}`,
      imageUrl: ImageAssets.trophies,
    }
  );
}

function useLocalizedCwlLeagues(locale: string): ReadonlyMap<number, LeaguePresentation> {
  'use no memo';
  const { t } = useI18n();
  useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => gameDataState.revision,
  );
  const result = new Map<number, LeaguePresentation>();
  for (let id = 48_000_001; id <= 48_000_022; id += 1) {
    result.set(id, defaultCwlLeague(id, t));
  }
  const languageCode = locale.split(/[-_]/, 1)[0] || 'en';
  for (const [id, item] of warLeaguesByApiId()) {
    const canonicalName =
      typeof item.name === 'string' ? item.name : defaultCwlLeague(id, t).canonicalName;
    result.set(id, {
      label: localizedNameForItemOrFallback(item, { languageCode }, canonicalName),
      canonicalName,
      imageUrl: ImageAssets.getWarLeagueImage(canonicalName),
    });
  }
  return result;
}

type Translate = ReturnType<typeof useI18n>['t'];

function cwlLeague(
  id: number | null,
  leagues: ReadonlyMap<number, LeaguePresentation>,
  t: Translate,
): LeaguePresentation {
  if (id == null) return unknownLeague(t);
  const known = leagues.get(id);
  if (known) return known;
  return defaultCwlLeague(id, t);
}

function defaultCwlLeague(id: number, t: Translate): LeaguePresentation {
  const offset = id - 48_000_000;
  if (offset === 0) {
    return { label: t('generalUnranked'), canonicalName: 'Unranked', imageUrl: ImageAssets.getWarLeagueImage('Unranked') };
  }
  if (offset === 22) {
    return { label: t('legendsTitle'), canonicalName: 'Legend League', imageUrl: ImageAssets.getWarLeagueImage('Legend League') };
  }
  if (offset >= 19 && offset <= 21) {
    const division = ['III', 'II', 'I'][offset - 19];
    const canonicalName = `Titan League ${division}`;
    return { label: `Titan ${division}`, canonicalName, imageUrl: ImageAssets.getWarLeagueImage(canonicalName) };
  }
  if (offset < 1 || offset > 18) {
    return { label: `${id}`, canonicalName: `${id}`, imageUrl: ImageAssets.defaultImage };
  }
  const division = ['III', 'II', 'I'][(offset - 1) % 3];
  const tier = Math.floor((offset - 1) / 3);
  const canonicalFamily = ['Bronze', 'Silver', 'Gold', 'Crystal', 'Master', 'Champion'][tier]!;
  const localizedFamily = leagueFamilyLabel(canonicalFamily, t);
  const canonicalName = `${canonicalFamily} League ${division}`;
  return {
    label: `${localizedFamily} ${division}`,
    canonicalName,
    imageUrl: ImageAssets.getWarLeagueImage(canonicalName),
  };
}

function capitalLeague(id: number | null, locale: string, t: Translate): LeaguePresentation {
  if (id == null) return unknownLeague(t);
  const offset = id - 85_000_000;
  if (offset === 0) {
    return {
      label: t('generalUnranked'),
      canonicalName: 'Unranked',
      imageUrl: ImageAssets.getCapitalLeagueImage('Unranked'),
    };
  }
  if (offset === 22) {
    return {
      label: t('legendsTitle'),
      canonicalName: 'Legend League',
      imageUrl: ImageAssets.getCapitalLeagueImage('Legend League'),
    };
  }
  if (offset < 1 || offset > 21) {
    return { label: `${id}`, canonicalName: `${id}`, imageUrl: ImageAssets.capitalTrophy };
  }
  const familyIndex = Math.floor((offset - 1) / 3);
  const division = ['III', 'II', 'I'][(offset - 1) % 3]!;
  const canonicalFamily = ['Bronze', 'Silver', 'Gold', 'Crystal', 'Master', 'Champion', 'Titan'][
    familyIndex
  ]!;
  const canonicalName = `${canonicalFamily} League ${division}`;
  const tidFamily = canonicalFamily === 'Titan' ? 'HERO' : canonicalFamily.toUpperCase();
  const tidDivision = 3 - ((offset - 1) % 3);
  const fallback = `${leagueFamilyLabel(canonicalFamily, t)} ${division}`;
  const label = localizedNameForItemOrFallback(
    { name: canonicalName, TID: { name: `TID_LEAGUE_${tidFamily}${tidDivision}` } },
    { languageCode: locale.split(/[-_]/, 1)[0] || 'en' },
    fallback,
  );
  return {
    label,
    canonicalName,
    imageUrl: ImageAssets.getCapitalLeagueImage(canonicalName),
  };
}

function leagueFamilyLabel(canonical: string, t: Translate): string {
  switch (canonical) {
    case 'Bronze':
      return t('statsLeagueBronze');
    case 'Silver':
      return t('statsLeagueSilver');
    case 'Gold':
      return t('statsLeagueGold');
    case 'Crystal':
      return t('statsLeagueCrystal');
    case 'Master':
      return t('statsLeagueMaster');
    case 'Champion':
      return t('statsLeagueChampion');
    default:
      return canonical;
  }
}

function unknownLeague(t: Translate): LeaguePresentation {
  return {
    label: t('generalUnknown'),
    canonicalName: '',
    imageUrl: ImageAssets.defaultImage,
  };
}

function finiteId(value: unknown): number | null {
  return typeof value === 'number' && Number.isFinite(value) ? Math.trunc(value) : null;
}

function formatShare(value: number, locale: string): string {
  return new Intl.NumberFormat(toIntlLocale(locale), {
    style: 'percent',
    maximumFractionDigits: 1,
  }).format(value);
}

const styles = StyleSheet.create({
  section: { gap: ckSpacing.xl },
  group: { gap: ckSpacing.sm },
  chart: { paddingHorizontal: ckSpacing.xs, paddingVertical: ckSpacing.sm, gap: ckSpacing.sm },
  rows: { gap: 7 },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.sm,
    minHeight: 36,
  },
  overview: { gap: ckSpacing.xs },
  overviewTrack: {
    height: 10,
    flexDirection: 'row',
    overflow: 'hidden',
    borderRadius: ckRadius.pill,
  },
  emptyRow: { minHeight: 44, justifyContent: 'center' },
  artwork: { width: 26, height: 26 },
  rowBody: { flex: 1, minWidth: 0, gap: 4 },
  rowCopy: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm },
  rowLabel: { flex: 1 },
  track: { height: 4, borderRadius: ckRadius.pill, overflow: 'hidden' },
  fill: { height: '100%', borderRadius: ckRadius.pill },
  disclosure: {
    minHeight: 44,
    alignSelf: 'center',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: ckSpacing.xs,
    paddingHorizontal: ckSpacing.lg,
  },
  pressed: { opacity: 0.72 },
});
