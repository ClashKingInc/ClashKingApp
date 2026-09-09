import { memo, useMemo } from 'react';
import { StyleSheet, View } from 'react-native';
import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import { CKText, MobileWebImage, useCKTheme } from '../../../ui';
import type { WarInfo } from '../models';

type Member = { townhallLevel: number };
function countLevels(members: readonly Member[]) {
  const counts = new Map<number, number>();
  for (const member of members)
    if (member.townhallLevel > 0)
      counts.set(member.townhallLevel, (counts.get(member.townhallLevel) ?? 0) + 1);
  return counts;
}
/** Registered rosters show unboxed artwork and counts, with no scope picker. */
export const TownHallBreakdown = memo(function TownHallBreakdown({
  members,
}: {
  members: readonly Member[];
}) {
  const { t } = useI18n();
  const levels = useMemo(() => [...countLevels(members)].sort(([a], [b]) => b - a), [members]);
  return (
    <View style={styles.levels}>
      {levels.length ? (
        levels.map(([level, count]) => (
          <View
            key={level}
            style={styles.level}
            accessible
            accessibilityLabel={`${t('gameTownHallLevelNumber', { level })}: ${count}`}
          >
            <MobileWebImage imageUrl={ImageAssets.townHall(level)} style={styles.icon} />
            <View>
              <CKText role="bodyLarge">×{count}</CKText>
              <CKText muted role="labelLarge">
                TH{level}
              </CKText>
            </View>
          </View>
        ))
      ) : (
        <CKText muted>{t('generalNoDataAvailable')}</CKText>
      )}
    </View>
  );
});
/** Align identical levels on one axis so matchup differences can be read across a row. */
export const WarLineupComparison = memo(function WarLineupComparison({ war }: { war: WarInfo }) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const left = countLevels(war.clan?.members ?? []),
    right = countLevels(war.opponent?.members ?? []);
  const levels = [...new Set([...left.keys(), ...right.keys()])].sort((a, b) => b - a);
  const maximum = Math.max(1, ...left.values(), ...right.values());
  if (!levels.length) return <CKText muted>{t('generalNoDataAvailable')}</CKText>;
  return (
    <View style={styles.comparison}>
      <View style={styles.row}>
        <CKText style={styles.name}>{war.clan?.name}</CKText>
        <View style={styles.axis} />
        <CKText style={styles.name}>{war.opponent?.name}</CKText>
      </View>
      {levels.map((level) => (
        <View
          key={level}
          style={styles.row}
          accessible
          accessibilityLabel={`${t('gameTownHallLevelNumber', { level })}: ${war.clan?.name} ${left.get(level) ?? 0}, ${war.opponent?.name} ${right.get(level) ?? 0}`}
        >
          <View style={styles.barColumn}>
            <CKText role="bodyLarge">{left.get(level) ?? 0}</CKText>
            <View
              style={[
                styles.bar,
                {
                  backgroundColor: theme.onSurfaceVariant,
                  width: `${((left.get(level) ?? 0) / maximum) * 100}%`,
                },
              ]}
            />
          </View>
          <View style={styles.axis}>
            <MobileWebImage imageUrl={ImageAssets.townHall(level)} style={styles.icon} />
            <CKText role="labelLarge">TH{level}</CKText>
          </View>
          <View style={styles.barColumn}>
            <CKText role="bodyLarge">{right.get(level) ?? 0}</CKText>
            <View
              style={[
                styles.bar,
                {
                  backgroundColor: theme.onSurfaceVariant,
                  width: `${((right.get(level) ?? 0) / maximum) * 100}%`,
                },
              ]}
            />
          </View>
        </View>
      ))}
    </View>
  );
});
const styles = StyleSheet.create({
  levels: { flexDirection: 'row', flexWrap: 'wrap', gap: 16 },
  level: { flexDirection: 'row', alignItems: 'center', gap: 8, minWidth: 78 },
  icon: { width: 40, height: 40 },
  comparison: { gap: 12 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  name: { flex: 1, textAlign: 'center' },
  axis: { width: 56, alignItems: 'center', gap: 4 },
  barColumn: { flex: 1, alignItems: 'center', gap: 8 },
  bar: { height: 4, borderRadius: 2 },
});
