import { ClanAdaptiveCards, ClanModalViewport } from './clan-tab-components';
import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { modalOrientations } from '../../../ui/modal-orientations';
import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { useLinkParameters, linkChoice } from '../../../core/deep-links/link-parameters';
import {
  Modal,
  Animated,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
  useWindowDimensions,
} from 'react-native';
import { SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  ArrowDown,
  ArrowUp,
  BarChart3,
  Building2,
  Check,
  ChevronRight,
  Info,
  LayoutDashboard,
  Link2,
  Search,
  Swords,
  Users,
  X,
  Zap,
} from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { canonicalTag } from '../../../core/domain/tags';
import { materialBackLabel, materialCloseLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  CardSurface,
  EmptyState,
  HeaderIconButton,
  CalendarPicker,
  DateNavigator,
  ProfileTabs,
  ProfilePageHeader,
  ProfileStatChip,
  InfoTooltip,
  SelectionPicker,
  MobileWebImage,
  PillSurface,
  Surface,
  SkeletonContent,
  ckRadius,
  colorWithAlpha,
  statColors,
  tintIcon,
  useCKTheme,
} from '../../../ui';
import { SlidingSegmentControl } from '../../../ui/sliding-segment-control';
import { PagerView, type PagerViewHandle } from '../../../ui/pager';
import { useCKAccessibility } from '../../../ui/accessibility';
import { usePrimarySwipeGuard } from '../../../ui/primary-swipe-guard';
import { AnalyticsLineChart } from '../../stats/presentation/analytics-chart';
import { CapitalHistoryItem, RaidMember, type Clan } from '../models';
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

type CapitalTab = 'summary' | 'members' | 'breakdown';
const CAPITAL_TABS: readonly CapitalTab[] = ['summary', 'members', 'breakdown'];
type MemberSort = 'loot' | 'attacks';
type MemberFilter = 'all' | 'attacked' | 'notAttacked';

export type ClanCapitalScreenProps = {
  clan: Clan;
  linkedPlayerTags?: readonly string[];
  goBack: () => void;
  loading?: boolean;
};

