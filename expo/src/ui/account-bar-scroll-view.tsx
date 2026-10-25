import { type ScrollViewInstance, Platform, ScrollView, type ScrollViewProps } from 'react-native';
import { forwardRef, useContext, useEffect, useMemo } from 'react';
import { Gesture, GestureDetector, type LegacyPanGesture } from 'react-native-gesture-handler';
import { DrawerGestureContext } from 'react-native-drawer-layout';
import { PrimaryPageGestureContext, usePrimarySwipeGuard } from './primary-swipe-guard';

/** Embedded horizontal scrolling wins over page navigation and drawer opening,
 * even at either end. Limit this recognizer to the strip/carousel itself so
 * touches elsewhere retain normal page swipes and Home hold-to-reorder. */
type HorizontalSwipeScrollViewProps = ScrollViewProps & {
  onNativeGestureFinalize?: () => void;
};

export const HorizontalSwipeScrollView = forwardRef<
  ScrollViewInstance,
  HorizontalSwipeScrollViewProps
>(function HorizontalSwipeScrollView({ onNativeGestureFinalize, ...props }, ref) {
  const drawer = useContext(DrawerGestureContext) as unknown as LegacyPanGesture | undefined;
  const pager = useContext(PrimaryPageGestureContext);
  const guard = usePrimarySwipeGuard();
  useEffect(() => () => guard(false), [guard]);
  const gesture = useMemo(() => {
    // A horizontal swipe may leave this short strip. Keep its native owner
    // until release, and report real cancellation separately from RN touch handoff.
    const native = Gesture.Native()
      .shouldCancelWhenOutside(false)
      .disallowInterruption(true)
      .onFinalize(() => onNativeGestureFinalize?.())
      .runOnJS(true);
    if (drawer) native.blocksExternalGesture(drawer);
    if (pager) native.blocksExternalGesture(pager);
    return native;
  }, [drawer, pager, onNativeGestureFinalize]);
  const content = (
    <ScrollView
      nestedScrollEnabled
      {...props}
      ref={ref}
      horizontal
      onTouchStart={(event) => {
        if (Platform.OS !== 'android') guard(true);
        props.onTouchStart?.(event);
      }}
      onTouchEnd={(event) => {
        if (Platform.OS !== 'android') guard(false);
        props.onTouchEnd?.(event);
      }}
      onTouchCancel={(event) => {
        if (Platform.OS !== 'android') guard(false);
        props.onTouchCancel?.(event);
      }}
    />
  );
  // Let the child cross its native scroll threshold before claiming the stream.
  // Eager activation steals events from Android's nested scrolling internals.
  return Platform.OS === 'web' ? (
    content
  ) : (
    <GestureDetector gesture={gesture}>{content}</GestureDetector>
  );
});

export const AccountBarScrollView = HorizontalSwipeScrollView;
