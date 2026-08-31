import { useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import {
  ArrowLeft,
  BarChart3,
  CalendarDays,
  ChevronDown,
  ChevronRight,
  Download,
  Search,
  Users,
} from 'lucide-react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  GlassSurface,
  MobileWebImage,
  ProfileTabs,
  SearchSortBar,
  Surface,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { CwlClan, CwlMember, WarCwl, WarInfo } from '../models';
import type { WarPresentationActions } from './contracts';
import {
  cwlRoundTiming,
  formatPercent,
  orderCwlRounds,
  sortCwlClans,
  sortCwlMembers,
  type CwlMemberSort,
} from './presentation-utils';
import { MetricPill, SelectionModal } from './war-components';

type CwlTab = 'rounds' | 'teams' | 'members';

export function CwlScreen({
  clanTag,
  summary,
  warLeagueName,
  actions,
  onBack,
  onOpenWar,
}: {
  clanTag: string;
  summary: WarCwl;
  warLeagueName?: string | null;
  actions: WarPresentationActions;
  onBack: () => void;
  onOpenWar: (war: WarInfo, roundNumber: number) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const [tab, setTab] = useState<CwlTab>('rounds');
  const clan = summary.leagueInfo?.getClanDetails(clanTag) ?? null;
  if (!clan || !summary.leagueInfo) {
    return (
      <SafeAreaView style={[styles.safe, { backgroundColor: theme.background }]}>
        <EmptyState
          title={t('generalNoDataAvailable')}
          actionLabel={materialBackLabel(locale)}
          onAction={onBack}
        />
      </SafeAreaView>
    );
  }
  const tabs = [
    {
      key: 'rounds',
      label: t('cwlRounds'),
      icon: (
        <CalendarDays size={18} color={tab === 'rounds' ? theme.primary : theme.onSurfaceVariant} />
      ),
    },
    {
      key: 'teams',
      label: t('navigationTeam'),
      icon: (
        <BarChart3 size={18} color={tab === 'teams' ? theme.primary : theme.onSurfaceVariant} />
      ),
    },
    {
      key: 'members',
      label: t('clanMembers'),
      icon: <Users size={18} color={tab === 'members' ? theme.primary : theme.onSurfaceVariant} />,
    },
  ];
  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.safe, { backgroundColor: theme.background }]}
    >
      <ScrollView contentContainerStyle={{ paddingBottom: insets.bottom + 18 }}>
        <CwlHero
          clan={clan}
          summary={summary}
          warLeagueName={warLeagueName}
          onBack={onBack}
          onExport={actions.exportCwl ? () => void actions.exportCwl!(clanTag) : undefined}
        />
        <View style={styles.tabs}>
          <ProfileTabs tabs={tabs} selectedKey={tab} onSelect={(key) => setTab(key as CwlTab)} />
        </View>
        <View style={styles.content}>
          {tab === 'rounds' ? (
            <CwlRounds summary={summary} clanTag={clanTag} onOpenWar={onOpenWar} />
          ) : null}
          {tab === 'teams' ? (
            <CwlTeams clans={summary.leagueInfo.clans} clanTag={clanTag} actions={actions} />
          ) : null}
          {tab === 'members' ? <CwlMembers members={clan.members} actions={actions} /> : null}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

function CwlHero({
  clan,
  summary,
  warLeagueName,
  onBack,
  onExport,
}: {
  clan: CwlClan;
  summary: WarCwl;
  warLeagueName?: string | null;
  onBack: () => void;
  onExport?: () => void;
}) {
  const { t, locale } = useI18n();
  const { width } = useWindowDimensions();
  const leagueName = warLeagueName?.trim() || 'Unranked';
  const currentRound = summary.leagueInfo?.getCurrentRounds()?.roundNumber ?? clan.warsPlayed;
  const totalPossible = summary.teamSize > 0 ? summary.teamSize * clan.warsPlayed : null;
  const totalRounds = summary.leagueInfo?.rounds.length ?? 0;
  return (
    <View style={styles.hero}>
      <MobileWebImage
        imageUrl={ImageAssets.cwlPageBackground}
        style={StyleSheet.absoluteFill}
        contentFit="cover"
        contentPosition="bottom"
      />
      <View style={[StyleSheet.absoluteFill, { backgroundColor: '#00000099' }]} />
      <View style={styles.heroActions}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={materialBackLabel(locale)}
          onPress={onBack}
        >
          <GlassSurface interactive cornerRadius={22} style={styles.roundButton}>
            <ArrowLeft color="#fff" size={22} />
          </GlassSurface>
        </Pressable>
        {onExport ? (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('downloadTooltip')}
            onPress={onExport}
          >
            <GlassSurface interactive cornerRadius={22} style={styles.roundButton}>
              <Download color="#fff" size={21} />
            </GlassSurface>
          </Pressable>
        ) : null}
      </View>
      <View style={styles.identity}>
        <MobileWebImage
          imageUrl={clan.badgeUrls.smallest}
          style={[
            styles.badge,
            { width: width >= 900 ? 116 : 94, height: width >= 900 ? 116 : 94 },
          ]}
        />
        <CKText role="titleLarge" style={styles.white}>
          {clan.name}
        </CKText>
        <CKText style={styles.mutedWhite}>
          {clan.tag} | {t('cwlClanWarLeague')}
        </CKText>
      </View>
      <View style={styles.heroStats}>
        <Surface style={styles.leagueTile}>
          <MobileWebImage
            imageUrl={ImageAssets.getWarLeagueImage(leagueName)}
            style={styles.leagueIcon}
          />
          <View>
            <CKText role="rowTitle" style={styles.white}>
              {leagueName.replace(' League', '')}
            </CKText>
            <CKText style={styles.mutedWhite}>
              {cwlSeasonSubtitle(summary.leagueInfo?.season, locale, t)}
            </CKText>
          </View>
        </Surface>
        <Surface style={styles.leagueTile}>
          <MobileWebImage imageUrl={ImageAssets.cwlSwordsNoBorder} style={styles.leagueIcon} />
          <View>
            <CKText role="rowTitle" style={styles.white}>
              {t('cwlRankTitle')} #{clan.rank}/{summary.leagueInfo?.clans.length}
            </CKText>
            <CKText style={styles.mutedWhite}>
              {clan.stars} ★ · {formatPercent(clan.destructionPercentageInflicted, 0)}
            </CKText>
          </View>
        </Surface>
      </View>
      <View style={styles.heroPills}>
        <MetricPill
          image={ImageAssets.sword}
          value={
            totalPossible !== null
              ? `${clan.attackCount}/${totalPossible}`
              : String(clan.attackCount)
          }
          label={t('warAttacksTitle')}
        />
        <MetricPill
          image={ImageAssets.brokenSword}
          value={String(clan.missedAttacks)}
          label={t('warAttacksMissedShort')}
        />
        {totalRounds > 0 ? (
          <MetricPill
            image={ImageAssets.war}
            value={t('cwlRoundNumber', { number: currentRound })}
            label={t('cwlRounds')}
          />
        ) : null}
      </View>
    </View>
  );
}

