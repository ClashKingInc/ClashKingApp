import { useState, type ReactNode } from 'react';
import { Platform, Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import {
  ArrowLeft,
  Bookmark,
  BookmarkCheck,
  ChevronRight,
  Copy,
  ExternalLink,
  Mail,
  MessageCircle,
  MoreHorizontal,
  Shield,
  Users,
} from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

import { ImageAssets } from '../../../core/assets/image-assets';
import { materialBackLabel, useI18n } from '../../../i18n';
import { CKText, MobileWebImage, colorWithAlpha, useCKTheme, useCKThemeMode } from '../../../ui';
import { clanMemberCapacityLabel } from './contracts';
import type { ClanInfoPresentationActions, ClanInfoPresentationModel } from './clan-info-contracts';
import { extractDiscordInviteCode } from './clan-info-contracts';
import { clanTypeLabel } from './presentation-utils';

export function ClanInfoHeader({
  model,
  actions,
}: {
  model: ClanInfoPresentationModel;
  actions: ClanInfoPresentationActions;
}) {
  const { clan } = model;
  const { t, locale } = useI18n();
  const { width } = useWindowDimensions();
  const insets = useSafeAreaInsets();
  const theme = useCKTheme();
  const themeMode = useCKThemeMode();
  const desktop = Platform.OS === 'web' && width >= 900;
  const [expanded, setExpanded] = useState(false);
  const discordCode = extractDiscordInviteCode(clan.description);
  const warLeagueAssetName = clan.warLeague?.name ?? 'Unranked';
  const capitalLeagueAssetName = clan.capitalLeague?.name ?? 'Unranked';
  const warLeagueLabel = clan.warLeague?.name ?? t('generalNotSet');
  const capitalLeagueLabel = clan.capitalLeague?.name ?? t('generalNotSet');
  const primaryStats = [
    { value: `${clan.clanPoints}`, image: ImageAssets.trophies, label: t('clanPointsTitle') },
    {
      value: clanMemberCapacityLabel(clan.members),
      icon: <Users size={19} color={theme.onSurface} />,
      label: t('clanMembers'),
    },
    {
      value: `${clan.clanBuilderBasePoints}`,
      image: ImageAssets.builderBaseTrophy,
      label: t('clanBuilderBasePoints'),
    },
  ];
  const secondaryStats = [
    {
      value: clanTypeLabel(clan.type, t),
      icon: <Mail size={19} color={theme.onSurface} />,
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
            icon: <Users size={19} color={theme.onSurface} />,
            label: 'Family-friendly',
          },
        ]
      : []),
  ];
  return (
    <View style={styles.hero}>
      <MobileWebImage
        imageUrl={ImageAssets.homeBaseBackground}
        style={StyleSheet.absoluteFill}
        contentFit="cover"
        contentPosition="bottom"
      />
      <View style={styles.imageDarken} />
      <Svg pointerEvents="none" style={StyleSheet.absoluteFill}>
        <Defs>
          <LinearGradient id="clan-header-scrim" x1="0%" y1="0%" x2="0%" y2="100%">
            <Stop offset="0" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.36 : 0.2} />
            <Stop offset="0.5" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.64 : 0.4} />
            <Stop offset="1" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.92 : 0.65} />
          </LinearGradient>
        </Defs>
        <Rect width="100%" height="100%" fill="url(#clan-header-scrim)" />
      </Svg>
      <View style={[styles.actions, { paddingTop: insets.top }, desktop && styles.desktopActions]}>
        <HeaderAction
          label={materialBackLabel(locale)}
          onPress={actions.goBack}
          icon={<ArrowLeft color="#FFF" />}
        />
        <View style={styles.actionSpacer} />
        {model.ongoingWar ? (
          <HeaderAction
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
          <HeaderAction
            label={t('generalDiscord')}
            onPress={() =>
              void actions
                .openDiscord(discordCode)
                .catch(() => actions.showMessage(t('errorCannotOpenLink')))
            }
            icon={<MessageCircle color="#FFF" />}
          />
        ) : null}
        <HeaderAction
          label={t('playerOpenInGame')}
          onPress={() => actions.openClanInGame(clan)}
          icon={<ExternalLink color="#FFF" />}
        />
        <HeaderAction
          label={model.bookmarked ? t('generalRemoveBookmark') : t('generalBookmark')}
          onPress={() => void actions.toggleClanBookmark(clan)}
          icon={model.bookmarked ? <BookmarkCheck color="#2F8CFF" /> : <Bookmark color="#FFF" />}
        />
      </View>
      <View style={[styles.body, desktop ? styles.desktopBody : styles.mobileBody]}>
        <View style={[styles.identity, desktop && styles.desktopIdentity]}>
          <MobileWebImage
            imageUrl={clan.badgeUrls.smallest}
            style={[styles.badge, desktop && styles.desktopBadge]}
          />
          <View style={desktop ? styles.desktopIdentityCopy : styles.centered}>
            <CKText numberOfLines={1} style={styles.name}>
              {clan.name}
            </CKText>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={`${clan.tag}. ${t('generalCopiedToClipboard')}`}
              onPress={() =>
                void actions
                  .copyClanTag(clan.tag)
                  .then(() => actions.showMessage(t('generalCopiedToClipboard')))
              }
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
              {clan.description.trim() ? (
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={expanded ? t('generalCollapse') : t('generalExpand')}
                  onPress={() => setExpanded(!expanded)}
                >
                  <MoreHorizontal size={18} color="#FFFFFFC2" />
                </Pressable>
              ) : null}
            </View>
            {desktop && expanded && clan.description.trim() ? (
              <CKText style={[styles.description, styles.desktopDescription]}>
                {clan.description.trim()}
              </CKText>
            ) : null}
          </View>
        </View>
        <View style={styles.stats}>
          {!desktop && expanded && clan.description.trim() ? (
            <CKText style={[styles.description, styles.mobilePanelDescription]}>
              {clan.description.trim()}
            </CKText>
          ) : null}
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
            <View style={styles.quickStatRow}>
              {primaryStats.map((stat) => (
                <QuickStat key={`${stat.label}:${stat.value}`} {...stat} />
              ))}
            </View>
            {secondaryStats.length ? (
              <View style={styles.quickStatRow}>
                {secondaryStats.map((stat) => (
                  <QuickStat key={`${stat.label}:${stat.value}`} {...stat} />
                ))}
              </View>
            ) : null}
          </View>
        </View>
      </View>
    </View>
  );
}

