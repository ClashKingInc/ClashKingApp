import type { ReactNode } from 'react';
import { Pressable, StyleSheet } from 'react-native';

import { GlassSurface } from './glass';
import { ckRadius } from './tokens';

export function HeaderIconButton({
  icon,
  label,
  onPress,
  glass = true,
}: {
  icon: ReactNode;
  label: string;
  onPress: () => void;
  glass?: boolean;
}) {
  const button = (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      hitSlop={8}
      onPress={onPress}
      style={styles.headerButton}
    >
      {icon}
    </Pressable>
  );
  return glass ? <GlassSurface cornerRadius={ckRadius.pill}>{button}</GlassSurface> : button;
}

const styles = StyleSheet.create({
  headerButton: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
