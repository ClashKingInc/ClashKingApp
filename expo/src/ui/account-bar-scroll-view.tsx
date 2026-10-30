import { type ScrollViewInstance, Platform, ScrollView, type ScrollViewProps } from 'react-native';
import { forwardRef, useContext, useEffect, useMemo, useRef } from 'react';
import { Gesture, GestureDetector, type LegacyPanGesture } from 'react-native-gesture-handler';
import { DrawerGestureContext } from 'react-native-drawer-layout';
import { PrimaryPageGestureContext, usePrimarySwipeGuard } from './primary-swipe-guard';

/** Embedded horizontal scrolling wins over page navigation and drawer opening,
 * even at either end. Limit this recognizer to the strip/carousel itself so
 * touches elsewhere retain normal page swipes and Home hold-to-reorder. */
type HorizontalSwipeScrollViewProps = ScrollViewProps & {
  onNativeGestureFinalize?: () => void;
  onNativeTouchChange?: (touching: boolean) => void;
};

export const HorizontalSwipeScrollView = forwardRef<
  ScrollViewInstance,
  HorizontalSwipeScrollViewProps
>(function HorizontalSwipeScrollView(
  { onNativeGestureFinalize, onNativeTouchChange, ...props },
  ref,
) {
  const drawer = useContext(DrawerGestureContext) as unknown as LegacyPanGesture | undefined;
  const pager = useContext(PrimaryPageGestureContext);
  const guard = usePrimarySwipeGuard();
  const callbacks = useRef({ onNativeGestureFinalize, onNativeTouchChange });
  useEffect(() => {
    callbacks.current = { onNativeGestureFinalize, onNativeTouchChange };
  }, [onNativeGestureFinalize, onNativeTouchChange]);
  useEffect(() => () => guard(false), [guard]);
  const gesture = useMemo(() => {
    // A horizontal swipe may leave this short strip. Keep its native owner
    // until release, and report real cancellation separately from RN touch handoff.
    const native = Gesture.Native()
      .shouldCancelWhenOutside(false)
      .disallowInterruption(true)
      // Keep this recognizer stable when its consumer rerenders during a swipe.
      // Native touch tracking survives RN cancelling its JS touch responder.
      .onTouchesDown(() => callbacks.current.onNativeTouchChange?.(true))
      .onTouchesUp((event) => {
        if (event.numberOfTouches === 0) callbacks.current.onNativeTouchChange?.(false);
      })
      .onFinalize(() => {
        callbacks.current.onNativeTouchChange?.(false);
        callbacks.current.onNativeGestureFinalize?.();
      })
      .runOnJS(true);
    if (drawer) native.blocksExternalGesture(drawer);
    if (pager) native.blocksExternalGesture(pager);
    return native;
  }, [drawer, pager]);
  // Native recognizer relationships retain ownership for the entire gesture.
  // RN touch-cancel is a handoff to scrolling, not permission to re-enable an
  // ancestor pager underneath a finger. Only the web fallback needs the JS guard.
  const content = (
    <ScrollView
      nestedScrollEnabled
      {...props}
      ref={ref}
      horizontal
      onTouchStart={(event) => {
        if (Platform.OS === 'web') guard(true);
        props.onTouchStart?.(event);
      }}
      onTouchEnd={(event) => {
        if (Platform.OS === 'web') guard(false);
        props.onTouchEnd?.(event);
      }}
      onTouchCancel={(event) => {
        if (Platform.OS === 'web') guard(false);
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
