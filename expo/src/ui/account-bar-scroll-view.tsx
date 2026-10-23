import { type ScrollViewInstance, Platform, ScrollView, type ScrollViewProps } from 'react-native';
import { forwardRef, useContext, useEffect, useMemo } from 'react';
import { Gesture, GestureDetector, type LegacyPanGesture } from 'react-native-gesture-handler';
import { DrawerGestureContext } from 'react-native-drawer-layout';
import { PrimaryPageGestureContext, usePrimarySwipeGuard } from './primary-swipe-guard';

/** Embedded horizontal scrolling wins over page navigation and drawer opening,
 * even at either end. Limit this recognizer to the strip/carousel itself so
 * touches elsewhere retain normal page swipes and Home hold-to-reorder. */
type HorizontalSwipeScrollViewProps = ScrollViewProps & {
  claimAndroidTouchOnStart?: boolean;
};

export const HorizontalSwipeScrollView = forwardRef<ScrollViewInstance, HorizontalSwipeScrollViewProps>(
  function HorizontalSwipeScrollView({ claimAndroidTouchOnStart = false, ...props }, ref) {
    const drawer = useContext(DrawerGestureContext) as unknown as LegacyPanGesture | undefined;
    const pager = useContext(PrimaryPageGestureContext);
    const guard = usePrimarySwipeGuard();
    useEffect(() => () => guard(false), [guard]);
    const gesture = useMemo(() => {
      const native = Gesture.Native().disallowInterruption(true);
      // Android's outer native pager can intercept before an inner scroll view
      // crosses its slop threshold. Carousels opt in to owning the stream from
      // DOWN; keep this scoped so other strips retain their existing behavior.
      if (Platform.OS === 'android' && claimAndroidTouchOnStart) native.shouldActivateOnStart(true);
      if (drawer) native.blocksExternalGesture(drawer);
      if (pager) native.blocksExternalGesture(pager);
      return native;
    }, [drawer, pager, claimAndroidTouchOnStart]);
    const content = (
      <ScrollView
        {...props}
        ref={ref}
        horizontal
        onTouchStart={(event) => {
          guard(true);
          props.onTouchStart?.(event);
        }}
        onTouchEnd={(event) => {
          guard(false);
          props.onTouchEnd?.(event);
        }}
        onTouchCancel={(event) => {
          guard(false);
          props.onTouchCancel?.(event);
        }}
      />
    );
    return Platform.OS === 'web' ? (
      content
    ) : (
      <GestureDetector gesture={gesture}>{content}</GestureDetector>
    );
  },
);

export const AccountBarScrollView = HorizontalSwipeScrollView;
