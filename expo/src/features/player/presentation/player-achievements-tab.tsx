import { useEffect, useState, useSyncExternalStore } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Star } from 'lucide-react-native';
import Reanimated, { useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';
import { materialBackLabel, toIntlLocale, useI18n } from '../../../i18n';
import { ImageAssets } from '../../../core/assets/image-assets';
import {
  localizedNameForItem,
  translationForTid,
} from '../../../core/game-data/game-data-localization';
import {
  gameDataState,
  subscribeToGameDataRevision,
} from '../../../core/game-data/game-data-state';
import {
  CKText,
  EmptyState,
  MobileWebImage,
  ResponsiveGrid,
  Surface,
  ckColors,
  ckRadius,
  statColors,
  useCKTheme,
  useCKAccessibility,
} from '../../../ui';
import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { ProgressRing } from '../../home/presentation/home-components';
import type { Player } from '../models';
import type { PlayerAchievement } from '../models/player-support';
import {
  achievementGemTotals,
  achievementMetadata,
  achievementStarCount,
  achievementTierTarget,
} from './player-achievement-metadata';

const GEM_IMAGE = `${ImageAssets.baseUrl}/resources/gems.webp`;

export function PlayerAchievementsTab({ player }: { player: Player }) {
  const { t, locale } = useI18n();
  const layout = useAdaptiveLayout();
  useSyncExternalStore(
    subscribeToGameDataRevision,
    () => gameDataState.revision,
    () => 0,
  );
  const items = player.achievements
    .filter((item) => item.name !== 'Keep Your Account Safe!')
    .map((item) => ({ item, metadata: achievementMetadata(item) }));
  const gemTotals = achievementGemTotals(player.achievements);
  const gemNumber = new Intl.NumberFormat(toIntlLocale(locale));
  const earnedGems =
    gemTotals.earned === null ? t('generalUnknown') : gemNumber.format(gemTotals.earned);
  const possibleGems =
    gemTotals.possible === null ? t('generalUnknown') : gemNumber.format(gemTotals.possible);
  const sections = [
    { key: 'home', title: t('gameBaseHome'), image: ImageAssets.townHall(player.townHallLevel) },
    {
      key: 'builderBase',
      title: t('gameBaseBuilder'),
      image: ImageAssets.builderHall(player.builderHallLevel),
    },
    { key: 'clanCapital', title: t('gameClanCapital'), image: ImageAssets.capitalGold },
    { key: 'other', title: t('generalOthers'), image: ImageAssets.attackStar },
  ];
  const firstSection = sections.find((section) =>
    items.some(({ item, metadata }) => {
      const village = metadata?.village || item.village;
      return section.key === 'other'
        ? !['home', 'builderBase', 'clanCapital'].includes(village)
        : village === section.key;
    }),
  )?.key;
  return (
    <View style={[styles.page, layout.isExpanded && { maxWidth: layout.contentMaxWidth }]}>
      {sections.map((section) => {
        const rows = items
          .filter(({ item, metadata }) => {
            const village = metadata?.village || item.village;
            return section.key === 'other'
              ? !['home', 'builderBase', 'clanCapital'].includes(village)
              : village === section.key;
          })
          .sort(
            (a, b) =>
              Number(achievementStarCount(a.item, a.metadata).completed) -
              Number(achievementStarCount(b.item, b.metadata).completed),
          );
        if (!rows.length) return null;
        const completed = rows.filter(
          ({ item, metadata }) => achievementStarCount(item, metadata).completed,
        ).length;
        return (
          <View
            key={section.key}
            style={styles.section}
            testID={`player-achievements-${section.key}`}
          >
            <View style={styles.sectionHeader}>
              <MobileWebImage
                imageUrl={section.image}
                style={styles.sectionImage}
                contentFit="contain"
              />
              <View style={styles.grow}>
                <View style={styles.sectionTitleRow}>
                  <CKText role="sectionTitle" testID={`player-achievements-title-${section.key}`}>
                    {section.title}
                  </CKText>
                  {section.key === firstSection ? (
                    <View
                      style={styles.gemSummary}
                      testID="player-achievements-gems-total"
                      accessible
                      accessibilityLabel={t('achievementGemsAccessibility', {
                        earned: earnedGems,
                        total: possibleGems,
                      })}
                    >
                      <MobileWebImage
                        imageUrl={GEM_IMAGE}
                        style={styles.summaryGem}
                        contentFit="contain"
                      />
                      <CKText muted role="metadata" style={styles.summaryCopy}>
                        {t('achievementGemsEarnedRatio', {
                          earned: earnedGems,
                          total: possibleGems,
                        })}
                      </CKText>
                    </View>
                  ) : null}
                </View>
                <CKText muted role="metadata">
                  {t('achievementSummary', { earned: completed, total: rows.length })}
                </CKText>
              </View>
            </View>
            <ResponsiveGrid minItemWidth={380} maxColumns={layout.isExpanded ? 2 : 1} gap={12}>
              {rows.map(({ item, metadata }) => (
                <AchievementCard key={item.name} item={item} metadata={metadata} />
              ))}
            </ResponsiveGrid>
          </View>
        );
      })}
      {!items.length ? <EmptyState title={t('generalNoDataAvailable')} /> : null}
    </View>
  );
}

function AchievementCard({
  item,
  metadata,
}: {
  item: PlayerAchievement;
  metadata: ReturnType<typeof achievementMetadata>;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const [flipped, setFlipped] = useState(false);
  const [sizes, setSizes] = useState({ front: 0, back: 0 });
  const progress = useSharedValue(0);
  useEffect(() => {
    progress.value = reduceMotion
      ? Number(flipped)
      : withSpring(Number(flipped), { duration: 340, dampingRatio: 1 });
  }, [flipped, progress, reduceMotion]);
  const frontStyle = useAnimatedStyle(() => ({
    opacity: progress.value < 0.5 ? 1 : 0,
    transform: [{ perspective: 1200 }, { rotateY: `${progress.value * 180}deg` }],
  }));
  const backStyle = useAnimatedStyle(() => ({
    opacity: progress.value >= 0.5 ? 1 : 0,
    transform: [{ perspective: 1200 }, { rotateY: `${(progress.value - 1) * 180}deg` }],
  }));
  const measure = (side: 'front' | 'back', height: number) => {
    const next = Math.ceil(height + 32);
    setSizes((current) => (current[side] === next ? current : { ...current, [side]: next }));
  };
  // Measure each face independently so long translations and larger text fit.
  // Follow the flip progress to avoid reserving the taller back on the front.
  const sizeStyle = useAnimatedStyle(() => {
    if (!sizes.front) return {};
    const backHeight = sizes.back || sizes.front;
    const position = Math.max(0, Math.min(1, progress.value));
    return { height: sizes.front + (backHeight - sizes.front) * position };
  });
  const number = new Intl.NumberFormat(toIntlLocale(locale));
  const status = achievementStarCount(item, metadata);
  const title = metadata ? localizedNameForItem(metadata.raw) || item.name : item.name;
  const percent =
    item.target > 0 ? Math.min(100, Math.max(0, (item.value / item.target) * 100)) : 0;
  const gems = translationForTid('TID_DIAMONDS') ?? 'Gems';
  const hasTiers = !!metadata?.tiers.length;
  const frontLabel = [
    title,
    item.info,
    `${status.earned} / ${status.maximum}`,
    `${number.format(item.value)} / ${number.format(item.target)}`,
    `${Math.round(percent)}%`,
    status.completed ? t('generalCompleted') : null,
  ]
    .filter(Boolean)
    .join(', ');
  const backLabel = metadata?.tiers
    .map((tier) =>
      [
        `${t('upgradeTrackerTier')} ${tier.level}`,
        `${t('calcTarget')} ${achievementTierTarget(tier, metadata, toIntlLocale(locale))}`,
        `${t('capitalRaidRewards')} ${tier.gems === null ? '—' : `${number.format(tier.gems)} ${gems}`}`,
      ].join(', '),
    )
    .join('. ');
  return (
    <Reanimated.View style={sizeStyle}>
      <Reanimated.View
        style={[styles.face, !sizes.front && styles.initialFace, frontStyle]}
        pointerEvents={flipped ? 'none' : 'auto'}
        accessibilityElementsHidden={flipped}
        importantForAccessibility={flipped ? 'no-hide-descendants' : 'auto'}
      >
        <Pressable
          disabled={!hasTiers}
          accessible={hasTiers}
          accessibilityRole={hasTiers ? 'button' : undefined}
          accessibilityLabel={hasTiers ? frontLabel : undefined}
          accessibilityHint={hasTiers ? t('generalDetails') : undefined}
          accessibilityState={hasTiers ? { expanded: false } : undefined}
          onPress={() => setFlipped(true)}
        >
          <Surface
            style={styles.card}
            radius={ckRadius.tile}
            accessibilityElementsHidden={hasTiers}
            importantForAccessibility={hasTiers ? 'no-hide-descendants' : 'auto'}
          >
            <View
              style={styles.cardContent}
              onLayout={(event) => measure('front', event.nativeEvent.layout.height)}
            >
              <View style={styles.frontRow}>
                <View style={styles.frontDetails}>
                  <CKText role="titleSmall">{title}</CKText>
                  <View
                    style={styles.stars}
                    accessible
                    accessibilityLabel={`${status.earned} / ${status.maximum}`}
                  >
                    {Array.from({ length: status.maximum }, (_, index) => (
                      <Star
                        key={index}
                        size={16}
                        color={index < status.earned ? ckColors.warGold : theme.outlineVariant}
                        fill={index < status.earned ? ckColors.warGold : 'transparent'}
                      />
                    ))}
                  </View>
                  {item.info ? (
                    <CKText muted role="body">
                      {item.info}
                    </CKText>
                  ) : null}
                  <CKText role="rowTitle">
                    {number.format(item.value)} / {number.format(item.target)}
                  </CKText>
                </View>
                <ProgressRing
                  progress={percent / 100}
                  size={64}
                  labelFontSize={16}
                  color={status.completed ? statColors.win : theme.primary}
                />
              </View>
            </View>
          </Surface>
        </Pressable>
      </Reanimated.View>
      {metadata && hasTiers ? (
        <Reanimated.View
          style={[styles.face, backStyle]}
          pointerEvents={flipped ? 'auto' : 'none'}
          accessibilityElementsHidden={!flipped}
          importantForAccessibility={!flipped ? 'no-hide-descendants' : 'auto'}
        >
          <Pressable
            accessibilityRole="button"
            accessibilityLabel={`${title}. ${backLabel}`}
            accessibilityHint={materialBackLabel(locale)}
            accessibilityState={{ expanded: true }}
            onPress={() => setFlipped(false)}
          >
            <Surface
              style={styles.card}
              radius={ckRadius.tile}
              accessibilityElementsHidden
              importantForAccessibility="no-hide-descendants"
            >
              <View
                style={styles.cardContent}
                onLayout={(event) => measure('back', event.nativeEvent.layout.height)}
              >
                <CKText role="titleSmall">{title}</CKText>
                <View style={styles.tiers}>
                  <View style={styles.tierRow}>
                    <CKText muted role="metadata" style={styles.tierNumber}>
                      {t('upgradeTrackerTier')}
                    </CKText>
                    <CKText muted role="metadata" style={styles.grow}>
                      {t('calcTarget')}
                    </CKText>
                    <CKText muted role="metadata">
                      {t('capitalRaidRewards')}
                    </CKText>
                  </View>
                  {metadata.tiers.map((tier) => (
                    <View key={tier.level} style={styles.tierRow}>
                      <View style={styles.tierNumber}>
                        <Star
                          size={15}
                          color={
                            tier.level <= status.earned ? ckColors.warGold : theme.onSurfaceVariant
                          }
                          fill={tier.level <= status.earned ? ckColors.warGold : 'transparent'}
                        />
                        <CKText role="metadata">{tier.level}</CKText>
                      </View>
                      <CKText role="metadata" style={styles.grow}>
                        {achievementTierTarget(tier, metadata, toIntlLocale(locale))}
                      </CKText>
                      {tier.gems !== null ? (
                        <View
                          style={styles.reward}
                          accessible
                          accessibilityLabel={`${number.format(tier.gems)} ${gems}`}
                        >
                          <MobileWebImage
                            imageUrl={GEM_IMAGE}
                            style={styles.gem}
                            contentFit="contain"
                          />
                          <CKText role="rowTitle">{number.format(tier.gems)}</CKText>
                        </View>
                      ) : (
                        <CKText muted>—</CKText>
                      )}
                    </View>
                  ))}
                </View>
              </View>
            </Surface>
          </Pressable>
        </Reanimated.View>
      ) : null}
    </Reanimated.View>
  );
}

const styles = StyleSheet.create({
  page: { gap: 28, padding: 12, width: '100%', alignSelf: 'center' },
  section: { gap: 12 },
  gemSummary: {
    alignSelf: 'center',
    marginLeft: 'auto',
    maxWidth: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  summaryGem: { width: 18, height: 18 },
  summaryCopy: { flexShrink: 1, textAlign: 'right' },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 4,
  },
  // Align supporting metadata with the title, not the separate completion line.
  sectionTitleRow: { flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 8 },
  sectionImage: { width: 44, height: 44 },
  card: { padding: 16, borderWidth: 0 },
  cardContent: { gap: 12 },
  initialFace: { position: 'relative' },
  face: { position: 'absolute', top: 0, left: 0, right: 0, backfaceVisibility: 'hidden' },
  grow: { flex: 1, minWidth: 0 },
  frontRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  frontDetails: { flex: 1, minWidth: 0, gap: 6 },
  stars: { flexDirection: 'row', flexWrap: 'wrap', gap: 3 },
  tiers: { gap: 6 },
  tierRow: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  tierNumber: { width: 52, flexDirection: 'row', alignItems: 'center', gap: 4 },
  reward: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  gem: { width: 18, height: 18 },
});
