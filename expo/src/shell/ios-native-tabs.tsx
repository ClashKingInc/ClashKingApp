import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { Modal, Pressable, StyleSheet, View, useWindowDimensions } from 'react-native';
import { useIsFocused } from 'expo-router';
import { NativeTabs } from 'expo-router/native-tabs';
import ClashKingNative from '@clashking/native';
import { useHinge } from 'expo-hinge';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';

import { primaryTabRoutes } from '../navigation';
import { modalOrientations as defaultModalOrientations } from '../ui/modal-orientations';
import { NativePrimaryNavigation } from '../ui/native-primary-navigation';
import { useAdaptiveLayout } from '../ui/adaptive-layout';
import { PrimaryPageGestureContext } from '../ui/primary-swipe-guard';
import { useCKTheme } from '../ui';
import { MobileDrawer } from './mobile-drawer';
import { registerDuoNavigationActions } from './duo-navigation-actions';
import { MobileHeader } from './mobile-header';
import { ReservedRegionLayout } from '../ui/reserved-region-layout';
import { useDuoPortraitBottomBar } from './duo-navigation-mode';
import { PrimaryTabBar } from './primary-tab-bar';
import type { NavigationShellProps } from './navigation-shell';
import type { PrimaryRouteId } from './retained-pager';

type IosTabsContextValue = NavigationShellProps & { openDrawer: () => void };
const IosTabsContext = createContext<IosTabsContextValue | null>(null);
function reconcileNativeBar() {
  // A missing method means an older development binary. The native guard also
  // checks the zero-height UIKit host, which frame conversion alone can miss.
  return ClashKingNative.reconcileNativeTabBar?.().catch(() => false);
}
// UIImage templates use the same 22-point Lucide artwork as the retained bar.
// The selected variants preserve its filled Home/Players/Clans treatment.
const icons = {
  home: { default: 'CKTabHome', selected: 'CKTabHomeSelected' },
  players: { default: 'CKTabPlayers', selected: 'CKTabPlayersSelected' },
  clans: { default: 'CKTabClans', selected: 'CKTabClansSelected' },
  war: { default: 'CKTabWar', selected: 'CKTabWarSelected' },
};

/** The file routes share one authenticated controller; UIKit owns tab placement. */
export function IosNativeTabs(props: NavigationShellProps) {
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const portraitBottomBar = useDuoPortraitBottomBar();
  const hinge = useHinge();
  const [hasHinge, setHasHinge] = useState(hinge !== null);
  if (hinge !== null && !hasHinge) setHasHinge(true);
  // Keep this sheet in the current Duo orientation, including when hinge
  // updates briefly disappear while the window moves between displays.
  const modalOrientations = hasHinge
    ? (['portrait', 'landscape-left', 'landscape-right'] as (
        'portrait' | 'landscape-left' | 'landscape-right'
      )[])
    : defaultModalOrientations;
  const { width } = useWindowDimensions();
  const [drawerOpen, setDrawerOpen] = useState(false);
  const afterDismiss = useRef<(() => void) | undefined>(undefined);
  useEffect(() => {
    let cancelled = false;
    let timer: ReturnType<typeof setTimeout> | undefined;
    const reconcile = async (attempt: number) => {
      const ready = await reconcileNativeBar();
      if (!ready && !cancelled && attempt < 5)
        timer = setTimeout(() => void reconcile(attempt + 1), 100);
    };
    const frame = requestAnimationFrame(() => {
      void reconcile(0);
    });
    return () => {
      cancelled = true;
      cancelAnimationFrame(frame);
      clearTimeout(timer);
    };
  }, [width]);
  const openDrawer = useCallback(() => setDrawerOpen(true), []);
  const closeDrawer = useCallback((after?: () => void) => {
    // MobileDrawer also requests close after selecting a route. That second
    // close must not erase the destination queued for the modal's dismissal.
    if (after) afterDismiss.current = after;
    setDrawerOpen(false);
  }, []);
  const dismissSwipe = useMemo(
    () =>
      Gesture.Pan()
        .activeOffsetX(props.isRtl ? 24 : -24)
        .failOffsetY([-16, 16])
        .runOnJS(true)
        .onStart(() => setDrawerOpen(false)),
    [props.isRtl],
  );
  useEffect(
    () => registerDuoNavigationActions({ select: props.onPrimarySelect }),
    [props.onPrimarySelect],
  );

  return (
    <NativePrimaryNavigation.Provider value={!portraitBottomBar}>
      <IosTabsContext.Provider value={{ ...props, openDrawer }}>
        <NativeTabs
          tintColor={theme.primary}
          minimizeBehavior="never"
          sidebarAdaptable={false}
          hidden={portraitBottomBar || props.hidePrimaryNavigation}
          disableHiddenAnimation
        >
          {primaryTabRoutes.map((route) => (
            <NativeTabs.Trigger
              key={route.id}
              name={route.id === 'home' ? 'index' : route.id}
              disableAutomaticContentInsets
              testID={`primary-tab-${route.id}`}
              accessibilityLabel={props.t(route.labelKey)}
            >
              <NativeTabs.Trigger.Label hidden>{props.t(route.labelKey)}</NativeTabs.Trigger.Label>
              <NativeTabs.Trigger.Icon xcasset={icons[route.id as PrimaryRouteId]} />
            </NativeTabs.Trigger>
          ))}
        </NativeTabs>
        <Modal
          supportedOrientations={modalOrientations}
          transparent
          visible={drawerOpen}
          animationType="fade"
          onRequestClose={() => closeDrawer()}
          onDismiss={() => {
            const action = afterDismiss.current;
            afterDismiss.current = undefined;
            action?.();
          }}
        >
          <SafeAreaProvider>
            <GestureDetector gesture={dismissSwipe}>
              <View style={styles.modal}>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={props.closeDrawerLabel}
                  onPress={() => closeDrawer()}
                  style={StyleSheet.absoluteFill}
                />
                <View
                  style={{
                    // A tablet-width window should not turn this menu into a full pane.
                    width: Math.min(width * 0.88, layout.isDuo || layout.isExpanded ? 320 : 400),
                    flex: 1,
                    alignSelf: props.isRtl ? 'flex-end' : 'flex-start',
                    backgroundColor: theme.background,
                  }}
                >
                  <MobileDrawer
                    isRtl={props.isRtl}
                    // Only the drawer's physical outside edge touches the screen.
                    // Applying the opposite rail inset here compresses its icons.
                    safeAreaEdges={['top', 'bottom', props.isRtl ? 'right' : 'left']}
                    features={props.features}
                    t={props.t}
                    avatar={props.avatar}
                    displayName={props.displayName}
                    followerCount={props.followerCount}
                    closeLabel={props.closeDrawerLabel}
                    onRequestClose={closeDrawer}
                    onNavigate={(route) =>
                      closeDrawer(() => props.onUtilityNavigate(route, { replace: false }))
                    }
                    onAchievements={props.onAchievements}
                    onAddAccount={props.onAddAccount}
                    hasUser={props.hasUser}
                    hasManagedDiscordBot={props.hasManagedDiscordBot}
                  />
                </View>
              </View>
            </GestureDetector>
          </SafeAreaProvider>
        </Modal>
      </IosTabsContext.Provider>
    </NativePrimaryNavigation.Provider>
  );
}

