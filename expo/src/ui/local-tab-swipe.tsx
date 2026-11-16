import { useCallback, useMemo, useState, type ReactNode } from 'react';
import { StyleSheet } from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Reanimated, { useAnimatedStyle, useSharedValue, withTiming } from 'react-native-reanimated';
import { scheduleOnRN } from 'react-native-worklets';
import { PrimaryPageGestureContext, PrimarySwipeGuard } from './primary-swipe-guard';
import { useCKAccessibility } from './accessibility';

/** A page owns its local tabs. Embedded horizontal strips block this recognizer
 * through PrimaryPageGestureContext, so reaching their edge never changes tabs. */
export function LocalTabSwipe<T extends string>({
  value,
  values,
  onChange,
  isRtl,
  disabled = false,
  children,
}: {
  value: T;
  values: readonly T[];
  onChange: (value: T) => void;
  isRtl: boolean;
  disabled?: boolean;
  children: ReactNode;
}) {
  const { reduceMotion } = useCKAccessibility();
  const [blocked, setBlocked] = useState(false);
  const offset = useSharedValue(0);
  const valuesKey = values.join('\u0000');
  const stableValues = useMemo(() => valuesKey.split('\u0000') as T[], [valuesKey]);
  const index = stableValues.indexOf(value);
  const commit = useCallback(
    (direction: number) => {
      const next = stableValues[index + direction];
      if (next !== undefined) onChange(next);
    },
    [index, stableValues, onChange],
  );
  const gesture = useMemo(
    () =>
      Gesture.Pan()
        .enabled(!disabled && !blocked)
        .activeOffsetX([-24, 24])
        .failOffsetY([-12, 12])
        .onUpdate((event) => {
          const direction = (event.translationX < 0 ? 1 : -1) * (isRtl ? -1 : 1);
          const atEdge = index + direction < 0 || index + direction >= stableValues.length;
          offset.set(
            reduceMotion
              ? 0
              : Math.max(-28, Math.min(28, event.translationX * (atEdge ? 0.06 : 0.16))),
          );
        })
        .onEnd((event) => {
          if (
            Math.abs(event.translationX) >= 56 ||
            (Math.abs(event.translationX) >= 24 && Math.abs(event.velocityX) >= 650)
          ) {
            scheduleOnRN(commit, (event.translationX < 0 ? 1 : -1) * (isRtl ? -1 : 1));
          }
        })
        .onFinalize(() => {
          offset.set(withTiming(0, { duration: reduceMotion ? 0 : 140 }));
        }),
    [disabled, blocked, isRtl, index, stableValues.length, offset, reduceMotion, commit],
  );
  const motion = useAnimatedStyle(() => ({ transform: [{ translateX: offset.get() }] }));
  return (
    <PrimarySwipeGuard.Provider value={setBlocked}>
      <PrimaryPageGestureContext.Provider value={gesture}>
        <GestureDetector gesture={gesture}>
          <Reanimated.View style={[styles.page, motion]}>{children}</Reanimated.View>
        </GestureDetector>
      </PrimaryPageGestureContext.Provider>
    </PrimarySwipeGuard.Provider>
  );
}
const styles = StyleSheet.create({ page: { flex: 1 } });
