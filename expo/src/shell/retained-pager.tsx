import {
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import { PrimaryPageGestureContext, PrimarySwipeGuard } from '../ui/primary-swipe-guard';
import { useIsFocused } from 'expo-router';
import { Platform, StyleSheet, View } from 'react-native';
import { Gesture, GestureDetector, type LegacyPanGesture } from 'react-native-gesture-handler';
import { DrawerGestureContext } from 'react-native-drawer-layout';

import { primaryTabRoutes } from '../navigation';
import { PagerView, type PagerViewHandle, type PagerViewOnPageSelectedEvent } from '../ui/pager';

export type PrimaryRouteId = 'home' | 'players' | 'clans' | 'war';
export type PrimaryScreenSlots = Record<PrimaryRouteId, ReactNode>;

/** Native parity for Flutter's continuous, velocity-aware PageView. */
export function RetainedPrimaryPager({
  selected,
  screens,
  onSelect,
  isRtl = false,
  swipeEnabled = true,
  visible = true,
  onWidgetTouchChange,
}: {
  selected: PrimaryRouteId;
  screens: PrimaryScreenSlots;
  onSelect: (route: PrimaryRouteId) => void;
  isRtl?: boolean;
  swipeEnabled?: boolean;
  visible?: boolean;
  onWidgetTouchChange?: (blocked: boolean) => void;
}) {
  const pager = useRef<PagerViewHandle>(null);
  const drawerGesture = useContext(DrawerGestureContext) as unknown as LegacyPanGesture | undefined;
  const pageGesture = useMemo(() => {
    const gesture = Gesture.Native();
    // The drawer rejects the page direction immediately. Simultaneous native
    // recognition lets the other direction open the drawer at Home's boundary.
    if (drawerGesture) gesture.simultaneousWithExternalGesture(drawerGesture);
    return gesture;
  }, [drawerGesture]);
  const [widgetTouch, setWidgetTouch] = useState(false);
  const handleWidgetTouch = useCallback(
    (blocked: boolean) => {
      setWidgetTouch(blocked);
      onWidgetTouchChange?.(blocked);
    },
    [onWidgetTouchChange],
  );
  const routeFocused = useIsFocused();
  useEffect(() => {
    // A tab change can detach the touched account bar before touch-end arrives.
    // Its old guard must not disable Home's drawer when returning to that tab.
    const frame = requestAnimationFrame(() => handleWidgetTouch(false));
    return () => cancelAnimationFrame(frame);
  }, [selected, handleWidgetTouch]);
  // Android secondary pages are overlays rather than native routes. Route
  // focus alone therefore cannot tell us whether the pager is actually visible.
  const isFocused = routeFocused && visible;
  useEffect(() => {
    if (isFocused) return;
    const frame = requestAnimationFrame(() => handleWidgetTouch(false));
    return () => cancelAnimationFrame(frame);
  }, [isFocused, handleWidgetTouch]);
  const wasFocused = useRef(isFocused);
  const selectedIndex = primaryTabRoutes.findIndex(({ id }) => id === selected);
  const nativeIndex = useRef(selectedIndex);
  const pendingIndex = useRef<number | null>(null);
  const nativeIsRtl = useRef(isRtl);

  useEffect(() => {
    const returningToPager = isFocused && !wasFocused.current;
    wasFocused.current = isFocused;
    // Android can drop pager commands while a native detail route covers it.
    // Defer tab changes until Home's shell is attached again, then reconcile
    // without animation. Never treat a command sent off-screen as confirmation.
    if (!isFocused) {
      pendingIndex.current = nativeIndex.current === selectedIndex ? null : selectedIndex;
      return;
    }
    if (returningToPager) {
      // A no-op resync may not emit onPageSelected on either native platform.
      // Never leave a pending target for the page we already observed: it would
      // reject the next genuine swipe forever if that no-op emits no event.
      pendingIndex.current = nativeIndex.current === selectedIndex ? null : selectedIndex;
      const frame = requestAnimationFrame(() => {
        nativeIsRtl.current = isRtl;
        pager.current?.setPageWithoutAnimation(selectedIndex);
      });
      return () => cancelAnimationFrame(frame);
    }
    if (nativeIsRtl.current !== isRtl) {
      pendingIndex.current = nativeIndex.current === selectedIndex ? null : selectedIndex;
      nativeIsRtl.current = isRtl;
      pager.current?.setPageWithoutAnimation(selectedIndex);
      return;
    }
    if (nativeIndex.current === selectedIndex) {
      pendingIndex.current = null;
      return;
    }
    if (pendingIndex.current === selectedIndex) return;
    pendingIndex.current = selectedIndex;
    pager.current?.setPage(selectedIndex);
  }, [isFocused, isRtl, selectedIndex]);

  const handlePageSelected = (event: PagerViewOnPageSelectedEvent) => {
    // A detached pager may emit its old page while Settings is closing. That
    // event must not overwrite the Players/Clans destination the user chose.
    if (!isFocused) return;
    const index = event.nativeEvent.position;
    if (pendingIndex.current !== null && pendingIndex.current !== index) return;
    pendingIndex.current = null;
    nativeIndex.current = index;
    const route = primaryTabRoutes[index];
    if (route && route.id !== selected) onSelect(route.id as PrimaryRouteId);
  };

  const content = (
    <PagerView
      initialPage={selectedIndex}
      keyboardDismissMode="none"
      layoutDirection={isRtl ? 'rtl' : 'ltr'}
      offscreenPageLimit={1}
      onPageSelected={handlePageSelected}
      orientation="horizontal"
      overdrag={false}
      overScrollMode="never"
      ref={pager}
      scrollEnabled={swipeEnabled && !widgetTouch}
      style={styles.pager}
      testID="native-primary-pager"
    >
      {primaryTabRoutes.map((route) => {
        const id = route.id as PrimaryRouteId;
        const active = id === selected;
        return (
          <View
            collapsable={false}
            accessibilityElementsHidden={!active}
            importantForAccessibility={active ? 'auto' : 'no-hide-descendants'}
            key={id}
            style={styles.page}
            testID={`primary-page-${id}`}
          >
            {screens[id]}
          </View>
        );
      })}
    </PagerView>
  );
  return (
    <PrimarySwipeGuard.Provider value={handleWidgetTouch}>
      <PrimaryPageGestureContext.Provider value={pageGesture}>
        {Platform.OS === 'web' ? (
          content
        ) : (
          <GestureDetector gesture={pageGesture}>{content}</GestureDetector>
        )}
      </PrimaryPageGestureContext.Provider>
    </PrimarySwipeGuard.Provider>
  );
}

const styles = StyleSheet.create({
  pager: { flex: 1 },
  // PagerView requires one real native child per page and explicit dimensions;
  // flattened children or flex-only sizing can desync content from tab indices.
  page: { width: '100%', height: '100%' },
});
