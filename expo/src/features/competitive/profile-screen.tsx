import { useAdaptiveLayout } from '../../ui/adaptive-layout';
import { illustratedHeaderLayout } from '../../ui/illustrated-header-layout';
import { ResponsiveGrid } from '../../ui/responsive-grid';
import { resolveGridColumns } from '../../ui/layout';
import { useEffect, useState } from 'react';
import {
  useWindowDimensions,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Switch,
  View,
} from 'react-native';
import { ChevronRight, Pencil, Settings2, Share2 } from 'lucide-react-native';
import { HeaderArtwork } from '../../ui/header-artwork';
import { HeroHeaderScrim } from '../../ui/hero-header-scrim';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { ImageAssets } from '../../core/assets/image-assets';
import { useAppRuntime } from '../../core/app/runtime-context';
import { queueAppLink } from '../../core/deep-links/link-inbox';
import { sharePageLink } from '../../core/deep-links/share-page-link';
import { toIntlLocale, useI18n } from '../../i18n';
import {
  CKText,
  SkeletonContent,
  useSkeletonContent,
  MobileWebImage,
  PressableSurface,
  ProfileHeaderAction,
  ProfileTabs,
  Skeleton,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
  useCKAccessibility,
} from '../../ui';
import {
  AchievementTile,
  AchievementDetail,
} from '../achievements/presentation/achievements-screen';
import { AchievementModelViewer } from '../achievements/presentation/achievement-model-viewer';
import type { Achievement } from '../achievements/models';
import { ACHIEVEMENT_COPY_KEYS } from '../achievements/presentation/contracts';
import { ACHIEVEMENT_CATALOG_FALLBACK } from '../achievements/models';
import { BUNDLED_TOURNAMENT_MODEL } from '../achievements/data/achievement-model-cache';
import type { Player } from '../player/models/player';
import {
  type competitiveService,
  type CompetitiveProfile,
  type CompetitiveTeam,
} from './competitive-service';

type ProfileQuery = {
  data?: CompetitiveProfile;
  loading: boolean;
  error?: string;
  refresh: () => void;
  service: ReturnType<typeof competitiveService>;
};

