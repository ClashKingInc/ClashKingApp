import { useCallback, useRef, useState } from 'react';
import {
  Platform,
  StyleSheet,
  View,
  type NativeScrollEvent,
  type NativeSyntheticEvent,
} from 'react-native';

import { CKText } from './text';
import { useCKTheme } from './theme';

// Only occupy the empty iOS overscroll area, before the native refresh control takes over.
export function usePullRefreshHint() {
  const dragging = useRef(false);
  const [distance, setDistance] = useState(0);
  const onScrollOffsetChange = useCallback((offset: number) => {
    const pull = Math.max(0, -offset);
    setDistance(Platform.OS === 'ios' && dragging.current && pull >= 24 && pull < 60 ? pull : 0);
  }, []);
  const onScroll = useCallback(
    (event: NativeSyntheticEvent<NativeScrollEvent>) => {
      onScrollOffsetChange(event.nativeEvent.contentOffset.y);
    },
    [onScrollOffsetChange],
  );
  const onScrollBeginDrag = useCallback(() => {
    dragging.current = true;
  }, []);
  const onScrollEndDrag = useCallback(() => {
    dragging.current = false;
    setDistance(0);
  }, []);
  return { distance, onScroll, onScrollOffsetChange, onScrollBeginDrag, onScrollEndDrag };
}

export function PullRefreshHint({
  distance,
  refreshing,
  label,
}: {
  distance: number;
  refreshing: boolean;
  label: string | undefined;
}) {
  const theme = useCKTheme();
  if (!label || refreshing || distance === 0) return null;
  return (
    <View
      testID="pull-refresh-hint"
      pointerEvents="none"
      style={[styles.hint, { height: distance, backgroundColor: theme.background }]}
    >
      <CKText role="bodySmall" muted numberOfLines={1}>
        {label}
      </CKText>
    </View>
  );
}

const styles = StyleSheet.create({
  hint: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    zIndex: 1,
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 16,
  },
});
