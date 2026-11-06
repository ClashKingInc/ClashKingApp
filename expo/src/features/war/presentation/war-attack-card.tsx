import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import { CKText, InfoTooltip, MobileWebImage, Surface } from '../../../ui';
import { ckColors } from '../../../ui/tokens';
import type { WarAttack, WarMember } from '../models';
import { formatDuration, formatPercent } from './presentation-utils';

export function WarAttackCard({
  attack,
  attacker,
  defender,
  attacking,
  showOpponent = false,
  footer,
  onPress,
  testID,
}: {
  attack: Pick<
    WarAttack,
    'attackerTag' | 'defenderTag' | 'stars' | 'destructionPercentage' | 'duration'
  >;
  attacker?: Pick<WarMember, 'name' | 'townhallLevel'> | null;
  defender?: Pick<WarMember, 'name' | 'townhallLevel'> | null;
  attacking: boolean;
  showOpponent?: boolean;
  footer?: ReactNode;
  onPress?: () => void;
  testID?: string;
}) {
  const { t } = useI18n();
  const own = attacking ? attacker : defender;
  const opponent = attacking ? defender : attacker;
  const primary = showOpponent ? opponent : own;
  const secondary = showOpponent ? own : opponent;
  const secondaryIsDefender = showOpponent ? !attacking : attacking;
  // The player history foregrounds the opponent; the war feed foregrounds
  // its clan member. Keep the secondary artwork and tooltip identity together.
  const opponentIcon = (
    <MobileWebImage
      imageUrl={
        secondary?.townhallLevel
          ? ImageAssets.townHall(secondary.townhallLevel)
          : ImageAssets.defaultImage
      }
      style={{ width: 18, height: 18 }}
    />
  );
  return (
    <Surface
      testID={testID}
      style={[
        styles.eventSurface,
        { overflow: 'hidden', width: '95%', alignSelf: attacking ? 'flex-start' : 'flex-end' },
      ]}
    >
      <View
        style={{
          position: 'absolute',
          left: attacking ? 0 : undefined,
          right: attacking ? undefined : 0,
          top: 0,
          bottom: 0,
          width: 4,
          backgroundColor: attacking ? ckColors.donationGreen : ckColors.primaryRed,
        }}
      />
      <Pressable
        onPress={onPress}
        disabled={!onPress}
        accessibilityRole={onPress ? 'button' : undefined}
      >
        <View
          style={{
            paddingVertical: 10,
            paddingHorizontal: 14,
            flexDirection: attacking ? 'row' : 'row-reverse',
            alignItems: 'center',
            gap: 8,
          }}
        >
          {/* Keep the home-clan player visible in both directions. Opponent
            identity is secondary disclosure, not another competing name row. */}
          <View
            style={[
              styles.grow,
              styles.nameRow,
              { flexDirection: attacking ? 'row' : 'row-reverse' },
            ]}
          >
            <MobileWebImage
              imageUrl={
                primary?.townhallLevel
                  ? ImageAssets.townHall(primary.townhallLevel)
                  : ImageAssets.defaultImage
              }
              style={{ width: 32, height: 32 }}
            />
            <CKText
              role="rowTitle"
              style={[styles.grow, { textAlign: attacking ? 'left' : 'right' }]}
            >
              {primary?.name ??
                (showOpponent !== attacking ? attack.attackerTag : attack.defenderTag)}
            </CKText>
          </View>
          <View
            style={[
              styles.resultColumn,
              { alignItems: attacking ? 'flex-end' : 'flex-start', gap: 2 },
            ]}
          >
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
              <WarResultStars stars={attack.stars} />
              <CKText style={{ fontSize: 16 }}>
                {formatPercent(attack.destructionPercentage)}
              </CKText>
            </View>
            <InfoTooltip
              label={t(
                secondaryIsDefender ? 'warAttacksDetailsDefender' : 'warAttacksDetailsAttacker',
              )}
              triggerStyle={{ width: 'auto', height: 28 }}
              triggerContent={
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                  {opponentIcon}
                  <CKText role="metadata" muted>
                    {attack.duration != null ? formatDuration(attack.duration) : '—'}
                  </CKText>
                </View>
              }
              message={
                t(secondaryIsDefender ? 'warAttacksDetailsDefender' : 'warAttacksDetailsAttacker') +
                ': ' +
                (secondary?.name ?? (secondaryIsDefender ? attack.defenderTag : attack.attackerTag))
              }
            />
          </View>
        </View>
        {footer ? <View style={{ paddingHorizontal: 14, paddingBottom: 10 }}>{footer}</View> : null}
      </Pressable>
    </Surface>
  );
}
export function WarResultStars({
  stars,
  compact = false,
  testID,
}: {
  stars: number;
  compact?: boolean;
  testID?: string;
}) {
  const { t } = useI18n();
  const earned = Math.max(0, Math.min(3, stars));
  return (
    <View
      accessible
      accessibilityLabel={t('warStarsTitle') + ': ' + earned + ' / 3'}
      testID={testID}
      style={styles.stars}
    >
      {[0, 1, 2].map((index) => (
        <MobileWebImage
          key={index}
          imageUrl={ImageAssets.attackStar}
          testID={testID ? testID + '-' + index : undefined}
          style={{
            width: compact ? 12 : 18,
            height: compact ? 12 : 18,
            opacity: index < earned ? 1 : 0.18,
          }}
        />
      ))}
    </View>
  );
}
const styles = StyleSheet.create({
  grow: { flex: 1, minWidth: 0 },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  resultColumn: { alignItems: 'flex-end', gap: 4 },
  eventSurface: { borderWidth: 0, borderRadius: 22 },
  stars: { flexDirection: 'row', gap: 1 },
});