function CwlRounds({
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
  const current = summary.leagueInfo?.getCurrentRounds()?.roundNumber ?? -1;
  const [expanded, setExpanded] = useState<ReadonlySet<number>>(
    new Set(current > 0 ? [current] : []),
  );
  const rounds = orderCwlRounds(summary);
  return (
    <View style={styles.stack}>
      {!rounds.length ? (
        <EmptyState title={t('generalNoDataAvailable')} />
      ) : (
        rounds.map((round) => {
          const wars = round.warTags
            .map((tag) => summary.getWarInfoFromTag(tag))
            .filter((war) => war.clan && war.opponent);
          const open = expanded.has(round.roundNumber);
          return (
            <Surface key={round.roundNumber}>
              <Pressable
                accessibilityRole="button"
                accessibilityState={{ expanded: open }}
                onPress={() => setExpanded(toggleSet(expanded, round.roundNumber))}
                style={styles.roundHeader}
              >
                <CalendarDays size={20} color={theme.onSurfaceVariant} />
                <CKText role="rowTitle" style={styles.grow}>
                  {t('cwlRoundNumber', { number: round.roundNumber })}
                </CKText>
                <RoundBadge wars={wars} clanTag={clanTag} />
                <ChevronDown
                  size={18}
                  color={theme.onSurfaceVariant}
                  style={{ transform: [{ rotate: open ? '180deg' : '0deg' }] }}
                />
              </Pressable>
              {open ? (
                <View style={styles.roundWars}>
                  {wars.length ? (
                    wars.map((war, index) => (
                      <CwlWarRow
                        key={war.tag ?? `${round.roundNumber}:${index}`}
                        war={war}
                        clanTag={clanTag}
                        onPress={() => onOpenWar(war.reorderForClan(clanTag), round.roundNumber)}
                      />
                    ))
                  ) : (
                    <CKText muted style={styles.emptyRound}>
                      {t('generalNoDataAvailable')}
                    </CKText>
                  )}
                </View>
              ) : null}
            </Surface>
          );
        })
      )}
    </View>
  );
}

function CwlWarRow({
  war,
  clanTag,
  onPress,
}: {
  war: WarInfo;
  clanTag: string;
  onPress: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const result = war.getWarResult(clanTag);
  const timing = formatCwlRoundTiming(war, t, locale);
  const color =
    result === 'won' || result === 'perfectWar'
      ? '#2EAD70'
      : result === 'lost'
        ? theme.error
        : theme.onSurfaceVariant;
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.cwlWarRow}>
      <MobileWebImage imageUrl={war.clan?.badgeUrls.smallest || ''} style={styles.smallBadge} />
      <View style={styles.teamName}>
        <CKText role="labelLarge" numberOfLines={1}>
          {war.clan?.name}
        </CKText>
        <RoundTeamMetric
          image={ImageAssets.sword}
          value={`${war.clan?.attacks ?? 0}/${war.teamSize ?? 0}`}
        />
        <RoundTeamMetric
          image={ImageAssets.hitrate}
          value={formatPercent(war.clan?.destructionPercentage ?? 0)}
        />
      </View>
      <View style={styles.warResult}>
        <CKText muted role="labelSmall" style={styles.roundTiming}>
          {timing}
        </CKText>
        <CKText role="titleMedium">
          {war.clan?.stars ?? 0} - {war.opponent?.stars ?? 0}
        </CKText>
        <CKText role="labelSmall" style={{ color }}>
          {result === 'won'
            ? t('warVictory')
            : result === 'perfectWar'
              ? t('warPerfectWar')
              : result === 'lost'
                ? t('warDefeat')
                : result === 'tie'
                  ? t('warDraw')
                  : war.state === 'preparation' || war.state === 'preparationDay'
                    ? t('warPreparation')
                    : t('warOngoing')}
        </CKText>
      </View>
      <View style={[styles.teamName, { alignItems: 'flex-end' }]}>
        <CKText role="labelLarge" numberOfLines={1}>
          {war.opponent?.name}
        </CKText>
        <RoundTeamMetric
          image={ImageAssets.sword}
          value={`${war.opponent?.attacks ?? 0}/${war.teamSize ?? 0}`}
          trailing
        />
        <RoundTeamMetric
          image={ImageAssets.hitrate}
          value={formatPercent(war.opponent?.destructionPercentage ?? 0)}
          trailing
        />
      </View>
      <MobileWebImage imageUrl={war.opponent?.badgeUrls.smallest || ''} style={styles.smallBadge} />
      <ChevronRight size={18} color={theme.onSurfaceVariant} />
    </Pressable>
  );
}

