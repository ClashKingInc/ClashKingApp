import { Platform, Pressable, StyleSheet, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { primaryTabRoutes } from '../navigation';
import { RouteIcon } from '../navigation/route-icons';
import { CKText, GlassSurface, colorWithAlpha, useCKTheme, useCKThemeMode } from '../ui';
import {
  fallbackTabBarBottomPadding,
  IOS_PRIMARY_TAB_BAR_MIN_HEIGHT,
  PRIMARY_TAB_BAR_HEIGHT,
  PRIMARY_TAB_BAR_TOP_PADDING,
  WEB_PRIMARY_TAB_BAR_HEIGHT,
} from './contracts';
import type { PrimaryRouteId } from './retained-pager';

type Translate = (key: (typeof primaryTabRoutes)[number]['labelKey']) => string;

export function PrimaryTabBar({
  selected,
  onSelect,
  t,
  isRtl = false,
}: {
  selected?: PrimaryRouteId;
  onSelect: (route: PrimaryRouteId) => void;
  t: Translate;
  isRtl?: boolean;
}) {
  const insets = useSafeAreaInsets();
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  const ios = Platform.OS === 'ios';
  const web = Platform.OS === 'web';
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
              !web ? styles.iosItem : styles.fallbackItem,
              web && styles.webItem,
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
              size={!web ? 22 : 25}
              color={active ? theme.primary : colorWithAlpha(theme.onSurface, 0.92)}
            />
            {web && (
              <CKText
                role="labelMedium"
                numberOfLines={1}
                style={{
                  color: active ? theme.primary : colorWithAlpha(theme.onSurface, 0.92),
                  fontWeight: active ? '800' : '700',
                  ...(web ? { fontSize: 12 } : {}),
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

  // In a mobile browser the page already sits above browser chrome. Keep
  // tabs attached to the viewport instead of adding a second floating pill.
  if (web) {
    return (
      <View
        style={[
          styles.webOuter,
          {
            backgroundColor: theme.surface,
            borderTopColor: colorWithAlpha(theme.outlineVariant, 0.25),
            paddingBottom: insets.bottom,
          },
        ]}
      >
        <View style={styles.webBar}>{items}</View>
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

const styles = StyleSheet.create({
  webOuter: { borderTopWidth: StyleSheet.hairlineWidth },
  webBar: { height: WEB_PRIMARY_TAB_BAR_HEIGHT, paddingHorizontal: 8 },
  webItem: { borderRadius: 14, marginVertical: 6, gap: 2 },
  items: { flex: 1, flexDirection: 'row' },
  itemsRtl: { flexDirection: 'row-reverse' },
  item: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  iosItem: { margin: 6, borderRadius: 25 },
  fallbackItem: { marginHorizontal: 4, marginVertical: 5, borderRadius: 29, gap: 4 },
  pressed: { opacity: 0.72 },
  iosOuter: {
    minHeight: IOS_PRIMARY_TAB_BAR_MIN_HEIGHT,
    paddingHorizontal: 8,
    paddingTop: PRIMARY_TAB_BAR_TOP_PADDING,
    justifyContent: 'flex-start',
  },
  iosGlass: { height: PRIMARY_TAB_BAR_HEIGHT },
  fallbackOuter: { paddingHorizontal: 8, paddingTop: PRIMARY_TAB_BAR_TOP_PADDING },
  fallbackBar: {
    height: PRIMARY_TAB_BAR_HEIGHT,
    borderRadius: 31,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 8 },
    shadowRadius: 18,
    elevation: 10,
  },
});
