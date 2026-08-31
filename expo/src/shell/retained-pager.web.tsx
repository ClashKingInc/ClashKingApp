import { useEffect, useState, type ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';

import { primaryTabRoutes } from '../navigation';

export type PrimaryRouteId = 'home' | 'players' | 'clans' | 'war';
export type PrimaryScreenSlots = Record<PrimaryRouteId, ReactNode>;

/** Flutter web uses a retained IndexedStack and deliberately has no tab swipe. */
export function RetainedPrimaryPager({
  selected,
  screens,
}: {
  selected: PrimaryRouteId;
  screens: PrimaryScreenSlots;
  onSelect: (route: PrimaryRouteId) => void;
  isRtl?: boolean;
  swipeEnabled?: boolean;
}) {
  const [visited, setVisited] = useState<ReadonlySet<PrimaryRouteId>>(() => new Set([selected]));

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    setVisited((current) => (current.has(selected) ? current : new Set([...current, selected])));
  }, [selected]);

  return (
    <View style={styles.pager}>
      {primaryTabRoutes.map((route) => {
        const id = route.id as PrimaryRouteId;
        const active = id === selected;
        if (!active && !visited.has(id)) return null;
        return (
          <View
            accessibilityElementsHidden={!active}
            importantForAccessibility={active ? 'auto' : 'no-hide-descendants'}
            key={id}
            style={[styles.page, !active && styles.hidden]}
            testID={`primary-page-${id}`}
          >
            {screens[id]}
          </View>
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  pager: { flex: 1, overflow: 'hidden' },
  page: StyleSheet.absoluteFill,
  hidden: { display: 'none' },
});