function RoundTeamMetric({
  image,
  value,
  trailing = false,
}: {
  image: string;
  value: string;
  trailing?: boolean;
}) {
  return (
    <View style={[styles.roundTeamMetric, trailing && styles.roundTeamMetricTrailing]}>
      {!trailing ? <MobileWebImage imageUrl={image} style={styles.roundTeamMetricIcon} /> : null}
      <CKText muted role="labelSmall">
        {value}
      </CKText>
      {trailing ? <MobileWebImage imageUrl={image} style={styles.roundTeamMetricIcon} /> : null}
    </View>
  );
}

function formatCwlRoundTiming(
  war: WarInfo,
  t: ReturnType<typeof useI18n>['t'],
  locale: string,
  now = new Date(),
): string {
  const timing = cwlRoundTiming(war, now);
  if (timing.kind === 'startsAt' || timing.kind === 'endsAt') {
    const time = timing.time.toLocaleTimeString(toIntlLocale(locale), {
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    });
    return timing.kind === 'startsAt' ? t('timeStartsAt', { time }) : t('timeEndsAt', { time });
  }
  if (timing.kind === 'endedJustNow') return t('timeEndedJustNow');
  if (timing.kind === 'endedMinutesAgo') return t('timeEndedMinutesAgo', { minutes: timing.value });
  if (timing.kind === 'endedHoursAgo') return t('timeEndedHoursAgo', { hours: timing.value });
  if (timing.kind === 'endedDaysAgo') return t('timeEndedDaysAgo', { days: timing.value });
  return t('generalUnknown');
}

