import { useEffect } from 'react';
import { Image } from 'expo-image';
import { type StyleProp, type ViewStyle } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, {
  cancelAnimation,
  useAnimatedStyle,
  useSharedValue,
  withSpring,
  withTiming,
} from 'react-native-reanimated';
import { GlassSurface } from './glass';

/** Shared, bounded artwork interaction. No idle loop; release returns to origin. */
export function DraggableArtworkBubble({
  source,
  active = true,
  reduceMotion,
  size = 90,
  maxTravel = 60,
  style,
}: {
  source: number;
  active?: boolean;
  reduceMotion: boolean;
  size?: number;
  maxTravel?: number;
  style?: StyleProp<ViewStyle>;
}) {
  const x = useSharedValue(0),
    y = useSharedValue(0),
    held = useSharedValue(0);
  useEffect(() => {
    if (!active) {
      cancelAnimation(x);
      cancelAnimation(y);
      cancelAnimation(held);
      x.set(0);
      y.set(0);
      held.set(0);
    }
    return () => {
      cancelAnimation(x);
      cancelAnimation(y);
      cancelAnimation(held);
    };
  }, [active, x, y, held]);
  const drag = Gesture.Pan()
    .enabled(active)
    .minDistance(4)
    .onStart(() => {
      cancelAnimation(x);
      cancelAnimation(y);
      held.set(reduceMotion ? 0 : withTiming(1, { duration: 100 }));
    })
    .onUpdate((e) => {
      x.set(Math.max(-maxTravel, Math.min(maxTravel, e.translationX)));
      y.set(Math.max(-maxTravel, Math.min(maxTravel, e.translationY)));
    })
    .onFinalize(() => {
      held.set(reduceMotion ? 0 : withTiming(0, { duration: 140 }));
      x.set(reduceMotion ? 0 : withSpring(0, { damping: 16, stiffness: 170 }));
      y.set(reduceMotion ? 0 : withSpring(0, { damping: 16, stiffness: 170 }));
    });
  const motion = useAnimatedStyle(() => ({
    transform: [
      { perspective: 600 },
      { translateX: x.value },
      { translateY: y.value },
      { scale: reduceMotion ? 1 : 1 + held.value * 0.06 },
      { rotateX: `${reduceMotion ? 0 : -y.value / 9}deg` },
      { rotateY: `${reduceMotion ? 0 : x.value / 9}deg` },
    ],
  }));
  const layer = useAnimatedStyle(() => ({ zIndex: held.value > 0 ? 20 : 1 }));
  return (
    <Animated.View style={[style, layer]}>
      <GestureDetector gesture={drag}>
        <Animated.View style={motion}>
          <GlassSurface
            cornerRadius={size * 0.3}
            interactive
            style={{ width: size, height: size, alignItems: 'center', justifyContent: 'center' }}
          >
            <Image
              source={source}
              contentFit="contain"
              style={{ width: size * 0.9, height: size * 0.9 }}
              transition={0}
            />
          </GlassSurface>
        </Animated.View>
      </GestureDetector>
    </Animated.View>
  );
}
