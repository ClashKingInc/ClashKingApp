import { useCallback, useEffect, useRef, useState, type ReactNode } from 'react';
import {
  Animated,
  BackHandler,
  Easing,
  Platform,
  StyleSheet,
  View,
  useWindowDimensions,
} from 'react-native';
import { Drawer } from 'react-native-drawer-layout';
import type { LegacyPanGesture as PanGesture } from 'react-native-gesture-handler';
import { ChevronLeft, ChevronRight } from 'lucide-react-native';

import { STORAGE_KEYS, type StringStorage } from '../core/storage/storage';
import type { MessageKey } from '../i18n';
import {
  appRoutes,
  type AppRouteDefinition,
  type AppRouteId,
  type FeatureState,
} from '../navigation';
import { colorWithAlpha, useCKAccessibility, useCKTheme } from '../ui';
import { DESKTOP_SIDEBAR_WIDTH, resolveMobileDrawerWidth, resolveShellLayout } from './contracts';
import { DesktopHeader } from './desktop-header';
import { DesktopSidebar } from './desktop-sidebar';
import { MobileDrawer } from './mobile-drawer';
import { MobileHeader } from './mobile-header';
import { tutorials } from '../features/tutorials/tutorial-service';
import { PrimaryTabBar } from './primary-tab-bar';
import {
  RetainedPrimaryPager,
  type PrimaryRouteId,
  type PrimaryScreenSlots,
} from './retained-pager';

type Translate = (key: MessageKey) => string;

