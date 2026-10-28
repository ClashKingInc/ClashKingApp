import { useId } from 'react';
import { StyleSheet, View } from 'react-native';
import Svg, { Defs, LinearGradient, Rect, Stop } from 'react-native-svg';
import { useVerticalBarEdgeIOS } from 'expo-status-bar';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { isDuoDevice } from './adaptive-layout';

/** Illustrated headers share the Ranked/Legends tint and opaque lower fade.
 * Draw the scrim directly: routing it through the artwork bitmap cache can
 * expose the photo while its tiny stretched image is loading or resizing.
 * Calculator tiles keep their existing, slightly translucent bottom edge. */
export function HeroHeaderScrim({
  variant = 'standard',
  edgeColor = '#000000',
  clipRailInset = false,
}: {
  variant?: 'standard' | 'clan' | 'player' | 'war' | 'ranked' | 'calculator' | 'calculatorDisabled';
  edgeColor?: string;
  clipRailInset?: boolean;
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
    <View collapsable={false} pointerEvents="none" accessible={false} style={styles.container}>
      {!isCard ? <View style={[styles.container, styles.tint]} /> : null}
      {/* Native layout resizes the gradient with the artwork. The small overscan
          covers fractional edges without waiting for a JavaScript layout event. */}
      <View style={styles.overscan}>
        <Svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none">
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
          <Rect x="0" y="0" width={100} height={100} fill={`url(#${gradientId})`} />
        </Svg>
      </View>
      {!isCard && isDuoDevice ? (
        <DuoRailFade edgeColor={edgeColor} clipRailInset={clipRailInset} />
      ) : null}
    </View>
  );
}

function DuoRailFade({ edgeColor, clipRailInset }: { edgeColor: string; clipRailInset: boolean }) {
  const rail = useVerticalBarEdgeIOS();
  const insets = useSafeAreaInsets();
  const gradientId = `railFade${useId().replace(/:/g, '')}`;
  // The reported edge can persist after the system hides its vertical bar.
  // Without a horizontal inset there is no rail for this fade to meet.
  if (rail === null || Math.max(insets.left, insets.right) < 1) return null;
  // Read the physical inset: the rail can be on either edge, including the
  // opposite side in a split window. Fade artwork only, never controls/text.
  const left = insets.left > insets.right || (insets.left === insets.right && rail === 'leading');
  // A header extended with negative safe-area margins can be clipped by its
  // scroll view. End the fade at that visible edge, not beyond the viewport.
  const clippedInset = clipRailInset ? (left ? insets.left : insets.right) : 0;
  return (
    <>
      <View
        pointerEvents="none"
        style={{
          position: 'absolute',
          top: 0,
          bottom: 0,
          width: '14%',
          minWidth: 48,
          maxWidth: 96,
          [left ? 'left' : 'right']: Math.max(0, clippedInset) - 1,
        }}
      >
        <View style={styles.overscan}>
          <Svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="none">
            <Defs>
              <LinearGradient
                id={gradientId}
                x1={left ? '100%' : '0%'}
                y1="0%"
                x2={left ? '0%' : '100%'}
                y2="0%"
              >
                <Stop offset="0" stopColor={edgeColor} stopOpacity={0} />
                <Stop offset="0.6" stopColor={edgeColor} stopOpacity={0.45} />
                <Stop offset="0.98" stopColor={edgeColor} stopOpacity={1} />
                <Stop offset="1" stopColor={edgeColor} stopOpacity={1} />
              </LinearGradient>
            </Defs>
            <Rect width={100} height={100} fill={`url(#${gradientId})`} />
          </Svg>
        </View>
      </View>
      {clippedInset > 0 ? (
        <View
          pointerEvents="none"
          style={{
            position: 'absolute',
            top: -1,
            bottom: -1,
            [left ? 'left' : 'right']: -1,
            width: clippedInset + 1,
            backgroundColor: edgeColor,
          }}
        />
      ) : null}
    </>
  );
}

const styles = StyleSheet.create({
  // Edge-pin the overlay independently of a header's padding and safe area.
  container: { position: 'absolute', top: 0, right: 0, bottom: 0, left: 0 },
  overscan: { position: 'absolute', top: -1, right: -1, bottom: -1, left: -1 },
  tint: { backgroundColor: '#00000080' },
});
