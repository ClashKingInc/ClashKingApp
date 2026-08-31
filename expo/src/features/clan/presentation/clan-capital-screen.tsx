import { useMemo, useState, type ReactNode } from 'react';
import { Modal, Pressable, ScrollView, StyleSheet, TextInput, View } from 'react-native';
import {
  ArrowDown,
  ArrowLeft,
  ArrowUp,
  BarChart3,
  Building2,
  Check,
  ChevronLeft,
  ChevronRight,
  History,
  Info,
  LayoutDashboard,
  Link2,
  Search,
  Shield,
  Swords,
  Users,
  X,
  Zap,
} from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { canonicalTag } from '../../../core/domain/tags';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  CardSurface,
  EmptyState,
  HeaderIconButton,
  MobileWebImage,
  PillSurface,
  Surface,
  ckRadius,
  colorWithAlpha,
  statColors,
  tintIcon,
  useCKTheme,
} from '../../../ui';
import type { CapitalHistoryItem, Clan, RaidMember } from '../models';
import {
  attackEfficiency,
  districtDefenseStats,
  districtStats,
  opponentStats,
  playerAttackStats,
  predictDefensiveReward,
  predictOffensiveReward,
  predictTrophyChange,
  projectedTotalLoot,
  trophyPerformance,
  type OpponentStat,
} from './clan-capital-analytics';

type CapitalTab = 'summary' | 'members' | 'breakdown' | 'history';
type MemberSort = 'loot' | 'attacks';
type MemberFilter = 'all' | 'attacked' | 'notAttacked';

export type ClanCapitalScreenProps = {
  clan: Clan;
  linkedPlayerTags?: readonly string[];
  goBack: () => void;
};

/** Frozen Flutter Clan Capital detail surface, kept independent for shell integration. */
export function ClanCapitalScreen({ clan, linkedPlayerTags = [], goBack }: ClanCapitalScreenProps) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const raids = clan.clanCapitalRaid?.items ?? [];
  const [tab, setTab] = useState<CapitalTab>('summary');
  const [week, setWeek] = useState(0);
  const selectedWeek = Math.min(week, Math.max(0, raids.length - 1));
  const raid = raids[selectedWeek];
  const tabs: readonly { key: CapitalTab; label: string; icon: ReactNode }[] = [
    {
      key: 'summary',
      label: t('generalSummary'),
      icon: (
        <LayoutDashboard
          size={17}
          color={tab === 'summary' ? theme.primary : theme.onSurfaceVariant}
        />
      ),
    },
    {
      key: 'members',
      label: t('clanMembers'),
      icon: <Users size={17} color={tab === 'members' ? theme.primary : theme.onSurfaceVariant} />,
    },
    {
      key: 'breakdown',
      label: t('generalBreakdown'),
      icon: (
        <Swords size={17} color={tab === 'breakdown' ? theme.primary : theme.onSurfaceVariant} />
      ),
    },
    {
      key: 'history',
      label: t('generalHistory'),
      icon: (
        <BarChart3 size={17} color={tab === 'history' ? theme.primary : theme.onSurfaceVariant} />
      ),
    },
  ];

  return (
    <ScrollView
      style={[styles.screen, { backgroundColor: theme.background }]}
      contentContainerStyle={styles.screenContent}
      testID="clan-capital-screen"
    >
      <CapitalHeader clan={clan} goBack={goBack} />
      {!raid ? (
        <EmptyState
          title={t('capitalRaidEmptyTitle')}
          body={t('capitalRaidEmptyBody')}
          icon={<Building2 color={theme.onSurfaceVariant} />}
          style={styles.empty}
        />
      ) : (
        <View style={styles.contentWidth}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.tabs}
          >
            {tabs.map((item) => (
              <Chip
                key={item.key}
                label={item.label}
                selected={tab === item.key}
                icon={item.icon}
                onPress={() => setTab(item.key)}
              />
            ))}
          </ScrollView>
          <WeekNavigator
            raid={raid}
            locale={locale}
            canOlder={selectedWeek < raids.length - 1}
            canNewer={selectedWeek > 0}
            onOlder={() => setWeek(selectedWeek + 1)}
            onNewer={() => setWeek(selectedWeek - 1)}
          />
          {tab === 'summary' ? <RaidSummary raid={raid} points={clan.clanCapitalPoints} /> : null}
          {tab === 'members' ? (
            <MembersTab
              clan={clan}
              raid={raid}
              allRaids={raids}
              linkedPlayerTags={linkedPlayerTags}
            />
          ) : null}
          {tab === 'breakdown' ? <BreakdownTab raid={raid} /> : null}
          {tab === 'history' ? (
            <HistoryTab raids={raids} clan={clan} points={clan.clanCapitalPoints} />
          ) : null}
        </View>
      )}
    </ScrollView>
  );
}

