import { createContext, useContext, useEffect, useState } from 'react';
import { Animated, AppState, Easing, StyleSheet, View } from 'react-native';
import Svg, { Defs, RadialGradient, Stop, Circle } from 'react-native-svg';
import { useCKAccessibility } from './accessibility';
import { useCKTheme } from './theme';
import { colorWithAlpha } from './tokens';

export type CardAppearance = 'original' | 'tint' | 'edge' | 'glow';
const CardAppearanceContext = createContext<CardAppearance>('edge');
export const CardAppearanceProvider = CardAppearanceContext.Provider;

export function CardAtmosphere({
  color = '#8A8F98',
  radius = 28,
}: {
  color?: string;
  radius?: number;
}) {
  const mode = useContext(CardAppearanceContext);
  const theme = useCKTheme();
  const { reduceMotion } = useCKAccessibility();
  const [size, setSize] = useState({ width: 0, height: 0 });
  const [phase] = useState(() => new Animated.Value(0));
  useEffect(() => {
    let loop: Animated.CompositeAnimation | undefined;
    const update = () => {
      loop?.stop();
      if (mode !== 'glow' || reduceMotion || AppState.currentState !== 'active') return;
      phase.setValue(0);
      loop = Animated.loop(
        Animated.timing(phase, {
          toValue: 1,
          duration: 16000,
          easing: Easing.linear,
          useNativeDriver: true,
        }),
      );
      loop.start();
    };
    update();
    const subscription = AppState.addEventListener('change', update);
    return () => {
      loop?.stop();
      subscription.remove();
    };
  }, [mode, phase, reduceMotion]);
  if (mode === 'original') return null;
  const edgeColor = color;
  return (
    <View
      pointerEvents="none"
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      onLayout={(event) => setSize(event.nativeEvent.layout)}
      style={[
        StyleSheet.absoluteFill,
        {
          borderRadius: radius,
          overflow: 'hidden',
          backgroundColor: colorWithAlpha(edgeColor, mode === 'tint' ? 0.22 : 0.3),
        },
      ]}
    >
      {mode === 'glow' && !reduceMotion ? (
        <Animated.View
          style={{
            position: 'absolute',
            width: 100,
            height: 100,
            opacity: 0.8,
            transform: [
              {
                translateX: phase.interpolate({
                  inputRange: [0, 0.35, 0.5, 0.85, 1],
                  outputRange: [-50, size.width - 50, size.width - 50, -50, -50],
                }),
              },
              {
                translateY: phase.interpolate({
                  inputRange: [0, 0.35, 0.5, 0.85, 1],
                  outputRange: [-50, -50, size.height - 50, size.height - 50, -50],
                }),
              },
            ],
          }}
        >
          <Svg width={100} height={100}>
            <Defs>
              <RadialGradient id="edge-light">
                <Stop offset="0" stopColor="#FFFFFF" />
                <Stop offset="0.35" stopColor={edgeColor} stopOpacity={0.8} />
                <Stop offset="1" stopColor={edgeColor} stopOpacity={0} />
              </RadialGradient>
            </Defs>
            <Circle cx={50} cy={50} r={50} fill="url(#edge-light)" />
          </Svg>
        </Animated.View>
      ) : null}
      <View
        style={{
          position: 'absolute',
          inset: 1,
          borderRadius: Math.max(0, radius - 1),
          backgroundColor: theme.surface,
        }}
      >
        {mode === 'tint' ? (
          <View
            style={[StyleSheet.absoluteFill, { backgroundColor: colorWithAlpha(color, 0.045) }]}
          />
        ) : null}
      </View>
    </View>
  );
}
