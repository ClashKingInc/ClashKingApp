import { useCallback, useEffect, useMemo, useState, type ReactNode } from 'react';
import {
  Animated,
  Linking,
  Modal,
  PanResponder,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
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
  Crosshair,
  Filter,
  Flag,
  Gamepad2,
  Info,
  ListOrdered,
  LogIn,
  LogOut,
  MapPin,
  Percent,
  Repeat2,
  Shield,
  Star,
  Swords,
  Trophy,
  Upload,
  UserRound,
  Users,
  X,
} from 'lucide-react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { ImageAssets } from '../../../core/assets/image-assets';
import {
  localizedInfoForItem,
  localizedNameForItem,
} from '../../../core/game-data/game-data-localization';
import { toIntlLocale, useI18n, type MessageKey } from '../../../i18n';
import { materialBackLabel, materialCloseLabel } from '../../../i18n/material-labels';
import {
  CKText,
  CalendarPicker,
  EmptyState,
  ErrorState,
  GlassSurface,
  LoadingIndicator,
  MobileWebImage,
  PillSurface,
  ResponsiveGrid,
  SelectionPicker,
  Skeleton,
  Surface,
  ckRadius,
  ckColors,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
  useCKThemeMode,
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
  PlayerWarStats,
  EnemyTownhallStats,
  WarStatsFilter,
} from '../models';
import { WarStatsFilter as WarStatsFilterModel } from '../models';
import { PlayerSuperTroop } from '../models/player-items';
import { PlayerBattlelogArmyCatalog } from '../models/player-battlelog';
import type {
  EnemyTownhallStats as EnemyThStats,
  PlayerWarStatsData,
  PlayerWarTypeStats,
  WarAttackSnapshot,
} from '../models/player-war';
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
import {
  builtInWarFilters,
  performanceWarFilters,
  warFilterCriteriaEqual,
  warFiltersEqual,
} from './player-war-filter-state';

export const PLAYER_DETAIL_TABS: readonly {
  key: PlayerDetailTabKey;
  labelKey?: MessageKey;
  flutterLabel?: string;
}[] = [
  { key: 'home', labelKey: 'gameBaseHome' },
  { key: 'builder', labelKey: 'gameBaseBuilder' },
  { key: 'battles', labelKey: 'playerBattlelogTab' },
  { key: 'history', labelKey: 'generalHistory' },
  { key: 'war', labelKey: 'warStats' },
  { key: 'cwl', labelKey: 'cwlHistoryTitle' },
  { key: 'achievements', labelKey: 'gameAchievements' },
  { key: 'joinLeave', labelKey: 'playerJoinLeaveTab' },
];

export function PlayerDetailHeader({
  model,
  actions,
  selectedTab,
  safeTop = 0,
}: {
  model: PlayerDetailPresentationModel;
  actions: PlayerDetailPresentationActions;
  selectedTab: PlayerDetailTabKey;
  safeTop?: number;
}) {
  const { player } = model;
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const themeMode = useCKThemeMode();
  const { width } = useWindowDimensions();
  const compact = width < 900;
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
      style={[styles.leagueTiles, compact && styles.leagueTilesCompact]}
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
          onPress={() => actions.openRanked(player)}
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
      style={[styles.header, { paddingTop: safeTop }]}
    >
      <View testID="player-header-backdrop" pointerEvents="none" style={styles.headerBackdrop}>
        <MobileWebImage
          imageUrl={
            selectedTab === 'builder'
              ? ImageAssets.builderBaseBackground
              : ImageAssets.homeBaseBackground
          }
          style={StyleSheet.absoluteFill}
          contentFit="cover"
        />
        <View style={[StyleSheet.absoluteFill, styles.headerScrim]} />
        <Svg style={StyleSheet.absoluteFill} width="100%" height="100%" pointerEvents="none">
          <Defs>
            <LinearGradient id="player-header-gradient" x1="0%" y1="0%" x2="0%" y2="100%">
              <Stop offset="0" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.36 : 0.2} />
              <Stop offset="0.5" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.64 : 0.4} />
              <Stop offset="1" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.92 : 0.65} />
            </LinearGradient>
          </Defs>
          <Rect width="100%" height="100%" fill="url(#player-header-gradient)" />
        </Svg>
      </View>
      <View testID="player-header-content" style={styles.headerContent}>
        <View
          style={[
            styles.headerActions,
            compact ? styles.headerActionsCompact : styles.headerActionsDesktop,
          ]}
        >
          <IconAction label={materialBackLabel(locale)} onPress={actions.goBack}>
            <ArrowLeft color="#fff" />
          </IconAction>
          <View style={styles.grow} />
          {warAction ? (
            <IconAction label={warAction.label} onPress={warAction.onPress}>
              <MobileWebImage imageUrl={warAction.image} style={styles.statIcon} />
            </IconAction>
          ) : null}
          <IconAction label={t('playerOpenInGame')} onPress={() => actions.openInGame(player.tag)}>
            <Gamepad2 color="#fff" />
          </IconAction>
          {model.bookmarked || !model.linkedAccount ? (
            <IconAction
              label={model.bookmarked ? t('playerBookmarkRemove') : t('playerBookmarkAdd')}
              onPress={() => void actions.toggleBookmark(player)}
            >
              {model.bookmarked ? <BookmarkCheck color="#2F8CFF" /> : <Bookmark color="#fff" />}
            </IconAction>
          ) : null}
        </View>
        <View style={[styles.identity, compact ? styles.identityCompact : styles.identityDesktop]}>
          <View style={styles.hallBadge}>
            <MobileWebImage
              imageUrl={
                selectedTab === 'builder'
                  ? ImageAssets.builderHall(player.builderHallLevel)
                  : player.townHallPic || ImageAssets.townHall(player.townHallLevel)
              }
              style={[styles.hall, compact && styles.hallCompact]}
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
          <View style={[styles.identityCopy, compact && styles.identityCopyCompact]}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={`${player.name}. ${t('generalCopiedToClipboard')}`}
              testID="player-header-name-copy"
              onPress={copyPlayerTag}
            >
              <CKText
                role="titleLarge"
                numberOfLines={1}
                style={[styles.headerText, compact && styles.centerText]}
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
                    <CKText numberOfLines={1} style={[styles.headerText, styles.clanIdentityText]}>
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
      </View>
    </View>
  );
}

function QuickStat({
  label,
  value,
  icon,
  iconElement,
}: {
  label: string;
  value: number | string;
  icon?: string;
  iconElement?: ReactNode;
}) {
  const { locale } = useI18n();
  return (
    <PillSurface style={styles.quickStat} accessible accessibilityLabel={`${label}: ${value}`}>
      {icon ? <MobileWebImage imageUrl={icon} style={styles.statIcon} /> : iconElement}
      <View>
        <CKText role="labelLarge">
          {typeof value === 'number'
            ? new Intl.NumberFormat(toIntlLocale(locale)).format(value)
            : value}
        </CKText>
      </View>
    </PillSurface>
  );
}

function IconAction({
  label,
  onPress,
  children,
}: {
  label: string;
  onPress: () => void;
  children: ReactNode;
}) {
  return (
    <Pressable accessibilityRole="button" accessibilityLabel={label} onPress={onPress}>
      <View style={styles.iconAction}>
        <View style={{ opacity: 0.9 }}>{children}</View>
      </View>
    </Pressable>
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
  const linked =
    player.clan && typeof player.clan === 'object'
      ? (player.clan as {
          tag?: string;
          name?: string;
          badgeUrls?: { small?: string; medium?: string };
        })
      : null;
  const tag = linked?.tag || player.clanOverview.tag || player.clanTag || cachedClanTag || '';
  return {
    tag,
    name: linked?.name || player.clanOverview.name || tag,
    badgeUrl:
      linked?.badgeUrls?.small ||
      linked?.badgeUrls?.medium ||
      player.clanOverview.badgeUrls.small ||
      player.clanOverview.badgeUrls.medium,
  };
}

export function PlayerBaseTab({
  player,
  village,
}: {
  player: Player;
  village: 'home' | 'builder';
}) {
  const { t } = useI18n();
  if (village === 'builder') {
    return (
      <View style={styles.sections}>
        <ResponsiveGrid minItemWidth={430} maxColumns={2}>
          <PlayerItemSection
            title={t('gameHeroes')}
            items={player.bbHeroes}
            townHallLevel={player.builderHallLevel}
            initiallyExpanded
          />
          <PlayerItemSection
            title={t('gameTroops')}
            items={player.bbTroops}
            townHallLevel={player.builderHallLevel}
            initiallyExpanded
          />
        </ResponsiveGrid>
      </View>
    );
  }
  return (
    <View style={styles.sections}>
      <ResponsiveGrid minItemWidth={430} maxColumns={2}>
        {player.superTroops.some((item) => item.isActive) ? (
          <PlayerSuperTroopSection
            title={t('gameActiveSuperTroops')}
            items={player.superTroops.filter((item) => item.isActive)}
          />
        ) : null}
        <PlayerItemSection
          title={t('gameHeroes')}
          items={player.heroes}
          townHallLevel={player.townHallLevel}
          initiallyExpanded
        />
        <PlayerItemSection
          title={t('gameEquipment')}
          items={player.equipments}
          townHallLevel={player.townHallLevel}
          initiallyExpanded
        />
        <PlayerItemSection
          title={t('gameTroops')}
          items={player.troops}
          townHallLevel={player.townHallLevel}
        />
        <PlayerItemSection
          title={t('gameSpells')}
          items={player.spells}
          townHallLevel={player.townHallLevel}
        />
        <PlayerItemSection
          title={t('gameSiegeMachines')}
          items={player.siegeMachines}
          townHallLevel={player.townHallLevel}
        />
        <PlayerItemSection
          title={t('gamePets')}
          items={player.pets}
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
  townHallLevel,
  initiallyExpanded = false,
}: {
  title: string;
  items: readonly PlayerItem[];
  townHallLevel: number;
  initiallyExpanded?: boolean;
}) {
  const { t, locale } = useI18n();
  const [expanded, setExpanded] = useState(initiallyExpanded);
  const [selected, setSelected] = useState<PlayerItem | null>(null);
  const [showSummary, setShowSummary] = useState(false);
  const theme = useCKTheme();
  const visible = useMemo(
    () => [...items].sort((a, b) => Number(b.isUnlocked) - Number(a.isUnlocked)),
    [items],
  );
  const maxLevels = items.reduce((sum, item) => sum + maxLevelForItemAtTH(item, townHallLevel), 0);
  const progress = maxLevels
    ? (items.reduce(
        (sum, item) =>
          sum + Math.min(Math.max(0, item.level), maxLevelForItemAtTH(item, townHallLevel)),
        0,
      ) /
        maxLevels) *
      100
    : 0;
  const badgeProgress = progress % 1 === 0 ? String(progress) : progress.toFixed(1);
  const formattedProgress = progress % 1 === 0 ? String(progress) : progress.toFixed(2);
  const summary = items.reduce(
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
  if (!items.length) return null;
  return (
    <Surface radius={ckRadius.card} style={styles.section}>
      <Pressable
        accessibilityRole="button"
        accessibilityState={{ expanded }}
        onPress={() => setExpanded(!expanded)}
        style={styles.sectionTitle}
      >
        <ChevronRight
          size={22}
          color={colorWithAlpha(theme.onSurface, 0.72)}
          style={{ transform: [{ rotate: expanded ? '90deg' : '0deg' }] }}
        />
        <CKText role="sectionTitle" style={styles.grow}>
          {title}
        </CKText>
        {items[0] instanceof PlayerSuperTroop ? null : (
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('playerUpgradeRemainingAccessibility', { townHallLevel })}
            onPress={(event) => {
              event.stopPropagation();
              setShowSummary(true);
            }}
          >
            <SectionProgressBadge progress={progress / 100} label={`${badgeProgress}%`} />
          </Pressable>
        )}
      </Pressable>
      {expanded ? (
        <ResponsiveGrid minItemWidth={54} maxColumns={10} gap={8}>
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
                    : `${item.name}, ${t('gameLevel', { level: item.level, maxLevel: item.maxLevel })}`
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
      ) : null}
      {selected instanceof PlayerSuperTroop ? (
        <ItemDetailModal item={selected} onClose={() => setSelected(null)} />
      ) : (
        <UpgradeItemDetailModal
          key={selected ? `${selected.name}-${selected.level}` : 'empty'}
          item={selected ? upgradeDetailsItem(selected) : null}
          snapshot={upgradeDetailsSnapshot(selected)}
          onClose={() => setSelected(null)}
        />
      )}
      <Modal
        transparent
        visible={showSummary}
        animationType="fade"
        onRequestClose={() => setShowSummary(false)}
      >
        <Pressable style={styles.overlay} onPress={() => setShowSummary(false)}>
          <Surface radius={ckRadius.card} style={styles.dialog}>
            <View style={styles.dialogTitle}>
              <CKText role="titleLarge" style={styles.grow}>
                {t('playerUpgradeSummaryTitle', {
                  progress: formattedProgress,
                  townHallLevel,
                })}
              </CKText>
              <Pressable
                accessibilityRole="button"
                accessibilityLabel={materialCloseLabel(locale)}
                onPress={() => setShowSummary(false)}
              >
                <X color={theme.onSurfaceVariant} />
              </Pressable>
            </View>
            {progress >= 100 ? (
              <CKText>{t('playerUpgradeSectionMaxed', { townHallLevel })}</CKText>
            ) : (
              <>
                <CKText role="rowTitle">{t('playerUpgradeTimeRemaining')}</CKText>
                <CKText>{formatDurationSeconds(summary.seconds, locale)}</CKText>
                <CKText role="rowTitle">{t('assetFolderResources')}</CKText>
                {summary.resources.size ? (
                  <View style={styles.wrap}>
                    {[...summary.resources]
                      .sort(([a], [b]) => a.localeCompare(b))
                      .map(([resource, amount]) => (
                        <PillSurface key={resource} style={styles.levelPill}>
                          <MobileWebImage
                            imageUrl={resourceImage(resource)}
                            style={styles.resourceIcon}
                          />
                          <CKText>{formatPlayerResourceAmount(amount, locale)}</CKText>
                        </PillSurface>
                      ))}
                  </View>
                ) : (
                  <CKText>{t('playerUpgradeNoResourceData')}</CKText>
                )}
              </>
            )}
          </Surface>
        </Pressable>
      </Modal>
    </Surface>
  );
}

function SectionProgressBadge({ progress, label }: { progress: number; label: string }) {
  const theme = useCKTheme();
  const normalized = Math.max(0, Math.min(1, progress));
  const accent = normalized >= 1 ? '#E8A524' : '#E0302B';
  const [size, setSize] = useState({ width: 0, height: 0 });
  const innerWidth = Math.max(0, size.width - 2);
  const innerHeight = Math.max(0, size.height - 2);
  const radius = innerHeight / 2;
  const perimeter = Math.max(0, 2 * (innerWidth - innerHeight) + 2 * Math.PI * radius);
  return (
    <View
      testID="section-progress-badge"
      onLayout={(event) => {
        const { width, height } = event.nativeEvent.layout;
        if (width !== size.width || height !== size.height) setSize({ width, height });
      }}
      style={[
        styles.sectionProgress,
        {
          backgroundColor:
            normalized >= 1
              ? colorWithAlpha(accent, 0.14)
              : colorWithAlpha(theme.surfaceContainerHighest, 0.55),
        },
      ]}
    >
      {size.width > 0 && size.height > 0 ? (
        <Svg
          style={StyleSheet.absoluteFill}
          viewBox={`0 0 ${size.width} ${size.height}`}
          pointerEvents="none"
        >
          <Rect
            x="1"
            y="1"
            width={innerWidth}
            height={innerHeight}
            rx={radius}
            fill="none"
            stroke={colorWithAlpha(theme.outlineVariant, 0.58)}
            strokeWidth="1.5"
          />
          <Rect
            x="1"
            y="1"
            width={innerWidth}
            height={innerHeight}
            rx={radius}
            fill="none"
            stroke={accent}
            strokeWidth="2"
            strokeDasharray={`${perimeter * normalized} ${perimeter}`}
            strokeLinecap="round"
          />
        </Svg>
      ) : null}
      <CKText role="labelMedium" style={styles.sectionProgressLabel}>
        {label}
      </CKText>
    </View>
  );
}

function ItemDetailModal({ item, onClose }: { item: PlayerItem | null; onClose: () => void }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const localizedName = item ? localizedNameForItem(item.meta) || item.name : '';
  const localizedDescription = item ? localizedInfoForItem(item.meta) : '';
  return (
    <Modal transparent visible={item !== null} animationType="fade" onRequestClose={onClose}>
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
                <CKText role="rowTitle">{t('gameItemOverview')}</CKText>
                <CKText muted>{localizedDescription}</CKText>
              </>
            ) : null}
          </Surface>
        ) : null}
      </View>
    </Modal>
  );
}

