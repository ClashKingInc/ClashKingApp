import { useState, type ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { ChevronRight } from 'lucide-react-native';
import { ImageAssets } from '../core/assets/image-assets';
import { toIntlLocale, useI18n } from '../i18n';
import { CKText } from './text';
import { MobileWebImage } from './mobile-web-image';
import { Surface } from './surfaces';
import { ckRadius, colorWithAlpha } from './tokens';
import { useCKTheme } from './theme';

/** Ranked and Legends share result geometry. Their callers supply identity and
 * army content; optional Town Hall art never changes the meaning of the result. */
export function BattleResultCard({
  name,
  time,
  identityDetails,
  townHallLevel,
  leadingIconUrl,
  stars,
  destruction,
  trophies,
  onOpenOpponent,
  children,
  compact = false,
  dashed = false,
  testID,
  detailTestID,
}: {
  name: string;
  time?: string | null;
  identityDetails?: ReactNode;
  townHallLevel?: number;
  leadingIconUrl?: string;
  stars: number | null;
  destruction: number | null;
  trophies: number;
  onOpenOpponent?: () => void;
  children?: ReactNode;
  compact?: boolean;
  dashed?: boolean;
  testID?: string;
  detailTestID?: string;
}) {
  const { t, locale } = useI18n();
  const theme = useCKTheme();
  const [expanded, setExpanded] = useState(false);
  const expandable = Boolean(children);
  const townHallImage =
    townHallLevel && townHallLevel > 0 ? ImageAssets.townHall(townHallLevel) : undefined;
  // The positive sign is part of this UI's contract. Render it explicitly
  // instead of depending on the runtime's Intl signDisplay support.
  const delta = `${trophies > 0 ? '+' : ''}${new Intl.NumberFormat(toIntlLocale(locale)).format(trophies)}`;
  return (
    <Surface
      radius={ckRadius.tile}
      style={[
        styles.card,
        dashed && {
          borderWidth: 1,
          borderStyle: 'dashed',
          borderColor: colorWithAlpha(theme.outlineVariant, 0.5),
        },
      ]}
    >
      <Pressable
        testID={testID}
        accessibilityLabel={name}
        accessibilityRole={expandable ? 'button' : undefined}
        accessibilityState={expandable ? { expanded } : undefined}
        onPress={expandable ? () => setExpanded((value) => !value) : undefined}
        style={({ pressed }) => [
          styles.body,
          compact && styles.compact,
          pressed && expandable && styles.pressed,
        ]}
      >
        {leadingIconUrl && !townHallImage ? (
          <MobileWebImage imageUrl={leadingIconUrl} style={styles.leadingIcon} />
        ) : null}
        <View style={styles.identity}>
          <View style={styles.nameRow}>
            {townHallImage ? (
              <MobileWebImage imageUrl={townHallImage} style={styles.townHall} />
            ) : null}
            <Pressable
              style={styles.name}
              accessibilityRole={onOpenOpponent ? 'link' : undefined}
              disabled={!onOpenOpponent}
              onPress={(event) => {
                event.stopPropagation();
                onOpenOpponent?.();
              }}
            >
              <CKText numberOfLines={1} role="bodyLarge">
                {name}
              </CKText>
            </Pressable>
          </View>
          {identityDetails}
          {time ? (
            <CKText muted role="metadata">
              {time}
            </CKText>
          ) : null}
        </View>
        <View style={styles.result}>
          {stars !== null ? (
            <View
              accessible
              accessibilityLabel={`${t('warStarsTitle')}: ${stars} / 3`}
              style={styles.stars}
            >
              {[0, 1, 2].map((star) => (
                <MobileWebImage
                  key={star}
                  imageUrl={ImageAssets.attackStar}
                  style={[styles.star, star >= stars && styles.unearned]}
                  testID={testID ? `${testID}-star-${star}` : undefined}
                />
              ))}
            </View>
          ) : null}
          <View style={styles.resultMain}>
            {stars !== null || destruction !== null ? (
              <CKText role="titleMedium">
                {destruction === null
                  ? '—'
                  : `${destruction.toLocaleString(toIntlLocale(locale), { maximumFractionDigits: 1 })}%`}
              </CKText>
            ) : null}
            <CKText muted role="metadata">
              ({delta})
            </CKText>
            {expandable ? (
              <ChevronRight
                size={18}
                color={theme.onSurfaceVariant}
                style={{ transform: [{ rotate: expanded ? '90deg' : '0deg' }] }}
              />
            ) : null}
          </View>
        </View>
      </Pressable>
      {expanded && expandable ? (
        <View style={styles.detail} testID={detailTestID}>
          {children}
        </View>
      ) : null}
    </Surface>
  );
}
const styles = StyleSheet.create({
  card: { overflow: 'hidden' },
  body: {
    minHeight: 82,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  compact: { minHeight: 68, paddingVertical: 8 },
  pressed: { opacity: 0.78, transform: [{ scale: 0.99 }] },
  identity: { flex: 1, minWidth: 0, gap: 3 },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  name: { flexShrink: 1, minWidth: 0 },
  townHall: { width: 24, height: 24, flexShrink: 0 },
  leadingIcon: { width: 34, height: 34 },
  result: { alignItems: 'flex-end', justifyContent: 'center', gap: 3 },
  resultMain: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  stars: { flexDirection: 'row', alignItems: 'center', gap: 1 },
  star: { width: 19, height: 19 },
  unearned: { opacity: 0.24 },
  detail: { paddingHorizontal: 12, paddingBottom: 10 },
});