/** Raid navigation and reporting share the app's profile-page controls. */
export function ClanCapitalScreen({
  clan,
  linkedPlayerTags = [],
  goBack,
  loading = false,
}: ClanCapitalScreenProps) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { width } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const storedRaids = clan.clanCapitalRaid?.items ?? [];
  const pending = loading && !storedRaids.length;
  // This model exists only inside the skeleton scope; never attach it to the
  // clan or its repository. The loaded screen and loading screen share cards.
  const raids = pending
    ? [
        new CapitalHistoryItem(
          'ongoing',
          new Date(0),
          new Date(3 * 86_400_000),
          100000,
          3,
          100,
          30,
          1000,
          100,
          (clan.memberList.length
            ? clan.memberList.slice(0, 4)
            : [{ tag: '', name: 'Clan member' }]
          ).map((member) => new RaidMember(member.tag, member.name, 6, 5, 1, 10000)),
          [],
          [],
        ),
      ]
    : storedRaids;
  const link = useLinkParameters();
  const [tab, setTab] = useState<CapitalTab>(() => {
    const requested = linkChoice(
      link.tab,
      ['summary', 'members', 'breakdown', 'history'],
      'summary',
    );
    // Existing shared history links now open the combined Stats destination.
    return requested === 'history' ? 'breakdown' : requested;
  });
  const [initialTab] = useState(tab);
  const pager = useRef<PagerViewHandle>(null);
  const [settledTab, setSettledTab] = useState(tab);
  const [tabPosition] = useState(() => new Animated.Value(CAPITAL_TABS.indexOf(initialTab)));
  const [pageHeights, setPageHeights] = useState<Partial<Record<CapitalTab, number>>>({});
  const { reduceMotion } = useCKAccessibility();
  const blockPrimarySwipe = usePrimarySwipeGuard();
  useEffect(() => () => blockPrimarySwipe(false), [blockPrimarySwipe]);
  const selectTab = (next: CapitalTab) => {
    setTab(next);
    const index = CAPITAL_TABS.indexOf(next);
    if (reduceMotion) {
      pager.current?.setPageWithoutAnimation(index);
      tabPosition.setValue(index);
      setSettledTab(next);
    } else {
      pager.current?.setPage(index);
    }
  };
  const [week, setWeek] = useState(
    Math.max(
      0,
      raids.findIndex((raid) => raid.startTime?.toISOString().slice(0, 10) === link.day),
    ),
  );
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
      label: t('generalStats'),
      icon: (
        <BarChart3 size={17} color={tab === 'breakdown' ? theme.primary : theme.onSurfaceVariant} />
      ),
    },
  ];

  return (
    <SafeAreaView
      edges={['left', 'right']}
      style={[styles.screen, { backgroundColor: theme.background }]}
    >
      <ScrollView
        style={[styles.screen, { backgroundColor: theme.background }]}
        contentContainerStyle={[styles.screenContent, { paddingBottom: insets.bottom + 32 }]}
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
          <View
            style={[styles.contentWidth, layout.isExpanded && { maxWidth: layout.contentMaxWidth }]}
          >
            <View style={styles.tabs}>
              <ProfileTabs
                variant="underline"
                overflow="fit"
                tabs={tabs.map((item) => ({ ...item, icon: width >= 600 ? item.icon : undefined }))}
                selectedKey={tab}
                animatedPosition={tabPosition}
                indicatorRtl={isRtl}
                onSelect={(key) => selectTab(key as CapitalTab)}
              />
            </View>
            <SkeletonContent loading={pending}>
              <WeekNavigator
                raid={raid}
                raids={raids}
                onSelect={setWeek}
                locale={locale}
                canOlder={selectedWeek < raids.length - 1}
                canNewer={selectedWeek > 0}
                onOlder={() => setWeek(selectedWeek + 1)}
                onNewer={() => setWeek(selectedWeek - 1)}
              />
            </SkeletonContent>
            <View
              onTouchStart={() => blockPrimarySwipe(true)}
              onTouchEnd={() => blockPrimarySwipe(false)}
              onTouchCancel={() => blockPrimarySwipe(false)}
            >
              <PagerView
                ref={pager}
                initialPage={CAPITAL_TABS.indexOf(initialTab)}
                layoutDirection={isRtl ? 'rtl' : 'ltr'}
                testID="capital-section-pager"
                style={{
                  height: Math.max(pageHeights[tab] ?? 500, pageHeights[settledTab] ?? 500),
                }}
                onPageScroll={(event) =>
                  tabPosition.setValue(event.nativeEvent.position + event.nativeEvent.offset)
                }
                onPageSelected={(event) => {
                  const next = CAPITAL_TABS[event.nativeEvent.position];
                  if (next) {
                    setTab(next);
                    setSettledTab(next);
                  }
                }}
              >
                {CAPITAL_TABS.map((page) => (
                  <View
                    key={page}
                    collapsable={false}
                    style={{ flex: 1 }}
                    aria-hidden={page !== tab}
                    accessibilityElementsHidden={page !== tab}
                    importantForAccessibility={page !== tab ? 'no-hide-descendants' : 'auto'}
                  >
                    <View
                      onLayout={(event) => {
                        const height = Math.ceil(event.nativeEvent.layout.height);
                        if (height > 0)
                          setPageHeights((old) =>
                            old[page] === height ? old : { ...old, [page]: height },
                          );
                      }}
                    >
                      <SkeletonContent loading={pending}>
                        {page === 'summary' ? (
                          <RaidSummary raid={raid} points={clan.clanCapitalPoints} />
                        ) : page === 'members' ? (
                          <MembersTab clan={clan} raid={raid} linkedPlayerTags={linkedPlayerTags} />
                        ) : (
                          <CapitalStatsTab raids={raids} points={clan.clanCapitalPoints}>
                            <BreakdownTab raid={raid} />
                          </CapitalStatsTab>
                        )}
                      </SkeletonContent>
                    </View>
                  </View>
                ))}
              </PagerView>
            </View>
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

function CapitalHeader({ clan, goBack }: { clan: Clan; goBack: () => void }) {
  const { t, locale } = useI18n();
  const insets = useSafeAreaInsets();
  const hall = clan.clanCapital?.capitalHallLevel ?? 1;
  return (
    <ProfilePageHeader
      testID="capital-profile-header"
      title={clan.name}
      titleImageUrl={clan.badgeUrls.smallest}
      imageUrl={ImageAssets.capitalHall(hall)}
      imageSize={104}
      backgroundUrl={ImageAssets.clanCapitalPageBackground}
      onBack={goBack}
      backLabel={materialBackLabel(locale)}
      safeTop={insets.top}
      bottomPadding={24}
    >
      <View style={styles.heroStats}>
        <ProfileStatChip
          icon={
            clan.capitalLeague
              ? ImageAssets.getCapitalLeagueImage(clan.capitalLeague.name)
              : ImageAssets.capitalTrophy
          }
          label={clan.capitalLeague?.name ?? t('clanCapitalPoints')}
          value={clan.clanCapitalPoints}
        />
        <ProfileStatChip
          icon={ImageAssets.capitalHall(hall)}
          label={t('clanCapitalHallTitle')}
          value={`${t('clanCapitalHallTitle')} ${hall}`}
        />
      </View>
    </ProfilePageHeader>
  );
}

function WeekNavigator({
  raid,
  raids,
  onSelect,
  locale,
  canOlder,
  canNewer,
  onOlder,
  onNewer,
}: {
  raid: CapitalHistoryItem;
  raids: readonly CapitalHistoryItem[];
  onSelect: (index: number) => void;
  locale: ReturnType<typeof useI18n>['locale'];
  canOlder: boolean;
  canNewer: boolean;
  onOlder: () => void;
  onNewer: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [calendarOpen, setCalendarOpen] = useState(false);
  const insets = useSafeAreaInsets();
  // Raid dates are UTC calendar labels; do not shift Friday to Thursday for
  // western time zones when matching the shared local-date calendar picker.
  const localDay = (date: Date) =>
    new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate());
  const dayKey = (date: Date) => `${date.getFullYear()}-${date.getMonth()}-${date.getDate()}`;
  const days = raids.map((item) => localDay(item.startTime));
  const available = new Set(days.map(dayKey));
  const ongoing = raid.state === 'ongoing';
  return (
    <>
      <DateNavigator
        label={`${formatDate(raid.startTime, locale)} – ${formatDate(raid.endTime, locale)}`}
        previousDisabled={!canOlder}
        nextDisabled={!canNewer}
        onPrevious={onOlder}
        onNext={onNewer}
        onPressLabel={() => setCalendarOpen(true)}
      >
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
      </DateNavigator>
      <Modal
        supportedOrientations={modalOrientations}
        visible={calendarOpen}
        transparent
        animationType="slide"
        onRequestClose={() => setCalendarOpen(false)}
      >
        <Pressable style={styles.modalBackdrop} onPress={() => setCalendarOpen(false)}>
          <Pressable
            style={[
              styles.calendarSheet,
              { backgroundColor: theme.sheet, paddingBottom: insets.bottom + 20 },
            ]}
            onPress={() => undefined}
          >
            <View style={styles.dialogTitle}>
              <CKText skeleton={false} role="sectionTitle" style={styles.grow}>
                {t('clanCapitalSelectedRaid')}
              </CKText>
              <HeaderIconButton
                label={materialCloseLabel(locale)}
                icon={<X color={theme.onSurface} size={22} />}
                onPress={() => setCalendarOpen(false)}
              />
            </View>
            <CalendarPicker
              key={raid.startTime.toISOString()}
              start={localDay(raid.startTime)}
              minimum={new Date(Math.min(...days.map(Number)))}
              maximum={new Date(Math.max(...days.map(Number)))}
              isDateSelectable={(date) => available.has(dayKey(date))}
              onChange={(date) => {
                const index = days.findIndex((day) => dayKey(day) === dayKey(date));
                if (index >= 0) {
                  onSelect(index);
                  setCalendarOpen(false);
                }
              }}
            />
          </Pressable>
        </Pressable>
      </Modal>
    </>
  );
}

function RaidSummary({ raid, points }: { raid: CapitalHistoryItem; points: number }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const ongoing = raid.state === 'ongoing';
  const [opponentOpen, setOpponentOpen] = useState(false);
  // Select the unfinished raid, not the first/highest-loot entry: completed
  // opponents remain in the same weekly log and must never look current.
  const currentRaid = ongoing
    ? raid.attackLog.find((entry) => entry.districtCount > entry.districtsDestroyed)
    : undefined;
  const currentOpponent = currentRaid ? opponentStats([currentRaid])[0] : undefined;
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
      image: ImageAssets.capitalClanHouse,
    },
    {
      label: t('raidsDistrictsDestroyed'),
      value: raid.enemyDistrictsDestroyed,
      image: ImageAssets.capitalDistrictHall(5),
    },
    {
      label: t('warAttacksTitle'),
      value: raid.totalAttacks,
      image: ImageAssets.raidAttacks,
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
            hint: t('capitalRaidTrophyPredictionTooltip'),
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
    <View style={styles.section}>
      {currentOpponent ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={`${t('capitalCurrentOpponent')}: ${currentOpponent.clan.name}`}
          onPress={() => setOpponentOpen(true)}
        >
          <CardSurface style={styles.summaryCard}>
            <CKText skeleton={false} muted role="metadata">
              {t('capitalCurrentOpponent')}
            </CKText>
            <View style={styles.rewardRow}>
              <MobileWebImage
                imageUrl={currentOpponent.clan.badgeUrls.medium}
                style={styles.rowImage}
              />
              <CKText role="titleSmall" style={styles.grow}>
                {currentOpponent.clan.name}
              </CKText>
              <ChevronRight size={18} color={theme.onSurfaceVariant} />
            </View>
            <View style={styles.currentRaidMetrics}>
              <View style={styles.grow}>
                <CKText role="bodyLarge">
                  {currentOpponent.districtsDestroyed}/{currentOpponent.districtCount}
                </CKText>
                <CKText skeleton={false} muted role="metadata">
                  {t('raidsDistrictsDestroyed')}
                </CKText>
              </View>
              <View style={styles.grow}>
                <CKText role="bodyLarge">{currentOpponent.attacks}</CKText>
                <CKText skeleton={false} muted role="metadata">
                  {t('warAttacksTitle')}
                </CKText>
              </View>
              <CapitalGoldValues total={formatNumber(currentOpponent.loot, locale)} />
            </View>
          </CardSurface>
        </Pressable>
      ) : null}
      <OpponentDialog
        opponent={opponentOpen ? currentOpponent : undefined}
        onClose={() => setOpponentOpen(false)}
      />
      <CardSurface style={styles.summaryCard}>
        <View style={styles.rewardRow}>
          <MobileWebImage imageUrl={ImageAssets.raidMedal} style={styles.rewardImage} />
          <View style={styles.grow}>
            <CKText skeleton={false} muted role="metadata">
              {t('capitalRaidRewards')}
            </CKText>
            <CKText role="titleLarge" style={styles.rewardValue} numberOfLines={1}>
              {formatNumber(reward, locale)}
            </CKText>
          </View>
          {ongoing ? (
            <PillSurface style={styles.estimated}>
              <BarChart3 size={12} color={theme.tertiary} />
              <CKText skeleton={false} role="labelMedium" style={{ color: theme.tertiary }}>
                {t('capitalRaidEstimated')}
              </CKText>
            </PillSurface>
          ) : null}
        </View>
      </CardSurface>
      <View style={styles.metricGrid}>
        {metrics.map((metric) => (
          <Metric key={metric.label} {...metric} />
        ))}
      </View>
    </View>
  );
}

