import { HeaderIconButton } from '../../../ui/header';
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
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';
import {
  Bookmark,
  ArrowLeft,
  ChevronRight,
  Eye,
  Link2,
  Shield,
  Sword,
  X,
} from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { materialBackLabel, useI18n } from '../../../i18n';
import {
  CKText,
  GlassSurface,
  MobileWebImage,
  PillSurface,
  SelectionPickerModal,
  Surface,
  colorWithAlpha,
  tintIcon,
  useCKTheme,
  useCKThemeMode,
} from '../../../ui';
import type { WarAttack, WarInfo, WarMember } from '../models';
import type { WarRosterItem } from './contracts';
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
}: {
  item: WarRosterItem;
  now?: Date;
  onOpenWar: (war: WarInfo) => void;
  onOpenCwl: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const war = item.displayWar;
  if (!war || ['notInWar', 'unknown', 'accessDenied'].includes(war.state)) {
    const privateLog = item.summary?.warInfo.state === 'accessDenied';
    return (
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
  return (
    <Surface style={styles.warCard}>
      {cwlBanner && canOpenCwl ? (
        <Pressable accessibilityRole="button" onPress={onOpenCwl}>
          {cwlBanner}
        </Pressable>
      ) : (
        cwlBanner
      )}
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={`${war.clan?.name} versus ${war.opponent?.name}`}
        onPress={() => onOpenWar(war)}
      >
        <View style={[styles.warBody, war.state === 'preparation' && styles.preparationWarBody]}>
          <WarSide clan={war.clan} />
          <View style={styles.scoreColumn}>
            {allSpectators ? (
              <PillSurface style={styles.statusPill}>
                <Eye size={13} color={theme.onSurfaceVariant} />
                <CKText role="labelSmall">Spectator</CKText>
              </PillSurface>
            ) : null}
            {war.state === 'warEnded' ? (
              <CKText
                role="titleMedium"
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
            )}
            {war.state !== 'preparation' ? (
              <>
                <WarScoreRow left={war.clan?.stars ?? 0} right={war.opponent?.stars ?? 0} />
                <WarDestructionRow
                  left={war.clan?.destructionPercentage ?? 0}
                  right={war.opponent?.destructionPercentage ?? 0}
                />
              </>
            ) : null}
          </View>
          <WarSide clan={war.opponent} />
        </View>
        {statuses.length ? (
          <View style={styles.attackStatusWrap}>
            {[...statuses]
              .sort(
                (left, right) =>
                  right.left - left.left || left.account.name.localeCompare(right.account.name),
              )
              .map((status) => {
                const complete = status.left === 0;
                return (
                  <View
                    key={status.account.tag}
                    style={[
                      styles.attackStatus,
                      {
                        backgroundColor: colorWithAlpha(complete ? '#2EAD70' : theme.primary, 0.14),
                      },
                    ]}
                  >
                    {status.account.bookmarked ? (
                      <Bookmark size={13} color={theme.onSurfaceVariant} />
                    ) : (
                      <Link2 size={13} color={theme.onSurfaceVariant} />
                    )}
                    <CKText role="labelSmall">
                      {status.account.name} {status.done}/{war.effectiveAttacksPerMember}
                    </CKText>
                  </View>
                );
              })}
          </View>
        ) : null}
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
  const themeMode = useCKThemeMode();
  return (
    <View style={styles.hero}>
      <MobileWebImage
        imageUrl={ImageAssets.warPageBackground}
        style={StyleSheet.absoluteFill}
        contentFit="cover"
        contentPosition="bottom"
      />
      <View style={[StyleSheet.absoluteFill, { backgroundColor: '#00000080' }]} />
      <Svg pointerEvents="none" style={StyleSheet.absoluteFill}>
        <Defs>
          <LinearGradient id="war-header-scrim" x1="0" y1="0" x2="0" y2="1">
            <Stop offset="0" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.36 : 0.2} />
            <Stop offset="0.55" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.64 : 0.4} />
            <Stop offset="1" stopColor="#000" stopOpacity={themeMode === 'dark' ? 0.92 : 0.65} />
          </LinearGradient>
        </Defs>
        <Rect width="100%" height="100%" fill="url(#war-header-scrim)" />
      </Svg>
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
  return (
    <Modal transparent visible={visible} animationType="slide" onRequestClose={onClose}>
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
                  <PillSurface style={styles.detailMetaPill}>
                    <CKText role="labelMedium">{war.warType ?? t('generalUnknown')}</CKText>
                  </PillSurface>
                </View>
              </View>
              <RoundButton label={t('generalCancel')} onPress={onClose}>
                <X size={20} color={theme.onSurface} />
              </RoundButton>
            </View>
            <View style={styles.resultHero}>
              <CKText role="heroMetric">
                {'★'.repeat(attack.stars)}
                {'☆'.repeat(3 - attack.stars)}
              </CKText>
              <CKText role="titleLarge">{formatPercent(attack.destructionPercentage)}</CKText>
            </View>
            <Participant
              title={t('warAttacksDetailsAttacker')}
              member={attacker}
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
              onPress={() => onOpenPlayer(attack.defenderTag)}
            />
            <Surface muted style={styles.detailsPanel}>
              <DetailRow label={t('warStarsTitle')} value={String(attack.stars)} />
              <DetailRow
                label={t('warDestructionTitle')}
                value={formatPercent(attack.destructionPercentage)}
              />
              <DetailRow label={t('warAttacksDetailsAttackOrder')} value={`#${attack.order}`} />
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

function WarSide({ clan }: { clan: WarInfo['clan'] }) {
  return (
    <View style={styles.warSide}>
      <MobileWebImage
        imageUrl={clan?.badgeUrls.smallest || ImageAssets.clanCastle}
        style={styles.warBadge}
      />
      <CKText role="labelMedium" numberOfLines={1}>
        {clan?.name ?? '—'}
      </CKText>
    </View>
  );
}

function WarScoreRow({ left, right }: { left: number; right: number }) {
  return (
    <View style={styles.scoreRow}>
      <CKText
        testID="war-summary-score"
        role="titleMedium"
        numberOfLines={1}
        adjustsFontSizeToFit
        minimumFontScale={0.75}
        style={styles.scoreValue}
      >
        {left} - {right}
      </CKText>
    </View>
  );
}

function WarDestructionRow({ left, right }: { left: number; right: number }) {
  return (
    <View style={styles.destructionRow}>
      <CKText muted role="labelSmall" style={styles.destructionValue}>
        {formatPercent(left)}
      </CKText>
      <CKText muted role="labelSmall" style={styles.destructionValue}>
        {formatPercent(right)}
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
          style={{ width: 72, height: 72, flex: 1 }}
        />
        <View style={{ alignItems: 'center', flex: 1 }}>
          <CKText role="screenTitle" style={{ color: foreground, fontVariant: ['tabular-nums'] }}>
            {war.state === 'preparation'
              ? '—'
              : `${war.clan?.stars ?? 0} – ${war.opponent?.stars ?? 0}`}
          </CKText>
          <CKText role="body" style={{ color: secondary }}>
            {t('warStarsTitle')}
          </CKText>
        </View>
        <MobileWebImage
          imageUrl={war.opponent?.badgeUrls.smallest || ImageAssets.clanCastle}
          style={{ width: 72, height: 72, flex: 1 }}
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
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
          <CKText role="body" style={{ flex: 1, color: foreground, textAlign: 'center' }}>
            {formatPercent(war.clan?.destructionPercentage ?? 0)}
          </CKText>
          <CKText role="body" style={{ color: secondary }}>
            {t('warDestructionTitle')}
          </CKText>
          <CKText role="body" style={{ flex: 1, color: foreground, textAlign: 'center' }}>
            {formatPercent(war.opponent?.destructionPercentage ?? 0)}
          </CKText>
        </View>
      ) : null}
      {!hero && war.state !== 'preparation' ? (
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
          <CKText role="body" style={{ flex: 1, color: secondary, textAlign: 'center' }}>
            {war.clan?.attacks ?? 0}/{capacity}
          </CKText>
          <CKText role="body" style={{ color: secondary }}>
            {t('warAttacksTitle')}
          </CKText>
          <CKText role="body" style={{ flex: 1, color: secondary, textAlign: 'center' }}>
            {war.opponent?.attacks ?? 0}/{capacity}
          </CKText>
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
  onPress,
}: {
  title: string;
  member: Pick<WarMember, 'tag' | 'name' | 'townhallLevel' | 'mapPosition'> | null;
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
  warBody: { minHeight: 124, flexDirection: 'row', alignItems: 'center', padding: 8 },
  preparationWarBody: { minHeight: 112 },
  warSide: { flex: 3, alignItems: 'center', gap: 3 },
  warBadge: { width: 70, height: 70, resizeMode: 'contain' },
  scoreColumn: { flex: 4, alignItems: 'center', justifyContent: 'center', gap: 5 },
  stateLabel: { textAlign: 'center', fontWeight: '700', flexShrink: 1, lineHeight: 18 },
  resultLabel: { fontWeight: '800' },
  scoreRow: { width: '100%', alignItems: 'center', justifyContent: 'center' },
  scoreValue: {
    width: '100%',
    paddingHorizontal: 2,
    fontSize: 24,
    lineHeight: 28,
    fontWeight: '800',
    textAlign: 'center',
  },
  destructionRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 12 },
  destructionValue: { width: 56, textAlign: 'center' },
  statusPill: {
    minHeight: 26,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 8,
  },
  attackStatusWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingBottom: 10,
  },
  attackStatus: {
    minHeight: 26,
    borderRadius: 999,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 9,
  },
  hero: { overflow: 'hidden', paddingBottom: 24, gap: 16 },
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
