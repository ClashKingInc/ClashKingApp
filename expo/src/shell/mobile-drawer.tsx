import { useEffect, useRef, useState, type ReactNode } from 'react';
import { Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { CircleHelp, Goal, UserPlus } from 'lucide-react-native';

import type { MessageKey } from '../i18n';
import {
  filterEnabledRoutes,
  mobileDrawerBodyRoutes,
  mobileDrawerFooterRoutes,
  RouteIcon,
  type AppRouteDefinition,
  type FeatureState,
} from '../navigation';
import { CKText, ckColors, colorWithAlpha, useCKTheme } from '../ui';

type Translate = (key: MessageKey) => string;

export function MobileDrawer({
  isRtl,
  features,
  t,
  avatar,
  displayName,
  followerCount,
  closeLabel,
  onRequestClose,
  onNavigate,
  onAchievements,
  onAddAccount,
  hasUser,
}: {
  isRtl: boolean;
  features: FeatureState;
  t: Translate;
  avatar: ReactNode;
  displayName: string;
  followerCount: number | null;
  closeLabel: string;
  onRequestClose: (after?: () => void) => void;
  onNavigate: (route: AppRouteDefinition) => void;
  onAchievements: () => void;
  onAddAccount: () => void;
  hasUser: boolean;
}) {
  const theme = useCKTheme();
  const bodyRoutes = filterEnabledRoutes(mobileDrawerBodyRoutes, features);
  const footerRoutes = filterEnabledRoutes(mobileDrawerFooterRoutes, features);
  const [showFollowerHelp, setShowFollowerHelp] = useState(false);
  const helpTimer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  useEffect(
    () => () => {
      if (helpTimer.current) clearTimeout(helpTimer.current);
    },
    [],
  );
  const revealFollowerHelp = () => {
    setShowFollowerHelp(true);
    if (helpTimer.current) clearTimeout(helpTimer.current);
    helpTimer.current = setTimeout(() => setShowFollowerHelp(false), 4000);
  };
  const navigate = (route: AppRouteDefinition) => {
    onRequestClose(() => onNavigate(route));
  };
  return (
    <SafeAreaView
      edges={['top', 'right', 'bottom', 'left']}
      onAccessibilityEscape={() => onRequestClose()}
      style={[
        styles.drawer,
        {
          backgroundColor: theme.surface,
          borderTopRightRadius: isRtl ? 0 : 28,
          borderBottomRightRadius: isRtl ? 0 : 28,
          borderTopLeftRadius: isRtl ? 28 : 0,
          borderBottomLeftRadius: isRtl ? 28 : 0,
        },
      ]}
      testID="mobile-drawer"
    >
      <ScrollView
        automaticallyAdjustContentInsets={false}
        contentContainerStyle={styles.scrollContent}
        contentInsetAdjustmentBehavior="never"
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header} accessibilityHint={closeLabel}>
          <View style={[styles.headerTop, isRtl && styles.rowRtl]}>
            <View style={styles.avatar}>{avatar}</View>
            <View style={[styles.headerActions, isRtl && styles.rowRtl]}>
              <DrawerHeaderAction
                label={t('achievementsTitle')}
                onPress={() => onRequestClose(onAchievements)}
              >
                <Goal color={ckColors.warGold} size={22} />
              </DrawerHeaderAction>
              <DrawerHeaderAction
                label={t('accountsAdd')}
                onPress={() => onRequestClose(onAddAccount)}
              >
                <UserPlus color={theme.onSurface} size={22} />
              </DrawerHeaderAction>
            </View>
          </View>
          <CKText role="titleLarge" numberOfLines={1} style={styles.displayName}>
            {displayName}
          </CKText>
          <View style={[styles.followerRow, isRtl && styles.rowRtl]}>
            <CKText muted role="bodyMedium">
              {followerCount ?? '—'} {t('drawerFollowers')}
            </CKText>
            <Pressable
              accessibilityHint={t('drawerFollowersHelp')}
              accessibilityLabel={t('drawerFollowersHelp')}
              accessibilityRole="button"
              hitSlop={8}
              onPress={revealFollowerHelp}
              style={styles.helpButton}
            >
              <CircleHelp color={theme.onSurfaceVariant} size={15} />
            </Pressable>
          </View>
          {showFollowerHelp ? (
            <View style={[styles.helpBubble, { backgroundColor: theme.surfaceContainerHighest }]}>
              <CKText muted role="bodySmall">
                {t('drawerFollowersHelp')}
              </CKText>
            </View>
          ) : null}
        </View>
        <View style={styles.body}>
          {bodyRoutes.map((route) => (
            <DrawerRoute
              key={route.id}
              route={route}
              t={t}
              isRtl={isRtl}
              onPress={() => navigate(route)}
            />
          ))}
        </View>
      </ScrollView>
      <View style={[styles.footer, { borderTopColor: colorWithAlpha(theme.outlineVariant, 0.2) }]}>
        {footerRoutes.map((route) => (
          <DrawerRoute
            key={route.id}
            route={route}
            t={t}
            compact
            isRtl={isRtl}
            disabled={!hasUser && route.id === 'settings'}
            onPress={() => navigate(route)}
          />
        ))}
      </View>
    </SafeAreaView>
  );
}

function DrawerHeaderAction({
  children,
  label,
  onPress,
}: {
  children: ReactNode;
  label: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      accessibilityLabel={label}
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.headerAction, pressed && styles.pressed]}
    >
      {children}
    </Pressable>
  );
}

function DrawerRoute({
  route,
  t,
  onPress,
  compact = false,
  disabled = false,
  isRtl = false,
}: {
  route: AppRouteDefinition;
  t: Translate;
  onPress: () => void;
  compact?: boolean;
  disabled?: boolean;
  isRtl?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled }}
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.route,
        isRtl && styles.rowRtl,
        compact && styles.compactRoute,
        disabled && styles.disabled,
        pressed && styles.pressed,
      ]}
    >
      <RouteIcon route={route} color={theme.onSurface} size={compact ? 18 : 21} />
      <CKText
        role={compact ? 'bodyLarge' : 'titleMedium'}
        numberOfLines={1}
        style={{ fontWeight: '700' }}
      >
        {t(route.labelKey)}
      </CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  drawer: { flex: 1, overflow: 'hidden' },
  header: { paddingLeft: 20, paddingTop: 12, paddingRight: 16, paddingBottom: 8 },
  headerTop: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerActions: { flexDirection: 'row', gap: 4 },
  followerRow: { flexDirection: 'row', alignItems: 'center', gap: 2 },
  helpButton: { width: 28, height: 28, alignItems: 'center', justifyContent: 'center' },
  helpBubble: { marginTop: 2, borderRadius: 10, paddingHorizontal: 10, paddingVertical: 8 },
  headerAction: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 22,
  },
  displayName: { marginTop: 10, fontWeight: '800' },
  scrollContent: { flexGrow: 1 },
  body: { paddingHorizontal: 12, paddingBottom: 8 },
  route: {
    minHeight: 59,
    paddingHorizontal: 8,
    paddingVertical: 9.5,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
  },
  compactRoute: { minHeight: 44, paddingVertical: 8 },
  footer: { borderTopWidth: StyleSheet.hairlineWidth, paddingHorizontal: 12, paddingVertical: 6 },
  pressed: { opacity: 0.72 },
  disabled: { opacity: 0.38 },
  rowRtl: { flexDirection: 'row-reverse' },
});