function CapitalHeader({ clan, goBack }: { clan: Clan; goBack: () => void }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const hall = clan.clanCapital?.capitalHallLevel ?? 1;
  const league = clan.capitalLeague?.name ?? 'Unranked';
  return (
    <View style={styles.hero}>
      <MobileWebImage
        imageUrl={ImageAssets.clanCapitalPageBackground}
        style={StyleSheet.absoluteFill}
        contentFit="cover"
        contentPosition="bottom"
      />
      <View style={styles.heroShade} />
      <View style={styles.heroTop}>
        <HeaderIconButton
          label={materialBackLabel(locale)}
          glass={false}
          onPress={goBack}
          icon={<ArrowLeft size={24} color="#FFF" />}
        />
      </View>
      <MobileWebImage imageUrl={ImageAssets.capitalHall(hall)} style={styles.capitalHall} />
      <CKText role="screenTitle" numberOfLines={1} style={styles.heroTitle}>
        {clan.name}
      </CKText>
      <CKText style={styles.heroTag}>{clan.tag}</CKText>
      <View style={styles.heroStats}>
        <HeroStat
          image={
            clan.capitalLeague
              ? ImageAssets.getCapitalLeagueImage(clan.capitalLeague.name)
              : ImageAssets.capitalTrophy
          }
          title={league.replace(' League', '')}
          subtitle={formatNumber(clan.clanCapitalPoints, locale)}
        />
        <HeroStat
          image={ImageAssets.capitalHall(hall)}
          title={`${t('clanCapitalHallTitle')} ${hall}`}
          subtitle={`${clan.clanCapital?.districts.length ?? 0} ${t('clanDistrictsTitle')}`}
        />
      </View>
      <View style={[styles.heroBottom, { backgroundColor: theme.background }]} />
    </View>
  );
}

function HeroStat({ image, title, subtitle }: { image: string; title: string; subtitle: string }) {
  return (
    <View style={styles.heroStat}>
      <MobileWebImage imageUrl={image} style={styles.heroStatImage} />
      <View style={styles.grow}>
        <CKText numberOfLines={1} style={styles.heroStatTitle}>
          {title}
        </CKText>
        <CKText numberOfLines={1} style={styles.heroStatSubtitle}>
          {subtitle}
        </CKText>
      </View>
    </View>
  );
}