export function formatDurationSeconds(seconds: number, locale: string) {
  const formatUnit = (value: number, unit: 'day' | 'hour' | 'minute') =>
    new Intl.NumberFormat(toIntlLocale(locale), {
      style: 'unit',
      unit,
      unitDisplay: 'narrow',
    }).format(value);
  if (!seconds) return formatUnit(0, 'minute');
  const days = Math.floor(seconds / 86400),
    hours = Math.floor((seconds % 86400) / 3600);
  return days
    ? `${formatUnit(days, 'day')} ${formatUnit(hours, 'hour')}`
    : formatUnit(Math.max(1, Math.ceil(seconds / 3600)), 'hour');
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

export function PlayerBattlelogTab({ data }: { data: PlayerBattlelogData | null | undefined }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [mode, setMode] = useState<'ranked' | 'farming'>('ranked');
  const [direction, setDirection] = useState<'all' | 'attacks' | 'defenses'>('all');
  if (!data)
    return <EmptyState title={t('playerBattlelogLoadError')} body={t('generalNoDataAvailable')} />;
  const battles = data.forMode(mode);
  const items = battles.filter(
    (item) => direction === 'all' || item.attack === (direction === 'attacks'),
  );
  const attacks = battles.filter((item) => item.attack);
  const defenses = battles.filter((item) => !item.attack);
  const averageStars = attacks.length
    ? attacks.reduce((sum, item) => sum + item.stars, 0) / attacks.length
    : 0;
  const averageDestruction = attacks.length
    ? attacks.reduce((sum, item) => sum + item.destructionPercentage, 0) / attacks.length
    : 0;
  const tripleRate = attacks.length
    ? (attacks.filter((item) => item.stars === 3).length / attacks.length) * 100
    : 0;
  const averageLoot = attacks.length
    ? attacks.reduce((sum, item) => sum + item.totalLoot, 0) / attacks.length
    : 0;
  const defenseAverageStars = average(defenses.map((item) => item.stars));
  const defenseAverageDestruction = average(defenses.map((item) => item.destructionPercentage));
  const defenseTripleRate = defenses.length
    ? (defenses.filter((item) => item.stars === 3).length / defenses.length) * 100
    : 0;
  const popularAttacks = data.popularTroops(mode, { limit: 5 });
  const popularDefenses = data.popularTroops(mode, { limit: 5, attack: false });
  return (
    <View style={styles.sections}>
      <Segmented
        choices={[
          ['ranked', t('playerBattlelogRanked')],
          ['farming', t('playerBattlelogFarming')],
        ]}
        selected={mode}
        onSelect={(value) => setMode(value as typeof mode)}
      />
      <Surface radius={ckRadius.card} style={styles.section}>
        <View style={styles.sectionTitle}>
          <CKText role="titleLarge" style={styles.grow}>
            {mode === 'ranked'
              ? t('playerBattlelogRankedOverview')
              : t('playerBattlelogFarmingOverview')}
          </CKText>
          <CKText muted>{t('playerBattlelogBattleCount', { count: battles.length })}</CKText>
        </View>
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
              mode === 'farming' ? ImageAssets.lootCart : ImageAssets.attackStar,
              mode === 'farming' ? t('generalAverage') : t('warStarsThree'),
              mode === 'farming'
                ? compactNumber(Math.round(averageLoot), locale)
                : `${tripleRate.toFixed(1)}%`,
            ],
          ]}
          popular={popularAttacks}
        />
        <View style={styles.battleSummaryDivider} />
        <BattleOverviewBand
          title={t('warDefensesTitle')}
          image={ImageAssets.shieldWithArrow}
          metrics={[
            [ImageAssets.shieldWithArrow, t('generalTotal'), `${defenses.length}`],
            [ImageAssets.attackStar, t('warAbbreviationAvg'), defenseAverageStars.toFixed(2)],
            [
              ImageAssets.hitrate,
              t('warAbbreviationAvgPercentage'),
              `${defenseAverageDestruction.toFixed(1)}%`,
            ],
            [ImageAssets.attackStar, t('warStarsThree'), `${defenseTripleRate.toFixed(1)}%`],
          ]}
          popular={popularDefenses}
        />
      </Surface>
      {!data.officialAvailable || !data.historyAvailable ? (
        <Surface radius={ckRadius.tile} style={styles.notice}>
          <Info size={18} color={theme.onSurfaceVariant} />
          <CKText muted style={styles.grow}>
            {!data.officialAvailable
              ? t('playerBattlelogOfficialUnavailable')
              : t('playerBattlelogHistoryUnavailable')}
          </CKText>
        </Surface>
      ) : null}
      <View style={styles.toolbar}>
        <CKText role="titleLarge" style={styles.grow}>
          {t('playerBattlelogRecentBattles')}
        </CKText>
        <FilterDropdown
          choices={[
            ['all', t('generalAll')],
            ['attacks', t('warAttacksTitle')],
            ['defenses', t('warDefensesTitle')],
          ]}
          value={direction}
          onSelect={(value) => setDirection(value as typeof direction)}
        />
      </View>
      <View testID="battle-responsive-grid">
        <ResponsiveGrid minItemWidth={430} maxColumns={2}>
          {items.map((item, index) => (
            <BattleRow key={`${item.mergeKey}-${index}`} item={item} />
          ))}
        </ResponsiveGrid>
      </View>
      {!battles.length ? (
        <EmptyState
          title={t('playerBattlelogNoBattlesTitle')}
          body={t('playerBattlelogNoBattlesBody')}
        />
      ) : !items.length ? (
        <EmptyState title={t('generalNoFilteredResults')} body={t('generalAdjustFilters')} />
      ) : null}
    </View>
  );
}

