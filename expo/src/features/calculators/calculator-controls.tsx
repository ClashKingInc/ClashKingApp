import type { ReactNode } from 'react';
import { Pressable, StyleSheet, View } from 'react-native';
import { materialBackLabel, useI18n } from '../../i18n';
import { CKText, SelectionPicker, colorWithAlpha, useCKTheme } from '../../ui';
import { HeaderIconButton } from '../../ui/header';
import { ArrowLeft } from 'lucide-react-native';

export function CalcHeader({ onBack }: { onBack: () => void; title?: string; image?: string }) {
  const { locale } = useI18n();
  const theme = useCKTheme();
  return (
    <HeaderIconButton
      label={materialBackLabel(locale)}
      onPress={onBack}
      icon={<ArrowLeft size={22} color={theme.onSurface} />}
    />
  );
}

export function CalcSelect({
  title,
  value,
  options,
  onChange,
  searchable,
}: {
  title: string;
  value: string;
  options: readonly { key: string; label: string; icon?: ReactNode }[];
  onChange: (value: string) => void;
  searchable?: boolean;
}) {
  const { t } = useI18n();
  return (
    <View style={{ gap: 6, minWidth: 120, flex: 1 }}>
      <CKText muted role="metadata">
        {title}
      </CKText>
      <SelectionPicker
        title={title}
        accessibilityLabel={title}
        selectedKey={value}
        options={options}
        onSelect={onChange}
        searchPlaceholder={(searchable ?? options.length > 12) ? t('calcSearch') : undefined}
      />
    </View>
  );
}

export function CalcChip({
  label,
  selected,
  onPress,
  icon,
  disabled = false,
}: {
  label: string;
  selected?: boolean;
  onPress: () => void;
  icon?: ReactNode;
  disabled?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={label}
      accessibilityState={{ selected, disabled }}
      disabled={disabled}
      onPress={onPress}
      style={[
        calcStyles.chip,
        {
          opacity: disabled ? 0.45 : 1,
          backgroundColor: colorWithAlpha(
            selected ? theme.secondary : theme.onSurface,
            selected ? 0.18 : 0.06,
          ),
        },
        selected && { borderBottomWidth: 2, borderBottomColor: theme.secondary },
      ]}
    >
      {icon}
      <CKText
        role="labelLarge"
        style={[{ flexShrink: 1 }, selected ? { color: theme.secondary } : undefined]}
      >
        {label}
      </CKText>
    </Pressable>
  );
}

export const calcStyles = StyleSheet.create({
  page: { flex: 1 },
  content: {
    padding: 16,
    gap: 20,
    paddingBottom: 48,
    maxWidth: 1120,
    width: '100%',
    alignSelf: 'center',
  },
  row: { flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 12 },
  grow: { flex: 1, minWidth: 0 },
  chip: {
    minHeight: 42,
    borderRadius: 16,
    paddingHorizontal: 14,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  card: { padding: 16, gap: 14 },
  image: { width: 32, height: 32 },
  heading: { gap: 8 },
});
