import type { PropsWithChildren } from 'react';
import { GlassView, isGlassEffectAPIAvailable, isLiquidGlassAvailable } from 'expo-glass-effect';
import {
  Platform,
  StyleSheet,
  View,
  type StyleProp,
  type ViewProps,
  type ViewStyle,
} from 'react-native';

import { currentPlatform, useCKAccessibility } from './accessibility';
import { resolveGlassMode } from './policies';
import { ckRadius, colorWithAlpha } from './tokens';
import { useCKTheme, useCKThemeMode } from './theme';

export type GlassSurfaceProps = PropsWithChildren<
  Omit<ViewProps, 'style'> & {
    cornerRadius?: number;
    interactive?: boolean;
    selected?: boolean;
    tintColor?: string;
    style?: StyleProp<ViewStyle>;
  }
>;

function nativeGlassIsAvailable(): boolean {
  if (Platform.OS !== 'ios') return false;
  try {
    return isLiquidGlassAvailable() && isGlassEffectAPIAvailable();
  } catch {
    return false;
  }
}

export function GlassSurface({
  children,
  cornerRadius = ckRadius.card,
  interactive = false,
  selected = false,
  tintColor,
  style,
  ...props
}: GlassSurfaceProps) {
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  const accessibility = useCKAccessibility();
  const glassMode = resolveGlassMode({
    platform: currentPlatform(),
    nativeGlassAvailable: nativeGlassIsAvailable(),
    reduceTransparency: accessibility.reduceTransparency,
    highContrast: accessibility.highContrast,
  });
  const borderAlpha = selected ? 0.42 : mode === 'dark' ? 0.22 : 0.34;
  const commonStyle: StyleProp<ViewStyle> = [
    styles.base,
    {
      borderRadius: cornerRadius,
      borderColor: colorWithAlpha(theme.outlineVariant, borderAlpha),
    },
    style,
  ];

  if (glassMode === 'native') {
    return (
      <GlassView
        colorScheme={mode}
        glassEffectStyle="clear"
        isInteractive={interactive}
        tintColor={tintColor ?? colorWithAlpha(theme.surface, selected ? 0.34 : 0.22)}
        style={commonStyle}
        {...props}
      >
        {children}
      </GlassView>
    );
  }

  return (
    <View
      style={[
        commonStyle,
        styles.fallback,
        {
          backgroundColor:
            glassMode === 'opaque'
              ? colorWithAlpha(theme.surface, mode === 'dark' ? 0.94 : 0.9)
              : colorWithAlpha(theme.surface, mode === 'dark' ? 0.74 : 0.82),
          shadowOpacity: mode === 'dark' ? 0.35 : 0.16,
        },
      ]}
      {...props}
    >
      {children}
    </View>
  );
}

export function GlassPill(props: GlassSurfaceProps) {
  return <GlassSurface cornerRadius={ckRadius.pill} {...props} />;
}

const styles = StyleSheet.create({
  base: {
    borderWidth: StyleSheet.hairlineWidth,
    overflow: 'hidden',
  },
  fallback: {
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 3 },
    shadowRadius: 12,
    elevation: 4,
  },
});
