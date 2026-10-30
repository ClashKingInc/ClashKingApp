import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { ASSET_ORIGIN } from '../../../core/assets/asset-origin';
import { useEffect, useState } from 'react';
import { Platform, Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { ArrowDown, ArrowUp, ChevronRight, Globe2, Trophy } from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  CardStatsFooter,
  ErrorState,
  SkeletonContent,
  MobileWebImage,
  PillSurface,
  ResponsiveGrid,
  Surface,
  ckColors,
  useCKTheme,
} from '../../../ui';
import type { CwlRankingHistoryEntry } from '../models';
import type { ClanCurrentRankings } from '../data/clan-service';
import type { ClanInfoPresentationActions, ClanInfoPresentationModel } from './clan-info-contracts';
import { ClanTabEmpty } from './clan-tab-components';

type Ranking = {
  title: string;
  value: number;
  globalRank: number | null;
  localRank: number | null;
  art: string;
};
export function ClanRankingsTab({
  model,
  actions,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
}) {
  const { t } = useI18n();
  const { width } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const [data, setData] = useState<ClanCurrentRankings>();
  const [failed, setFailed] = useState(false);
  const [revision, setRevision] = useState(0);
  useEffect(() => {
    let active = true;
    void actions
      .loadCurrentRankings(model.clan.tag)
      .then((value) => {
        if (active) setData(value);
      })
      .catch(() => {
        if (active) setFailed(true);
      });
    return () => {
      active = false;
    };
  }, [actions, model.clan.tag, revision]);
  const category = (
    value: ClanCurrentRankings['homeVillage'] | undefined,
    title: string,
    art: string,
  ): Ranking[] => {
    if (!value) return [];
    const global = value.placements.find((item) => item.locationId === 'global' && item.rank > 0);
    const local = model.clan.location?.isCountry
      ? value.placements.find(
          (item) => item.locationId === String(model.clan.location!.id) && item.rank > 0,
        )
      : undefined;
    // A missing placement is not rank zero. Never derive ranks from the clan's
    // stat value or from this subset of leaderboard records.
    if (!global && !local) return [];
    return [
      {
        title,
        art,
        value: global?.points ?? local!.points,
        globalRank: global?.rank ?? null,
        localRank: local?.rank ?? null,
      },
    ];
  };
  const rankings = data
    ? [
        ...category(data.homeVillage, t('clanPointsTitle'), ImageAssets.trophies),
        ...category(data.builderBase, t('clanBuilderBasePoints'), ImageAssets.builderBaseTrophy),
        ...category(data.clanCapital, t('clanCapitalPoints'), ImageAssets.capitalTrophy),
        ...category(data.donations, t('gameDonations'), 'up'),
        ...category(data.donationsReceived, t('gameDonationsReceived'), 'down'),
        ...category(data.warWins, t('warWinsTitle'), ImageAssets.sword),
        ...category(data.warWinStreak, t('clanWinStreakTitle'), 'fire'),
        ...category(data.capitalGold, t('rankingsCapitalGold'), ImageAssets.capitalTrophy),
      ]
    : [];
  return (
    <View style={styles.tab}>
      {failed ? (
        <ErrorState
          title={t('generalFailed')}
          actionLabel={t('generalRetry')}
          onAction={() => {
            setFailed(false);
            setData(undefined);
            setRevision((value) => value + 1);
          }}
        />
      ) : !data ? (
        <SkeletonContent loading>
          <ResponsiveGrid
            minItemWidth={layout.isExpanded ? 400 : 340}
            minColumns={layout.isExpanded ? 2 : 1}
            maxColumns={
              layout.isExpanded
                ? layout.isTablet && layout.width > layout.height
                  ? 3
                  : 2
                : Platform.OS === 'web' && width >= 900
                  ? 3
                  : 1
            }
            gap={10}
          >
            {[ImageAssets.trophies, ImageAssets.builderBaseTrophy, ImageAssets.capitalTrophy].map(
              (art, index) => (
                <RankingCard
                  key={art}
                  item={{
                    title: [
                      t('clanPointsTitle'),
                      t('clanBuilderBasePoints'),
                      t('clanCapitalPoints'),
                    ][index]!,
                    art,
                    value: 10000,
                    globalRank: 100,
                    localRank: 100,
                  }}
                  countryCode={model.clan.location?.countryCode ?? null}
                />
              ),
            )}
          </ResponsiveGrid>
        </SkeletonContent>
      ) : !rankings.length ? (
        <ClanTabEmpty title={t('sideRankingsEmptyTitle')} />
      ) : (
        <ResponsiveGrid
          minItemWidth={layout.isExpanded ? 400 : 340}
          minColumns={layout.isExpanded ? 2 : 1}
          maxColumns={
            layout.isExpanded
              ? layout.isTablet && layout.width > layout.height
                ? 3
                : 2
              : Platform.OS === 'web' && width >= 900
                ? 3
                : 1
          }
          gap={10}
        >
          {rankings.map((item) => (
            <RankingCard
              key={item.title}
              item={item}
              countryCode={model.clan.location?.countryCode ?? null}
            />
          ))}
        </ResponsiveGrid>
      )}
    </View>
  );
}
function RankingCard({ item, countryCode }: { item: Ranking; countryCode: string | null }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  // Wider cards separate the metric from its placements. Keeping the compact
  // row below intact preserves the phone layout while long values stay whole.
  if (layout.isExpanded) {
    return (
      <Surface radius={22} style={styles.expandedRankingCard}>
        <View style={styles.expandedRankingHeading}>
          {item.art.startsWith('http') ? (
            <MobileWebImage imageUrl={item.art} style={styles.expandedRankingArt} />
          ) : item.art === 'up' ? (
            <ArrowUp color="#14A37F" size={28} />
          ) : item.art === 'down' ? (
            <ArrowDown color="#E35D4F" size={28} />
          ) : (
            <Trophy color={theme.primary} size={28} />
          )}
          <CKText role="rowTitle" style={styles.expandedRankingTitle}>
            {item.title}
          </CKText>
        </View>
        <CKText
          role="titleLarge"
          style={styles.expandedRankingValue}
          numberOfLines={1}
          adjustsFontSizeToFit
          minimumFontScale={0.7}
        >
          {item.value.toLocaleString(toIntlLocale(locale))}
        </CKText>
        <View style={styles.expandedRankingPlacements}>
          {item.globalRank !== null ? (
            <ExpandedRank
              label={t('statsWorld')}
              icon={<Globe2 size={20} color={theme.onSurfaceVariant} />}
              value={item.globalRank}
            />
          ) : null}
          {item.localRank !== null && countryCode ? (
            <ExpandedRank
              label={t('legendsCountryTitle')}
              icon={
                <MobileWebImage
                  imageUrl={ImageAssets.flag(countryCode)}
                  style={styles.expandedFlag}
                />
              }
              value={item.localRank}
            />
          ) : null}
        </View>
      </Surface>
    );
  }
  return (
    <Surface radius={18} style={styles.rankingCard}>
      {item.art.startsWith('http') ? (
        <MobileWebImage imageUrl={item.art} style={styles.rankingArt} />
      ) : item.art === 'up' ? (
        <ArrowUp color="#14A37F" />
      ) : item.art === 'down' ? (
        <ArrowDown color="#E35D4F" />
      ) : (
        <Trophy color={theme.primary} />
      )}
      <View style={styles.grow}>
        <CKText style={styles.bold}>{item.title}</CKText>
        <CKText muted role="labelLarge">
          {item.value.toLocaleString(toIntlLocale(locale))}
        </CKText>
      </View>
      {item.globalRank !== null ? (
        <Rank icon={<Globe2 size={17} color={theme.onSurfaceVariant} />} value={item.globalRank} />
      ) : null}
      {item.localRank !== null && countryCode ? (
        <Rank
          icon={<MobileWebImage imageUrl={ImageAssets.flag(countryCode)} style={styles.flag} />}
          value={item.localRank}
        />
      ) : null}
    </Surface>
  );
}
function ExpandedRank({
  icon,
  label,
  value,
}: {
  icon: React.ReactNode;
  label: string;
  value: number;
}) {
  const { locale } = useI18n();
  return (
    <View style={styles.expandedRank}>
      {icon}
      <View style={styles.expandedRankText}>
        <CKText muted role="metadata">
          {label}
        </CKText>
        <CKText role="rowTitle" style={styles.expandedRankValue}>
          #{value.toLocaleString(toIntlLocale(locale))}
        </CKText>
      </View>
    </View>
  );
}
function Rank({ icon, value }: { icon: React.ReactNode; value: number }) {
  const { locale } = useI18n();
  return (
    <View style={styles.rank}>
      {icon}
      <CKText role="labelLarge">#{value.toLocaleString(toIntlLocale(locale))}</CKText>
    </View>
  );
}