function WeekNavigator({
  raid,
  locale,
  canOlder,
  canNewer,
  onOlder,
  onNewer,
}: {
  raid: CapitalHistoryItem;
  locale: string;
  canOlder: boolean;
  canNewer: boolean;
  onOlder: () => void;
  onNewer: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const ongoing = raid.state === 'ongoing';
  return (
    <View style={styles.weekRow}>
      <RoundButton
        label={t('capitalRaidPreviousWeek')}
        disabled={!canOlder}
        onPress={onOlder}
        icon={<ChevronLeft size={21} color={theme.onSurface} />}
      />
      <View style={styles.weekCenter}>
        <CKText role="labelLarge" numberOfLines={1} style={styles.bold}>
          {formatDate(raid.startTime, locale)} – {formatDate(raid.endTime, locale)}
        </CKText>
        <PillSurface
          style={[
            styles.status,
            {
              backgroundColor: colorWithAlpha(ongoing ? statColors.tie : statColors.win, 0.14),
              borderColor: colorWithAlpha(ongoing ? statColors.tie : statColors.win, 0.32),
            },
          ]}
        >
          {ongoing ? (
            <Swords size={12} color={statColors.tie} />
          ) : (
            <Check size={12} color={statColors.win} />
          )}
          <CKText role="labelMedium" style={{ color: ongoing ? statColors.tie : statColors.win }}>
            {ongoing ? t('capitalRaidStatusOngoing') : t('capitalRaidStatusEnded')}
          </CKText>
        </PillSurface>
      </View>
      <RoundButton
        label={t('capitalRaidNextWeek')}
        disabled={!canNewer}
        onPress={onNewer}
        icon={<ChevronRight size={21} color={theme.onSurface} />}
      />
    </View>
  );
}

function RaidSummary({ raid, points }: { raid: CapitalHistoryItem; points: number }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const ongoing = raid.state === 'ongoing';
  const estimate = Math.max(
    0,
    predictOffensiveReward(raid.attackLog) + predictDefensiveReward(raid.defenseLog),
  );
  const reward = ongoing ? estimate : 6 * raid.offensiveReward + raid.defensiveReward;
  const projected = projectedTotalLoot(raid);
  const prediction = ongoing ? predictTrophyChange(raid, points) : null;
  const metrics = [
    {
      label: t('raidsCompleted'),
      value: raid.raidsCompleted,
      icon: <Check size={18} color={theme.primary} />,
    },
    {
      label: t('raidsDistrictsDestroyed'),
      value: raid.enemyDistrictsDestroyed,
      icon: <Building2 size={18} color={statColors.capitalDistrict} />,
    },
    {
      label: t('warAttacksTitle'),
      value: raid.totalAttacks,
      icon: <Zap size={18} color={statColors.capitalAttack} />,
    },
    { label: t('capitalRaidLoot'), value: raid.capitalTotalLoot, image: ImageAssets.capitalGold },
    ...(projected === null
      ? []
      : [
          {
            label: t('capitalRaidProjectedLoot'),
            value: projected,
            icon: <ArrowUp size={18} color={statColors.capitalProjected} />,
          },
        ]),
    ...(prediction === null
      ? []
      : [
          {
            label: t('capitalRaidTrophyPrediction'),
            value: `${formatNumber(prediction.predictedPoints, locale)} (${prediction.change >= 0 ? '+' : ''}${formatNumber(prediction.change, locale)})`,
            icon:
              prediction.change >= 0 ? (
                <ArrowUp size={18} color={statColors.win} />
              ) : (
                <ArrowDown size={18} color={statColors.loss} />
              ),
          },
        ]),
  ];
  return (
    <CardSurface style={styles.summaryCard}>
      <View style={styles.rewardRow}>
        <MobileWebImage imageUrl={ImageAssets.raidMedal} style={styles.rewardImage} />
        <CKText role="heroMetric" numberOfLines={1} style={styles.grow}>
          {formatNumber(reward, locale)}
        </CKText>
        {ongoing ? (
          <PillSurface style={styles.estimated}>
            <BarChart3 size={12} color={theme.tertiary} />
            <CKText role="labelMedium" style={{ color: theme.tertiary }}>
              {t('capitalRaidEstimated')}
            </CKText>
          </PillSurface>
        ) : null}
        <CKText muted role="labelLarge">
          {t('capitalRaidRewards')}
        </CKText>
      </View>
      <View style={styles.metricGrid}>
        {metrics.map((metric) => (
          <Metric key={metric.label} {...metric} />
        ))}
      </View>
    </CardSurface>
  );
}

function MembersTab({
  clan,
  raid,
  allRaids,
  linkedPlayerTags,
}: {
  clan: Clan;
  raid: CapitalHistoryItem;
  allRaids: readonly CapitalHistoryItem[];
  linkedPlayerTags: readonly string[];
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [query, setQuery] = useState('');
  const [sort, setSort] = useState<MemberSort>('loot');
  const [filter, setFilter] = useState<MemberFilter>('all');
  const [linkedOnly, setLinkedOnly] = useState(false);
  const [historyMode, setHistoryMode] = useState(false);
  const [showSort, setShowSort] = useState(false);
  const linked = useMemo(() => new Set(linkedPlayerTags.map(canonicalTag)), [linkedPlayerTags]);
  const membersByTag = useMemo(
    () => new Map(clan.memberList.map((member) => [canonicalTag(member.tag), member])),
    [clan.memberList],
  );
  const selectedHasMembers = raid.members.length > 0;
  const attackMembers = useMemo(
    () => (selectedHasMembers ? [] : playerAttackStats(raid.attackLog)),
    [raid.attackLog, selectedHasMembers],
  );

  const rows = useMemo(() => {
    const search = query.trim().toLowerCase();
    const accepts = (name: string, tag: string) =>
      (!search || name.toLowerCase().includes(search)) &&
      (!linkedOnly || linked.has(canonicalTag(tag)));
    if (historyMode) {
      const byTag = new Map<
        string,
        {
          name: string;
          tag: string;
          raids: number;
          attacks: number;
          limit: number;
          loot: number;
          stars: number;
          destruction: number;
          perfect: number;
        }
      >();
      for (const item of allRaids) {
        if (item.members.length) {
          for (const member of item.members) {
            const key = canonicalTag(member.tag);
            const value = byTag.get(key) ?? {
              name: member.name,
              tag: member.tag,
              raids: 0,
              attacks: 0,
              limit: 0,
              loot: 0,
              stars: 0,
              destruction: 0,
              perfect: 0,
            };
            value.raids += 1;
            value.attacks += member.attacks;
            value.limit += member.attackLimit + member.bonusAttackLimit;
            value.loot += member.capitalResourcesLooted;
            byTag.set(key, value);
          }
        } else {
          for (const member of playerAttackStats(item.attackLog)) {
            const key = canonicalTag(member.tag);
            const value = byTag.get(key) ?? {
              name: member.name,
              tag: member.tag,
              raids: 0,
              attacks: 0,
              limit: 0,
              loot: 0,
              stars: 0,
              destruction: 0,
              perfect: 0,
            };
            value.raids += 1;
            value.attacks += member.attacks;
            value.stars += member.stars;
            value.destruction += member.destruction;
            value.perfect += member.perfectHits;
            byTag.set(key, value);
          }
        }
      }
      return [...byTag.values()]
        .filter((item) => accepts(item.name, item.tag))
        .sort((a, b) =>
          sort === 'attacks' ? b.attacks - a.attacks : b.loot - a.loot || b.stars - a.stars,
        )
        .map((item) => ({
          key: item.tag,
          name: item.name,
          tag: item.tag,
          townHall: membersByTag.get(canonicalTag(item.tag))?.townHallLevel ?? 0,
          subtitle:
            item.limit > 0
              ? `${item.raids} raids · ${item.attacks}/${item.limit} attacks`
              : `${item.raids} raids · ${item.attacks} hits · attack log`,
          top: item.loot > 0 ? formatNumber(item.loot, locale) : `${item.stars}★`,
          bottom:
            item.loot > 0
              ? `${formatNumber(Math.round(item.loot / Math.max(1, item.raids)), locale)}/raid`
              : `${Math.round(item.destruction / Math.max(1, item.attacks))}% avg`,
          linked: linked.has(canonicalTag(item.tag)),
        }));
    }
    if (!selectedHasMembers) {
      return attackMembers
        .filter((item) => accepts(item.name, item.tag))
        .map((item) => ({
          key: item.tag || item.name,
          name: item.name,
          tag: item.tag,
          townHall: membersByTag.get(canonicalTag(item.tag))?.townHallLevel ?? 0,
          subtitle: `${item.attacks} hits · ${Math.round(item.avgDestruction)}% avg`,
          top: `${item.stars}★`,
          bottom: `${item.perfectHits} perfect`,
          linked: linked.has(canonicalTag(item.tag)),
        }));
    }
    const participants = [...raid.members]
      .filter((member) => filter !== 'notAttacked' && accepts(member.name, member.tag))
      .sort((a, b) =>
        sort === 'attacks'
          ? b.attacks - a.attacks
          : b.capitalResourcesLooted - a.capitalResourcesLooted,
      )
      .map((member) =>
        memberRow(
          member,
          membersByTag.get(canonicalTag(member.tag))?.townHallLevel ?? 0,
          linked.has(canonicalTag(member.tag)),
          locale,
        ),
      );
    if (raid.state !== 'ongoing' || filter === 'attacked') return participants;
    const everRaided = new Set(
      allRaids.flatMap((item) => item.members.map((member) => canonicalTag(member.tag))),
    );
    const absent = clan.memberList
      .filter(
        (member) => !everRaided.has(canonicalTag(member.tag)) && accepts(member.name, member.tag),
      )
      .map((member) => ({
        key: member.tag,
        name: member.name,
        tag: member.tag,
        townHall: member.townHallLevel,
        subtitle: member.tag,
        top: '✕',
        bottom: '',
        linked: linked.has(canonicalTag(member.tag)),
        missing: true,
      }));
    return filter === 'notAttacked' ? absent : [...participants, ...absent];
  }, [
    allRaids,
    attackMembers,
    clan.memberList,
    filter,
    historyMode,
    linked,
    linkedOnly,
    locale,
    membersByTag,
    query,
    raid.members,
    raid.state,
    selectedHasMembers,
    sort,
  ]);

  return (
    <View style={styles.section}>
      <View style={styles.searchRow}>
        <Surface radius={ckRadius.control} style={styles.searchSurface}>
          <Search size={18} color={theme.onSurfaceVariant} />
          <TextInput
            accessibilityLabel={t('clanMembersSearchPlaceholder')}
            placeholder={t('clanMembersSearchPlaceholder')}
            placeholderTextColor={theme.onSurfaceVariant}
            value={query}
            onChangeText={setQuery}
            style={[styles.searchInput, { color: theme.onSurface }]}
          />
        </Surface>
        <Chip
          label={sort === 'loot' ? t('capitalRaidLoot') : t('warAttacksTitle')}
          selected
          onPress={() => setShowSort(true)}
        />
      </View>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.chipRail}
      >
        <Chip
          label={t('clanCapitalSelectedRaid')}
          selected={!historyMode}
          icon={<History size={15} color={theme.onSurfaceVariant} />}
          onPress={() => setHistoryMode(false)}
        />
        <Chip
          label={t('generalHistory')}
          selected={historyMode}
          icon={<History size={15} color={theme.onSurfaceVariant} />}
          onPress={() => setHistoryMode(true)}
        />
      </ScrollView>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.chipRail}
      >
        {!historyMode && selectedHasMembers ? (
          <>
            <Chip
              label={t('generalAll')}
              selected={filter === 'all'}
              onPress={() => setFilter('all')}
            />
            <Chip
              label={t('capitalRaidFilterAttacked')}
              selected={filter === 'attacked'}
              icon={<Check size={15} color={theme.onSurfaceVariant} />}
              onPress={() => setFilter('attacked')}
            />
            {raid.state === 'ongoing' ? (
              <Chip
                label={t('capitalRaidFilterNotAttacked')}
                selected={filter === 'notAttacked'}
                icon={<X size={15} color={theme.onSurfaceVariant} />}
                onPress={() => setFilter('notAttacked')}
              />
            ) : null}
          </>
        ) : null}
        <Chip
          label={t('capitalRaidFilterLinked')}
          selected={linkedOnly}
          icon={<Link2 size={15} color={theme.onSurfaceVariant} />}
          onPress={() => setLinkedOnly(!linkedOnly)}
        />
      </ScrollView>
      {!historyMode && !selectedHasMembers ? (
        <InfoPanel
          text={
            attackMembers.length
              ? t('capitalRaidMembersAttackLogFallback')
              : t('capitalRaidMembersNoPlayerData')
          }
        />
      ) : null}
      {!rows.length ? (
        <EmptyState
          title={
            !selectedHasMembers && !attackMembers.length
              ? t('capitalRaidMembersNoIndividualData')
              : query
                ? t('generalNoFilteredResults')
                : t('generalNoDataAvailable')
          }
        />
      ) : (
        rows.map(({ key, ...row }) => <MemberRow key={key} {...row} />)
      )}
      <ChoiceDialog
        visible={showSort}
        title={t('statsSortBy')}
        options={[
          {
            label: t('capitalRaidLoot'),
            selected: sort === 'loot',
            onPress: () => setSort('loot'),
          },
          {
            label: t('warAttacksTitle'),
            selected: sort === 'attacks',
            onPress: () => setSort('attacks'),
          },
        ]}
        onClose={() => setShowSort(false)}
      />
    </View>
  );
}

