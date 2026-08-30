import type { PropsWithChildren } from 'react';
import {
  Pressable,
  StyleSheet,
  View,
  type PressableProps,
  type StyleProp,
  type ViewProps,
  type ViewStyle,
} from 'react-native';

import { ckOpacity, ckRadius, colorWithAlpha } from './tokens';
import { useCKTheme } from './theme';

export type SurfaceProps = PropsWithChildren<
  Omit<ViewProps, 'style'> & {
    radius?: number;
    strongBorder?: boolean;
    muted?: boolean;
    style?: StyleProp<ViewStyle>;
  }
>;

export function Surface({
  children,
  radius = ckRadius.card,
  strongBorder = false,
  muted = false,
  style,
  ...props
}: SurfaceProps) {
  const theme = useCKTheme();
  return (
    <View
      style={[
        styles.surface,
        {
          backgroundColor: muted
            ? colorWithAlpha(theme.surfaceContainerHighest, ckOpacity.fillMuted)
            : theme.card,
          borderColor: colorWithAlpha(
            theme.outlineVariant,
            strongBorder ? ckOpacity.borderStrong : ckOpacity.border,
          ),
          borderRadius: radius,
        },
        style,
      ]}
      {...props}
    >
      {children}
    </View>
  );
}

export function CardSurface(props: SurfaceProps) {
  return <Surface radius={ckRadius.card} {...props} />;
}

export function PillSurface(props: SurfaceProps) {
  return <Surface radius={ckRadius.pill} {...props} />;
}

export type PressableSurfaceProps = PropsWithChildren<
  Omit<PressableProps, 'style'> & {
    radius?: number;
    strongBorder?: boolean;
    style?: StyleProp<ViewStyle>;
  }
>;

export function PressableSurface({
  children,
  radius = ckRadius.chip,
  strongBorder = false,
  style,
  ...props
}: PressableSurfaceProps) {
  const theme = useCKTheme();
  return (
    <Pressable
      style={({ pressed }) => [
        styles.surface,
        styles.pressable,
        {
          backgroundColor: theme.card,
          borderColor: colorWithAlpha(
            theme.outlineVariant,
            strongBorder ? ckOpacity.borderStrong : ckOpacity.border,
          ),
          borderRadius: radius,
          transform: [{ scale: pressed ? 0.985 : 1 }],
        },
        style,
      ]}
      {...props}
    >
      {children}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  surface: {
    borderWidth: StyleSheet.hairlineWidth,
    overflow: 'hidden',
  },
  pressable: {
    minHeight: 44,
  },
});
