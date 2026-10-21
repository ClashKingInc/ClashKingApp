import { useRef, useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import {
  ProfileOptionSwitch as PlayerOptionSwitch,
  profileOptionStyles,
} from '../../../ui/profile-option-switch';
import {
  Bookmark,
  CheckSquare,
  ChevronRight,
  Construction,
  EyeOff,
  House,
  ShieldCheck,
  SlidersHorizontal,
  TriangleAlert,
} from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import {
  CKText,
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
  homeIncluded = true,
  hideAccountsEnabled = false,
  actions,
  onVerify,
  onLongPress,
  dragTestID,
}: {
  player: Player;
  link?: CocAccountLink;
  bookmarked?: boolean;
  options: PlayerCardOptions;
  homeIncluded?: boolean;
  hideAccountsEnabled?: boolean;
  featureFlags: PlayersFeatureFlags;
  notificationsEnabled: boolean;
  notificationActive: boolean;
  notificationUpdating: boolean;
  actions: PlayersPresentationActions;
  onVerify: () => void;
  onLongPress?: () => void;
  dragTestID?: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState(false);
  const [visibilityUpdating, setVisibilityUpdating] = useState(false);
  const longPressActivated = useRef(false);
  const verified = link?.isVerified;
  const clan = playerClanPresentation(player);
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
    <Surface radius={ckRadius.card} style={styles.card}>
      <Pressable
        accessibilityRole="button"
        delayLongPress={300}
        onLongPress={
          onLongPress
            ? () => {
                longPressActivated.current = true;
                onLongPress();
              }
            : undefined
        }
        onPress={() => {
          if (longPressActivated.current) {
            longPressActivated.current = false;
            return;
          }
          actions.openPlayer(player);
        }}
        style={[styles.main, !bookmarked && styles.mainWithOptions]}
        testID={dragTestID}
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
                <ShieldCheck size={14} color={statColors.win} />
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
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Options"
            hitSlop={{ top: 2, bottom: 2 }}
            accessibilityState={{ expanded }}
            onPress={() => setExpanded(!expanded)}
            style={[profileOptionStyles.optionsToggle, styles.optionsToggle]}
          >
            <SlidersHorizontal size={16} color={theme.onSurfaceVariant} />
            <CKText muted role="labelLarge" style={styles.optionsTitle}>
              Options
            </CKText>
          </Pressable>
          {expanded ? (
            <View style={profileOptionStyles.options}>
              {verified === false ? (
                <PlayerOptionAction
                  title={t('homeVerifyAccountAction')}
                  subtitle={t('playerOptionVerifyAccountBody')}
                  onPress={onVerify}
                />
              ) : null}
              {link ? (
                <PlayerOptionSwitch
                  icon={<House color={theme.onSurfaceVariant} />}
                  title={t('playerOptionShowOnHomeTitle')}
                  subtitle={
                    verified
                      ? `${t('todoTitle')} · ${t('playerBattlelogFarming')}`
                      : t('playerOptionShowOnHomeVerifyFirst')
                  }
                  value={homeIncluded}
                  enabled={verified === true}
                  onChange={(value) => void actions.setCardOption(player.tag, 'home', value)}
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
              {link && hideAccountsEnabled ? (
                <PlayerOptionSwitch
                  icon={<EyeOff color={theme.onSurfaceVariant} />}
                  title={t('playerHideAccountTitle')}
                  subtitle={
                    link.isVerified
                      ? t('playerHideAccountExplanation')
                      : t('playerHideAccountVerify')
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
  onLongPress,
  dragTestID,
}: {
  bookmark: BookmarkedPlayerSummary;
  onPress: () => void;
  onLongPress?: () => void;
  dragTestID?: string;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const longPressActivated = useRef(false);
  return (
    <Surface radius={ckRadius.card} style={styles.card}>
      <Pressable
        accessibilityRole="button"
        delayLongPress={300}
        onLongPress={
          onLongPress
            ? () => {
                longPressActivated.current = true;
                onLongPress();
              }
            : undefined
        }
        onPress={() => {
          if (longPressActivated.current) {
            longPressActivated.current = false;
            return;
          }
          onPress();
        }}
        style={styles.main}
        testID={dragTestID}
      >
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
    <Pressable accessibilityRole="button" onPress={onPress} style={profileOptionStyles.option}>
      <TriangleAlert size={20} color={statColors.capitalProjected} />
      <View style={profileOptionStyles.optionCopy}>
        <CKText style={profileOptionStyles.rowTitle}>{title}</CKText>
        <CKText muted role="bodySmall" numberOfLines={2}>
          {subtitle}
        </CKText>
      </View>
      <ChevronRight color={theme.onSurfaceVariant} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: { width: '100%', borderWidth: 0 },
  optionsToggle: { justifyContent: 'flex-end' },
  optionsTitle: { fontWeight: '700' },
  main: { padding: 14, flexDirection: 'row', alignItems: 'flex-start' },
  mainWithOptions: { paddingBottom: 2 },
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
});