function BreakdownTab({ raid }: { raid: CapitalHistoryItem }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [offense, setOffense] = useState(true);
  const [opponent, setOpponent] = useState<OpponentStat>();
  const log = offense ? raid.attackLog : raid.defenseLog;
  const efficiency = attackEfficiency(log);
  const districts = districtStats(log);
  const defense = offense ? [] : districtDefenseStats(log);
  const opponents = opponentStats(log);
  return (
    <View style={styles.section}>
      <View style={styles.chipRail}>
        <Chip
          label={t('capitalDetailsOffense')}
          selected={offense}
          icon={<Swords size={15} color={theme.onSurfaceVariant} />}
          onPress={() => setOffense(true)}
        />
        <Chip
          label={t('capitalDetailsDefense')}
          selected={!offense}
          icon={<Shield size={15} color={theme.onSurfaceVariant} />}
          onPress={() => setOffense(false)}
        />
      </View>
      <View style={styles.chipRail}>
        <MetricPill label={t('capitalRaidOneshots')} value={efficiency.oneshots} />
        <MetricPill label={t('capitalRaidFails')} value={efficiency.fails} />
      </View>
      {defense.length ? <SectionTitle title="District defense" /> : null}
      {defense.map((item) => (
        <DataRow
          key={item.id}
          icon={<Shield size={18} color={item.held ? statColors.win : statColors.loss} />}
          title={item.name}
          subtitle={`${item.held} held / ${item.destroyed} destroyed · ${item.avgAttacksTaken.toFixed(1)} hits avg`}
          trailing={`${item.avgDestruction.toFixed(0)}%\n${formatNumber(item.lootLost, locale)}`}
        />
      ))}
      {districts.length ? <SectionTitle title={t('capitalDistrictsSection')} /> : null}
      {districts.map((item) => (
        <DataRow
          key={item.id}
          icon={<Building2 size={18} color={theme.onSurfaceVariant} />}
          title={item.name}
          subtitle={`${item.destroyedCount} destroyed · ${item.avgAttacksPerDestroy.toFixed(1)} ${t('capitalAvgAttacksPerDistrict')}`}
          trailing={`${formatNumber(item.loot, locale)}\n${formatNumber(Math.round(item.avgLootPerAttack), locale)}/hit`}
        />
      ))}
      {opponents.length ? <SectionTitle title={t('capitalOpponentsSection')} /> : null}
      {opponents.map((item) => (
        <Pressable key={item.clan.tag || item.clan.name} onPress={() => setOpponent(item)}>
          <DataRow
            image={item.clan.badgeUrls.smallest}
            title={item.clan.name}
            subtitle={`${item.districtsDestroyed}/${item.districtCount} districts · ${item.attacks} attacks`}
            trailing={formatNumber(item.loot, locale)}
          />
        </Pressable>
      ))}
      <OpponentDialog opponent={opponent} onClose={() => setOpponent(undefined)} />
    </View>
  );
}

