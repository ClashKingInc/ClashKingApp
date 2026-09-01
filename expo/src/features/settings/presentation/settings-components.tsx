import { Children, Fragment, type ReactElement, type ReactNode } from 'react';
import {
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
  type RefreshControlProps,
} from 'react-native';
import { ArrowLeft, Check, ChevronRight } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { materialBackLabel, useI18n } from '../../../i18n';
import { CKText, Surface, ckRadius, ckSpacing, colorWithAlpha, useCKTheme } from '../../../ui';

export function SettingsPage({
  title,
  children,
  onBack,
  backLabel,
  refreshControl,
}: {
  title: string;
  children: ReactNode;
  onBack?: () => void;
  backLabel?: string;
  refreshControl?: ReactElement<RefreshControlProps>;
}) {
  const theme = useCKTheme();
  const { locale } = useI18n();
  return (
    <SafeAreaView
      edges={['top', 'bottom']}
      style={[styles.safe, { backgroundColor: theme.surface }]}
    >
      <View style={styles.header}>
        {onBack ? (
          <Pressable
            accessibilityLabel={backLabel ?? materialBackLabel(locale)}
            accessibilityRole="button"
            hitSlop={8}
            onPress={onBack}
            style={({ pressed }) => [styles.back, pressed && styles.pressed]}
          >
            <ArrowLeft color={theme.onSurface} size={24} />
          </Pressable>
        ) : null}
        <CKText role="screenTitle">{title}</CKText>
      </View>
      <ScrollView contentContainerStyle={styles.page} refreshControl={refreshControl}>
        {children}
      </ScrollView>
    </SafeAreaView>
  );
}

export function SettingsSection({
  title,
  children,
  variant = 'compact',
}: {
  title: string;
  children: ReactNode;
  variant?: 'compact' | 'notification';
}) {
  const theme = useCKTheme();
  const items = Children.toArray(children);
  const notification = variant === 'notification';
  return (
    <View style={notification ? styles.notificationSection : styles.section}>
      <CKText
        muted
        role={notification ? 'titleSmall' : 'labelLarge'}
        style={notification ? styles.notificationSectionTitle : styles.sectionTitle}
      >
        {title}
      </CKText>
      <Surface radius={notification ? 18 : ckRadius.chip}>
        {items.map((child, index) => (
          <Fragment key={index}>
            {child}
            {index < items.length - 1 ? (
              <View
                accessibilityElementsHidden
                importantForAccessibility="no"
                style={[
                  styles.divider,
                  !notification && styles.compactDivider,
                  { backgroundColor: theme.outlineVariant },
                ]}
              />
            ) : null}
          </Fragment>
        ))}
      </Surface>
    </View>
  );
}

export function SettingsTile({
  icon,
  title,
  subtitle,
  trailing,
  destructive = false,
  disabled = false,
  showChevron = true,
  onPress,
}: {
  icon: ReactNode;
  title: string;
  subtitle?: string;
  trailing?: string | ReactNode;
  destructive?: boolean;
  disabled?: boolean;
  showChevron?: boolean;
  onPress?: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole={onPress ? 'button' : 'text'}
      accessibilityState={{ disabled }}
      disabled={disabled || !onPress}
      onPress={onPress}
      style={({ pressed }) => [
        styles.tile,
        subtitle ? styles.tileWithSubtitle : styles.tileWithoutSubtitle,
        disabled && styles.disabled,
        pressed && styles.pressed,
      ]}
    >
      <View style={styles.icon}>{icon}</View>
      <View style={styles.tileCopy}>
        <CKText
          role="bodyLarge"
          numberOfLines={1}
          style={[styles.tileTitle, { color: destructive ? theme.error : theme.onSurface }]}
        >
          {title}
        </CKText>
        {subtitle ? (
          <CKText muted role="bodySmall" numberOfLines={1} style={styles.tileSubtitle}>
            {subtitle}
          </CKText>
        ) : null}
      </View>
      {typeof trailing === 'string' ? (
        <CKText muted role="bodyMedium" style={styles.trailing}>
          {trailing}
        </CKText>
      ) : (
        trailing
      )}
      {showChevron && onPress ? <ChevronRight color={theme.onSurfaceVariant} size={22} /> : null}
    </Pressable>
  );
}

