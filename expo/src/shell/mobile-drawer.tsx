import { useEffect, useRef, useState, type ReactNode } from 'react';
import * as Linking from 'expo-linking';
import { Platform, Pressable, ScrollView, StyleSheet, View } from 'react-native';
import { SafeAreaView, type Edge } from 'react-native-safe-area-context';
import { Bot, CircleHelp, Goal, MessageCircle, UserPlus } from 'lucide-react-native';

import { DISCORD_BOT_INVITE_URL, DISCORD_URL } from '../core/config/api-config';
import type { MessageKey } from '../i18n';
import {
  filterEnabledRoutes,
  appRoutes,
  filterVisibleRoutes,
  isRouteEnabled,
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
  hasManagedDiscordBot = false,
  safeAreaEdges = ['top', 'right', 'bottom', 'left'],
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
  hasManagedDiscordBot?: boolean;
  safeAreaEdges?: Edge[];
}) {
  const theme = useCKTheme();
  // A narrow browser uses this drawer too. The embedded dashboard is native-only.
  const bodyRoutes = filterVisibleRoutes(mobileDrawerBodyRoutes, features).filter(
    (route) =>
      !['servers', 'esports'].includes(route.id) ||
      Platform.OS === 'ios' ||
      Platform.OS === 'android',
  );
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
    // Select the destination behind the drawer first. Deferring navigation
    // until the closing animation ends briefly reveals the previous page.
    onNavigate(route);
    onRequestClose();
  };
  const openExternal = (url: string) => {
    onRequestClose(() => {
      void Linking.openURL(url).catch(() => undefined);
    });
  };
  return (
    <SafeAreaView
      edges={safeAreaEdges}
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
        testID="mobile-drawer-scroll"
        bounces={false}
        alwaysBounceVertical={false}
        overScrollMode="never"
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
                onPress={() => {
                  onRequestClose();
                  onAchievements();
                }}
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
          <View style={styles.followerWrap}>
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
              <View
                pointerEvents="none"
                testID="drawer-followers-tooltip"
                style={[
                  styles.helpBubble,
                  isRtl ? styles.helpBubbleRtl : styles.helpBubbleLtr,
                  { backgroundColor: theme.surfaceContainerHighest },
                ]}
              >
                <CKText muted role="bodySmall">
                  {t('drawerFollowersHelp')}
                </CKText>
              </View>
            ) : null}
          </View>
        </View>
        <View style={styles.body}>
          {bodyRoutes.map((route) => (
            <DrawerRoute
              key={route.id}
              route={route}
              t={t}
              isRtl={isRtl}
              disabled={!isRouteEnabled(route, features)}
              onPress={() => navigate(route)}
            />
          ))}
        </View>
      </ScrollView>
      <View style={[styles.footer, { borderTopColor: colorWithAlpha(theme.outlineVariant, 0.2) }]}>
        <DrawerAction
          icon={<Bot color={theme.onSurface} size={18} />}
          label={t(hasManagedDiscordBot ? 'discordBotDashboard' : 'drawerInviteDiscordBot')}
          compact
          isRtl={isRtl}
          onPress={() => {
            if (Platform.OS === 'web') openExternal(DISCORD_BOT_INVITE_URL);
            else navigate(appRoutes.find((route) => route.id === 'servers')!);
          }}
          testID="drawer-discord-bot"
        />
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
        <DrawerAction
          icon={<MessageCircle color={theme.onSurface} size={18} />}
          label={t('faqJoinDiscord')}
          compact
          isRtl={isRtl}
          onPress={() => openExternal(DISCORD_URL)}
          testID="drawer-discord-server"
        />
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
    <DrawerAction
      icon={<RouteIcon route={route} color={theme.onSurface} size={compact ? 18 : 21} />}
      label={t(route.labelKey)}
      badge={route.comingSoon ? t('generalComingSoon') : undefined}
      onPress={onPress}
      compact={compact}
      disabled={disabled}
      isRtl={isRtl}
    />
  );
}

function DrawerAction({
  icon,
  label,
  onPress,
  compact = false,
  disabled = false,
  isRtl = false,
  testID,
  badge,
}: {
  icon: ReactNode;
  label: string;
  onPress: () => void;
  compact?: boolean;
  disabled?: boolean;
  isRtl?: boolean;
  testID?: string;
  badge?: string;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled }}
      disabled={disabled}
      onPress={onPress}
      testID={testID}
      style={({ pressed }) => [
        styles.route,
        isRtl && styles.rowRtl,
        compact && styles.compactRoute,
        disabled && styles.disabled,
        pressed && styles.pressed,
      ]}
    >
      {icon}
      <CKText
        role={compact ? 'bodyLarge' : 'titleMedium'}
        numberOfLines={1}
        style={{ fontWeight: compact ? '500' : '700', fontSize: compact ? 16 : 17 }}
      >
        {label}
      </CKText>
      {badge ? (
        <CKText role="labelSmall" muted style={{ marginLeft: 'auto' }}>
          {badge}
        </CKText>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  drawer: { flex: 1, overflow: 'hidden' },
  header: { paddingLeft: 20, paddingTop: 12, paddingRight: 16, paddingBottom: 8, zIndex: 2 },
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
  followerWrap: { position: 'relative' },
  helpButton: { width: 28, height: 28, alignItems: 'center', justifyContent: 'center' },
  helpBubble: {
    position: 'absolute',
    top: 30,
    width: '100%',
    maxWidth: 280,
    zIndex: 3,
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
    elevation: 8,
  },
  helpBubbleLtr: { left: 0 },
  helpBubbleRtl: { right: 0 },
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
    minHeight: 49,
    paddingHorizontal: 8,
    paddingVertical: 7,
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