function HistoryTab({
  raids,
  clan,
  points,
}: {
  raids: readonly CapitalHistoryItem[];
  clan: Clan;
  points: number;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [metric, setMetric] = useState<'loot' | 'rewards' | 'trophies'>('loot');
  const ended = raids
    .filter((raid) => raid.state === 'ended')
    .sort((a, b) => a.startTime.getTime() - b.startTime.getTime());
  const totalLoot = ended.reduce((sum, raid) => sum + raid.capitalTotalLoot, 0);
  const totalAttacks = ended.reduce((sum, raid) => sum + raid.totalAttacks, 0);
  const rewards = (raid: CapitalHistoryItem) => 6 * raid.offensiveReward + raid.defensiveReward;
  const best = ended.reduce<CapitalHistoryItem | undefined>(
    (value, raid) => (!value || rewards(raid) > rewards(value) ? raid : value),
    undefined,
  );
  const worst = ended.reduce<CapitalHistoryItem | undefined>(
    (value, raid) => (!value || rewards(raid) < rewards(value) ? raid : value),
    undefined,
  );
  const trends = memberTrends(raids, clan);
  const defense = districtDefenseStats(raids.flatMap((raid) => raid.defenseLog));
  const trophyTrend = estimatedTrophyTrend(ended, points);
  const values = ended.map((raid, index) =>
    metric === 'loot'
      ? raid.capitalTotalLoot
      : metric === 'rewards'
        ? rewards(raid)
        : (trophyTrend[index] ?? 0),
  );
  return (
    <View style={styles.section}>
      {!ended.length ? (
        <EmptyState title={t('generalNoDataAvailable')} />
      ) : (
        <>
          <View style={styles.metricGrid}>
            <Metric label={t('capitalHistoryWeeksTracked')} value={ended.length} />
            <Metric
              label={t('capitalAvgLootPerWeek')}
              value={formatNumber(Math.round(totalLoot / ended.length), locale)}
              image={ImageAssets.capitalGold}
            />
            <Metric
              label={t('capitalAvgAttacksPerWeek')}
              value={(totalAttacks / ended.length).toFixed(1)}
              icon={<Zap size={18} color={theme.onSurfaceVariant} />}
            />
            <Metric
              label={t('clanCapitalAvgRewards')}
              value={formatNumber(
                Math.round(ended.reduce((sum, raid) => sum + rewards(raid), 0) / ended.length),
                locale,
              )}
              image={ImageAssets.raidMedal}
            />
          </View>
          {trends.length ? (
            <SectionTitle
              title={t('clanCapitalTopAttackers')}
              subtitle={t('clanCapitalPlayersTracked', { count: trends.length })}
            />
          ) : null}
          {trends.slice(0, 10).map((item) => (
            <DataRow
              key={item.tag}
              image={
                item.townHall ? ImageAssets.townHall(item.townHall) : ImageAssets.capitalClanHouse
              }
              title={item.name}
              subtitle={`${item.weeks} weeks · ${item.attacks} attacks${item.townHall ? ` · TH${item.townHall}` : ''}`}
              trailing={`${formatNumber(item.loot, locale)}\n${formatNumber(Math.round(item.loot / item.weeks), locale)}/week`}
            />
          ))}
          {defense.length ? (
            <SectionTitle
              title={t('clanCapitalDefenseOverTime')}
              subtitle={t('clanCapitalDistrictsTracked', { count: defense.length })}
            />
          ) : null}
          {defense.map((item) => (
            <DataRow
              key={item.id}
              icon={<Shield size={18} color={item.held ? statColors.win : statColors.loss} />}
              title={item.name}
              subtitle={`${item.held} held / ${item.destroyed} destroyed`}
              trailing={`${item.avgDestruction.toFixed(0)}%\n${formatNumber(item.lootLost, locale)}`}
            />
          ))}
          {ended.length > 1 ? (
            <CardSurface style={styles.chartCard}>
              <CKText muted role="labelLarge">
                {t('capitalHistoryChartTitle')}
              </CKText>
              <View style={styles.chipRail}>
                <Chip
                  label={t('capitalRaidLoot')}
                  selected={metric === 'loot'}
                  onPress={() => setMetric('loot')}
                />
                <Chip
                  label={t('capitalRaidRewards')}
                  selected={metric === 'rewards'}
                  onPress={() => setMetric('rewards')}
                />
                {trophyTrend.length ? (
                  <Chip
                    label={t('gameTrophies')}
                    selected={metric === 'trophies'}
                    onPress={() => setMetric('trophies')}
                  />
                ) : null}
              </View>
              <BarTrend
                values={values}
                labels={ended.map((raid) =>
                  new Intl.DateTimeFormat(toIntlLocale(locale), {
                    month: 'numeric',
                    day: 'numeric',
                  }).format(raid.startTime),
                )}
              />
            </CardSurface>
          ) : null}
          {best ? (
            <Highlight
              raid={best}
              label={t('capitalBestRaid')}
              reward={rewards(best)}
              color={statColors.win}
              locale={locale}
            />
          ) : null}
          {worst ? (
            <Highlight
              raid={worst}
              label={t('capitalWorstRaid')}
              reward={rewards(worst)}
              color={statColors.loss}
              locale={locale}
            />
          ) : null}
        </>
      )}
    </View>
  );
}

function memberRow(member: RaidMember, townHall: number, linked: boolean, locale: string) {
  return {
    key: member.tag,
    name: member.name,
    tag: member.tag,
    townHall,
    subtitle: `${member.attacks}/${member.attackLimit + member.bonusAttackLimit} attacks · ${member.tag}`,
    top: formatNumber(member.capitalResourcesLooted, locale),
    bottom: '',
    linked,
  };
}

function memberTrends(raids: readonly CapitalHistoryItem[], clan: Clan) {
  const halls = new Map(
    clan.memberList.map((member) => [canonicalTag(member.tag), member.townHallLevel]),
  );
  const values = new Map<
    string,
    { name: string; tag: string; townHall: number; weeks: number; attacks: number; loot: number }
  >();
  for (const raid of raids)
    for (const member of raid.members) {
      const key = canonicalTag(member.tag);
      const value = values.get(key) ?? {
        name: member.name,
        tag: member.tag,
        townHall: halls.get(key) ?? 0,
        weeks: 0,
        attacks: 0,
        loot: 0,
      };
      value.weeks += 1;
      value.attacks += member.attacks;
      value.loot += member.capitalResourcesLooted;
      values.set(key, value);
    }
  return [...values.values()].sort((a, b) => b.loot - a.loot || b.attacks - a.attacks);
}

function estimatedTrophyTrend(ended: readonly CapitalHistoryItem[], current: number): number[] {
  if (current <= 0 || !ended.length) return [];
  const values = Array<number>(ended.length).fill(0);
  let points = current;
  for (let index = ended.length - 1; index >= 0; index -= 1) {
    values[index] = points;
    points = Math.max(0, Math.round((points - trophyPerformance(ended[index]!) * 0.2) / 0.8));
  }
  return values;
}

function MemberRow(row: {
  name: string;
  tag: string;
  townHall: number;
  subtitle: string;
  top: string;
  bottom: string;
  linked: boolean;
  missing?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <Surface
      strongBorder
      style={[
        styles.memberRow,
        {
          borderColor: row.missing
            ? statColors.loss
            : row.linked
              ? statColors.win
              : colorWithAlpha(theme.outlineVariant, 0.32),
        },
      ]}
    >
      <MobileWebImage
        imageUrl={
          row.townHall
            ? ImageAssets.townHall(row.townHall)
            : row.missing
              ? ImageAssets.capitalVacantHouse
              : ImageAssets.capitalClanHouse
        }
        style={styles.memberImage}
      />
      <View style={styles.grow}>
        <CKText role="rowTitle" numberOfLines={1}>
          {row.name}
        </CKText>
        <CKText muted role="metadata" numberOfLines={1}>
          {row.subtitle}
        </CKText>
      </View>
      <View style={styles.trailing}>
        <CKText role="labelLarge" style={row.missing ? { color: statColors.loss } : undefined}>
          {row.top}
        </CKText>
        {row.bottom ? (
          <CKText muted role="labelLarge">
            {row.bottom}
          </CKText>
        ) : null}
      </View>
    </Surface>
  );
}

function DataRow({
  icon,
  image,
  title,
  subtitle,
  trailing,
}: {
  icon?: ReactNode;
  image?: string;
  title: string;
  subtitle: string;
  trailing: string;
}) {
  const theme = useCKTheme();
  return (
    <Surface style={styles.dataRow}>
      {image ? (
        <MobileWebImage imageUrl={image} style={styles.rowImage} />
      ) : (
        <View style={styles.rowIcon}>{tintIcon(icon, theme.onSurfaceVariant)}</View>
      )}
      <View style={styles.grow}>
        <CKText role="rowTitle" numberOfLines={1}>
          {title}
        </CKText>
        <CKText muted role="metadata" numberOfLines={2}>
          {subtitle}
        </CKText>
      </View>
      <CKText role="labelLarge" style={styles.trailingText}>
        {trailing}
      </CKText>
    </Surface>
  );
}

function SectionTitle({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <View style={styles.sectionHeading}>
      <CKText role="titleSmall" style={styles.bold}>
        {title}
      </CKText>
      {subtitle ? (
        <CKText muted role="metadata">
          {subtitle}
        </CKText>
      ) : null}
    </View>
  );
}

function Metric({
  label,
  value,
  icon,
  image,
}: {
  label: string;
  value: string | number;
  icon?: ReactNode;
  image?: string;
}) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={styles.metric}>
      {image ? (
        <MobileWebImage imageUrl={image} style={styles.metricImage} />
      ) : (
        tintIcon(icon, theme.onSurfaceVariant)
      )}
      <CKText muted role="labelMedium" numberOfLines={1}>
        {label}
      </CKText>
      <CKText role="labelLarge" numberOfLines={1} style={styles.bold}>
        {typeof value === 'number' ? formatNumber(value, locale) : value}
      </CKText>
    </View>
  );
}

