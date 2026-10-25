import { useEffect, useState } from 'react';
import { Animated, Easing, StyleSheet, View } from 'react-native';
import { Hand } from 'lucide-react-native';
import { useCKAccessibility } from '../../ui';

/** Illustrate the gesture above real content without claiming any touch input.
 * Only transforms/opacity animate; the app's actual cards never move themselves. */
export function TutorialGestureCue({
  mode,
  rtl = false,
}: {
  mode: 'swipe' | 'hold';
  rtl?: boolean;
}) {
  const { reduceMotion } = useCKAccessibility();
  const [phase] = useState(() => new Animated.Value(0));
  useEffect(() => {
    if (reduceMotion) {
      phase.setValue(0.36);
      return;
    }
    const animation = Animated.loop(
      Animated.sequence([
        Animated.timing(phase, {
          toValue: 1,
          duration: mode === 'hold' ? 3000 : 2400,
          easing: Easing.linear,
          useNativeDriver: true,
        }),
        Animated.delay(700),
      ]),
    );
    animation.start();
    return () => animation.stop();
  }, [mode, phase, reduceMotion]);
  const opacity = phase.interpolate({ inputRange: [0, 0.1, 0.82, 1], outputRange: [0, 1, 1, 0] });
  const travel = phase.interpolate({
    inputRange: mode === 'hold' ? [0, 0.2, 0.52, 0.78, 1] : [0, 0.12, 0.2, 0.78, 1],
    outputRange: mode === 'hold' ? [0, 0, 0, -54, -54] : [-80, -80, -80, 80, 80],
  });
  const holdScale = phase.interpolate({
    inputRange: [0, 0.2, 0.48, 0.58, 1],
    outputRange: [0.6, 0.6, 1.25, 0.8, 0.8],
  });
  const scale = phase.interpolate({
    inputRange: [0, 0.18, 0.3, 0.52, 0.78, 1],
    outputRange: [1, 1, 0.87, 0.87, 1, 1],
  });
  return (
    <View
      pointerEvents="none"
      accessible={false}
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      style={styles.frame}
    >
      {mode === 'swipe' ? <View style={styles.track} /> : null}
      <Animated.View
        style={[
          styles.touch,
          {
            opacity,
            transform:
              mode === 'swipe'
                ? [{ translateX: Animated.multiply(travel, rtl ? -1 : 1) }]
                : [{ translateY: travel }],
          },
        ]}
      >
        {mode === 'hold' ? (
          <Animated.View style={[styles.holdRing, { transform: [{ scale: holdScale }] }]} />
        ) : null}
        <Animated.View style={[styles.finger, { transform: [{ scale }] }]}>
          <Hand size={34} color="#FFF4DC" fill="#4E3D27" strokeWidth={2} />
        </Animated.View>
      </Animated.View>
    </View>
  );
}
const styles = StyleSheet.create({
  frame: { width: 220, height: 100, alignItems: 'center', justifyContent: 'center' },
  track: {
    position: 'absolute',
    width: 180,
    height: 6,
    borderRadius: 3,
    backgroundColor: '#FFF4DC55',
  },
  touch: { width: 46, height: 46, alignItems: 'center', justifyContent: 'center' },
  holdRing: {
    position: 'absolute',
    width: 44,
    height: 44,
    borderRadius: 22,
    borderWidth: 3,
    borderColor: '#F8D88F',
    backgroundColor: '#F8D88F22',
  },
  finger: {
    shadowColor: '#000',
    shadowOpacity: 0.35,
    shadowRadius: 3,
    shadowOffset: { width: 0, height: 2 },
  },
});
