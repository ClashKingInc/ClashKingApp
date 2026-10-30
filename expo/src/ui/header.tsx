import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View, type ViewProps } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { GlassSurface } from './glass';
import { ckRadius } from './tokens';
import { useNativeRailBack, useNativeRailShare } from './native-back-context';
import { materialBackLabel, useI18n } from '../i18n';

// The global search field must stay anchored when its editable view opens.
export const globalSearchHeaderLayout = {
  height: 64,
  paddingHorizontal: 16,
  gap: 10,
  leadingWidth: 46,
  fieldHeight: 48,
} as const;

export function GlobalSearchHeaderFrame({ style, ...props }: ViewProps) {
  const { top } = useSafeAreaInsets();
  // Both inactive and editable headers consume the same provider inset on
  // their first render. A newly mounted native SafeAreaView can apply padding
  // after focus/layout, making Android search briefly jump toward the status bar.
  return <View {...props} style={[{ paddingTop: top }, style]} />;
}

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
  const { locale } = useI18n();
  const nativeBack = useNativeRailBack(label === materialBackLabel(locale) ? onPress : undefined);
  if (nativeBack && label === materialBackLabel(locale))
    return <View style={styles.headerButtonFrame} />;
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
  return glass ? (
    <GlassSurface cornerRadius={ckRadius.pill} style={styles.headerButtonFrame}>
      {button}
    </GlassSurface>
  ) : (
    button
  );
}

/** Plain, consistent action used over player, clan, Ranked, and Legends artwork. */
export function ProfileHeaderAction({
  icon,
  label,
  onPress,
  disabled = false,
  appLinkShare = false,
}: {
  icon: ReactNode;
  label: string;
  onPress: () => void;
  disabled?: boolean;
  appLinkShare?: boolean;
}) {
  const { locale } = useI18n();
  const isBack = label === materialBackLabel(locale);
  const nativeBack = useNativeRailBack(isBack ? onPress : undefined);
  const nativeShare = useNativeRailShare(appLinkShare && !disabled ? onPress : undefined, label);
  if (nativeBack && isBack) return <View style={styles.headerButtonFrame} />;
  if (nativeShare) return null;
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