export function CompetitiveProfileScreen({
  query,
  ownProfile,
  onTeam,
  onTournament,
  onManageAccounts,
}: {
  query: ProfileQuery;
  ownProfile: boolean;
  onTeam: (team: CompetitiveTeam) => void;
  onTournament: (id: string) => void;
  onManageAccounts?: () => void;
}) {
  const { t } = useI18n();
  const runtime = useAppRuntime();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const layout = useAdaptiveLayout();
  const headerLayout = illustratedHeaderLayout(layout);
  const [draft, setDraft] = useState<CompetitiveProfile>();
  const [editing, setEditing] = useState(false);
  const [tab, setTab] = useState('accounts');
  const [notice, setNotice] = useState('');
  const [saving, setSaving] = useState(false);
  const loadedProfile = draft ?? query.data;
  const contentLoading = query.loading && !loadedProfile;
  const profile: CompetitiveProfile | undefined =
    loadedProfile ??
    (contentLoading
      ? {
          userId: '',
          displayName: 'ClashKing profile',
          avatarUrl: null,
          discordAvatarUrl: 'loading',
          bannerUrl: null,
          private: false,
          hideDiscord: false,
          bio: '',
          socials: {},
          achievements: [],
          tournamentHistory: [],
          teams: [],
          accounts: [0, 1, 2].map((index) => ({
            tag: `loading-${index}`,
            name: 'Linked player',
            townHallLevel: 1,
          })),
        }
      : undefined);
  const signedInUser = runtime.auth.state.currentUser;
  // Identity photos come only from Discord. Never display a legacy upload
  // returned by an older API or persist a provider photo as custom media.
  const avatarUrl =
    profile?.discordAvatarUrl ||
    (ownProfile &&
    signedInUser?.userId === profile?.userId &&
    signedInUser?.avatarUrl.includes('cdn.discordapp.com/avatars/')
      ? signedInUser.avatarUrl
      : null);
  const allTeams = [...new Map((profile?.teams ?? []).map((team) => [team.id, team])).values()];
  const teams = [
    ...new Map(
      (profile?.teams ?? []).filter((team) => !team.leftAt).map((team) => [team.id, team]),
    ).values(),
  ];
  const change = <K extends keyof CompetitiveProfile>(key: K, value: CompetitiveProfile[K]) => {
    if (profile) setDraft({ ...profile, [key]: value });
  };
  const openTeam = (id: string) => {
    void query.service
      .request<{ team: CompetitiveTeam }>(
        `/competitive/teams/${encodeURIComponent(id)}`,
        'GET',
        undefined,
        true,
      )
      .then(({ team }) => onTeam(team))
      .catch((error: Error) => setNotice(error.message));
  };
  const save = async () => {
    if (!profile) return;
    setSaving(true);
    setNotice('');
    try {
      // About and social links are not editable here. Omit them so a privacy
      // save cannot erase values retained by the API for older clients.
      const next = await query.service.request<CompetitiveProfile>('/competitive/profile', 'PUT', {
        private: profile.private,
      });
      setDraft(next);
      setEditing(false);
      query.refresh();
    } catch (error) {
      setNotice((error as Error).message);
    } finally {
      setSaving(false);
    }
  };
  const cancel = () => {
    setDraft(undefined);
    setEditing(false);
    setNotice('');
  };
  return (
    <ScrollView
      contentContainerStyle={[
        styles.page,
        (layout.isExpanded || layout.isDuo) && { maxWidth: layout.contentMaxWidth },
      ]}
      keyboardShouldPersistTaps="handled"
      refreshControl={
        <RefreshControl
          refreshing={query.loading}
          onRefresh={query.refresh}
          tintColor={theme.primary}
        />
      }
    >
      {query.error ? (
        <ProfileRow
          title={t('competitiveUnavailable')}
          subtitle={query.error}
          onPress={query.refresh}
        />
      ) : null}
      <SkeletonContent loading={contentLoading}>
        {profile ? (
          <>
            <View
              style={[
                styles.header,
                {
                  minHeight: (layout.isExpanded ? headerLayout.minHeight : 236) + insets.top,
                  paddingTop: ckSpacing.lg + insets.top,
                  ...(layout.isExpanded
                    ? {
                        paddingHorizontal: headerLayout.horizontal,
                        paddingBottom: headerLayout.bottom,
                      }
                    : {}),
                },
              ]}
            >
              <HeaderArtwork
                // Original profile-only artwork; do not substitute another page's backdrop.
                source={require('../../../assets/clashking/profile/profile-selected-banner.png')}
                style={StyleSheet.absoluteFill}
                contentFit="cover"
                contentPosition="center"
              />
              <HeroHeaderScrim edgeColor={theme.background} />
              <View
                style={[
                  styles.identity,
                  layout.isExpanded && {
                    gap: headerLayout.gap,
                    minHeight: headerLayout.bodyMinHeight,
                  },
                ]}
              >
                {avatarUrl ? (
                  <MobileWebImage
                    imageUrl={avatarUrl}
                    contentFit="cover"
                    style={[
                      styles.avatar,
                      layout.isExpanded && {
                        width: headerLayout.image,
                        height: headerLayout.image,
                      },
                    ]}
                  />
                ) : null}
                <View style={styles.identityText}>
                  <CKText
                    role="screenTitle"
                    style={[
                      styles.name,
                      { color: '#FFFFFF' },
                      layout.isExpanded && {
                        fontSize: headerLayout.title,
                        lineHeight: headerLayout.titleLine,
                      },
                    ]}
                  >
                    {profile.discordHandle || profile.displayName || t('competitiveProfile')}
                  </CKText>
                </View>
                <View style={styles.headerActions}>
                  {ownProfile && !editing ? (
                    <ProfileHeaderAction
                      label={t('competitiveEditProfile')}
                      icon={<Pencil color="#FFFFFF" size={20} />}
                      onPress={() => {
                        setDraft(query.data);
                        setEditing(true);
                      }}
                    />
                  ) : null}
                  <ProfileHeaderAction
                    label={t('gameAssetsShare')}
                    appLinkShare
                    icon={<Share2 color="#FFFFFF" size={20} />}
                    onPress={() =>
                      void sharePageLink(
                        { kind: 'page', page: 'profile', params: { userId: profile.userId } },
                        profile.discordHandle || profile.displayName || t('competitiveProfile'),
                      ).catch(() => setNotice(t('generalError')))
                    }
                  />
                </View>
              </View>
            </View>
            {teams.length ? (
              <View style={styles.teamBadges}>
                {teams.map((team) => (
                  <PressableSurface
                    key={team.id}
                    onPress={() => openTeam(team.id)}
                    accessibilityLabel={team.clanName}
                    style={[
                      styles.teamBadge,
                      { backgroundColor: colorWithAlpha(theme.onSurface, 0.05) },
                    ]}
                  >
                    <MobileWebImage
                      imageUrl={ImageAssets.warClan}
                      style={{ width: 24, height: 24 }}
                    />
                    <CKText role="metadata">{team.clanName}</CKText>
                    <ChevronRight size={14} color={theme.onSurfaceVariant} />
                  </PressableSurface>
                ))}
              </View>
            ) : null}
            {notice ? <CKText accessibilityLiveRegion="polite">{notice}</CKText> : null}
            {editing && ownProfile ? (
              <View style={styles.section}>
                <CKText role="sectionTitle">{t('competitiveEditProfile')}</CKText>
                <View style={styles.toggle}>
                  <CKText style={{ flex: 1 }}>{t('competitivePrivate')}</CKText>
                  <Switch
                    accessibilityLabel={t('competitivePrivate')}
                    value={profile.private}
                    onValueChange={(value) => change('private', value)}
                  />
                </View>
                <View style={styles.inline}>
                  <ProfileButton
                    primary
                    label={t('presetsSave')}
                    disabled={saving}
                    onPress={() => void save()}
                  />
                  <ProfileButton label={t('generalCancel')} disabled={saving} onPress={cancel} />
                </View>
              </View>
            ) : (
              <>
                <ProfileTabs
                  variant="underline"
                  overflow="menu"
                  selectedKey={tab}
                  onSelect={setTab}
                  tabs={[
                    { key: 'accounts', label: t('accountsMenuTitle') },
                    { key: 'achievements', label: t('achievementsTitle') },
                    { key: 'competition', label: t('competitiveCompetition') },
                  ]}
                />
                {/* Do not keep hidden model renderers running behind another tab. */}
                {tab === 'achievements' ? (
                  <View>
                    <ProfileAchievements
                      awards={profile.achievements ?? []}
                      verifiedCount={profile.verifiedAccountCount}
                    />
                  </View>
                ) : null}
                {tab === 'accounts' ? (
                  <View style={styles.section}>
                    {ownProfile && onManageAccounts ? (
                      <PressableSurface
                        accessibilityRole="button"
                        accessibilityLabel={t('drawerManageAccounts')}
                        style={styles.manageAccounts}
                        onPress={onManageAccounts}
                      >
                        <Settings2 size={16} color={theme.onSurfaceVariant} />
                        <CKText role="metadata" muted>
                          {t('drawerManageAccounts')}
                        </CKText>
                        <ChevronRight size={16} color={theme.onSurfaceVariant} />
                      </PressableSurface>
                    ) : null}
                    {profile.accounts?.length ? (
                      // The profile endpoint only returns verified accounts.
                      // Keep this source even though the tab uses the shorter label.
                      layout.isExpanded ? (
                        <ResponsiveGrid
                          minItemWidth={360}
                          maxColumns={layout.columns(360, 2)}
                          gap={16}
                        >
                          {profile.accounts.map((account) => (
                            <ProfileAccount key={account.tag} account={account} />
                          ))}
                        </ResponsiveGrid>
                      ) : (
                        profile.accounts.map((account) => (
                          <ProfileAccount key={account.tag} account={account} />
                        ))
                      )
                    ) : (
                      <ProfileEmpty />
                    )}
                  </View>
                ) : null}
                {tab === 'competition' ? (
                  !profile.tournamentHistory?.length &&
                  !allTeams.length &&
                  !profile.tournamentStats?.attacks ? (
                    <View style={[styles.section, { paddingVertical: 22, gap: 10 }]}>
                      <CKText role="sectionTitle">{t('competitiveNoHistory')}</CKText>
                      <CKText muted>{t('competitiveHistoryHint')}</CKText>
                    </View>
                  ) : (
                    <View style={styles.section}>
                      <CKText skeleton={false} role="sectionTitle">
                        {t('navigationStatistics')}
                      </CKText>
                      {profile.statsAvailability ? (
                        <>
                          <View style={styles.metrics}>
                            {(
                              [
                                ['warAttacksTitle', profile.tournamentStats?.attacks],
                                [
                                  'statsThreeStarRate',
                                  profile.tournamentStats?.hitRatePercent == null
                                    ? undefined
                                    : `${profile.tournamentStats.hitRatePercent.toFixed(1)}%`,
                                ],
                                [
                                  'statsAverageDestruction',
                                  profile.tournamentStats?.averageDestruction == null
                                    ? undefined
                                    : `${profile.tournamentStats.averageDestruction.toFixed(1)}%`,
                                ],
                              ] as const
                            ).map(([label, value]) => (
                              <View
                                key={label}
                                style={[styles.metric, { backgroundColor: theme.card }]}
                              >
                                <CKText role="titleSmall">{value ?? '—'}</CKText>
                                <CKText muted role="metadata">
                                  {t(label)}
                                </CKText>
                              </View>
                            ))}
                          </View>
                          <CKText muted role="metadata">
                            {profile.statsAvailability.observedMatches}/
                            {profile.statsAvailability.totalCompletedMatches} · {t('cwlMatches')}
                          </CKText>
                        </>
                      ) : (
                        <ProfileEmpty />
                      )}
                      <CKText skeleton={false} role="sectionTitle">
                        {t('generalHistory')}
                      </CKText>
                      {profile.tournamentHistory?.length ? (
                        profile.tournamentHistory.map((entry) => (
                          <ProfileRow
                            key={`${entry.id}:${entry.teamId}`}
                            title={entry.name}
                            subtitle={entry.clanName}
                            image={ImageAssets.war}
                            onPress={() => onTournament(entry.id)}
                          />
                        ))
                      ) : (
                        <ProfileEmpty />
                      )}
                      <CKText skeleton={false} role="sectionTitle">
                        {t('competitiveTeams')}
                      </CKText>
                      {allTeams.length ? (
                        allTeams.map((team) => (
                          <ProfileRow
                            key={team.id}
                            title={team.clanName}
                            subtitle={`${team.size}v${team.size}${team.leftAt ? ` · ${t('generalHistory')}` : ''}`}
                            image={ImageAssets.warClan}
                            onPress={() => openTeam(team.id)}
                          />
                        ))
                      ) : (
                        <ProfileEmpty />
                      )}
                    </View>
                  )
                ) : null}
              </>
            )}
          </>
        ) : null}
      </SkeletonContent>
    </ScrollView>
  );
}

