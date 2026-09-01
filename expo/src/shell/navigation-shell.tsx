import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react';
import { BackHandler, Platform, StyleSheet, View, useWindowDimensions } from 'react-native';
import ReanimatedDrawerLayout, {
  DrawerKeyboardDismissMode,
  DrawerLockMode,
  DrawerPosition,
  DrawerType,
  type DrawerLayoutMethods,
} from 'react-native-gesture-handler/ReanimatedDrawerLayout';

import type { MessageKey } from '../i18n';
import {
  appRoutes,
  type AppRouteDefinition,
  type AppRouteId,
  type FeatureState,
} from '../navigation';
import { useCKTheme } from '../ui';
import { DESKTOP_SIDEBAR_WIDTH, resolveMobileDrawerWidth, resolveShellLayout } from './contracts';
import { DesktopHeader } from './desktop-header';
import { DesktopSidebar } from './desktop-sidebar';
import { MobileDrawer } from './mobile-drawer';
import { MobileHeader } from './mobile-header';
import { PrimaryTabBar } from './primary-tab-bar';
import {
  RetainedPrimaryPager,
  type PrimaryRouteId,
  type PrimaryScreenSlots,
} from './retained-pager';

type Translate = (key: MessageKey) => string;

export interface NavigationShellProps {
  selectedPrimary: PrimaryRouteId;
  selectedUtility?: AppRouteId;
  /** A pushed detail can own the content pane without becoming a sidebar utility. */
  secondaryRouteId?: AppRouteId;
  primaryScreens: PrimaryScreenSlots;
  secondaryContent?: ReactNode;
  /** Android and web retain app-owned secondary scenes; iOS uses Expo Router's native stack. */
  secondaryLayers?: readonly { readonly key: string; readonly content: ReactNode }[];
  /** Flutter's global search route covers the complete desktop shell, including the sidebar. */
  secondaryFullScreen?: boolean;
  features: FeatureState;
  t: Translate;
  isRtl: boolean;
  avatar: ReactNode;
  displayName: string;
  followerCount: number | null;
  productLabel: string;
  hasUser: boolean;
  profileMenuLabel: string;
  closeDrawerLabel: string;
  onPrimarySelect: (route: PrimaryRouteId) => void;
  onUtilityNavigate: (route: AppRouteDefinition, options: { replace: boolean }) => void;
  onResetDesktopContent?: () => void;
  onSearch?: () => void;
  onAchievements: () => void;
  onAddAccount: () => void;
  onAccounts: () => void;
  viewportWidth?: number;
  platform?: string;
}

export function NavigationShell(props: NavigationShellProps) {
  const measured = useWindowDimensions().width;
  const width = props.viewportWidth ?? measured;
  const platform = props.platform ?? Platform.OS;
  return resolveShellLayout(platform, width) === 'desktop' ? (
    <DesktopNavigationShell {...props} width={width} />
  ) : (
    <MobileNavigationShell {...props} width={width} />
  );
}

