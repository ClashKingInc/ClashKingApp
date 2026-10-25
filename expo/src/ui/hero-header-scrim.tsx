import { useId, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';

/** Illustrated headers share the Ranked/Legends tint and opaque lower fade.
 * Draw the scrim directly: routing it through the artwork bitmap cache can
 * expose the photo while its tiny stretched image is loading or resizing.
 * Calculator tiles keep their existing, slightly translucent bottom edge. */
export function HeroHeaderScrim({
  variant = 'standard',
  edgeColor = '#000000',
}: {
  variant?: 'standard' | 'clan' | 'player' | 'war' | 'ranked' | 'calculator' | 'calculatorDisabled';
  edgeColor?: string;
}) {
  const [bounds, setBounds] = useState({ width: 0, height: 0 });
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
    <View
      collapsable={false}
      pointerEvents="none"
      accessible={false}
      style={styles.container}
      onLayout={({ nativeEvent: { layout } }) => {
        // react-native-svg truncates numeric width/height with parseInt. Round
        // outward first, or fractional native layouts expose an artwork hairline.
        const width = Math.ceil(layout.width);
        const height = Math.ceil(layout.height);
        setBounds((current) =>
          current.width === width && current.height === height ? current : { width, height },
        );
      }}
    >
      {!isCard ? <View style={[styles.container, styles.tint]} /> : null}
      {/* Content-sized headers can grow when badges/chips resolve. A measured
          viewport keeps the opaque stop at the real bottom instead of leaving
          a black band followed by uncovered artwork. */}
      <Svg
        width={bounds.width || '100%'}
        height={bounds.height || '100%'}
        style={StyleSheet.absoluteFill}
      >
        <Defs>
          <LinearGradient id={gradientId} x1="0%" y1="0%" x2="0%" y2="100%">
            {stops.map(([offset, opacity]) => (
              <Stop
                key={offset}
                offset={offset}
                stopColor={isCard ? '#030304' : offset === 1 ? edgeColor : '#000000'}
                stopOpacity={opacity}
              />
            ))}
          </LinearGradient>
        </Defs>
        <Rect
          x="0"
          y="0"
          width={bounds.width || '100%'}
          height={bounds.height || '100%'}
          fill={`url(#${gradientId})`}
        />
      </Svg>
    </View>
  );
}

const styles = StyleSheet.create({
  // Edge-pin the overlay independently of a header's padding and safe area.
  container: { position: 'absolute', top: 0, right: 0, bottom: 0, left: 0 },
  tint: { backgroundColor: '#00000080' },
});