function CwlTeams({
  clans,
  clanTag,
  actions,
}: {
  clans: readonly CwlClan[];
  clanTag: string;
  actions: WarPresentationActions;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [sort, setSort] = useState('stars');
  const [open, setOpen] = useState(false);
  const [expanded, setExpanded] = useState<ReadonlySet<string>>(new Set());
  const ordered = useMemo(() => sortCwlClans(clans, sort), [clans, sort]);
  const options = [
    { key: 'stars' as const, label: t('warStarsTitle') },
    { key: 'percentage' as const, label: t('warDestructionTitle') },
    { key: 'townHallLevel', label: t('gameTownHallLevel') },
    { key: 'missedAttacks', label: t('warAttacksMissed') },
    { key: 'averageStars' as const, label: t('warStarsAverage') },
    { key: '3stars', label: `⚔ 3 ★` },
    { key: '2stars', label: `⚔ 2 ★` },
    { key: '1stars', label: `⚔ 1 ★` },
    { key: '0stars', label: `⚔ 0 ★` },
    { key: 'defStars', label: `${t('warDefensesTitle')} · ${t('warStarsTitle')}` },
    { key: 'defDestruction', label: `${t('warDefensesTitle')} · ${t('warDestructionTitle')}` },
    { key: 'defAverageStars', label: `${t('warDefensesTitle')} · ${t('warStarsAverage')}` },
    {
      key: 'defAverageDestruction',
      label: `${t('warDefensesTitle')} · ${t('warDestructionAverage')}`,
    },
    { key: 'def3stars', label: `🛡 3 ★` },
    { key: 'def2stars', label: `🛡 2 ★` },
    { key: 'def1stars', label: `🛡 1 ★` },
    { key: 'def0stars', label: `🛡 0 ★` },
  ];
  return (
    <View style={styles.stack}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={t('generalFilters')}
        onPress={() => setOpen(true)}
        style={styles.teamSortWrap}
      >
        <GlassSurface interactive style={styles.teamSort}>
          <BarChart3 size={18} color={theme.onSurfaceVariant} />
          <CKText role="labelLarge" style={styles.grow}>
            {options.find((option) => option.key === sort)?.label}
          </CKText>
          <ChevronDown size={18} color={theme.onSurfaceVariant} />
        </GlassSurface>
      </Pressable>
      {ordered.map((clan, index) => (
        <View key={clan.tag}>
          <Surface style={[styles.teamCard, clan.tag === clanTag && styles.selectedTeam]}>
            <Pressable onPress={() => actions.openClan(clan.tag)} style={styles.teamHeader}>
              <View style={styles.rank}>
                <CKText role="titleMedium">#{clan.rank || index + 1}</CKText>
              </View>
              <MobileWebImage imageUrl={clan.badgeUrls.smallest} style={styles.teamBadge} />
              <View style={styles.grow}>
                <CKText role="rowTitle" numberOfLines={1}>
                  {clan.name}
                </CKText>
                <CKText muted role="labelSmall">
                  {clan.tag}
                </CKText>
              </View>
              <View style={styles.teamMetrics}>
                <CKText role="titleMedium">{clan.stars} ★</CKText>
                <CKText muted role="labelSmall">
                  {formatPercent(clan.destructionPercentageInflicted, 0)}
                </CKText>
              </View>
            </Pressable>
            <View style={styles.townHallStrip}>
              {Object.entries(clan.townHallLevels)
                .sort(([left], [right]) => Number(right) - Number(left))
                .map(([level, count]) => (
                  <View key={level} style={styles.townHallCount}>
                    <MobileWebImage
                      imageUrl={ImageAssets.townHall(Number(level))}
                      style={styles.townHallIcon}
                    />
                    <CKText role="labelMedium">x{count}</CKText>
                  </View>
                ))}
            </View>
            <FullStatsToggle
              expanded={expanded.has(clan.tag)}
              onPress={() => setExpanded(toggleStringSet(expanded, clan.tag))}
            />
            {expanded.has(clan.tag) ? <CwlClanFullStats clan={clan} /> : null}
          </Surface>
        </View>
      ))}
      <SelectionModal
        visible={open}
        title={t('generalFilters')}
        options={options}
        selected={sort}
        onSelect={setSort}
        onClose={() => setOpen(false)}
      />
    </View>
  );
}

function CwlMembers({
  members,
  actions,
}: {
  members: readonly CwlMember[];
  actions: WarPresentationActions;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [query, setQuery] = useState('');
  const [sort, setSort] = useState<CwlMemberSort>('stars');
  const [open, setOpen] = useState(false);
  const [expanded, setExpanded] = useState<ReadonlySet<string>>(new Set());
  const ordered = useMemo(() => sortCwlMembers(members, sort, query), [members, query, sort]);
  const options = cwlMemberSortOptions(t);
  return (
    <View style={styles.stack}>
      <SearchSortBar
        value={query}
        onChangeText={setQuery}
        placeholder={t('warStatsSearchPlaceholder')}
        searchIcon={<Search size={18} color={theme.onSurfaceVariant} />}
        sortLabel={t('generalFilters')}
        sortValue={options.find((option) => option.key === sort)?.label}
        onSortPress={() => setOpen(true)}
      />
      {!ordered.length ? (
        <EmptyState title={t('generalNoFilteredResults')} body={t('generalAdjustFilters')} />
      ) : (
        ordered.map((member, index) => (
          <CwlMemberCard
            key={member.tag}
            member={member}
            index={index}
            sort={sort}
            expanded={expanded.has(member.tag)}
            onToggle={() => setExpanded(toggleStringSet(expanded, member.tag))}
            onPress={() => actions.openPlayer(member.tag)}
          />
        ))
      )}
      <SelectionModal
        visible={open}
        title={t('generalFilters')}
        options={options}
        selected={sort}
        onSelect={setSort}
        onClose={() => setOpen(false)}
      />
    </View>
  );
}

function CwlMemberCard({
  member,
  index,
  sort,
  expanded,
  onToggle,
  onPress,
}: {
  member: CwlMember;
  index: number;
  sort: CwlMemberSort;
  expanded: boolean;
  onToggle: () => void;
  onPress: () => void;
}) {
  const { t } = useI18n();
  const attack = member.attackStats;
  const defense = member.defenseStats;
  return (
    <Surface style={styles.memberCard}>
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={member.name}
        onPress={onPress}
        style={styles.memberHeader}
      >
        <CKText role="titleMedium">{index + 1}.</CKText>
        <View style={styles.memberPosition}>
          <CKText muted role="labelSmall">
            📍{decimalOrDash(member.avgOpponentPosition)}
          </CKText>
          <MobileWebImage
            imageUrl={ImageAssets.townHall(member.townhallLevel)}
            style={styles.memberTh}
          />
        </View>
        <View style={styles.grow}>
          <CKText role="rowTitle">{member.name}</CKText>
          <CKText muted role="labelSmall">
            {member.tag} · TH{member.townhallLevel}
          </CKText>
        </View>
        <CwlMemberSortValue member={member} sort={sort} />
      </Pressable>
      <FullStatsToggle expanded={expanded} onPress={onToggle} />
      {expanded ? (
        <View style={styles.memberStats}>
          {attack ? (
            <CwlStatsSection
              title={t('warAttacksTitle')}
              metrics={[
                [t('warAttacksTitle'), String(attack.attackCount)],
                [t('warStatusMissed'), String(attack.missedAttacks)],
                [t('generalTotal'), `${attack.stars} ★`],
                [t('warAbbreviationAvg'), attack.averageStars.toFixed(1)],
                [t('warDestructionTitle'), formatPercent(attack.totalDestruction)],
                [t('warAbbreviationAvgPercentage'), attack.averageDestruction.toFixed(1)],
                [t('warPositionOrder'), decimalOrDash(member.avgAttackOrder)],
                [t('warPositionAbbr'), decimalOrDash(member.avgOpponentPosition)],
                [t('warOpponentTownhall'), decimalOrDash(member.avgOpponentTownHallLevel)],
                [t('warOpponentLowerTownhall'), integerOrDash(member.attackLowerTHLevel)],
                [t('warOpponentUpperTownhall'), integerOrDash(member.attackUpperTHLevel)],
              ]}
              stars={[member.threeStars, member.twoStars, member.oneStar, member.zeroStar]}
            />
          ) : null}
          {defense ? (
            <CwlStatsSection
              title={t('warDefensesTitle')}
              metrics={[
                [t('warDefensesTitle'), String(defense.defenseCount)],
                [t('warStatusMissed'), String(defense.missedDefenses)],
                [t('generalTotal'), `${defense.stars} ★`],
                [t('warAbbreviationAvg'), defense.averageStars.toFixed(1)],
                [t('warDestructionTitle'), formatPercent(defense.totalDestruction)],
                [t('warAbbreviationAvgPercentage'), defense.averageDestruction.toFixed(1)],
                [t('warPositionOrder'), decimalOrDash(member.avgDefenseOrder)],
                [t('warPositionAbbr'), decimalOrDash(member.avgAttackerPosition)],
                [t('warOpponentTownhall'), decimalOrDash(member.avgAttackerTownHallLevel)],
                [t('warOpponentLowerTownhall'), integerOrDash(member.defenseLowerTHLevel)],
                [t('warOpponentUpperTownhall'), integerOrDash(member.defenseUpperTHLevel)],
              ]}
              stars={[
                member.threeStarsDef,
                member.twoStarsDef,
                member.oneStarDef,
                member.zeroStarDef,
              ]}
            />
          ) : null}
        </View>
      ) : null}
    </Surface>
  );
}

function cwlMemberSortOptions(
  t: ReturnType<typeof useI18n>['t'],
): { key: CwlMemberSort; label: string }[] {
  return [
    { key: 'stars', label: `${t('warAttacksTitle')} · ${t('warStarsTitle')}` },
    { key: 'percentage', label: `${t('warAttacksTitle')} · ${t('warDestructionTitle')}` },
    { key: 'averageStars', label: t('warStarsAverage') },
    { key: 'averagePercentage', label: t('warDestructionAverage') },
    { key: 'attackCount', label: t('warAttacksCount') },
    { key: 'missedAttacks', label: t('warAttacksMissed') },
    { key: '3stars', label: `⚔ 3 ★` },
    { key: '2stars', label: `⚔ 2 ★` },
    { key: '1stars', label: `⚔ 1 ★` },
    { key: '0stars', label: `⚔ 0 ★` },
    { key: 'attackLowerTH', label: t('warOpponentLowerTownhall') },
    { key: 'attackUpperTH', label: t('warOpponentUpperTownhall') },
    { key: 'defStars', label: `${t('warDefensesTitle')} · ${t('warStarsTitle')}` },
    { key: 'defDestruction', label: `${t('warDefensesTitle')} · ${t('warDestructionTitle')}` },
    { key: 'defAverageStars', label: `${t('warDefensesTitle')} · ${t('warStarsAverage')}` },
    {
      key: 'defAverageDestruction',
      label: `${t('warDefensesTitle')} · ${t('warDestructionAverage')}`,
    },
    { key: 'def3stars', label: `🛡 3 ★` },
    { key: 'def2stars', label: `🛡 2 ★` },
    { key: 'def1stars', label: `🛡 1 ★` },
    { key: 'def0stars', label: `🛡 0 ★` },
    { key: 'defenseLowerTH', label: `${t('warDefensesTitle')} · ${t('warOpponentLowerTownhall')}` },
    { key: 'defenseUpperTH', label: `${t('warDefensesTitle')} · ${t('warOpponentUpperTownhall')}` },
  ];
}

function FullStatsToggle({ expanded, onPress }: { expanded: boolean; onPress: () => void }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ expanded }}
      onPress={onPress}
      style={styles.fullStatsToggle}
    >
      <CKText role="labelLarge">{t('generalFullStats')}</CKText>
      <ChevronDown
        size={18}
        color={theme.onSurfaceVariant}
        style={{ transform: [{ rotate: expanded ? '180deg' : '0deg' }] }}
      />
    </Pressable>
  );
}

