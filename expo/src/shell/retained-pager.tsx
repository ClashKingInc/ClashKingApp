import { useEffect, useRef, useState, type ReactNode } from 'react';
import { PrimarySwipeGuard } from '../ui/primary-swipe-guard';
import { useIsFocused } from 'expo-router';
import { StyleSheet, View } from 'react-native';

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
}: {
  selected: PrimaryRouteId;
  screens: PrimaryScreenSlots;
  onSelect: (route: PrimaryRouteId) => void;
  isRtl?: boolean;
  swipeEnabled?: boolean;
  visible?: boolean;
}) {
  const pager = useRef<PagerViewHandle>(null);
  const [widgetTouch, setWidgetTouch] = useState(false);
  const routeFocused = useIsFocused();
  // Android secondary pages are overlays rather than native routes. Route
  // focus alone therefore cannot tell us whether the pager is actually visible.
  const isFocused = routeFocused && visible;
  useEffect(() => {
    if (isFocused) return;
    const frame = requestAnimationFrame(() => setWidgetTouch(false));
    return () => cancelAnimationFrame(frame);
  }, [isFocused]);
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
      pendingIndex.current = selectedIndex;
      return;
    }
    if (returningToPager) {
      pendingIndex.current = selectedIndex;
      const frame = requestAnimationFrame(() => {
        nativeIsRtl.current = isRtl;
        nativeIndex.current = selectedIndex;
        pager.current?.setPageWithoutAnimation(selectedIndex);
      });
      return () => cancelAnimationFrame(frame);
    }
    if (nativeIsRtl.current !== isRtl) {
      pendingIndex.current = selectedIndex;
      nativeIsRtl.current = isRtl;
      nativeIndex.current = selectedIndex;
      pager.current?.setPageWithoutAnimation(selectedIndex);
      return;
    }
    if (nativeIndex.current === selectedIndex) return;
    pendingIndex.current = selectedIndex;
    nativeIndex.current = selectedIndex;
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

  return (
    <PrimarySwipeGuard.Provider value={setWidgetTouch}>
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
    </PrimarySwipeGuard.Provider>
  );
}

const styles = StyleSheet.create({
  pager: { flex: 1 },
  // PagerView requires one real native child per page and explicit dimensions;
  // flattened children or flex-only sizing can desync content from tab indices.
  page: { width: '100%', height: '100%' },
});
