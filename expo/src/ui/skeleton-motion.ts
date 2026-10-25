import { useEffect, useMemo, useState } from 'react';
import { Animated, Easing } from 'react-native';
import { useCKAccessibility } from './accessibility';

// One native animation drives every placeholder. Large pages must not start a
// separate repeating animation for each text line, icon, and nested card.
const pulse = new Animated.Value(1);
let consumers = 0;
let startTimer: ReturnType<typeof setTimeout> | undefined;
let animation: Animated.CompositeAnimation | undefined;
function retainPulse() {
  consumers += 1;
  if (consumers === 1) {
    startTimer = setTimeout(() => {
      animation = Animated.loop(
        Animated.sequence([
          Animated.timing(pulse, {
            toValue: 0.78,
            duration: 850,
            easing: Easing.inOut(Easing.quad),
            useNativeDriver: true,
          }),
          Animated.timing(pulse, {
            toValue: 1,
            duration: 850,
            easing: Easing.inOut(Easing.quad),
            useNativeDriver: true,
          }),
        ]),
      );
      animation.start();
    }, 500);
  }
  return () => {
    consumers -= 1;
    if (consumers === 0) {
      clearTimeout(startTimer);
      animation?.stop();
      animation = undefined;
      pulse.setValue(1);
    }
  };
}

export function useSkeletonMotion(active: boolean) {
  const { reduceMotion } = useCKAccessibility();
  const [reveal] = useState(() => new Animated.Value(0));
  const opacity = useMemo(() => Animated.multiply(reveal, pulse), [reveal]);
  useEffect(() => {
    if (!active) return;
    // Keep the real geometry mounted, but skip a one-frame flash on fast loads.
    // There is deliberately no minimum display time: ready content wins immediately.
    reveal.setValue(0);
    let fade: Animated.CompositeAnimation | undefined;
    const timer = setTimeout(() => {
      if (reduceMotion) reveal.setValue(1);
      else {
        fade = Animated.timing(reveal, { toValue: 1, duration: 120, useNativeDriver: true });
        fade.start();
      }
    }, 120);
    const release = reduceMotion ? undefined : retainPulse();
    return () => {
      clearTimeout(timer);
      fade?.stop();
      release?.();
    };
  }, [active, reduceMotion, reveal]);
  return active ? opacity : 1;
}