function CwlClanFullStats({ clan }: { clan: CwlClan }) {
  const { t } = useI18n();
  return (
    <View style={styles.fullStatsStack}>
      <CwlStatsSection
        title={t('warAttacksTitle')}
        metrics={[
          [t('warAttacksTitle'), String(clan.attackCount)],
          [t('warStatusMissed'), String(clan.missedAttacks)],
          [t('warAbbreviationAvg'), clan.averageStars.toFixed(1)],
          [t('warDestructionTitle'), formatPercent(clan.destructionPercentageInflicted)],
          [t('warAbbreviationAvgPercentage'), clan.averageDestruction.toFixed(1)],
        ]}
        stars={[clan.threeStars, clan.twoStars, clan.oneStar, clan.zeroStar]}
      />
      <CwlStatsSection
        title={t('warDefensesTitle')}
        metrics={[
          [t('warDefensesTitle'), String(clan.defenseCount)],
          [t('warStatusMissed'), String(clan.missedDefenses)],
          [t('warAbbreviationAvg'), clan.defAverageStars.toFixed(1)],
          [t('warDestructionTitle'), formatPercent(clan.destructionPercentage)],
          [t('warAbbreviationAvgPercentage'), clan.defAverageDestruction.toFixed(1)],
        ]}
        stars={[clan.threeStarsDef, clan.twoStarsDef, clan.oneStarDef, clan.zeroStarDef]}
      />
    </View>
  );
}

