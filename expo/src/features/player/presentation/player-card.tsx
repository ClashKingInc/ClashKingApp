import { useState, type ReactElement } from 'react';
import { Pressable, StyleSheet, Switch, View } from 'react-native';
import {
  Bell,
  Bookmark,
  CheckSquare,
  ChevronDown,
  ChevronRight,
  Construction,
  EyeOff,
  Shield,
  ShieldCheck,
  SlidersHorizontal,
  Trophy,
  TriangleAlert,
} from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import {
  CKText,
  LoadingIndicator,
  MobileWebImage,
  PillSurface,
  Surface,
  ckRadius,
  colorWithAlpha,
  statColors,
  useCKTheme,
} from '../../../ui';
import {
  formatPlayerActivity,
  playerClanPresentation,
  wrapActivityCaption,
} from './presentation-utils';
import type {
  BookmarkedPlayerSummary,
  PlayersFeatureFlags,
  PlayersPresentationActions,
} from './contracts';
import type { CocAccountLink } from '../../auth/models';
import type { PlayerCardOptions } from '../models/player-support';
import type { Player } from '../models/player';

export function PlayerDataCard({
  player,
  link,
  bookmarked = false,
  options,
  notificationsEnabled,
  notificationActive,
  notificationUpdating,
  actions,
  onVerify,
}: {
  player: Player;
  link?: CocAccountLink;
  bookmarked?: boolean;
  options: PlayerCardOptions;
  featureFlags: PlayersFeatureFlags;
  notificationsEnabled: boolean;
  notificationActive: boolean;
  notificationUpdating: boolean;
  actions: PlayersPresentationActions;
  onVerify: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState(false);
  const [visibilityUpdating, setVisibilityUpdating] = useState(false);
  const verified = link?.isVerified;
  const clan = playerClanPresentation(player);
  const notificationAvailable = verified === true && notificationsEnabled && !notificationUpdating;
  const notificationSubtitle =
    verified === false
      ? t('playerOptionNotificationsVerifyFirst')
      : !notificationsEnabled
        ? t('playerOptionNotificationsEnableMaster')
        : t('playerOptionNotificationsSubtitle');
  const updateHidden = async () => {
    if (!link || !link.isVerified) return;
    setVisibilityUpdating(true);
    try {
      await actions.setAccountHidden(player.tag, !link.hidden);
    } catch {
      actions.showMessage('Couldn’t update account visibility.');
    } finally {
      setVisibilityUpdating(false);
    }
  };
  return (
    <Surface radius={ckRadius.control} style={styles.card}>
      <Pressable
        accessibilityRole="button"
        onPress={() => actions.openPlayer(player)}
        style={styles.main}
      >
        <View style={styles.artColumn}>
          <View>
            <MobileWebImage imageUrl={player.townHallPic} style={styles.townHall} />
            <Pressable
              accessibilityRole={verified === false ? 'button' : undefined}
              accessibilityLabel={verified === false ? t('homeVerifyAccountAction') : undefined}
              disabled={verified !== false}
              onPress={onVerify}
              style={[
                styles.status,
                {
                  backgroundColor: theme.card,
                  borderColor: colorWithAlpha(theme.outlineVariant, 0.4),
                },
              ]}
            >
              {bookmarked ? (
                <Bookmark size={14} color={theme.onSurfaceVariant} />
              ) : verified ? (
                <ShieldCheck size={14} color={theme.primary} />
              ) : (
                <TriangleAlert size={14} color={statColors.capitalProjected} />
              )}
            </Pressable>
          </View>
          {!bookmarked ? (
            <CKText muted role="labelSmall" style={styles.activity}>
              {wrapActivityCaption(formatPlayerActivity(player.lastOnline, t))}
            </CKText>
          ) : null}
        </View>
        <View style={styles.copy}>
          <View style={styles.titleRow}>
            <CKText role="titleMedium" numberOfLines={1} style={styles.title}>
              {player.name}
            </CKText>
            <ChevronRight color={theme.onSurfaceVariant} />
          </View>
          <CKText muted role="labelLarge">
            {player.tag}
          </CKText>
          <View style={styles.chips}>
            <InfoChip imageUrl={clan.imageUrl} label={clan.label || t('clanNone')} />
            <InfoChip
              imageUrl={player.leagueUrl || ImageAssets.getLeagueImage(player.league)}
              label={`${player.trophies}`}
            />
          </View>
        </View>
      </Pressable>
      {!bookmarked ? (
        <>
          <View
            style={[styles.divider, { backgroundColor: colorWithAlpha(theme.outlineVariant, 0.4) }]}
          />
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Options"
            accessibilityState={{ expanded }}
            onPress={() => setExpanded(!expanded)}
            style={styles.optionsToggle}
          >
            <SlidersHorizontal size={16} color={theme.onSurfaceVariant} />
            <CKText muted role="labelLarge" style={styles.optionTitle}>
              Options
            </CKText>
            <ChevronDown
              size={20}
              color={theme.onSurfaceVariant}
              style={{ transform: [{ rotate: expanded ? '180deg' : '0deg' }] }}
            />
          </Pressable>
          {expanded ? (
            <View style={styles.options}>
              <PlayerOptionSwitch
                icon={<Bell color={theme.onSurfaceVariant} />}
                title={t('playerOptionNotificationsTitle')}
                subtitle={notificationSubtitle}
                value={notificationActive}
                enabled={notificationAvailable}
                loading={notificationUpdating}
                onChange={(value) =>
                  void actions
                    .setAccountNotifications(player.tag, value)
                    .catch(() => actions.showMessage('Couldn’t update account notifications.'))
                }
              />
              {verified === false ? (
                <PlayerOptionAction
                  title={t('homeVerifyAccountAction')}
                  subtitle={t('playerOptionVerifyAccountBody')}
                  onPress={onVerify}
                />
              ) : null}
              <PlayerOptionSwitch
                icon={<CheckSquare color={theme.onSurfaceVariant} />}
                title={t('playerOptionShowTodoPageTitle')}
                subtitle={
                  verified
                    ? t('playerOptionShowTodoPageSubtitle')
                    : t('playerOptionShowTodoPageVerifyFirst')
                }
                value={options.showInTodoPage}
                enabled={verified === true}
                onChange={(value) => void actions.setCardOption(player.tag, 'todo', value)}
              />
              <PlayerOptionSwitch
                icon={<Construction color={theme.onSurfaceVariant} />}
                title={t('playerOptionShowUpgradeTrackerHomeTitle')}
                subtitle={
                  verified
                    ? t('playerOptionShowUpgradeTrackerHomeSubtitle')
                    : t('playerOptionShowUpgradeTrackerHomeVerifyFirst')
                }
                value={options.showUpgradeTrackerOnHome}
                enabled={verified === true}
                onChange={(value) => void actions.setCardOption(player.tag, 'upgrade', value)}
              />
              <PlayerOptionSwitch
                icon={<Trophy color={theme.onSurfaceVariant} />}
                title={t('playerOptionShowRankedHomeTitle')}
                subtitle={
                  verified
                    ? t('playerOptionShowRankedHomeSubtitle')
                    : t('playerOptionShowRankedHomeVerifyFirst')
                }
                value={options.showRankedOnHome}
                enabled={verified === true}
                onChange={(value) => void actions.setCardOption(player.tag, 'ranked', value)}
              />
              <PlayerOptionSwitch
                icon={<Shield color={theme.onSurfaceVariant} />}
                title={t('playerOptionShowWarTabTitle')}
                subtitle={t('playerOptionShowWarTabSubtitle')}
                value={options.showInWarTab}
                onChange={(value) => void actions.setCardOption(player.tag, 'war', value)}
              />
              {link ? (
                <PlayerOptionSwitch
                  icon={<EyeOff color={theme.onSurfaceVariant} />}
                  title="Hide account"
                  subtitle={
                    link.isVerified
                      ? link.hidden
                        ? 'This account is hidden from public lookups.'
                        : 'This account is visible in public lookups.'
                      : 'Verify this account to change visibility.'
                  }
                  value={link.hidden}
                  enabled={link.isVerified && !visibilityUpdating}
                  loading={visibilityUpdating}
                  onChange={() => void updateHidden()}
                />
              ) : null}
            </View>
          ) : null}
        </>
      ) : null}
    </Surface>
  );
}

export function BookmarkedPlayerCard({
  bookmark,
  onPress,
}: {
  bookmark: BookmarkedPlayerSummary;
  onPress: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  return (
    <Surface radius={ckRadius.control}>
      <Pressable accessibilityRole="button" onPress={onPress} style={styles.main}>
        <View style={styles.artColumn}>
          <MobileWebImage
            imageUrl={bookmark.townHallPic || ImageAssets.townHall(bookmark.townHallLevel)}
            style={styles.townHall}
          />
          <View style={[styles.status, { backgroundColor: theme.card }]}>
            <Bookmark size={14} color={theme.onSurfaceVariant} />
          </View>
        </View>
        <View style={styles.copy}>
          <View style={styles.titleRow}>
            <CKText role="titleMedium" numberOfLines={1} style={styles.title}>
              {bookmark.name}
            </CKText>
            <ChevronRight color={theme.onSurfaceVariant} />
          </View>
          <CKText muted role="labelLarge">
            {bookmark.tag}
          </CKText>
          <View style={styles.chips}>
            <InfoChip
              imageUrl={ImageAssets.clanCastle}
              label={bookmark.clanName || t('clanNone')}
            />
            {bookmark.trophies > 0 ? (
              <InfoChip
                imageUrl={bookmark.leagueUrl || ImageAssets.getLeagueImage(bookmark.league)}
                label={`${bookmark.trophies}`}
              />
            ) : null}
          </View>
        </View>
      </Pressable>
    </Surface>
  );
}

function InfoChip({ imageUrl, label }: { imageUrl: string; label: string }) {
  return (
    <PillSurface style={styles.chip}>
      <MobileWebImage imageUrl={imageUrl} style={styles.chipImage} />
      <CKText role="labelLarge" numberOfLines={1} style={styles.chipLabel}>
        {label}
      </CKText>
    </PillSurface>
  );
}

function PlayerOptionAction({
  title,
  subtitle,
  onPress,
}: {
  title: string;
  subtitle: string;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.option}>
      <TriangleAlert size={20} color={statColors.capitalProjected} />
      <View style={styles.optionCopy}>
        <CKText style={styles.optionTitle}>{title}</CKText>
        <CKText muted role="bodySmall" numberOfLines={2}>
          {subtitle}
        </CKText>
      </View>
      <ChevronRight color={theme.onSurfaceVariant} />
    </Pressable>
  );
}

function PlayerOptionSwitch({
  icon,
  title,
  subtitle,
  value,
  enabled = true,
  loading = false,
  onChange,
}: {
  icon: ReactElement;
  title: string;
  subtitle: string;
  value: boolean;
  enabled?: boolean;
  loading?: boolean;
  onChange: (value: boolean) => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityLabel={title}
      accessibilityState={{ checked: value, disabled: !enabled }}
      disabled={!enabled}
      onPress={() => onChange(!value)}
      style={[styles.option, !enabled && styles.disabled]}
    >
      <View style={styles.optionIcon}>{loading ? <LoadingIndicator /> : icon}</View>
      <View style={styles.optionCopy}>
        <CKText style={styles.optionTitle}>{title}</CKText>
        <CKText muted role="bodySmall" numberOfLines={2}>
          {subtitle}
        </CKText>
      </View>
      <Switch
        accessible={false}
        pointerEvents="none"
        value={value}
        disabled={!enabled}
        trackColor={{ true: theme.primary }}
        style={styles.switch}
      />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: { width: '100%' },
  main: { padding: 14, flexDirection: 'row', alignItems: 'flex-start' },
  artColumn: { width: 66, alignItems: 'center' },
  townHall: { width: 62, height: 62, resizeMode: 'contain' },
  status: {
    position: 'absolute',
    right: -1,
    top: 42,
    padding: 3,
    borderRadius: 12,
    borderWidth: StyleSheet.hairlineWidth,
  },
  activity: { marginTop: 2, textAlign: 'center', fontSize: 10, lineHeight: 11 },
  copy: { flex: 1, marginLeft: 12 },
  titleRow: { flexDirection: 'row', alignItems: 'center' },
  title: { flex: 1, fontWeight: '800', fontSize: 17 },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: 7, marginTop: 10 },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  chipImage: { width: 18, height: 18, resizeMode: 'contain' },
  chipLabel: { maxWidth: 172, fontWeight: '700' },
  divider: { height: StyleSheet.hairlineWidth },
  optionsToggle: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    gap: 8,
  },
  optionTitle: { flex: 1, fontWeight: '700' },
  options: { paddingHorizontal: 8, paddingBottom: 8 },
  option: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 6,
    paddingVertical: 6,
    borderRadius: 12,
  },
  optionIcon: { width: 30, alignItems: 'center' },
  optionCopy: { flex: 1, gap: 1 },
  switch: { transform: [{ scale: 0.85 }] },
  disabled: { opacity: 0.45 },
});
