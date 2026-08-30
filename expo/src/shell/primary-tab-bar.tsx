import { Platform, Pressable, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { primaryTabRoutes } from '../navigation';
import { RouteIcon } from '../navigation/route-icons';
import { CKText, GlassSurface, colorWithAlpha, useCKTheme, useCKThemeMode } from '../ui';
import type { PrimaryRouteId } from './retained-pager';

type Translate = (key: (typeof primaryTabRoutes)[number]['labelKey']) => string;

export function PrimaryTabBar({
  selected,
  onSelect,
  t,
  isRtl = false,
}: {
  selected: PrimaryRouteId;
  onSelect: (route: PrimaryRouteId) => void;
  t: Translate;
  isRtl?: boolean;
}) {
  const insets = useSafeAreaInsets();
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  const ios = Platform.OS === 'ios';
  const items = (
    <View style={[styles.items, isRtl && styles.itemsRtl]} accessibilityRole="tablist">
      {primaryTabRoutes.map((route) => {
        const active = route.id === selected;
        return (
          <Pressable
            accessibilityLabel={t(route.labelKey)}
            accessibilityRole="tab"
            accessibilityState={{ selected: active }}
            key={route.id}
            onPress={() => onSelect(route.id as PrimaryRouteId)}
            style={({ pressed }) => [
              styles.item,
              ios ? styles.iosItem : styles.fallbackItem,
              active && {
                backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, ios ? 0.42 : 0.58),
              },
              pressed && styles.pressed,
            ]}
            testID={`primary-tab-${route.id}`}
          >
            <RouteIcon
              route={route}
              selected={active}
              size={ios ? 22 : 25}
              color={active ? theme.primary : colorWithAlpha(theme.onSurface, 0.92)}
            />
            {!ios && (
              <CKText
                role="labelMedium"
                numberOfLines={1}
                style={{
                  color: active ? theme.primary : colorWithAlpha(theme.onSurface, 0.92),
                  fontWeight: active ? '800' : '700',
                }}
              >
                {t(route.labelKey)}
              </CKText>
            )}
          </Pressable>
        );
      })}
    </View>
  );

  if (ios) {
    return (
      <View style={[styles.iosOuter, { paddingBottom: Math.max(insets.bottom, 4) }]}>
        <GlassSurface cornerRadius={31} interactive style={styles.iosGlass}>
          {items}
        </GlassSurface>
      </View>
    );
  }

  return (
    <View
      style={[styles.fallbackOuter, { paddingBottom: fallbackTabBarBottomPadding(insets.bottom) }]}
    >
      <View
        style={[
          styles.fallbackBar,
          {
            backgroundColor:
              mode === 'dark'
                ? colorWithAlpha('#000000', 0.9)
                : colorWithAlpha(theme.surface, 0.94),
            shadowOpacity: mode === 'dark' ? 0.3 : 0.14,
          },
        ]}
      >
        {items}
      </View>
    </View>
  );
}

export function fallbackTabBarBottomPadding(bottomInset: number): number {
  return bottomInset > 0 ? bottomInset : 10;
}

const styles = StyleSheet.create({
  items: { flex: 1, flexDirection: 'row' },
  itemsRtl: { flexDirection: 'row-reverse' },
  item: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  iosItem: { margin: 6, borderRadius: 25 },
  fallbackItem: { marginHorizontal: 4, marginVertical: 5, borderRadius: 29, gap: 4 },
  pressed: { opacity: 0.72 },
  iosOuter: { minHeight: 78, paddingHorizontal: 8, paddingTop: 4, justifyContent: 'flex-start' },
  iosGlass: { height: 62 },
  fallbackOuter: { paddingHorizontal: 14, paddingTop: 2 },
  fallbackBar: {
    height: 68,
    borderRadius: 34,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowRadius: 18,
    elevation: 10,
  },
});