function MetricPill({ label, value }: { label: string; value: number }) {
  const { locale } = useI18n();
  return (
    <PillSurface style={styles.metricPill}>
      <CKText role="labelLarge" style={styles.bold}>
        {formatNumber(value, locale)}
      </CKText>
      <CKText muted role="labelMedium">
        {label}
      </CKText>
    </PillSurface>
  );
}

function Chip({
  label,
  selected,
  icon,
  onPress,
}: {
  label: string;
  selected: boolean;
  icon?: ReactNode;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable accessibilityRole="button" accessibilityState={{ selected }} onPress={onPress}>
      <PillSurface
        style={[
          styles.chip,
          {
            backgroundColor: colorWithAlpha(
              selected ? theme.primary : theme.surfaceContainerHighest,
              selected ? 0.14 : 0.38,
            ),
            borderColor: colorWithAlpha(
              selected ? theme.primary : theme.outlineVariant,
              selected ? 0.42 : 0.28,
            ),
          },
        ]}
      >
        {tintIcon(icon, selected ? theme.primary : theme.onSurfaceVariant)}
        <CKText role="labelLarge" style={selected ? styles.bold : undefined}>
          {label}
        </CKText>
      </PillSurface>
    </Pressable>
  );
}

function RoundButton({
  label,
  disabled,
  onPress,
  icon,
}: {
  label: string;
  disabled: boolean;
  onPress: () => void;
  icon: ReactNode;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      disabled={disabled}
      onPress={onPress}
      style={[styles.roundButton, disabled && styles.disabled]}
    >
      {icon}
    </Pressable>
  );
}