function MobileNavigationShell(props: NavigationShellProps & { width: number }) {
  const theme = useCKTheme();
  const { isRtl, width } = props;
  const platform = props.platform ?? Platform.OS;
  const [drawerOpen, setDrawerOpen] = useState(false);
  const drawerRef = useRef<DrawerLayoutMethods>(null);
  const pendingDrawerAction = useRef<(() => void) | undefined>(undefined);
  const drawerEdgeWidth = 20;
  const drawerWidth = resolveMobileDrawerWidth(width);
  const secondaryLayers = props.secondaryLayers?.length
    ? props.secondaryLayers
    : props.secondaryContent
      ? [
          {
            key: `secondary:${props.secondaryRouteId ?? props.selectedUtility ?? 'content'}`,
            content: props.secondaryContent,
          },
        ]
      : [];
  const secondaryActive = Boolean(
    (props.secondaryRouteId ?? props.selectedUtility) && secondaryLayers.length,
  );
  // Retain the active scene and its immediate predecessor for an interactive pop. Older scene
  // descriptors stay in the app-owned stack, but their native image trees are unmounted until
  // they become the predecessor again, preventing deep navigation from retaining every decode.
  const mountedSecondaryLayers = secondaryLayers.slice(-2);
  const openDrawer = useCallback(() => {
    if (secondaryActive) return;
    drawerRef.current?.openDrawer();
  }, [secondaryActive]);
  const closeDrawer = useCallback((after?: () => void) => {
    pendingDrawerAction.current = after;
    if (drawerRef.current) drawerRef.current.closeDrawer();
    else {
      pendingDrawerAction.current = undefined;
      after?.();
    }
  }, []);
  const handleDrawerClose = useCallback(() => {
    setDrawerOpen(false);
    const pending = pendingDrawerAction.current;
    pendingDrawerAction.current = undefined;
    pending?.();
  }, []);
  useEffect(() => {
    if (!secondaryActive) return;
    pendingDrawerAction.current = undefined;
    drawerRef.current?.closeDrawer();
  }, [secondaryActive]);
  useEffect(() => {
    if (!drawerOpen || platform === 'web') return;
    const subscription = BackHandler.addEventListener('hardwareBackPress', () => {
      closeDrawer();
      return true;
    });
    return () => subscription.remove();
  }, [closeDrawer, drawerOpen, platform]);
  return (
    <ReanimatedDrawerLayout
      ref={drawerRef}
      animationSpeed={1}
      contentContainerStyle={styles.shell}
      drawerBackgroundColor="transparent"
      keyboardDismissMode={DrawerKeyboardDismissMode.ON_DRAG}
      drawerLockMode={secondaryActive ? DrawerLockMode.LOCKED_CLOSED : DrawerLockMode.UNLOCKED}
      drawerPosition={isRtl ? DrawerPosition.RIGHT : DrawerPosition.LEFT}
      drawerType={DrawerType.FRONT}
      drawerWidth={drawerWidth}
      edgeWidth={drawerEdgeWidth}
      hideStatusBar={false}
      minSwipeDistance={8}
      onDrawerClose={handleDrawerClose}
      onDrawerOpen={() => setDrawerOpen(true)}
      overlayColor="#00000066"
      renderNavigationView={() => (
        <MobileDrawer
          isRtl={props.isRtl}
          features={props.features}
          t={props.t}
          avatar={props.avatar}
          displayName={props.displayName}
          followerCount={props.followerCount}
          closeLabel={props.closeDrawerLabel}
          onRequestClose={closeDrawer}
          onNavigate={(route) => props.onUtilityNavigate(route, { replace: false })}
          onAchievements={props.onAchievements}
          onAddAccount={props.onAddAccount}
          hasUser={props.hasUser}
        />
      )}
    >
      <View
        style={[styles.shell, { backgroundColor: theme.background }]}
        testID={secondaryActive ? 'mobile-utility-shell' : 'mobile-navigation-shell'}
      >
        <View
          accessibilityElementsHidden={secondaryActive}
          importantForAccessibility={secondaryActive ? 'no-hide-descendants' : 'auto'}
          pointerEvents={secondaryActive ? 'none' : 'auto'}
          style={styles.shell}
          testID="retained-primary-shell"
        >
          <MobileHeader
            avatar={props.avatar}
            profileLabel={props.profileMenuLabel}
            searchHint={props.t('searchGlobalHint')}
            onOpenProfile={openDrawer}
            onSearch={props.onSearch}
            isRtl={props.isRtl}
          />
          <RetainedPrimaryPager
            selected={props.selectedPrimary}
            screens={props.primaryScreens}
            onSelect={props.onPrimarySelect}
            isRtl={props.isRtl}
            swipeEnabled={platformAllowsTabSwipe(props.platform)}
          />
          <View style={styles.tabBarOverlay}>
            <PrimaryTabBar
              selected={props.selectedPrimary}
              onSelect={props.onPrimarySelect}
              t={props.t}
              isRtl={props.isRtl}
            />
          </View>
        </View>
        {secondaryActive
          ? mountedSecondaryLayers.map((layer, index) => {
              const isTop = index === mountedSecondaryLayers.length - 1;
              return (
                <View
                  accessibilityElementsHidden={!isTop}
                  importantForAccessibility={isTop ? 'auto' : 'no-hide-descendants'}
                  key={layer.key}
                  pointerEvents={isTop ? 'auto' : 'none'}
                  style={[
                    styles.secondaryOverlay,
                    { backgroundColor: theme.background, zIndex: 4 + index },
                  ]}
                  testID={isTop ? 'mobile-secondary-overlay' : `mobile-secondary-underlay-${index}`}
                >
                  {layer.content}
                </View>
              );
            })
          : null}
      </View>
    </ReanimatedDrawerLayout>
  );
}