// Native accessibility flags do not hide retained layers from browser focus.
// inert keeps background controls out of both keyboard and assistive navigation.
const hiddenWebLayer = (hidden: boolean) =>
  Platform.OS === 'web' ? { inert: hidden, 'aria-hidden': hidden } : {};

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
  hasManagedDiscordBot?: boolean;
  profileMenuLabel: string;
  closeDrawerLabel: string;
  drawerHintStore?: StringStorage;
  onPrimarySelect: (route: PrimaryRouteId) => void;
  onUtilityNavigate: (route: AppRouteDefinition, options: { replace: boolean }) => void;
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
  const [drawerHintVisible, setDrawerHintVisible] = useState(false);
  const pendingDrawerAction = useRef<(() => void) | undefined>(undefined);
  const allowsDrawerEdgeGesture = platformAllowsDrawerEdgeGesture(platform);
  const showsDrawerEdgeHint = platformShowsDrawerEdgeHint(platform);
  // Only Home opens by swipe. Other tabs use the profile button, so their
  // horizontal interactions cannot accidentally pull the sidebar open.
  const canSwipeOpenDrawer = allowsDrawerEdgeGesture && props.selectedPrimary === 'home';
  const drawerEdgeWidth = canSwipeOpenDrawer ? width : 0;
  const drawerWidth = resolveMobileDrawerWidth(width);
  const configureDrawerGesture = useCallback(
    (gesture: PanGesture) => {
      const openingDirection = isRtl ? -1 : 1;
      const direction = drawerOpen ? -openingDirection : openingDirection;
      // Reject the opposite direction before the native page swipe activates.
      // A one-sided activation threshold without this fail threshold leaves the
      // drawer waiting on page swipes and makes the two recognizers compete.
      return gesture
        .activeOffsetX(direction * 12)
        .failOffsetX(-direction * 8)
        .failOffsetY([-14, 14]);
    },
    [drawerOpen, isRtl],
  );
  // Replay this revised hint once in development without resetting production preferences.
  const hintStorageKey = __DEV__
    ? `${STORAGE_KEYS.mobileDrawerGestureHintSeen}_preview_v2`
    : STORAGE_KEYS.mobileDrawerGestureHintSeen;
  useEffect(() => {
    let current = true;
    if (!showsDrawerEdgeHint || !props.drawerHintStore) return;
    void props.drawerHintStore
      .getString(hintStorageKey)
      .then((seen) => {
        if (current) setDrawerHintVisible(seen !== 'true');
      })
      .catch(() => {
        // A discovery hint should never make navigation unavailable.
      });
    return () => {
      current = false;
    };
  }, [showsDrawerEdgeHint, props.drawerHintStore, hintStorageKey]);
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
    setDrawerOpen(true);
  }, [secondaryActive]);
  useEffect(() => tutorials.registerAction('open-sidebar', openDrawer), [openDrawer]);
  const closeDrawer = useCallback(
    (after?: () => void) => {
      pendingDrawerAction.current = after;
      if (drawerOpen) setDrawerOpen(false);
      else {
        pendingDrawerAction.current = undefined;
        after?.();
      }
    },
    [drawerOpen],
  );
  const handleDrawerClose = useCallback(() => {
    setDrawerOpen(false);
    const pending = pendingDrawerAction.current;
    pendingDrawerAction.current = undefined;
    pending?.();
  }, []);
  const handleDrawerOpen = useCallback(() => {
    tutorials.event('sidebar-opened');
    setDrawerOpen(true);
    setDrawerHintVisible(false);
    void props.drawerHintStore?.setString(hintStorageKey, 'true').catch(() => {
      // The drawer remains usable when persistence is unavailable.
    });
  }, [props.drawerHintStore, hintStorageKey]);
  useEffect(() => {
    if (platform !== 'web' || !drawerOpen) return;
    const dismiss = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        closeDrawer();
      }
    };
    window.addEventListener('keydown', dismiss);
    return () => window.removeEventListener('keydown', dismiss);
  }, [platform, drawerOpen, closeDrawer]);
  useEffect(() => {
    if (!secondaryActive) return;
    pendingDrawerAction.current = undefined;
    const frame = requestAnimationFrame(() => setDrawerOpen(false));
    return () => cancelAnimationFrame(frame);
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
    <Drawer
      open={drawerOpen}
      onOpen={() => setDrawerOpen(true)}
      onClose={() => setDrawerOpen(false)}
      onTransitionEnd={(closing) => (closing ? handleDrawerClose() : handleDrawerOpen())}
      style={styles.shell}
      drawerStyle={{ width: drawerWidth, backgroundColor: 'transparent' }}
      keyboardDismissMode="on-drag"
      swipeEnabled={!secondaryActive && (drawerOpen || canSwipeOpenDrawer)}
      // Drawer 4.x creates a legacy Gesture.Pan at runtime; Gesture Handler 3
      // renamed its public type without changing this builder's behavior.
      configureGestureHandler={configureDrawerGesture as unknown as React.ComponentProps<typeof Drawer>['configureGestureHandler']}
      direction={isRtl ? 'rtl' : 'ltr'}
      drawerPosition={isRtl ? 'right' : 'left'}
      drawerType="slide"
      swipeEdgeWidth={drawerEdgeWidth}
      hideStatusBarOnOpen={false}
      swipeMinDistance={40}
      overlayStyle={{ backgroundColor: '#00000066' }}
      overlayAccessibilityLabel={props.closeDrawerLabel}
      renderDrawerContent={() => (
        <View style={styles.shell} {...hiddenWebLayer(!drawerOpen)}>
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
            hasManagedDiscordBot={props.hasManagedDiscordBot}
          />
        </View>
      )}
    >
      <View
        style={[styles.shell, { backgroundColor: theme.background }]}
        testID={secondaryActive ? 'mobile-utility-shell' : 'mobile-navigation-shell'}
      >
        <View
          {...hiddenWebLayer(secondaryActive || drawerOpen)}
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
            visible={!secondaryActive && !drawerOpen}
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
          {showsDrawerEdgeHint && drawerHintVisible ? <DrawerEdgeHint isRtl={isRtl} /> : null}
        </View>
        {secondaryActive
          ? mountedSecondaryLayers.map((layer, index) => {
              const isTop = index === mountedSecondaryLayers.length - 1;
              return (
                <View
                  {...hiddenWebLayer(!isTop)}
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
    </Drawer>
  );
}

function DrawerEdgeHint({ isRtl }: { isRtl: boolean }) {
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const [progress] = useState(() => new Animated.Value(0));

  useEffect(() => {
    if (reduceMotion) {
      progress.setValue(0.45);
      return;
    }
    const animation = Animated.loop(
      Animated.sequence([
        Animated.timing(progress, {
          toValue: 1,
          duration: 700,
          easing: Easing.inOut(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.timing(progress, {
          toValue: 0,
          duration: 700,
          easing: Easing.inOut(Easing.quad),
          useNativeDriver: true,
        }),
        Animated.delay(900),
      ]),
      { iterations: 3 },
    );
    animation.start();
    return () => animation.stop();
  }, [progress, reduceMotion]);

  const translateX = progress.interpolate({
    inputRange: [0, 1],
    outputRange: isRtl ? [0, -5] : [0, 5],
  });
  return (
    <Animated.View
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      pointerEvents="none"
      style={[
        styles.drawerHint,
        isRtl ? styles.drawerHintRight : styles.drawerHintLeft,
        {
          backgroundColor: 'transparent',
          opacity: progress.interpolate({ inputRange: [0, 1], outputRange: [0.58, 0.9] }),
          transform: [{ translateX }],
        },
      ]}
      testID="mobile-drawer-gesture-hint"
    >
      <View
        style={[styles.drawerHintBar, { backgroundColor: colorWithAlpha(theme.onSurface, 0.5) }]}
      />
      {isRtl ? (
        <ChevronLeft color={theme.onSurfaceVariant} size={12} strokeWidth={2} />
      ) : (
        <ChevronRight color={theme.onSurfaceVariant} size={12} strokeWidth={2} />
      )}
    </Animated.View>
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
    // The primary-selection owner clears secondary scenes. Calling its Back
    // action first races an async browser popstate against the new selection.
    props.onPrimarySelect(route);
  };
  return (
    <View
      style={[styles.desktopFrame, { backgroundColor: theme.background }]}
      testID="desktop-navigation-shell"
    >
      <View
        {...hiddenWebLayer(Boolean(props.secondaryFullScreen))}
        accessibilityElementsHidden={Boolean(props.secondaryFullScreen)}
        importantForAccessibility={props.secondaryFullScreen ? 'no-hide-descendants' : 'auto'}
        pointerEvents={props.secondaryFullScreen ? 'none' : 'auto'}
        style={[styles.desktopRow, props.isRtl && styles.desktopRowRtl]}
      >
        <DesktopSidebar
          selectedPrimary={
            utilitySecondary
              ? undefined
              : ((effectiveSecondary ?? props.selectedPrimary) as PrimaryRouteId)
          }
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
              {...hiddenWebLayer(Boolean(props.secondaryRouteId ?? props.selectedUtility))}
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

function platformAllowsDrawerEdgeGesture(platform?: string): boolean {
  return (platform ?? Platform.OS) !== 'web';
}

function platformShowsDrawerEdgeHint(platform?: string): boolean {
  void platform;
  return false;
}

const styles = StyleSheet.create({
  shell: { flex: 1 },
  drawerHint: {
    position: 'absolute',
    top: '36%',
    zIndex: 3,
    width: 22,
    height: 44,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  drawerHintLeft: {
    left: 2,
    borderTopRightRadius: 14,
    borderBottomRightRadius: 14,
  },
  drawerHintRight: {
    right: 2,
    flexDirection: 'row-reverse',
    borderTopLeftRadius: 14,
    borderBottomLeftRadius: 14,
  },
  drawerHintBar: { height: 30, width: 3, borderRadius: 2 },
  desktopFrame: { flex: 1, position: 'relative' },
  desktopRow: { flex: 1, flexDirection: 'row' },
  desktopRowRtl: { flexDirection: 'row-reverse' },
  desktopContent: { flex: 1 },
  desktopBody: { flex: 1, position: 'relative' },
  tabBarOverlay: { position: 'absolute', left: 0, right: 0, bottom: 0, zIndex: 2 },
  secondaryOverlay: { position: 'absolute', top: 0, right: 0, bottom: 0, left: 0, zIndex: 4 },
});