function ProfileAccount({ account }: { account: CompetitiveProfile['accounts'][number] }) {
  const runtime = useAppRuntime();
  const contentLoading = useSkeletonContent();
  const theme = useCKTheme();
  const { t, locale } = useI18n();
  const [player, setPlayer] = useState<Player | undefined>(() =>
    runtime.players.profiles.find((item) => item.tag === account.tag),
  );
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    if (contentLoading) return;
    let active = true;
    // Reuse the player service's deduplicated, short-lived current-data cache.
    // Only enrich accounts returned by the verified profile endpoint; never
    // infer profile ownership from locally bookmarked or searched players.
    void runtime.players
      .getPlayerAndClanData(account.tag)
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
  }, [runtime.players, account.tag, contentLoading]);
  const townHall = player?.townHallLevel ?? account.townHallLevel;
  return (
    <PressableSurface
      accessibilityRole="button"
      onPress={() => queueAppLink(`/player/${encodeURIComponent(account.tag)}`)}
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

function ProfileAchievements({
  awards,
  verifiedCount,
}: {
  awards: CompetitiveProfile['achievements'];
  verifiedCount?: number;
}) {
  const { t } = useI18n();
  const { width: windowWidth, height: windowHeight, fontScale } = useWindowDimensions();
  const layout = useAdaptiveLayout();
  const width = layout.isDuo || layout.isTablet ? layout.width : windowWidth;
  const height = layout.isDuo || layout.isTablet ? layout.height : windowHeight;
  const { reduceMotion } = useCKAccessibility();
  const [selected, setSelected] = useState<Achievement>();
  const [gridWidth, setGridWidth] = useState(0);
  const byId = new Map<string, number>();
  for (const award of awards) byId.set(award.id, (byId.get(award.id) ?? 0) + 1);
  // Catalog entries remain visible before earning them. Count only awards
  // returned for this profile; bookmarks never imply achievement ownership.
  const achievements = [
    ...ACHIEVEMENT_CATALOG_FALLBACK,
    {
      id: 'first_tournament' as const,
      modelUrl: BUNDLED_TOURNAMENT_MODEL,
      earnedCount: 0,
      isRepeatable: true,
    },
  ].map((item) => ({
    ...item,
    earnedCount:
      item.id === 'verified_accounts'
        ? verifiedCount !== undefined && verifiedCount > 1
          ? 1
          : 0
        : (byId.get(item.id) ?? 0),
  }));
  const collectionWidth = Math.min(
    width - 32,
    layout.isExpanded || layout.isDuo ? layout.contentMaxWidth - 32 : 1088,
  );
  // The profile can occupy a narrower pane than the window after the Duo rail
  // and page padding. Size expanded tiles from the grid that actually contains them.
  const expandedWidth = gridWidth || collectionWidth;
  const columns = layout.isExpanded
    ? resolveGridColumns({
        width: expandedWidth,
        minItemWidth: 232 * Math.max(1, fontScale),
        maxColumns: 4,
        gap: ckSpacing.md,
      })
    : 3;
  const tileWidth = layout.isExpanded
    ? (expandedWidth - ckSpacing.md * (columns - 1)) / columns
    : (collectionWidth - 16 * (columns - 1)) / columns;
  return (
    <View
      style={styles.achievements}
      onLayout={
        layout.isExpanded ? ({ nativeEvent }) => setGridWidth(nativeEvent.layout.width) : undefined
      }
    >
      {achievements.map((achievement) => (
        <AchievementTile
          key={achievement.id}
          achievement={achievement}
          modelRenderer={AchievementModelViewer}
          name={t(ACHIEVEMENT_COPY_KEYS[achievement.id].name)}
          subtitle={achievement.earnedCount ? `×${achievement.earnedCount}` : t('widgetLocked')}
          onPress={() => setSelected(achievement)}
          width={tileWidth}
        />
      ))}
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

function ProfileButton({
  label,
  onPress,
  disabled = false,
  primary = false,
}: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
  primary?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <PressableSurface
      accessibilityRole="button"
      accessibilityState={{ disabled }}
      disabled={disabled}
      onPress={onPress}
      style={[
        styles.button,
        { backgroundColor: primary ? theme.primary : theme.card, opacity: disabled ? 0.45 : 1 },
      ]}
    >
      <CKText role="rowTitle" style={{ color: primary ? theme.onPrimary : theme.onSurface }}>
        {label}
      </CKText>
    </PressableSurface>
  );
}
function ProfileRow({
  title,
  subtitle,
  image,
  onPress,
}: {
  title: string;
  subtitle?: string;
  image?: string;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <PressableSurface accessibilityRole="button" onPress={onPress} style={styles.row}>
      {image ? <MobileWebImage imageUrl={image} style={{ width: 48, height: 48 }} /> : null}
      <View style={{ flex: 1, gap: 4 }}>
        <CKText role="rowTitle">{title}</CKText>
        {subtitle ? (
          <CKText muted role="metadata">
            {subtitle}
          </CKText>
        ) : null}
      </View>
      <ChevronRight size={20} color={theme.onSurfaceVariant} />
    </PressableSurface>
  );
}
function ProfileEmpty() {
  const { t } = useI18n();
  return <CKText muted>{t('generalNoDataAvailable')}</CKText>;
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
  manageAccounts: {
    alignSelf: 'flex-end',
    minHeight: 40,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
    paddingHorizontal: 14,
    paddingVertical: 10,
  },
  headerArtwork: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'flex-end',
    gap: 8,
    height: 68,
  },
  banner: { width: '100%', height: 160, borderRadius: ckRadius.tile },
  headerActions: { flexDirection: 'row', alignItems: 'center', marginRight: -ckSpacing.sm },
  identity: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.md },
  identityWithoutBanner: { paddingTop: ckSpacing.xxl, minHeight: 96 },
  identityText: { flex: 1, minWidth: 0, gap: ckSpacing.xs },
  name: { fontSize: 30, lineHeight: 36 },
  avatar: {
    width: 64,
    height: 64,
    borderRadius: ckRadius.tile,
    overflow: 'hidden',
  },
  teamBadges: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  teamBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 999,
    borderWidth: 0,
  },
  section: { gap: 16 },
  inline: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  toggle: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  input: { minHeight: 48, padding: 14, borderRadius: 14 },
  button: {
    minHeight: 48,
    padding: 14,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
  },
  row: {
    padding: ckSpacing.md,
    borderRadius: ckRadius.tile,
    borderWidth: 0,
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.md,
  },
  metrics: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  metric: { flexGrow: 1, flexBasis: 130, padding: 16, borderRadius: 20, gap: 6 },
  achievements: { flexDirection: 'row', flexWrap: 'wrap', gap: ckSpacing.md },
  achievement: {
    flexGrow: 1,
    flexBasis: 320,
    maxWidth: 538,
    padding: ckSpacing.md,
    borderRadius: ckRadius.tile,
    flexDirection: 'row',
    alignItems: 'center',
    gap: ckSpacing.md,
  },
  model: { width: 120, height: 140 },
  achievementDetails: { flex: 1, minWidth: 0, gap: ckSpacing.xs },
});