function MembersTab({
  clan,
  raid,
  linkedPlayerTags,
}: {
  clan: Clan;
  raid: CapitalHistoryItem;
  linkedPlayerTags: readonly string[];
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [query, setQuery] = useState('');
  const [sort, setSort] = useState<MemberSort>('loot');
  const [filter, setFilter] = useState<MemberFilter>('all');
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
    const accepts = (name: string) => !search || name.toLowerCase().includes(search);
    if (!selectedHasMembers) {
      return attackMembers
        .filter((item) => accepts(item.name))
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
      .filter((member) => filter !== 'notAttacked' && accepts(member.name))
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
    // A member who raided last week can still be missing this weekend.
    const participantsThisWeek = new Set(raid.members.map((member) => canonicalTag(member.tag)));
    const absent = clan.memberList
      .filter(
        (member) => !participantsThisWeek.has(canonicalTag(member.tag)) && accepts(member.name),
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
    attackMembers,
    clan.memberList,
    filter,
    linked,
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
        <SelectionPicker
          title={t('statsSortBy')}
          selectedKey={sort}
          onSelect={setSort}
          options={[
            { key: 'loot', label: t('capitalRaidLoot') },
            { key: 'attacks', label: t('warAttacksTitle') },
          ]}
        />
      </View>
      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.chipRail}
      >
        {selectedHasMembers ? (
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
      </ScrollView>
      {!selectedHasMembers ? (
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
        <ClanAdaptiveCards>
          {rows.map(({ key, ...row }) => (
            <MemberRow key={key} {...row} />
          ))}
        </ClanAdaptiveCards>
      )}
    </View>
  );
}

function BreakdownTab({ raid }: { raid: CapitalHistoryItem }) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const [contentWidth, setContentWidth] = useState(0);
  const [offense, setOffense] = useState(true);
  const [opponent, setOpponent] = useState<OpponentStat>();
  const log = offense ? raid.attackLog : raid.defenseLog;
  const efficiency = attackEfficiency(log);
  const districts = districtStats(log);
  const defense = offense ? [] : districtDefenseStats(log);
  const opponents = opponentStats(log);
  const wideSections =
    layout.isExpanded &&
    contentWidth >= 840 &&
    (districts.length > 0 || defense.length > 0) &&
    opponents.length > 0;
  const controls = (
    <>
      <SlidingSegmentControl
        value={offense ? 'offense' : 'defense'}
        style={layout.isExpanded ? styles.breakdownMode : undefined}
        isRtl={isRtl}
        options={[
          { value: 'offense', label: t('capitalDetailsOffense') },
          { value: 'defense', label: t('capitalDetailsDefense') },
        ]}
        onChange={(value) => setOffense(value === 'offense')}
      />
      <View style={styles.chipRail}>
        <MetricPill label={t('capitalRaidOneshots')} value={efficiency.oneshots} />
        <MetricPill label={t('capitalRaidFails')} value={efficiency.fails} />
      </View>
    </>
  );
  return (
    <View
      style={styles.breakdownSection}
      onLayout={(event) => setContentWidth(event.nativeEvent.layout.width)}
    >
      {layout.isExpanded ? <View style={styles.breakdownToolbar}>{controls}</View> : controls}
      {!opponents.length ? (
        <EmptyState
          title={t('generalNoDataAvailable')}
          icon={<Swords color={theme.onSurfaceVariant} />}
        />
      ) : null}
      <View
        style={[
          { gap: 12, display: wideSections ? 'flex' : 'contents' },
          wideSections && { flexDirection: 'row', alignItems: 'flex-start' },
        ]}
      >
        <View
          style={[
            { gap: 12, display: wideSections ? 'flex' : 'contents' },
            wideSections && { flex: 1, minWidth: 0 },
          ]}
        >
          {defense.length ? <SectionTitle title={t('capitalDetailsDefense')} /> : null}
          {defense.map((item) => (
            <DataRow
              key={item.id}
              image={districtArtwork(raid.defenseLog, item.id)}
              title={item.name}
              subtitle={`${item.held} held / ${item.destroyed} destroyed · ${item.avgAttacksTaken.toFixed(1)} hits avg`}
              trailing={`${item.avgDestruction.toFixed(0)}%\n${formatNumber(item.lootLost, locale)}`}
            />
          ))}
          {districts.length ? <SectionTitle title={t('capitalDistrictsSection')} /> : null}
          {districts.map((item) => (
            <DataRow
              key={item.id}
              image={districtArtwork(log, item.id)}
              title={item.name}
              subtitle={`${item.destroyedCount} destroyed · ${item.avgAttacksPerDestroy.toFixed(1)} ${t('capitalAvgAttacksPerDistrict')}`}
              trailing={
                <CapitalGoldValues
                  total={formatNumber(item.loot, locale)}
                  perHit={`${formatNumber(Math.round(item.avgLootPerAttack), locale)}/hit`}
                />
              }
            />
          ))}
        </View>
        <View
          style={[
            { gap: 12, display: wideSections ? 'flex' : 'contents' },
            wideSections && { flex: 1, minWidth: 0 },
          ]}
        >
          {opponents.length ? <SectionTitle title={t('capitalOpponentsSection')} /> : null}
          {opponents.map((item) => (
            <Pressable key={item.clan.tag || item.clan.name} onPress={() => setOpponent(item)}>
              <DataRow
                image={item.clan.badgeUrls.small}
                title={item.clan.name}
                subtitle={`${item.districtsDestroyed}/${item.districtCount} districts · ${item.attacks} attacks`}
                trailing={<CapitalGoldValues total={formatNumber(item.loot, locale)} />}
              />
            </Pressable>
          ))}
        </View>
      </View>
      <OpponentDialog opponent={opponent} onClose={() => setOpponent(undefined)} />
    </View>
  );
}

function CapitalStatsTab({
  raids,
  points,
  children,
}: {
  raids: readonly CapitalHistoryItem[];
  points: number;
  children: ReactNode;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
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
  const trophyTrend = estimatedTrophyTrend(ended, points);
  const values = ended.map((raid, index) =>
    metric === 'loot'
      ? raid.capitalTotalLoot
      : metric === 'rewards'
        ? rewards(raid)
        : (trophyTrend[index] ?? 0),
  );
  const chart =
    ended.length > 1 ? (
      <CardSurface style={[styles.chartCard, layout.isExpanded && styles.expandedChartCard]}>
        <View style={styles.dialogTitle}>
          <CKText skeleton={false} role="sectionTitle" style={styles.grow}>
            {t('capitalHistoryChartTitle')}
          </CKText>
          {metric === 'trophies' ? (
            <CKText skeleton={false} muted role="metadata">
              {t('capitalRaidEstimated')}
            </CKText>
          ) : null}
        </View>
        <SlidingSegmentControl
          value={metric}
          style={layout.isExpanded ? styles.expandedChartSwitch : undefined}
          isRtl={isRtl}
          onChange={setMetric}
          options={[
            { value: 'loot', label: t('capitalRaidLoot') },
            { value: 'rewards', label: t('capitalRaidMedals') },
            ...(trophyTrend.length
              ? [{ value: 'trophies' as const, label: t('gameTrophies') }]
              : []),
          ]}
        />
        <AnalyticsLineChart
          key={metric}
          title={t('capitalHistoryChartTitle')}
          showTitle={false}
          exportable={false}
          xDomain="observations"
          responsiveAxes
          height={layout.isExpanded ? 260 : 200}
          showPoints
          connectGaps={false}
          formatAxisValue={(value) => formatCompact(value, locale)}
          formatValue={(value) => formatNumber(Math.round(value), locale)}
          formatDay={(day) => formatDate(new Date(`${day}T00:00:00Z`), locale)}
          formatAxisDay={(day) =>
            new Intl.DateTimeFormat(toIntlLocale(locale), {
              month: 'short',
              ...(ended[0]?.startTime.getUTCFullYear() !== ended.at(-1)?.startTime.getUTCFullYear()
                ? { year: '2-digit' as const }
                : { day: 'numeric' as const }),
              timeZone: 'UTC',
            }).format(new Date(`${day}T00:00:00Z`))
          }
          series={[
            {
              key: metric,
              label: t(
                metric === 'loot'
                  ? 'capitalRaidLoot'
                  : metric === 'rewards'
                    ? 'capitalRaidMedals'
                    : 'gameTrophies',
              ),
              color:
                metric === 'rewards'
                  ? statColors.capitalDistrict
                  : metric === 'loot'
                    ? statColors.capitalLoot
                    : statColors.capitalTrophy,
              // Keep missing raid weekends disconnected rather than drawing a
              // smooth progression through unobserved results.
              points: ended.flatMap((raid, index) => {
                const point = {
                  day: raid.startTime.toISOString().slice(0, 10),
                  value: values[index] ?? null,
                };
                const previous = ended[index - 1];
                return previous &&
                  raid.startTime.getTime() - previous.startTime.getTime() > 8 * 86400000
                  ? [
                      {
                        day: new Date(previous.startTime.getTime() + 7 * 86400000)
                          .toISOString()
                          .slice(0, 10),
                        value: null,
                      },
                      point,
                    ]
                  : [point];
              }),
            },
          ]}
        />
      </CardSurface>
    ) : null;
  // The chart is a peer of the history summary, not a sidebar beside the
  // entire district list. Keep breakdown controls and records full width below.
  const sideBySide = chart !== null && Math.min(layout.usableWidth, layout.contentMaxWidth) >= 780;
  if (layout.isExpanded)
    return (
      <View style={styles.section}>
        <View style={[styles.statsOverview, sideBySide && styles.statsOverviewRow]}>
          {chart ? (
            <View style={sideBySide ? styles.statsChartColumn : undefined}>{chart}</View>
          ) : null}
          <View style={[styles.statsSummaryColumn, sideBySide && { flex: 1 }]}>
            {!ended.length ? (
              <EmptyState title={t('generalNoDataAvailable')} />
            ) : (
              <>
                <View style={styles.metricGrid}>
                  <Metric
                    columns={2}
                    label={t('capitalHistoryWeeksTracked')}
                    value={ended.length}
                  />
                  <Metric
                    columns={2}
                    label={t('capitalAvgLootPerWeek')}
                    value={formatNumber(Math.round(totalLoot / ended.length), locale)}
                    image={ImageAssets.capitalGold}
                  />
                  <Metric
                    columns={2}
                    label={t('capitalAvgAttacksPerWeek')}
                    value={(totalAttacks / ended.length).toFixed(1)}
                    icon={<Zap size={18} color={theme.onSurfaceVariant} />}
                  />
                  <Metric
                    columns={2}
                    label={t('clanCapitalAvgRewards')}
                    value={formatNumber(
                      Math.round(
                        ended.reduce((sum, raid) => sum + rewards(raid), 0) / ended.length,
                      ),
                      locale,
                    )}
                    image={ImageAssets.raidMedal}
                  />
                </View>
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
        </View>
        {children}
      </View>
    );
  return (
    <View
      style={[
        styles.section,
        layout.isExpanded && chart && { flexDirection: 'row', alignItems: 'flex-start', gap: 24 },
      ]}
    >
      <View
        style={layout.isExpanded && chart ? { width: '40%', minWidth: 0 } : { display: 'contents' }}
      >
        {chart}
      </View>
      <View
        style={[
          { gap: 12, display: layout.isExpanded && chart ? 'flex' : 'contents' },
          layout.isExpanded && chart && { flex: 1, minWidth: 0 },
        ]}
      >
        {children}
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
      style={[
        styles.memberRow,
        {
          backgroundColor: row.missing ? colorWithAlpha(statColors.loss, 0.07) : theme.card,
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
        <View style={styles.memberName}>
          <CKText role="rowTitle" numberOfLines={1} style={styles.shrink}>
            {row.name}
          </CKText>
          {row.linked ? <Link2 size={13} color={statColors.win} /> : null}
        </View>
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

function CapitalGoldValues({ total, perHit }: { total: string; perHit?: string }) {
  const { t } = useI18n();
  return (
    <View
      style={styles.trailing}
      accessibilityLabel={`${t('capitalRaidLoot')}: ${total}${perHit ? `, ${perHit}` : ''}`}
    >
      <View style={styles.lootValue}>
        <MobileWebImage imageUrl={ImageAssets.capitalGold} style={styles.lootIcon} />
        <CKText role="labelLarge" style={styles.trailingText}>
          {total}
        </CKText>
      </View>
      {perHit ? (
        <CKText muted role="labelLarge" style={styles.trailingText}>
          ({perHit})
        </CKText>
      ) : null}
    </View>
  );
}

function DataRow({
  icon,
  image,
  title,
  subtitle,
  trailing,
  disclosure = false,
}: {
  icon?: ReactNode;
  image?: string;
  title: string;
  subtitle: string;
  trailing: ReactNode;
  disclosure?: boolean;
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
      {typeof trailing === 'string' ? (
        <CKText role="labelLarge" style={styles.trailingText}>
          {trailing}
        </CKText>
      ) : (
        trailing
      )}
      {disclosure ? <ChevronRight size={18} color={theme.onSurfaceVariant} /> : null}
    </Surface>
  );
}

function SectionTitle({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <View style={styles.sectionHeading}>
      <CKText skeleton={false} role="titleSmall" style={styles.bold}>
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
  hint,
  columns,
}: {
  label: string;
  value: string | number;
  icon?: ReactNode;
  image?: string;
  hint?: string;
  columns?: number;
}) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const columnCount = columns ?? layout.columns(170, 4);
  return (
    <Surface
      style={[
        styles.metric,
        layout.isExpanded && {
          // The overview summary is narrower than the page. Leave real room
          // for its 10pt gap, then flexGrow shares the remaining width evenly.
          flexBasis: columns === 2 ? '46%' : `${(100 - (columnCount - 1) * 1.5) / columnCount}%`,
        },
      ]}
    >
      <View style={styles.metricTitle}>
        {image ? (
          <MobileWebImage imageUrl={image} style={styles.metricImage} />
        ) : (
          tintIcon(icon, theme.onSurfaceVariant)
        )}
        <CKText skeleton={false} muted role="labelMedium" style={styles.shrink}>
          {label}
        </CKText>
        {hint ? (
          <InfoTooltip label={label} message={hint} triggerStyle={{ width: 18, height: 24 }} />
        ) : null}
      </View>
      <CKText
        role="titleMedium"
        numberOfLines={1}
        adjustsFontSizeToFit
        minimumFontScale={0.7}
        style={styles.bold}
      >
        {typeof value === 'number' ? formatNumber(value, locale) : value}
      </CKText>
    </Surface>
  );
}

function MetricPill({ label, value }: { label: string; value: number }) {
  const { locale } = useI18n();
  return (
    <PillSurface style={styles.metricPill}>
      <CKText role="labelLarge" style={styles.bold}>
        {formatNumber(value, locale)}
      </CKText>
      <CKText skeleton={false} muted role="labelMedium">
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
              selected ? theme.onSurface : theme.surfaceContainerHighest,
              selected ? 0.12 : 0.38,
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

function OpponentDialog({ opponent, onClose }: { opponent?: OpponentStat; onClose: () => void }) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  return (
    <Modal
      supportedOrientations={modalOrientations}
      visible={opponent !== undefined}
      transparent
      animationType="fade"
      onRequestClose={onClose}
    >
      <ClanModalViewport>
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
                  image={
                    district.id === 70_000_000
                      ? ImageAssets.capitalHall(district.districtHallLevel)
                      : ImageAssets.capitalDistrictHall(district.districtHallLevel)
                  }
                  title={district.name}
                  subtitle={`${district.attackCount} attacks · ${district.destructionPercent}%`}
                  trailing={`${district.stars}★\n${formatNumber(district.totalLooted, locale)}`}
                />
              ))}
            </ScrollView>
          </CardSurface>
        </View>
      </ClanModalViewport>
    </Modal>
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
    timeZone: 'UTC',
  }).format(value);
}

function districtArtwork(log: CapitalHistoryItem['attackLog'], id: number): string {
  const level = Math.max(
    1,
    ...log.flatMap((opponent) =>
      opponent.districts
        .filter((district) => district.id === id)
        .map((district) => district.districtHallLevel),
    ),
  );
  return id === 70_000_000
    ? ImageAssets.capitalHall(level)
    : ImageAssets.capitalDistrictHall(level);
}
function formatNumber(value: number, locale: string): string {
  return new Intl.NumberFormat(toIntlLocale(locale)).format(value);
}
function formatCompact(value: number, locale: string): string {
  const unit = Math.abs(value) >= 1_000_000 ? 1_000_000 : Math.abs(value) >= 1_000 ? 1_000 : 1;
  const number = new Intl.NumberFormat(toIntlLocale(locale), {
    maximumFractionDigits: unit === 1 ? 0 : 2,
  }).format(value / unit);
  return `${number}${unit === 1_000_000 ? 'M' : unit === 1_000 ? 'K' : ''}`;
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  screenContent: { paddingBottom: 32 },
  contentWidth: { width: '100%', maxWidth: 980, alignSelf: 'center' },
  grow: { flex: 1 },
  bold: { fontWeight: '700' },
  shrink: { flexShrink: 1 },
  memberName: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  trailing: { alignItems: 'flex-end' },
  disabled: { opacity: 0.35 },
  heroStats: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 8,
  },
  empty: { margin: 16 },
  tabs: { paddingHorizontal: 12 },
  chipRail: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: {
    minHeight: 38,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    borderWidth: 0,
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
  summaryCard: { padding: 20, gap: 12, borderWidth: 0 },
  rewardRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  rewardImage: { width: 42, height: 42, resizeMode: 'contain' },
  rewardValue: { fontSize: 28, lineHeight: 34, fontWeight: '700' },
  estimated: { flexDirection: 'row', gap: 4, paddingHorizontal: 7, paddingVertical: 3 },
  metricGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  metric: {
    flexGrow: 1,
    flexBasis: '46%',
    minHeight: 88,
    padding: 14,
    justifyContent: 'center',
    gap: 10,
    borderWidth: 0,
    borderRadius: 24,
  },
  metricTitle: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  metricImage: { width: 20, height: 20, resizeMode: 'contain' },
  metricPill: {
    minHeight: 42,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    borderWidth: 0,
  },
  section: { padding: 16, gap: 12 },
  breakdownSection: { gap: 12 },
  breakdownToolbar: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 16,
  },
  breakdownMode: { flex: 1, minWidth: 260, maxWidth: 420, height: 44 },
  expandedChartCard: { padding: 20, gap: 16 },
  expandedChartSwitch: { height: 44 },
  statsOverview: { gap: 20, marginBottom: 12 },
  statsOverviewRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 24 },
  statsChartColumn: { flex: 1.4, minWidth: 0 },
  statsSummaryColumn: { gap: 12, minWidth: 0 },
  searchRow: { flexDirection: 'row', gap: 8 },
  searchSurface: {
    minHeight: 48,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    borderWidth: 0,
    borderRadius: 26,
  },
  searchInput: { flex: 1, minHeight: 46, fontFamily: 'ClashKing', fontSize: 15 },
  info: {
    flexDirection: 'row',
    padding: 14,
    alignItems: 'center',
    gap: 8,
    borderWidth: 0,
    borderRadius: 20,
  },
  memberRow: {
    minHeight: 82,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 14,
    gap: 12,
    borderRadius: 24,
    borderWidth: 0,
  },
  memberImage: { width: 44, height: 44, resizeMode: 'contain' },
  sectionHeading: { marginTop: 18, marginBottom: 2, gap: 4 },
  dataRow: {
    minHeight: 82,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderRadius: 24,
    borderWidth: 0,
  },
  rowIcon: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  rowImage: { width: 36, height: 36, resizeMode: 'contain' },
  trailingText: { maxWidth: 104, textAlign: 'right', lineHeight: 20, fontWeight: '600' },
  currentRaidMetrics: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  lootValue: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  lootIcon: { width: 14, height: 14, resizeMode: 'contain' },
  modalBackdrop: {
    flex: 1,
    backgroundColor: '#00000080',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  dialog: { width: '100%', maxWidth: 360, padding: 18, gap: 8 },
  calendarSheet: { width: '100%', maxWidth: 480, padding: 20, gap: 16, borderRadius: 28 },
  dialogOption: { minHeight: 48, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 8 },
  opponentDialog: {
    width: '100%',
    maxWidth: 560,
    maxHeight: '78%',
    padding: 20,
    gap: 12,
    borderWidth: 0,
  },
  dialogTitle: { flexDirection: 'row', alignItems: 'center' },
  chartCard: { padding: 12, gap: 10, borderWidth: 0 },
  chart: { minWidth: '100%', height: 160, flexDirection: 'row', alignItems: 'flex-end', gap: 8 },
  barSlot: {
    flexGrow: 1,
    minWidth: 52,
    height: 156,
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 6,
  },
  bar: { width: 24, borderRadius: 7 },
  highlight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    padding: 16,
    borderRadius: 24,
    borderWidth: 0,
  },
});