export function ClanCwlHistoryTab({
  model,
  actions,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
}) {
  const { t, locale } = useI18n();
  const { width } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const desktop = (Platform.OS === 'web' && width >= 900) || layout.isExpanded;
  const [entries, setEntries] = useState<readonly CwlRankingHistoryEntry[]>();
  const [error, setError] = useState(false);
  const load = async () => {
    setError(false);
    try {
      setEntries(await actions.loadCwlHistory(model.clan.tag));
    } catch {
      setError(true);
    }
  };
  useEffect(() => {
    let active = true;
    void actions
      .loadCwlHistory(model.clan.tag)
      .then((value) => {
        if (active) setEntries(value);
      })
      .catch(() => {
        if (active) setError(true);
      });
    return () => {
      active = false;
    };
  }, [actions, model.clan.tag]);
  if (!entries && !error)
    return (
      <SkeletonContent loading style={styles.tab}>
        {[0, 1, 2].map((index) => (
          <CwlCard
            key={index}
            entry={{
              season: '2026-01',
              league: model.clan.warLeague?.name ?? 'Champion League I',
              leagueId: model.clan.warLeague?.id ?? 0,
              rank: 1,
              stars: 100,
              destruction: 100,
              roundsWon: 1,
              roundsTied: 1,
              roundsLost: 1,
              hasStanding: true,
            }}
            movement={null}
            locale={locale}
            onPress={() => undefined}
          />
        ))}
      </SkeletonContent>
    );
  if (error)
    return (
      <ClanTabEmpty
        title={t('generalError')}
        body={t('generalTryAgain')}
        onRetry={() => void load()}
      />
    );
  if (!entries?.length)
    return <ClanTabEmpty title={t('cwlHistoryEmptyTitle')} body={t('cwlHistoryEmptyBody')} />;
  const cards = entries.map((entry, index) => (
    <CwlCard
      key={`${entry.season}:${index}`}
      entry={entry}
      movement={cwlMovement(entries, index, model.clan.warLeague?.id)}
      locale={locale}
      onPress={() => actions.openHistoricalCwl(model.clan, entry.season, entry.league ?? undefined)}
    />
  ));
  return (
    <View style={styles.tab}>
      {desktop ? (
        <ResponsiveGrid minItemWidth={layout.isExpanded ? 300 : 420} maxColumns={2} gap={10}>
          {cards}
        </ResponsiveGrid>
      ) : (
        <View style={styles.list}>{cards}</View>
      )}
    </View>
  );
}
export function cwlMovement(
  entries: readonly CwlRankingHistoryEntry[],
  index: number,
  current: number | undefined,
): 'up' | 'down' | null {
  const entry = entries[index]!;
  const month = entry.season.length >= 7 ? entry.season.slice(0, 7) : entry.season;
  let following = index === 0 ? current : undefined;
  if (index > 0) {
    for (let newerIndex = index - 1; newerIndex >= 0; newerIndex -= 1) {
      const candidate = entries[newerIndex]!;
      const candidateMonth =
        candidate.season.length >= 7 ? candidate.season.slice(0, 7) : candidate.season;
      if (candidateMonth !== month) {
        following = candidate.leagueId ?? undefined;
        break;
      }
    }
  }
  if (entry.leagueId == null || following == null || following === entry.leagueId) return null;
  return following > entry.leagueId ? 'up' : 'down';
}
export function CwlCard({
  entry,
  movement,
  locale,
  onPress,
}: {
  entry: CwlRankingHistoryEntry;
  movement: 'up' | 'down' | null;
  locale: string;
  onPress?: () => void;
}) {
  const theme = useCKTheme();
  const league = entry.league ?? 'Unranked';
  const date = new Date(`${entry.season.slice(0, 7)}-01T00:00:00`);
  const season = Number.isNaN(date.getTime())
    ? entry.season
    : new Intl.DateTimeFormat(toIntlLocale(locale), { month: 'long', year: 'numeric' }).format(
        date,
      );
  const number = new Intl.NumberFormat(toIntlLocale(locale));
  return (
    <Surface style={styles.cwlCard}>
      <Pressable
        testID={`clan-cwl-card-${entry.season}`}
        onPress={onPress}
        disabled={!onPress}
        accessibilityRole={onPress ? 'button' : undefined}
        accessibilityLabel={`${season}, ${league}, ${entry.hasStanding && entry.rank > 0 ? '#' + entry.rank : '—'}`}
        style={({ pressed }) => (pressed && onPress ? { opacity: 0.75 } : undefined)}
      >
        <View style={styles.cwlCardContent}>
          <MobileWebImage
            imageUrl={ImageAssets.getWarLeagueImage(league)}
            style={styles.cwlImage}
          />
          <View testID="clan-cwl-main" style={styles.cwlIdentity}>
            <CKText role="bodyMedium" style={styles.cwlSeasonLabel}>
              {season}
            </CKText>
            <CKText muted role="labelLarge" style={styles.cwlLeagueLabel}>
              {league}
            </CKText>
          </View>
          <View style={styles.cwlRank}>
            <View style={styles.movementSlot}>
              {movement ? (
                <MobileWebImage
                  accessibilityLabel={movement === 'up' ? 'Promoted' : 'Demoted'}
                  imageUrl={
                    movement === 'up'
                      ? `${ASSET_ORIGIN}/bot/icons/up_green_arrow.png`
                      : `${ASSET_ORIGIN}/bot/icons/down_red_arrow.png`
                  }
                  style={styles.movementIcon}
                />
              ) : null}
            </View>
            <CKText role="titleLarge" style={styles.cwlRankValue}>
              {entry.hasStanding && entry.rank > 0 ? `#${entry.rank}` : '—'}
            </CKText>
          </View>
          {onPress ? (
            <View style={styles.cwlNavigation}>
              <ChevronRight size={26} color={theme.onSurfaceVariant} />
            </View>
          ) : null}
        </View>
        {/* A shared full-width footer gives results room without a second card.
            Avoid a fixed height: long season/league labels must be able to wrap. */}
        <CardStatsFooter testID="clan-cwl-side">
          <View style={styles.cwlMetricRow}>
            <MobileWebImage imageUrl={ImageAssets.attackStar} style={styles.cwlMetricImage} />
            <CKText role="bodyMedium" style={styles.cwlResultText}>
              {entry.hasStanding ? number.format(entry.stars) : '—'}
            </CKText>
          </View>
          {entry.hasStanding ? (
            <PillSurface style={styles.record}>
              <CKText style={[styles.cwlResultText, { color: ckColors.donationGreen }]}>
                {entry.roundsWon}W
              </CKText>
              <CKText style={styles.cwlResultText}>{entry.roundsTied}T</CKText>
              <CKText style={[styles.cwlResultText, { color: ckColors.lossRed }]}>
                {entry.roundsLost}L
              </CKText>
            </PillSurface>
          ) : null}
          <CKText muted style={styles.cwlResultText}>
            {entry.hasStanding
              ? new Intl.NumberFormat(toIntlLocale(locale), {
                  style: 'percent',
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2,
                }).format(entry.destruction / 100)
              : '—'}
          </CKText>
        </CardStatsFooter>
      </Pressable>
    </Surface>
  );
}