function CwlStatsSection({
  title,
  metrics,
  stars,
}: {
  title: string;
  metrics: readonly (readonly [string, string])[];
  stars: readonly [number, number, number, number];
}) {
  return (
    <View style={styles.statsSection}>
      <CKText role="titleSmall" style={styles.statsTitle}>
        {title}
      </CKText>
      <View style={styles.metricsGrid}>
        {metrics.map(([label, value]) => (
          <View key={`${label}:${value}`} style={styles.metricTile}>
            <CKText muted role="labelSmall">
              {label}
            </CKText>
            <CKText role="labelLarge">{value}</CKText>
          </View>
        ))}
      </View>
      <View style={styles.starBreakdown}>
        {stars.map((count, index) => (
          <View key={3 - index} style={styles.starBreakdownItem}>
            <CKText role="labelMedium">{3 - index} ★</CKText>
            <CKText role="labelLarge">{count}</CKText>
          </View>
        ))}
      </View>
    </View>
  );
}

function CwlMemberSortValue({ member, sort }: { member: CwlMember; sort: CwlMemberSort }) {
  const attack = member.attackStats;
  const defense = member.defenseStats;
  const values: Record<CwlMemberSort, string> = {
    stars: `${attack?.stars ?? 0} ★`,
    percentage: formatPercent(attack?.totalDestruction ?? 0, 0),
    averageStars: `${(attack?.averageStars ?? 0).toFixed(1)} ★`,
    averagePercentage: formatPercent(attack?.averageDestruction ?? 0, 1),
    attackCount: String(attack?.attackCount ?? 0),
    missedAttacks: String(attack?.missedAttacks ?? 0),
    '0stars': `${member.zeroStar} ★`,
    '1stars': `${member.oneStar} ★`,
    '2stars': `${member.twoStars} ★`,
    '3stars': `${member.threeStars} ★`,
    attackLowerTH: integerOrZero(member.attackLowerTHLevel),
    attackUpperTH: integerOrZero(member.attackUpperTHLevel),
    defStars: `${defense?.stars ?? 0} ★`,
    defDestruction: formatPercent(defense?.totalDestruction ?? 0, 0),
    defAverageStars: `${(defense?.averageStars ?? 0).toFixed(1)} ★`,
    defAverageDestruction: formatPercent(defense?.averageDestruction ?? 0, 1),
    def0stars: `${member.zeroStarDef} ★`,
    def1stars: `${member.oneStarDef} ★`,
    def2stars: `${member.twoStarsDef} ★`,
    def3stars: `${member.threeStarsDef} ★`,
    defenseLowerTH: integerOrZero(member.defenseLowerTHLevel),
    defenseUpperTH: integerOrZero(member.defenseUpperTHLevel),
  };
  return <CKText role="bodyLarge">{values[sort]}</CKText>;
}

