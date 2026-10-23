import { memo } from 'react';
import { Image, StyleSheet, View, useWindowDimensions } from 'react-native';
import { Asset } from 'expo-asset';
import { useCKThemeMode } from './theme';

export type RankedCheckerColor = 'blue' | 'purple' | 'green' | 'red';
const artwork = {
  blue: require('../../assets/clashking/backgrounds/blue.webp'),
  purple: require('../../assets/clashking/backgrounds/purple.webp'),
  green: require('../../assets/clashking/backgrounds/green.webp'),
  red: require('../../assets/clashking/backgrounds/red.webp'),
};
const fades = {
  dark: require('../../assets/clashking/backgrounds/fade-dark.png'),
  light: require('../../assets/clashking/backgrounds/fade-light.png'),
};
const fallback = { blue: '#302A68', purple: '#4A203D', green: '#174A20', red: '#652626' };
let warmup: Promise<unknown> | undefined;

/** Opportunistic warmup only: routing and the launch screen never await artwork. */
export function warmRankedCheckerBackgrounds() {
  warmup ??= Promise.allSettled(
    [...Object.values(artwork), ...Object.values(fades)].map((source) =>
      Image.prefetch(Asset.fromModule(source).uri),
    ),
  );
  return warmup;
}

/** No layout feedback or SVG composition on navigation; native views paint cached rasters. */
export const RankedCheckerBackground = memo(function RankedCheckerBackground({
  color,
}: {
  color: RankedCheckerColor;
}) {
  const mode = useCKThemeMode();
  const { width: screenWidth } = useWindowDimensions();
  const width = Math.max(700, screenWidth);
  return (
    <View
      pointerEvents="none"
      style={[StyleSheet.absoluteFill, styles.clip, { backgroundColor: fallback[color] }]}
    >
      <Image
        source={artwork[color]}
        resizeMode="cover"
        resizeMethod="resize"
        fadeDuration={0}
        style={{
          position: 'absolute',
          width,
          height: width * 0.75,
          left: '50%',
          top: 0,
          transform: [{ translateX: -width / 2 }],
        }}
      />
      {/* Shade only the artwork; keep titles and controls fully opaque. Apply
        below the existing theme fade so every checker header stays consistent. */}
      <View
        testID="ranked-checker-tint"
        style={[StyleSheet.absoluteFill, { backgroundColor: '#0000007A' }]}
      />
      <Image
        source={fades[mode]}
        resizeMode="stretch"
        fadeDuration={0}
        style={StyleSheet.absoluteFill}
      />
    </View>
  );
});
const styles = StyleSheet.create({ clip: { overflow: 'hidden' } });
