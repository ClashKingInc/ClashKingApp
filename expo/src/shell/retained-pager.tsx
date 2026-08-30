import { useEffect, useRef, type ReactNode } from 'react';
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
}: {
  selected: PrimaryRouteId;
  screens: PrimaryScreenSlots;
  onSelect: (route: PrimaryRouteId) => void;
  isRtl?: boolean;
  swipeEnabled?: boolean;
}) {
  const pager = useRef<PagerViewHandle>(null);
  const selectedIndex = primaryTabRoutes.findIndex(({ id }) => id === selected);
  const nativeIndex = useRef(selectedIndex);
  const nativeIsRtl = useRef(isRtl);

  useEffect(() => {
    if (nativeIsRtl.current !== isRtl) {
      nativeIsRtl.current = isRtl;
      nativeIndex.current = selectedIndex;
      pager.current?.setPageWithoutAnimation(selectedIndex);
      return;
    }
    if (nativeIndex.current === selectedIndex) return;
    nativeIndex.current = selectedIndex;
    pager.current?.setPage(selectedIndex);
  }, [isRtl, selectedIndex]);

  const handlePageSelected = (event: PagerViewOnPageSelectedEvent) => {
    const index = event.nativeEvent.position;
    nativeIndex.current = index;
    const route = primaryTabRoutes[index];
    if (route && route.id !== selected) onSelect(route.id as PrimaryRouteId);
  };

  return (
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
      scrollEnabled={swipeEnabled}
      style={styles.pager}
      testID="native-primary-pager"
    >
      {primaryTabRoutes.map((route) => {
        const id = route.id as PrimaryRouteId;
        const active = id === selected;
        return (
          <View
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
}

const styles = StyleSheet.create({
  pager: { flex: 1 },
  page: { flex: 1 },
});
