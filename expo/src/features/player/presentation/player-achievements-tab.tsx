import { useState } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { Star, Trophy } from 'lucide-react-native';
import { toIntlLocale, useI18n } from '../../../i18n';
import {
  CKText,
  PillSurface,
  ResponsiveGrid,
  Surface,
  ckRadius,
  colorWithAlpha,
  useCKTheme,
} from '../../../ui';
import type { Player } from '../models';

export function PlayerAchievementsTab({ player }: { player: Player }) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [village, setVillage] = useState<'home' | 'others'>('home');
  const achievements = player.achievements.filter(
    (item) => item.name !== 'Keep Your Account Safe!',
  );
  const home = achievements.filter((item) => item.village === 'home');
  const others = achievements.filter(
    (item) => item.village === 'builderBase' || item.village === 'clanCapital',
  );
  const items = (village === 'home' ? home : others)
    .slice()
    .sort((a, b) => Number(complete(a)) - Number(complete(b)));
  return (
    <View style={styles.sections}>
      <View style={styles.segmented}>
        {(
          [
            ['home', `${t('gameBaseHome')} · ${home.filter(complete).length}/${home.length}`],
            [
              'others',
              `${t('generalOthers')} · ${others.filter(complete).length}/${others.length}`,
            ],
          ] as const
        ).map(([value, label]) => (
          <Pressable
            key={value}
            accessibilityRole="radio"
            accessibilityState={{ selected: village === value }}
            onPress={() => setVillage(value)}
            style={[
              styles.segment,
              village === value && { backgroundColor: colorWithAlpha(theme.primary, 0.16) },
            ]}
          >
            <CKText>{label}</CKText>
          </Pressable>
        ))}
      </View>
      <Surface radius={28} style={styles.container}>
        <ResponsiveGrid minItemWidth={360} maxColumns={3}>
          {items.map((item) => {
            const ratio = item.target > 0 ? item.value / item.target : 0;
            const visualComplete = ratio >= 1;
            return (
              <View key={item.name} style={[styles.card, visualComplete && styles.complete]}>
                <View style={[styles.leading, visualComplete && styles.leadingComplete]}>
                  {visualComplete ? (
                    <Trophy size={20} color="#FFD75E" />
                  ) : (
                    <Star size={20} color={theme.onSurfaceVariant} />
                  )}
                </View>
                <View style={styles.grow}>
                  <View style={styles.row}>
                    <CKText role="rowTitle" style={styles.grow}>
                      {item.name}
                    </CKText>
                    <View
                      style={styles.stars}
                      accessible
                      accessibilityLabel={`${displayStars(item)} of 3 stars`}
                    >
                      {[0, 1, 2].map((index) => {
                        const filled = index < displayStars(item);
                        return (
                          <Star
                            key={index}
                            size={15}
                            color={filled ? '#FFD75E' : theme.outlineVariant}
                            fill={filled ? '#FFD75E' : theme.outlineVariant}
                          />
                        );
                      })}
                    </View>
                  </View>
                  <CKText muted numberOfLines={2}>
                    {item.info.replace(/000000 /g, 'M ')}
                  </CKText>
                  <View style={styles.progressRow}>
                    <View style={styles.track}>
                      <View
                        style={[
                          styles.fill,
                          {
                            width: `${Math.max(0, Math.min(100, item.target > 0 ? (item.value / item.target) * 100 : 0))}%`,
                            backgroundColor: visualComplete ? '#FFD75E' : theme.primary,
                          },
                        ]}
                      />
                    </View>
                    <PillSurface>
                      <CKText role="labelSmall">
                        {compact(item.value, locale)} / {compact(item.target, locale)}
                      </CKText>
                    </PillSurface>
                  </View>
                </View>
              </View>
            );
          })}
        </ResponsiveGrid>
      </Surface>
    </View>
  );
}
function complete(item: Player['achievements'][number]) {
  return (
    ((item.name === 'Dragon Slayer' || item.name === 'Ungrateful Child') && item.value >= 1) ||
    (item.value >= item.target && item.stars === 3)
  );
}
function displayStars(item: Player['achievements'][number]) {
  const count =
    complete(item) && (item.name === 'Dragon Slayer' || item.name === 'Ungrateful Child')
      ? 3
      : item.stars;
  return count;
}
function compact(value: number, locale: string) {
  return new Intl.NumberFormat(toIntlLocale(locale), {
    notation: 'compact',
    maximumFractionDigits: 1,
  }).format(value);
}
const styles = StyleSheet.create({
  sections: { gap: 12, padding: 12, maxWidth: 1320, width: '100%', alignSelf: 'center' },
  segmented: { flexDirection: 'row', gap: 4 },
  segment: {
    minHeight: 44,
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 12,
    borderRadius: ckRadius.control,
  },
  grow: { flex: 1 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  container: { padding: 8 },
  card: {
    minHeight: 86,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    padding: 10,
    borderRadius: 18,
  },
  complete: { borderWidth: 1, borderColor: '#FFD75E80', backgroundColor: '#FFD75E12' },
  leading: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#80808022',
  },
  leadingComplete: { backgroundColor: '#FFD75E22' },
  stars: { flexDirection: 'row', gap: 1 },
  progressRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 8 },
  track: {
    height: 6,
    flex: 1,
    overflow: 'hidden',
    borderRadius: 999,
    backgroundColor: '#80808044',
  },
  fill: { height: '100%', borderRadius: 999 },
});
