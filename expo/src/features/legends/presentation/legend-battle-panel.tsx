import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChevronRight } from 'lucide-react-native';

import { ImageAssets } from '../../../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../../../i18n';
import { CKText, MobileWebImage, ckRadius, colorWithAlpha, useCKTheme } from '../../../ui';
import type { PlayerLegendBattle, PlayerLegendBattlelog } from '../../player/models';
import { relativeWarTime } from '../../war/presentation/presentation-utils';
import { BattleResultCard } from '../../../ui/battle-result-card';
import { LegendArmy } from './legend-army-presentation';

export function LegendBattlePanel({
  data,
  onOpenOpponent,
  onOpenArmy,
  now = new Date(),
}: {
  readonly data: PlayerLegendBattlelog;
  readonly onOpenOpponent?: (tag: string) => void;
  readonly onOpenArmy?: (shareCode: string) => void;
  readonly now?: Date;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [battleType, setBattleType] = useState<'attacks' | 'defenses'>('attacks');
  const battles = sortedLegendBattles(battleType === 'attacks' ? data.attacks : data.defenses);

  return (
    <View style={styles.panel}>
      <View accessibilityRole="tablist" style={styles.tabs}>
        {(
          [
            ['attacks', ImageAssets.sword, data.attacks.length, data.attackTrophies],
            ['defenses', ImageAssets.shieldWithArrow, data.defenses.length, data.defenseTrophies],
          ] as const
        ).map(([type, imageUrl, count, trophies]) => {
          const selected = battleType === type;
          const label = t(type === 'attacks' ? 'rankedLeagueAttacks' : 'rankedLeagueDefenses');
          return (
            <Pressable
              key={type}
              accessibilityLabel={`${label}, ${count} / 8`}
              accessibilityRole="tab"
              accessibilityState={{ selected }}
              onPress={() => setBattleType(type)}
              style={[
                styles.tab,
                {
                  backgroundColor: colorWithAlpha(
                    theme.surfaceContainerHighest,
                    selected ? 0.78 : 0.38,
                  ),
                },
                selected && { borderBottomColor: theme.primary },
              ]}
            >
              <View style={styles.tabMain}>
                <MobileWebImage imageUrl={imageUrl} style={styles.tabImage} />
                <CKText role="titleLarge">
                  {count}
                  <CKText muted role="metadata">
                    {' '}
                    / 8 ({trophies >= 0 ? '+' : ''}
                    {trophies})
                  </CKText>
                </CKText>
              </View>
              <CKText numberOfLines={1} muted role="metadata">
                {label}
              </CKText>
            </Pressable>
          );
        })}
      </View>
      <View style={styles.battles}>
        {battles.map((battle, index) => (
          <LegendBattleCard
            key={`${battleType}-${battle.battleTime?.getTime() ?? 'unknown'}-${index}`}
            battle={battle}
            index={index}
            now={now}
            onOpenArmy={onOpenArmy}
            onOpenOpponent={onOpenOpponent}
          />
        ))}
      </View>
    </View>
  );
}

function LegendBattleCard({
  battle,
  index,
  now,
  onOpenOpponent,
  onOpenArmy,
}: {
  readonly battle: PlayerLegendBattle;
  readonly index: number;
  readonly now: Date;
  readonly onOpenOpponent?: (tag: string) => void;
  readonly onOpenArmy?: (shareCode: string) => void;
}) {
  const { locale, t } = useI18n();
  const theme = useCKTheme();
  const hasArmy = !battle.automatic && Boolean(battle.shareCode);
  const opponentName = battle.automatic
    ? t('legendsAutomaticDefense')
    : battle.opponentName || battle.opponentTag || t('generalUnknown');
  const relativeTime = battle.battleTime ? relativeWarTime(battle.battleTime, now, t) : null;
  const opponentDetails = battle.opponentInsight
    ? [
        battle.opponentInsight.trophies === null
          ? null
          : new Intl.NumberFormat(toIntlLocale(locale)).format(battle.opponentInsight.trophies),
        battle.opponentInsight.globalRank === null
          ? null
          : `(#${new Intl.NumberFormat(toIntlLocale(locale)).format(battle.opponentInsight.globalRank)})`,
      ]
        .filter(Boolean)
        .join(' ')
    : '';
  return (
    <BattleResultCard
      name={opponentName}
      time={relativeTime}
      identityDetails={
        opponentDetails ? (
          <View style={styles.opponentStanding}>
            <MobileWebImage imageUrl={ImageAssets.legendLeagueOne} style={styles.legendIcon} />
            <CKText muted role="metadata">
              {opponentDetails}
            </CKText>
          </View>
        ) : undefined
      }
      stars={battle.stars}
      destruction={battle.destructionPercentage}
      trophies={battle.trophies}
      onOpenOpponent={
        battle.opponentTag && onOpenOpponent ? () => onOpenOpponent(battle.opponentTag!) : undefined
      }
      testID={`legend-battle-${index}`}
      detailTestID={`legend-battle-army-${index}`}
    >
      {hasArmy && battle.shareCode ? (
        <>
          <LegendArmy shareCode={battle.shareCode} />
          {onOpenArmy ? (
            <Pressable
              accessibilityRole="button"
              onPress={() => onOpenArmy(battle.shareCode!)}
              style={styles.detailsButton}
            >
              <CKText role="rowTitle">{t('generalDetails')}</CKText>
              <ChevronRight color={theme.onSurface} size={20} />
            </Pressable>
          ) : null}
        </>
      ) : null}
    </BattleResultCard>
  );
}

export function sortedLegendBattles(battles: readonly PlayerLegendBattle[]) {
  return battles
    .map((battle, sourceIndex) => ({ battle, sourceIndex }))
    .sort((left, right) => {
      const leftTime = left.battle.battleTime?.getTime() ?? null;
      const rightTime = right.battle.battleTime?.getTime() ?? null;
      if (leftTime === null && rightTime === null) return left.sourceIndex - right.sourceIndex;
      if (leftTime === null) return 1;
      if (rightTime === null) return -1;
      return rightTime - leftTime || left.sourceIndex - right.sourceIndex;
    })
    .map(({ battle }) => battle);
}

const styles = StyleSheet.create({
  panel: { gap: 10 },
  tabs: { flexDirection: 'row', gap: 8 },
  tab: {
    flex: 1,
    minHeight: 76,
    justifyContent: 'center',
    alignItems: 'center',
    gap: 2,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: ckRadius.control,
    borderBottomWidth: 3,
    borderBottomColor: 'transparent',
  },
  tabMain: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 6 },
  tabImage: { width: 30, height: 30 },
  battles: { gap: 8 },
  opponentStanding: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  legendIcon: { width: 18, height: 18 },
  detailsButton: {
    minHeight: 44,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: 6,
  },
});
