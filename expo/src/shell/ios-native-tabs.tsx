import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { StyleSheet, View, useWindowDimensions } from 'react-native';
import { Drawer } from 'react-native-drawer-layout';
import type { LegacyPanGesture as PanGesture } from 'react-native-gesture-handler';
import { useIsFocused } from 'expo-router';
import { NativeTabs } from 'expo-router/native-tabs';
import ClashKingNative from '@clashking/native';
import {
  SafeAreaView,
  SafeAreaInsetsContext,
  useSafeAreaInsets,
  type EdgeInsets,
} from 'react-native-safe-area-context';

import { primaryTabRoutes } from '../navigation';
import { NativePrimaryNavigation } from '../ui/native-primary-navigation';
import { useAdaptiveLayout } from '../ui/adaptive-layout';
import { useCKTheme } from '../ui';
import { MobileDrawer } from './mobile-drawer';
import { registerDuoNavigationActions } from './duo-navigation-actions';
import { MobileHeader } from './mobile-header';
import { ReservedRegionLayout } from '../ui/reserved-region-layout';
import { useDuoPortraitBottomBar } from './duo-navigation-mode';
import { PrimaryTabBar } from './primary-tab-bar';
import type { NavigationShellProps } from './navigation-shell';
import type { PrimaryRouteId } from './retained-pager';

type IosTabsContextValue = NavigationShellProps & {
  openDrawer: () => void;
  shellInsets: EdgeInsets;
};
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
  const shellInsets = useSafeAreaInsets();
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const portraitBottomBar = useDuoPortraitBottomBar();
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
    // close must not erase the destination queued for the drawer's closing transition.
    if (after) afterDismiss.current = after;
    setDrawerOpen(false);
  }, []);
  const configureDrawerGesture = useCallback(
    (gesture: PanGesture) => {
      const direction = (props.isRtl ? -1 : 1) * (drawerOpen ? -1 : 1);
      return gesture
        .activeOffsetX(direction * 12)
        .failOffsetX(-direction * 8)
        .failOffsetY([-14, 14]);
    },
    [drawerOpen, props.isRtl],
  );
  useEffect(
    () => registerDuoNavigationActions({ select: props.onPrimarySelect }),
    [props.onPrimarySelect],
  );

  return (
    <NativePrimaryNavigation.Provider value={!portraitBottomBar}>
      <IosTabsContext.Provider value={{ ...props, openDrawer, shellInsets }}>
        {/* Keep UIKit tabs inside the sliding surface so the whole page follows
            the finger. A Modal here turns the drawer into an unrelated overlay. */}
        <Drawer
          open={drawerOpen}
          onOpen={() => setDrawerOpen(true)}
          onClose={() => setDrawerOpen(false)}
          onTransitionEnd={(closing) => {
            if (!closing) return;
            const action = afterDismiss.current;
            afterDismiss.current = undefined;
            action?.();
          }}
          style={{ flex: 1 }}
          drawerType="slide"
          drawerPosition={props.isRtl ? 'right' : 'left'}
          direction={props.isRtl ? 'rtl' : 'ltr'}
          drawerStyle={{
            width: Math.min(width * 0.88, layout.isDuo || layout.isExpanded ? 320 : 400),
            backgroundColor: theme.background,
          }}
          swipeEnabled={!props.searchOverlay && (drawerOpen || props.selectedPrimary === 'home')}
          // Home's entire surface opens the drawer. Inner account/event rails
          // retain priority through explicit native recognizer relationships.
          swipeEdgeWidth={props.selectedPrimary === 'home' ? width : 0}
          swipeMinDistance={40}
          configureGestureHandler={
            configureDrawerGesture as unknown as React.ComponentProps<
              typeof Drawer
            >['configureGestureHandler']
          }
          keyboardDismissMode="on-drag"
          hideStatusBarOnOpen={false}
          overlayStyle={{ backgroundColor: '#00000066' }}
          overlayAccessibilityLabel={props.closeDrawerLabel}
          renderDrawerContent={() => (
            <MobileDrawer
              isRtl={props.isRtl}
              safeAreaEdges={['top', 'bottom', props.isRtl ? 'right' : 'left']}
              features={props.features}
              t={props.t}
              avatar={props.sidebarAvatar ?? props.avatar}
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
              isDiscordCommunityMember={props.isDiscordCommunityMember}
            />
          )}
        >
          <View style={{ flex: 1 }}>
            <View
              style={{ flex: 1 }}
              pointerEvents={props.searchOverlay ? 'none' : 'auto'}
              accessibilityElementsHidden={Boolean(props.searchOverlay)}
            >
              <NativeTabs
                tintColor={theme.primary}
                minimizeBehavior="never"
                sidebarAdaptable={false}
                hidden={
                  portraitBottomBar || props.hidePrimaryNavigation || Boolean(props.searchOverlay)
                }
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
                    <NativeTabs.Trigger.Label hidden>
                      {props.t(route.labelKey)}
                    </NativeTabs.Trigger.Label>
                    <NativeTabs.Trigger.Icon xcasset={icons[route.id as PrimaryRouteId]} />
                  </NativeTabs.Trigger>
                ))}
              </NativeTabs>
            </View>
            {props.searchOverlay ? (
              <View style={StyleSheet.absoluteFill}>{props.searchOverlay}</View>
            ) : null}
          </View>
        </Drawer>
      </IosTabsContext.Provider>
    </NativePrimaryNavigation.Provider>
  );
}

export function IosPrimaryPage({ route }: { route: PrimaryRouteId }) {
  const context = useContext(IosTabsContext);
  const pageInsets = useSafeAreaInsets();
  const layout = useAdaptiveLayout();
  const portraitBottomBar = useDuoPortraitBottomBar();
  const focused = useIsFocused();
  const onFocus = context?.onNativePrimaryFocus;
  useEffect(() => {
    if (focused) onFocus?.(route);
  }, [focused, route, onFocus]);
  if (!context) return null; // Android renders its retained pager from the group layout.
  // NativeTabs mounts a separate safe-area provider for each screen. During
  // its first custom slide the destination can briefly report top=0. Ordinary
  // iPhone tabs share the shell status bar, so use its stable top inset while
  // preserving local bottom insets for the tab bar. Duo owns per-pane insets.
  const stableInsets = layout.isDuo ? pageInsets : { ...pageInsets, top: context.shellInsets.top };
  return (
    <SafeAreaInsetsContext.Provider value={stableInsets}>
      <ReservedRegionLayout>
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
      </ReservedRegionLayout>
    </SafeAreaInsetsContext.Provider>
  );
}
const styles = StyleSheet.create({
  portraitBar: { position: 'absolute', left: 0, right: 0, bottom: 0 },
  page: { flex: 1 },
});
