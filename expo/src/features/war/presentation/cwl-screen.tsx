import { memo, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import {
  ActivityIndicator,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import {
  ArrowLeft,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ChevronUp,
  Download,
  Search,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';
import { ImageAssets } from '../../../core/assets/image-assets';
import { useLinkParameters, linkChoice } from '../../../core/deep-links/link-parameters';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  MobileWebImage,
  ProfileTabs,
  SearchField,
  SelectionPicker,
  Surface,
  useCKTheme,
} from '../../../ui';
import { HeaderIconButton } from '../../../ui/header';
import { ckSpacing } from '../../../ui/tokens';
import { retainRecentSections } from '../../../ui/retained-sections';
import type { CwlClan, CwlMember, WarCwl, WarInfo } from '../models';
import {
  cwlOutlook,
  cwlStandings,
  remainingCwlOpponents,
  type CwlStanding,
} from '../models/cwl-outlook';
import type { WarPresentationActions } from './contracts';
import { formatPercent, sortCwlMembers } from './presentation-utils';
import { WarMatchup, WarTiming } from './war-components';
import { TownHallBreakdown, WarLineupComparison } from './town-hall-breakdown';

type CwlTab = 'rounds' | 'teams' | 'members';
export function CwlScreen({
  clanTag,
  summary,
  warLeagueName,
  actions,
  onBack,
  onOpenWar,
  loading = false,
  failed = false,
  refreshing = false,
  onRefresh,
}: {
  clanTag: string;
  summary: WarCwl;
  warLeagueName?: string | null;
  actions: WarPresentationActions;
  onBack: () => void;
  onOpenWar: (war: WarInfo, round: number) => void;
  loading?: boolean;
  failed?: boolean;
  refreshing?: boolean;
  onRefresh?: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const link = useLinkParameters();
  const [tab, setTab] = useState<CwlTab>(
    linkChoice(link.tab, ['rounds', 'teams', 'members'], 'rounds'),
  );
  const [retained, setRetained] = useState<readonly CwlTab[]>([tab]);
  const scroll = useRef<ScrollView>(null);
  const scrollY = useRef(0);
  const headerHeight = useRef(0);
  const tabStart = useRef(0);
  useEffect(() => {
    const frame = requestAnimationFrame(() =>
      scroll.current?.scrollTo({ y: tabStart.current, animated: false }),
    );
    return () => cancelAnimationFrame(frame);
  }, [tab]);
  const clan = summary.leagueInfo?.getClanDetails(clanTag);
  const standings = useMemo(() => cwlStandings(summary), [summary]);
  const select = (key: string) => {
    tabStart.current = Math.max(0, Math.min(scrollY.current, headerHeight.current));
    setTab(key as CwlTab);
    setRetained((old) => retainRecentSections(old, key as CwlTab, 3));
  };
  if (!clan)
    return (
      <SafeAreaView style={{ flex: 1, backgroundColor: theme.background }}>
        <EmptyState
          title={t('generalNoDataAvailable')}
          actionLabel={materialBackLabel(locale)}
          onAction={onBack}
        />
      </SafeAreaView>
    );
  return (
    <SafeAreaView
      edges={['top', 'left', 'right']}
      style={{ flex: 1, backgroundColor: theme.background }}
    >
      <ScrollView
        ref={scroll}
        stickyHeaderIndices={[1]}
        scrollEventThrottle={100}
        onScroll={(event) => {
          scrollY.current = event.nativeEvent.contentOffset.y;
        }}
        contentContainerStyle={{ paddingBottom: insets.bottom + ckSpacing.xl }}
        refreshControl={
          onRefresh ? (
            <RefreshControl
              refreshing={refreshing}
              onRefresh={onRefresh}
              tintColor={theme.onSurface}
            />
          ) : undefined
        }
      >
        <View
          onLayout={(event) => {
            headerHeight.current = event.nativeEvent.layout.height;
          }}
        >
          <CwlHero
            clan={clan}
            season={summary.leagueInfo?.season}
            league={warLeagueName}
            navigation={
              <View style={styles.actions}>
                <HeaderIconButton
                  icon={<ArrowLeft color="#fff" size={24} />}
                  label={materialBackLabel(locale)}
                  onPress={onBack}
                  glass={false}
                />
                <View style={styles.grow} />
                {actions.exportCwl ? (
                  <HeaderIconButton
                    icon={<Download color="#fff" size={24} />}
                    label={t('downloadTooltip')}
                    onPress={() => void actions.exportCwl!(clanTag)}
                    glass={false}
                  />
                ) : null}
              </View>
            }
          />
        </View>
        <View style={[styles.tabs, { backgroundColor: theme.background }]}>
          <ProfileTabs
            selectedKey={tab}
            onSelect={select}
            tabs={[
              { key: 'rounds', label: t('cwlMatches') },
              { key: 'teams', label: t('searchTabClans') },
              { key: 'members', label: t('warPlayersTitle') },
            ]}
          />
        </View>
        <View style={styles.content}>
          {loading ? (
            <View style={styles.loading}>
              <ActivityIndicator color={theme.onSurface} />
              <CKText>{t('loadingWarStats')}</CKText>
            </View>
          ) : failed ? (
            <EmptyState
              title={t('errorNetworkTitle')}
              actionLabel={t('generalRetry')}
              onAction={onRefresh}
            />
          ) : (
            (['rounds', 'teams', 'members'] as const)
              .filter((key) => retained.includes(key))
              .map((key) => (
                <View key={key} style={key === tab ? undefined : { display: 'none' }}>
                  {key === 'rounds' ? (
                    <CwlMatches summary={summary} clanTag={clanTag} onOpenWar={onOpenWar} />
                  ) : key === 'teams' ? (
                    <CwlClans
                      summary={summary}
                      clanTag={clanTag}
                      standings={standings}
                      actions={actions}
                    />
                  ) : (
                    <CwlPlayers
                      clans={summary.leagueInfo!.clans}
                      clanTag={clanTag}
                      actions={actions}
                    />
                  )}
                </View>
              ))
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}
function CwlHero({
  clan,
  season,
  league,
  navigation,
}: {
  clan: CwlClan;
  season?: string;
  league?: string | null;
  navigation: ReactNode;
}) {
  const { locale } = useI18n();
  const match = /^(\d{4})-(\d{2})/.exec(season ?? '');
  const date = match
    ? new Date(Number(match[1]), Number(match[2]) - 1, 1).toLocaleDateString(toIntlLocale(locale), {
        month: 'long',
        year: 'numeric',
      })
    : season;
  return (
    <View style={styles.hero}>
      <MobileWebImage
        imageUrl={ImageAssets.cwlPageBackground}
        style={StyleSheet.absoluteFill}
        contentFit="cover"
      />
      <Svg pointerEvents="none" style={StyleSheet.absoluteFill}>
        <Defs>
          <LinearGradient id="cwl-scrim" x1="0" y1="0" x2="0" y2="1">
            <Stop offset="0" stopColor="#000" stopOpacity={0.6} />
            <Stop offset="1" stopColor="#000" stopOpacity={0.92} />
          </LinearGradient>
        </Defs>
        <Rect width="100%" height="100%" fill="url(#cwl-scrim)" />
      </Svg>
      {navigation}
      <View style={styles.identity}>
        <MobileWebImage imageUrl={clan.badgeUrls.smallest} style={styles.heroBadge} />
        <CKText role="screenTitle" style={styles.heroText}>
          {clan.name}
        </CKText>
        <View style={styles.league}>
          {league ? (
            <MobileWebImage
              imageUrl={ImageAssets.getWarLeagueImage(league)}
              style={styles.leagueImage}
            />
          ) : null}
          <CKText role="body" style={styles.heroText}>
            {[league?.replace(' League', ''), date].filter(Boolean).join(' · ')}
          </CKText>
        </View>
      </View>
    </View>
  );
}
const CwlMatches = memo(function CwlMatches({
  summary,
  clanTag,
  onOpenWar,
}: {
  summary: WarCwl;
  clanTag: string;
  onOpenWar: (war: WarInfo, round: number) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const link = useLinkParameters();
  const rounds = summary.leagueInfo?.rounds ?? [];
  const active = summary.getActiveWarByTag(clanTag);
  const initial = Number(link.round) || summary.getRoundForWarTag(active?.tag ?? null).roundNumber;
  const [selected, setSelected] = useState(String(initial));
  const [lineup, setLineup] = useState(false);
  const index = Math.max(
    0,
    rounds.findIndex((round) => String(round.roundNumber) === selected),
  );
  const round = rounds[index];
  const wars =
    round?.warTags
      .map((tag) => summary.getWarInfoFromTag(tag))
      .filter((war) => war.clan && war.opponent) ?? [];
  const ours = wars
    .find((war) => war.clan?.tag === clanTag || war.opponent?.tag === clanTag)
    ?.reorderForClan(clanTag);
  const next = summary.warLeagueInfos
    .find(
      (war) =>
        war.state === 'preparation' &&
        war.tag !== active?.tag &&
        (war.clan?.tag === clanTag || war.opponent?.tag === clanTag),
    )
    ?.reorderForClan(clanTag);
  const select = (key: string) => {
    setSelected(key);
    setLineup(false);
  };
  const others = wars.filter((war) => war.tag !== ours?.tag);
  return (
    <View style={styles.stack}>
      <View style={styles.roundNavigation}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('upgradeTrackerPreviousPeriod')}
          accessibilityState={{ disabled: index === 0 }}
          disabled={index === 0}
          onPress={() => select(String(rounds[index - 1]!.roundNumber))}
          style={styles.arrow}
        >
          <ChevronLeft size={24} color={index === 0 ? theme.outlineVariant : theme.onSurface} />
        </Pressable>
        <View style={styles.grow}>
          <SelectionPicker
            title={t('cwlRounds')}
            selectedKey={String(round?.roundNumber ?? '')}
            onSelect={select}
            options={rounds.map((round) => ({
              key: String(round.roundNumber),
              label: t('cwlRoundNumber', { number: round.roundNumber }),
            }))}
          />
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('upgradeTrackerNextPeriod')}
          accessibilityState={{ disabled: index >= rounds.length - 1 }}
          disabled={index >= rounds.length - 1}
          onPress={() => select(String(rounds[index + 1]!.roundNumber))}
          style={styles.arrow}
        >
          <ChevronRight
            size={24}
            color={index >= rounds.length - 1 ? theme.outlineVariant : theme.onSurface}
          />
        </Pressable>
      </View>
      {ours ? (
        <Surface style={styles.section}>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={`${ours.clan?.name} · ${ours.opponent?.name}`}
            onPress={() => onOpenWar(ours, round!.roundNumber)}
          >
            <WarMatchup war={ours} />
            <View style={styles.detailLink}>
              <CKText>{t('generalDetails')}</CKText>
              <ChevronRight size={22} color={theme.onSurfaceVariant} />
            </View>
          </Pressable>
          <Disclosure
            label={t('statsTownHallDistribution')}
            expanded={lineup}
            onPress={() => setLineup((value) => !value)}
          />
          {lineup ? <WarLineupComparison war={ours} /> : null}
        </Surface>
      ) : (
        <EmptyState title={t('generalNoDataAvailable')} />
      )}
      {next && ours?.tag === active?.tag ? (
        <Surface style={styles.section}>
          <CKText role="sectionTitle">{t('cwlNextMatchup')}</CKText>
          <MatchRow
            war={next}
            onPress={() => onOpenWar(next, summary.getRoundForWarTag(next.tag).roundNumber)}
          />
          <WarLineupComparison war={next} />
        </Surface>
      ) : null}
      {others.length ? (
        <Surface style={styles.section}>
          <CKText role="sectionTitle">{t('cwlOtherMatches')}</CKText>
          {others.map((war) => (
            <MatchRow key={war.tag} war={war} onPress={() => onOpenWar(war, round!.roundNumber)} />
          ))}
        </Surface>
      ) : null}
    </View>
  );
});
function MatchRow({ war, onPress }: { war: WarInfo; onPress: () => void }) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`${war.clan?.name} · ${war.opponent?.name}`}
      onPress={onPress}
      style={[styles.matchRow, { borderTopColor: theme.outlineVariant }]}
    >
      <View style={styles.grow}>
        <View style={{ alignSelf: 'flex-start', marginBottom: 8 }}>
          <WarTiming war={war} />
        </View>
        {[war.clan, war.opponent].map((clan) =>
          clan ? (
            <View key={clan.tag} style={styles.matchLine}>
              <MobileWebImage imageUrl={clan.badgeUrls.smallest} style={styles.smallBadge} />
              <CKText role="body" numberOfLines={2} style={styles.grow}>
                {clan.name}
              </CKText>
              {war.state !== 'preparation' ? (
                <>
                  <CKText role="body" muted style={styles.percent}>
                    {formatPercent(clan.destructionPercentage)}
                  </CKText>
                  <CKText role="titleSmall" style={styles.score}>
                    {clan.stars}
                  </CKText>
                </>
              ) : null}
            </View>
          ) : null,
        )}
      </View>
      <ChevronRight size={22} color={theme.onSurfaceVariant} />
    </Pressable>
  );
}
const CwlClans = memo(function CwlClans({
  summary,
  clanTag,
  standings,
  actions,
}: {
  summary: WarCwl;
  clanTag: string;
  standings: CwlStanding[];
  actions: WarPresentationActions;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={styles.stack}>
      <SeasonOutlook summary={summary} clanTag={clanTag} standings={standings} />
      <CKText role="sectionTitle">{t('searchTabClans')}</CKText>
      <CKText muted>{t('cwlWinBonusNote')}</CKText>
      {standings.map((standing) => {
        const clan = summary.leagueInfo!.getClanDetails(standing.tag)!;
        return (
          <Surface
            key={clan.tag}
            style={[styles.section, clan.tag === clanTag && { borderColor: theme.primary }]}
          >
            <Pressable
              accessibilityRole="button"
              onPress={() => actions.openClan(clan.tag)}
              style={styles.clanHeading}
            >
              <CKText role="titleSmall">{standing.rank ? `#${standing.rank}` : '—'}</CKText>
              <MobileWebImage imageUrl={clan.badgeUrls.smallest} style={styles.clanBadge} />
              <CKText role="titleSmall" style={styles.grow}>
                {clan.name}
              </CKText>
              <CKText role="titleMedium">{standing.stars} ★</CKText>
            </Pressable>
            <View style={styles.inline}>
              <CKText muted>
                {t('generalTotal')} · {t('warDestructionTitle')}:{' '}
                {formatPercent(standing.destruction)}
              </CKText>
              <CKText muted>
                {t('warWinsTitle')}: {standing.wins}
              </CKText>
            </View>
            <CKText role="body" muted>
              {t('cwlRegisteredRoster')} · {clan.members.length}
            </CKText>
            <TownHallBreakdown members={clan.members} />
          </Surface>
        );
      })}
    </View>
  );
});
function SeasonOutlook({
  summary,
  clanTag,
  standings,
}: {
  summary: WarCwl;
  clanTag: string;
  standings: CwlStanding[];
}) {
  const { t } = useI18n();
  const [show, setShow] = useState(false);
  const [forecast, setForecast] = useState<{ summary: WarCwl; rows: CwlStanding[] }>();
  useEffect(() => {
    const timer = setTimeout(() => setForecast({ summary, rows: cwlOutlook(summary) }), 0);
    return () => clearTimeout(timer);
  }, [summary]);
  const projected =
    forecast?.summary === summary ? forecast.rows.find((row) => row.tag === clanTag) : null;
  const remaining = remainingCwlOpponents(summary, clanTag);
  return (
    <Surface style={styles.section}>
      <CKText role="sectionTitle">{t('cwlOutlook')}</CKText>
      {!projected ? (
        <ActivityIndicator />
      ) : projected.firstChance !== null ? (
        <>
          <StatRow
            label={t('cwlFirstPlace')}
            value={formatPercent(projected.firstChance * 100, 0)}
          />
          <StatRow label={t('cwlTopTwo')} value={formatPercent(projected.topTwoChance! * 100, 0)} />
        </>
      ) : (
        <CKText muted>{t('generalNoDataAvailable')}</CKText>
      )}
      <Disclosure
        expanded={show}
        label={t('generalDetails')}
        onPress={() => setShow((value) => !value)}
      />
      {show ? (
        <View style={styles.stack}>
          <CKText muted>{t('cwlEstimateNote')}</CKText>
          <CKText role="rowTitle">{t('cwlRemainingOpponents')}</CKText>
          {remaining.map((clan) => (
            <View key={clan.tag} style={styles.clanHeading}>
              <MobileWebImage imageUrl={clan.badgeUrls.smallest} style={styles.smallBadge} />
              <CKText style={styles.grow}>{clan.name}</CKText>
              <CKText>{standings.find((row) => row.tag === clan.tag)?.stars ?? 0} ★</CKText>
            </View>
          ))}
        </View>
      ) : null}
    </Surface>
  );
}
const CwlPlayers = memo(function CwlPlayers({
  clans,
  clanTag,
  actions,
}: {
  clans: readonly CwlClan[];
  clanTag: string;
  actions: WarPresentationActions;
}) {
  const { t } = useI18n();
  const [selected, setSelected] = useState(clanTag);
  const [retained, setRetained] = useState<readonly string[]>([clanTag]);
  return (
    <View style={styles.stack}>
      <SelectionPicker
        title={t('searchTabClans')}
        selectedKey={selected}
        onSelect={(tag) => {
          setSelected(tag);
          setRetained((old) => retainRecentSections(old, tag));
        }}
        options={clans.map((clan) => ({
          key: clan.tag,
          label: clan.name,
          icon: <MobileWebImage imageUrl={clan.badgeUrls.smallest} style={styles.smallBadge} />,
        }))}
      />
      {clans
        .filter((clan) => retained.includes(clan.tag))
        .map((clan) => (
          <View key={clan.tag} style={clan.tag === selected ? undefined : { display: 'none' }}>
            <StarLeaderboard members={clan.members} actions={actions} />
          </View>
        ))}
    </View>
  );
});
const StarLeaderboard = memo(function StarLeaderboard({
  members,
  actions,
}: {
  members: readonly CwlMember[];
  actions: WarPresentationActions;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [query, setQuery] = useState('');
  const [expanded, setExpanded] = useState<string>();
  const ranking = useMemo(() => sortCwlMembers(members, 'stars'), [members]);
  const ordered = useMemo(() => sortCwlMembers(ranking, 'stars', query), [ranking, query]);
  return (
    <View style={styles.stack}>
      <SearchField
        value={query}
        onChangeText={setQuery}
        placeholder={t('warStatsSearchPlaceholder')}
        searchIcon={<Search size={20} color={theme.onSurfaceVariant} />}
      />
      <Surface style={styles.section}>
        <View style={styles.inline}>
          <CKText role="sectionTitle">{t('warStarsTitle')}</CKText>
          <CKText muted>
            {t('warPlayersTitle')} · {members.length}
          </CKText>
        </View>
        {ordered.length ? (
          ordered.map((member) => (
            <View
              key={member.tag}
              style={[styles.playerRow, { borderTopColor: theme.outlineVariant }]}
            >
              <Pressable
                accessibilityRole="button"
                accessibilityState={{ expanded: expanded === member.tag }}
                accessibilityLabel={member.name}
                onPress={() => setExpanded((tag) => (tag === member.tag ? undefined : member.tag))}
                style={styles.clanHeading}
              >
                <CKText role="body" muted style={styles.rank}>
                  {ranking.indexOf(member) + 1}
                </CKText>
                <MobileWebImage
                  imageUrl={ImageAssets.townHall(member.townhallLevel)}
                  style={styles.clanBadge}
                />
                <View style={styles.grow}>
                  <CKText role="bodyLarge">{member.name}</CKText>
                  <CKText role="body" muted>
                    {member.attackStats?.attackCount ?? 0} {t('warAttacksTitle')}
                  </CKText>
                </View>
                <CKText role="titleMedium">{member.attackStats?.stars ?? 0} ★</CKText>
                {expanded === member.tag ? (
                  <ChevronUp color={theme.onSurfaceVariant} size={22} />
                ) : (
                  <ChevronDown color={theme.onSurfaceVariant} size={22} />
                )}
              </Pressable>
              {expanded === member.tag ? (
                <View style={styles.playerDetails}>
                  <PlayerStats member={member} />
                  <View style={styles.inline}>
                    <Pressable
                      accessibilityRole="button"
                      onPress={() => actions.openPlayer(member.tag)}
                      style={styles.arrow}
                    >
                      <CKText>{t('generalDetails')}</CKText>
                    </Pressable>
                    <Pressable
                      accessibilityRole="button"
                      onPress={() => setExpanded(undefined)}
                      style={styles.arrow}
                    >
                      <CKText>{t('generalCollapse')}</CKText>
                      <ChevronUp color={theme.onSurfaceVariant} size={20} />
                    </Pressable>
                  </View>
                </View>
              ) : null}
            </View>
          ))
        ) : (
          <EmptyState title={t('generalNoFilteredResults')} />
        )}
      </Surface>
    </View>
  );
});
function PlayerStats({ member }: { member: CwlMember }) {
  const { t } = useI18n();
  const attack = member.attackStats;
  const defense = member.defenseStats;
  return (
    <View style={styles.stack}>
      <CKText role="rowTitle">{t('warAttacksTitle')}</CKText>
      <StatRow label={t('warStarsAverage')} value={(attack?.averageStars ?? 0).toFixed(2)} />
      <StatRow
        label={t('warDestructionAverage')}
        value={formatPercent(attack?.averageDestruction ?? 0)}
      />
      <StatRow label={t('warAttacksMissed')} value={String(attack?.missedAttacks ?? 0)} />
      <View style={styles.starRow}>
        {[member.threeStars, member.twoStars, member.oneStar, member.zeroStar].map(
          (count, index) => (
            <View key={index} style={styles.starCell}>
              <CKText muted>{3 - index} ★</CKText>
              <CKText role="titleSmall">{count}</CKText>
            </View>
          ),
        )}
      </View>
      {defense?.defenseCount ? (
        <>
          <CKText role="rowTitle">{t('warDefensesTitle')}</CKText>
          <StatRow label={t('warStarsAverage')} value={defense.averageStars.toFixed(2)} />
          <StatRow
            label={t('warDestructionAverage')}
            value={formatPercent(defense.averageDestruction)}
          />
        </>
      ) : null}
    </View>
  );
}
function StatRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.inline}>
      <CKText muted style={styles.grow}>
        {label}
      </CKText>
      <CKText role="bodyLarge">{value}</CKText>
    </View>
  );
}
function Disclosure({
  label,
  expanded,
  onPress,
}: {
  label: string;
  expanded: boolean;
  onPress: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ expanded }}
      onPress={onPress}
      style={styles.disclosure}
    >
      <CKText style={styles.grow}>{expanded ? t('generalCollapse') : label}</CKText>
      {expanded ? (
        <ChevronUp color={theme.onSurfaceVariant} size={22} />
      ) : (
        <ChevronDown color={theme.onSurfaceVariant} size={22} />
      )}
    </Pressable>
  );
}
export function hasCwlMemberStats(member: CwlMember) {
  return (member.attackStats?.attackCount ?? 0) > 0 || (member.defenseStats?.defenseCount ?? 0) > 0;
}
export function hasCwlClanStats(clan: CwlClan) {
  return clan.members.some(hasCwlMemberStats);
}
const styles = StyleSheet.create({
  detailLink: {
    minHeight: 44,
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
    justifyContent: 'flex-end',
  },
  grow: { flex: 1, minWidth: 0 },
  stack: { gap: ckSpacing.lg },
  content: { padding: ckSpacing.lg, width: '100%', maxWidth: 1120, alignSelf: 'center' },
  tabs: { paddingHorizontal: ckSpacing.lg, paddingVertical: ckSpacing.sm },
  hero: { overflow: 'hidden' },
  heroText: { color: '#fff', textAlign: 'center' },
  actions: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: ckSpacing.sm },
  identity: {
    alignItems: 'center',
    paddingHorizontal: ckSpacing.lg,
    paddingBottom: ckSpacing.xl,
    gap: ckSpacing.sm,
  },
  heroBadge: { width: 94, height: 94 },
  league: {
    flexDirection: 'row',
    gap: ckSpacing.sm,
    alignItems: 'center',
    justifyContent: 'center',
    flexWrap: 'wrap',
  },
  leagueImage: { width: 32, height: 32 },
  loading: { padding: ckSpacing.xl, alignItems: 'center', gap: ckSpacing.lg },
  section: { padding: ckSpacing.lg, gap: ckSpacing.md },
  inline: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    flexWrap: 'wrap',
    gap: ckSpacing.sm,
  },
  roundNavigation: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm },
  arrow: {
    minWidth: 44,
    minHeight: 44,
    alignItems: 'center',
    justifyContent: 'center',
    flexDirection: 'row',
    gap: ckSpacing.sm,
  },
  matchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.sm,
    paddingVertical: ckSpacing.md,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  matchLine: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm, minHeight: 44 },
  smallBadge: { width: 28, height: 28 },
  clanBadge: { width: 40, height: 40 },
  percent: { width: 66, textAlign: 'right', fontVariant: ['tabular-nums'] },
  score: { width: 28, textAlign: 'right', fontVariant: ['tabular-nums'] },
  clanHeading: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm, minHeight: 52 },
  rank: { width: 24, textAlign: 'center' },
  playerRow: { paddingVertical: ckSpacing.md, borderTopWidth: StyleSheet.hairlineWidth },
  playerDetails: { paddingTop: ckSpacing.lg, gap: ckSpacing.lg },
  starRow: { flexDirection: 'row', paddingVertical: ckSpacing.sm },
  starCell: { flex: 1, alignItems: 'center', gap: ckSpacing.xs },
  disclosure: { minHeight: 44, flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm },
});