function InfoPanel({ text }: { text: string }) {
  const theme = useCKTheme();
  return (
    <Surface muted style={styles.info}>
      <Info size={18} color={theme.onSurfaceVariant} />
      <CKText muted role="metadata" style={styles.grow}>
        {text}
      </CKText>
    </Surface>
  );
}

function ChoiceDialog({
  visible,
  title,
  options,
  onClose,
}: {
  visible: boolean;
  title: string;
  options: readonly { label: string; selected: boolean; onPress: () => void }[];
  onClose: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.modalBackdrop} onPress={onClose}>
        <CardSurface style={[styles.dialog, { backgroundColor: theme.sheet }]}>
          <CKText role="sectionTitle">{title}</CKText>
          {options.map((option) => (
            <Pressable
              key={option.label}
              style={styles.dialogOption}
              onPress={() => {
                option.onPress();
                onClose();
              }}
            >
              <CKText style={styles.grow}>{option.label}</CKText>
              {option.selected ? <Check size={18} color={theme.primary} /> : null}
            </Pressable>
          ))}
        </CardSurface>
      </Pressable>
    </Modal>
  );
}

function OpponentDialog({ opponent, onClose }: { opponent?: OpponentStat; onClose: () => void }) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  return (
    <Modal
      visible={opponent !== undefined}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <View style={styles.modalBackdrop}>
        <CardSurface style={[styles.opponentDialog, { backgroundColor: theme.sheet }]}>
          <View style={styles.dialogTitle}>
            <CKText role="sectionTitle" style={styles.grow}>
              {opponent?.clan.name}
            </CKText>
            <Pressable onPress={onClose}>
              <X color={theme.onSurface} />
            </Pressable>
          </View>
          <ScrollView>
            {opponent?.districts.map((district) => (
              <DataRow
                key={district.id}
                icon={<Building2 size={18} color={theme.onSurfaceVariant} />}
                title={district.name}
                subtitle={`${district.attackCount} attacks · ${district.destructionPercent}%`}
                trailing={`${district.stars}★\n${formatNumber(district.totalLooted, locale)}`}
              />
            ))}
          </ScrollView>
        </CardSurface>
      </View>
    </Modal>
  );
}

function BarTrend({ values, labels }: { values: readonly number[]; labels: readonly string[] }) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  const maximum = Math.max(1, ...values);
  return (
    <View style={styles.chart}>
      {values.map((value, index) => (
        <View key={`${labels[index]}-${index}`} style={styles.barSlot}>
          <CKText role="labelSmall" numberOfLines={1}>
            {formatCompact(value, locale)}
          </CKText>
          <View
            style={[
              styles.bar,
              {
                height: Math.max(3, (value / maximum) * 92),
                backgroundColor: colorWithAlpha(theme.primary, 0.86),
              },
            ]}
          />
          <CKText muted role="labelSmall">
            {labels[index]}
          </CKText>
        </View>
      ))}
    </View>
  );
}

