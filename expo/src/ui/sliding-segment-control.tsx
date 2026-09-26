import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Animated,
  Pressable,
  StyleSheet,
  View,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import { useCKAccessibility } from './accessibility';
import { CKText } from './text';
import { useCKTheme } from './theme';
import { colorWithAlpha } from './tokens';

export function SlidingSegmentControl<T extends string>({
  value,
  options,
  style,
  testID,
  isRtl,
  onChange,
}: {
  value: T;
  options: readonly [{ value: T; label: string }, { value: T; label: string }];
  style?: StyleProp<ViewStyle>;
  testID?: string;
  isRtl: boolean;
  onChange: (value: T) => void;
}) {
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const [segmentWidth, setSegmentWidth] = useState(0);
  const [position] = useState(() => new Animated.Value(value === options[0].value ? 0 : 1));
  const startIndex = value === options[0].value ? 0 : 1;
  const animateTo = useCallback(
    (index: 0 | 1) => {
      if (reduceMotion) {
        position.setValue(index);
        return;
      }
      Animated.spring(position, {
        toValue: index,
        mass: 1,
        stiffness: 420,
        damping: 41,
        useNativeDriver: true,
      }).start();
    },
    [position, reduceMotion],
  );
  useEffect(() => animateTo(startIndex), [animateTo, startIndex]);
  const pan = useMemo(
    () =>
      Gesture.Pan()
        .activeOffsetX([-4, 4])
        .failOffsetY([-10, 10])
        .runOnJS(true)
        .onStart(() => position.stopAnimation())
        .onUpdate((gesture) => {
          if (segmentWidth <= 0) return;
          const direction = isRtl ? -1 : 1;
          position.setValue(
            Math.max(
              0,
              Math.min(1, startIndex + direction * (gesture.translationX / segmentWidth)),
            ),
          );
        })
        .onEnd((gesture) => {
          if (segmentWidth <= 0) return;
          const direction = isRtl ? -1 : 1;
          const projected =
            startIndex +
            direction *
              (gesture.translationX / segmentWidth + (gesture.velocityX / segmentWidth) * 0.08);
          const target: 0 | 1 = projected >= 0.5 ? 1 : 0;
          animateTo(target);
          onChange(options[target].value);
        })
        .onFinalize((_event, success) => {
          if (success) return;
          animateTo(startIndex);
        }),
    [animateTo, isRtl, onChange, options, position, segmentWidth, startIndex],
  );
  return (
    <GestureDetector gesture={pan}>
      <View
        testID={testID}
        onLayout={(event) => setSegmentWidth((event.nativeEvent.layout.width - 4) / 2)}
        style={[
          styles.segment,
          style,
          {
            flexDirection: isRtl ? 'row-reverse' : 'row',
            backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.45),
            borderColor: colorWithAlpha(theme.outlineVariant, 0.32),
          },
        ]}
      >
        {segmentWidth > 0 ? (
          <Animated.View
            pointerEvents="none"
            style={[
              styles.segmentIndicator,
              {
                width: segmentWidth,
                backgroundColor: colorWithAlpha(theme.surfaceContainerHighest, 0.74),
                transform: [
                  {
                    translateX: position.interpolate({
                      inputRange: [0, 1],
                      outputRange: isRtl ? [segmentWidth, 0] : [0, segmentWidth],
                    }),
                  },
                ],
              },
            ]}
          />
        ) : null}
        {options.map(({ value: optionValue, label }) => (
          <Pressable
            key={optionValue}
            accessibilityRole="tab"
            accessibilityState={{ selected: value === optionValue }}
            accessibilityLabel={label}
            onPress={() => onChange(optionValue)}
            style={styles.segmentItem}
          >
            <CKText
              style={[
                styles.segmentLabel,
                value !== optionValue && { color: colorWithAlpha(theme.onSurface, 0.67) },
              ]}
            >
              {label}
            </CKText>
          </Pressable>
        ))}
      </View>
    </GestureDetector>
  );
}

const styles = StyleSheet.create({
  segment: {
    height: 32,
    flexDirection: 'row',
    padding: 2,
    borderRadius: 16,
    borderWidth: 0.8,
    overflow: 'hidden',
  },
  segmentIndicator: { position: 'absolute', left: 2, top: 2, bottom: 2, borderRadius: 14 },
  segmentItem: { flex: 1, alignItems: 'center', justifyContent: 'center', borderRadius: 14 },
  segmentLabel: { width: '100%', textAlign: 'center', fontSize: 13, fontWeight: '600' },
});