export function cwlLeagueAccent(league: string): string {
  const normalized = league.toLowerCase();
  if (normalized.includes('legend')) return '#8C63FF';
  if (normalized.includes('champion')) return '#FF8A2B';
  if (normalized.includes('master')) return '#1B1D23';
  if (normalized.includes('crystal')) return '#8C63FF';
  if (normalized.includes('gold')) return '#FFC83D';
  if (normalized.includes('silver')) return '#C9D1DA';
  if (normalized.includes('bronze')) return '#C9793E';
  return '#8C63FF';
}

const styles = StyleSheet.create({
  tab: { padding: 16, gap: 12 },
  center: { minHeight: 180, alignItems: 'center', justifyContent: 'center' },
  list: { gap: 8 },
  bold: { fontWeight: '800' },
  grow: { flex: 1 },
  calendar: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  rankingCard: { minHeight: 62, padding: 10, flexDirection: 'row', alignItems: 'center', gap: 10 },
  rankingArt: { width: 28, height: 28, resizeMode: 'contain' },
  expandedRankingCard: { padding: 18, gap: 16, borderWidth: 0 },
  expandedRankingHeading: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  expandedRankingArt: { width: 32, height: 32, resizeMode: 'contain' },
  expandedRankingTitle: { flex: 1, minWidth: 0 },
  expandedRankingValue: { fontWeight: '800', fontVariant: ['tabular-nums'] },
  expandedRankingPlacements: { flexDirection: 'row', flexWrap: 'wrap', gap: 20 },
  expandedRank: { flexDirection: 'row', alignItems: 'center', gap: 8, minWidth: 112 },
  expandedRankText: { gap: 2 },
  expandedRankValue: { fontVariant: ['tabular-nums'] },
  expandedFlag: { width: 20, height: 20 },
  rank: { flexDirection: 'row', alignItems: 'center', gap: 4, marginLeft: 8 },
  flag: { width: 17, height: 17 },
  cwlCard: { borderWidth: 0, overflow: 'hidden' },
  cwlCardContent: {
    paddingLeft: 12,
    paddingRight: 6,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  cwlImage: { width: 48, height: 48, resizeMode: 'contain' },
  cwlIdentity: { flex: 1, minWidth: 0, gap: 4 },
  cwlRank: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  movementSlot: { width: 18, alignItems: 'center', justifyContent: 'center' },
  cwlRankValue: { lineHeight: 28, fontWeight: '800', fontVariant: ['tabular-nums'] },
  cwlNavigation: { width: 32, minHeight: 44, alignItems: 'center', justifyContent: 'center' },
  record: {
    flexDirection: 'row',
    gap: 7,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderWidth: 0,
  },
  cwlSeasonLabel: { fontSize: 14, lineHeight: 20, fontWeight: '700' },
  cwlLeagueLabel: { fontSize: 12, lineHeight: 17 },
  movementIcon: { width: 18, height: 18, resizeMode: 'contain' },
  cwlMetricRow: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  cwlMetricImage: { width: 18, height: 18, resizeMode: 'contain' },
  cwlResultText: {
    fontSize: 14,
    lineHeight: 20,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  },
});