function Highlight({
  raid,
  label,
  reward,
  color,
  locale,
}: {
  raid: CapitalHistoryItem;
  label: string;
  reward: number;
  color: string;
  locale: string;
}) {
  return (
    <Surface style={[styles.highlight, { borderColor: colorWithAlpha(color, 0.35) }]}>
      <View style={[styles.rowIcon, { backgroundColor: colorWithAlpha(color, 0.14) }]}>
        <BarChart3 size={18} color={color} />
      </View>
      <View style={styles.grow}>
        <CKText muted role="labelMedium">
          {label}
        </CKText>
        <CKText role="rowTitle">{formatDate(raid.startTime, locale)}</CKText>
      </View>
      <View style={styles.trailing}>
        <CKText role="rowTitle">{formatNumber(reward, locale)}</CKText>
        <CKText muted role="labelMedium">
          {formatNumber(raid.capitalTotalLoot, locale)}
        </CKText>
      </View>
    </Surface>
  );
}

function formatDate(value: Date, locale: string): string {
  return new Intl.DateTimeFormat(toIntlLocale(locale), {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  }).format(value);
}
function formatNumber(value: number, locale: string): string {
  return new Intl.NumberFormat(toIntlLocale(locale)).format(value);
}
function formatCompact(value: number, locale: string): string {
  return new Intl.NumberFormat(toIntlLocale(locale), {
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(value);
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  screenContent: { paddingBottom: 32 },
  contentWidth: { width: '100%', maxWidth: 980, alignSelf: 'center' },
  grow: { flex: 1 },
  bold: { fontWeight: '800' },
  trailing: { alignItems: 'flex-end' },
  disabled: { opacity: 0.35 },
  hero: { minHeight: 330, alignItems: 'center', paddingHorizontal: 16, paddingBottom: 18 },
  heroShade: { ...StyleSheet.absoluteFill, backgroundColor: '#0000008A' },
  heroBottom: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: -1,
    height: 10,
    borderTopLeftRadius: 18,
    borderTopRightRadius: 18,
  },
  heroTop: { width: '100%', minHeight: 58, alignItems: 'flex-start', justifyContent: 'center' },
  capitalHall: { width: 94, height: 94, resizeMode: 'contain' },
  heroTitle: { color: '#FFF', fontSize: 26 },
  heroTag: { color: '#FFFFFFA0' },
  heroStats: { width: '100%', maxWidth: 620, flexDirection: 'row', gap: 8, marginTop: 14 },
  heroStat: {
    flex: 1,
    minHeight: 64,
    flexDirection: 'row',
    alignItems: 'center',
    padding: 10,
    gap: 8,
    borderRadius: 18,
    backgroundColor: '#00000075',
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#FFFFFF35',
  },
  heroStatImage: { width: 42, height: 42, resizeMode: 'contain' },
  heroStatTitle: { color: '#FFF', fontWeight: '800' },
  heroStatSubtitle: { color: '#FFFFFFB5', fontSize: 11 },
  empty: { margin: 16 },
  tabs: { paddingHorizontal: 16, paddingTop: 10, gap: 8 },
  chipRail: { flexDirection: 'row', gap: 8 },
  chip: {
    minHeight: 38,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
  },
  weekRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 12,
    gap: 10,
  },
  weekCenter: { flex: 1, alignItems: 'center', gap: 4 },
  roundButton: {
    width: 38,
    height: 38,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
  },
  status: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  summaryCard: { margin: 16, padding: 16, gap: 16 },
  rewardRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  rewardImage: { width: 34, height: 34, resizeMode: 'contain' },
  estimated: { flexDirection: 'row', gap: 4, paddingHorizontal: 7, paddingVertical: 3 },
  metricGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 16 },
  metric: { width: 92, minHeight: 60, alignItems: 'center', justifyContent: 'center', gap: 3 },
  metricImage: { width: 20, height: 20, resizeMode: 'contain' },
  metricPill: {
    minHeight: 42,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  section: { padding: 16, gap: 8 },
  searchRow: { flexDirection: 'row', gap: 8 },
  searchSurface: {
    minHeight: 48,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
  },
  searchInput: { flex: 1, minHeight: 46, fontFamily: 'ClashKing', fontSize: 15 },
  info: { flexDirection: 'row', padding: 10, alignItems: 'center', gap: 8 },
  memberRow: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
    paddingVertical: 7,
    gap: 9,
    borderRadius: 16,
  },
  memberImage: { width: 38, height: 38, resizeMode: 'contain' },
  sectionHeading: { marginTop: 10, gap: 2 },
  dataRow: {
    minHeight: 58,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 16,
  },
  rowIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowImage: { width: 36, height: 36, resizeMode: 'contain' },
  trailingText: { width: 92, textAlign: 'right', lineHeight: 17 },
  modalBackdrop: {
    flex: 1,
    backgroundColor: '#00000080',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  dialog: { width: '100%', maxWidth: 360, padding: 18, gap: 8 },
  dialogOption: { minHeight: 48, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 8 },
  opponentDialog: { width: '100%', maxWidth: 520, maxHeight: '78%', padding: 16, gap: 12 },
  dialogTitle: { flexDirection: 'row', alignItems: 'center' },
  chartCard: { padding: 12, gap: 10 },
  chart: { height: 130, flexDirection: 'row', alignItems: 'flex-end', gap: 5 },
  barSlot: { flex: 1, height: 126, alignItems: 'center', justifyContent: 'flex-end', gap: 3 },
  bar: { width: '68%', maxWidth: 28, borderRadius: 4 },
  highlight: { flexDirection: 'row', alignItems: 'center', gap: 10, padding: 10, borderRadius: 16 },
});
