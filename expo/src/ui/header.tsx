import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';

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
  // Size the material itself: a sized child does not stop a column parent
  // stretching the glass wrapper into a full-width pill.
  return glass ? <GlassSurface cornerRadius={ckRadius.pill} style={styles.headerButtonFrame}>{button}</GlassSurface> : button;
}

/** Plain, consistent action used over player, clan, Ranked, and Legends artwork. */
export function ProfileHeaderAction({
  icon,
  label,
  onPress,
  disabled = false,
}: {
  icon: ReactNode;
  label: string;
  onPress: () => void;
  disabled?: boolean;
}) {
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      disabled={disabled}
      hitSlop={8}
      onPress={onPress}
      style={[styles.profileAction, disabled && styles.disabled]}
    >
      <View style={styles.profileActionIcon}>{icon}</View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  headerButtonFrame: {
    width: 44,
    height: 44,
    flexShrink: 0,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerButton: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
  },
  profileAction: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  profileActionIcon: { opacity: 0.9 },
  disabled: { opacity: 0.4 },
});
