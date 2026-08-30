import type { ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import type { MessageKey } from '../i18n';
import {
  desktopSidebarBodyRoutes,
  desktopSidebarFooterRoutes,
  filterEnabledRoutes,
  primaryTabRoutes,
  RouteIcon,
  type AppRouteDefinition,
  type AppRouteId,
  type FeatureState,
} from '../navigation';
import { CKText, colorWithAlpha, useCKTheme } from '../ui';
import type { PrimaryRouteId } from './retained-pager';
import { DESKTOP_SIDEBAR_WIDTH } from './contracts';

type Translate = (key: MessageKey) => string;

export function DesktopSidebar({
  selectedPrimary,
  selectedUtility,
  features,
  t,
  avatar,
  displayName,
  productLabel,
  hasUser,
  onPrimary,
  onUtility,
  isRtl = false,
}: {
  selectedPrimary?: PrimaryRouteId;
  selectedUtility?: AppRouteId;
  features: FeatureState;
  t: Translate;
  avatar: ReactNode;
  displayName: string;
  productLabel: string;
  hasUser: boolean;
  onPrimary: (route: PrimaryRouteId) => void;
  onUtility: (route: AppRouteDefinition, replace: boolean) => void;
  isRtl?: boolean;
}) {
  const theme = useCKTheme();
  const body = filterEnabledRoutes(desktopSidebarBodyRoutes, features);
  const footer = filterEnabledRoutes(desktopSidebarFooterRoutes, features);
  return (
    <SafeAreaView
      edges={['top', 'bottom', 'left', 'right']}
      style={[
        styles.sidebar,
        {
          backgroundColor: colorWithAlpha(theme.surface, 0.58),
          borderColor: colorWithAlpha(theme.outlineVariant, 0.2),
        },
        isRtl
          ? { borderLeftWidth: StyleSheet.hairlineWidth }
          : { borderRightWidth: StyleSheet.hairlineWidth },
      ]}
      testID="desktop-sidebar"
    >
      <View style={[styles.identity, isRtl && styles.rowRtl]}>
        <View style={styles.avatar}>{avatar}</View>
        <View style={styles.identityText}>
          <CKText role="titleMedium" numberOfLines={1} style={styles.strong}>
            {displayName}
          </CKText>
          <CKText muted role="labelMedium" numberOfLines={1}>
            {productLabel}
          </CKText>
        </View>
      </View>
      <View style={styles.primary}>
        {primaryTabRoutes.map((route) => (
          <SidebarRoute
            key={route.id}
            route={route}
            label={t(route.labelKey)}
            selected={route.id === selectedPrimary}
            onPress={() => onPrimary(route.id as PrimaryRouteId)}
            isRtl={isRtl}
          />
        ))}
      </View>
      <ScrollView
        contentContainerStyle={[
          styles.utilities,
          { borderTopColor: colorWithAlpha(theme.outlineVariant, 0.2) },
        ]}
      >
        {body.map((route) => (
          <SidebarRoute
            key={route.id}
            route={route}
            label={t(route.labelKey)}
            selected={route.id === selectedUtility}
            onPress={() => onUtility(route, selectedUtility !== undefined)}
            isRtl={isRtl}
            compact
          />
        ))}
      </ScrollView>
      <View style={[styles.footer, { borderTopColor: colorWithAlpha(theme.outlineVariant, 0.2) }]}>
        {footer.map((route) => (
          <SidebarRoute
            key={route.id}
            route={route}
            label={t(route.labelKey)}
            selected={route.id === selectedUtility}
            disabled={!hasUser && route.id === 'settings'}
            onPress={() => onUtility(route, selectedUtility !== undefined)}
            isRtl={isRtl}
            compact
          />
        ))}
      </View>
    </SafeAreaView>
  );
}

function SidebarRoute({
  route,
  label,
  selected,
  disabled = false,
  onPress,
  isRtl = false,
  compact = false,
}: {
  route: AppRouteDefinition;
  label: string;
  selected: boolean;
  disabled?: boolean;
  onPress: () => void;
  isRtl?: boolean;
  compact?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ selected, disabled }}
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.route,
        compact && styles.compactRoute,
        isRtl && styles.rowRtl,
        selected && { backgroundColor: colorWithAlpha(theme.primary, 0.22) },
        disabled && styles.disabled,
        pressed && styles.pressed,
      ]}
    >
      <RouteIcon route={route} selected={selected} color={theme.onSurface} size={21} />
      <CKText
        numberOfLines={1}
        style={{
          color: selected ? theme.primary : theme.onSurface,
          fontWeight: selected ? '800' : '700',
        }}
      >
        {label}
      </CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  sidebar: {
    width: DESKTOP_SIDEBAR_WIDTH,
    paddingLeft: 18,
    paddingTop: 16,
    paddingRight: 18,
    paddingBottom: 18,
  },
  identity: { flexDirection: 'row', alignItems: 'center', gap: 12, marginBottom: 24 },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
  },
  identityText: { flex: 1 },
  strong: { fontWeight: '800' },
  primary: { gap: 7, paddingBottom: 25 },
  utilities: { borderTopWidth: StyleSheet.hairlineWidth, paddingTop: 8 },
  footer: { borderTopWidth: StyleSheet.hairlineWidth, paddingTop: 8 },
  route: {
    minHeight: 44,
    borderRadius: 14,
    paddingHorizontal: 12,
    paddingVertical: 11,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  compactRoute: {
    minHeight: 38,
    borderRadius: 12,
    paddingHorizontal: 10,
    paddingVertical: 9,
  },
  pressed: { opacity: 0.72 },
  disabled: { opacity: 0.38 },
  rowRtl: { flexDirection: 'row-reverse' },
});