function decimalOrDash(value: number | null): string {
  return value === null ? '-' : value.toFixed(1);
}

function integerOrDash(value: number | null): string {
  return value === null ? '-' : value.toFixed(0);
}

function integerOrZero(value: number | null): string {
  return value === null ? '0' : value.toFixed(0);
}

function toggleStringSet(source: ReadonlySet<string>, value: string): ReadonlySet<string> {
  const next = new Set(source);
  if (next.has(value)) next.delete(value);
  else next.add(value);
  return next;
}

function toggleSet(source: ReadonlySet<number>, value: number): ReadonlySet<number> {
  const next = new Set(source);
  if (next.has(value)) next.delete(value);
  else next.add(value);
  return next;
}

function RoundBadge({ wars, clanTag }: { wars: readonly WarInfo[]; clanTag: string }) {
  const { t } = useI18n();
  const selected =
    wars.find((war) => war.clan?.tag === clanTag || war.opponent?.tag === clanTag) ?? wars[0];
  let label = t('warPreparation');
  let image = ImageAssets.iconClock;
  let color = '#D6A633';
  if (selected?.state === 'inWar' || selected?.state === 'warInWar') {
    label = t('warOngoing');
    image = ImageAssets.sword;
    color = '#F2C94C';
  } else if (selected?.state === 'warEnded') {
    const result = selected.getWarResult(clanTag);
    if (result === 'won' || result === 'perfectWar') {
      label = result === 'perfectWar' ? t('warPerfectWar') : t('warVictory');
      image = ImageAssets.attackStar;
      color = '#2EAD70';
    } else if (result === 'lost') {
      label = t('warDefeat');
      image = ImageAssets.brokenSword;
      color = '#D9534F';
    } else {
      label = t('warDraw');
      image = ImageAssets.shield;
      color = '#D6A633';
    }
  }
  return (
    <View
      accessibilityLabel={label}
      style={[
        styles.roundBadge,
        { backgroundColor: colorWithAlpha(color, 0.26), borderColor: colorWithAlpha(color, 0.46) },
      ]}
    >
      <MobileWebImage imageUrl={image} style={styles.roundBadgeImage} />
      <CKText role="labelSmall" style={{ color }}>
        {label}
      </CKText>
    </View>
  );
}

