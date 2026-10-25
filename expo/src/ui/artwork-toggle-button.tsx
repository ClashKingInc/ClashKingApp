import {
  Pressable,
  StyleSheet,
  type PressableProps,
  type StyleProp,
  type ViewStyle,
} from 'react-native';
import { useCKTheme } from './theme';
import { colorWithAlpha } from './tokens';

/** Compact artwork toggle shared by profile filters and breakdown controls. */
export function ArtworkToggleButton({
  active,
  style,
  ...props
}: Omit<PressableProps, 'style'> & {
  active: boolean;
  style?: StyleProp<ViewStyle>;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      {...props}
      style={[
        styles.button,
        {
          borderColor: active ? theme.secondary : 'transparent',
          backgroundColor: colorWithAlpha(
            active ? theme.secondary : theme.onSurface,
            active ? 0.2 : 0.06,
          ),
        },
        style,
      ]}
    />
  );
}

const styles = StyleSheet.create({
  button: {
    width: 44,
    height: 44,
    flexShrink: 0,
    borderRadius: 14,
    borderWidth: 1.5,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