export function IosPrimaryPage({ route }: { route: PrimaryRouteId }) {
  const context = useContext(IosTabsContext);
  const layout = useAdaptiveLayout();
  const portraitBottomBar = useDuoPortraitBottomBar();
  const focused = useIsFocused();
  const onFocus = context?.onNativePrimaryFocus;
  useEffect(() => {
    if (focused) onFocus?.(route);
  }, [focused, route, onFocus]);
  const openDrawer = context?.openDrawer;
  const isRtl = context?.isRtl ?? false;
  // Claim only a narrow leading-edge drag. Embedded event/account strips keep
  // horizontal gestures elsewhere, and vertical scrolling can fail this pan.
  const openSwipe = useMemo(
    () =>
      Gesture.Pan()
        .enabled(route === 'home')
        .hitSlop(isRtl ? { right: 0, width: 24 } : { left: 0, width: 24 })
        .activeOffsetX(isRtl ? -24 : 24)
        .failOffsetY([-16, 16])
        .runOnJS(true)
        .onStart(() => openDrawer?.()),
    [isRtl, openDrawer, route],
  );
  const selectPrimary = context?.onPrimarySelect;
  const pageSwipe = useMemo(
    () =>
      Gesture.Pan()
        .activeOffsetX([-28, 28])
        .failOffsetY([-18, 18])
        .runOnJS(true)
        .onEnd((event) => {
          if (Math.abs(event.translationX) < 60 && Math.abs(event.velocityX) < 500) return;
          const direction = (event.translationX < 0 ? 1 : -1) * (isRtl ? -1 : 1);
          const next =
            primaryTabRoutes[primaryTabRoutes.findIndex((item) => item.id === route) + direction];
          if (next) selectPrimary?.(next.id as PrimaryRouteId);
          else if (route === 'home' && direction < 0) openDrawer?.();
        }),
    [route, isRtl, selectPrimary, openDrawer],
  );
  const navigationGesture = useMemo(
    () => Gesture.Race(openSwipe, pageSwipe),
    [openSwipe, pageSwipe],
  );
  if (!context) return null; // Android renders its retained pager from the group layout.
  return (
    <PrimaryPageGestureContext.Provider value={pageSwipe}>
      <ReservedRegionLayout>
        <GestureDetector gesture={navigationGesture}>
          <View
            style={styles.page}
            collapsable={false}
            onLayout={() => {
              void reconcileNativeBar();
            }}
            testID={`native-primary-${route}`}
          >
            <SafeAreaView edges={['left', 'right']}>
              <MobileHeader
                avatar={context.avatar}
                profileLabel={context.profileMenuLabel}
                searchHint={context.t('searchGlobalHint')}
                onOpenProfile={context.openDrawer}
                onSearch={context.onSearch}
                isRtl={context.isRtl}
                // The compact Duo's native SafeAreaView already removes its
                // status rail. A percentage-width header resolves against the
                // outer width and can extend back into that rail; let it stretch
                // inside the safe content box instead. Other devices retain
                // their existing width calculation.
                maxContentWidth={
                  layout.isDuo && !layout.isExpanded ? undefined : layout.contentMaxWidth
                }
                searchMaxWidth={layout.isExpanded ? 360 : undefined}
                alignSearchToEnd={layout.isExpanded}
              />
            </SafeAreaView>
            {context.primaryScreens[route]}
            {portraitBottomBar ? (
              <View style={styles.portraitBar} testID="duo-portrait-bottom-bar">
                <PrimaryTabBar
                  selected={context.selectedPrimary}
                  onSelect={context.onPrimarySelect}
                  t={context.t}
                  isRtl={context.isRtl}
                />
              </View>
            ) : null}
          </View>
        </GestureDetector>
      </ReservedRegionLayout>
    </PrimaryPageGestureContext.Provider>
  );
}
const styles = StyleSheet.create({
  portraitBar: { position: 'absolute', left: 0, right: 0, bottom: 0 },
  page: { flex: 1 },
  modal: { flex: 1, backgroundColor: '#00000066' },
});
