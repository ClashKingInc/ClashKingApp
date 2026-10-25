import { useEffect, useState } from 'react';
import { HeaderArtwork } from '../../../ui/header-artwork';
import { Animated, Pressable, StyleSheet, View } from 'react-native';
import { ArrowLeft } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { HeroHeaderScrim } from '../../../ui/hero-header-scrim';
import { ImageAssets } from '../../../core/assets/image-assets';
import { materialBackLabel, useI18n } from '../../../i18n';
import { CKText, MobileWebImage, PillSurface, SkeletonContent, useCKTheme } from '../../../ui';
import { HeaderIconButton } from '../../../ui/header';
import { useCKAccessibility } from '../../../ui/accessibility';
import type { WarInfo } from '../models';
import { formatPercent, relativeWarTime, warTimeRemaining } from './presentation-utils';

export function WarBattleHeader({
  loading = false,
  war,
  cwlRoundNumber,
  onBack,
  onOpenClan,
  onOpenCwl,
}: {
  war: WarInfo;
  loading?: boolean;
  cwlRoundNumber?: number | null;
  onBack: () => void;
  onOpenClan: (tag: string) => void;
  onOpenCwl?: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const insets = useSafeAreaInsets();
  const { reduceMotion } = useCKAccessibility();
  const [settle] = useState(() => new Animated.Value(1));
  const [flagsHeight, setFlagsHeight] = useState(0);
  useEffect(() => {
    if (reduceMotion) {
      settle.setValue(1);
      return;
    }
    // A short settling response acknowledges new scores, not a perpetual
    // decorative loop that competes with the numbers people are reading.
    settle.setValue(0.985);
    const motion = Animated.spring(settle, {
      toValue: 1,
      damping: 26,
      stiffness: 260,
      mass: 0.6,
      useNativeDriver: true,
    });
    motion.start();
    return () => motion.stop();
  }, [
    settle,
    reduceMotion,
    war.clan?.stars,
    war.opponent?.stars,
    war.clan?.attacks,
    war.opponent?.attacks,
  ]);
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 30000);
    return () => clearInterval(timer);
  }, []);
  const ended = war.state === 'warEnded';
  const preparation = ['preparation', 'preparationDay'].includes(war.state);
  const target = preparation ? war.startTime : war.endTime;
  const time =
    ended && war.endTime
      ? relativeWarTime(war.endTime, now, t)
      : target
        ? t(preparation ? 'timeStartsIn' : 'timeEndsIn', {
            time: warTimeRemaining(target, now, locale),
          })
        : '';
  const modifier = war.battleModifier?.trim();
  const showModifier =
    !!modifier && !['none', 'normal', 'default'].includes(modifier.toLowerCase());
  const showCwl = war.isClanWarLeague || !!cwlRoundNumber;
  const hasFlags = showCwl || war.warType === 'friendly' || showModifier;
  const tiedStars = war.clan?.stars === war.opponent?.stars;
  const attackCapacity = war.teamSize == null ? null : war.teamSize * war.effectiveAttacksPerMember;
  return (
    <View
      testID="war-battle-header"
      style={[styles.header, { paddingTop: insets.top + 4, backgroundColor: theme.background }]}
    >
      {/* Mount artwork on the first render. Waiting for onLayout left this
          region black while native layout and the roster finished loading. */}
      <View pointerEvents="none" style={StyleSheet.absoluteFill}>
        <HeaderArtwork
          testID="war-header-artwork"
          source={require('../../../../assets/clashking/war/war-wood-header.webp')}
          style={StyleSheet.absoluteFill}
          contentFit="cover"
        />
        <HeroHeaderScrim variant="war" />
      </View>
      <View style={styles.navigation}>
        <HeaderIconButton
          icon={<ArrowLeft size={24} color="#fff" />}
          label={materialBackLabel(locale)}
          onPress={onBack}
          glass={false}
        />
        <SkeletonContent loading={loading} style={styles.timeSlot}>
          {time ? (
            <View style={styles.timeChip}>
              <CKText role="metadata" style={styles.time}>
                {time}
              </CKText>
            </View>
          ) : null}
        </SkeletonContent>
        <View style={{ width: 44 }} />
      </View>
      <SkeletonContent loading={loading} style={styles.content}>
        <Animated.View style={{ gap: 4, paddingTop: 2, transform: [{ scale: settle }] }}>
          <View style={[styles.badgeRow, { minHeight: Math.max(54, hasFlags ? flagsHeight : 0) }]}>
            <Pressable
              onPress={() => war.clan && onOpenClan(war.clan.tag)}
              accessibilityRole="button"
              accessibilityLabel={war.clan?.name}
              style={styles.identity}
            >
              <MobileWebImage
                imageUrl={war.clan?.badgeUrls.smallest ?? ImageAssets.clanCastle}
                style={styles.badge}
              />
            </Pressable>
            {hasFlags ? (
              <View
                onLayout={({ nativeEvent: { layout } }) =>
                  setFlagsHeight((old) => (old === layout.height ? old : layout.height))
                }
                style={[styles.flags, { transform: [{ translateY: -flagsHeight / 2 }] }]}
              >
                {showCwl ? (
                  <Pressable
                    disabled={!onOpenCwl}
                    onPress={onOpenCwl}
                    accessibilityRole={onOpenCwl ? 'button' : undefined}
                    style={styles.flag}
                  >
                    <MobileWebImage
                      imageUrl={ImageAssets.cwlSwordsNoBorder}
                      style={styles.flagIcon}
                    />
                    <CKText role="metadata" style={styles.flagText}>
                      {cwlRoundNumber
                        ? t('cwlRoundNumber', { number: cwlRoundNumber })
                        : t('cwlTitle')}
                    </CKText>
                  </Pressable>
                ) : null}
                {war.warType === 'friendly' ? (
                  <View style={styles.flag}>
                    <CKText role="metadata" style={styles.flagText}>
                      {t('warFiltersFriendly')}
                    </CKText>
                  </View>
                ) : null}
                {showModifier ? (
                  <View
                    style={styles.flag}
                    accessible
                    accessibilityLabel={`${t('calcBattleModifier')}: ${modifier}`}
                  >
                    <CKText role="metadata" style={styles.flagText}>
                      {modifier}
                    </CKText>
                  </View>
                ) : null}
              </View>
            ) : null}
            <Pressable
              onPress={() => war.opponent && onOpenClan(war.opponent.tag)}
              accessibilityRole="button"
              accessibilityLabel={war.opponent?.name}
              style={styles.identity}
            >
              <MobileWebImage
                imageUrl={war.opponent?.badgeUrls.smallest ?? ImageAssets.clanCastle}
                style={styles.badge}
              />
            </Pressable>
          </View>
          <View style={styles.match}>
            {(['clan', 'opponent'] as const).map((side) => (
              <Pressable
                key={side}
                onPress={() => war[side] && onOpenClan(war[side]!.tag)}
                accessibilityRole="button"
                accessibilityLabel={war[side]?.name}
                style={[styles.identity, { gap: 4 }]}
              >
                <CKText role="rowTitle" style={styles.name}>
                  {war[side]?.name}
                </CKText>
              </Pressable>
            ))}
          </View>
          <View style={styles.scoreRow}>
            {(['clan', 'opponent'] as const).map((side) => (
              <View key={side} style={styles.scoreGroup}>
                <CKText testID={`war-header-score-${side}`} role="heroMetric" style={styles.score}>
                  {preparation ? '—' : (war[side]?.stars ?? 0)}
                </CKText>
                {/* One non-wrapping chip row belongs to this clan's score.
                    Keep both metrics aligned even when their digits differ. */}
                <View style={styles.statChips}>
                  <PillSurface
                    style={styles.statChip}
                    accessible
                    accessibilityLabel={`${war[side]?.name}: ${t('warAttacksTitle')} ${war[side]?.attacks ?? 0}/${attackCapacity ?? '—'}`}
                  >
                    <MobileWebImage
                      imageUrl={ImageAssets.sword}
                      style={{ width: 13, height: 13 }}
                    />
                    <CKText
                      role="metadata"
                      numberOfLines={1}
                      adjustsFontSizeToFit
                      style={styles.chipText}
                    >
                      {war[side]?.attacks ?? 0}/{attackCapacity ?? '—'}
                    </CKText>
                  </PillSurface>
                  {!preparation ? (
                    <PillSurface style={styles.statChip}>
                      <CKText
                        role="metadata"
                        numberOfLines={1}
                        adjustsFontSizeToFit
                        style={[styles.chipText, tiedStars && styles.tiedPercentage]}
                      >
                        {formatPercent(war[side]?.destructionPercentage ?? 0)}
                      </CKText>
                    </PillSurface>
                  ) : null}
                </View>
              </View>
            ))}
            <CKText style={styles.dash}>—</CKText>
          </View>
        </Animated.View>
      </SkeletonContent>
      {/* Cover the final physical pixels independently of SVG rasterization.
          Red artwork must not peek through the native scroll/header seam. */}
      <View
        pointerEvents="none"
        style={{
          position: 'absolute',
          bottom: -1,
          left: -1,
          right: -1,
          height: 4,
          backgroundColor: theme.background,
        }}
      />
    </View>
  );
}
const styles = StyleSheet.create({
  header: { overflow: 'hidden', paddingBottom: 14, flexShrink: 0 },
  navigation: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 8 },
  timeSlot: { flex: 1, alignItems: 'center' },
  timeChip: {
    maxWidth: '100%',
    backgroundColor: '#00000099',
    borderRadius: 16,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  time: { color: '#F2EAE4', textAlign: 'center', fontSize: 12.6, lineHeight: 17 },
  content: { width: '100%', maxWidth: 640, alignSelf: 'center', paddingHorizontal: 24 },
  match: { flexDirection: 'row', gap: 28, paddingTop: 4 },
  badgeRow: { flexDirection: 'row', alignItems: 'center', gap: 28 },
  scoreRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 28 },
  scoreGroup: {
    flex: 1,
    minWidth: 0,
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 5,
  },
  tiedPercentage: { color: '#FFFFFF', fontWeight: '700' },
  dash: {
    position: 'absolute',
    left: '50%',
    marginLeft: -14,
    width: 28,
    textAlign: 'center',
    fontSize: 28,
    lineHeight: 42,
    color: '#E5DBD0',
  },
  identity: { flex: 1, minWidth: 0, alignItems: 'center', gap: 5 },
  badge: { width: 54, height: 54 },
  name: { color: '#fff', textAlign: 'center', minHeight: 18, fontSize: 15, lineHeight: 18 },
  metric: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  score: {
    color: '#fff',
    fontSize: 36,
    lineHeight: 42,
    fontWeight: '600',
    fontVariant: ['tabular-nums'],
  },
  statChips: {
    flexDirection: 'row',
    flexWrap: 'nowrap',
    alignItems: 'center',
    justifyContent: 'center',
    width: '100%',
    gap: 4,
  },
  statChip: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 1,
    minWidth: 0,
    gap: 3,
    borderWidth: 0,
    backgroundColor: '#00000070',
    paddingHorizontal: 6,
    paddingVertical: 5,
  },
  chipText: {
    color: '#DFDBD7',
    fontSize: 11,
    lineHeight: 14,
    flexShrink: 1,
    fontVariant: ['tabular-nums'],
  },
  flags: {
    position: 'absolute',
    top: '50%',
    left: '50%',
    marginLeft: -56,
    width: 112,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 4,
  },
  flag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    maxWidth: '100%',
    backgroundColor: '#00000080',
    paddingHorizontal: 6,
    paddingVertical: 4,
    borderRadius: 16,
  },
  flagIcon: { width: 14, height: 14 },
  flagText: { color: '#FFFFFF', fontSize: 10, lineHeight: 13, textAlign: 'center', flexShrink: 1 },
});
