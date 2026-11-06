import { StyleSheet, View, type ViewProps } from 'react-native';
import { useCKTheme } from './theme';
import { colorWithAlpha } from './tokens';

/** Full-width secondary stats inside a card whose outer surface clips its corners. */
export function CardStatsFooter({ style, ...props }: ViewProps) {
  const theme = useCKTheme();
  return (
    <View
      {...props}
      style={[styles.footer, { backgroundColor: colorWithAlpha(theme.onSurface, 0.035) }, style]}
    />
  );
}

const styles = StyleSheet.create({
  footer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
});