function DesktopNavigationShell(props: NavigationShellProps & { width: number }) {
  const theme = useCKTheme();
  const effectiveSecondary = props.secondaryRouteId ?? props.selectedUtility;
  const utilitySecondary =
    effectiveSecondary !== undefined &&
    !(['home', 'players', 'clans', 'war'] as const).includes(effectiveSecondary as PrimaryRouteId);
  const effectiveUtility = utilitySecondary ? effectiveSecondary : props.selectedUtility;
  const selectedDefinition = appRoutes.find(
    ({ id }) => id === (effectiveSecondary ?? props.selectedPrimary),
  );
  if (!selectedDefinition) throw new Error('NavigationShell selected an unknown route.');
  const selectPrimary = (route: PrimaryRouteId) => {
    props.onResetDesktopContent?.();
    props.onPrimarySelect(route);
  };
  return (
    <View
      style={[styles.desktopFrame, { backgroundColor: theme.background }]}
      testID="desktop-navigation-shell"
    >
      <View
        accessibilityElementsHidden={Boolean(props.secondaryFullScreen)}
        importantForAccessibility={props.secondaryFullScreen ? 'no-hide-descendants' : 'auto'}
        pointerEvents={props.secondaryFullScreen ? 'none' : 'auto'}
        style={[styles.desktopRow, props.isRtl && styles.desktopRowRtl]}
      >
        <DesktopSidebar
          selectedPrimary={utilitySecondary ? undefined : props.selectedPrimary}
          selectedUtility={effectiveUtility}
          features={props.features}
          t={props.t}
          avatar={props.avatar}
          displayName={props.displayName}
          productLabel={props.productLabel}
          hasUser={props.hasUser}
          onPrimary={selectPrimary}
          onUtility={(route, replace) => props.onUtilityNavigate(route, { replace })}
          isRtl={props.isRtl}
        />
        <View style={styles.desktopContent}>
          {!utilitySecondary ? (
            <DesktopHeader
              title={props.t(selectedDefinition.labelKey)}
              searchHint={props.t('searchGlobalHint')}
              achievementsLabel={props.t('achievementsTitle')}
              accountsLabel={props.t('drawerManageAccounts')}
              contentWidth={props.width - DESKTOP_SIDEBAR_WIDTH - StyleSheet.hairlineWidth}
              onSearch={props.onSearch}
              onAchievements={props.onAchievements}
              onAccounts={props.onAccounts}
              isRtl={props.isRtl}
            />
          ) : null}
          <View style={styles.desktopBody}>
            <View
              accessibilityElementsHidden={Boolean(props.secondaryRouteId ?? props.selectedUtility)}
              importantForAccessibility={
                (props.secondaryRouteId ?? props.selectedUtility) ? 'no-hide-descendants' : 'auto'
              }
              pointerEvents={(props.secondaryRouteId ?? props.selectedUtility) ? 'none' : 'auto'}
              style={styles.shell}
              testID="retained-primary-shell"
            >
              <RetainedPrimaryPager
                selected={props.selectedPrimary}
                screens={props.primaryScreens}
                onSelect={selectPrimary}
                swipeEnabled={false}
              />
            </View>
            {!props.secondaryFullScreen &&
            (props.secondaryRouteId ?? props.selectedUtility) &&
            props.secondaryContent ? (
              <View style={[styles.secondaryOverlay, { backgroundColor: theme.background }]}>
                {props.secondaryContent}
              </View>
            ) : null}
          </View>
        </View>
      </View>
      {props.secondaryFullScreen && props.secondaryContent ? (
        <View
          style={[styles.secondaryOverlay, { backgroundColor: theme.background }]}
          testID="desktop-fullscreen-secondary"
        >
          {props.secondaryContent}
        </View>
      ) : null}
    </View>
  );
}

function platformAllowsTabSwipe(platform?: string): boolean {
  return (platform ?? Platform.OS) !== 'web';
}

const styles = StyleSheet.create({
  shell: { flex: 1 },
  desktopFrame: { flex: 1, position: 'relative' },
  desktopRow: { flex: 1, flexDirection: 'row' },
  desktopRowRtl: { flexDirection: 'row-reverse' },
  desktopContent: { flex: 1 },
  desktopBody: { flex: 1, position: 'relative' },
  tabBarOverlay: { position: 'absolute', left: 0, right: 0, bottom: 0, zIndex: 2 },
  secondaryOverlay: { position: 'absolute', top: 0, right: 0, bottom: 0, left: 0, zIndex: 4 },
});