function BattleRow({ item }: { item: PlayerBattlelogEntry }) {
  const { t, locale } = useI18n();
  const army = Object.entries(item.armyCounts).slice(0, 6);
  return (
    <Surface radius={ckRadius.tile} style={styles.battleCard}>
      <View style={styles.row}>
        <MobileWebImage
          imageUrl={
            item.opponentTownHall > 0
              ? ImageAssets.townHall(item.opponentTownHall)
              : item.attack
                ? ImageAssets.attacks
                : ImageAssets.shield
          }
          style={styles.rowImage}
        />
        <View style={styles.grow}>
          <CKText role="rowTitle" numberOfLines={1}>
            {item.opponentName || item.opponentTag || t('generalUnknown')}
          </CKText>
          {item.timestamp ? (
            <CKText muted role="labelSmall">
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
  return (
    <View style={styles.battleOverviewBand}>
      <View style={styles.battleBandTitle}>
        <MobileWebImage imageUrl={image} style={styles.battleBandIcon} />
        <CKText role="labelLarge">{title}</CKText>
      </View>
      <View style={styles.battleMetricRow}>
        {metrics.map(([metricImage, label, value]) => (
          <View
            key={`${label}-${value}`}
            accessible
            accessibilityLabel={`${label}: ${value}`}
            style={styles.battleMetric}
          >
            <MobileWebImage imageUrl={metricImage} style={styles.battleMetricIcon} />
            <CKText muted role="labelSmall" numberOfLines={1}>
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
          <CKText muted role="labelSmall" style={styles.centerText}>
            {t('playerBattlelogPopularTroops')}
          </CKText>
          <View style={styles.popularTroopRow}>
            {popular.slice(0, 5).map((entry) => (
              <View
                key={entry.item.code}
                accessible
                accessibilityLabel={`${entry.item.name}, ×${entry.uses}`}
                style={styles.popularTroop}
              >
                <MobileWebImage imageUrl={entry.item.imageUrl} style={styles.popularTroopImage} />
                <PillSurface style={styles.popularCount}>
                  <CKText role="labelSmall">×{entry.uses}</CKText>
                </PillSurface>
              </View>
            ))}
          </View>
        </>
      ) : null}
    </View>
  );
}

export function PlayerActivityTab({
  data,
  verifiedTracking,
  actions,
}: {
  data: PlayerActivityFeed | null | undefined;
  verifiedTracking: boolean;
  actions: PlayerDetailPresentationActions;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [filter, setFilter] = useState<PlayerHistoryTypeValue>('troop_level');
  const [showTracking, setShowTracking] = useState(false);
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
    <View style={styles.sections}>
      <View style={styles.toolbar}>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={`${verifiedTracking ? t('playerActivityTrackingActive') : t('playerActivityTrackingUnknown')}. ${verifiedTracking ? t('playerActivityTrackingActiveBody') : t('playerActivityTrackingUnknownBody')}`}
          onPress={() => setShowTracking(true)}
        >
          <PillSurface style={styles.dropdownControl}>
            {verifiedTracking ? (
              <Crosshair size={18} color={theme.primary} />
            ) : (
              <Info size={18} color={theme.onSurfaceVariant} />
            )}
            <CKText numberOfLines={1} style={styles.trackingLabel}>
              {verifiedTracking
                ? t('playerActivityTrackingActive')
                : t('playerActivityTrackingUnknown')}
            </CKText>
          </PillSurface>
        </Pressable>
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
      <Modal
        transparent
        visible={showTracking}
        animationType="fade"
        onRequestClose={() => setShowTracking(false)}
      >
        <Pressable style={styles.overlay} onPress={() => setShowTracking(false)}>
          <Surface radius={ckRadius.card} style={styles.dialog}>
            <CKText role="titleLarge">
              {verifiedTracking
                ? t('playerActivityTrackingActive')
                : t('playerActivityTrackingUnknown')}
            </CKText>
            <CKText>
              {verifiedTracking
                ? t('playerActivityTrackingActiveBody')
                : t('playerActivityTrackingUnknownBody')}
            </CKText>
            <Pressable accessibilityRole="button" onPress={() => setShowTracking(false)}>
              <CKText>{materialCloseLabel(locale)}</CKText>
            </Pressable>
          </Surface>
        </Pressable>
      </Modal>
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
  if (!data?.items.length)
    return <EmptyState title={t('cwlHistoryEmptyTitle')} body={t('generalNoDataAvailable')} />;
  return (
    <View style={styles.sections}>
      {data.items.map((season, index) => (
        <CwlSeasonCard
          key={`${season.season}-${season.clan.tag}-${index}`}
          recordId={`${season.season}-${index}`}
          season={season}
        />
      ))}
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
          <View style={styles.cwlTrailing}>
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
                  <MobileWebImage
                    imageUrl={ImageAssets.builderBaseStar}
                    style={styles.cwlStarIcon}
                  />
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

export function PlayerWarTab({
  data,
  actions,
  player,
  loading = false,
}: {
  data: PlayerWarStats | null | undefined;
  actions: PlayerDetailPresentationActions;
  player: Player;
  loading?: boolean;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [showFilter, setShowFilter] = useState(false);
  const [showExport, setShowExport] = useState(false);
  const [filter, setFilter] = useState(() => WarStatsFilterModel.defaultFilter());
  const [exporting, setExporting] = useState(false);
  const [exportedPath, setExportedPath] = useState<string | null>(null);
  const [quickTypes, setQuickTypes] = useState<string[]>(['random', 'cwl', 'friendly']);
  const [filtersExpanded, setFiltersExpanded] = useState(false);
  const [section, setSection] = useState<'stats' | 'attacks' | 'defenses' | 'charts'>('stats');
  const selectedTypes = quickTypes.length === 3 ? [] : quickTypes;
  const stats = data?.getStatsForTypes(selectedTypes);
  const filteredWars = useMemo(
    () =>
      data?.wars.filter((war) => quickTypes.includes(normalizedWarType(war.warDetails.warType))) ??
      [],
    [data?.wars, quickTypes],
  );
  if (!data || !stats) return <EmptyState title={t('generalNoDataAvailable')} />;
  return (
    <View style={styles.sections}>
      <View style={styles.toolbar}>
        <Segmented
          choices={[
            ['stats', t('generalStats')],
            ['attacks', t('warAttacksTitle')],
            ['defenses', t('warDefensesTitle')],
            ['charts', t('generalCharts')],
          ]}
          selected={section}
          onSelect={(v) => setSection(v as typeof section)}
        />
        <CKText muted style={styles.grow}>
          {filter.hasActiveFilters()
            ? warFilterSummary(filter, t, locale)
            : t('filtersShowingDefaultData', { count: 50 })}
        </CKText>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('filtersQuickFilters')}
          accessibilityState={{ expanded: filtersExpanded }}
          onPress={() => setFiltersExpanded((value) => !value)}
        >
          <PillSurface style={styles.compactFilterButton}>
            <Filter size={18} color={theme.onSurfaceVariant} />
          </PillSurface>
        </Pressable>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('generalFilters')}
          onPress={() => setShowFilter(true)}
        >
          <GlassSurface cornerRadius={ckRadius.control} interactive style={styles.filterButton}>
            <Filter size={18} color={theme.onSurfaceVariant} />
          </GlassSurface>
        </Pressable>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('generalExport')}
          disabled={exporting}
          onPress={() => setShowExport(true)}
        >
          <GlassSurface cornerRadius={ckRadius.control} interactive style={styles.filterButton}>
            <Upload size={18} color={theme.onSurfaceVariant} />
          </GlassSurface>
        </Pressable>
      </View>
      {filtersExpanded ? (
        <View
          testID="player-war-quick-filter-options"
          style={[styles.wrap, styles.trailingChoices]}
        >
          {['random', 'cwl', 'friendly'].map((type) => (
            <Choice
              key={type}
              label={warTypeLabel(type, t)}
              selected={quickTypes.includes(type)}
              onPress={() => {
                setQuickTypes((current) =>
                  current.includes(type)
                    ? current.filter((value) => value !== type)
                    : [...current, type],
                );
              }}
            />
          ))}
        </View>
      ) : null}
      {filter.hasActiveFilters() ? (
        <Surface radius={ckRadius.tile} style={styles.rowCard}>
          <Filter size={18} color={theme.onSurfaceVariant} />
          <CKText style={styles.grow}>{warFilterSummary(filter, t, locale)}</CKText>
          <Pressable
            accessibilityRole="button"
            onPress={() => {
              const cleared = WarStatsFilterModel.defaultFilter();
              setFilter(cleared);
              void actions.updateWarFilter(cleared);
            }}
          >
            <CKText>{t('generalClearFilters')}</CKText>
          </Pressable>
        </Surface>
      ) : null}
      {loading ? (
        <View testID="war-filter-loading" style={styles.sections}>
          <Skeleton width="100%" height={84} />
          <Skeleton width="100%" height={84} />
        </View>
      ) : null}
      <Modal
        transparent
        visible={showExport}
        animationType="fade"
        onRequestClose={() => setShowExport(false)}
      >
        <Pressable style={styles.overlay} onPress={() => setShowExport(false)}>
          <Surface radius={ckRadius.card} style={styles.dialog}>
            <View style={styles.dialogTitle}>
              <Upload color={theme.onSurfaceVariant} />
              <CKText role="titleLarge" style={styles.grow}>
                {t('exportTitle')}
              </CKText>
            </View>
            <CKText>{t('exportDialogDesc')}</CKText>
            {exportedPath ? <CKText selectable>{exportedPath}</CKText> : null}
            <Surface radius={ckRadius.tile} style={styles.section}>
              <CKText>
                {t('exportLabelPlayer')}: {player.name}
              </CKText>
              <CKText>
                {t('exportLabelFormat')}: {t('exportLabelExcel')}
              </CKText>
              <CKText>
                {t('exportLabelIncludes')}: {t('exportLabelContent')}
              </CKText>
              {filter.hasActiveFilters() ? (
                <CKText>
                  {t('generalFilters')}: {warFilterSummary(filter, t, locale)}
                </CKText>
              ) : null}
            </Surface>
            <View style={styles.dialogActions}>
              <Pressable accessibilityRole="button" onPress={() => setShowExport(false)}>
                <CKText>{t('generalCancel')}</CKText>
              </Pressable>
              {exportedPath ? (
                <Pressable
                  accessibilityRole="button"
                  onPress={() =>
                    void Linking.openURL(
                      exportedPath.startsWith('file:') ? exportedPath : `file://${exportedPath}`,
                    )
                  }
                >
                  <CKText>{t('generalOpen')}</CKText>
                </Pressable>
              ) : null}
              <Pressable
                accessibilityRole="button"
                onPress={() => {
                  setExporting(true);
                  setExportedPath(null);
                  actions.showMessage(t('exportGenerating'));
                  void actions
                    .exportWarStats(filter)
                    .then((path) => {
                      setExportedPath(path);
                      actions.showMessage(`${t('exportSuccess')} · ${path}`);
                    })
                    .catch((error) => {
                      const message = error instanceof Error ? error.message : String(error);
                      actions.showMessage(t('warStatsExportFailed', { error: message }));
                    })
                    .finally(() => setExporting(false));
                }}
              >
                <PillSurface style={styles.apply}>
                  <CKText>{t('generalExport')}</CKText>
                </PillSurface>
              </Pressable>
            </View>
          </Surface>
        </Pressable>
      </Modal>
      {section === 'stats' ? (
        stats.totalAttacks || stats.totalDefenses || !filter.hasActiveFilters() ? (
          <WarStatsSections stats={stats} />
        ) : (
          <EmptyState
            title={t('generalNoFilteredResults')}
            body={warFilterSummary(filter, t, locale)}
            actionLabel={t('generalClearFilters')}
            onAction={() => {
              const cleared = WarStatsFilterModel.defaultFilter();
              setFilter(cleared);
              void actions.updateWarFilter(cleared);
            }}
          />
        )
      ) : null}
      {section === 'charts' ? (
        <WarChartsView stats={stats} playerTownHall={player.townHallLevel} />
      ) : null}
      {section === 'attacks' || section === 'defenses' ? (
        <WarAttackList
          key={`${section}-${filteredWars
            .map(
              (war) =>
                `${war.warDetails.tag ?? ''}-${war.warDetails.warType ?? ''}-${
                  section === 'attacks'
                    ? war.memberData.attacks.length
                    : war.memberData.defenses.length
                }`,
            )
            .join('|')}-${data.timeRange.end ?? 0}`}
          wars={filteredWars}
          stats={stats}
          type={section}
          actions={actions}
        />
      ) : null}
      {showFilter ? (
        <WarFilterModal
          visible={showFilter}
          initialFilter={filter}
          warStats={data}
          actions={actions}
          onClose={() => setShowFilter(false)}
          onApply={(filter) => {
            setShowFilter(false);
            setFilter(filter);
            void actions.updateWarFilter(filter);
          }}
        />
      ) : null}
    </View>
  );
}

export function WarFilterModal({
  visible,
  initialFilter,
  warStats,
  actions,
  onClose,
  onApply,
}: {
  visible: boolean;
  initialFilter: WarStatsFilter;
  warStats: PlayerWarStats;
  actions: PlayerDetailPresentationActions;
  onClose: () => void;
  onApply: (filter: WarStatsFilter) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const { height: viewportHeight } = useWindowDimensions();
  const [types, setTypes] = useState<string[]>([
    ...(initialFilter.warTypes ?? ['random', 'cwl', 'friendly']),
  ]);
  const [season, setSeason] = useState(initialFilter.season ?? '');
  const [sameTownHall, setSameTownHall] = useState(initialFilter.sameTownHall);
  const [fresh, setFresh] = useState(initialFilter.freshAttacksOnly === true);
  const [stars, setStars] = useState<number[]>([...(initialFilter.allowedStars ?? [])]);
  const [ownTownHall, setOwnTownHall] = useState(initialFilter.ownTownHall?.toString() ?? '');
  const [enemyTownHall, setEnemyTownHall] = useState(initialFilter.enemyTownHall?.toString() ?? '');
  const [startDate, setStartDate] = useState(
    initialFilter.startDate?.toISOString().slice(0, 10) ?? '',
  );
  const [endDate, setEndDate] = useState(initialFilter.endDate?.toISOString().slice(0, 10) ?? '');
  const [minDestruction, setMinDestruction] = useState(
    initialFilter.minDestruction?.toString() ?? '',
  );
  const [maxDestruction, setMaxDestruction] = useState(
    initialFilter.maxDestruction?.toString() ?? '',
  );
  const [minPosition, setMinPosition] = useState(initialFilter.minMapPosition?.toString() ?? '');
  const [maxPosition, setMaxPosition] = useState(initialFilter.maxMapPosition?.toString() ?? '');
  const [limit, setLimit] = useState(initialFilter.limit.toString());
  const [presetName, setPresetName] = useState('');
  const [presetError, setPresetError] = useState('');
  const [presets, setPresets] = useState<readonly { name: string; filter: WarStatsFilter }[]>([]);
  const [contextPreset, setContextPreset] = useState<string | null>(null);
  const [deletePreset, setDeletePreset] = useState<string | null>(null);
  const [renamePreset, setRenamePreset] = useState<string | null>(null);
  const [renameName, setRenameName] = useState('');
  const [showSuggestionInfo, setShowSuggestionInfo] = useState(false);
  const [dateMode, setDateMode] = useState<'all' | 'season' | 'custom'>(
    initialFilter.season
      ? 'season'
      : initialFilter.startDate || initialFilter.endDate
        ? 'custom'
        : 'all',
  );
  const [presetNow] = useState(() => new Date());
  const [showCalendar, setShowCalendar] = useState(false);
  useEffect(() => {
    if (!visible) return;
    void actions
      .loadWarFilterPresets()
      .then(setPresets)
      .catch(() => undefined);
  }, [actions, visible]);
  const currentFilter = () =>
    new WarStatsFilterModel({
      warTypes: types,
      startDate: dateMode === 'custom' ? parseFilterDate(startDate) : null,
      endDate: dateMode === 'custom' ? parseFilterDate(endDate) : null,
      season: dateMode === 'season' ? season.trim() || null : null,
      ownTownHalls: parseFilterNumbers(ownTownHall),
      enemyTownHalls: parseFilterNumbers(enemyTownHall),
      sameTownHall,
      freshAttacksOnly: fresh || null,
      allowedStars: stars.length ? stars : null,
      minDestruction: parseFilterNumber(minDestruction),
      maxDestruction: parseFilterNumber(maxDestruction),
      minMapPosition: parseFilterNumber(minPosition),
      maxMapPosition: parseFilterNumber(maxPosition),
      limit: parseFilterNumber(limit) ?? 50,
    });
  const applyPreset = (preset: WarStatsFilter) => {
    setTypes([...(preset.warTypes ?? ['random', 'cwl', 'friendly'])]);
    setSameTownHall(preset.sameTownHall);
    setFresh(preset.freshAttacksOnly === true);
    setStars([...(preset.allowedStars ?? [])]);
    setOwnTownHall((preset.ownTownHalls ?? []).join(','));
    setEnemyTownHall((preset.enemyTownHalls ?? []).join(','));
    setSeason(preset.season ?? '');
    setStartDate(preset.startDate?.toISOString().slice(0, 10) ?? '');
    setEndDate(preset.endDate?.toISOString().slice(0, 10) ?? '');
    setDateMode(preset.season ? 'season' : preset.startDate || preset.endDate ? 'custom' : 'all');
    setMinDestruction(preset.minDestruction?.toString() ?? '');
    setMaxDestruction(preset.maxDestruction?.toString() ?? '');
    setMinPosition(preset.minMapPosition?.toString() ?? '');
    setMaxPosition(preset.maxMapPosition?.toString() ?? '');
    setLimit(preset.limit.toString());
  };
  const clearFilter = () => applyPreset(WarStatsFilterModel.defaultFilter());
  const removePreset = (name: string) => {
    const next = presets.filter((preset) => preset.name !== name);
    setPresets(next);
    setContextPreset(null);
    setDeletePreset(null);
    setPresetName('');
    void actions.saveWarFilterPresets(next);
  };
  const builtIns = builtInWarFilters(presetNow);
  const suggestions = performanceWarFilters(warStats, presetNow);
  const toggle = <T,>(values: T[], value: T) =>
    values.includes(value) ? values.filter((item) => item !== value) : [...values, value];
  return (
    <Modal transparent visible={visible} animationType="slide" onRequestClose={onClose}>
      <Pressable style={styles.overlay} onPress={onClose}>
        <Surface
          testID="war-filter-dialog"
          radius={ckRadius.card}
          style={[styles.dialog, { maxHeight: viewportHeight * 0.8 }]}
        >
          <View style={styles.dialogTitle}>
            <Filter color={theme.onSurfaceVariant} />
            <CKText role="titleLarge" style={styles.grow}>
              {t('generalFilters')}
            </CKText>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('generalCancel')}
              onPress={onClose}
            >
              <X color={theme.onSurfaceVariant} />
            </Pressable>
          </View>
          <ScrollView
            testID="war-filter-scroll"
            keyboardShouldPersistTaps="handled"
            contentContainerStyle={styles.dialogScrollContent}
          >
            <CKText role="rowTitle">{t('filtersWarType')}</CKText>
            <View style={styles.wrap}>
              {builtIns.map(([name, preset]) => (
                <Choice
                  key={name}
                  label={builtInFilterLabel(name, t)}
                  selected={warFilterCriteriaEqual(currentFilter(), preset)}
                  onPress={() =>
                    warFilterCriteriaEqual(currentFilter(), preset)
                      ? clearFilter()
                      : applyPreset(preset)
                  }
                />
              ))}
            </View>
            {suggestions.length ? (
              <>
                <View style={styles.row}>
                  <CKText role="rowTitle">{t('performanceAnalysisSuggestions')}</CKText>
                  <Pressable
                    accessibilityRole="button"
                    accessibilityLabel={t('performanceAnalysisTooltip')}
                    onPress={() => setShowSuggestionInfo((value) => !value)}
                  >
                    <Info size={16} color={theme.onSurfaceVariant} />
                  </Pressable>
                </View>
                {showSuggestionInfo ? (
                  <CKText muted>{t('performanceAnalysisTooltip')}</CKText>
                ) : null}
                <View style={styles.wrap}>
                  {suggestions.map(([name, preset]) => (
                    <Choice
                      key={name}
                      label={performanceSuggestionText(name, t).label}
                      description={performanceSuggestionText(name, t).description}
                      selected={warFilterCriteriaEqual(currentFilter(), preset)}
                      onPress={() =>
                        warFilterCriteriaEqual(currentFilter(), preset)
                          ? clearFilter()
                          : applyPreset(preset)
                      }
                    />
                  ))}
                </View>
              </>
            ) : null}
            {presets.length ? (
              <>
                <CKText role="rowTitle">{t('presetsSaved')}</CKText>
                <View style={styles.wrap}>
                  {presets.map((preset) => (
                    <Choice
                      key={preset.name}
                      testID={`war-filter-preset-${preset.name}`}
                      label={preset.name}
                      selected={warFiltersEqual(currentFilter(), preset.filter)}
                      onPress={() => {
                        if (warFiltersEqual(currentFilter(), preset.filter)) {
                          clearFilter();
                          return;
                        }
                        setPresetName(preset.name);
                        applyPreset(preset.filter);
                      }}
                      onLongPress={() => {
                        setPresetName(preset.name);
                        setContextPreset(preset.name);
                      }}
                    />
                  ))}
                </View>
                {contextPreset ? (
                  <Surface radius={ckRadius.tile} style={styles.section}>
                    <Pressable
                      accessibilityRole="button"
                      onPress={() => {
                        const preset = presets.find((item) => item.name === contextPreset);
                        if (preset) {
                          if (warFiltersEqual(currentFilter(), preset.filter)) clearFilter();
                          else applyPreset(preset.filter);
                        }
                        setContextPreset(null);
                      }}
                    >
                      <CKText>{t('presetsApply')}</CKText>
                    </Pressable>
                    <Pressable
                      testID="war-filter-rename-preset"
                      accessibilityRole="button"
                      onPress={() => {
                        setRenamePreset(contextPreset);
                        setRenameName(contextPreset);
                        setPresetError('');
                        setContextPreset(null);
                      }}
                    >
                      <CKText>{t('presetsRename')}</CKText>
                    </Pressable>
                    <Pressable
                      testID="war-filter-delete-preset"
                      accessibilityRole="button"
                      onPress={() => setDeletePreset(contextPreset)}
                    >
                      <CKText>{t('presetsDelete')}</CKText>
                    </Pressable>
                  </Surface>
                ) : null}
                {deletePreset ? (
                  <Surface radius={ckRadius.tile} style={styles.section}>
                    <CKText role="rowTitle">{t('presetsDeleteTitle')}</CKText>
                    <CKText>{t('presetsDeleteConfirm', { name: deletePreset })}</CKText>
                    <View style={styles.dialogActions}>
                      <Pressable accessibilityRole="button" onPress={() => setDeletePreset(null)}>
                        <CKText>{t('generalCancel')}</CKText>
                      </Pressable>
                      <Pressable
                        testID="war-filter-confirm-delete-preset"
                        accessibilityRole="button"
                        onPress={() => removePreset(deletePreset)}
                      >
                        <CKText>{t('presetsDelete')}</CKText>
                      </Pressable>
                    </View>
                  </Surface>
                ) : null}
                {renamePreset ? (
                  <Surface radius={ckRadius.tile} style={styles.section}>
                    <CKText role="rowTitle">{t('presetsRenameTitle')}</CKText>
                    <FilterField
                      testID="war-filter-rename-name"
                      label={t('presetsName')}
                      value={renameName}
                      onChangeText={(value) => {
                        setRenameName(value);
                        setPresetError('');
                      }}
                    />
                    {presetError ? (
                      <CKText style={{ color: '#D90709' }}>{presetError}</CKText>
                    ) : null}
                    <View style={styles.dialogActions}>
                      <Pressable accessibilityRole="button" onPress={() => setRenamePreset(null)}>
                        <CKText>{t('generalCancel')}</CKText>
                      </Pressable>
                      <Pressable
                        testID="war-filter-confirm-rename-preset"
                        accessibilityRole="button"
                        disabled={!renameName.trim() || renameName.trim() === renamePreset}
                        onPress={() => {
                          const nextName = renameName.trim();
                          if (
                            presets.some(
                              (preset) => preset.name === nextName && preset.name !== renamePreset,
                            )
                          ) {
                            setPresetError(t('presetsNameExists'));
                            return;
                          }
                          const next = presets.map((preset) =>
                            preset.name === renamePreset ? { ...preset, name: nextName } : preset,
                          );
                          setPresets(next);
                          setRenamePreset(null);
                          void actions.saveWarFilterPresets(next);
                        }}
                      >
                        <CKText>{t('presetsRename')}</CKText>
                      </Pressable>
                    </View>
                  </Surface>
                ) : null}
              </>
            ) : null}
            <View style={styles.wrap}>
              {['random', 'cwl', 'friendly'].map((type) => (
                <Choice
                  key={type}
                  label={warTypeLabel(type, t)}
                  selected={types.includes(type)}
                  onPress={() => setTypes(toggle(types, type))}
                />
              ))}
            </View>
            <CKText role="rowTitle">{t('filtersDateRange')}</CKText>
            <Segmented
              testIDPrefix="war-filter-date-mode"
              choices={[
                ['all', t('generalAllTime')],
                ['season', t('filtersSeason')],
                ['custom', t('filtersDateRange')],
              ]}
              selected={dateMode}
              onSelect={(value) => {
                const next = value as typeof dateMode;
                setDateMode(next);
                if (next === 'all') setLimit('10000');
                else if (dateMode === 'all' && limit === '10000') setLimit('50');
              }}
            />
            <View style={styles.fieldGrid}>
              {dateMode === 'season' ? (
                <SeasonPicker value={season} maximum={presetNow} onChange={setSeason} />
              ) : null}
              {dateMode === 'custom' ? (
                <>
                  <Pressable
                    accessibilityRole="button"
                    onPress={() => setShowCalendar((value) => !value)}
                  >
                    <CKText>{`${startDate || t('generalNotSet')} – ${endDate || t('generalNotSet')}`}</CKText>
                  </Pressable>
                  {showCalendar ? (
                    <CalendarPicker
                      range
                      start={
                        parseFilterDate(startDate) ??
                        new Date(
                          presetNow.getFullYear(),
                          presetNow.getMonth(),
                          presetNow.getDate() - 29,
                        )
                      }
                      end={parseFilterDate(endDate) ?? undefined}
                      minimum={new Date(2020, 0, 1)}
                      maximum={presetNow}
                      onChange={(nextStart, nextEnd) => {
                        setStartDate(formatLocalFilterDate(nextStart));
                        setEndDate(nextEnd ? formatLocalFilterDate(nextEnd) : '');
                        if (nextEnd) setShowCalendar(false);
                      }}
                    />
                  ) : null}
                </>
              ) : null}
            </View>
            <CKText role="rowTitle">{t('filtersTownHall')}</CKText>
            <View style={styles.fieldGrid}>
              <FilterField
                label={t('filtersAttackerTh')}
                value={ownTownHall}
                onChangeText={setOwnTownHall}
              />
              <FilterField
                label={t('filtersDefenderTh')}
                value={enemyTownHall}
                onChangeText={setEnemyTownHall}
              />
            </View>
            <CKText role="rowTitle">{t('warStarsTitle')}</CKText>
            <View style={styles.wrap}>
              {[0, 1, 2, 3].map((value) => (
                <Choice
                  key={value}
                  label={`${value} ★`}
                  selected={stars.includes(value)}
                  onPress={() => setStars(toggle(stars, value))}
                />
              ))}
            </View>
            <CKText role="rowTitle">{t('filtersDestructionPercentage')}</CKText>
            <View style={styles.fieldGrid}>
              <FilterField
                label={t('warStatsFilterMinDestructionPercent')}
                value={minDestruction}
                onChangeText={setMinDestruction}
                numeric
              />
              <FilterField
                label={t('warStatsFilterMaxDestructionPercent')}
                value={maxDestruction}
                onChangeText={setMaxDestruction}
                numeric
              />
            </View>
            <CKText role="rowTitle">{t('filtersAdvanced')}</CKText>
            <View style={styles.fieldGrid}>
              <FilterField
                label={t('warStatsFilterMinPosition')}
                value={minPosition}
                onChangeText={setMinPosition}
                numeric
              />
              <FilterField
                label={t('warStatsFilterMaxPosition')}
                value={maxPosition}
                onChangeText={setMaxPosition}
                numeric
              />
              <FilterField
                label={t('warStatsFilterResultLimit')}
                value={limit}
                onChangeText={setLimit}
                numeric
              />
            </View>
            <View style={styles.wrap}>
              <Choice
                label={t('warStatsFilterSameTownHallOnly')}
                selected={sameTownHall}
                onPress={() => setSameTownHall(!sameTownHall)}
              />
              <Choice
                label={t('warStatsFilterFreshAttacksOnly')}
                selected={fresh}
                onPress={() => setFresh(!fresh)}
              />
            </View>
            <View style={styles.dialogActions}>
              <FilterField
                label={t('presetsName')}
                value={presetName}
                onChangeText={setPresetName}
              />
              {presetError ? <CKText style={{ color: '#D90709' }}>{presetError}</CKText> : null}
              <Pressable
                accessibilityRole="button"
                disabled={!presetName.trim()}
                onPress={() => {
                  if (presets.some((preset) => preset.name === presetName.trim())) {
                    setPresetError(t('presetsNameExists'));
                    return;
                  }
                  const next = [...presets, { name: presetName.trim(), filter: currentFilter() }];
                  setPresets(next);
                  setPresetError('');
                  setPresetName('');
                  void actions.saveWarFilterPresets(next);
                }}
              >
                <CKText>{t('presetsSave')}</CKText>
              </Pressable>
              <Pressable accessibilityRole="button" onPress={clearFilter}>
                <CKText>{t('generalClearFilters')}</CKText>
              </Pressable>
              <Pressable accessibilityRole="button" onPress={() => onApply(currentFilter())}>
                <PillSurface style={styles.apply}>
                  <CKText>{t('generalApply')}</CKText>
                </PillSurface>
              </Pressable>
            </View>
          </ScrollView>
        </Surface>
      </Pressable>
    </Modal>
  );
}

function warFilterSummary(
  filter: WarStatsFilter,
  t: ReturnType<typeof useI18n>['t'],
  locale: string,
) {
  const intlLocale = toIntlLocale(locale);
  const parts = [
    filter.warTypes?.length
      ? filter.warTypes.map((type) => warTypeLabel(type, t)).join(', ')
      : null,
    filter.season ? `${t('filtersSeason')}: ${filter.season}` : null,
    filter.startDate || filter.endDate
      ? `${filter.startDate?.toLocaleDateString(intlLocale) ?? '…'} – ${filter.endDate?.toLocaleDateString(intlLocale) ?? '…'}`
      : null,
    filter.ownTownHalls?.length
      ? `${t('filtersAttackerTh')}: ${filter.ownTownHalls.join(', ')}`
      : filter.ownTownHall
        ? `${t('filtersAttackerTh')}: ${filter.ownTownHall}`
        : null,
    filter.enemyTownHalls?.length
      ? `${t('filtersDefenderTh')}: ${filter.enemyTownHalls.join(', ')}`
      : filter.enemyTownHall
        ? `${t('filtersDefenderTh')}: ${filter.enemyTownHall}`
        : null,
    filter.sameTownHall ? t('warStatsFilterSameTownHallOnly') : null,
    filter.freshAttacksOnly ? t('warStatsFilterFreshAttacksOnly') : null,
    filter.allowedStars?.length ? `${filter.allowedStars.join('/')} ★` : null,
    filter.minDestruction != null
      ? `${t('warStatsFilterMinDestructionPercent')}: ${filter.minDestruction}%`
      : null,
    filter.maxDestruction != null
      ? `${t('warStatsFilterMaxDestructionPercent')}: ${filter.maxDestruction}%`
      : null,
    filter.minMapPosition != null
      ? `${t('warStatsFilterMinPosition')}: ${filter.minMapPosition}`
      : null,
    filter.maxMapPosition != null
      ? `${t('warStatsFilterMaxPosition')}: ${filter.maxMapPosition}`
      : null,
  ].filter(Boolean);
  return parts.join(' · ') || t('filtersNoneApplied');
}

function WarStatsSections({ stats }: { stats: PlayerWarTypeStats }) {
  const { t } = useI18n();
  const attacks = groupWarStats(stats.byEnemyTownhall);
  const defenses = groupWarStats(stats.byEnemyTownhallDef);
  const levels = [...new Set([...Object.keys(attacks), ...Object.keys(defenses)])].sort(
    (left, right) => Number(right) - Number(left),
  );
  return (
    <ResponsiveGrid minItemWidth={400} maxColumns={2}>
      <WarStatsSection
        testID="war-stats-all"
        title={t('statsAllTownHalls')}
        attackCount={stats.totalAttacks}
        defenseCount={stats.totalDefenses}
        initiallyExpanded
      >
        <View style={styles.warStatPair}>
          <EnhancedWarStatCard
            title={t('warAttacksTitle')}
            isAttack
            stats={{
              averageStars: stats.averageStars,
              averageDestruction: stats.averageDestruction,
              count: stats.totalAttacks,
              starsCount: stats.starsCount,
            }}
            missed={stats.missedAttacks}
          />
          <EnhancedWarStatCard
            title={t('warDefensesTitle')}
            isAttack={false}
            stats={{
              averageStars: stats.averageStarsDef,
              averageDestruction: stats.averageDestructionDef,
              count: stats.totalDefenses,
              starsCount: stats.starsCountDef,
            }}
            missed={stats.missedDefenses}
          />
        </View>
      </WarStatsSection>
      {levels.map((level) => (
        <WarStatsSection
          key={level}
          testID={`war-stats-th-${level}`}
          title={t('gameTownHallLevelNumber', { level: Number(level) })}
          image={ImageAssets.townHall(Number(level))}
          attackCount={attacks[level]?.count ?? 0}
          defenseCount={defenses[level]?.count ?? 0}
        >
          <View style={styles.warStatPair}>
            {attacks[level] ? (
              <EnhancedWarStatCard title={t('warAttacksTitle')} stats={attacks[level]} isAttack />
            ) : (
              <EmptyWarStatCard label={t('warAttacksNone')} />
            )}
            {defenses[level] ? (
              <EnhancedWarStatCard
                title={t('warDefensesTitle')}
                stats={defenses[level]}
                isAttack={false}
              />
            ) : (
              <EmptyWarStatCard label={t('warDefensesNone')} />
            )}
          </View>
        </WarStatsSection>
      ))}
    </ResponsiveGrid>
  );
}

function WarStatsSection({
  testID,
  title,
  image,
  attackCount,
  defenseCount,
  initiallyExpanded = false,
  children,
}: {
  testID: string;
  title: string;
  image?: string;
  attackCount: number;
  defenseCount: number;
  initiallyExpanded?: boolean;
  children: ReactNode;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState(initiallyExpanded);
  return (
    <Surface radius={ckRadius.card} style={styles.warStatsSection}>
      <Pressable
        testID={testID}
        accessibilityRole="button"
        accessibilityState={{ expanded }}
        onPress={() => setExpanded((value) => !value)}
      >
        <View style={styles.rowCard}>
          {image ? <MobileWebImage imageUrl={image} style={styles.compactImage} /> : null}
          <CKText role="rowTitle" style={styles.grow}>
            {title}
          </CKText>
          <PillSurface>
            <CKText role="labelSmall">
              {t('warAttacksTitle')} {attackCount}
            </CKText>
          </PillSurface>
          <PillSurface>
            <CKText role="labelSmall">
              {t('warDefensesTitle')} {defenseCount}
            </CKText>
          </PillSurface>
          <ChevronRight
            color={theme.onSurfaceVariant}
            style={{ transform: [{ rotate: expanded ? '90deg' : '0deg' }] }}
          />
        </View>
      </Pressable>
      {expanded ? children : null}
    </Surface>
  );
}

function EnhancedWarStatCard({
  title,
  stats,
  isAttack,
  missed = 0,
}: {
  title: string;
  stats: Pick<EnemyThStats, 'averageStars' | 'averageDestruction' | 'count' | 'starsCount'>;
  isAttack: boolean;
  missed?: number;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const starPerformance = Math.max(0, Math.min(1, stats.averageStars / 3));
  const destructionPerformance = Math.max(0, Math.min(1, stats.averageDestruction / 100));
  const performance = isAttack
    ? (starPerformance + destructionPerformance) / 2
    : 1 - (starPerformance + destructionPerformance) / 2;
  const accent = performanceScaleColor(performance);
  return (
    <Surface
      radius={ckRadius.tile}
      style={[
        styles.enhancedStatCard,
        {
          backgroundColor: colorWithAlpha(accent, 0.06),
          borderColor: colorWithAlpha(accent, 0.35),
        },
      ]}
    >
      <CKText role="rowTitle">{title}</CKText>
      <View style={styles.warStatHeadline}>
        <View style={styles.metric}>
          <CKText role="titleLarge">{'★'.repeat(Math.round(stats.averageStars))}</CKText>
          <CKText role="labelLarge">{stats.averageStars.toFixed(2)}</CKText>
        </View>
        <View style={styles.metric}>
          <MobileWebImage
            imageUrl={isAttack ? ImageAssets.sword : ImageAssets.shield}
            style={styles.compactImage}
          />
          <CKText role="labelLarge">{stats.count}</CKText>
        </View>
      </View>
      <CKText muted role="labelSmall">
        {t('warDestructionTitle')}
      </CKText>
      <View style={styles.warPerformanceTrack}>
        <View
          style={[
            styles.warPerformanceFill,
            {
              width: `${Math.max(0, Math.min(100, stats.averageDestruction))}%`,
              backgroundColor: accent,
            },
          ]}
        />
      </View>
      <CKText role="labelLarge" style={{ color: accent }}>
        {stats.averageDestruction.toFixed(1)}%
      </CKText>
      <View style={styles.warStarBreakdown}>
        {[0, 1, 2, 3].map((stars) => (
          <View key={stars} style={styles.warStarBreakdownRow}>
            <CKText role="labelSmall" style={styles.warStarLabel}>
              {'★'.repeat(stars) || '☆'}
            </CKText>
            <CKText
              role="labelSmall"
              style={{ color: warStarColor(stars, isAttack), fontWeight: '700' }}
            >
              {stats.starsCount[String(stars)] ?? 0} (
              {stats.count
                ? Math.round(((stats.starsCount[String(stars)] ?? 0) / stats.count) * 100)
                : 0}
              %)
            </CKText>
          </View>
        ))}
      </View>
      <PillSurface
        style={{
          backgroundColor: colorWithAlpha(
            missed > 0 ? theme.error : theme.surfaceContainerHighest,
            missed > 0 ? 0.14 : 0.34,
          ),
          borderColor: colorWithAlpha(missed > 0 ? theme.error : theme.outlineVariant, 0.42),
        }}
      >
        <View style={styles.warMissedPill}>
          <MobileWebImage imageUrl={ImageAssets.brokenSword} style={styles.compactImage} />
          <CKText role="labelSmall" style={missed > 0 ? { color: theme.error } : undefined}>
            {t('warStatusMissedInfo', { number: missed })}
          </CKText>
        </View>
      </PillSurface>
    </Surface>
  );
}

function EmptyWarStatCard({ label }: { label: string }) {
  return (
    <Surface radius={ckRadius.tile} style={styles.enhancedStatCard}>
      <CKText muted>{label}</CKText>
    </Surface>
  );
}

function groupWarStats(values: Readonly<Record<string, EnemyTownhallStats>>) {
  const grouped: Record<string, EnemyTownhallStats[]> = {};
  for (const [key, value] of Object.entries(values)) {
    const level = key.split('vs')[1];
    if (level) (grouped[level] ??= []).push(value);
  }
  return Object.fromEntries(
    Object.entries(grouped).map(([level, entries]) => {
      const count = entries.reduce((sum, entry) => sum + entry.count, 0);
      const starsCount: Record<string, number> = {};
      for (const entry of entries)
        for (const [stars, value] of Object.entries(entry.starsCount))
          starsCount[stars] = (starsCount[stars] ?? 0) + value;
      return [
        level,
        {
          count,
          averageStars: count
            ? entries.reduce((sum, entry) => sum + entry.averageStars * entry.count, 0) / count
            : 0,
          averageDestruction: count
            ? entries.reduce((sum, entry) => sum + entry.averageDestruction * entry.count, 0) /
              count
            : 0,
          starsCount,
        },
      ];
    }),
  );
}

function WarChartsView({
  stats,
  playerTownHall,
}: {
  stats: PlayerWarTypeStats;
  playerTownHall: number;
}) {
  const { t } = useI18n();
  return (
    <View style={styles.sections}>
      <View style={styles.wrap} testID="war-chart-guide">
        <PillSurface>
          <CKText role="labelSmall">{t('chartsRowsYourTh')}</CKText>
        </PillSurface>
        <PillSurface>
          <CKText role="labelSmall">{t('warStarsAverage')}</CKText>
        </PillSurface>
      </View>
      <View style={styles.warChartLegend} testID="war-chart-scale">
        <WarChartScale
          title={t('warAttacksTitle')}
          startStars={0}
          endStars={3}
          startLabel={t('generalPoor')}
          endLabel={t('chartsExcellent')}
        />
        <WarChartScale
          title={t('warDefensesTitle')}
          startStars={3}
          endStars={0}
          startLabel={t('generalPoor')}
          endLabel={t('chartsExcellent')}
        />
      </View>
      <WarHeatmap
        title={t('warAttacksTitle')}
        subtitle={t('chartsAttackPerformance')}
        stats={stats.byEnemyTownhall}
        playerTownHall={playerTownHall}
      />
      <WarHeatmap
        title={t('warDefensesTitle')}
        subtitle={t('chartsDefensePerformance')}
        stats={stats.byEnemyTownhallDef}
        playerTownHall={playerTownHall}
        showDefense
      />
    </View>
  );
}

function WarChartScale({
  title,
  startStars,
  endStars,
  startLabel,
  endLabel,
}: {
  title: string;
  startStars: number;
  endStars: number;
  startLabel: string;
  endLabel: string;
}) {
  const colors = ['#E53935', '#FB8C00', '#F9A825', '#43A047'];
  return (
    <View style={styles.warChartScaleRow}>
      <CKText role="labelSmall">{title}</CKText>
      <View style={styles.warChartScaleColors}>
        {colors.map((color) => (
          <View key={color} style={[styles.warChartScaleColor, { backgroundColor: color }]} />
        ))}
      </View>
      <View style={styles.warChartScaleEndpoints}>
        <CKText muted role="labelSmall">
          {startStars} ★ · {startLabel}
        </CKText>
        <CKText muted role="labelSmall">
          {endStars} ★ · {endLabel}
        </CKText>
      </View>
    </View>
  );
}

function WarHeatmap({
  title,
  subtitle,
  stats,
  playerTownHall,
  showDefense = false,
}: {
  title: string;
  subtitle: string;
  stats: Readonly<Record<string, EnemyTownhallStats>>;
  playerTownHall: number;
  showDefense?: boolean;
}) {
  const { t } = useI18n();
  const { playerLevels, opponentLevels } = heatmapTownHallLevels(
    stats,
    playerTownHall,
    showDefense,
  );
  return (
    <Surface radius={ckRadius.card} style={styles.section}>
      <CKText role="titleLarge">{title}</CKText>
      <CKText muted role="labelSmall">
        {subtitle}
      </CKText>
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <View style={styles.warHeatmap}>
          <View style={styles.warHeatmapRow}>
            <View style={styles.warHeatmapHeaderCell}>
              <CKText muted role="labelSmall">
                {t('filtersTownHall')}
              </CKText>
            </View>
            {opponentLevels.map((level) => (
              <View key={level} style={styles.warHeatmapCell}>
                <MobileWebImage
                  imageUrl={ImageAssets.townHall(level)}
                  style={styles.warHeatmapTownHall}
                />
              </View>
            ))}
          </View>
          {playerLevels.map((playerLevel) => (
            <View key={playerLevel} style={styles.warHeatmapRow}>
              <View style={styles.warHeatmapHeaderCell}>
                <MobileWebImage
                  imageUrl={ImageAssets.townHall(playerLevel)}
                  style={styles.warHeatmapTownHall}
                />
              </View>
              {opponentLevels.map((opponentLevel) => {
                const key = showDefense
                  ? `${opponentLevel}vs${playerLevel}`
                  : `${playerLevel}vs${opponentLevel}`;
                const value = stats[key];
                const color = value
                  ? heatmapPerformanceColor(value.averageStars, showDefense)
                  : undefined;
                return (
                  <View
                    key={key}
                    testID={`war-heatmap-${showDefense ? 'defense' : 'attack'}-${key}`}
                    style={[
                      styles.warHeatmapCell,
                      value && color
                        ? {
                            backgroundColor: colorWithAlpha(color, 0.13),
                            borderColor: colorWithAlpha(color, 0.42),
                          }
                        : undefined,
                    ]}
                  >
                    {value ? (
                      <>
                        <CKText role="labelLarge" style={{ color }}>
                          {value.averageStars.toFixed(1)} ★
                        </CKText>
                        <View style={styles.warHeatmapCount}>
                          <MobileWebImage imageUrl={ImageAssets.sword} style={styles.tinyImage} />
                          <CKText muted role="labelSmall">
                            {value.count}
                          </CKText>
                        </View>
                      </>
                    ) : (
                      <CKText muted>-</CKText>
                    )}
                  </View>
                );
              })}
            </View>
          ))}
        </View>
      </ScrollView>
    </Surface>
  );
}

function WarAttackList({
  wars,
  stats,
  type,
  actions,
}: {
  wars: readonly PlayerWarStatsData[];
  stats: PlayerWarTypeStats;
  type: 'attacks' | 'defenses';
  actions: PlayerDetailPresentationActions;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const entries = useMemo(
    () =>
      wars.flatMap((war) =>
        (type === 'attacks' ? war.memberData.attacks : war.memberData.defenses).map((attack) => ({
          war,
          attack,
        })),
      ),
    [type, wars],
  );
  const [visible, setVisible] = useState(Math.min(25, entries.length));
  const [details, setDetails] = useState<{
    war: PlayerWarStatsData;
    attack: WarAttackSnapshot;
  } | null>(null);
  useEffect(() => {
    if (entries.length <= 25) return;
    const timer = setInterval(
      () => setVisible((value) => Math.min(entries.length, value + 12)),
      80,
    );
    return () => clearInterval(timer);
  }, [entries]);
  const isAttack = type === 'attacks';
  const count = isAttack ? stats.totalAttacks : stats.totalDefenses;
  const averageStars = isAttack ? stats.averageStars : stats.averageStarsDef;
  const destruction = isAttack ? stats.averageDestruction : stats.averageDestructionDef;
  const missed = isAttack ? stats.missedAttacks : stats.missedDefenses;
  if (!entries.length)
    return <EmptyState title={isAttack ? t('warAttacksNone') : t('warDefensesNone')} />;
  return (
    <View style={styles.sections}>
      <ScrollView horizontal showsHorizontalScrollIndicator={false} testID="war-attack-summary">
        <View style={styles.wrap}>
          <SummaryPill label={t('generalTotal')} value={`${count}`} />
          <SummaryPill label={t('warStarsAverage')} value={averageStars.toFixed(2)} />
          <SummaryPill label={t('warDestructionTitle')} value={`${destruction.toFixed(1)}%`} />
          <SummaryPill label={t('warAttacksMissedShort')} value={`${missed}`} />
        </View>
      </ScrollView>
      <ResponsiveGrid minItemWidth={420} maxColumns={2}>
        {entries.slice(0, visible).map(({ war, attack }, index) => {
          const target = isAttack ? attack.defender : attack.attacker;
          const tag = target?.tag ?? (isAttack ? attack.defenderTag : attack.attackerTag);
          return (
            <WarAttackSwipeRow
              key={`${war.warDetails.tag}-${attack.order}-${index}`}
              war={war}
              attack={attack}
              target={target}
              targetTag={tag}
              isAttack={isAttack}
              locale={locale}
              actions={actions}
              onDetails={() => setDetails({ war, attack })}
            />
          );
        })}
      </ResponsiveGrid>
      <Modal
        transparent
        visible={details !== null}
        animationType="slide"
        onRequestClose={() => setDetails(null)}
      >
        <Pressable style={styles.overlay} onPress={() => setDetails(null)}>
          <Pressable
            style={styles.warDetailsDialogWrap}
            onPress={(event) => event.stopPropagation()}
          >
            <Surface radius={ckRadius.card} style={styles.warDetailsDialog}>
              <View style={styles.dialogTitle}>
                <CKText role="titleLarge" style={styles.grow}>
                  {t('warAttacksDetailsTitle')}
                </CKText>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={materialCloseLabel(locale)}
                  onPress={() => setDetails(null)}
                >
                  <X color={theme.onSurfaceVariant} />
                </Pressable>
              </View>
              {details ? <WarAttackDetails details={details} locale={locale} /> : null}
            </Surface>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

function WarAttackSwipeRow({
  war,
  attack,
  target,
  targetTag,
  isAttack,
  locale,
  actions,
  onDetails,
}: {
  war: PlayerWarStatsData;
  attack: WarAttackSnapshot;
  target: WarAttackSnapshot['defender'];
  targetTag: string;
  isAttack: boolean;
  locale: string;
  actions: PlayerDetailPresentationActions;
  onDetails: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [translation] = useState(() => new Animated.Value(0));
  const accent = warStarColor(attack.stars, isAttack);
  const openTarget = useCallback(async () => {
    if (!targetTag) {
      actions.showMessage(t('warAttacksFailedToLoadPlayer'));
      return;
    }
    try {
      await actions.openPlayer(targetTag);
    } catch {
      actions.showMessage(t('warAttacksFailedToLoadPlayer'));
    }
  }, [actions, t, targetTag]);
  const reset = useCallback(
    () =>
      Animated.spring(translation, {
        toValue: 0,
        useNativeDriver: true,
        stiffness: 420,
        damping: 41,
        mass: 1,
      }).start(),
    [translation],
  );
  const panResponder = useMemo(
    () =>
      PanResponder.create({
        onMoveShouldSetPanResponder: (_event, gesture) =>
          Math.abs(gesture.dx) > 8 && Math.abs(gesture.dx) > Math.abs(gesture.dy),
        onPanResponderMove: (_event, gesture) =>
          translation.setValue(Math.max(-112, Math.min(112, gesture.dx))),
        onPanResponderRelease: (_event, gesture) => {
          const action = warAttackSwipeAction(gesture.dx);
          if (action === 'player') void openTarget();
          if (action === 'details') onDetails();
          reset();
        },
        onPanResponderTerminate: reset,
      }),
    [onDetails, openTarget, reset, translation],
  );
  const detailParts = [
    target?.townhallLevel ? t('gameTownHallLevelShort', { level: target.townhallLevel }) : null,
    new Intl.DateTimeFormat(toIntlLocale(locale), {
      year: 'numeric',
      month: 'numeric',
      day: 'numeric',
    }).format(war.warDetails.startTime ?? new Date()),
    attack.order > 0 ? `#${attack.order}` : null,
  ].filter(Boolean);
  const targetLabel = `${target?.mapPosition ? `${target.mapPosition}. ` : ''}${target?.name ?? t('generalUnknown')}`;
  return (
    <Surface radius={ckRadius.tile} style={styles.warAttackSwipeClip}>
      <View style={styles.warSwipeActions} pointerEvents="none">
        <View style={[styles.warSwipeAction, styles.warSwipePlayerAction]}>
          <UserRound color="#FFFFFF" size={24} />
        </View>
        <View style={[styles.warSwipeAction, styles.warSwipeDetailsAction]}>
          <Info color="#FFFFFF" size={24} />
        </View>
      </View>
      <Animated.View
        testID={`war-attack-row-${attack.order}-${targetTag}`}
        {...panResponder.panHandlers}
        style={{ transform: [{ translateX: translation }] }}
      >
        <View style={[styles.warAttackRow, { backgroundColor: theme.card }]}>
          <Pressable
            accessibilityRole="button"
            onPress={() => void openTarget()}
            style={[styles.rowCard, styles.grow]}
          >
            <View style={[styles.warAttackAccent, { backgroundColor: accent }]} />
            <MobileWebImage
              imageUrl={ImageAssets.townHall(target?.townhallLevel ?? 1)}
              style={styles.warAttackTownHall}
              errorFallback={
                <View style={[styles.warAttackTownHall, styles.rowImageFallback]}>
                  <CKText role="labelSmall">
                    {target?.townhallLevel
                      ? t('gameTownHallLevelShort', { level: target.townhallLevel })
                      : '?'}
                  </CKText>
                </View>
              }
            />
            <View style={styles.grow}>
              <CKText role="rowTitle" numberOfLines={1}>
                {targetLabel}
              </CKText>
              <CKText muted role="labelSmall" numberOfLines={1}>
                {detailParts.join(' · ')}
              </CKText>
            </View>
            <CKText role="labelLarge">{'★'.repeat(attack.stars)}</CKText>
            <CKText role="labelLarge" style={{ color: accent }}>
              {attack.destructionPercentage}%
            </CKText>
          </Pressable>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={t('warAttacksDetailsTitle')}
            onPress={onDetails}
            style={styles.warAttackInfoButton}
          >
            <Info size={18} color={theme.onSurfaceVariant} />
          </Pressable>
        </View>
      </Animated.View>
    </Surface>
  );
}

export function warAttackSwipeAction(translationX: number): 'player' | 'details' | null {
  if (translationX >= 72) return 'player';
  if (translationX <= -72) return 'details';
  return null;
}

function WarAttackDetails({
  details,
  locale,
}: {
  details: { war: PlayerWarStatsData; attack: WarAttackSnapshot };
  locale: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const { warDetails } = details.war;
  const unknown = t('generalUnknown');
  return (
    <ScrollView contentContainerStyle={styles.warDetailsContent}>
      <WarDetailCard
        title={t('warAttacksDetailsTitle')}
        icon={<Trophy size={20} color={theme.primary} />}
      >
        <WarDetailRow
          icon={<Star size={18} color={theme.onSurfaceVariant} />}
          label={t('warStarsTitle')}
          value={`${details.attack.stars}`}
        />
        <WarDetailRow
          icon={<Percent size={18} color={theme.onSurfaceVariant} />}
          label={t('warDestructionTitle')}
          value={`${details.attack.destructionPercentage}%`}
        />
        <WarDetailRow
          icon={<ListOrdered size={18} color={theme.onSurfaceVariant} />}
          label={t('warAttacksDetailsAttackOrder')}
          value={`${details.attack.order}`}
        />
        <WarDetailRow
          icon={<Swords size={18} color={theme.onSurfaceVariant} />}
          label={t('filtersWarType')}
          value={warTypeLabel(warDetails.warType, t)}
        />
      </WarDetailCard>
      <WarDetailCard
        title={t('warInformationTitle')}
        icon={<Info size={20} color={theme.primary} />}
      >
        <WarDetailRow
          icon={<Info size={18} color={theme.onSurfaceVariant} />}
          label={t('warDataState')}
          value={warStateLabel(warDetails.state, t)}
        />
        <WarDetailRow
          icon={<Users size={18} color={theme.onSurfaceVariant} />}
          label={t('warTeamSize')}
          value={warDetails.teamSize?.toString() ?? unknown}
        />
        <WarDetailRow
          icon={<Swords size={18} color={theme.onSurfaceVariant} />}
          label={t('warDataAttacksPerMember')}
          value={warDetails.attacksPerMember?.toString() ?? unknown}
        />
        {warDetails.startTime ? (
          <WarDetailRow
            icon={<Gamepad2 size={18} color={theme.onSurfaceVariant} />}
            label={t('warDataStartTime')}
            value={formatWarDateTime(warDetails.startTime, locale)}
          />
        ) : null}
        {warDetails.endTime ? (
          <WarDetailRow
            icon={<Flag size={18} color={theme.onSurfaceVariant} />}
            label={t('warDataEndTime')}
            value={formatWarDateTime(warDetails.endTime, locale)}
          />
        ) : null}
      </WarDetailCard>
      {warDetails.clan && warDetails.opponent ? (
        <WarClanComparison clan={warDetails.clan} opponent={warDetails.opponent} />
      ) : null}
      <WarDetailCard title={t('warPlayersTitle')} icon={<Users size={20} color={theme.primary} />}>
        <WarPlayerDetail
          title={t('warAttacksDetailsAttacker')}
          player={details.attack.attacker}
          tone="#1976D2"
        />
        <WarPlayerDetail
          title={t('warAttacksDetailsDefender')}
          player={details.attack.defender}
          tone="#D32F2F"
        />
      </WarDetailCard>
    </ScrollView>
  );
}

function WarDetailCard({
  title,
  icon,
  children,
}: {
  title: string;
  icon: ReactNode;
  children: ReactNode;
}) {
  const theme = useCKTheme();
  return (
    <Surface radius={ckRadius.control} style={styles.warDetailCard}>
      <View
        style={[
          styles.warDetailCardHeader,
          { backgroundColor: colorWithAlpha(theme.primary, 0.1) },
        ]}
      >
        {icon}
        <CKText role="rowTitle" style={{ color: theme.primary }}>
          {title}
        </CKText>
      </View>
      <View style={styles.warDetailCardBody}>{children}</View>
    </Surface>
  );
}

function WarDetailRow({ icon, label, value }: { icon: ReactNode; label: string; value: string }) {
  return (
    <View style={styles.warDetailRow}>
      {icon}
      <CKText muted style={styles.grow}>
        {label}
      </CKText>
      <CKText role="labelLarge">{value}</CKText>
    </View>
  );
}

function WarClanComparison({
  clan,
  opponent,
}: {
  clan: NonNullable<PlayerWarStatsData['warDetails']['clan']>;
  opponent: NonNullable<PlayerWarStatsData['warDetails']['opponent']>;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <WarDetailCard title={t('warResultsTitle')} icon={<Swords size={20} color={theme.primary} />}>
      <View style={styles.warClanNames}>
        <CKText role="rowTitle" style={styles.grow} numberOfLines={1}>
          {clan.name}
        </CKText>
        <Swords size={18} color={theme.onSurfaceVariant} />
        <CKText role="rowTitle" style={[styles.grow, styles.alignEnd]} numberOfLines={1}>
          {opponent.name}
        </CKText>
      </View>
      <View style={styles.warClanComparison}>
        <WarClanStats clan={clan} />
        <View style={styles.warClanDivider} />
        <WarClanStats clan={opponent} />
      </View>
    </WarDetailCard>
  );
}

function WarClanStats({ clan }: { clan: NonNullable<PlayerWarStatsData['warDetails']['clan']> }) {
  const { t } = useI18n();
  return (
    <View style={styles.warClanStats}>
      <Metric label={t('warDataClanLevel')} value={`${clan.clanLevel}`} />
      <Metric label={t('warDataTotalStars')} value={`${clan.stars}`} />
      <Metric label={t('warAttacksTitle')} value={`${clan.attacks}`} />
      <Metric
        label={t('warDataDestructionPercentage')}
        value={`${clan.destructionPercentage.toFixed(1)}%`}
      />
    </View>
  );
}

function WarPlayerDetail({
  title,
  player,
  tone,
}: {
  title: string;
  player: WarAttackSnapshot['attacker'];
  tone: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <View
      style={[
        styles.warPlayerDetail,
        { backgroundColor: colorWithAlpha(tone, 0.1), borderColor: colorWithAlpha(tone, 0.25) },
      ]}
    >
      <CKText role="rowTitle" style={{ color: tone }}>
        {title}
      </CKText>
      <WarDetailRow
        icon={<UserRound size={16} color={theme.onSurfaceVariant} />}
        label={t('warAttacksDetailsName')}
        value={player?.name ?? t('generalUnknown')}
      />
      <WarDetailRow
        icon={<Trophy size={16} color={theme.onSurfaceVariant} />}
        label={t('gameTownHallLevel')}
        value={player?.townhallLevel?.toString() ?? t('generalUnknown')}
      />
      <WarDetailRow
        icon={<MapPin size={16} color={theme.onSurfaceVariant} />}
        label={t('warPositionMap')}
        value={player?.mapPosition?.toString() ?? t('generalUnknown')}
      />
    </View>
  );
}

function SummaryPill({ label, value }: { label: string; value: string }) {
  return (
    <PillSurface>
      <CKText role="labelSmall">{label}</CKText>
      <CKText role="labelLarge">{value}</CKText>
    </PillSurface>
  );
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
  const { t } = useI18n();
  const theme = useCKTheme();
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
  const events = filteredJoinLeaveEvents(page, eventType);
  const sortedTotals = sortedJoinLeaveTotals(totals ?? [], totalsSort);
  const totalMinutes = (totals ?? []).reduce((sum, total) => sum + total.minutes, 0);
  return (
    <View style={styles.sections}>
      <View testID="player-join-leave-toolbar" style={styles.toolbar}>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.grow}>
          <View style={styles.wrap}>
            {view === 'events' ? (
              <>
                <JoinLeaveSummaryChip
                  icon={<Repeat2 size={15} color={theme.primary} />}
                  value={`${page.available}`}
                  label={t('warEventsTitle')}
                  color={theme.primary}
                />
                <JoinLeaveSummaryChip
                  icon={<Shield size={15} color={theme.primary} />}
                  value={`${(totals ?? []).length}`}
                  label={t('statsClans')}
                  color={theme.primary}
                />
              </>
            ) : (
              <>
                <JoinLeaveSummaryChip
                  icon={<Shield size={15} color={theme.primary} />}
                  value={`${(totals ?? []).length}`}
                  label={t('statsClans')}
                  color={theme.primary}
                />
                <JoinLeaveSummaryChip
                  icon={<Clock3 size={15} color="#009688" />}
                  value={joinLeaveDuration(totalMinutes)}
                  label={t('playerJoinLeaveTime')}
                  color="#009688"
                />
              </>
            )}
          </View>
        </ScrollView>
        <View testID="player-join-leave-view-control" style={styles.joinLeaveTrailingControl}>
          <FilterDropdown
            value={view}
            fillWidth
            showIcon={false}
            choices={[
              ['events', t('generalHistory')],
              ['clans', t('playerJoinLeaveClanTotals')],
            ]}
            onSelect={(v) => setView(v as typeof view)}
          />
        </View>
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={t('generalFilters')}
          accessibilityState={{ expanded: filtersExpanded }}
          testID="player-join-leave-filter-control"
          onPress={() => setFiltersExpanded((value) => !value)}
        >
          <PillSurface style={styles.compactFilterButton}>
            <Filter size={17} color={theme.onSurfaceVariant} />
          </PillSurface>
        </Pressable>
      </View>
      {filtersExpanded ? (
        view === 'events' ? (
          <View
            testID="player-join-leave-filter-options"
            style={[styles.wrap, styles.trailingChoices]}
          >
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
                  <LogIn key="join" size={16} color="#4CAF50" />,
                  '#4CAF50',
                ],
                [
                  'leave',
                  t('joinLeaveLeave'),
                  <LogOut key="leave" size={16} color="#FF5252" />,
                  '#FF5252',
                ],
              ] as const
            ).map(([key, label, icon, color]) => (
              <Choice
                key={key}
                label={label}
                icon={icon}
                accent={color}
                selected={eventType === key}
                onPress={() => setEventType(key as typeof eventType)}
              />
            ))}
          </View>
        ) : (
          <View
            testID="player-join-leave-filter-options"
            style={[styles.wrap, styles.trailingChoices]}
          >
            {(
              [
                [
                  'time',
                  t('playerJoinLeaveTimeSpent'),
                  <Clock3 key="time" size={16} color="#009688" />,
                  '#009688',
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
                onPress={() => setTotalsSort(key as typeof totalsSort)}
              />
            ))}
          </View>
        )
      ) : null}
      {view === 'events' ? (
        <>
          {events.map((event, index) => (
            <Surface
              key={`${event.time.toISOString()}-${index}`}
              radius={ckRadius.tile}
              style={styles.rowCard}
            >
              {event.clan?.badge ? (
                <MobileWebImage imageUrl={event.clan.badge} style={styles.rowImage} />
              ) : (
                <View style={styles.rowImageFallback}>
                  <Shield color={theme.onSurfaceVariant} />
                </View>
              )}
              <View style={styles.grow}>
                <CKText role="rowTitle">{event.clan?.name || event.clan?.tag || ''}</CKText>
                <CKText muted>{joinLeaveRelativeTime(event.time, t)}</CKText>
              </View>
              <View style={styles.joinLeaveMovement}>
                {event.type.toLowerCase().includes('join') ? (
                  <LogIn size={18} color="#4CAF50" />
                ) : (
                  <LogOut size={18} color="#FF5252" />
                )}
                <CKText>
                  {event.type.toLowerCase().includes('join')
                    ? t('playerJoinLeaveJoined')
                    : t('playerJoinLeaveLeft')}
                </CKText>
              </View>
            </Surface>
          ))}
          {!events.length ? (
            <EmptyState
              title={
                eventType === 'all' ? t('playerJoinLeaveNoHistory') : t('generalNoFilteredResults')
              }
            />
          ) : null}
          {page.items.length < page.available ? (
            loadingMore ? (
              <View testID="join-leave-pagination-skeleton" style={styles.rowCard}>
                <Skeleton width={48} height={48} radius={24} />
                <View style={[styles.grow, styles.sections]}>
                  <Skeleton width={180} />
                  <Skeleton width={120} height={12} />
                </View>
              </View>
            ) : null
          ) : null}
        </>
      ) : (
        <>
          {sortedTotals.map((total) => (
            <Surface key={total.clan.tag} radius={ckRadius.tile} style={styles.rowCard}>
              <MobileWebImage imageUrl={total.clan.badge} style={styles.rowImage} />
              <View style={styles.grow}>
                <CKText role="rowTitle">{total.clan.name || total.clan.tag}</CKText>
                <View style={styles.row}>
                  <CKText style={{ color: '#009688' }}>{joinLeaveDuration(total.minutes)}</CKText>
                  <CKText muted>{t('playerJoinLeaveTimeSpent')}</CKText>
                </View>
              </View>
              <PillSurface style={styles.joinLeaveVisitChip}>
                <Repeat2 size={15} color={theme.primary} />
                <CKText role="labelLarge">{total.visits}</CKText>
                <CKText role="labelSmall">{t('playerJoinLeaveVisits')}</CKText>
              </PillSurface>
            </Surface>
          ))}
          {!sortedTotals.length ? <EmptyState title={t('playerJoinLeaveNoClanTotals')} /> : null}
        </>
      )}
    </View>
  );
}

function JoinLeaveSummaryChip({
  icon,
  value,
  label,
  color,
}: {
  icon: ReactNode;
  value: string;
  label: string;
  color: string;
}) {
  return (
    <View
      style={[
        styles.joinLeaveSummaryChip,
        { backgroundColor: colorWithAlpha(color, 0.12), borderColor: colorWithAlpha(color, 0.3) },
      ]}
    >
      {icon}
      <CKText role="labelLarge">{value}</CKText>
      <CKText muted role="labelSmall">
        {label}
      </CKText>
    </View>
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
  if (
    model.loadingTabs?.has(tab) &&
    !(tab === 'joinLeave' && model.joinLeave?.items.length) &&
    !(tab === 'war' && model.warStats)
  )
    return <LoadingIndicator label={t('generalLoading')} />;
  const error = model.errorByTab?.[tab];
  if (
    error &&
    !(tab === 'joinLeave' && model.joinLeave?.items.length) &&
    !(tab === 'war' && model.warStats)
  )
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

function Segmented({
  choices,
  selected,
  onSelect,
  scroll = false,
  testIDPrefix,
}: {
  choices: readonly (readonly [string, string])[];
  selected: string;
  onSelect: (value: string) => void;
  scroll?: boolean;
  testIDPrefix?: string;
}) {
  const theme = useCKTheme();
  const content = (
    <View style={styles.segmented}>
      {choices.map(([value, label]) => (
        <Pressable
          key={value}
          testID={testIDPrefix ? `${testIDPrefix}-${value}` : undefined}
          accessibilityRole="radio"
          accessibilityState={{ selected: value === selected }}
          onPress={() => onSelect(value)}
          style={[
            styles.segment,
            value === selected && { backgroundColor: colorWithAlpha(theme.primary, 0.16) },
          ]}
        >
          <CKText
            role="labelLarge"
            style={value === selected ? { color: theme.primary } : undefined}
          >
            {label}
          </CKText>
        </Pressable>
      ))}
    </View>
  );
  return scroll ? (
    <ScrollView horizontal showsHorizontalScrollIndicator={false}>
      {content}
    </ScrollView>
  ) : (
    content
  );
}

function FilterDropdown({
  value,
  choices,
  onSelect,
  fillWidth = false,
  icon,
  showIcon = true,
}: {
  value: string;
  choices: readonly (readonly [string, string])[];
  onSelect: (value: string) => void;
  fillWidth?: boolean;
  icon?: ReactNode;
  showIcon?: boolean;
}) {
  const theme = useCKTheme();
  const selected = choices.find(([key]) => key === value)?.[1] ?? value;
  return (
    <SelectionPicker
      accessibilityLabel={selected}
      fillWidth={fillWidth}
      leading={showIcon ? (icon ?? <Filter size={16} color={theme.onSurfaceVariant} />) : undefined}
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
function SeasonPicker({
  value,
  maximum,
  onChange,
}: {
  value: string;
  maximum: Date;
  onChange: (value: string) => void;
}) {
  const { t, locale } = useI18n();
  const [rawYear, rawMonth] = value.split('-');
  const selectedYear = Number(rawYear) || maximum.getFullYear();
  const selectedMonth = Number(rawMonth) || maximum.getMonth() + 1;
  const years = Array.from(
    { length: maximum.getFullYear() - 2019 },
    (_, index) => maximum.getFullYear() - index,
  );
  const months = Array.from({ length: 12 }, (_, index) => index + 1);
  const update = (year: number, month: number) =>
    onChange(`${year}-${String(month).padStart(2, '0')}`);
  return (
    <View style={styles.section}>
      <CKText role="rowTitle">{t('filtersYear')}</CKText>
      <ScrollView horizontal showsHorizontalScrollIndicator={false}>
        <View style={styles.wrap}>
          {years.map((year) => (
            <Choice
              key={year}
              label={`${year}`}
              selected={year === selectedYear}
              onPress={() => update(year, selectedMonth)}
            />
          ))}
        </View>
      </ScrollView>
      <CKText role="rowTitle">{t('filtersMonth')}</CKText>
      <View style={styles.wrap}>
        {months.map((month) => (
          <Choice
            key={month}
            label={new Intl.DateTimeFormat(toIntlLocale(locale), { month: 'short' }).format(
              new Date(2026, month - 1, 1),
            )}
            selected={month === selectedMonth}
            onPress={() => update(selectedYear, month)}
          />
        ))}
      </View>
    </View>
  );
}
function FilterField({
  label,
  value,
  onChangeText,
  numeric = false,
  testID,
}: {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  numeric?: boolean;
  testID?: string;
}) {
  const theme = useCKTheme();
  return (
    <View style={styles.filterField}>
      <CKText muted role="labelSmall">
        {label}
      </CKText>
      <TextInput
        testID={testID}
        accessibilityLabel={label}
        value={value}
        onChangeText={onChangeText}
        keyboardType={numeric ? 'number-pad' : 'default'}
        placeholderTextColor={theme.onSurfaceVariant}
        style={[styles.filterInput, { color: theme.onSurface }]}
      />
    </View>
  );
}
function Metric({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.metric}>
      <CKText role="titleMedium">{value}</CKText>
      <CKText muted role="labelSmall">
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
function warTypeLabel(value: string | null | undefined, t: ReturnType<typeof useI18n>['t']) {
  if (value === 'cwl') return t('cwlTitle');
  if (value === 'friendly') return t('warFiltersFriendly');
  if (value === 'random') return t('warFiltersRandom');
  return t('filtersAllWars');
}
function normalizedWarType(value: string | null | undefined) {
  const type = value?.toLowerCase();
  return type === 'cwl' || type === 'friendly' ? type : 'random';
}
function warStateLabel(value: string, t: ReturnType<typeof useI18n>['t']) {
  if (value.toLowerCase() === 'warended') return t('warEnded');
  if (value.toLowerCase() === 'inwar') return t('warInWar');
  if (value.toLowerCase() === 'preparation') return t('warPreparation');
  return value || t('generalUnknown');
}
function formatWarDateTime(value: Date, locale: string) {
  return new Intl.DateTimeFormat(toIntlLocale(locale), {
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    hour: 'numeric',
    minute: '2-digit',
  }).format(value);
}
function performanceScaleColor(performance: number) {
  if (performance >= 0.8) return '#43A047';
  if (performance >= 0.6) return '#FB8C00';
  if (performance >= 0.4) return '#F9A825';
  return '#E53935';
}
function warStarColor(stars: number, isAttack: boolean) {
  const score = isAttack ? stars : 3 - stars;
  if (score >= 3) return '#43A047';
  if (score >= 2) return '#FB8C00';
  if (score >= 1) return '#F9A825';
  return '#E53935';
}
function heatmapPerformanceColor(stars: number, showDefense: boolean) {
  const performance = showDefense ? 3 - stars : stars;
  if (performance >= 2.5) return '#43A047';
  if (performance >= 2) return '#F9A825';
  if (performance >= 1) return '#FB8C00';
  return '#E53935';
}
function heatmapTownHallLevels(
  stats: Readonly<Record<string, EnemyTownhallStats>>,
  playerTownHall: number,
  showDefense: boolean,
) {
  const playerLevels = new Set<number>();
  const opponentLevels = new Set<number>();
  for (const [key, value] of Object.entries(stats)) {
    if (value.count <= 0) continue;
    const match = /^(\d+)vs(\d+)$/.exec(key);
    if (!match) continue;
    const attacker = Number(match[1]);
    const defender = Number(match[2]);
    playerLevels.add(showDefense ? defender : attacker);
    opponentLevels.add(showDefense ? attacker : defender);
  }
  if (!playerLevels.size && !opponentLevels.size) {
    const minimum = Math.max(1, Math.min(17, playerTownHall - 2));
    const maximum = Math.max(1, Math.min(17, playerTownHall + 2));
    const fallback = Array.from({ length: maximum - minimum + 1 }, (_, index) => minimum + index);
    return { playerLevels: fallback, opponentLevels: fallback };
  }
  return {
    playerLevels: [...playerLevels].sort((left, right) => left - right),
    opponentLevels: [...opponentLevels].sort((left, right) => left - right),
  };
}
function builtInFilterLabel(name: string, t: ReturnType<typeof useI18n>['t']) {
  if (name === 'Last 30 days') return t('filtersLast30Days');
  if (name === '3 stars') return t('filters3StarOnly');
  if (name === 'Fresh') return t('filtersFreshAttacks');
  return warTypeLabel(name.toLowerCase(), t);
}
function performanceSuggestionText(name: string, t: ReturnType<typeof useI18n>['t']) {
  if (name === 'Failed Attacks (0-1 Stars)')
    return {
      label: t('performanceAnalysisFailedAttacks'),
      description: t('performanceAnalysisFailedAttacksDesc'),
    };
  if (name === 'Missed Perfect Attacks')
    return {
      label: t('performanceAnalysisMissedPerfects'),
      description: t('performanceAnalysisMissedPerfectsDesc'),
    };
  if (name === 'CWL Performance Issues')
    return {
      label: t('performanceAnalysisCwlIssues'),
      description: t('performanceAnalysisCwlIssuesDesc'),
    };
  if (name === 'Random War Issues')
    return {
      label: t('performanceAnalysisRandomWarIssues'),
      description: t('performanceAnalysisRandomWarIssuesDesc'),
    };
  if (name === 'Fresh Attack Analysis')
    return {
      label: t('performanceAnalysisFreshOnly'),
      description: t('performanceAnalysisFreshOnlyDesc'),
    };
  if (name === 'Recent Performance (30 Days)')
    return {
      label: t('performanceAnalysisRecentPerformance'),
      description: t('performanceAnalysisRecentPerformanceDesc'),
    };
  if (name === 'High-Stakes Attacks')
    return {
      label: t('performanceAnalysisHighStakes'),
      description: t('performanceAnalysisHighStakesDesc'),
    };
  if (name === 'Cleanup Attacks')
    return {
      label: t('performanceAnalysisCleanupCrew'),
      description: t('performanceAnalysisCleanupCrewDesc'),
    };
  const th = Number(name.match(/TH(\d+)/)?.[1]);
  if (name.includes('Attack Issues'))
    return {
      label: t('performanceAnalysisThAttackIssues', { thLevel: th }),
      description: t('performanceAnalysisThAttackIssuesDesc', { thLevel: th }),
    };
  if (name.includes('Defense Issues'))
    return {
      label: t('performanceAnalysisThDefenseIssues', { thLevel: th }),
      description: t('performanceAnalysisThDefenseIssuesDesc', { thLevel: th }),
    };
  return { label: name, description: name };
}
function parseFilterNumber(value: string) {
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : null;
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
function parseFilterNumbers(value: string) {
  const values = value
    .split(',')
    .map((part) => parseFilterNumber(part))
    .filter((part): part is number => part !== null);
  return values.length ? values : null;
}
function parseFilterDate(value: string) {
  if (!value.trim()) return null;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}
function formatLocalFilterDate(value: Date) {
  return `${value.getFullYear()}-${String(value.getMonth() + 1).padStart(2, '0')}-${String(value.getDate()).padStart(2, '0')}`;
}
function average(values: readonly number[]) {
  return values.length ? values.reduce((sum, value) => sum + value, 0) / values.length : 0;
}

const styles = StyleSheet.create({
  grow: { flex: 1 },
  centerText: { textAlign: 'center' },
  centeredWrap: { justifyContent: 'center' },
  superTroopImage: { width: 50, height: 50, borderRadius: 6 },
  header: {
    paddingBottom: 0,
    overflow: 'hidden',
    justifyContent: 'flex-start',
  },
  headerScrim: { backgroundColor: '#00000080' },
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
  iconAction: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  identity: { alignItems: 'center', justifyContent: 'center' },
  identityDesktop: { flexDirection: 'row', gap: 52, paddingHorizontal: 28 },
  identityCompact: { flexDirection: 'column', gap: 2, paddingHorizontal: 4, marginTop: 6 },
  identityCopy: { flex: 1, minWidth: 0, gap: 4 },
  identityCopyCompact: { flex: 0, alignItems: 'center', width: '100%', gap: 2 },
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
  leagueTilesCompact: { paddingHorizontal: 16 },
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
  quickStat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
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
    maxWidth: 1120,
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
  cwlTrailing: { minWidth: 108, alignItems: 'flex-end', alignSelf: 'stretch' },
  cwlSeasonDate: { fontWeight: '700', marginBottom: 10 },
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
  trackingLabel: { maxWidth: 116 },
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
  warStatsSection: { overflow: 'hidden', gap: 8, paddingBottom: 8 },
  warStatPair: { flexDirection: 'row', gap: 8, paddingHorizontal: 8 },
  enhancedStatCard: { flex: 1, minWidth: 0, gap: 5, padding: 10 },
  warStatHeadline: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center' },
  warPerformanceTrack: {
    width: 80,
    height: 8,
    overflow: 'hidden',
    borderRadius: 999,
    backgroundColor: '#80808044',
  },
  warPerformanceFill: { height: '100%', borderRadius: 999 },
  warStarBreakdown: { alignItems: 'center', gap: 2 },
  warStarBreakdownRow: { width: 124, flexDirection: 'row', alignItems: 'center' },
  warStarLabel: { width: 54, textAlign: 'center' },
  warMissedPill: { flexDirection: 'row', alignItems: 'center', gap: 4, padding: 5 },
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
  joinLeaveMovement: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  battleCard: { minHeight: 120, gap: 8, paddingHorizontal: 12, paddingVertical: 8 },
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
  joinLeaveSummaryChip: {
    height: 30,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 999,
  },
  joinLeaveVisitChip: {
    minHeight: 32,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
  },
  joinLeaveTrailingControl: {
    width: 160,
    minWidth: 130,
    maxWidth: 180,
    marginLeft: 'auto',
    flexShrink: 1,
  },
  directionBadge: { width: 64, alignItems: 'center', padding: 5, borderRadius: ckRadius.tile },
  subRow: {
    minHeight: 42,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 8,
  },
  toolbar: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  filterButton: { width: 48, height: 48, alignItems: 'center', justifyContent: 'center' },
  compactFilterButton: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  wrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  trailingChoices: { justifyContent: 'flex-end' },
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
