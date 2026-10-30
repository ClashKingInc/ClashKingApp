import { useEffect, useState, useCallback } from 'react';
import { RefreshControl, ScrollView, StyleSheet, View, useWindowDimensions } from 'react-native';
import { ArrowLeft, ChevronRight, Settings2, UserRound } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { illustratedHeaderLayout } from '../../../ui/illustrated-header-layout';
import { ResponsiveGrid } from '../../../ui/responsive-grid';
import { HeaderArtwork } from '../../../ui/header-artwork';
import { HeroHeaderScrim } from '../../../ui/hero-header-scrim';
import { InlineBackControl } from '../../../ui/native-back-context';
import { useAppRuntime } from '../../../core/app/runtime-context';
import { ImageAssets } from '../../../core/assets/image-assets';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  MobileWebImage,
  PressableSurface,
  ProfileHeaderAction,
  ProfileTabs,
  Skeleton,
  useSkeletonContent,
  ckRadius,
  ckSpacing,
  useCKTheme,
  useCKAccessibility,
} from '../../../ui';
import type { AuthUser } from '../../auth/models';
import type { Player } from '../../player/models/player';
import type { LinkedAccountItem } from './contracts';
import {
  AchievementTile,
  AchievementDetail,
  useAchievementsSnapshot,
} from '../../achievements/presentation/achievements-screen';
import { AchievementModelViewer } from '../../achievements/presentation/achievement-model-viewer';
import {
  ACHIEVEMENT_COPY_KEYS,
  achievementColumnCount,
} from '../../achievements/presentation/contracts';
import { ACHIEVEMENT_CATALOG_FALLBACK, type Achievement } from '../../achievements/models';

/** Retain the original profile's artwork and layout without its deferred
 * tournament dependencies. Identity is shared by email and Discord accounts. */
