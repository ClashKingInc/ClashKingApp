import { StyleSheet, View } from 'react-native';
import { ckRadius, useCKThemeMode } from '../../ui';

export function SuperchargeBorder() {
  const dark = useCKThemeMode() === 'dark';
  return (
    <View
      pointerEvents="none"
      accessible={false}
      accessibilityElementsHidden
      importantForAccessibility="no-hide-descendants"
      testID="damage-supercharge-border"
      style={[styles.rim, { borderColor: dark ? '#62A0FF' : '#337EE5' }]}
    />
  );
}

const styles = StyleSheet.create({
  rim: {
    position: 'absolute',
    inset: 0,
    borderWidth: 1.5,
    borderRadius: ckRadius.card,
  },
});
