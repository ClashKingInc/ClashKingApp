import { useEffect, useState } from 'react';
import { Animated, Pressable, StyleSheet, View } from 'react-native';
import { useCKAccessibility } from '../../../ui/accessibility';
import { ChevronDown, ChevronRight } from 'lucide-react-native';
import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  InfoTooltip,
  MobileWebImage,
  SkeletonContent,
  Surface,
  ckRadius,
  colorWithAlpha,
  statColors,
  useCKTheme,
} from '../../../ui';
import { RankedLeagueBattle } from '../../player/models';
import type { RankedPeriod } from '../data';
import { LegendArmy } from '../../legends/presentation/legend-army-presentation';
import { relativeWarTime } from '../../war/presentation/presentation-utils';

export function RankedBattles({
  period,
  onOpenOpponent,
  loading,
  error,
  onRetry,
}: {
  period: RankedPeriod;
  onOpenOpponent: (tag: string) => Promise<void>;
  loading?: boolean;
  error?: string;
  onRetry: () => void;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [direction, setDirection] = useState<'attacks' | 'defenses'>('attacks');
  const attacks = direction === 'attacks';
  const battles = attacks ? period.attacks : period.defenses;
  const real = battles
    .filter((battle) => !battle.automatic)
    .sort((a, b) => (b.creationTime?.getTime() ?? 0) - (a.creationTime?.getTime() ?? 0));
  // Archived records can share time/opponent or omit both. Keep each occurrence,
  // while preserving known row identities when a newer battle is prepended.
  const occurrences = new Map<string, number>();
  const rows = real.map((battle) => {
    const identity = `${period.seasonId}:${direction}:${battle.creationTime?.getTime() ?? 0}:${battle.opponentPlayerTag}`;
    const occurrence = occurrences.get(identity) ?? 0;
    occurrences.set(identity, occurrence + 1);
    return { battle, key: `${identity}:${occurrence}` };
  });
  const automatic = battles.filter((battle) => battle.automatic);
  const waiting = Boolean(loading && !real.length);
  const { reduceMotion } = useCKAccessibility();
  const placeholderRequestKey = `${period.seasonId}:${direction}`;
  const [placeholderKey, setPlaceholderKey] = useState<string>();
  const showPlaceholder = waiting && placeholderKey === placeholderRequestKey;
  const [contentOpacity] = useState(() => new Animated.Value(reduceMotion ? 1 : 0));
  useEffect(() => {
    if (!waiting) return;
    // Avoid a one-frame skeleton flash for cached/fast responses. Data never
    // waits for this timer; only a genuinely pending request reveals skeletons.
    const timer = setTimeout(() => setPlaceholderKey(placeholderRequestKey), 120);
    return () => clearTimeout(timer);
  }, [waiting, placeholderRequestKey]);
  useEffect(() => {
    const visible = !waiting || showPlaceholder;
    if (reduceMotion) {
      contentOpacity.setValue(visible ? 1 : 0);
      return;
    }
    const animation = Animated.timing(contentOpacity, {
      toValue: visible ? 1 : 0,
      duration: 150,
      useNativeDriver: true,
    });
    animation.start();
    return () => animation.stop();
  }, [contentOpacity, reduceMotion, waiting, showPlaceholder]);
  const complete = attacks ? period.attacksComplete : period.defensesComplete;
  const max = attacks ? period.attackMaxBattles : period.defenseMaxBattles;
  const count = (attacks ? period.attackCount : period.defenseCount) + automatic.length;
  const remaining = max > 0 ? Math.max(0, max - count) : null;
  const average =
    battles.length > 0 && complete
      ? battles.reduce((sum, battle) => sum + battle.trophies, 0) / battles.length
      : null;
  const signed = (value: number) =>
    new Intl.NumberFormat(toIntlLocale(locale), {
      maximumFractionDigits: 1,
      signDisplay: 'exceptZero',
    }).format(value);
  return (
    <View style={styles.section}>
      <View accessibilityRole="tablist" style={styles.selectors}>
        {(['attacks', 'defenses'] as const).map((key) => {
          const selected = direction === key;
          const list = key === 'attacks' ? period.attacks : period.defenses;
          const registered = key === 'attacks' ? period.attackCount : period.defenseCount;
          const used = registered + list.filter((battle) => battle.automatic).length;
          const limit = key === 'attacks' ? period.attackMaxBattles : period.defenseMaxBattles;
          const known = key === 'attacks' ? period.attacksComplete : period.defensesComplete;
          const total = list.reduce((sum, battle) => sum + battle.trophies, 0);
          const label = t(key === 'attacks' ? 'rankedLeagueAttacks' : 'rankedLeagueDefenses');
          return (
            <Pressable
              key={key}
              accessibilityRole="tab"
              accessibilityState={{ selected }}
              onPress={() => setDirection(key)}
              style={[
                styles.selector,
                {
                  backgroundColor: selected ? colorWithAlpha(theme.primary, 0.13) : theme.card,
                  borderBottomColor: selected ? theme.primary : 'transparent',
                },
              ]}
            >
              <View style={styles.inline}>
                <MobileWebImage
                  imageUrl={key === 'attacks' ? ImageAssets.sword : ImageAssets.shieldWithArrow}
                  style={styles.icon}
                />
                <CKText role="rowTitle">{label}</CKText>
              </View>
              <View style={styles.summaryNumbers}>
                <CKText role="titleLarge">
                  {used}
                  <CKText muted role="metadata">
                    {limit > 0 ? ` / ${limit}` : ''}
                  </CKText>
                </CKText>
                <View style={styles.inline}>
                  <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.smallIcon} />
                  <CKText
                    role="rowTitle"
                    style={{ color: total < 0 ? statColors.loss : statColors.win }}
                  >
                    {known && list.length ? signed(total) : '—'}
                  </CKText>
                </View>
              </View>
            </Pressable>
          );
        })}
      </View>
      <View style={styles.summaryStrip}>
        <View style={styles.inline}>
          <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.smallIcon} />
          <CKText role="metadata" muted>
            {t('rankedLeagueAverage')}
          </CKText>
          <CKText role="rowTitle">{average === null ? '—' : signed(average)}</CKText>
        </View>
        {period.isCurrent && remaining !== null ? (
          <CKText role="metadata" muted>
            {t('rankedLeagueRemaining')}: {remaining}
          </CKText>
        ) : null}
      </View>
      <Animated.View style={[styles.section, { opacity: contentOpacity }]}>
        {waiting ? (
          <View style={{ minHeight: 300 }} accessibilityState={{ busy: true }}>
            {showPlaceholder ? (
              <SkeletonContent loading style={styles.section}>
                {[0, 1, 2].map((index) => (
                  <RankedBattleRow
                    key={index}
                    battle={new RankedLeagueBattle('', 'Opponent player', 3, 100, 40, new Date(0))}
                    onOpenOpponent={onOpenOpponent}
                  />
                ))}
              </SkeletonContent>
            ) : null}
          </View>
        ) : error ? (
          <EmptyState title={error} actionLabel={t('sideRefresh')} onAction={onRetry} />
        ) : (
          <>
            {!complete && period.hasDetails ? (
              <CKText role="metadata" muted>
                {t('rankedLeagueBattleDetailsUnavailable')}
              </CKText>
            ) : null}
            {rows.map(({ battle, key }) => (
              <RankedBattleRow key={key} battle={battle} onOpenOpponent={onOpenOpponent} />
            ))}
            {automatic.map((battle, index) => (
              <Surface
                key={`automatic:${period.seasonId}:${index}`}
                radius={ckRadius.tile}
                testID={`ranked-automatic-defense-${index}`}
                style={[
                  styles.battle,
                  styles.automatic,
                  { borderColor: colorWithAlpha(theme.outlineVariant, 0.5) },
                ]}
              >
                <View style={styles.battleBody}>
                  <View style={styles.battleTop}>
                    <MobileWebImage
                      imageUrl={ImageAssets.shieldWithArrow}
                      style={styles.townHall}
                    />
                    <View style={styles.grow}>
                      <CKText role="rowTitle">{t('legendsAutomaticDefense')}</CKText>
                    </View>
                    <View style={styles.result}>
                      <CKText
                        role="titleSmall"
                        style={{
                          color: battle.trophies < 0 ? statColors.loss : statColors.win,
                        }}
                      >
                        {signed(battle.trophies)}
                      </CKText>
                      <View style={styles.inline}>
                        <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.smallIcon} />
                        <InfoTooltip
                          label={t('legendsAutomaticDefense')}
                          message={t('rankedAutomaticDefenseExplanation')}
                          triggerStyle={{ width: 24, height: 24 }}
                        />
                      </View>
                    </View>
                  </View>
                </View>
              </Surface>
            ))}
            {!period.hasDetails || (!real.length && !automatic.length) ? (
              <EmptyState
                title={t(
                  period.hasDetails
                    ? 'rankedLeagueNoBattles'
                    : 'rankedLeagueBattleDetailsUnavailable',
                )}
              />
            ) : null}
          </>
        )}
      </Animated.View>
    </View>
  );
}