export function UserProfileScreen({
  user,
  accounts,
  onBack,
  onAddAccount,
  onOpenPlayer,
}: {
  user: AuthUser | null;
  accounts: readonly LinkedAccountItem[];
  onBack: () => void;
  onAddAccount: () => void;
  onOpenPlayer: (tag: string) => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const runtime = useAppRuntime();
  const insets = useSafeAreaInsets();
  const layout = useAdaptiveLayout();
  const headerLayout = illustratedHeaderLayout(layout);
  const [tab, setTab] = useState('accounts');
  const [refreshing, setRefreshing] = useState(false);
  const verifiedAccounts = accounts.filter((account) => account.isVerified);
  const refresh = async () => {
    setRefreshing(true);
    try {
      await runtime.accountBootstrap.initialize(user?.userId ?? null);
    } finally {
      setRefreshing(false);
    }
  };
  return (
    <ScrollView
      style={{ flex: 1, backgroundColor: theme.background }}
      contentContainerStyle={[
        styles.page,
        (layout.isExpanded || layout.isDuo) && { maxWidth: layout.contentMaxWidth },
      ]}
      refreshControl={
        <RefreshControl
          refreshing={refreshing}
          onRefresh={() => void refresh().catch(() => undefined)}
          tintColor={theme.primary}
        />
      }
    >
      <View
        style={[
          styles.header,
          {
            minHeight: (layout.isExpanded ? headerLayout.minHeight : 236) + insets.top,
            paddingTop: ckSpacing.lg + insets.top,
            ...(layout.isExpanded
              ? { paddingHorizontal: headerLayout.horizontal, paddingBottom: headerLayout.bottom }
              : {}),
          },
        ]}
      >
        <HeaderArtwork
          source={require('../../../../assets/clashking/profile/profile-selected-banner.png')}
          style={StyleSheet.absoluteFill}
          contentFit="cover"
          contentPosition="center"
        />
        <HeroHeaderScrim edgeColor={theme.background} />
        <View style={{ position: 'absolute', top: insets.top + 8, left: 14 }}>
          <InlineBackControl onBack={onBack}>
            <ProfileHeaderAction
              label={materialBackLabel(locale)}
              icon={<ArrowLeft color="#fff" size={23} />}
              onPress={onBack}
            />
          </InlineBackControl>
        </View>
        <View
          style={[
            styles.identity,
            layout.isExpanded && { gap: headerLayout.gap, minHeight: headerLayout.bodyMinHeight },
          ]}
        >
          <View
            style={[
              styles.avatar,
              layout.isExpanded && { width: headerLayout.image, height: headerLayout.image },
            ]}
          >
            {user?.avatarUrl ? (
              <MobileWebImage
                imageUrl={user.avatarUrl}
                contentFit="cover"
                style={{ width: '100%', height: '100%' }}
                errorFallback={<UserRound size={34} color="#fff" />}
              />
            ) : (
              <UserRound size={34} color="#fff" />
            )}
          </View>
          <View style={styles.identityText}>
            <CKText
              role="screenTitle"
              style={[
                styles.name,
                { color: '#fff' },
                layout.isExpanded && {
                  fontSize: headerLayout.title,
                  lineHeight: headerLayout.titleLine,
                },
              ]}
            >
              {user?.username || t('competitiveProfile')}
            </CKText>
          </View>
        </View>
      </View>
      <ProfileTabs
        variant="underline"
        overflow="menu"
        selectedKey={tab}
        onSelect={setTab}
        tabs={[
          { key: 'accounts', label: t('accountsMenuTitle') },
          { key: 'achievements', label: t('achievementsTitle') },
          { key: 'tournaments', label: t('competitiveTournaments') },
        ]}
      />
      {tab === 'accounts' ? (
        <View style={styles.section}>
          <PressableSurface
            accessibilityRole="button"
            accessibilityLabel={t('drawerManageAccounts')}
            style={styles.manageAccounts}
            onPress={onAddAccount}
          >
            <Settings2 size={16} color={theme.onSurfaceVariant} />
            <CKText role="metadata" muted>
              {t('drawerManageAccounts')}
            </CKText>
            <ChevronRight size={16} color={theme.onSurfaceVariant} />
          </PressableSurface>
          {verifiedAccounts.length ? (
            layout.isExpanded ? (
              <ResponsiveGrid minItemWidth={360} maxColumns={layout.columns(360, 2)} gap={16}>
                {verifiedAccounts.map((account) => (
                  <ProfileAccount
                    key={account.playerTag}
                    account={account}
                    onOpenPlayer={onOpenPlayer}
                  />
                ))}
              </ResponsiveGrid>
            ) : (
              verifiedAccounts.map((account) => (
                <ProfileAccount
                  key={account.playerTag}
                  account={account}
                  onOpenPlayer={onOpenPlayer}
                />
              ))
            )
          ) : (
            <CKText muted>{t('accountsNoneFound')}</CKText>
          )}
        </View>
      ) : tab === 'achievements' ? (
        <ProfileAchievements />
      ) : (
        <View style={{ paddingVertical: 36, alignItems: 'center' }}>
          <CKText muted>{t('generalComingSoon')}</CKText>
        </View>
      )}
    </ScrollView>
  );
}

function ProfileAccount({
  account,
  onOpenPlayer,
}: {
  account: LinkedAccountItem;
  onOpenPlayer: (tag: string) => void;
}) {
  const runtime = useAppRuntime();
  const contentLoading = useSkeletonContent();
  const theme = useCKTheme();
  const { t, locale } = useI18n();
  const [player, setPlayer] = useState<Player | undefined>(() =>
    runtime.players.profiles.find((item) => item.tag === account.playerTag),
  );
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    if (contentLoading) return;
    let active = true;
    // Reuse the player service's deduplicated, short-lived current-data cache.
    // Only enrich accounts returned by the verified profile endpoint; never
    // infer profile ownership from locally bookmarked or searched players.
    void runtime.players
      .getPlayerAndClanData(account.playerTag)
      .then((value) => {
        if (active) setPlayer(value);
      })
      .catch(() => undefined)
      .finally(() => {
        if (active) setLoading(false);
      });
    return () => {
      active = false;
    };
  }, [runtime.players, account.playerTag, contentLoading]);
  const townHall = player?.townHallLevel ?? account.townHallLevel;
  return (
    <PressableSurface
      accessibilityRole="button"
      onPress={() => onOpenPlayer(account.playerTag)}
      style={[styles.row, { backgroundColor: theme.card }]}
    >
      {townHall ? (
        <MobileWebImage
          imageUrl={ImageAssets.townHall(townHall)}
          style={{ width: 56, height: 56 }}
        />
      ) : null}
      <View style={{ flex: 1, minWidth: 0, gap: 6 }}>
        <CKText role="rowTitle">{player?.name ?? account.name}</CKText>
        {player ? (
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6, flexWrap: 'wrap' }}>
            {player.league.toLowerCase() !== 'unranked' && player.leagueUrl ? (
              <>
                <MobileWebImage imageUrl={player.leagueUrl} style={{ width: 24, height: 24 }} />
                <CKText role="metadata">
                  {new Intl.NumberFormat(toIntlLocale(locale)).format(player.trophies)}
                </CKText>
              </>
            ) : (
              <>
                <MobileWebImage
                  imageUrl={ImageAssets.getLeagueImage('Unranked')}
                  style={{ width: 24, height: 24 }}
                />
                <CKText role="metadata" muted>
                  {t('generalUnranked')}
                </CKText>
              </>
            )}
            {player.clanOverview.tag ? (
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5, flexShrink: 1 }}>
                <MobileWebImage
                  imageUrl={player.clanOverview.badgeUrls.small}
                  style={{ width: 22, height: 22 }}
                />
                <CKText muted role="metadata" numberOfLines={1}>
                  {player.clanOverview.name}
                </CKText>
              </View>
            ) : null}
          </View>
        ) : loading ? (
          <Skeleton width={126} height={18} />
        ) : null}
      </View>
      <ChevronRight size={20} color={theme.onSurfaceVariant} />
    </PressableSurface>
  );
}

