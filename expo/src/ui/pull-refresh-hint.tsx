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

type PullRefreshHintOptions = {
  readonly onRefresh?: () => void;
  readonly refreshing?: boolean;
  readonly releaseThreshold?: number;
  readonly showOnAndroid?: boolean;
};

// Only occupy the empty iOS overscroll area, before the native refresh control takes over.
export function usePullRefreshHint(options: PullRefreshHintOptions = {}) {
  const { onRefresh, refreshing = false, releaseThreshold = 72, showOnAndroid = false } = options;
  const dragging = useRef(false);
  const pullDistance = useRef(0);
  const [distance, setDistance] = useState(0);
  const onScrollOffsetChange = useCallback(
    (offset: number) => {
      const pull = Math.max(0, -offset);
      pullDistance.current = pull;
      const showsHint = Platform.OS === 'ios' || showOnAndroid;
      setDistance(
        !refreshing && showsHint && dragging.current && pull >= 24
          ? Math.min(pull, releaseThreshold)
          : 0,
      );
    },
    [refreshing, releaseThreshold, showOnAndroid],
  );
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
    const shouldRefresh = !refreshing && pullDistance.current >= releaseThreshold;
    dragging.current = false;
    pullDistance.current = 0;
    setDistance(0);
    if (shouldRefresh) onRefresh?.();
  }, [onRefresh, refreshing, releaseThreshold]);
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