function RankedBattleRow({
  battle,
  onOpenOpponent,
}: {
  battle: RankedLeagueBattle;
  onOpenOpponent: (tag: string) => Promise<void>;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState(false);
  const hasArmy = Boolean(battle.shareCode);
  const name = battle.opponentName || battle.opponentPlayerTag || t('generalUnknown');
  const date = battle.creationTime ? relativeWarTime(battle.creationTime, new Date(), t) : null;
  return (
    <Surface radius={ckRadius.tile} style={styles.battle}>
      <Pressable
        accessibilityRole={hasArmy ? 'button' : undefined}
        accessibilityState={hasArmy ? { expanded } : undefined}
        onPress={hasArmy ? () => setExpanded((value) => !value) : undefined}
        style={styles.battleBody}
      >
        <View style={styles.battleTop}>
          {battle.opponentTownHallLevel > 0 ? (
            <MobileWebImage
              imageUrl={ImageAssets.townHall(battle.opponentTownHallLevel)}
              style={styles.townHall}
            />
          ) : null}
          <View style={styles.grow}>
            <Pressable
              accessibilityRole={battle.opponentPlayerTag ? 'link' : undefined}
              disabled={!battle.opponentPlayerTag}
              onPress={(event) => {
                event.stopPropagation();
                void onOpenOpponent(battle.opponentPlayerTag);
              }}
            >
              <CKText role="rowTitle" numberOfLines={1}>
                {name}
              </CKText>
            </Pressable>
            <CKText role="metadata" muted>
              {date || '—'}
            </CKText>
          </View>
          <View style={styles.result}>
            <CKText
              role="titleSmall"
              style={{ color: battle.trophies < 0 ? statColors.loss : statColors.win }}
            >
              {battle.trophies > 0 ? '+' : ''}
              {battle.trophies}
            </CKText>
            <View style={styles.inline}>
              {[0, 1, 2].map((star) => (
                <MobileWebImage
                  key={star}
                  imageUrl={ImageAssets.attackStar}
                  style={[
                    styles.star,
                    (battle.stars === null || star >= battle.stars) && { opacity: 0.2 },
                  ]}
                />
              ))}
              <CKText role="metadata">
                {battle.destructionPercentage === null
                  ? '—'
                  : `${Math.round(battle.destructionPercentage)}%`}
              </CKText>
            </View>
          </View>
        </View>
        {hasArmy ? (
          <View style={[styles.inline, styles.armyToggle]}>
            <CKText role="metadata" muted>
              {t('upgradeTrackerPlanCategoryArmy')}
            </CKText>
            {expanded ? (
              <ChevronDown size={16} color={theme.onSurfaceVariant} />
            ) : (
              <ChevronRight size={16} color={theme.onSurfaceVariant} />
            )}
          </View>
        ) : null}
      </Pressable>
      {expanded && hasArmy ? (
        <View style={styles.army} testID="ranked-battle-army">
          <LegendArmy shareCode={battle.shareCode} />
        </View>
      ) : null}
    </Surface>
  );
}

const styles = StyleSheet.create({
  section: { gap: 12 },
  selectors: { flexDirection: 'row', gap: 10 },
  selector: { flex: 1, padding: 14, gap: 12, borderRadius: ckRadius.tile, borderBottomWidth: 3 },
  inline: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  summaryNumbers: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 4,
  },
  summaryStrip: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    flexWrap: 'wrap',
    gap: 8,
    paddingHorizontal: 4,
  },
  icon: { width: 24, height: 24 },
  smallIcon: { width: 16, height: 16 },
  battle: { borderWidth: 0, overflow: 'hidden' },
  battleBody: { padding: 14, gap: 10, minHeight: 92 },
  battleTop: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  grow: { flex: 1, minWidth: 0, gap: 4 },
  townHall: { width: 38, height: 38 },
  result: { alignItems: 'flex-end', gap: 6 },
  star: { width: 15, height: 15 },
  armyToggle: { justifyContent: 'flex-end' },
  army: { paddingHorizontal: 14, paddingBottom: 16 },
  automatic: { borderWidth: 1, borderStyle: 'dashed' },
});