function ProfileAchievements() {
  const runtime = useAppRuntime();
  const snapshot = useAchievementsSnapshot(runtime.achievements);
  const { t } = useI18n();
  const { height, fontScale } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const { reduceMotion } = useCKAccessibility();
  const [selected, setSelected] = useState<Achievement>();
  const [gridWidth, setGridWidth] = useState(0);
  const [modelBudget, setModelBudget] = useState(0);
  const measure = useCallback(
    ({ nativeEvent }: { nativeEvent: { layout: { width: number } } }) =>
      setGridWidth(nativeEvent.layout.width),
    [],
  );
  const achievements = snapshot.achievements.length
    ? snapshot.achievements
    : ACHIEVEMENT_CATALOG_FALLBACK;
  useEffect(() => {
    void runtime.achievements.load().catch(() => undefined);
  }, [runtime.achievements]);
  useEffect(() => {
    if (modelBudget >= achievements.length) return;
    const frame = requestAnimationFrame(() => setModelBudget((count) => count + 1));
    return () => cancelAnimationFrame(frame);
  }, [modelBudget, achievements.length]);
  const columns = layout.isExpanded
    ? Math.max(1, Math.min(4, Math.floor((gridWidth + 16) / (232 * Math.max(1, fontScale) + 16))))
    : achievementColumnCount(gridWidth);
  const tileWidth = Math.max(0, (gridWidth - ckSpacing.md * (columns - 1)) / columns);
  return (
    <View style={styles.achievements} onLayout={measure}>
      {gridWidth > 0
        ? achievements.map((achievement, index) => (
            <AchievementTile
              key={achievement.id}
              achievement={achievement}
              modelRenderer={AchievementModelViewer}
              showModel={index < modelBudget}
              name={t(ACHIEVEMENT_COPY_KEYS[achievement.id].name)}
              subtitle={achievement.earnedCount ? `×${achievement.earnedCount}` : t('widgetLocked')}
              onPress={() => setSelected(achievement)}
              width={tileWidth}
            />
          ))
        : null}
      <AchievementDetail
        achievement={selected}
        bottomInset={24}
        enableIdleRotation={!reduceMotion}
        modelRenderer={AchievementModelViewer}
        onClose={() => setSelected(undefined)}
        sheetHeight={Math.min(height * 0.82, 680)}
      />
    </View>
  );
}
const styles = StyleSheet.create({
  page: {
    padding: ckSpacing.lg,
    paddingTop: 0,
    paddingBottom: 40,
    gap: ckSpacing.md,
    width: '100%',
    maxWidth: 1120,
    alignSelf: 'center',
  },
  header: {
    marginHorizontal: -ckSpacing.lg,
    borderBottomLeftRadius: ckRadius.card,
    borderBottomRightRadius: ckRadius.card,
    padding: ckSpacing.lg,
    overflow: 'hidden',
    minHeight: 236,
    justifyContent: 'flex-end',
  },
  identity: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.md },
  identityText: { flex: 1, minWidth: 0, gap: ckSpacing.xs },
  name: { fontSize: 30, lineHeight: 36 },
  avatar: {
    width: 64,
    height: 64,
    borderRadius: ckRadius.tile,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
  },
  section: { gap: 16 },
  manageAccounts: {
    alignSelf: 'flex-end',
    minHeight: 40,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  row: {
    padding: ckSpacing.md,
    borderRadius: ckRadius.tile,
    borderWidth: 0,
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.md,
  },
  achievements: { flexDirection: 'row', flexWrap: 'wrap', gap: ckSpacing.md },
});
