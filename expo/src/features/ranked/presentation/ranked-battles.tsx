import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { useEffect, useState, type ReactNode } from 'react';
import { Animated, Pressable, StyleSheet, View } from 'react-native';
import { useCKAccessibility } from '../../../ui/accessibility';
import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  EmptyState,
  InfoTooltip,
  MobileWebImage,
  ResponsiveGrid,
  SkeletonContent,
  ckRadius,
  colorWithAlpha,
  statColors,
  useCKTheme,
} from '../../../ui';
import { RankedLeagueBattle } from '../../player/models';
import type { RankedPeriod } from '../data';
import { LegendArmy } from '../../legends/presentation/legend-army-presentation';
import { relativeWarTime } from '../../war/presentation/presentation-utils';
import { BattleResultCard } from '../../../ui/battle-result-card';

// Ranked defenses award points; only Legends treats defense trophies as losses.
// Normalize at this presentation boundary, keeping source records unchanged.
function rankedPoints(battle: RankedLeagueBattle, direction: 'attacks' | 'defenses') {
  return direction === 'defenses' ? Math.abs(battle.trophies) : battle.trophies;
}

export function RankedBattles({
  period,
  onOpenOpponent,
  loading,
  error,
  onRetry,
  dateNavigator,
}: {
  period: RankedPeriod;
  onOpenOpponent: (tag: string) => Promise<void>;
  loading?: boolean;
  error?: string;
  onRetry: () => void;
  dateNavigator?: ReactNode;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const expanded = layout.isExpanded;
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
      ? battles.reduce((sum, battle) => sum + rankedPoints(battle, direction), 0) / battles.length
      : null;
  const signed = (value: number) =>
    `${value > 0 ? '+' : ''}${new Intl.NumberFormat(toIntlLocale(locale), {
      maximumFractionDigits: 1,
    }).format(value)}`;
  return (
    <View style={styles.section}>
      {expanded && dateNavigator ? (
        <View style={styles.periodToolbar}>
          <View style={styles.dateNavigator}>{dateNavigator}</View>
        </View>
      ) : null}
      <View style={{ display: 'contents' }}>
        <View
          accessibilityRole="tablist"
          style={[styles.selectors, expanded && styles.expandedSelectors]}
        >
          {(['attacks', 'defenses'] as const).map((key) => {
            const selected = direction === key;
            const list = key === 'attacks' ? period.attacks : period.defenses;
            const registered = key === 'attacks' ? period.attackCount : period.defenseCount;
            const used = registered + list.filter((battle) => battle.automatic).length;
            const limit = key === 'attacks' ? period.attackMaxBattles : period.defenseMaxBattles;
            const known = key === 'attacks' ? period.attacksComplete : period.defensesComplete;
            const total = list.reduce((sum, battle) => sum + rankedPoints(battle, key), 0);
            const label = t(key === 'attacks' ? 'rankedLeagueAttacks' : 'rankedLeagueDefenses');
            return (
              <Pressable
                key={key}
                accessibilityRole="tab"
                accessibilityState={{ selected }}
                onPress={() => setDirection(key)}
                style={[
                  styles.selector,
                  // Keep the expanded choices in a real horizontal row. A
                  // vertical flex rail previously collapsed these summary cards.
                  expanded && styles.expandedSelector,
                  {
                    backgroundColor: selected ? colorWithAlpha(theme.primary, 0.13) : theme.card,
                    borderBottomColor: selected ? theme.primary : 'transparent',
                  },
                ]}
              >
                {expanded ? (
                  <View style={styles.expandedSelectorContent}>
                    <MobileWebImage
                      imageUrl={key === 'attacks' ? ImageAssets.sword : ImageAssets.shieldWithArrow}
                      style={styles.icon}
                    />
                    <View style={styles.expandedSelectorIdentity}>
                      <CKText skeleton={false} role="metadata" style={styles.expandedSelectorLabel}>
                        {label}
                      </CKText>
                      <CKText role="titleLarge" style={styles.expandedSelectorCount}>
                        {used}
                        <CKText muted role="metadata">
                          {limit > 0 ? ` / ${limit}` : ''}
                        </CKText>
                      </CKText>
                    </View>
                    <View style={styles.inline}>
                      <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.smallIcon} />
                      <CKText
                        role="rowTitle"
                        style={[
                          styles.expandedSelectorGain,
                          { color: total < 0 ? statColors.loss : statColors.win },
                        ]}
                      >
                        {known && list.length ? signed(total) : '—'}
                      </CKText>
                    </View>
                  </View>
                ) : (
                  <>
                    <View style={styles.inline}>
                      <MobileWebImage
                        imageUrl={
                          key === 'attacks' ? ImageAssets.sword : ImageAssets.shieldWithArrow
                        }
                        style={styles.icon}
                      />
                      <CKText skeleton={false} role="rowTitle">
                        {label}
                      </CKText>
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
                  </>
                )}
              </Pressable>
            );
          })}
        </View>
        <View style={[styles.summaryStrip, expanded && styles.expandedSummaryStrip]}>
          <View style={styles.inline}>
            <MobileWebImage imageUrl={ImageAssets.trophies} style={styles.smallIcon} />
            <CKText skeleton={false} role="metadata" muted>
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
      </View>
      <Animated.View style={[styles.section, { opacity: contentOpacity }]}>
        {waiting ? (
          <View style={{ minHeight: 300 }} accessibilityState={{ busy: true }}>
            {showPlaceholder ? (
              <SkeletonContent loading style={styles.section}>
                <RankedBattleList expanded={expanded}>
                  {[0, 1, 2].map((index) => (
                    <RankedBattleRow
                      key={index}
                      battle={
                        new RankedLeagueBattle('', 'Opponent player', 3, 100, 40, new Date(0))
                      }
                      direction={direction}
                      onOpenOpponent={onOpenOpponent}
                    />
                  ))}
                </RankedBattleList>
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
            <RankedBattleList expanded={expanded}>
              {rows.map(({ battle, key }) => (
                <RankedBattleRow
                  key={key}
                  battle={battle}
                  direction={direction}
                  onOpenOpponent={onOpenOpponent}
                />
              ))}
              {automatic.map((battle, index) => (
                <BattleResultCard
                  key={`automatic:${period.seasonId}:${index}`}
                  compact
                  dashed
                  testID={`ranked-automatic-defense-${index}`}
                  name={t('legendsAutomaticDefense')}
                  leadingIconUrl={ImageAssets.shieldWithArrow}
                  stars={null}
                  destruction={null}
                  trophies={rankedPoints(battle, direction)}
                  identityDetails={
                    <InfoTooltip
                      label={t('legendsAutomaticDefense')}
                      message={t('rankedAutomaticDefenseExplanation')}
                      triggerStyle={{ width: 24, height: 24 }}
                    />
                  }
                />
              ))}
            </RankedBattleList>
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

function RankedBattleList({ expanded, children }: { expanded: boolean; children: ReactNode }) {
  return expanded ? (
    <ResponsiveGrid minItemWidth={420} maxColumns={2} gap={12}>
      {children}
    </ResponsiveGrid>
  ) : (
    <>{children}</>
  );
}

function RankedBattleRow({
  battle,
  direction,
  onOpenOpponent,
}: {
  battle: RankedLeagueBattle;
  direction: 'attacks' | 'defenses';
  onOpenOpponent: (tag: string) => Promise<void>;
}) {
  const { t } = useI18n();
  return (
    <BattleResultCard
      compact
      name={battle.opponentName || battle.opponentPlayerTag || t('generalUnknown')}
      time={battle.creationTime ? relativeWarTime(battle.creationTime, new Date(), t) : null}
      townHallLevel={battle.opponentTownHallLevel}
      stars={battle.stars}
      destruction={battle.destructionPercentage}
      trophies={rankedPoints(battle, direction)}
      onOpenOpponent={
        battle.opponentPlayerTag
          ? () => {
              void onOpenOpponent(battle.opponentPlayerTag);
            }
          : undefined
      }
      detailTestID="ranked-battle-army"
    >
      {battle.shareCode ? <LegendArmy shareCode={battle.shareCode} /> : null}
    </BattleResultCard>
  );
}

const styles = StyleSheet.create({
  section: { gap: 12 },
  selectors: { flexDirection: 'row', gap: 10 },
  expandedSelectors: { gap: 12, alignItems: 'stretch' },
  expandedSelector: {
    minHeight: 84,
    flexShrink: 0,
    paddingHorizontal: 16,
    paddingVertical: 12,
    gap: 0,
  },
  expandedSelectorContent: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  expandedSelectorIdentity: { flex: 1, minWidth: 0, gap: 2 },
  expandedSelectorLabel: { fontSize: 14, lineHeight: 18 },
  expandedSelectorCount: {
    fontSize: 28,
    lineHeight: 32,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  expandedSelectorGain: {
    fontSize: 20,
    lineHeight: 25,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  expandedSummaryStrip: { justifyContent: 'flex-start', gap: 24 },
  periodToolbar: { alignItems: 'flex-end' },
  dateNavigator: { width: '100%', maxWidth: 440 },
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
});
