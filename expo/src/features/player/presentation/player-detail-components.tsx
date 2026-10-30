import { SafeAreaProvider, SafeAreaView, useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { illustratedHeaderLayout } from '../../../ui/illustrated-header-layout';
import { HeroHeaderScrim } from '../../../ui/hero-header-scrim';
import { HeaderArtwork } from '../../../ui/header-artwork';
import { modalOrientations } from '../../../ui/modal-orientations';
import type { StyleProp, ViewInstance, ViewStyle } from 'react-native';
import {
  cloneElement,
  isValidElement,
  useCallback,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import {
  Modal,
  PanResponder,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  ArrowLeft,
  ArrowDown,
  ArrowUp,
  Bookmark,
  BookmarkCheck,
  CircleAlert,
  Check,
  ChevronRight,
  Clock3,
  ExternalLink,
  Filter,
  ListOrdered,
  LogIn,
  LogOut,
  Repeat2,
  Share2,
  Shield,
  Upload,
  UserRound,
  X,
} from 'lucide-react-native';
import { SlidingSegmentControl } from '../../../ui/sliding-segment-control';
import { ExpandableProgressCard } from '../../../ui/expandable-progress-card';
import { trackerCategoryImage } from '../../upgrade-tracker/presentation/tracker-category-art';
import { UpgradeVillage } from '../../upgrade-tracker/models';
import { sharePageLink } from '../../../core/deep-links/share-page-link';
import { playerProfileClanIdentity } from './player-clan-identity';

import {
  ChartInteractionBoundary,
  useChartDismissal,
} from '../../stats/presentation/chart-interaction-boundary';
import { ImageAssets } from '../../../core/assets/image-assets';
import { formatUpgradeDuration } from '../../../core/utils/upgrade-duration';
import {
  localizedInfoForItem,
  localizedNameForItem,
} from '../../../core/game-data/game-data-localization';
import { toIntlLocale, useI18n, type MessageKey } from '../../../i18n';
import { materialBackLabel } from '../../../i18n/material-labels';
import {
  CKText,
  EmptyState,
  ErrorState,
  SkeletonContent,
  MobileWebImage,
  PillSurface,
  PressableSurface,
  ProfileHeaderAction,
  ProfileStatChip as QuickStat,
  ResponsiveGrid,
  SelectionPicker,
  Surface,
  ckRadius,
  ckColors,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type {
  Player,
  PlayerActivityEvent,
  PlayerActivityFeed,
  PlayerBattlelogData,
  PlayerBattlelogEntry,
  PlayerPopularArmyItem,
  PlayerCwlHistory,
  PlayerCwlSeason,
  PlayerItem,
  PlayerJoinLeavePage,
  PlayerJoinLeaveTotal,
  PlayerHistoryTypeValue,
} from '../models';

import { PlayerSuperTroop } from '../models/player-items';
import { PlayerBattlelogArmyCatalog } from '../models/player-battlelog';
import { playerTabHasContent } from './player-loading-model';
import {
  battlelogLootTimeline,
  battlelogLootWeeks,
  type BattlelogLootDay,
} from './player-battlelog-share';

import { UpgradeItemDetailModal } from '../../upgrade-tracker/presentation/upgrade-tracker-breakdowns';
import { calculateRemainingUpgradeSummary, maxLevelForItemAtTH } from '../data/player-item-utils';
import type {
  PlayerDetailPresentationActions,
  PlayerDetailPresentationModel,
  PlayerDetailTabKey,
} from './player-detail-contracts';
import { upgradeDetailsItem, upgradeDetailsSnapshot } from './player-item-detail-adapter';
import {
  filteredJoinLeaveEvents,
  joinLeaveDuration,
  sortedJoinLeaveTotals,
} from './player-join-leave-state';
export { PlayerWarTab } from './player-war-tab';

export const PLAYER_DETAIL_TABS: readonly {
  key: PlayerDetailTabKey;
  labelKey?: MessageKey;
  flutterLabel?: string;
}[] = [
  { key: 'home', labelKey: 'gameBaseHome' },
  { key: 'builder', labelKey: 'gameBaseBuilder' },
  { key: 'battles', labelKey: 'playerBattlelogTab' },
  { key: 'history', labelKey: 'generalHistory' },
  { key: 'legendHistory', labelKey: 'clanLegendHistoryTab' },
  { key: 'war', labelKey: 'warStats' },
  { key: 'cwl', labelKey: 'cwlHistoryTitle' },
  { key: 'achievements', labelKey: 'gameAchievements' },
  { key: 'joinLeave', labelKey: 'playerJoinLeaveTab' },
];

export function PlayerDetailHeader({
  model,
  actions,
  selectedTab,
  onBattlelogExport,
  safeTop = 0,
  loading = false,
}: {
  model: PlayerDetailPresentationModel;
  actions: PlayerDetailPresentationActions;
  selectedTab: PlayerDetailTabKey;
  onBattlelogExport?: () => void;
  safeTop?: number;
  loading?: boolean;
}) {
  const { player } = model;
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const { width } = useWindowDimensions();
  const [headerSize, setHeaderSize] = useState({ width, height: 0 });
  // Expanded native layouts share the desktop identity and league row while
  // compact phones retain the centered composition.
  const layout = useAdaptiveLayout();
  const headerLayout = illustratedHeaderLayout(layout);
  const insets = useSafeAreaInsets();
  const compact =
    !layout.isExpanded && (Platform.OS !== 'web' || Math.min(width, headerSize.width) < 900);
  const clan = playerHeaderClanIdentity(player, model.cachedClanTag);
  const role = playerRoleLabel(player.role, t);
  const copyPlayerTag = () =>
    void actions.copyTag(player.tag).then(() => actions.showMessage(t('generalCopiedToClipboard')));
  const warAction = model.currentWar
    ? {
        label: t('warOngoing'),
        image: ImageAssets.war,
        onPress: () => actions.openWar(model.currentWar!),
      }
    : model.currentCwl?.summary.isInWar
      ? {
          label: t('warOngoing'),
          image: ImageAssets.war,
          onPress: () => actions.openWar(model.currentCwl!.summary.warInfo),
        }
      : model.currentCwl?.summary.isInCwl
        ? {
            label: t('cwlOngoing'),
            image: ImageAssets.cwlSwordsNoBorder,
            onPress: () => actions.openCwl(model.currentCwl!),
          }
        : null;
  const leagueTiles = (
    <View
      testID="player-league-tiles"
      style={[
        styles.leagueTiles,
        compact ? styles.leagueTilesCompact : styles.leagueTilesDesktop,
        layout.isExpanded && styles.leagueTilesExpanded,
      ]}
    >
      {(selectedTab === 'builder'
        ? [
            [
              player.builderBaseLeague,
              player.builderBaseLeagueUrl,
              player.builderBaseTrophies,
              false,
            ],
            [player.league, player.leagueUrl, player.trophies, true],
          ]
        : [
            [player.league, player.leagueUrl, player.trophies, true],
            [
              player.builderBaseLeague,
              player.builderBaseLeagueUrl,
              player.builderBaseTrophies,
              false,
            ],
          ]
      ).map(([name, image, trophies, ranked], index) => (
        <Pressable
          key={`${String(name)}-${index}`}
          accessibilityRole={ranked ? 'button' : undefined}
          disabled={!ranked}
          onPress={() =>
            player.isLegendLeague ? actions.openLegends(player) : actions.openRanked(player)
          }
          style={styles.leagueTilePressable}
        >
          <PillSurface style={styles.leagueBlock}>
            <MobileWebImage
              imageUrl={
                String(image) ||
                (ranked
                  ? ImageAssets.getLeagueImage(String(name))
                  : ImageAssets.getBuilderBaseLeagueImage(String(name)))
              }
              style={styles.league}
            />
            <View style={styles.grow}>
              <CKText role="labelLarge" numberOfLines={1}>
                {String(name).replace(' League', '').trim() || t('generalUnranked')}
              </CKText>
              <View style={styles.leagueSubtitle}>
                <MobileWebImage
                  imageUrl={ranked ? ImageAssets.trophies : ImageAssets.builderBaseTrophy}
                  style={styles.leagueSubtitleIcon}
                />
                <CKText muted role="labelSmall">
                  {new Intl.NumberFormat(toIntlLocale(locale)).format(Number(trophies))}
                </CKText>
              </View>
            </View>
            {ranked ? <ChevronRight size={20} color={theme.onSurface} /> : null}
          </PillSurface>
        </Pressable>
      ))}
    </View>
  );
  const primaryQuickStats = [
    <QuickStat
      key="war-stars"
      label={t('playerWarStarsTitle')}
      value={player.warStars}
      icon={ImageAssets.attackStar}
    />,
    <QuickStat
      key="war-preference"
      label={t('playerWarPreferenceTitle')}
      value={player.warPreference === 'in' ? t('warStatusReady') : t('warStatusUnready')}
      icon={player.warPreferenceImage}
    />,
    <QuickStat
      key="donated"
      label={t('playerDonatedTitle')}
      value={player.donations}
      iconElement={<ArrowUp size={19} color={theme.onSurface} />}
    />,
    <QuickStat
      key="received"
      label={t('playerReceivedTitle')}
      value={player.donationsReceived}
      iconElement={<ArrowDown size={19} color={theme.onSurface} />}
    />,
  ];
  const secondaryQuickStats = [
    <QuickStat
      key="capital"
      label={t('playerCapitalTitle')}
      value={player.clanCapitalContributions}
      icon={ImageAssets.capitalGold}
    />,
    <QuickStat
      key="experience"
      label={t('playerExpLevelTitle')}
      value={player.expLevel}
      icon={ImageAssets.xp}
    />,
    <QuickStat
      key="best-trophies"
      label={t('playerBestTrophies')}
      value={player.bestTrophies}
      icon={ImageAssets.bestTrophies}
    />,
  ];
  return (
    <View
      testID={compact ? 'player-header-mobile' : 'player-header-desktop'}
      onLayout={({ nativeEvent: { layout } }) =>
        setHeaderSize((current) =>
          current.width === layout.width && current.height === layout.height
            ? current
            : { width: layout.width, height: layout.height },
        )
      }
      style={[
        styles.header,
        { paddingTop: safeTop },
        layout.isExpanded && {
          marginLeft: -insets.left,
          marginRight: -insets.right,
          minHeight: headerLayout.minHeight + safeTop,
        },
      ]}
    >
      <View testID="player-header-backdrop" pointerEvents="none" style={styles.headerBackdrop}>
        {/* All Player Info tabs share this artwork, including Builder Base. */}
        <HeaderArtwork
          testID="player-header-background-image"
          source={require('../../../../assets/clashking/backgrounds/player-electro-dragon-quiet-v3.webp')}
          style={StyleSheet.absoluteFill}
          contentFit="cover"
          contentPosition="center"
          transition={0}
          cachePolicy="memory-disk"
        />
        {/* Native image bounds follow rotation without a JS measurement frame. */}
        <HeroHeaderScrim variant="player" clipRailInset={layout.isExpanded} />
      </View>
      <View
        testID="player-header-content"
        style={[
          styles.headerContent,
          layout.isExpanded && {
            maxWidth: layout.contentMaxWidth + insets.left + insets.right,
            paddingLeft: insets.left,
            paddingRight: insets.right,
            paddingBottom: headerLayout.bottom,
          },
        ]}
      >
        <View
          style={[
            styles.headerActions,
            compact ? styles.headerActionsCompact : styles.headerActionsDesktop,
            layout.isExpanded && { paddingHorizontal: headerLayout.horizontal },
          ]}
        >
          <ProfileHeaderAction
            label={materialBackLabel(locale)}
            onPress={actions.goBack}
            icon={<ArrowLeft color="#fff" />}
          />
          <View style={styles.grow} />
          {!loading ? (
            <>
              {warAction ? (
                <ProfileHeaderAction
                  label={warAction.label}
                  onPress={warAction.onPress}
                  icon={<MobileWebImage imageUrl={warAction.image} style={styles.statIcon} />}
                />
              ) : null}
              {selectedTab === 'battles' ? (
                <ProfileHeaderAction
                  label={t('generalExport')}
                  onPress={onBattlelogExport ?? (() => undefined)}
                  icon={<Upload color="#fff" />}
                />
              ) : null}
              <ProfileHeaderAction
                label={t('gameAssetsShare')}
                appLinkShare
                onPress={() =>
                  void sharePageLink(
                    { kind: 'player', tag: player.tag, params: { tab: selectedTab } },
                    player.name,
                  ).catch(() => actions.showMessage(t('errorCannotOpenLink')))
                }
                icon={<Share2 color="#fff" />}
              />
              <ProfileHeaderAction
                label={t('playerOpenInGame')}
                onPress={() => actions.openInGame(player.tag)}
                icon={<ExternalLink color="#fff" />}
              />
              {model.bookmarked || !model.linkedAccount ? (
                <ProfileHeaderAction
                  label={model.bookmarked ? t('playerBookmarkRemove') : t('playerBookmarkAdd')}
                  onPress={() => void actions.toggleBookmark(player)}
                  icon={
                    model.bookmarked ? <BookmarkCheck color="#2F8CFF" /> : <Bookmark color="#fff" />
                  }
                />
              ) : null}
            </>
          ) : null}
        </View>
        <SkeletonContent loading={loading} style={{ display: 'contents' }}>
          <View
            style={[
              styles.identity,
              compact ? styles.identityCompact : styles.identityDesktop,
              layout.isExpanded && {
                gap: headerLayout.gap,
                paddingHorizontal: headerLayout.horizontal,
                minHeight: headerLayout.bodyMinHeight,
              },
            ]}
          >
            <View
              style={[
                styles.hallBadge,
                layout.isExpanded && { width: headerLayout.image, height: headerLayout.image },
              ]}
            >
              <MobileWebImage
                imageUrl={
                  selectedTab === 'builder'
                    ? ImageAssets.builderHall(player.builderHallLevel)
                    : player.townHallPic || ImageAssets.townHall(player.townHallLevel)
                }
                style={[
                  styles.hall,
                  compact && styles.hallCompact,
                  layout.isExpanded && { width: headerLayout.image, height: headerLayout.image },
                ]}
              />
              {selectedTab !== 'builder' && player.townHallWeaponLevel > 0 ? (
                <View
                  style={styles.weaponStars}
                  accessibilityLabel={`${player.townHallWeaponLevel} stars`}
                >
                  {Array.from({ length: player.townHallWeaponLevel }, (_, index) => (
                    <MobileWebImage
                      key={index}
                      imageUrl={ImageAssets.attackStar}
                      style={styles.weaponStar}
                    />
                  ))}
                </View>
              ) : null}
            </View>
            <View
              style={[
                styles.identityCopy,
                compact && styles.identityCopyCompact,
                compact && Platform.OS === 'web' && styles.identityCopyWeb,
              ]}
            >
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={`${player.name}. ${t('generalCopiedToClipboard')}`}
                testID="player-header-name-copy"
                onPress={copyPlayerTag}
              >
                <CKText
                  role="titleLarge"
                  numberOfLines={1}
                  style={[
                    styles.headerText,
                    compact && styles.centerText,
                    layout.isExpanded && {
                      fontSize: headerLayout.title,
                      lineHeight: headerLayout.titleLine,
                    },
                  ]}
                >
                  {player.name}
                </CKText>
              </Pressable>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={player.tag}
                onPress={copyPlayerTag}
              >
                <CKText role="labelLarge" style={styles.headerText}>
                  {player.tag}
                </CKText>
              </Pressable>
              {clan.tag ? (
                <Pressable
                  accessibilityRole="button"
                  onPress={() => actions.openClan(clan.tag)}
                  style={styles.clanLine}
                >
                  {clan.badgeUrl ? (
                    <MobileWebImage imageUrl={clan.badgeUrl} style={styles.clanBadge} />
                  ) : null}
                  <CKText numberOfLines={1} style={[styles.headerText, styles.clanIdentityText]}>
                    {clan.name}
                  </CKText>
                  {role ? (
                    <>
                      <CKText style={styles.clanDelimiter}>|</CKText>
                      <CKText
                        numberOfLines={1}
                        style={[styles.headerText, styles.clanIdentityText]}
                      >
                        {role}
                      </CKText>
                    </>
                  ) : null}
                  <ChevronRight size={18} color="#FFFFFFAD" />
                </Pressable>
              ) : (
                <CKText style={styles.headerText}>{role}</CKText>
              )}
            </View>
            {compact ? null : leagueTiles}
          </View>
          {compact ? (
            <View style={styles.mobileStats}>
              {leagueTiles}
              <View style={styles.mobileQuickStats}>
                <View testID="player-primary-quick-stats" style={styles.quickStatsRow}>
                  {primaryQuickStats}
                </View>
                <View testID="player-secondary-quick-stats" style={styles.quickStatsRow}>
                  {secondaryQuickStats}
                </View>
              </View>
            </View>
          ) : (
            <View style={styles.quickStats}>{[...primaryQuickStats, ...secondaryQuickStats]}</View>
          )}
        </SkeletonContent>
      </View>
    </View>
  );
}

function playerRoleLabel(role: string, t: ReturnType<typeof useI18n>['t']) {
  if (role === 'leader') return t('clanRoleLeader');
  if (role === 'coLeader') return t('clanRoleCoLeader');
  if (role === 'admin') return t('clanRoleElder');
  if (role === 'member') return t('clanRoleMember');
  return role;
}

export function playerHeaderClanIdentity(
  player: Player,
  cachedClanTag: string | null | undefined = '',
) {
  return playerProfileClanIdentity(player, cachedClanTag);
}

export function PlayerBaseTab({
  player,
  village,
}: {
  player: Player;
  village: 'home' | 'builder';
}) {
  const { t } = useI18n();
  const layout = useAdaptiveLayout();
  const sectionStyle = [styles.sections, layout.isExpanded && { maxWidth: layout.contentMaxWidth }];
  if (village === 'builder') {
    return (
      <View style={sectionStyle}>
        <ResponsiveGrid
          minItemWidth={layout.isExpanded ? 330 : 430}
          maxColumns={2}
          gap={layout.isExpanded ? 12 : undefined}
        >
          <PlayerItemSection
            title={t('gameHeroes')}
            items={player.bbHeroes}
            categoryIcon={trackerCategoryImage('heroes', UpgradeVillage.builderBase)}
            townHallLevel={player.builderHallLevel}
            initiallyExpanded
          />
          <PlayerItemSection
            title={t('gameTroops')}
            items={player.bbTroops}
            categoryIcon={ImageAssets.upgradeCategoryIcons.troops}
            townHallLevel={player.builderHallLevel}
            initiallyExpanded
          />
        </ResponsiveGrid>
      </View>
    );
  }
  return (
    <View style={sectionStyle}>
      <ResponsiveGrid
        minItemWidth={layout.isExpanded ? 330 : 430}
        maxColumns={2}
        gap={layout.isExpanded ? 12 : undefined}
      >
        {player.superTroops.some((item) => item.isActive) ? (
          <PlayerSuperTroopSection
            title={t('gameActiveSuperTroops')}
            items={player.superTroops.filter((item) => item.isActive)}
          />
        ) : null}
        <PlayerItemSection
          title={t('gameHeroes')}
          items={player.heroes}
          categoryIcon={ImageAssets.upgradeCategoryIcons.heroes}
          townHallLevel={player.townHallLevel}
          initiallyExpanded
        />
        <PlayerItemSection
          title={t('gameEquipment')}
          items={player.equipments}
          categoryIcon={trackerCategoryImage('equipment', UpgradeVillage.home)}
          townHallLevel={player.townHallLevel}
          initiallyExpanded
        />
        <PlayerItemSection
          title={t('gameTroops')}
          items={player.troops}
          categoryIcon={ImageAssets.upgradeCategoryIcons.troops}
          townHallLevel={player.townHallLevel}
        />
        <PlayerItemSection
          title={t('gameSpells')}
          items={player.spells}
          categoryIcon={ImageAssets.upgradeCategoryIcons.spells}
          townHallLevel={player.townHallLevel}
        />
        <PlayerItemSection
          title={t('gameSiegeMachines')}
          items={player.siegeMachines}
          categoryIcon={ImageAssets.upgradeCategoryIcons.siege}
          townHallLevel={player.townHallLevel}
        />
        <PlayerItemSection
          title={t('gamePets')}
          items={player.pets}
          categoryIcon={ImageAssets.upgradeCategoryIcons.pets}
          townHallLevel={player.townHallLevel}
        />
      </ResponsiveGrid>
    </View>
  );
}

function PlayerSuperTroopSection({
  title,
  items,
}: {
  title: string;
  items: readonly PlayerItem[];
}) {
  const theme = useCKTheme();
  return (
    <Surface radius={16} style={styles.section}>
      <CKText role="titleMedium" style={styles.centerText}>
        {title}
      </CKText>
      <View style={[styles.wrap, styles.centeredWrap]}>
        {items.map((item) => (
          <View
            key={item.name}
            accessible
            accessibilityLabel={localizedNameForItem(item.meta) || item.name}
          >
            <MobileWebImage
              imageUrl={item.imageUrl}
              style={styles.superTroopImage}
              contentFit="cover"
              errorFallback={<CircleAlert color={theme.onSurfaceVariant} />}
            />
          </View>
        ))}
      </View>
    </Surface>
  );
}

export function PlayerItemSection({
  title,
  items,
  categoryIcon,
  townHallLevel,
  initiallyExpanded = false,
}: {
  title: string;
  items: readonly PlayerItem[];
  categoryIcon?: string;
  townHallLevel: number;
  initiallyExpanded?: boolean;
}) {
  const { t, locale } = useI18n();
  const [expanded, setExpanded] = useState(initiallyExpanded);
  const [selected, setSelected] = useState<PlayerItem | null>(null);
  const theme = useCKTheme();
  const visible = useMemo(
    () =>
      items
        .filter((item) => maxLevelForItemAtTH(item, townHallLevel) > 0)
        .sort((a, b) => Number(b.isUnlocked) - Number(a.isUnlocked)),
    [items, townHallLevel],
  );
  const maxLevels = visible.reduce(
    (sum, item) => sum + maxLevelForItemAtTH(item, townHallLevel),
    0,
  );
  const progress = maxLevels
    ? (visible.reduce(
        (sum, item) =>
          sum + Math.min(Math.max(0, item.level), maxLevelForItemAtTH(item, townHallLevel)),
        0,
      ) /
        maxLevels) *
      100
    : 0;
  const levelsRemaining = visible.reduce(
    (sum, item) =>
      sum + Math.max(0, maxLevelForItemAtTH(item, townHallLevel) - Math.max(0, item.level)),
    0,
  );
  const summary = visible.reduce(
    (result, item) => {
      const remaining = calculateRemainingUpgradeSummary(
        item,
        maxLevelForItemAtTH(item, townHallLevel),
      );
      result.seconds += remaining.seconds;
      for (const resource of remaining.resources)
        result.resources.set(
          resource.key,
          (result.resources.get(resource.key) ?? 0) + resource.amount,
        );
      return result;
    },
    { seconds: 0, resources: new Map<string, number>() },
  );
  if (!visible.length) return null;
  return (
    <>
      <ExpandableProgressCard
        title={title}
        imageUrl={categoryIcon ?? items[0]!.imageUrl}
        percent={progress}
        open={expanded}
        onToggle={() => setExpanded((value) => !value)}
        footer={
          <View
            style={{
              flexDirection: 'row',
              alignItems: 'center',
              gap: 6,
              flexWrap: 'nowrap',
              width: '100%',
            }}
          >
            <CKText role="bodySmall" muted numberOfLines={1} style={{ flexShrink: 1 }}>
              {levelsRemaining === 0
                ? t('homeRecentlyCompleted')
                : t('gameItemLevelCount', { count: levelsRemaining })}
            </CKText>
            {levelsRemaining > 0 && summary.seconds > 0 ? (
              <CKText role="bodySmall" muted numberOfLines={1} style={{ flexShrink: 1 }}>
                · {formatUpgradeDuration(summary.seconds)}
              </CKText>
            ) : null}
            {[...summary.resources]
              .filter(([, amount]) => amount > 0)
              .map(([resource, amount]) => (
                <View
                  key={resource}
                  style={{ flexDirection: 'row', alignItems: 'center', gap: 3, flexShrink: 1 }}
                >
                  <MobileWebImage
                    imageUrl={resourceImage(resource)}
                    style={{ width: 15, height: 15 }}
                  />
                  <CKText role="bodySmall" numberOfLines={1} style={{ flexShrink: 1 }}>
                    {formatPlayerResourceAmount(amount, locale)}
                  </CKText>
                </View>
              ))}
          </View>
        }
      >
        <ResponsiveGrid
          minItemWidth={54}
          maxColumns={10}
          gap={8}
          waitForLayout
          testID="player-item-grid"
        >
          {visible.map((item, index) => {
            const thMax = maxLevelForItemAtTH(item, townHallLevel);
            const isGlobalMax = item.maxLevel > 0 && item.level >= item.maxLevel;
            const isTownHallMax = thMax > 0 && item.level >= thMax;
            return (
              <Pressable
                key={`${item.name}-${index}`}
                accessibilityRole="button"
                accessibilityLabel={
                  item instanceof PlayerSuperTroop
                    ? item.name
                    : `${item.name}, ${t('gameLevel', { level: item.level, maxLevel: thMax })}`
                }
                onPress={() => setSelected(item)}
              >
                <View
                  style={[
                    styles.itemTile,
                    item.type === 'equipment' &&
                      item.isUnlocked && {
                        backgroundColor:
                          String(item.meta?.rarity ?? item.meta?.rarity_label) === '2' ||
                          String(item.meta?.rarity_label).toLowerCase() === 'epic'
                            ? '#800080'
                            : '#1565C0',
                      },
                    (!item.isUnlocked || item.level === 0) && styles.locked,
                    {
                      borderColor:
                        !item.isUnlocked || item.level === 0
                          ? '#808080'
                          : isGlobalMax
                            ? '#FFD75E'
                            : isTownHallMax
                              ? '#CD7F32'
                              : theme.onSurface,
                    },
                  ]}
                >
                  <MobileWebImage
                    imageUrl={item.imageUrl}
                    style={styles.itemImage}
                    contentFit="cover"
                  />
                  {!(item instanceof PlayerSuperTroop) && item.isUnlocked && item.level > 0 ? (
                    <PillSurface style={styles.itemLevelPill}>
                      <CKText role="labelSmall">{item.level}</CKText>
                    </PillSurface>
                  ) : null}
                </View>
              </Pressable>
            );
          })}
        </ResponsiveGrid>
      </ExpandableProgressCard>
      {selected instanceof PlayerSuperTroop ? (
        <ItemDetailModal item={selected} onClose={() => setSelected(null)} />
      ) : (
        <UpgradeItemDetailModal
          key={selected ? `${selected.name}-${selected.level}` : 'empty'}
          item={
            selected
              ? upgradeDetailsItem(selected, maxLevelForItemAtTH(selected, townHallLevel))
              : null
          }
          snapshot={upgradeDetailsSnapshot(selected, townHallLevel)}
          onClose={() => setSelected(null)}
        />
      )}
    </>
  );
}

function PlayerModalViewport({ children }: { children: ReactNode }) {
  const layout = useAdaptiveLayout();
  if (!layout.isDuo && !layout.isTablet) return <>{children}</>;
  // Tint belongs to the full modal window; only the content respects safe areas.
  // Moving the whole backdrop into SafeAreaView leaves untinted strips at the rail.
  const backdrop = isValidElement<{ style?: StyleProp<ViewStyle> }>(children)
    ? StyleSheet.flatten(children.props.style)?.backgroundColor
    : undefined;
  const content = isValidElement<{ style?: StyleProp<ViewStyle> }>(children)
    ? cloneElement(children, { style: [children.props.style, { backgroundColor: 'transparent' }] })
    : children;
  return (
    <SafeAreaProvider style={{ flex: 1, backgroundColor: backdrop }}>
      <SafeAreaView style={{ flex: 1 }}>{content}</SafeAreaView>
    </SafeAreaProvider>
  );
}

function ItemDetailModal({ item, onClose }: { item: PlayerItem | null; onClose: () => void }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const localizedName = item ? localizedNameForItem(item.meta) || item.name : '';
  const localizedDescription = item ? localizedInfoForItem(item.meta) : '';
  return (
    <Modal
      supportedOrientations={modalOrientations}
      transparent
      visible={item !== null}
      animationType="fade"
      onRequestClose={onClose}
    >
      <PlayerModalViewport>
        <View style={styles.overlay}>
          <Pressable
            accessible={false}
            onPress={onClose}
            style={StyleSheet.absoluteFill}
            testID="player-item-detail-backdrop"
          />
          {item ? (
            <Surface
              accessibilityViewIsModal
              onAccessibilityEscape={onClose}
              radius={ckRadius.card}
              style={styles.dialog}
              testID="player-item-detail-dialog"
            >
              <View style={styles.dialogTitle}>
                <MobileWebImage imageUrl={item.imageUrl} style={styles.detailImage} />
                <View style={styles.grow}>
                  <CKText role="titleLarge">{localizedName}</CKText>
                  <CKText muted>
                    {item instanceof PlayerSuperTroop && item.superTroopIsActive
                      ? t('generalActive')
                      : t('generalInactive')}
                  </CKText>
                </View>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={t('generalOk')}
                  onPress={onClose}
                >
                  <X color={theme.onSurfaceVariant} />
                </Pressable>
              </View>
              {localizedDescription ? (
                <>
                  <CKText skeleton={false} role="rowTitle">
                    {t('gameItemOverview')}
                  </CKText>
                  <CKText muted>{localizedDescription}</CKText>
                </>
              ) : null}
            </Surface>
          ) : null}
        </View>
      </PlayerModalViewport>
    </Modal>
  );
}

export function formatPlayerResourceAmount(value: number, locale: string) {
  const suffix = (amount: number, unit: string) =>
    `${amount.toFixed(1).replace(/\.0$/, '')}${unit}`;
  if (Math.abs(value) >= 1e9) return suffix(value / 1e9, 'B');
  if (Math.abs(value) >= 1e6) return suffix(value / 1e6, 'M');
  if (Math.abs(value) >= 1e3) return suffix(value / 1e3, 'K');
  return new Intl.NumberFormat(toIntlLocale(locale)).format(Math.round(value));
}
function compactNumber(value: number, locale: string) {
  return formatPlayerResourceAmount(value, locale);
}
function resourceImage(key: string) {
  return `${ImageAssets.baseUrl}/resources/${key}.webp`;
}

export function PlayerBattlelogTab({
  data,
  visibleCount = 20,
  onLootGridScrubChange,
}: {
  data: PlayerBattlelogData | null | undefined;
  visibleCount?: number;
  onLootGridScrubChange?: (active: boolean) => void;
}) {
  const { t, locale } = useI18n();
  const layout = useAdaptiveLayout();
  const mode = 'farming';
  const attacks = useMemo(() => data?.forMode(mode).filter((item) => item.attack) ?? [], [data]);
  const lootTimeline = useMemo(() => battlelogLootTimeline(attacks, new Date(), 180), [attacks]);
  if (!data)
    return <EmptyState title={t('playerBattlelogLoadError')} body={t('generalNoDataAvailable')} />;
  const averageStars = attacks.length
    ? attacks.reduce((sum, item) => sum + item.stars, 0) / attacks.length
    : 0;
  const averageDestruction = attacks.length
    ? attacks.reduce((sum, item) => sum + item.destructionPercentage, 0) / attacks.length
    : 0;
  const averageLoot = attacks.length
    ? attacks.reduce((sum, item) => sum + item.totalLoot, 0) / attacks.length
    : 0;
  const popularAttacks = data.popularTroops(mode, { limit: 5, weightByHousing: true });
  return (
    <ChartInteractionBoundary>
      <View style={[styles.sections, layout.isExpanded && { maxWidth: layout.contentMaxWidth }]}>
        <Surface radius={ckRadius.card} style={styles.section}>
          <BattleOverviewBand
            title={t('warAttacksTitle')}
            image={ImageAssets.sword}
            metrics={[
              [ImageAssets.attacksNoShield, t('generalTotal'), `${attacks.length}`],
              [ImageAssets.attackStar, t('warAbbreviationAvg'), averageStars.toFixed(2)],
              [
                ImageAssets.hitrate,
                t('warAbbreviationAvgPercentage'),
                `${averageDestruction.toFixed(1)}%`,
              ],
              [
                ImageAssets.lootCart,
                t('generalAverage'),
                compactNumber(Math.round(averageLoot), locale),
              ],
            ]}
            popular={popularAttacks}
          />
          <BattlelogLootGrid
            timeline={lootTimeline}
            locale={locale}
            onScrubActiveChange={onLootGridScrubChange}
          />
        </Surface>
        <View style={styles.toolbar}>
          <CKText skeleton={false} role="titleLarge" style={styles.grow}>
            {t('playerBattlelogRecentBattles')}
          </CKText>
        </View>
        <View testID="battle-responsive-grid">
          <ResponsiveGrid minItemWidth={layout.isExpanded ? 330 : 430} maxColumns={2}>
            {attacks.slice(0, visibleCount).map((item, index) => (
              <BattleRow key={`${item.mergeKey}-${index}`} item={item} />
            ))}
          </ResponsiveGrid>
        </View>
        {!attacks.length ? (
          <EmptyState
            title={t('playerBattlelogNoBattlesTitle')}
            body={t('playerBattlelogNoBattlesBody')}
          />
        ) : null}
      </View>
    </ChartInteractionBoundary>
  );
}

export function lootGridIndexAtPoint(
  x: number,
  y: number,
  width: number,
  columns: number,
): number | null {
  if (![x, y, width, columns].every(Number.isFinite) || columns < 1 || !Number.isInteger(columns))
    return null;
  const cell = (width - (columns - 1) * 3) / columns;
  if (cell <= 0 || x < 0 || x > width || y < 0 || y > 7 * (cell + 3) - 3) return null;
  return (
    Math.min(columns - 1, Math.floor(x / (cell + 3))) * 7 + Math.min(6, Math.floor(y / (cell + 3)))
  );
}

function BattlelogLootGrid({
  timeline,
  locale,
  onScrubActiveChange,
}: {
  timeline: readonly BattlelogLootDay[];
  locale: string;
  onScrubActiveChange?: (active: boolean) => void;
}) {
  const { t, isRtl } = useI18n();
  const theme = useCKTheme();
  const [gridMode, setGridMode] = useState<'daily' | 'weekly' | 'cumulative'>('daily');
  const [selected, setSelected] = useState<{ day: string; total: number; index: number } | null>(
    null,
  );
  const clearSelection = useCallback(() => setSelected(null), []);
  useChartDismissal(clearSelection);
  const gridRef = useRef<ViewInstance>(null);
  const origin = useRef({ x: 0, y: 0 });
  const [gridWidth, setGridWidth] = useState(0);
  const weeks = useMemo(() => battlelogLootWeeks(timeline), [timeline]);
  const padded = useMemo(() => {
    const offset = new Date(`${timeline[0]!.day}T00:00:00Z`).getUTCDay();
    const days: (BattlelogLootDay | null)[] = [...Array<null>(offset).fill(null), ...timeline];
    while (days.length % 7) days.push(null);
    return days;
  }, [timeline]);
  const columnCount = padded.length / 7;
  const columns = Array.from({ length: padded.length / 7 }, (_, index) =>
    padded.slice(index * 7, index * 7 + 7),
  );
  const cellSize = Math.max(0, (gridWidth - (columns.length - 1) * 3) / columns.length);
  const weekValues = weeks.map((week) => (gridMode === 'weekly' ? week.total : week.cumulative));
  const weekMaximum = Math.max(1, ...weekValues);
  const selectIndex = useCallback(
    (index: number) => {
      if (gridMode === 'daily') {
        const day = padded[index];
        if (day)
          setSelected((current) =>
            current?.day === day.day ? current : { day: day.day, total: day.total, index },
          );
        return;
      }
      const column = Math.floor(index / 7);
      const week = weeks[column];
      if (!week) return;
      const total = gridMode === 'weekly' ? week.total : week.cumulative;
      setSelected((current) =>
        current?.index === column * 7 + 3
          ? current
          : { day: week.day, total, index: column * 7 + 3 },
      );
    },
    [gridMode, padded, weeks],
  );
  const selectPoint = useCallback(
    (pageX: number, pageY: number) => {
      const index = lootGridIndexAtPoint(
        pageX - origin.current.x,
        pageY - origin.current.y,
        gridWidth,
        columnCount,
      );
      if (index !== null) selectIndex(index);
    },
    [gridWidth, columnCount, selectIndex],
  );
  const beginTouch = useCallback(
    (pageX: number, pageY: number) => {
      gridRef.current?.measureInWindow((x, y) => {
        origin.current = { x, y };
        selectPoint(pageX, pageY);
      });
    },
    [selectPoint],
  );
  const finishScrub = useCallback(() => onScrubActiveChange?.(false), [onScrubActiveChange]);
  // Keep the active responder alive when moving to another day updates the tooltip.
  const responder = useMemo(
    () =>
      // PanResponder stores these callbacks; refs are read only when a touch invokes them.
      // eslint-disable-next-line react-hooks/refs
      PanResponder.create({
        // A touch inside the grid is a 2D scrub, including vertical movement between days.
        // Own it from touch-down so the parent scroll view cannot begin scrolling first.
        onStartShouldSetPanResponder: () => true,
        onStartShouldSetPanResponderCapture: () => true,
        onMoveShouldSetPanResponder: () => true,
        onPanResponderGrant: (event) => {
          onScrubActiveChange?.(true);
          beginTouch(event.nativeEvent.pageX, event.nativeEvent.pageY);
        },
        onPanResponderMove: (event) =>
          selectPoint(event.nativeEvent.pageX, event.nativeEvent.pageY),
        onPanResponderRelease: finishScrub,
        onPanResponderTerminationRequest: () => false,
        onShouldBlockNativeResponder: () => true,
        onPanResponderTerminate: () => {
          finishScrub();
          clearSelection();
        },
      }),
    [beginTouch, selectPoint, clearSelection, finishScrub, onScrubActiveChange],
  );
  const selectedIndex = selected?.index ?? -1;
  const selectedRow = selectedIndex % 7;
  return (
    <View testID="battlelog-loot-grid" style={styles.sections}>
      <SlidingSegmentControl
        testID="battlelog-loot-mode"
        value={gridMode}
        options={[
          { value: 'daily', label: t('statsDaily') },
          { value: 'weekly', label: t('statsWeekly') },
          { value: 'cumulative', label: t('playerBattlelogCumulative') },
        ]}
        isRtl={isRtl}
        onChange={(key) => {
          setSelected(null);
          setGridMode(key);
        }}
      />
      <View style={styles.lootContributionCard}>
        <View
          ref={gridRef}
          testID="loot-grid-touch-area"
          style={styles.lootContributionGrid}
          {...responder.panHandlers}
          onLayout={(event) => setGridWidth(event.nativeEvent.layout.width)}
          onTouchStart={(event) => {
            onScrubActiveChange?.(true);
            beginTouch(event.nativeEvent.pageX, event.nativeEvent.pageY);
          }}
          onTouchEnd={finishScrub}
          onTouchCancel={() => {
            finishScrub();
            clearSelection();
          }}
          onAccessibilityEscape={clearSelection}
        >
          {columns.map((column, columnIndex) =>
            gridMode === 'daily' ? (
              <View key={columnIndex} style={styles.lootContributionColumn}>
                {column.map((day, rowIndex) =>
                  day ? (
                    <Pressable
                      accessibilityRole="button"
                      accessibilityLabel={`${day.day}: ${day.total}`}
                      key={day.day}
                      onPress={() => selectIndex(columnIndex * 7 + rowIndex)}
                      onHoverIn={() => selectIndex(columnIndex * 7 + rowIndex)}
                      accessibilityState={{
                        selected: selectedIndex === columnIndex * 7 + rowIndex,
                      }}
                      style={[
                        styles.lootContributionCell,
                        selectedIndex === columnIndex * 7 + rowIndex && {
                          borderWidth: 1.5,
                          borderColor: theme.onSurface,
                        },
                        {
                          backgroundColor:
                            day.total > 0
                              ? colorWithAlpha(theme.primary, 0.25 + day.intensity * 0.75)
                              : colorWithAlpha(theme.surfaceContainerHighest, 0.45),
                        },
                      ]}
                    />
                  ) : (
                    <View key={`empty-${rowIndex}`} style={styles.lootContributionCell} />
                  ),
                )}
              </View>
            ) : (
              <Pressable
                key={columnIndex}
                accessibilityRole="button"
                accessibilityLabel={`${weeks[columnIndex]?.day}: ${weekValues[columnIndex] ?? 0}`}
                accessibilityState={{ selected: Math.floor(selectedIndex / 7) === columnIndex }}
                onPress={() => selectIndex(columnIndex * 7 + 3)}
                onHoverIn={() => selectIndex(columnIndex * 7 + 3)}
                style={styles.lootContributionColumn}
              >
                {Array.from({ length: 7 }, (_, rowIndex) => {
                  const value = weekValues[columnIndex] ?? 0;
                  const filled = value > 0 && rowIndex >= 7 - Math.ceil((value / weekMaximum) * 7);
                  return (
                    <View
                      key={rowIndex}
                      style={[
                        styles.lootContributionCell,
                        Math.floor(selectedIndex / 7) === columnIndex && {
                          borderWidth: 1,
                          borderColor: theme.onSurface,
                        },
                        {
                          backgroundColor: filled
                            ? colorWithAlpha(theme.primary, 0.25 + (value / weekMaximum) * 0.75)
                            : colorWithAlpha(theme.surfaceContainerHighest, 0.45),
                        },
                      ]}
                    />
                  );
                })}
              </Pressable>
            ),
          )}
        </View>
        {selected ? (
          <View
            testID="loot-grid-tooltip"
            pointerEvents="none"
            style={[
              styles.lootTooltip,
              {
                backgroundColor: theme.surfaceContainerHighest,
                left: Math.max(
                  0,
                  Math.min(
                    Math.max(0, gridWidth - 240),
                    Math.floor(selectedIndex / 7) * (cellSize + 3) - 120,
                  ),
                ),
                top:
                  selectedRow < 3
                    ? (selectedRow + 1) * (cellSize + 3) + 4
                    : selectedRow * (cellSize + 3) - 38,
              },
            ]}
          >
            <CKText role="labelLarge" numberOfLines={2}>
              {formatPlayerResourceAmount(selected.total, locale)} ·{' '}
              {gridMode === 'weekly'
                ? `${t('statsWeekly')} · `
                : gridMode === 'cumulative'
                  ? `${t('playerBattlelogCumulative')} · `
                  : ''}
              {new Intl.DateTimeFormat(toIntlLocale(locale), {
                month: 'short',
                day: 'numeric',
                year: 'numeric',
                timeZone: 'UTC',
              }).format(new Date(selected.day + 'T00:00:00Z'))}
            </CKText>
          </View>
        ) : null}
        <View style={styles.lootContributionGrid}>
          {columns.map((column, index) => {
            const first = column.find((day) => day !== null);
            const monthStart = column.find((day) => day?.day.endsWith('-01'));
            const label = monthStart ?? (index === 0 ? first : null);
            return (
              <View key={index} style={styles.lootContributionColumn}>
                {label ? (
                  <CKText muted role="labelSmall" style={styles.lootMonthLabel}>
                    {new Intl.DateTimeFormat(toIntlLocale(locale), {
                      month: 'short',
                      timeZone: 'UTC',
                    }).format(new Date(`${label.day}T00:00:00Z`))}
                  </CKText>
                ) : null}
              </View>
            );
          })}
        </View>
      </View>
    </View>
  );
}

function BattleRow({ item }: { item: PlayerBattlelogEntry }) {
  const { t, locale } = useI18n();
  const army = Object.entries(item.armyCounts).slice(0, 6);
  return (
    <Surface testID="farming-battle-row" radius={ckRadius.tile} style={styles.battleCard}>
      <View style={styles.row}>
        <View style={styles.grow}>
          {item.timestamp ? (
            <CKText muted role="labelLarge">
              {new Intl.DateTimeFormat(toIntlLocale(locale), {
                dateStyle: 'medium',
                timeStyle: 'short',
              }).format(item.timestamp)}
            </CKText>
          ) : null}
        </View>
        <MobileWebImage
          imageUrl={item.attack ? ImageAssets.sword : ImageAssets.shieldWithArrow}
          style={styles.directionImage}
        />
      </View>
      <View style={[styles.wrap, styles.battleResult]}>
        <View style={styles.row}>
          {[0, 1, 2].map((index) => (
            <MobileWebImage
              key={index}
              imageUrl={index < item.stars ? ImageAssets.attackStar : ImageAssets.emptyStar}
              style={styles.starImage}
            />
          ))}
          <CKText role="rowTitle">{item.destructionPercentage}%</CKText>
        </View>
        {item.attack ? (
          <View style={styles.wrap}>
            {[
              [ImageAssets.gold, t('resourceGold'), item.gold],
              [ImageAssets.elixir, t('resourceElixir'), item.elixir],
              [ImageAssets.darkElixir, t('resourceDarkElixir'), item.darkElixir],
            ].map(([image, label, value]) =>
              Number(value) > 0 ? (
                <View
                  key={String(label)}
                  accessible
                  accessibilityLabel={`${label}: ${value}`}
                  style={styles.lootValue}
                >
                  <MobileWebImage imageUrl={String(image)} style={styles.resourceIcon} />
                  <CKText role="labelSmall">{compactNumber(Number(value), locale)}</CKText>
                </View>
              ) : null,
            )}
          </View>
        ) : null}
      </View>
      {army.length ? (
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <View style={styles.wrap}>
            {army.map(([code, count]) => {
              const resolved = PlayerBattlelogArmyCatalog.resolve(code);
              return (
                <View
                  key={code}
                  accessible
                  accessibilityLabel={`${count} ${resolved.name}`}
                  style={styles.armyItem}
                >
                  <MobileWebImage
                    imageUrl={resolved.imageUrl}
                    style={styles.armyImage}
                    contentFit="cover"
                  />
                  <PillSurface style={styles.armyCount}>
                    <CKText role="labelSmall">×{count}</CKText>
                  </PillSurface>
                </View>
              );
            })}
          </View>
        </ScrollView>
      ) : null}
    </Surface>
  );
}

function BattleOverviewBand({
  title,
  image,
  metrics,
  popular,
}: {
  title: string;
  image: string;
  metrics: readonly (readonly [string, string, string])[];
  popular: readonly PlayerPopularArmyItem[];
}) {
  const { t } = useI18n();
  const layout = useAdaptiveLayout();
  return (
    <View style={styles.battleOverviewBand}>
      <View style={styles.battleBandTitle}>
        <MobileWebImage skeleton={false} imageUrl={image} style={styles.battleBandIcon} />
        <CKText skeleton={false} role="labelLarge">
          {title}
        </CKText>
      </View>
      <View style={styles.battleMetricRow}>
        {metrics.map(([metricImage, label, value]) => (
          <View
            key={`${label}-${value}`}
            accessible
            accessibilityLabel={`${label}: ${value}`}
            style={styles.battleMetric}
          >
            <MobileWebImage
              skeleton={false}
              imageUrl={metricImage}
              style={styles.battleMetricIcon}
            />
            <CKText skeleton={false} muted role="labelSmall" numberOfLines={1}>
              {label}
            </CKText>
            <CKText role="rowTitle" numberOfLines={1}>
              {value}
            </CKText>
          </View>
        ))}
      </View>
      {popular.length ? (
        <>
          <CKText skeleton={false} muted role="labelSmall" style={styles.centerText}>
            {t('playerBattlelogPopularTroops')}
          </CKText>
          <View style={styles.popularTroopRow}>
            {popular.slice(0, 5).map((entry) => {
              const content = (
                <>
                  <MobileWebImage imageUrl={entry.item.imageUrl} style={styles.popularTroopImage} />
                  <PillSurface style={styles.popularCount}>
                    <CKText role="labelSmall">×{entry.uses}</CKText>
                  </PillSurface>
                </>
              );
              return (
                <View
                  key={entry.item.code}
                  accessible
                  accessibilityLabel={`${entry.item.name}, ×${entry.uses}`}
                  style={styles.popularTroop}
                >
                  {layout.isExpanded ? (
                    <View style={styles.popularTroopVisual}>{content}</View>
                  ) : (
                    content
                  )}
                </View>
              );
            })}
          </View>
        </>
      ) : null}
    </View>
  );
}

export function PlayerActivityTab({
  data,
  actions,
}: {
  data: PlayerActivityFeed | null | undefined;
  actions: PlayerDetailPresentationActions;
}) {
  const { t } = useI18n();
  const layout = useAdaptiveLayout();
  const [filter, setFilter] = useState<PlayerHistoryTypeValue>('troop_level');
  if (!data) return <EmptyState title={t('playerActivityLoadError')} body={t('generalTryAgain')} />;
  const choices: readonly (readonly [PlayerHistoryTypeValue, string])[] = [
    ['troop_level', t('gameTroops')],
    ['super_troop_boost', t('gameActiveSuperTroops')],
    ['hero_level', t('gameHeroes')],
    ['spell_level', t('gameSpells')],
    ['pet_level', t('gamePets')],
    ['equipment_level', t('gameEquipment')],
    ['townhall_level', t('gameTownHallLevel')],
    ['exp_level', t('gameExpLevel')],
    ['best_trophies', t('playerBestTrophies')],
    ['best_builder_base_trophies', `${t('playerBestTrophies')} · ${t('gameBaseBuilder')}`],
    ['war_preference', t('playerWarPreferenceTitle')],
  ];
  return (
    <View style={[styles.sections, layout.isExpanded && { maxWidth: layout.contentMaxWidth }]}>
      <View
        testID="player-history-category-filter"
        style={[
          styles.toolbar,
          layout.isExpanded ? styles.historyToolbar : styles.compactHistoryToolbar,
        ]}
      >
        <FilterDropdown
          fillWidth
          choices={choices}
          value={filter}
          onSelect={(value) => {
            const next = value as PlayerHistoryTypeValue;
            setFilter(next);
            void actions.loadActivity(next);
          }}
        />
      </View>
      <View testID="activity-responsive-grid">
        <ResponsiveGrid minItemWidth={430} maxColumns={2}>
          {data.items.map((item, index) => (
            <ActivityRow key={`${item.time.toISOString()}-${index}`} item={item} />
          ))}
        </ResponsiveGrid>
      </View>
      {!data.items.length ? (
        <EmptyState
          title={t('playerActivityNoEventsTitle')}
          body={t('playerActivityNoEventsBody')}
        />
      ) : null}
    </View>
  );
}

function ActivityRow({ item }: { item: PlayerActivityEvent }) {
  const { t, locale } = useI18n();
  const image = activityImage(item);
  const detail = activityDetail(item, t);
  return (
    <Surface radius={ckRadius.tile} style={styles.rowCard}>
      <MobileWebImage imageUrl={image} style={styles.rowImage} />
      <View style={styles.grow}>
        <CKText role="rowTitle">{activityTitle(item, t)}</CKText>
        {detail ? <CKText style={{ color: activityAccent(item) }}>{detail}</CKText> : null}
        <CKText muted role="labelSmall">
          {new Intl.DateTimeFormat(toIntlLocale(locale), { dateStyle: 'medium' }).format(item.time)}{' '}
          ·{' '}
          {new Intl.DateTimeFormat(toIntlLocale(locale), { timeStyle: 'short' }).format(item.time)}
        </CKText>
      </View>
    </Surface>
  );
}

export function PlayerCwlTab({
  data,
}: {
  data: PlayerCwlHistory | null | undefined;
  actions: PlayerDetailPresentationActions;
}) {
  const { t } = useI18n();
  const layout = useAdaptiveLayout();
  if (!data?.items.length)
    return <EmptyState title={t('cwlHistoryEmptyTitle')} body={t('generalNoDataAvailable')} />;
  const cards = data.items.map((season, index) => (
    <CwlSeasonCard
      key={`${season.season}-${season.clan.tag}-${index}`}
      recordId={`${season.season}-${index}`}
      season={season}
    />
  ));
  return (
    <View style={[styles.sections, layout.isExpanded && { maxWidth: layout.contentMaxWidth }]}>
      {layout.isDuo || layout.isTablet ? (
        <ResponsiveGrid minItemWidth={330} maxColumns={layout.isExpanded ? 2 : 1} gap={10}>
          {cards}
        </ResponsiveGrid>
      ) : (
        cards
      )}
    </View>
  );
}

function CwlSeasonCard({ season, recordId }: { season: PlayerCwlSeason; recordId: string }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState(false);
  const participantOnly = season.attacks.length === 0 && season.missedAttacks === 0;
  const month = formatPlayerCwlSeason(season.season, locale);
  return (
    <Surface radius={ckRadius.card} style={styles.cwlCard}>
      <Pressable
        testID={`cwl-season-${recordId}`}
        accessibilityRole="button"
        accessibilityState={{
          expanded: participantOnly ? undefined : expanded,
          disabled: participantOnly,
        }}
        disabled={participantOnly}
        onPress={() => setExpanded((value) => !value)}
      >
        <View style={styles.cwlHeader}>
          <MobileWebImage
            imageUrl={ImageAssets.townHall(season.townHallLevel)}
            style={styles.cwlTownHallLeading}
          />
          <View style={styles.grow}>
            <View style={styles.cwlTitleRow}>
              <MobileWebImage imageUrl={season.clan.badgeUrl} style={styles.cwlClanBadge} />
              <CKText role="rowTitle" numberOfLines={1} style={styles.grow}>
                {season.clan.name}
              </CKText>
            </View>
            <View style={styles.cwlLeagueRow}>
              <MobileWebImage
                imageUrl={ImageAssets.getWarLeagueImage(season.clan.leagueName)}
                style={styles.cwlLeague}
              />
              <CKText role="metadata" numberOfLines={1} style={styles.grow}>
                {season.clan.leagueName}
              </CKText>
            </View>
          </View>
          <View testID={`cwl-season-summary-${recordId}`} style={styles.cwlTrailing}>
            <CKText muted role="labelSmall" style={styles.cwlSeasonDate}>
              {month}
            </CKText>
            {participantOnly ? (
              <PillSurface style={styles.cwlParticipant}>
                <UserRound size={14} color={theme.onSurfaceVariant} />
                <CKText role="labelSmall">{t('cwlParticipantOnly')}</CKText>
              </PillSurface>
            ) : (
              <View style={styles.cwlActionRow}>
                <View testID={`cwl-season-stars-${recordId}`} style={styles.cwlStars}>
                  <MobileWebImage imageUrl={ImageAssets.attackStar} style={styles.cwlStarIcon} />
                  <CKText role="titleMedium" style={styles.cwlStarValue}>
                    {season.stars}
                  </CKText>
                </View>
                <ChevronRight
                  size={22}
                  color={theme.onSurfaceVariant}
                  style={{ transform: [{ rotate: expanded ? '90deg' : '0deg' }] }}
                />
              </View>
            )}
          </View>
        </View>
      </Pressable>
      {expanded ? (
        <View style={styles.cwlBody}>
          <View style={styles.detailMetrics}>
            <Metric label={t('warStarsTitle')} value={`${season.stars}`} />
            <Metric label={t('warAttacksTitle')} value={`${season.attacks.length}`} />
            <Metric label={t('warAttacksMissedShort')} value={`${season.missedAttacks}`} />
          </View>
          {season.attacks.map((attack, index) => (
            <View key={`${attack.warTag}-${index}`} style={styles.subRow}>
              <MobileWebImage
                imageUrl={ImageAssets.townHall(attack.defenderTownHallLevel)}
                style={styles.compactImage}
              />
              <CKText role="labelLarge" style={styles.grow}>
                {attack.defenderName} · {attack.opponentName} ·{' '}
                {t('cwlRoundShort', { round: attack.round })}
              </CKText>
              <CKText>
                {'★'.repeat(attack.stars)} · {attack.destructionPercentage}%
              </CKText>
            </View>
          ))}
        </View>
      ) : null}
    </Surface>
  );
}

export function formatPlayerCwlSeason(raw: string, locale: string) {
  const match = /^(\d{4})-(\d{2})/.exec(raw.trim());
  if (!match) return raw;
  const year = Number(match[1]);
  const month = Number(match[2]);
  if (!Number.isInteger(year) || month < 1 || month > 12) return raw;
  return new Intl.DateTimeFormat(toIntlLocale(locale), {
    month: 'long',
    year: 'numeric',
    timeZone: 'UTC',
  }).format(new Date(Date.UTC(year, month - 1, 1)));
}

export function PlayerJoinLeaveTab({
  page,
  totals,
  actions,
  loadingMore = false,
}: {
  page: PlayerJoinLeavePage | null | undefined;
  totals: readonly PlayerJoinLeaveTotal[] | null | undefined;
  actions: PlayerDetailPresentationActions;
  loadingMore?: boolean;
}) {
  const { t, locale, isRtl } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const [view, setView] = useState<'events' | 'clans'>('events');
  const [eventType, setEventType] = useState<'all' | 'join' | 'leave'>('all');
  const [totalsSort, setTotalsSort] = useState<'time' | 'visits'>('time');
  const [filtersExpanded, setFiltersExpanded] = useState(false);
  if (!page)
    return (
      <ErrorState
        title={t('playerJoinLeaveLoadError')}
        actionLabel={t('generalRetry')}
        onAction={() => void actions.loadTab('joinLeave', true)}
      />
    );
  // Filtering must keep the API's chronology and every individual event. The
  // aggregate Clans view alone is sorted; page.available is the full event count,
  // not the currently loaded or filtered subset. Unknown clan totals stay uncounted.
  const events = filteredJoinLeaveEvents(page, eventType);
  const sortedTotals = sortedJoinLeaveTotals(totals ?? [], totalsSort);
  const count = (value: number) => value.toLocaleString(toIntlLocale(locale));
  const filterActive = view === 'events' ? eventType !== 'all' : totalsSort !== 'time';
  const filterLabel =
    view === 'events'
      ? eventType === 'join'
        ? t('joinLeaveJoin')
        : eventType === 'leave'
          ? t('joinLeaveLeave')
          : t('generalAll')
      : totalsSort === 'visits'
        ? t('playerJoinLeaveVisits')
        : t('playerJoinLeaveTimeSpent');
  return (
    <View
      style={[
        styles.sections,
        styles.joinLeaveSection,
        layout.isExpanded && {
          maxWidth: Math.min(layout.contentMaxWidth, view === 'events' ? 960 : 1240),
        },
      ]}
    >
      <View testID="player-join-leave-toolbar" style={styles.joinLeaveToolbar}>
        <View testID="player-join-leave-controls-row" style={styles.joinLeaveControlsRow}>
          <View testID="player-join-leave-view-control" style={styles.joinLeaveViewControl}>
            <SlidingSegmentControl
              testID="player-join-leave-mode"
              value={view}
              options={[
                { value: 'events', label: `${t('warEventsTitle')} ${count(page.available)}` },
                {
                  value: 'clans',
                  label:
                    totals == null ? t('statsClans') : `${t('statsClans')} ${count(totals.length)}`,
                },
              ]}
              style={styles.joinLeaveSegment}
              isRtl={isRtl}
              onChange={setView}
            />
          </View>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={`${t('generalFilters')}: ${filterLabel}`}
            accessibilityState={{ expanded: filtersExpanded, selected: filterActive }}
            testID="player-join-leave-filter-control"
            onPress={() => setFiltersExpanded((value) => !value)}
          >
            <PillSurface
              style={[
                styles.joinLeaveFilterButton,
                (filterActive || filtersExpanded) && {
                  backgroundColor: colorWithAlpha(theme.primary, 0.12),
                },
              ]}
            >
              <Filter
                size={20}
                color={filterActive || filtersExpanded ? theme.primary : theme.onSurfaceVariant}
              />
            </PillSurface>
          </Pressable>
        </View>
        {filtersExpanded ? (
          view === 'events' ? (
            <View testID="player-join-leave-filter-options" style={styles.wrap}>
              {(
                [
                  [
                    'all',
                    t('generalAll'),
                    <ListOrdered key="all" size={16} color={theme.primary} />,
                    theme.primary,
                  ],
                  [
                    'join',
                    t('joinLeaveJoin'),
                    <LogIn key="join" size={16} color={ckColors.donationGreen} />,
                    ckColors.donationGreen,
                  ],
                  [
                    'leave',
                    t('joinLeaveLeave'),
                    <LogOut key="leave" size={16} color={ckColors.lossRed} />,
                    ckColors.lossRed,
                  ],
                ] as const
              ).map(([key, label, icon, color]) => (
                <Choice
                  key={key}
                  label={label}
                  icon={icon}
                  accent={color}
                  selected={eventType === key}
                  onPress={() => setEventType(key)}
                />
              ))}
            </View>
          ) : (
            <View testID="player-join-leave-filter-options" style={styles.wrap}>
              {(
                [
                  [
                    'time',
                    t('playerJoinLeaveTimeSpent'),
                    <Clock3 key="time" size={16} color={ckColors.donationGreen} />,
                    ckColors.donationGreen,
                  ],
                  [
                    'visits',
                    t('playerJoinLeaveVisits'),
                    <Repeat2 key="visits" size={16} color={theme.primary} />,
                    theme.primary,
                  ],
                ] as const
              ).map(([key, label, icon, color]) => (
                <Choice
                  key={key}
                  label={label}
                  icon={icon}
                  accent={color}
                  selected={totalsSort === key}
                  onPress={() => setTotalsSort(key)}
                />
              ))}
            </View>
          )
        ) : null}
      </View>
      {view === 'events' ? (
        <View testID="player-join-leave-event-stream" style={styles.joinLeaveEventStream}>
          {events.map((event, index) => (
            <PlayerJoinLeaveEventRow
              key={`${event.time.toISOString()}-${index}`}
              event={event}
              onOpenClan={actions.openClan}
            />
          ))}
          {!events.length ? (
            <EmptyState
              title={
                eventType === 'all' ? t('playerJoinLeaveNoHistory') : t('generalNoFilteredResults')
              }
            />
          ) : null}
          {page.items.length < page.available && loadingMore ? (
            <SkeletonContent loading>
              <PlayerJoinLeaveEventRow
                event={{
                  type: 'join',
                  time: new Date(0),
                  tag: '',
                  name: 'Player name',
                  th: 16,
                  clan: { tag: '', name: 'Clan name', badge: ImageAssets.clanCastle },
                }}
              />
            </SkeletonContent>
          ) : null}
        </View>
      ) : (
        <>
          <ResponsiveGrid
            minItemWidth={360}
            maxColumns={layout.isExpanded ? layout.columns(360, 3) : 1}
            gap={12}
          >
            {sortedTotals.map((total) => (
              <PlayerJoinLeaveClanCard
                key={total.clan.tag}
                total={total}
                onOpenClan={actions.openClan}
              />
            ))}
          </ResponsiveGrid>
          {!sortedTotals.length ? <EmptyState title={t('playerJoinLeaveNoClanTotals')} /> : null}
        </>
      )}
    </View>
  );
}

function PlayerJoinLeaveEventRow({
  event,
  onOpenClan,
}: {
  event: PlayerJoinLeavePage['items'][number];
  onOpenClan?: (tag: string) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const joined = event.type.toLowerCase().includes('join');
  const tone = joined ? ckColors.donationGreen : ckColors.lossRed;
  const movement = t(joined ? 'playerJoinLeaveJoined' : 'playerJoinLeaveLeft');
  const clanName = event.clan?.name || event.clan?.tag || t('generalUnknown');
  const relativeTime = joinLeaveRelativeTime(event.time, t);
  const clanTag = event.clan?.tag;
  return (
    <PressableSurface
      radius={ckRadius.tile}
      accessibilityRole={clanTag && onOpenClan ? 'button' : undefined}
      accessibilityLabel={`${clanName}, ${movement}, ${relativeTime}`}
      disabled={!clanTag || !onOpenClan}
      onPress={clanTag && onOpenClan ? () => onOpenClan(clanTag) : undefined}
      style={styles.joinLeaveEventRow}
    >
      {event.clan?.badge ? (
        <MobileWebImage imageUrl={event.clan.badge} style={styles.joinLeaveClanBadge} />
      ) : (
        <View style={styles.joinLeaveClanBadgeFallback}>
          <Shield color={theme.onSurfaceVariant} size={22} />
        </View>
      )}
      <View style={styles.joinLeaveEventIdentity}>
        <CKText role="rowTitle">{clanName}</CKText>
        <CKText muted role="bodySmall">
          {relativeTime}
        </CKText>
      </View>
      <View style={styles.joinLeaveMovement}>
        {joined ? <LogIn size={17} color={tone} /> : <LogOut size={17} color={tone} />}
        <CKText role="bodySmall" style={{ color: tone, flexShrink: 1 }}>
          {movement}
        </CKText>
      </View>
    </PressableSurface>
  );
}

function PlayerJoinLeaveClanCard({
  total,
  onOpenClan,
}: {
  total: PlayerJoinLeaveTotal;
  onOpenClan: (tag: string) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  return (
    <PressableSurface
      testID={`player-join-leave-clan-${total.clan.tag}`}
      radius={ckRadius.tile}
      accessibilityRole="button"
      disabled={!total.clan.tag}
      onPress={() => onOpenClan(total.clan.tag)}
      style={styles.joinLeaveClanCard}
    >
      <View style={styles.joinLeaveClanIdentity}>
        <MobileWebImage imageUrl={total.clan.badge} style={styles.joinLeaveClanBadge} />
        <CKText role="rowTitle" style={styles.grow}>
          {total.clan.name || total.clan.tag || t('generalUnknown')}
        </CKText>
        <ChevronRight size={18} color={theme.onSurfaceVariant} />
      </View>
      <View style={styles.joinLeaveClanMetrics}>
        <View style={styles.joinLeaveClanMetric}>
          <CKText role="bodyMedium">{joinLeaveDuration(total.minutes)}</CKText>
          <CKText muted role="bodySmall">
            {t('playerJoinLeaveTimeSpent')}
          </CKText>
        </View>
        <View style={styles.joinLeaveClanMetric}>
          <CKText role="bodyMedium">{total.visits.toLocaleString(toIntlLocale(locale))}</CKText>
          <CKText muted role="bodySmall">
            {t('playerJoinLeaveVisits')}
          </CKText>
        </View>
      </View>
    </PressableSurface>
  );
}

export function TabState({
  model,
  tab,
  actions,
  children,
}: {
  model: PlayerDetailPresentationModel;
  tab: PlayerDetailTabKey;
  actions: PlayerDetailPresentationActions;
  children: ReactNode;
}) {
  const { t } = useI18n();
  if (model.loadingTabs?.has(tab) && !playerTabHasContent(model, tab))
    return <SkeletonContent loading>{children}</SkeletonContent>;
  const error = model.errorByTab?.[tab];
  if (error && !playerTabHasContent(model, tab))
    return (
      <ErrorState
        title={t('generalError')}
        body={error}
        actionLabel={t('generalRetry')}
        onAction={() => void actions.loadTab(tab, true)}
      />
    );
  return <>{children}</>;
}

function FilterDropdown({
  value,
  choices,
  onSelect,
  fillWidth = false,
  icon,
  plain = false,
  showIcon = true,
}: {
  value: string;
  choices: readonly (readonly [string, string])[];
  onSelect: (value: string) => void;
  fillWidth?: boolean;
  icon?: ReactNode;
  plain?: boolean;
  showIcon?: boolean;
}) {
  const theme = useCKTheme();
  const selected = choices.find(([key]) => key === value)?.[1] ?? value;
  return (
    <SelectionPicker
      accessibilityLabel={selected}
      fillWidth={fillWidth}
      leading={showIcon ? (icon ?? <Filter size={16} color={theme.onSurfaceVariant} />) : undefined}
      plain={plain}
      onSelect={onSelect}
      options={choices.map(([key, label]) => ({ key, label }))}
      selectedKey={value}
      title={selected}
    />
  );
}
function Choice({
  testID,
  label,
  description,
  selected,
  onPress,
  onLongPress,
  icon,
  accent,
}: {
  testID?: string;
  label: string;
  description?: string;
  selected: boolean;
  onPress: () => void;
  onLongPress?: () => void;
  icon?: ReactNode;
  accent?: string;
}) {
  const theme = useCKTheme();
  const tone = accent ?? theme.primary;
  return (
    <Pressable
      testID={testID}
      accessibilityRole="checkbox"
      accessibilityHint={description}
      accessibilityState={{ checked: selected }}
      onPress={onPress}
      onLongPress={onLongPress}
    >
      <PillSurface
        style={[
          styles.choice,
          selected && {
            borderColor: colorWithAlpha(tone, 0.55),
            backgroundColor: colorWithAlpha(tone, 0.14),
          },
        ]}
      >
        {icon ?? (selected ? <Check size={14} color={tone} /> : null)}
        <CKText style={selected ? { color: tone, fontWeight: '700' } : undefined}>{label}</CKText>
      </PillSurface>
    </Pressable>
  );
}
function Metric({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.metric}>
      <CKText role="titleMedium">{value}</CKText>
      <CKText skeleton={false} muted role="labelSmall">
        {label}
      </CKText>
    </View>
  );
}
export function activityTitle(item: PlayerActivityEvent, t: ReturnType<typeof useI18n>['t']) {
  if (item.kind === 'townHallUpgrade') return t('playerActivityTownHallUpgraded');
  if (item.kind === 'superTroopBoost')
    return t('playerActivitySuperTroopBoosted', { name: item.name });
  if (item.kind === 'itemUnlocked') return t('playerActivityItemUnlocked', { name: item.name });
  if (item.kind === 'experienceLevelChange') return t('gameExpLevel');
  if (item.kind === 'trophyRecord') return t('playerBestTrophies');
  if (item.kind === 'builderTrophyRecord')
    return `${t('playerBestTrophies')} · ${t('gameBaseBuilder')}`;
  if (item.kind === 'warPreferenceChange') return t('playerWarPreferenceTitle');
  return t('playerActivityItemUpgraded', { name: item.name });
}
export function activityDetail(item: PlayerActivityEvent, t: ReturnType<typeof useI18n>['t']) {
  if (item.kind === 'superTroopBoost') return null;
  if (item.kind === 'itemUnlocked')
    return t('playerActivityUnlockedAtLevel', { level: item.currentLevel ?? 0 });
  if (
    item.kind === 'experienceLevelChange' ||
    item.kind === 'trophyRecord' ||
    item.kind === 'builderTrophyRecord' ||
    item.kind === 'warPreferenceChange'
  )
    return t('playerActivityNameChangeDetail', {
      from: item.previousValue ?? '',
      to: item.currentValue ?? '',
    });
  return t('playerActivityLevelChange', {
    from: item.previousLevel ?? 0,
    to: item.currentLevel ?? 0,
  });
}
export function activityImage(item: PlayerActivityEvent) {
  if (item.kind === 'experienceLevelChange') return ImageAssets.xp;
  if (item.kind === 'warPreferenceChange') {
    const value = item.currentValue?.toLowerCase();
    return value === 'true' || value === 'in' || value === '1'
      ? ImageAssets.warPreferenceIn
      : ImageAssets.warPreferenceOut;
  }
  if (item.itemType === 'townHall') return ImageAssets.townHall(item.currentLevel ?? 1);
  if (item.itemType === 'hero') return ImageAssets.getHeroImage(item.name);
  if (item.itemType === 'spell') return ImageAssets.getSpellImage(item.name);
  if (item.itemType === 'pet') return ImageAssets.getPetImage(item.name);
  if (item.itemType === 'equipment') return ImageAssets.getGearImage(item.name);
  if (item.itemType === 'trophy')
    return item.kind === 'builderTrophyRecord'
      ? ImageAssets.builderBaseTrophy
      : ImageAssets.trophies;
  if (item.itemType === 'profile') return ImageAssets.defaultProfile;
  return ImageAssets.getTroopImage(item.name);
}
export function activityAccent(item: PlayerActivityEvent) {
  if (item.kind === 'superTroopBoost' || item.kind === 'warPreferenceChange')
    return ckColors.capitalPurple;
  if (item.kind === 'townHallUpgrade') return ckColors.warGold;
  if (item.kind === 'experienceLevelChange' || item.kind === 'builderTrophyRecord')
    return ckColors.builderBlue;
  if (item.kind === 'trophyRecord') return ckColors.legendBlue;
  if (item.kind === 'itemUnlocked') return ckColors.donationGreen;
  return ckColors.legendBlue;
}
function joinLeaveRelativeTime(time: Date, t: ReturnType<typeof useI18n>['t']) {
  const minutes = Math.max(1, Math.floor((Date.now() - time.getTime()) / 60_000));
  if (minutes >= 1440) {
    const days = Math.floor(minutes / 1440);
    return days === 1 ? t('timeDayAgo', { day: days }) : t('timeDaysAgo', { days });
  }
  if (minutes >= 60) {
    const hours = Math.floor(minutes / 60);
    return hours === 1 ? t('timeHourAgo', { hour: hours }) : t('timeHoursAgo', { hours });
  }
  const elapsedMinutes = Math.min(59, minutes);
  return elapsedMinutes === 1
    ? t('timeMinuteAgo', { minute: elapsedMinutes })
    : t('timeMinutesAgo', { minutes: elapsedMinutes });
}

const styles = StyleSheet.create({
  grow: { flex: 1 },
  disabled: { opacity: 0.46 },
  centerText: { textAlign: 'center' },
  centeredWrap: { justifyContent: 'center' },
  superTroopImage: { width: 50, height: 50, borderRadius: 6 },
  header: {
    paddingBottom: 0,
    overflow: 'hidden',
    justifyContent: 'flex-start',
  },
  headerBackdrop: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    overflow: 'hidden',
  },
  headerText: { color: '#FFFFFF' },
  headerContent: { maxWidth: 1120, width: '100%', alignSelf: 'center' },
  headerActions: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  headerActionsCompact: { paddingHorizontal: 12 },
  headerActionsDesktop: { paddingHorizontal: 20 },
  identity: { alignItems: 'center', justifyContent: 'center' },
  identityDesktop: { flexDirection: 'row', gap: 52, paddingHorizontal: 28 },
  identityCompact: { flexDirection: 'column', gap: 2, paddingHorizontal: 4, marginTop: 6 },
  identityCopy: { flex: 1, minWidth: 0, gap: 4 },
  identityCopyCompact: { flex: 0, alignItems: 'center', width: '100%', gap: 2 },
  identityCopyWeb: { flexBasis: 'auto', flexShrink: 0 },
  hallBadge: { width: 104, height: 104, alignItems: 'center', justifyContent: 'center' },
  hall: { width: 96, height: 96, resizeMode: 'contain' },
  hallCompact: { width: 94, height: 94 },
  weaponStars: { flexDirection: 'row', marginTop: -7, justifyContent: 'center' },
  weaponStar: { width: 15, height: 15, resizeMode: 'contain', marginHorizontal: -1 },
  league: { width: 34, height: 34, resizeMode: 'contain' },
  leagueBlock: {
    width: '100%',
    height: 64,
    flexDirection: 'row',
    alignItems: 'center',
    minWidth: 132,
    gap: 8,
    paddingHorizontal: 10,
    paddingVertical: 8,
    borderRadius: 16,
  },
  leagueSubtitle: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  leagueSubtitleIcon: { width: 16, height: 16, resizeMode: 'contain' },
  leagueTiles: { flexDirection: 'row', alignItems: 'center', gap: 8, width: '100%' },
  // League summaries stay phone-sized instead of becoming full-width tablet tiles.
  leagueTilesCompact: { paddingHorizontal: 16, maxWidth: 460, alignSelf: 'center' },
  leagueTilesDesktop: { width: '44%', maxWidth: 460, flexShrink: 0 },
  leagueTilesExpanded: { paddingRight: 8 },
  leagueTilePressable: { flex: 1 },
  clanLine: { flexDirection: 'row', alignItems: 'center', maxWidth: 320 },
  clanBadge: { width: 16, height: 16, resizeMode: 'contain', marginRight: 4 },
  clanIdentityText: { flexShrink: 1 },
  clanDelimiter: { color: '#FFFFFF4D', marginHorizontal: 7 },
  quickStats: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 7,
    justifyContent: 'center',
    marginTop: 10,
  },
  mobileStats: { paddingTop: 11, gap: 8 },
  mobileQuickStats: { gap: 8, paddingHorizontal: 16 },
  quickStatsRow: { flexDirection: 'row', flexWrap: 'wrap', gap: 7, justifyContent: 'center' },
  statIcon: { width: 19, height: 19, resizeMode: 'contain' },
  resourceIcon: { width: 22, height: 22, resizeMode: 'contain' },
  rankedLink: {
    minHeight: 50,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 14,
  },
  sections: {
    gap: 10,
    paddingHorizontal: 16,
    paddingVertical: 10,
    maxWidth: 760,
    width: '100%',
    alignSelf: 'center',
  },
  section: { padding: 12, gap: 12 },
  sectionTitle: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingVertical: 2,
  },
  sectionProgress: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    overflow: 'hidden',
  },
  sectionProgressLabel: { fontWeight: '600' },
  searchRow: { flexDirection: 'row', gap: 8 },
  searchBox: {
    minHeight: 44,
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
  },
  input: { flex: 1, minHeight: 44, fontSize: 16 },
  sort: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 10,
  },
  itemTile: {
    width: '100%',
    aspectRatio: 1,
    minHeight: 54,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 2,
    borderRadius: ckRadius.tile,
    overflow: 'hidden',
  },
  locked: { opacity: 0.42 },
  itemImage: { width: '100%', height: '100%', resizeMode: 'cover' },
  itemLevelPill: {
    position: 'absolute',
    right: 2,
    bottom: 2,
    paddingHorizontal: 5,
    paddingVertical: 1,
  },
  levelPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 3,
  },
  overlay: {
    flex: 1,
    backgroundColor: '#00000070',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 20,
  },
  dialog: { width: '100%', maxWidth: 560, padding: 20, gap: 16 },
  dialogScrollContent: { gap: 16, paddingBottom: 4 },
  dialogTitle: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  detailImage: { width: 78, height: 78, resizeMode: 'contain' },
  detailMetrics: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-around',
    gap: 12,
  },
  cwlCard: { overflow: 'hidden' },
  cwlHeader: {
    minHeight: 82,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  cwlClanBadge: { width: 20, height: 20, resizeMode: 'contain' },
  cwlTitleRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  cwlTownHallLeading: { width: 54, height: 54, resizeMode: 'contain' },
  cwlTrailing: { alignItems: 'flex-end', justifyContent: 'center', gap: 8, maxWidth: '40%' },
  cwlSeasonDate: { fontWeight: '700', textAlign: 'right' },
  cwlActionRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  cwlStars: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  cwlStarIcon: { width: 21, height: 21, resizeMode: 'contain' },
  cwlStarValue: { fontWeight: '900' },
  cwlLeagueRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 4 },
  cwlLeague: { width: 22, height: 22, resizeMode: 'contain' },
  cwlParticipant: {
    maxWidth: 126,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 8,
    paddingVertical: 6,
  },
  cwlBody: { gap: 12, paddingHorizontal: 12, paddingBottom: 12 },
  metric: { minWidth: 80, alignItems: 'center', gap: 2 },
  metricCard: {
    minHeight: 92,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 12,
    gap: 4,
  },
  segmented: { flexDirection: 'row', flexWrap: 'wrap', gap: 4, padding: 4 },
  dropdownControl: {
    minHeight: 40,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
  },
  dropdownMenu: {
    position: 'absolute',
    zIndex: 20,
    top: 44,
    minWidth: 180,
    maxWidth: 320,
    padding: 6,
  },
  dropdownItem: { minHeight: 42, justifyContent: 'center', paddingHorizontal: 10 },
  segment: {
    minHeight: 40,
    minWidth: 76,
    flexGrow: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 12,
    borderRadius: ckRadius.control,
  },
  notice: { flexDirection: 'row', alignItems: 'center', gap: 10, padding: 12 },
  battleOverviewBand: { alignItems: 'stretch', gap: 8 },
  battleBandTitle: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 4 },
  battleBandIcon: { width: 18, height: 18 },
  battleMetricRow: { flexDirection: 'row' },
  battleMetric: { flex: 1, minWidth: 0, alignItems: 'center', gap: 2 },
  battleMetricIcon: { width: 20, height: 20 },
  battleSummaryDivider: { height: 1, backgroundColor: '#80808044', marginVertical: 12 },
  popularTroopRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 4 },
  popularTroop: { flex: 1, height: 48, alignItems: 'center', justifyContent: 'center' },
  // The row cell may span a tablet column; the badge belongs to the image,
  // not that cell's far edge. Compact retains its existing view hierarchy.
  popularTroopVisual: { width: 48, height: 48, flexShrink: 0, position: 'relative' },
  popularTroopImage: { width: 48, height: 48, borderRadius: ckRadius.tile },
  popularCount: { position: 'absolute', right: 0, bottom: 0, paddingHorizontal: 4 },
  chartRow: { minHeight: 36, flexDirection: 'row', alignItems: 'center', gap: 8 },
  chartLabel: { width: 78 },
  chartTrack: {
    height: 10,
    flex: 1,
    overflow: 'hidden',
    borderRadius: 999,
    backgroundColor: '#80808044',
  },
  chartFill: { height: '100%', borderRadius: 999, backgroundColor: '#D90709' },
  warChartLegend: { gap: 10, padding: 12 },
  warChartScaleRow: { gap: 6 },
  warChartScaleColors: { height: 8, flexDirection: 'row', overflow: 'hidden', borderRadius: 999 },
  warChartScaleColor: { flex: 1 },
  warChartScaleEndpoints: { flexDirection: 'row', justifyContent: 'space-between' },
  warHeatmap: { borderWidth: StyleSheet.hairlineWidth, borderColor: '#80808055', borderRadius: 12 },
  warHeatmapRow: { flexDirection: 'row' },
  warHeatmapHeaderCell: {
    width: 68,
    minHeight: 52,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#80808044',
  },
  warHeatmapCell: {
    width: 68,
    minHeight: 52,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: StyleSheet.hairlineWidth,
    borderColor: '#80808044',
    borderRadius: 8,
    margin: 2,
  },
  warHeatmapTownHall: { width: 24, height: 24, resizeMode: 'contain' },
  warHeatmapCount: { flexDirection: 'row', alignItems: 'center', gap: 2 },
  tinyImage: { width: 10, height: 10, resizeMode: 'contain' },
  warAttackSwipeClip: { position: 'relative', overflow: 'hidden' },
  warSwipeActions: {
    position: 'absolute',
    top: 0,
    right: 0,
    bottom: 0,
    left: 0,
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  warSwipeAction: { width: 112, alignItems: 'center', justifyContent: 'center' },
  warSwipePlayerAction: { backgroundColor: '#1976D2', alignItems: 'flex-start', paddingLeft: 20 },
  warSwipeDetailsAction: { backgroundColor: '#2E7D32', alignItems: 'flex-end', paddingRight: 20 },
  warAttackRow: { minHeight: 58, flexDirection: 'row', alignItems: 'center', paddingRight: 4 },
  warAttackAccent: { width: 3, height: 44, borderRadius: 999 },
  warAttackTownHall: { width: 34, height: 34, resizeMode: 'contain', borderRadius: 8 },
  warAttackInfoButton: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  warDetailsDialogWrap: { width: '100%', maxWidth: 560, maxHeight: '90%' },
  warDetailsDialog: { maxHeight: '100%', padding: 20, gap: 16 },
  warDetailsContent: { gap: 16, paddingBottom: 4 },
  warDetailCard: { overflow: 'hidden' },
  warDetailCardHeader: {
    minHeight: 52,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    padding: 16,
  },
  warDetailCardBody: { gap: 8, padding: 16 },
  warDetailRow: { minHeight: 30, flexDirection: 'row', alignItems: 'center', gap: 12 },
  warClanNames: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  warClanComparison: { flexDirection: 'row', alignItems: 'stretch', gap: 12 },
  warClanStats: { flex: 1, gap: 8 },
  warClanDivider: { width: StyleSheet.hairlineWidth, backgroundColor: '#80808055' },
  warPlayerDetail: { gap: 4, padding: 12, borderWidth: StyleSheet.hairlineWidth, borderRadius: 8 },
  alignEnd: { textAlign: 'right' },
  rowCard: { minHeight: 72, flexDirection: 'row', alignItems: 'center', gap: 12, padding: 12 },
  joinLeaveMovement: {
    maxWidth: '36%',
    flexShrink: 0,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 5,
  },
  battleCard: { minHeight: 120, gap: 8, paddingHorizontal: 12, paddingVertical: 8 },
  lootContributionCard: { paddingVertical: 6, gap: 12, position: 'relative' },
  lootTooltip: {
    position: 'absolute',
    zIndex: 2,
    maxWidth: 240,
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  lootContributionGrid: { flexDirection: 'row', gap: 3 },
  lootContributionColumn: { gap: 3, flex: 1, minWidth: 0 },
  lootMonthLabel: { width: 38, fontSize: 9 },
  lootContributionCell: {
    width: '100%',
    aspectRatio: 1,
    borderRadius: 3,
  },
  modalBackdrop: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    backgroundColor: '#00000088',
  },
  iconButton: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  battleResult: { alignItems: 'center' },
  directionImage: { width: 20, height: 20, resizeMode: 'contain' },
  starImage: { width: 19, height: 19, resizeMode: 'contain' },
  battleExtras: { maxWidth: 260, gap: 6 },
  lootValue: { flexDirection: 'row', alignItems: 'center', gap: 3 },
  armyItem: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  armyImage: { position: 'absolute', width: 44, height: 44, resizeMode: 'cover', borderRadius: 6 },
  armyCount: { position: 'absolute', right: 0, bottom: 0, paddingHorizontal: 3 },
  compactImage: { width: 24, height: 24, resizeMode: 'contain' },
  row: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  achievementCard: {
    minHeight: 86,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    padding: 10,
  },
  achievementComplete: { borderWidth: 1, borderColor: '#FFD75E80' },
  achievementProgressRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 8 },
  progressTrack: {
    height: 6,
    flex: 1,
    overflow: 'hidden',
    borderRadius: 999,
    backgroundColor: '#80808044',
  },
  progressFill: { height: '100%', borderRadius: 999 },
  rowImage: { width: 50, height: 50, resizeMode: 'contain' },
  rowImageFallback: { width: 50, height: 50, alignItems: 'center', justifyContent: 'center' },
  // Keep the two-mode toolbar above the content on every device. Events are
  // one chronological stream; only the already-aggregated Clans view uses a grid.
  joinLeaveSection: { gap: 14 },
  joinLeaveToolbar: { gap: 10 },
  joinLeaveControlsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 10,
  },
  joinLeaveViewControl: { flex: 1, minWidth: 0, maxWidth: 460 },
  joinLeaveSegment: { height: 44, borderWidth: 0 },
  joinLeaveFilterButton: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 0,
  },
  joinLeaveEventStream: { gap: 8 },
  joinLeaveEventIdentity: { flex: 1, minWidth: 0, gap: 3 },
  joinLeaveEventRow: {
    minHeight: 74,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderWidth: 0,
  },
  joinLeaveClanBadge: { width: 42, height: 42, resizeMode: 'contain', flexShrink: 0 },
  joinLeaveClanBadgeFallback: {
    width: 42,
    height: 42,
    alignItems: 'center',
    justifyContent: 'center',
  },
  joinLeaveClanCard: { padding: 16, gap: 16, borderWidth: 0 },
  joinLeaveClanIdentity: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  joinLeaveClanMetrics: { flexDirection: 'row', gap: 18, paddingLeft: 54 },
  joinLeaveClanMetric: { flex: 1, minWidth: 0, gap: 2 },
  directionBadge: { width: 64, alignItems: 'center', padding: 5, borderRadius: ckRadius.tile },
  subRow: {
    minHeight: 42,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 8,
  },
  toolbar: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  // Keep the category filter aligned above the history list, even when its
  // records use multiple columns; a dedicated side rail wastes that space.
  historyToolbar: { width: '100%', maxWidth: 420, alignSelf: 'flex-start' },
  compactHistoryToolbar: { width: '50%', minWidth: 180, maxWidth: '100%', alignSelf: 'flex-end' },
  filterButton: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  wrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  fieldGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  filterField: { minWidth: 150, flex: 1, gap: 4 },
  filterInput: {
    minHeight: 44,
    borderWidth: 1,
    borderColor: '#80808055',
    borderRadius: ckRadius.control,
    paddingHorizontal: 12,
  },
  choice: {
    minHeight: 38,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  dialogActions: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 18,
  },
  apply: { paddingHorizontal: 16, paddingVertical: 10 },
  rankedScreen: { flex: 1 },
  screenContent: {
    padding: ckSpacing.lg,
    paddingBottom: 40,
    gap: ckSpacing.md,
    maxWidth: 1040,
    width: '100%',
    alignSelf: 'center',
  },
});
