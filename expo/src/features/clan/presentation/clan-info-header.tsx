import { useRef, useState } from 'react';
import { TutorialTarget } from '../../tutorials/tutorial-ui';
import { tutorials, TUTORIAL_CLAN_TAG } from '../../tutorials/tutorial-service';
import {
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import {
  ArrowLeft,
  Bookmark,
  BookmarkCheck,
  ChevronRight,
  Copy,
  ExternalLink,
  Mail,
  MoreHorizontal,
  Share2,
  Shield,
  Users,
  X,
} from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { ImageAssets } from '../../../core/assets/image-assets';
import { DiscordMark } from '../../../ui/discord-mark';
import { sharePageLink } from '../../../core/deep-links/share-page-link';
import { materialBackLabel, materialCloseLabel, useI18n } from '../../../i18n';
import {
  CKText,
  MobileWebImage,
  PillSurface,
  ProfileHeaderAction,
  ProfileStatChip,
  useCKTheme,
  useCKThemeMode,
} from '../../../ui';
import { clanMemberCapacityLabel } from './contracts';
import type {
  ClanInfoPresentationActions,
  ClanInfoPresentationModel,
  ClanInfoTabKey,
} from './clan-info-contracts';
import { extractDiscordInviteCode } from './clan-info-contracts';
import { clanTypeLabel } from './presentation-utils';
import { ClanSpringTarget } from './clan-spring-transition';
import { headerArtworkSize } from '../../../ui/mobile-web-image';

export function ClanInfoHeader({
  model,
  actions,
  selectedTab = 'members',
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
  selectedTab?: ClanInfoTabKey;
}) {
  const { clan } = model;
  const { t, locale } = useI18n();
  const { width, height } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const theme = useCKTheme();
  const themeMode = useCKThemeMode();
  const desktop = Platform.OS === 'web' && width >= 900;
  const descriptionTriggerRef = useRef<View>(null);
  const descriptionMeasureGeneration = useRef(0);
  const [descriptionVisible, setDescriptionVisible] = useState(false);
  const [descriptionAnchor, setDescriptionAnchor] = useState<{
    x: number;
    y: number;
    width: number;
    height: number;
  } | null>(null);
  const description = clan.description.trim();
  const tooltipWidth = Math.max(0, Math.min(width - 32, 320));
  const tooltipMaxHeight = Math.min(height * 0.42, 280);
  const tooltipLeft = descriptionAnchor
    ? Math.max(
        16,
        Math.min(
          descriptionAnchor.x + descriptionAnchor.width - tooltipWidth,
          width - tooltipWidth - 16,
        ),
      )
    : 16;
  const tooltipBelow = descriptionAnchor
    ? Math.max(insets.top + 8, descriptionAnchor.y + descriptionAnchor.height + 8)
    : insets.top + 8;
  const tooltipTop =
    descriptionAnchor && height - insets.bottom - tooltipBelow < tooltipMaxHeight + 16
      ? Math.max(insets.top + 8, descriptionAnchor.y - tooltipMaxHeight - 8)
      : tooltipBelow;
  const showDescription = () => {
    const generation = ++descriptionMeasureGeneration.current;
    // The measured anchor replaces this fallback before the fade finishes; the
    // tooltip still opens if measurement is unavailable on a platform.
    setDescriptionAnchor({ x: width - 40, y: insets.top + 260, width: 24, height: 24 });
    setDescriptionVisible(true);
    descriptionTriggerRef.current?.measureInWindow((x, y, anchorWidth, anchorHeight) => {
      if (descriptionMeasureGeneration.current === generation)
        setDescriptionAnchor({ x, y, width: anchorWidth, height: anchorHeight });
    });
  };
  // Keep the anchor through Modal's exit fade, or the tooltip animates to its
  // unanchored default before disappearing.
  const hideDescription = () => {
    descriptionMeasureGeneration.current += 1;
    setDescriptionVisible(false);
  };
  const discordCode = extractDiscordInviteCode(clan.description);
  const warLeagueAssetName = clan.warLeague?.name ?? 'Unranked';
  const capitalLeagueAssetName = clan.capitalLeague?.name ?? 'Unranked';
  const warLeagueLabel = clan.warLeague?.name ?? t('generalNotSet');
  const capitalLeagueLabel = clan.capitalLeague?.name ?? t('generalNotSet');
  const copyClanTag = () =>
    void actions
      .copyClanTag(clan.tag)
      .then(() => actions.showMessage(t('generalCopiedToClipboard')));
  const primaryStats = [
    { value: clan.clanPoints, image: ImageAssets.trophies, label: t('clanPointsTitle') },
    {
      value: clanMemberCapacityLabel(clan.members),
      iconElement: <Users size={19} color={theme.onSurface} />,
      label: t('clanMembers'),
    },
    {
      value: clan.clanBuilderBasePoints,
      image: ImageAssets.builderBaseTrophy,
      label: t('clanBuilderBasePoints'),
    },
  ];
  const secondaryStats = [
    {
      value: clanTypeLabel(clan.type, t),
      iconElement: <Mail size={19} color={theme.onSurface} />,
      label: t('clanType'),
    },
    ...(clan.requiredTownhallLevel > 0
      ? [
          {
            value: t('clanRequiredTownHallOnly', { level: clan.requiredTownhallLevel }),
            image: ImageAssets.townHall(clan.requiredTownhallLevel),
            label: t('clanRequiredTownHall'),
          },
        ]
      : []),
    ...(clan.isFamilyFriendly
      ? [
          {
            value: 'Family-friendly',
            iconElement: <Users size={19} color={theme.onSurface} />,
            label: 'Family-friendly',
          },
        ]
      : []),
  ];
  return (
    <View testID="clan-header-hero" style={styles.hero}>
      <View testID="clan-header-backdrop" pointerEvents="none" style={StyleSheet.absoluteFill}>
        <MobileWebImage
          testID="clan-header-background-image"
          imageUrl={ImageAssets.homeBaseBackground}
          displaySize={headerArtworkSize(width)}
          cachePolicy="memory-disk"
          transition={0}
          style={StyleSheet.absoluteFill}
          contentFit="cover"
          contentPosition="bottom"
        />
        <View style={styles.imageDarken} />
        <Svg
          testID="clan-header-gradient"
          style={StyleSheet.absoluteFill}
          width="100%"
          height="100%"
          pointerEvents="none"
        >
          <Defs>
            <LinearGradient id="clan-header-scrim" x1="0%" y1="0%" x2="0%" y2="100%">
              <Stop offset="0" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.36 : 0.2} />
              <Stop offset="0.5" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.64 : 0.4} />
              <Stop offset="1" stopColor="#000" stopOpacity={1} />
            </LinearGradient>
          </Defs>
          <Rect width="100%" height="100%" fill="url(#clan-header-scrim)" />
        </Svg>
      </View>
      <View style={[styles.actions, { paddingTop: insets.top }, desktop && styles.desktopActions]}>
        <ProfileHeaderAction
          label={materialBackLabel(locale)}
          onPress={actions.goBack}
          icon={<ArrowLeft color="#FFF" />}
        />
        <View style={styles.actionSpacer} />
        {model.ongoingWar ? (
          <ProfileHeaderAction
            label={model.ongoingWar === 'cwl' ? t('cwlOngoing') : t('warOngoing')}
            onPress={() =>
              model.ongoingWar === 'cwl' ? actions.openCwl(clan) : actions.openWar(clan)
            }
            icon={
              <MobileWebImage
                imageUrl={
                  model.ongoingWar === 'cwl' ? ImageAssets.cwlSwordsNoBorder : ImageAssets.war
                }
                style={styles.actionImage}
              />
            }
          />
        ) : null}
        {discordCode ? (
          <ProfileHeaderAction
            label={t('generalDiscord')}
            onPress={() =>
              void actions
                .openDiscord(discordCode)
                .catch(() => actions.showMessage(t('errorCannotOpenLink')))
            }
            icon={<DiscordMark color="#FFF" size={22} />}
          />
        ) : null}
        <ProfileHeaderAction
          label={t('gameAssetsShare')}
          onPress={() =>
            void sharePageLink(
              { kind: 'clan', tag: clan.tag, params: { tab: selectedTab } },
              clan.name,
            ).catch(() => actions.showMessage(t('errorCannotOpenLink')))
          }
          icon={<Share2 color="#FFF" />}
        />
        <ProfileHeaderAction
          label={t('playerOpenInGame')}
          onPress={() => actions.openClanInGame(clan)}
          icon={<ExternalLink color="#FFF" />}
        />
        <TutorialTarget id="bookmark" offer={clan.tag === TUTORIAL_CLAN_TAG ? 'clanGuide' : undefined}><ProfileHeaderAction
          label={model.bookmarked ? t('generalRemoveBookmark') : t('generalBookmark')}
          onPress={() => void actions.toggleClanBookmark(clan).then(() => tutorials.event('bookmarked'))}
          icon={model.bookmarked ? <BookmarkCheck color="#2F8CFF" /> : <Bookmark color="#FFF" />}
        /></TutorialTarget>
      </View>
      <View style={[styles.body, desktop ? styles.desktopBody : styles.mobileBody]}>
        <View style={[styles.identity, desktop && styles.desktopIdentity]}>
          <ClanSpringTarget part="badge">
            <MobileWebImage
              imageUrl={clan.badgeUrls.smallest}
              cachePolicy="memory-disk"
              transition={0}
              style={[styles.badge, desktop && styles.desktopBadge]}
            />
          </ClanSpringTarget>
          <View style={desktop ? styles.desktopIdentityCopy : styles.centered}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={`${clan.name}. ${t('generalCopiedToClipboard')}`}
              testID="clan-header-name-copy"
              onPress={copyClanTag}
            >
              <ClanSpringTarget part="name">
                <CKText numberOfLines={1} style={styles.name}>
                  {clan.name}
                </CKText>
              </ClanSpringTarget>
            </Pressable>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={`${clan.tag}. ${t('generalCopiedToClipboard')}`}
              onPress={copyClanTag}
              style={styles.tagRow}
            >
              <CKText style={styles.tag}>{clan.tag}</CKText>
              <Copy size={13} color="#FFFFFF9E" />
            </Pressable>
            <View style={[styles.meta, desktop && styles.desktopMeta]}>
              {clan.location?.countryCode ? (
                <MobileWebImage
                  imageUrl={ImageAssets.flag(clan.location.countryCode)}
                  style={styles.flag}
                />
              ) : null}
              {clan.location?.name ? (
                <CKText style={styles.metaText}>{clan.location.name}</CKText>
              ) : null}
              {clan.location?.name && clan.labels.length ? (
                <CKText style={styles.metaDivider}>|</CKText>
              ) : null}
              {clan.labels.slice(0, 3).map((label) => {
                const uri = label.smallIconUrl ?? label.mediumIconUrl ?? label.tinyIconUrl;
                return uri ? (
                  <MobileWebImage key={label.id} imageUrl={uri} style={styles.labelIcon} />
                ) : (
                  <Shield key={label.id} size={16} color="#FFFFFFC2" />
                );
              })}
              {description ? (
                <Pressable
                  ref={descriptionTriggerRef}
                  testID="clan-description-trigger"
                  accessibilityRole="button"
                  accessibilityLabel={t('generalExpand')}
                  onPress={showDescription}
                  hitSlop={8}
                >
                  <MoreHorizontal size={18} color="#FFFFFFC2" />
                </Pressable>
              ) : null}
            </View>
          </View>
        </View>
        <View style={styles.stats}>
          <View style={styles.leagues}>
            <LeagueTile
              leagueName={warLeagueLabel.replace(' League', '')}
              subtitle={t('cwlTitle')}
              imageUrl={ImageAssets.getWarLeagueImage(warLeagueAssetName)}
              onPress={model.hasCwlLeagueData ? () => actions.openCwl(clan) : undefined}
            />
            <LeagueTile
              leagueName={capitalLeagueLabel.replace(' League', '')}
              subtitle={`${clan.clanCapitalPoints}`}
              subtitleImageUrl={ImageAssets.capitalTrophy}
              imageUrl={
                clan.capitalLeague
                  ? ImageAssets.getCapitalLeagueImage(capitalLeagueAssetName)
                  : ImageAssets.capitalTrophy
              }
              onPress={() => actions.openCapital(clan)}
            />
          </View>
          <View style={styles.quickStats}>
            {[primaryStats, secondaryStats].map((stats, index) => (
              <View key={index} style={styles.quickStatRow}>
                {stats.map((stat) => (
                  <ProfileStatChip
                    key={`${stat.label}:${stat.value}`}
                    label={stat.label}
                    value={stat.value}
                    icon={stat.image}
                    iconElement={stat.iconElement}
                  />
                ))}
              </View>
            ))}
          </View>
        </View>
      </View>
      <Modal
        visible={descriptionVisible}
        transparent
        animationType="fade"
        onRequestClose={hideDescription}
        statusBarTranslucent
      >
        <Pressable
          testID="clan-description-overlay"
          style={styles.tooltipBackdrop}
          onPress={hideDescription}
        >
          <Pressable
            testID="clan-description-tooltip"
            accessibilityViewIsModal
            onPress={(event) => event.stopPropagation()}
            style={[
              styles.tooltip,
              {
                top: tooltipTop,
                left: tooltipLeft,
                width: tooltipWidth,
                maxHeight: tooltipMaxHeight,
              },
            ]}
          >
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={materialCloseLabel(locale)}
              onPress={hideDescription}
              style={styles.tooltipClose}
            >
              <X size={16} color="#FFFFFFC2" />
            </Pressable>
            <ScrollView bounces={false} contentContainerStyle={styles.tooltipContent}>
              <CKText style={styles.tooltipText}>{description}</CKText>
            </ScrollView>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

function LeagueTile({
  leagueName,
  subtitle,
  subtitleImageUrl,
  imageUrl,
  onPress,
}: {
  leagueName: string;
  subtitle: string;
  subtitleImageUrl?: string;
  imageUrl: string;
  onPress?: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole={onPress ? 'button' : undefined}
      accessibilityLabel={`${leagueName}, ${subtitle}`}
      onPress={onPress}
      disabled={!onPress}
      style={styles.leaguePressable}
    >
      <PillSurface testID="clan-header-league-surface" style={styles.leagueTile}>
        <MobileWebImage imageUrl={imageUrl} style={styles.leagueImage} />
        <View style={styles.leagueCopy}>
          <CKText role="bodyMedium" numberOfLines={1} style={styles.leagueName}>
            {leagueName}
          </CKText>
          <View style={styles.leagueSubtitle}>
            {subtitleImageUrl ? (
              <MobileWebImage imageUrl={subtitleImageUrl} style={styles.leagueSubtitleImage} />
            ) : null}
            <CKText muted role="labelSmall" numberOfLines={1}>
              {subtitle}
            </CKText>
          </View>
        </View>
        {onPress ? <ChevronRight size={20} color={theme.onSurfaceVariant} /> : null}
      </PillSurface>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  hero: { width: '100%', backgroundColor: '#000', overflow: 'hidden' },
  imageDarken: { ...StyleSheet.absoluteFill, backgroundColor: '#00000080' },
  actions: {
    minHeight: 48,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  desktopActions: { width: '100%', maxWidth: 1120, alignSelf: 'center', paddingHorizontal: 20 },
  actionSpacer: { flex: 1 },
  actionImage: { width: 24, height: 24, resizeMode: 'contain' },
  body: {},
  mobileBody: { paddingTop: 6 },
  desktopBody: {
    maxWidth: 1120,
    width: '100%',
    alignSelf: 'center',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 28,
    gap: 52,
  },
  identity: { alignItems: 'center' },
  desktopIdentity: { flex: 4, flexDirection: 'row', justifyContent: 'flex-end' },
  badge: { width: 94, height: 94, resizeMode: 'contain' },
  desktopBadge: { width: 104, height: 104 },
  centered: { alignItems: 'center', maxWidth: '100%' },
  desktopIdentityCopy: { marginLeft: 18, alignItems: 'flex-start', maxWidth: 250 },
  name: { color: '#FFF', fontSize: 26, lineHeight: 27, fontWeight: '700' },
  tagRow: { flexDirection: 'row', alignItems: 'center', gap: 4, paddingVertical: 1 },
  tag: { color: '#FFFFFF9E', fontSize: 15 },
  meta: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
    maxWidth: '100%',
  },
  desktopMeta: { justifyContent: 'flex-start' },
  metaText: { color: '#FFF', fontSize: 15 },
  metaDivider: { color: '#FFFFFF4D', marginHorizontal: 3 },
  flag: { width: 16, height: 16 },
  labelIcon: { width: 16, height: 16 },
  tooltipBackdrop: { flex: 1 },
  tooltip: {
    position: 'absolute',
    borderRadius: 18,
    backgroundColor: '#242428F2',
    borderWidth: 1,
    borderColor: '#FFFFFF24',
    shadowColor: '#000',
    shadowOpacity: 0.35,
    shadowRadius: 18,
    shadowOffset: { width: 0, height: 8 },
    elevation: 12,
    overflow: 'hidden',
  },
  tooltipClose: {
    position: 'absolute',
    zIndex: 1,
    top: 4,
    right: 4,
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
  },
  tooltipContent: { paddingVertical: 16, paddingLeft: 16, paddingRight: 48 },
  tooltipText: { color: '#FFF', fontSize: 14, lineHeight: 20 },
  stats: { flex: 6, paddingTop: 11, paddingHorizontal: 16, paddingBottom: 0 },
  leagues: { flexDirection: 'row', gap: 8 },
  leaguePressable: { flex: 1 },
  leagueTile: {
    height: 64,
    borderRadius: 16,
    paddingHorizontal: 10,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
  },
  leagueImage: { width: 34, height: 34, resizeMode: 'contain' },
  leagueCopy: { flex: 1, marginLeft: 8 },
  leagueName: { fontWeight: '600' },
  leagueSubtitle: { flexDirection: 'row', alignItems: 'center', gap: 3, marginTop: 2 },
  leagueSubtitleImage: { width: 14, height: 14, resizeMode: 'contain' },
  quickStats: {
    marginTop: 8,
    gap: 8,
  },
  quickStatRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    flexWrap: 'wrap',
    gap: 7,
  },
});
