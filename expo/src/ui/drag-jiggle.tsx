import { useEffect, type PropsWithChildren } from 'react';
import Reanimated, {
  cancelAnimation,
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withSequence,
  withTiming,
} from 'react-native-reanimated';
import { useCKAccessibility } from './accessibility';

export const CARD_REORDER_HOLD_MS = 300;

/** Feedback only while dragging; never enters a persistent home-screen edit mode. */
export function DragJiggle({
  active,
  scale = 1,
  children,
}: PropsWithChildren<{ active: boolean; scale?: number }>) {
  const { reduceMotion } = useCKAccessibility();
  const rotation = useSharedValue(0);
  const size = useSharedValue(1);
  useEffect(() => {
    cancelAnimation(rotation);
    cancelAnimation(size);
    size.value = withTiming(active && !reduceMotion ? scale : 1, { duration: 140 });
    rotation.value =
      active && !reduceMotion
        ? withSequence(
            withTiming(-0.35, { duration: 80 }),
            withRepeat(
              withTiming(0.35, { duration: 160, easing: Easing.inOut(Easing.quad) }),
              -1,
              true,
            ),
          )
        : withTiming(0, { duration: reduceMotion ? 0 : 100 });
    return () => {
      cancelAnimation(rotation);
      cancelAnimation(size);
    };
  }, [active, reduceMotion, rotation, scale, size]);
  const style = useAnimatedStyle(() => ({
    transform: [{ rotate: `${rotation.value}deg` }, { scale: size.value }],
  }));
  return <Reanimated.View style={style}>{children}</Reanimated.View>;
}
