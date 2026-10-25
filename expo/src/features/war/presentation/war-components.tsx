import { HeroHeaderScrim } from '../../../ui/hero-header-scrim';
import { modalOrientations } from '../../../ui/modal-orientations';
import { HeaderIconButton } from '../../../ui/header';
import { AccountBarScrollView } from '../../../ui/account-bar-scroll-view';
import { CARD_REORDER_HOLD_MS } from '../../../ui/drag-jiggle';
import { useEffect, useState, type ReactNode } from 'react';
import {
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { ArrowLeft, ChevronRight, Eye, Shield, Sword, X } from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { materialBackLabel, useI18n } from '../../../i18n';
import {
  CKText,
  GlassSurface,
  MobileWebImage,
  ckColors,
  PillSurface,
  SkeletonContent,
  SelectionPickerModal,
  Surface,
  colorWithAlpha,
  tintIcon,
  useCKTheme,
} from '../../../ui';
import type { WarAttack, WarInfo, WarMember } from '../models';
import type { WarRosterItem } from './contracts';
import { loadingWar } from './war-loading-model';
import {
  formatDuration,
  formatPercent,
  remainingWarTime,
  warTimeRemaining,
} from './presentation-utils';

export function WarSummaryCard({
  item,
  now = new Date(),
  onOpenWar,
  onOpenCwl,
  onLongPress,
  dragTestID,
  loading = false,
}: {
  item: WarRosterItem;
  now?: Date;
  onOpenWar: (war: WarInfo) => void;
  onOpenCwl: () => void;
  onLongPress?: () => void;
  dragTestID?: string;
  loading?: boolean;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const war = item.displayWar;
  if (loading && !item.summary) {
    return (
      <SkeletonContent loading>
        <WarSummaryCard
          item={{ ...item, displayWar: loadingWar(item.tag, item.name, item.badgeUrl) }}
          now={now}
          onOpenWar={onOpenWar}
          onOpenCwl={onOpenCwl}
        />
      </SkeletonContent>
    );
  }
  if (!war || ['notInWar', 'unknown', 'accessDenied'].includes(war.state)) {
    const privateLog = item.summary?.warInfo.state === 'accessDenied';
    return (
      <Pressable
        delayLongPress={CARD_REORDER_HOLD_MS}
        onLongPress={onLongPress}
        testID={dragTestID}
      >
        <Surface style={styles.emptyWarCard}>
          <MobileWebImage
            imageUrl={item.badgeUrl || ImageAssets.clanCastle}
            style={styles.emptyBadge}
          />
          <CKText muted style={styles.emptyMessage}>
            {privateLog
              ? t('warLogClosed', { clan: item.name })
              : t('warIsNotInWar', { clan: item.name })}
          </CKText>
        </Surface>
      </Pressable>
    );
  }
  const statuses = item.accountStatuses.filter((status) => status.inWar);
  const allSpectators = item.accounts.length > 0 && statuses.length === 0;
  const canOpenCwl = item.summary?.leagueInfo?.getClanDetails(item.tag) != null;
  const cwlBanner = item.cwlRoundNumber ? (
    <View style={[styles.cwlStrip, { backgroundColor: colorWithAlpha('#8D63D9', 0.16) }]}>
      <MobileWebImage imageUrl={ImageAssets.cwlSwordsNoBorder} style={styles.stripIcon} />
      <CKText role="labelMedium">
        CWL — {t('cwlRoundNumber', { number: item.cwlRoundNumber })}
        {item.cwlRank ? ` — #${item.cwlRank}` : ''}
      </CKText>
    </View>
  ) : null;
  const stateLabel =
    war.state === 'preparation'
      ? war.startTime
        ? `${t('warPreparation')}\n${t('timeStartsIn', {
            time: remainingWarTime(war.startTime, now, t),
          })}`
        : t('warPreparation')
      : war.state === 'warEnded'
        ? resultLabel(war, item.tag, t)
        : war.endTime
          ? t('timeEndsIn', {
              time: remainingWarTime(war.endTime, now, t),
            })
          : t('warOngoing');
  const accountStatus = statuses.length ? (
    <AccountBarScrollView
      horizontal
      testID="war-summary-account-status"
      showsHorizontalScrollIndicator={statuses.length > 1}
      contentContainerStyle={styles.accountStatusContent}
      style={[
        styles.accountStatusFooter,
        { backgroundColor: colorWithAlpha(theme.onSurface, 0.035) },
      ]}
    >
      {[...statuses]
        .sort(
          (left, right) =>
            right.left - left.left || left.account.name.localeCompare(right.account.name),
        )
        .map((status) => {
          const statusColor =
            status.left === 0
              ? ckColors.donationGreen
              : war.state === 'preparation'
                ? theme.onSurfaceVariant
                : ckColors.lossRed;
          return (
            <View
              key={status.account.tag}
              style={styles.accountStatusItem}
              accessible
              accessibilityLabel={`${status.account.name}, ${t('warAttacksTitle')}: ${status.done}/${war.effectiveAttacksPerMember}`}
            >
              <View style={[styles.accountStatusDot, { backgroundColor: statusColor }]} />
              <CKText role="labelMedium" numberOfLines={1}>
                {status.account.name}
              </CKText>
              <MobileWebImage imageUrl={ImageAssets.sword} style={{ width: 13, height: 13 }} />
              <CKText
                role="labelMedium"
                style={{ color: statusColor, fontVariant: ['tabular-nums'] }}
              >
                {status.done}/{war.effectiveAttacksPerMember}
              </CKText>
            </View>
          );
        })}
    </AccountBarScrollView>
  ) : allSpectators ? (
    <View
      style={[
        styles.accountStatusFooter,
        styles.spectatorFooter,
        { backgroundColor: colorWithAlpha(theme.onSurface, 0.035) },
      ]}
    >
      <Eye size={13} color={theme.onSurfaceVariant} />
      <CKText role="labelMedium" muted>
        Spectator
      </CKText>
    </View>
  ) : null;
  return (
    <Surface style={styles.warCard}>
      {cwlBanner && canOpenCwl ? (
        <Pressable
          accessibilityRole="button"
          onPress={onOpenCwl}
          delayLongPress={CARD_REORDER_HOLD_MS}
          onLongPress={onLongPress}
        >
          {cwlBanner}
        </Pressable>
      ) : (
        cwlBanner
      )}
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${war.clan?.name} versus ${war.opponent?.name}`}
        onPress={() => onOpenWar(war)}
        delayLongPress={CARD_REORDER_HOLD_MS}
        onLongPress={onLongPress}
        testID={dragTestID}
      >
        <View testID="war-summary-body" style={styles.summaryBody}>
          <CompactWarScoreboard
            war={war}
            aboveScore={
              war.state === 'warEnded' ? (
                <CKText
                  testID="war-summary-result-label"
                  role="bodyMedium"
                  style={[styles.resultLabel, { color: warResultColor(war, item.tag, theme) }]}
                >
                  {stateLabel}
                </CKText>
              ) : (
                <CKText
                  testID="war-summary-state-label"
                  role="labelLarge"
                  numberOfLines={2}
                  style={styles.stateLabel}
                >
                  {stateLabel}
                </CKText>
              )
            }
          />
        </View>
        {/* Keep participation separate from the scoreboard. A horizontal rail
            supports every account without stretching the card or hiding names
            behind an aggregate count. Any participant suppresses Spectator. */}
        {accountStatus}
      </Pressable>
    </Surface>
  );
}

export function WarStatePill({ war, clanTag }: { war: WarInfo; clanTag: string }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const label =
    war.state === 'warEnded'
      ? resultLabel(war, clanTag, t)
      : war.state === 'preparation'
        ? t('warPreparation')
        : war.state === 'inWar'
          ? t('warOngoing')
          : t('generalNoDataAvailable');
  const color =
    war.state === 'warEnded'
      ? warResultColor(war, clanTag, theme)
      : war.state === 'inWar'
        ? theme.primary
        : theme.onSurfaceVariant;
  return (
    <PillSurface
      style={{
        paddingHorizontal: 12,
        paddingVertical: 7,
        flexShrink: 1,
        backgroundColor: colorWithAlpha(color, 0.12),
      }}
    >
      <CKText role="body" style={{ color }}>
        {label}
      </CKText>
    </PillSurface>
  );
}

export function WarHero({
  war,
  cwlRoundNumber,
  onBack,
  onOpenClan,
  onCopy,
  onOpenCwl,
}: {
  war: WarInfo;
  cwlRoundNumber?: number | null;
  onBack: () => void;
  onOpenClan: (tag: string) => void;
  onCopy: (tag: string) => void;
  onOpenCwl?: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  return (
    <View style={styles.hero}>
      <MobileWebImage
        imageUrl={ImageAssets.warPageBackground}
        style={StyleSheet.absoluteFill}
        contentFit="cover"
        contentPosition="bottom"
      />
      <HeroHeaderScrim variant="war" />
      <View style={styles.heroActions}>
        <HeaderIconButton
          icon={<ArrowLeft color="#fff" size={24} />}
          label={materialBackLabel(locale)}
          onPress={onBack}
          glass={false}
        />
        {cwlRoundNumber && onOpenCwl ? (
          <View pointerEvents="box-none" style={styles.heroRoundCenter}>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('cwlRoundNumber', { number: cwlRoundNumber })}
              onPress={onOpenCwl}
            >
              <PillSurface style={styles.roundPill}>
                <MobileWebImage imageUrl={ImageAssets.cwlSwordsNoBorder} style={styles.roundIcon} />
                <CKText role="body" numberOfLines={1} style={styles.roundLabel}>
                  {t('cwlRoundNumber', { number: cwlRoundNumber })}
                </CKText>
                <ChevronRight size={18} color={theme.onSurfaceVariant} />
              </PillSurface>
            </Pressable>
          </View>
        ) : null}
      </View>
      <View style={{ paddingHorizontal: 16, width: '100%', maxWidth: 720, alignSelf: 'center' }}>
        <WarMatchup war={war} hero onOpenClan={onOpenClan} onCopy={onCopy} />
      </View>
    </View>
  );
}

export function AttackDetailsModal({
  visible,
  attack,
  war,
  onClose,
  onOpenPlayer,
}: {
  visible: boolean;
  attack: WarAttack | null;
  war: WarInfo;
  onClose: () => void;
  onOpenPlayer: (tag: string) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  if (!attack) return null;
  const attacker = war.getMemberByTag(attack.attackerTag) ?? attack.attacker;
  const defender = war.getMemberByTag(attack.defenderTag) ?? attack.defender;
  const clanFor = (tag: string) =>
    [war.clan, war.opponent].find((clan) => clan?.members.some((member) => member.tag === tag)) ??
    null;
  return (
    <Modal
      supportedOrientations={modalOrientations}
      transparent
      visible={visible}
      animationType="slide"
      onRequestClose={onClose}
    >
      <Pressable style={styles.modalOverlay} onPress={onClose}>
        <Pressable
          onPress={(event) => event.stopPropagation()}
          style={[styles.detailSheet, { backgroundColor: theme.surface }]}
        >
          <ScrollView contentContainerStyle={styles.detailSheetContent}>
            <View style={styles.handle} />
            <View style={styles.modalTitleRow}>
              <View style={styles.grow}>
                <CKText role="titleLarge">{t('warAttacksDetailsTitle')}</CKText>
                <View style={styles.detailMeta}>
                  <PillSurface style={styles.detailMetaPill}>
                    <CKText role="labelMedium">#{attack.order}</CKText>
                  </PillSurface>
                  {war.isClanWarLeague || war.warType === 'friendly' ? (
                    <PillSurface style={styles.detailMetaPill}>
                      <CKText role="labelMedium">
                        {t(war.isClanWarLeague ? 'cwlTitle' : 'warFiltersFriendly')}
                      </CKText>
                    </PillSurface>
                  ) : null}
                </View>
              </View>
              <RoundButton label={t('generalCancel')} onPress={onClose}>
                <X size={20} color={theme.onSurface} />
              </RoundButton>
            </View>
            <View style={styles.resultHero}>
              <View
                style={styles.resultStars}
                accessibilityLabel={`${attack.stars}/3 ${t('warStarsTitle')}`}
              >
                {[0, 1, 2].map((index) => (
                  <MobileWebImage
                    key={index}
                    imageUrl={ImageAssets.attackStar}
                    style={[styles.resultStar, index >= attack.stars && styles.unearnedStar]}
                  />
                ))}
              </View>
              <CKText role="titleLarge">{formatPercent(attack.destructionPercentage)}</CKText>
            </View>
            <Participant
              title={t('warAttacksDetailsAttacker')}
              member={attacker}
              clan={clanFor(attack.attackerTag)}
              onPress={() => onOpenPlayer(attack.attackerTag)}
            />
            <View style={styles.versus}>
              <Sword size={18} color={theme.onSurfaceVariant} />
              <CKText muted>VS</CKText>
              <Shield size={18} color={theme.onSurfaceVariant} />
            </View>
            <Participant
              title={t('warAttacksDetailsDefender')}
              member={defender}
              clan={clanFor(attack.defenderTag)}
              onPress={() => onOpenPlayer(attack.defenderTag)}
            />
            <Surface muted style={styles.detailsPanel}>
              {attack.duration !== null ? (
                <DetailRow
                  label={t('warAttacksDetailsDuration')}
                  value={formatDuration(attack.duration)}
                />
              ) : null}
              <DetailRow
                label={t('warTeamSize')}
                value={war.teamSize?.toString() ?? t('generalUnknown')}
              />
              <DetailRow
                label={t('warDataAttacksPerMember')}
                value={String(war.effectiveAttacksPerMember)}
              />
            </Surface>
          </ScrollView>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

export function SelectionModal<T extends string>({
  visible,
  title,
  options,
  selected,
  onSelect,
  onClose,
}: {
  visible: boolean;
  title: string;
  options: readonly { readonly key: T; readonly label: string; readonly icon?: ReactNode }[];
  selected: T;
  onSelect: (value: T) => void;
  onClose: () => void;
}) {
  return (
    <SelectionPickerModal
      visible={visible}
      title={title}
      options={options}
      selectedKey={selected}
      onClose={onClose}
      onSelect={(value) => {
        onSelect(value);
        onClose();
      }}
    />
  );
}

export function MetricPill({
  image,
  icon,
  value,
  label,
}: {
  image?: string;
  icon?: ReactNode;
  value: string;
  label?: string;
}) {
  const theme = useCKTheme();
  return (
    <PillSurface
      style={styles.metricPill}
      accessibilityLabel={label ? `${label}: ${value}` : value}
    >
      {image ? (
        <MobileWebImage imageUrl={image} style={styles.metricIcon} />
      ) : (
        tintIcon(icon, theme.onSurfaceVariant)
      )}
      <View>
        <CKText role="labelLarge">{value}</CKText>
        {label ? (
          <CKText muted role="labelSmall">
            {label}
          </CKText>
        ) : null}
      </View>
    </PillSurface>
  );
}

export function SectionPanel({
  title,
  children,
  style,
}: {
  title?: string;
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
}) {
  return (
    <Surface style={[styles.sectionPanel, style]}>
      {title ? <CKText role="titleMedium">{title}</CKText> : null}
      {children}
    </Surface>
  );
}

/** Shared compact score layout; participation belongs outside the score area. */
export function CompactWarScoreboard({
  war,
  leftColor,
  rightColor,
  aboveScore,
  lightText = false,
  onOpenClan,
  onCopyClan,
}: {
  war: WarInfo;
  leftColor?: string;
  rightColor?: string;
  aboveScore?: ReactNode;
  lightText?: boolean;
  onOpenClan?: (tag: string) => void;
  onCopyClan?: (tag: string) => void;
}) {
  const attackCapacity = (war.teamSize ?? 0) * war.effectiveAttacksPerMember;
  return (
    <View style={styles.scoreboard}>
      <View style={styles.warBody}>
        <WarSide
          clan={war.clan}
          nameColor={leftColor ?? (lightText ? '#fff' : undefined)}
          attackCapacity={attackCapacity}
          onOpenClan={onOpenClan}
          onCopyClan={onCopyClan}
          lightText={lightText}
        />
        <View style={styles.scoreColumn}>
          {aboveScore}
          {war.state === 'preparation' ? (
            <CKText style={[styles.scoreValue, lightText && { color: '#fff' }]}>—</CKText>
          ) : (
            <>
              <WarScoreRow
                left={war.clan?.stars ?? 0}
                right={war.opponent?.stars ?? 0}
                color={lightText ? '#fff' : undefined}
              />
              <View style={styles.destructionRow}>
                <CKText
                  role="labelSmall"
                  muted
                  style={[styles.destructionValue, lightText && { color: '#D8DEE8' }]}
                >
                  {formatPercent(war.clan?.destructionPercentage ?? 0)}
                </CKText>
                <CKText
                  role="labelSmall"
                  muted
                  style={[styles.destructionValue, lightText && { color: '#D8DEE8' }]}
                >
                  {formatPercent(war.opponent?.destructionPercentage ?? 0)}
                </CKText>
              </View>
            </>
          )}
        </View>
        <WarSide
          clan={war.opponent}
          nameColor={rightColor ?? (lightText ? '#fff' : undefined)}
          onOpenClan={onOpenClan}
          onCopyClan={onCopyClan}
          attackCapacity={attackCapacity}
          lightText={lightText}
        />
      </View>
    </View>
  );
}

function WarSide({
  clan,
  attackCapacity,
  nameColor,
  onOpenClan,
  lightText = false,
  onCopyClan,
}: {
  clan: WarInfo['clan'];
  attackCapacity?: number;
  nameColor?: string;
  onOpenClan?: (tag: string) => void;
  lightText?: boolean;
  onCopyClan?: (tag: string) => void;
}) {
  const { t } = useI18n();
  return (
    <View style={styles.warSide}>
      {onOpenClan && clan ? (
        <Pressable
          accessibilityRole="button"
          accessibilityLabel={clan.name}
          onPress={() => onOpenClan(clan.tag)}
          onLongPress={onCopyClan ? () => onCopyClan(clan.tag) : undefined}
        >
          <MobileWebImage
            imageUrl={clan.badgeUrls.smallest || ImageAssets.clanCastle}
            style={styles.warBadge}
          />
        </Pressable>
      ) : (
        <MobileWebImage
          imageUrl={clan?.badgeUrls.smallest || ImageAssets.clanCastle}
          style={styles.warBadge}
        />
      )}
      <CKText
        role="labelMedium"
        style={[styles.sideName, nameColor ? { color: nameColor } : undefined]}
      >
        {clan?.name ?? '—'}
      </CKText>
      {attackCapacity !== undefined ? (
        <View
          style={styles.sideAttacks}
          accessible
          accessibilityLabel={`${t('warAttacksTitle')}: ${clan?.attacks ?? 0}/${attackCapacity}`}
        >
          <MobileWebImage imageUrl={ImageAssets.sword} style={{ width: 12, height: 12 }} />
          <CKText
            role="labelSmall"
            muted
            style={[{ fontVariant: ['tabular-nums'] }, lightText && { color: '#D8DEE8' }]}
          >
            {clan?.attacks ?? 0}/{attackCapacity}
          </CKText>
        </View>
      ) : null}
    </View>
  );
}

function WarScoreRow({ left, right, color }: { left: number; right: number; color?: string }) {
  return (
    <View testID="war-summary-score" style={styles.scoreRow}>
      <CKText
        role="titleMedium"
        numberOfLines={1}
        adjustsFontSizeToFit
        style={[styles.scoreValue, styles.leftScore, color ? { color } : undefined]}
      >
        {left}
      </CKText>
      <MobileWebImage imageUrl={ImageAssets.attackStar} style={{ width: 19, height: 19 }} />
      <CKText
        role="titleMedium"
        numberOfLines={1}
        adjustsFontSizeToFit
        style={[styles.scoreValue, styles.rightScore, color ? { color } : undefined]}
      >
        {right}
      </CKText>
    </View>
  );
}

/** One competitive identity, shared by the season's current matchup and war detail. */
export function WarMatchup({
  war,
  hero = false,
  onOpenClan,
  onCopy,
}: {
  war: WarInfo;
  hero?: boolean;
  onOpenClan?: (tag: string) => void;
  onCopy?: (tag: string) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const foreground = hero ? '#fff' : theme.onSurface;
  const secondary = hero ? '#ffffffcc' : theme.onSurfaceVariant;
  const capacity = (war.teamSize ?? 0) * war.effectiveAttacksPerMember;
  return (
    <View style={{ gap: 16 }}>
      <WarTiming war={war} hero={hero} />
      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
        <MobileWebImage
          imageUrl={war.clan?.badgeUrls.smallest || ImageAssets.clanCastle}
          style={{ width: 56, height: 56 }}
        />
        <View style={{ alignItems: 'center', flex: 1 }}>
          <CKText
            numberOfLines={1}
            style={{
              color: foreground,
              fontSize: 28,
              lineHeight: 34,
              fontWeight: '700',
              fontVariant: ['tabular-nums'],
            }}
          >
            {war.state === 'preparation'
              ? '—'
              : `${war.clan?.stars ?? 0} – ${war.opponent?.stars ?? 0}`}
          </CKText>
          <MobileWebImage
            imageUrl={ImageAssets.attackStar}
            style={{ width: 22, height: 22 }}
            accessibilityLabel={t('warStarsTitle')}
          />
        </View>
        <MobileWebImage
          imageUrl={war.opponent?.badgeUrls.smallest || ImageAssets.clanCastle}
          style={{ width: 56, height: 56 }}
        />
      </View>
      <View style={{ flexDirection: 'row', alignItems: 'flex-start', gap: 24 }}>
        {[war.clan, war.opponent].map((clan, index) => (
          <View key={index} style={{ flex: 1, minWidth: 0, alignItems: 'center', gap: 8 }}>
            <Pressable
              disabled={!onOpenClan || !clan}
              accessibilityRole={onOpenClan ? 'button' : undefined}
              accessibilityLabel={clan?.name}
              onPress={() => clan && onOpenClan?.(clan.tag)}
              onLongPress={() => clan && onCopy?.(clan.tag)}
              style={{
                alignItems: 'center',
                width: '100%',
                minHeight: onOpenClan ? 44 : undefined,
              }}
            >
              <CKText
                role="bodyLarge"
                numberOfLines={2}
                style={{ color: foreground, textAlign: 'center' }}
              >
                {clan?.name ?? '—'}
              </CKText>
            </Pressable>
          </View>
        ))}
      </View>
      {war.state !== 'preparation' ? (
        <View style={{ flexDirection: 'row', gap: 16 }}>
          {[war.clan, war.opponent].map((clan, index) => (
            <View key={index} style={styles.matchupMetrics}>
              <CKText
                role="body"
                accessibilityLabel={`${t('warDestructionTitle')}: ${formatPercent(clan?.destructionPercentage ?? 0)}`}
                style={{ color: foreground, fontVariant: ['tabular-nums'] }}
              >
                {formatPercent(clan?.destructionPercentage ?? 0)}
              </CKText>
              <View
                style={styles.matchupAttackCount}
                accessible
                accessibilityLabel={`${t('warAttacksTitle')}: ${clan?.attacks ?? 0}/${capacity}`}
              >
                <MobileWebImage imageUrl={ImageAssets.sword} style={{ width: 18, height: 18 }} />
                <CKText role="body" style={{ color: secondary, fontVariant: ['tabular-nums'] }}>
                  {clan?.attacks ?? 0}/{capacity}
                </CKText>
              </View>
            </View>
          ))}
        </View>
      ) : null}
    </View>
  );
}

export function WarTiming({ war, hero = false }: { war: WarInfo; hero?: boolean }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 30_000);
    return () => clearInterval(timer);
  }, []);
  return (
    <View style={{ alignItems: 'center', gap: 8 }}>
      {hero ? (
        <CKText style={{ color: '#ffffffcc' }}>
          {war.state === 'warEnded'
            ? resultLabel(war, war.clan?.tag ?? '', t)
            : war.state === 'preparation'
              ? t('warPreparation')
              : t('warOngoing')}
        </CKText>
      ) : (
        <WarStatePill war={war} clanTag={war.clan?.tag ?? ''} />
      )}
      {war.state !== 'warEnded' ? (
        <CKText style={{ color: hero ? '#fff' : theme.onSurface, textAlign: 'center' }}>
          {warCountdown(war, now, t, locale)}
        </CKText>
      ) : null}
    </View>
  );
}

function Participant({
  title,
  member,
  clan,
  onPress,
}: {
  title: string;
  member: Pick<WarMember, 'tag' | 'name' | 'townhallLevel' | 'mapPosition'> | null;
  clan: WarInfo['clan'];
  onPress: () => void;
}) {
  return (
    <Pressable accessibilityRole="button" onPress={onPress} style={styles.participant}>
      <MobileWebImage
        imageUrl={ImageAssets.townHall(member?.townhallLevel ?? 1)}
        style={styles.participantImage}
      />
      <View style={styles.grow}>
        <CKText muted role="labelSmall">
          {title}
        </CKText>
        <CKText role="rowTitle">{member?.name ?? '—'}</CKText>
        <CKText muted>{member?.tag ?? '—'}</CKText>
        {clan ? (
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
            <MobileWebImage imageUrl={clan.badgeUrls.smallest} style={{ width: 18, height: 20 }} />
            <CKText role="metadata" muted>
              {clan.name}
            </CKText>
          </View>
        ) : null}
      </View>
      <PillSurface style={styles.mapPill}>
        <CKText role="labelMedium">#{member?.mapPosition ?? '—'}</CKText>
      </PillSurface>
    </Pressable>
  );
}

function DetailRow({ label, value }: { label: string; value: string }) {
  return (
    <View style={styles.detailRow}>
      <CKText muted>{label}</CKText>
      <CKText role="labelLarge">{value}</CKText>
    </View>
  );
}

function RoundButton({
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
      <GlassSurface interactive cornerRadius={22} style={styles.roundButton}>
        {children}
      </GlassSurface>
    </Pressable>
  );
}

function resultLabel(war: WarInfo, clanTag: string, t: ReturnType<typeof useI18n>['t']): string {
  const result = war.getWarResult(clanTag);
  if (result === 'won') return t('warVictory');
  if (result === 'lost') return t('warDefeat');
  if (result === 'tie') return t('warDraw');
  if (result === 'perfectWar') return t('warPerfectWar');
  return t('warEnded');
}

function warResultColor(war: WarInfo, clanTag: string, theme: ReturnType<typeof useCKTheme>) {
  const result = war.getWarResult(clanTag);
  if (result === 'won' || result === 'perfectWar') return '#2EAD70';
  if (result === 'lost') return theme.error;
  return theme.onSurface;
}

function warCountdown(
  war: WarInfo,
  now: Date,
  t: ReturnType<typeof useI18n>['t'],
  locale: string,
): string {
  if (war.state === 'warEnded') return t('warEnded');
  const target =
    war.state === 'preparation' ? war.startTime : war.state === 'inWar' ? war.endTime : null;
  if (!target) return '';
  const time = warTimeRemaining(target, now, locale);
  return war.state === 'preparation' ? t('timeStartsIn', { time }) : t('timeEndsIn', { time });
}

const styles = StyleSheet.create({
  grow: { flex: 1 },
  emptyWarCard: {
    minHeight: 132,
    padding: 16,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
  },
  emptyBadge: { width: 74, height: 74, resizeMode: 'contain' },
  emptyMessage: { textAlign: 'center' },
  warCard: { width: '100%' },
  cwlStrip: {
    minHeight: 34,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingHorizontal: 12,
  },
  stripIcon: { width: 16, height: 16, resizeMode: 'contain' },
  summaryBody: { paddingHorizontal: 8, paddingTop: 16, paddingBottom: 8 },
  scoreboard: { gap: 8, width: '100%' },
  warBody: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  // Each identity is a single stack: badge, name, then attacks. Do not split the
  // names into another row; that disconnects them from their badge on wider cards.
  warSide: { flex: 3, minWidth: 0, alignItems: 'center', gap: 3 },
  warBadge: { width: 54, height: 54, resizeMode: 'contain' },
  sideName: { textAlign: 'center' },
  sideAttacks: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 1 },
  scoreColumn: { flex: 5, minWidth: 0, alignItems: 'center', justifyContent: 'center', gap: 5 },
  stateLabel: { textAlign: 'center', fontWeight: '700', flexShrink: 1, lineHeight: 18 },
  resultLabel: { fontWeight: '600', textAlign: 'center', lineHeight: 18 },
  scoreRow: {
    width: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  scoreValue: {
    fontSize: 28,
    lineHeight: 34,
    flexShrink: 1,
    fontVariant: ['tabular-nums'],
    fontWeight: '800',
    textAlign: 'center',
  },
  leftScore: { flex: 1, textAlign: 'right' },
  rightScore: { flex: 1, textAlign: 'left' },
  destructionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
    marginTop: -3,
  },
  destructionValue: { width: 56, textAlign: 'center' },
  accountStatusFooter: { borderBottomLeftRadius: 28, borderBottomRightRadius: 28 },
  accountStatusContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 20,
    paddingHorizontal: 16,
    paddingVertical: 10,
    flexGrow: 1,
  },
  accountStatusItem: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  accountStatusDot: { width: 5, height: 5, borderRadius: 3 },
  spectatorFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 5,
    padding: 9,
  },
  hero: { overflow: 'hidden', paddingBottom: 24, gap: 16 },
  matchupMetrics: {
    flex: 1,
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    alignItems: 'center',
    columnGap: 14,
    rowGap: 6,
  },
  matchupAttackCount: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  heroStatus: { alignItems: 'center', gap: 8, paddingHorizontal: 16 },
  sideMetrics: { alignItems: 'center', marginTop: 12, gap: 2 },
  heroActions: {
    height: 44,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
  },
  heroBackButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  heroRoundCenter: {
    position: 'absolute',
    left: 64,
    right: 64,
    alignItems: 'center',
  },
  roundButton: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  roundPill: {
    minHeight: 44,
    maxWidth: '100%',
    paddingHorizontal: 13,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  roundIcon: { width: 19, height: 19, resizeMode: 'contain' },
  roundLabel: { flexShrink: 1, fontWeight: '800' },
  heroScore: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 12 },
  heroScoreCore: { alignItems: 'center', justifyContent: 'center', gap: 6, paddingHorizontal: 10 },
  heroSide: { flex: 3, alignItems: 'center' },
  heroBadge: { alignSelf: 'center' },
  heroText: { color: '#fff', textAlign: 'center' },
  heroClanName: { marginTop: 8, minHeight: 42, fontWeight: '700' },
  heroLeadingClanName: { fontWeight: '900' },
  heroMuted: { color: '#ffffffa8', textAlign: 'center' },
  copyTag: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 4 },
  countdown: { color: '#ffffffdb', textAlign: 'center', fontSize: 15, fontWeight: '800' },
  warIcon: { width: 32, height: 32, alignSelf: 'center' },
  warIconDesktop: { width: 38, height: 38, alignSelf: 'center' },
  modalOverlay: { flex: 1, backgroundColor: '#00000088', justifyContent: 'flex-end' },
  detailSheet: {
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    maxHeight: '92%',
    overflow: 'hidden',
  },
  detailSheetContent: { padding: 18, paddingBottom: 28, gap: 14 },
  handle: {
    width: 44,
    height: 5,
    borderRadius: 3,
    backgroundColor: '#88888888',
    alignSelf: 'center',
  },
  modalTitleRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  detailMeta: { flexDirection: 'row', flexWrap: 'wrap', gap: 7, paddingTop: 8 },
  detailMetaPill: { paddingHorizontal: 9, paddingVertical: 5 },
  resultHero: { alignItems: 'center', gap: 4 },
  resultStars: { flexDirection: 'row', gap: 4 },
  resultStar: { width: 32, height: 32 },
  unearnedStar: { opacity: 0.2 },
  participant: { minHeight: 72, flexDirection: 'row', alignItems: 'center', gap: 10 },
  participantImage: { width: 54, height: 54, resizeMode: 'contain' },
  mapPill: { paddingHorizontal: 10, paddingVertical: 6 },
  versus: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8 },
  detailsPanel: { padding: 12, gap: 9 },
  detailRow: { flexDirection: 'row', justifyContent: 'space-between', gap: 12 },
  metricPill: {
    minHeight: 46,
    paddingHorizontal: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 7,
  },
  metricIcon: { width: 22, height: 22, resizeMode: 'contain' },
  sectionPanel: { padding: 14, gap: 12 },
});