function HeaderAction({
  label,
  onPress,
  icon,
}: {
  label: string;
  onPress: () => void;
  icon: ReactNode;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      onPress={onPress}
      style={styles.headerAction}
    >
      {icon}
    </Pressable>
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
      <View style={[styles.leagueTile, { backgroundColor: colorWithAlpha(theme.surface, 0.58) }]}>
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
      </View>
    </Pressable>
  );
}

function QuickStat({
  value,
  image,
  icon,
  label,
}: {
  value: string;
  image?: string;
  icon?: ReactNode;
  label: string;
}) {
  const theme = useCKTheme();
  return (
    <View
      accessibilityLabel={`${label}: ${value}`}
      style={[styles.quickStat, { backgroundColor: colorWithAlpha(theme.surface, 0.58) }]}
    >
      {image ? <MobileWebImage imageUrl={image} style={styles.quickImage} /> : icon}
      <CKText role="labelLarge" numberOfLines={1}>
        {value}
      </CKText>
    </View>
  );
}

const styles = StyleSheet.create({
  hero: { width: '100%', backgroundColor: '#000' },
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
  headerAction: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 20,
  },
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
  description: {
    color: '#FFF',
    fontSize: 12,
    fontWeight: '600',
    textAlign: 'center',
    marginTop: 6,
    paddingHorizontal: 20,
  },
  desktopDescription: { textAlign: 'left', paddingHorizontal: 0 },
  mobilePanelDescription: { marginTop: 0, marginBottom: 8 },
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
  quickStat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
  },
  quickImage: { width: 19, height: 19, resizeMode: 'contain' },
});
