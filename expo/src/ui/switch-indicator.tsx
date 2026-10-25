import { View } from 'react-native';
import { colorWithAlpha } from './tokens';
import { useCKTheme } from './theme';

/** Fixed layout shared by settings switches; the owning row handles input. */
export function SwitchIndicator({ value }: { value: boolean }) {
  const theme = useCKTheme();
  return (
    <View
      pointerEvents="none"
      style={{
        width: 48,
        height: 28,
        borderRadius: 14,
        padding: 3,
        backgroundColor: value ? theme.primary : colorWithAlpha(theme.outlineVariant, 0.6),
        justifyContent: 'center',
      }}
    >
      <View
        style={{
          width: 22,
          height: 22,
          borderRadius: 11,
          backgroundColor: '#FFFFFF',
          alignSelf: value ? 'flex-end' : 'flex-start',
        }}
      />
    </View>
  );
}
