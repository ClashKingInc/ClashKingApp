import { useId } from 'react';
import { StyleSheet, View } from 'react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

/** Illustrated headers share the Ranked/Legends tint and opaque lower fade.
 * Draw the scrim directly: routing it through the artwork bitmap cache can
 * expose the photo while its tiny stretched image is loading or resizing.
 * Calculator tiles keep their existing, slightly translucent bottom edge. */
export function HeroHeaderScrim({
  variant = 'standard',
}: {
  variant?: 'standard' | 'clan' | 'player' | 'war' | 'ranked' | 'calculator' | 'calculatorDisabled';
}) {
  const gradientId = `headerFade${useId().replace(/:/g, '')}`;
  const isCard = variant === 'calculator' || variant === 'calculatorDisabled';
  const stops = isCard
    ? [
        [0, variant === 'calculatorDisabled' ? 0.35 : 0.2],
        [0.45, 0.32],
        [0.7, 0.65],
        [1, 0.94],
      ]
    : [
        [0, 0.34],
        [0.6, 0.52],
        [0.84, 0.76],
        [1, 1],
      ];
  return (
    <View pointerEvents="none" accessible={false} style={styles.container}>
      {!isCard ? <View style={[styles.container, styles.tint]} /> : null}
      <Svg width="100%" height="100%" style={StyleSheet.absoluteFill}>
        <Defs>
          <LinearGradient id={gradientId} x1="0%" y1="0%" x2="0%" y2="100%">
            {stops.map(([offset, opacity]) => (
              <Stop
                key={offset}
                offset={offset}
                stopColor={isCard ? '#030304' : '#000000'}
                stopOpacity={opacity}
              />
            ))}
          </LinearGradient>
        </Defs>
        <Rect x="0" y="0" width="100%" height="100%" fill={`url(#${gradientId})`} />
      </Svg>
    </View>
  );
}

const styles = StyleSheet.create({
  // Edge-pin the overlay independently of a header's padding and safe area.
  container: { position: 'absolute', top: 0, right: 0, bottom: 0, left: 0 },
  tint: { backgroundColor: '#00000080' },
});
