import { useEffect, useState } from 'react';
import { AppState, StyleSheet, View } from 'react-native';
import { useIsFocused } from '@react-navigation/native';
import Svg, { Rect, type RectProps } from 'react-native-svg';
import Animated, {
  cancelAnimation,
  Easing,
  useAnimatedProps,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';
import { useCKAccessibility, useCKThemeMode } from '../../ui';

const AnimatedRect = Animated.createAnimatedComponent(Rect);

/** Animate a scalar around a fixed perimeter, not hundreds of path vertices.
 * Layered thin strokes replace full-card Gaussian filters. Keep this animation
 * on the UI thread, and pause it offscreen or when reduced motion is requested. */
export function SuperchargeBorder() {
  const { reduceMotion } = useCKAccessibility();
  const dark = useCKThemeMode() === 'dark';
  const focused = useIsFocused();
  const [foreground, setForeground] = useState(AppState.currentState === 'active');
  const [size, setSize] = useState({ width: 0, height: 0 });
  const progress = useSharedValue(0);
  const radius = Math.min(26, size.width / 2, size.height / 2);
  const perimeter = Math.max(
    1,
    2 * (size.width + size.height - 8 - 4 * radius) + 2 * Math.PI * radius,
  );
  useEffect(() => {
    const listener = AppState.addEventListener('change', (state) =>
      setForeground(state === 'active'),
    );
    return () => listener.remove();
  }, []);
  useEffect(() => {
    cancelAnimation(progress);
    if (reduceMotion || !focused || !foreground || !size.width) return;
    progress.value = 0;
    progress.value = withRepeat(
      withTiming(1, { duration: 6500, easing: Easing.linear }),
      -1,
      false,
    );
    return () => cancelAnimation(progress);
  }, [progress, reduceMotion, focused, foreground, size.width, size.height]);
  const highlights = useAnimatedProps<RectProps>(() => ({
    strokeDashoffset: -progress.value * perimeter,
  }));
  const blue = dark ? '#62A0FF' : '#337EE5';
  const rect = {
    x: 4,
    y: 4,
    width: Math.max(0, size.width - 8),
    height: Math.max(0, size.height - 8),
    rx: radius,
    fill: 'none',
  };
  return (
    <View
      pointerEvents="none"
      accessible={false}
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      testID="damage-supercharge-border"
      onLayout={({ nativeEvent: { layout } }) =>
        setSize((current) =>
          current.width === layout.width && current.height === layout.height
            ? current
            : { width: layout.width, height: layout.height },
        )
      }
      style={styles.rim}
    >
      <Svg width={size.width} height={size.height}>
        <Rect {...rect} stroke={blue} strokeWidth={7} opacity={0.12} />
        <Rect {...rect} stroke={blue} strokeWidth={3.5} opacity={0.32} />
        <Rect {...rect} stroke={dark ? '#91CBFF' : '#337EE5'} strokeWidth={1.2} opacity={0.85} />
        <AnimatedRect
          {...rect}
          animatedProps={highlights}
          stroke="#E4F7FF"
          strokeWidth={2}
          strokeLinecap="round"
          strokeDasharray={[
            Math.min(28, perimeter / 12),
            Math.max(1, perimeter / 4 - Math.min(28, perimeter / 12)),
          ]}
        />
      </Svg>
    </View>
  );
}
const styles = StyleSheet.create({
  rim: { position: 'absolute', inset: -4 },
});