export function ChoiceDialog<T extends string>({
  visible,
  title,
  subtitle,
  choices,
  selected,
  onSelect,
  onClose,
  heightFactor,
}: {
  visible: boolean;
  title: string;
  subtitle?: string;
  choices: readonly { value: T; label: string; subtitle?: string; icon?: ReactNode }[];
  selected: T;
  onSelect: (value: T) => void;
  onClose: () => void;
  heightFactor?: number;
}) {
  const theme = useCKTheme();
  return (
    <Modal transparent animationType="slide" visible={visible} onRequestClose={onClose}>
      <SafeAreaView style={styles.overlay}>
        <Pressable
          accessibilityElementsHidden
          importantForAccessibility="no-hide-descendants"
          onPress={onClose}
          style={StyleSheet.absoluteFill}
        />
        <Surface
          radius={ckRadius.card}
          style={[styles.sheet, heightFactor ? { height: `${heightFactor * 100}%` } : undefined]}
          accessibilityViewIsModal
        >
          <View style={[styles.dragHandle, { backgroundColor: theme.onSurfaceVariant }]} />
          <View style={styles.sheetHeader}>
            <View style={styles.tileCopy}>
              <CKText role="titleLarge" style={{ fontWeight: '800' }}>
                {title}
              </CKText>
              {subtitle ? <CKText muted>{subtitle}</CKText> : null}
            </View>
          </View>
          <Surface radius={ckRadius.chip} style={styles.choiceGroup}>
            <ScrollView>
              {choices.map((choice, index) => {
                const isSelected = choice.value === selected;
                return (
                  <Fragment key={choice.value}>
                    <Pressable
                      accessibilityRole="radio"
                      accessibilityState={{ checked: isSelected }}
                      onPress={() => {
                        onSelect(choice.value);
                        onClose();
                      }}
                      style={({ pressed }) => [
                        styles.choice,
                        choice.subtitle ? styles.choiceWithSubtitle : styles.choiceWithoutSubtitle,
                        isSelected && {
                          backgroundColor: colorWithAlpha(theme.primary, 0.08),
                        },
                        pressed && styles.pressed,
                      ]}
                    >
                      <View style={styles.choiceLeading}>{choice.icon}</View>
                      <View style={styles.tileCopy}>
                        <CKText numberOfLines={1} style={styles.choiceTitle}>
                          {choice.label}
                        </CKText>
                        {choice.subtitle ? (
                          <CKText
                            muted
                            numberOfLines={1}
                            role="bodySmall"
                            style={styles.choiceSubtitle}
                          >
                            {choice.subtitle}
                          </CKText>
                        ) : null}
                      </View>
                      <View style={styles.choiceCheck}>
                        {isSelected ? <Check color={theme.primary} size={20} /> : null}
                      </View>
                    </Pressable>
                    {index < choices.length - 1 ? (
                      <View
                        style={[
                          styles.choiceDivider,
                          { backgroundColor: colorWithAlpha(theme.outlineVariant, 0.32) },
                        ]}
                      />
                    ) : null}
                  </Fragment>
                );
              })}
            </ScrollView>
          </Surface>
        </Surface>
      </SafeAreaView>
    </Modal>
  );
}

export function SettingSwitch({
  value,
  disabled = false,
  onChange,
}: {
  value: boolean;
  disabled?: boolean;
  onChange: (value: boolean) => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityState={{ checked: value, disabled }}
      disabled={disabled}
      onPress={() => onChange(!value)}
      style={[
        styles.switch,
        { backgroundColor: value ? theme.primary : colorWithAlpha(theme.outlineVariant, 0.6) },
      ]}
    >
      <View style={[styles.knob, { alignSelf: value ? 'flex-end' : 'flex-start' }]} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  safe: { flex: 1 },
  header: {
    minHeight: 58,
    paddingHorizontal: 16,
    paddingTop: 10,
    paddingBottom: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  back: { width: 40, height: 40, marginLeft: -8, alignItems: 'center', justifyContent: 'center' },
  page: { paddingHorizontal: 16, paddingTop: 2, paddingBottom: 28 },
  section: { marginBottom: 14 },
  notificationSection: { marginBottom: 18 },
  sectionTitle: { paddingLeft: 8, paddingBottom: 5, fontWeight: '700' },
  notificationSectionTitle: { paddingHorizontal: 4, paddingBottom: 8, fontWeight: '800' },
  divider: { height: StyleSheet.hairlineWidth, opacity: 0.34 },
  compactDivider: { marginLeft: 55, opacity: 0.42 },
  tile: {
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  tileWithoutSubtitle: { height: 50 },
  tileWithSubtitle: { height: 62 },
  icon: { width: 28, alignItems: 'center' },
  tileCopy: { flex: 1, gap: 2 },
  tileTitle: { fontWeight: '500', fontSize: 17 },
  tileSubtitle: { fontSize: 13 },
  trailing: { fontSize: 16 },
  disabled: { opacity: 0.46 },
  pressed: { opacity: 0.72 },
  overlay: { flex: 1, justifyContent: 'flex-end', backgroundColor: '#00000066' },
  sheet: {
    maxHeight: '82%',
    borderBottomLeftRadius: 0,
    borderBottomRightRadius: 0,
    paddingBottom: ckSpacing.lg,
  },
  dragHandle: {
    width: 32,
    height: 4,
    borderRadius: 2,
    opacity: 0.4,
    alignSelf: 'center',
    marginTop: 8,
  },
  sheetHeader: {
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 14,
    flexDirection: 'row',
    alignItems: 'center',
  },
  choiceGroup: { marginHorizontal: 16, flexShrink: 1 },
  choice: {
    paddingHorizontal: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  choiceWithoutSubtitle: { height: 56 },
  choiceWithSubtitle: { height: 66 },
  choiceLeading: { width: 34, height: 34, alignItems: 'center', justifyContent: 'center' },
  choiceTitle: { fontWeight: '600', fontSize: 17 },
  choiceSubtitle: { marginTop: 2, fontSize: 13 },
  choiceCheck: { width: 20, height: 20 },
  choiceDivider: { height: StyleSheet.hairlineWidth, marginLeft: 58 },
  switch: { width: 48, height: 28, borderRadius: 14, padding: 3, justifyContent: 'center' },
  knob: { width: 22, height: 22, borderRadius: 11, backgroundColor: '#FFFFFF' },
});
