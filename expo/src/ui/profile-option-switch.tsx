import type { ReactElement, ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { SwitchIndicator } from './switch-indicator';
import { CKText } from './text';
import { LoadingIndicator } from './feedback';

// Shared by player and clan Options so native controls and type stay identical.
export function ProfileOptionSwitch({
  icon,
  title,
  subtitle,
  trailing,
  value,
  enabled = true,
  loading = false,
  onChange,
}: {
  icon: ReactElement;
  title: string;
  subtitle?: string;
  trailing?: ReactNode;
  value: boolean;
  enabled?: boolean;
  loading?: boolean;
  onChange: (value: boolean) => void;
}) {
  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityLabel={title}
      accessibilityState={{ checked: value, disabled: !enabled }}
      disabled={!enabled}
      onPress={() => onChange(!value)}
      style={[profileOptionStyles.option, !enabled && profileOptionStyles.disabled]}
    >
      <View style={profileOptionStyles.optionIcon}>{loading ? <LoadingIndicator /> : icon}</View>
      <View style={profileOptionStyles.optionCopy}>
        <CKText style={profileOptionStyles.rowTitle}>{title}</CKText>
        {subtitle ? (
          <CKText muted role="bodySmall">
            {subtitle}
          </CKText>
        ) : null}
      </View>
      <View style={profileOptionStyles.controls}>
        {trailing}
        {/* One input owner prevents native-switch tap interception and overflow. */}
        <SwitchIndicator value={value} />
      </View>
    </Pressable>
  );
}

export const profileOptionStyles = StyleSheet.create({
  optionsToggle: {
    minHeight: 40,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    gap: 8,
  },
  optionTitle: { flex: 1, fontWeight: '700' },
  rowTitle: { fontWeight: '700' },
  options: { paddingHorizontal: 8, paddingBottom: 4 },
  option: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 6,
    paddingVertical: 6,
    borderRadius: 12,
  },
  optionIcon: {
    width: 30,
    height: 30,
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  optionCopy: { flex: 1, minWidth: 0, gap: 1, justifyContent: 'center' },
  controls: { flexDirection: 'row', alignItems: 'center', gap: 8, flexShrink: 0 },
  // Reserve the native switch's unscaled width: visual scaling does not change
  // Yoga measurement, and iOS otherwise paints past a clipped settings row.
  switchFrame: {
    width: 58,
    height: 34,
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  switch: { transform: [{ scale: 0.85 }] },
  disabled: { opacity: 0.45 },
});
