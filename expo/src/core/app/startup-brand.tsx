import { useEffect, useState } from 'react';
import { Animated, Easing, StyleSheet, View } from 'react-native';
import Svg, { Path, Polygon } from 'react-native-svg';
import { startupBrandPaths as art } from '../assets/startup-brand-paths';

/** One native-driver timeline; bootstrap never waits for its completion. */
export function StartupBrand({
  reduceMotion,
  foreground,
  background,
  label,
  width,
}: {
  reduceMotion: boolean;
  foreground: string;
  background: string;
  label: string;
  width: number;
}) {
  const [progress] = useState(() => new Animated.Value(reduceMotion ? 1 : 0));
  useEffect(() => {
    if (reduceMotion) {
      progress.stopAnimation();
      progress.setValue(1);
      return;
    }
    const animation = Animated.timing(progress, {
      toValue: 1,
      duration: 770,
      easing: Easing.linear,
      useNativeDriver: true,
    });
    animation.start();
    return () => animation.stop();
  }, [progress, reduceMotion]);
  const flight = (values: number[]) =>
    progress.interpolate({
      inputRange: [0, 0.25, 0.5, 0.56, 0.68, 0.82, 1],
      outputRange: values,
      extrapolate: 'clamp',
    });
  const recoil = (values: number[]) =>
    progress.interpolate({
      inputRange: [0, 0.5, 0.56, 0.7, 0.86, 1],
      outputRange: values,
      extrapolate: 'clamp',
    });
  const reveal = progress.interpolate({
    inputRange: [0, 0.49, 0.55, 1],
    outputRange: [0, 0, 1, 1],
  });
  return (
    <View accessible accessibilityLabel={label} testID="startup-brand" style={styles.brand}>
      <View
        testID="startup-mark"
        style={styles.mark}
        accessibilityElementsHidden
        importantForAccessibility="no-hide-descendants"
      >
        <Animated.View
          style={[
            StyleSheet.absoluteFill,
            {
              opacity: flight([0, 0, 1, 0, 0, 0, 0]),
              transform: [
                { translateX: flight([90, 90, -1, 0, 0, 0, 0]) },
                { translateY: flight([-168, -168, 2, 0, 0, 0, 0]) },
              ],
            },
          ]}
        >
          <Svg width="100%" height="100%" viewBox="0 0 84.5112 101.14">
            <Path d="M65 7L24 84" stroke={foreground} strokeWidth={2.8} />
          </Svg>
        </Animated.View>
        <Animated.View
          style={[
            StyleSheet.absoluteFill,
            {
              transform: [
                { translateY: recoil([0, 0, 4, -1, 0.3, 0]) },
                {
                  rotate: recoil([0, 0, -3.8, 1.2, -0.35, 0]).interpolate({
                    inputRange: [-3.8, 1.2],
                    outputRange: ['-3.8deg', '1.2deg'],
                  }),
                },
              ],
            },
          ]}
        >
          <Svg width="100%" height="100%" viewBox="0 0 84.5112 101.14" fillRule="evenodd">
            <Path d={art.crown[0]} fill="#BF0000" />
            <Path d={art.crown[1]} fill="#D90709" />
          </Svg>
          <Animated.View style={[StyleSheet.absoluteFill, { opacity: reveal }]}>
            <Svg width="100%" height="100%" viewBox="0 0 84.5112 101.14">
              <Polygon points={art.cut} fill={background} />
            </Svg>
          </Animated.View>
        </Animated.View>
        <Animated.View
          style={[
            StyleSheet.absoluteFill,
            {
              opacity: flight([0, 0, 1, 1, 1, 1, 1]),
              transform: [
                { translateX: flight([90, 90, -1, 0, 0, 0, 0]) },
                { translateY: flight([-168, -168, 2, 0, 0, 0, 0]) },
                {
                  rotate: flight([0, 0, 0, -2, 1, -0.3, 0]).interpolate({
                    inputRange: [-2, 1],
                    outputRange: ['-2deg', '1deg'],
                  }),
                },
              ],
            },
          ]}
        >
          <Svg width="100%" height="100%" viewBox="0 0 84.5112 101.14" fillRule="evenodd">
            <Path d={art.crown[2]} fill={foreground} />
            <Path d={art.crown[3]} fill={foreground} />
          </Svg>
        </Animated.View>
        <Animated.View
          style={[
            StyleSheet.absoluteFill,
            {
              opacity: progress.interpolate({
                inputRange: [0, 0.5, 0.54, 0.72, 1],
                outputRange: [0, 0, 1, 0, 0],
              }),
            },
          ]}
        >
          <Svg width="100%" height="100%" viewBox="0 0 84.5112 101.14">
            <Path
              d="M49 20l-5 -5 M60 21l5 -3 M49 30l-6 1 M59 30l4 5"
              stroke={foreground}
              strokeWidth={1.3}
              strokeLinecap="round"
            />
          </Svg>
        </Animated.View>
      </View>
      <Animated.View
        testID="startup-wordmark"
        style={{
          width,
          aspectRatio: 163 / 23,
          marginTop: 24,
          opacity: progress.interpolate({
            inputRange: [0, 0.55, 0.8, 1],
            outputRange: [0, 0, 1, 1],
          }),
          transform: [
            {
              translateY: progress.interpolate({
                inputRange: [0, 0.55, 0.8, 1],
                outputRange: [5, 5, 0, 0],
              }),
            },
          ],
        }}
      >
        <Svg width="100%" height="100%" viewBox="58 22 163 23" fillRule="evenodd">
          <Path d={art.word[0]} fill="#D90709" />
          <Path d={art.word[1]} fill={foreground} />
        </Svg>
      </Animated.View>
    </View>
  );
}
const styles = StyleSheet.create({
  brand: { alignItems: 'center' },
  mark: { width: 112, height: 134 },
});