function cwlSeasonSubtitle(
  season: string | undefined,
  locale: string,
  t: ReturnType<typeof useI18n>['t'],
): string {
  const trimmed = season?.trim();
  if (!trimmed || trimmed === 'unknown') return t('cwlTitle');
  const match = /^(\d{4})-(\d{2})$/.exec(trimmed);
  if (!match) return t('statsSeasonDate', { date: trimmed });
  const date = new Date(Number(match[1]), Number(match[2]) - 1, 1);
  return t('statsSeasonDate', {
    date: date.toLocaleDateString(toIntlLocale(locale), { year: 'numeric', month: 'long' }),
  });
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  stack: { gap: 10 },
  grow: { flex: 1 },
  tabs: { paddingHorizontal: 12, marginTop: -12 },
  content: { width: '100%', maxWidth: 1320, alignSelf: 'center', padding: 10 },
  hero: { minHeight: 500, paddingTop: 10, paddingBottom: 20, gap: 8, overflow: 'hidden' },
  heroActions: { flexDirection: 'row', justifyContent: 'space-between', paddingHorizontal: 12 },
  roundButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  identity: { alignItems: 'center', gap: 2 },
  badge: { width: 98, height: 98, resizeMode: 'contain' },
  white: { color: '#fff' },
  mutedWhite: { color: '#ffffffa8' },
  heroStats: { flexDirection: 'row', gap: 8, paddingHorizontal: 16 },
  leagueTile: {
    flex: 1,
    minHeight: 72,
    backgroundColor: '#1111118c',
    flexDirection: 'row',
    alignItems: 'center',
    padding: 9,
    gap: 7,
  },
  leagueIcon: { width: 45, height: 45, resizeMode: 'contain' },
  heroPills: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 7,
    paddingHorizontal: 14,
  },
  roundHeader: {
    minHeight: 54,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 9,
    paddingHorizontal: 13,
  },
  currentLabel: { color: '#8D63D9' },
  roundBadge: {
    minHeight: 28,
    borderWidth: 1,
    borderRadius: 999,
    paddingHorizontal: 8,
    paddingVertical: 5,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  roundBadgeImage: { width: 15, height: 15 },
  roundWars: { borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: '#88888838' },
  emptyRound: { padding: 14 },
  cwlWarRow: { minHeight: 76, flexDirection: 'row', alignItems: 'center', gap: 6, padding: 9 },
  smallBadge: { width: 42, height: 42, resizeMode: 'contain' },
  teamName: { flex: 1 },
  roundTeamMetric: { flexDirection: 'row', alignItems: 'center', gap: 3 },
  roundTeamMetricTrailing: { justifyContent: 'flex-end' },
  roundTeamMetricIcon: { width: 12, height: 12 },
  roundTiming: { textAlign: 'center' },
  warResult: { width: 96, alignItems: 'center' },
  teamCard: { minHeight: 88, gap: 8, padding: 8 },
  teamHeader: { minHeight: 52, flexDirection: 'row', alignItems: 'center', gap: 8 },
  selectedTeam: { borderColor: colorWithAlpha('#8D63D9', 0.58), borderWidth: 1.5 },
  rank: { width: 38, alignItems: 'center' },
  teamBadge: { width: 54, height: 54, resizeMode: 'contain' },
  teamMetrics: { alignItems: 'flex-end' },
  townHallStrip: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', gap: 8 },
  townHallCount: { alignItems: 'center', padding: 4 },
  townHallIcon: { width: 20, height: 20 },
  teamSortWrap: { alignSelf: 'flex-end', width: '100%', maxWidth: 320 },
  teamSort: {
    minHeight: 48,
    paddingHorizontal: 13,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 9,
  },
  memberCard: { padding: 12, gap: 2 },
  memberHeader: { minHeight: 54, flexDirection: 'row', alignItems: 'center', gap: 8 },
  memberPosition: { alignItems: 'center', gap: 3 },
  memberTh: { width: 36, height: 36, resizeMode: 'contain' },
  memberStats: { gap: 18, paddingTop: 8 },
  fullStatsToggle: {
    minHeight: 40,
    alignSelf: 'flex-end',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
  },
  fullStatsStack: { gap: 10, paddingTop: 10 },
  statsSection: { gap: 10, alignItems: 'stretch' },
  statsTitle: { textAlign: 'center' },
  metricsGrid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'center', gap: 8 },
  metricTile: {
    minWidth: 104,
    flexGrow: 1,
    maxWidth: 170,
    minHeight: 58,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    backgroundColor: '#88888818',
    padding: 7,
  },
  starBreakdown: { flexDirection: 'row', justifyContent: 'center', gap: 7 },
  starBreakdownItem: {
    minWidth: 58,
    alignItems: 'center',
    borderRadius: 10,
    backgroundColor: '#88888818',
    padding: 6,
  },
});
