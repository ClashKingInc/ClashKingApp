import { useAdaptiveLayout } from '../../../ui/adaptive-layout';
import { InlineBackControl } from '../../../ui/native-back-context';
import { modalOrientations } from '../../../ui/modal-orientations';
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
import { SwitchIndicator } from '../../../ui/switch-indicator';
import { CKText, Surface, ckRadius, ckSpacing, colorWithAlpha, useCKTheme } from '../../../ui';

export function SettingsPage({
  title,
  children,
  onBack,
  backLabel,
  refreshControl,
  wide = false,
}: {
  title: string;
  children: ReactNode;
  onBack?: () => void;
  backLabel?: string;
  refreshControl?: ReactElement<RefreshControlProps>;
  wide?: boolean;
}) {
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  const { locale } = useI18n();
  return (
    <SafeAreaView
      edges={
        layout.isExpanded || layout.isDuo ? ['top', 'bottom', 'left', 'right'] : ['top', 'bottom']
      }
      style={[styles.safe, { backgroundColor: theme.surface }]}
    >
      <View
        style={[
          styles.header,
          (layout.isExpanded || layout.isDuo) && {
            width: '100%',
            maxWidth: !layout.isExpanded
              ? layout.contentMaxWidth
              : wide
                ? layout.contentMaxWidth
                : layout.readableMaxWidth,
            alignSelf: 'center',
          },
        ]}
      >
        {onBack ? (
          <InlineBackControl onBack={onBack}>
            <Pressable
              accessibilityLabel={backLabel ?? materialBackLabel(locale)}
              accessibilityRole="button"
              hitSlop={8}
              onPress={onBack}
              style={({ pressed }) => [styles.back, pressed && styles.pressed]}
            >
              <ArrowLeft color={theme.onSurface} size={24} />
            </Pressable>
          </InlineBackControl>
        ) : null}
        <CKText role="screenTitle">{title}</CKText>
      </View>
      <ScrollView
        contentContainerStyle={[
          styles.page,
          (layout.isExpanded || layout.isDuo) && {
            width: '100%',
            maxWidth: !layout.isExpanded
              ? layout.contentMaxWidth
              : wide
                ? layout.contentMaxWidth
                : layout.readableMaxWidth,
            alignSelf: 'center',
          },
        ]}
        refreshControl={refreshControl}
      >
        {children}
      </ScrollView>
    </SafeAreaView>
  );
}

/** Preserve phone section order; large windows get two independent columns. */
export function SettingsColumns({ children }: { children: ReactNode }) {
  const layout = useAdaptiveLayout();
  if (!layout.isExpanded || layout.columns(420, 2) < 2) return <>{children}</>;
  return (
    <View style={{ flexDirection: 'row', alignItems: 'flex-start', gap: 24 }}>
      {Children.toArray(children).map((child, index) => (
        <View key={index} style={{ flex: 1, minWidth: 0 }}>
          {child}
        </View>
      ))}
    </View>
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
  subtitleNumberOfLines = 1,
  trailing,
  destructive = false,
  disabled = false,
  showChevron = true,
  onPress,
}: {
  icon: ReactNode;
  title: string;
  subtitle?: string;
  subtitleNumberOfLines?: number;
  trailing?: string | ReactNode;
  destructive?: boolean;
  disabled?: boolean;
  showChevron?: boolean;
  onPress?: () => void;
}) {
  const theme = useCKTheme();
  const layout = useAdaptiveLayout();
  return (
    <Pressable
      accessibilityRole={onPress ? 'button' : 'text'}
      accessibilityState={{ disabled }}
      disabled={disabled || !onPress}
      onPress={onPress}
      style={({ pressed }) => [
        styles.tile,
        subtitle ? styles.tileWithSubtitle : styles.tileWithoutSubtitle,
        subtitle && subtitleNumberOfLines > 1 && styles.multilineTile,
        layout.isExpanded && {
          height: undefined,
          minHeight: subtitle ? 82 : 64,
          paddingVertical: 14,
          gap: 14,
        },
        disabled && styles.disabled,
        pressed && styles.pressed,
      ]}
    >
      <View style={styles.icon}>{icon}</View>
      <View style={styles.tileCopy}>
        <CKText
          role="bodyLarge"
          numberOfLines={layout.isExpanded || subtitleNumberOfLines > 1 ? 2 : 1}
          style={[
            styles.tileTitle,
            layout.isExpanded && { fontSize: 20, lineHeight: 25 },
            { color: destructive ? theme.error : theme.onSurface },
          ]}
        >
          {title}
        </CKText>
        {subtitle ? (
          <CKText
            muted
            role="bodySmall"
            numberOfLines={
              layout.isExpanded ? Math.max(2, subtitleNumberOfLines) : subtitleNumberOfLines
            }
            style={[styles.tileSubtitle, layout.isExpanded && { fontSize: 15, lineHeight: 21 }]}
          >
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

/** A compact choice is part of the settings row, not a second floating control.
 * The choices identify this setting visually; each accessible label retains its title. */
export function SettingsChoiceTile<T extends string>({
  icon,
  title,
  value,
  options,
  onChange,
  isRtl = false,
}: {
  icon: ReactNode;
  title: string;
  value: T;
  options: readonly { value: T; label: string }[];
  onChange: (value: T) => void;
  isRtl?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <View
      style={{ flexDirection: isRtl ? 'row-reverse' : 'row', alignItems: 'center', height: 50 }}
    >
      <View style={{ width: 56, alignItems: 'center', justifyContent: 'center' }}>{icon}</View>
      <View
        style={{
          flex: 1,
          height: 38,
          marginEnd: 8,
          padding: 3,
          borderRadius: 10,
          backgroundColor: colorWithAlpha(theme.onSurface, 0.06),
          flexDirection: isRtl ? 'row-reverse' : 'row',
          minWidth: 0,
        }}
      >
        {options.map((option) => {
          const selected = option.value === value;
          return (
            <Pressable
              key={option.value}
              accessibilityRole="radio"
              accessibilityState={{ checked: selected }}
              accessibilityLabel={`${title}: ${option.label}`}
              onPress={() => onChange(option.value)}
              hitSlop={{ top: 6, bottom: 6 }}
              style={({ pressed }) => ({
                flex: 1,
                minWidth: 0,
                height: 32,
                borderRadius: 7,
                paddingHorizontal: 4,
                paddingVertical: 2,
                justifyContent: 'center',
                alignItems: 'center',
                backgroundColor: selected
                  ? theme.surfaceContainerHighest
                  : pressed
                    ? colorWithAlpha(theme.onSurface, 0.05)
                    : 'transparent',
              })}
            >
              <CKText
                role="bodyMedium"
                skeleton={false}
                style={{
                  textAlign: 'center',
                  fontWeight: selected ? '700' : '500',
                  color: selected ? theme.onSurface : theme.onSurfaceVariant,
                }}
              >
                {option.label}
              </CKText>
              {selected ? (
                <View
                  pointerEvents="none"
                  style={{
                    position: 'absolute',
                    bottom: 1,
                    left: '40%',
                    right: '40%',
                    height: 2,
                    borderRadius: 2,
                    backgroundColor: theme.primary,
                  }}
                />
              ) : null}
            </Pressable>
          );
        })}
      </View>
    </View>
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
  const layout = useAdaptiveLayout();
  return (
    <Modal
      supportedOrientations={modalOrientations}
      transparent
      animationType="slide"
      visible={visible}
      onRequestClose={onClose}
    >
      <SafeAreaView
        style={[styles.overlay, layout.isExpanded && { justifyContent: 'center', padding: 24 }]}
      >
        <Pressable
          accessibilityElementsHidden
          importantForAccessibility="no-hide-descendants"
          onPress={onClose}
          style={StyleSheet.absoluteFill}
        />
        <Surface
          radius={ckRadius.card}
          style={[
            styles.sheet,
            heightFactor ? { height: `${heightFactor * 100}%` } : undefined,
            layout.isExpanded && {
              width: '100%',
              maxWidth: 560,
              alignSelf: 'center',
              borderBottomLeftRadius: ckRadius.card,
              borderBottomRightRadius: ckRadius.card,
            },
          ]}
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
                        layout.isExpanded && {
                          height: undefined,
                          minHeight: choice.subtitle ? 82 : 64,
                          paddingVertical: 14,
                        },
                        isSelected && {
                          backgroundColor: colorWithAlpha(theme.primary, 0.08),
                        },
                        pressed && styles.pressed,
                      ]}
                    >
                      <View style={styles.choiceLeading}>{choice.icon}</View>
                      <View style={styles.tileCopy}>
                        <CKText
                          numberOfLines={1}
                          style={[
                            styles.choiceTitle,
                            layout.isExpanded && { fontSize: 20, lineHeight: 25 },
                          ]}
                        >
                          {choice.label}
                        </CKText>
                        {choice.subtitle ? (
                          <CKText
                            muted
                            numberOfLines={1}
                            role="bodySmall"
                            style={[
                              styles.choiceSubtitle,
                              layout.isExpanded && { fontSize: 15, lineHeight: 21 },
                            ]}
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
  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityState={{ checked: value, disabled }}
      disabled={disabled}
      onPress={() => onChange(!value)}
      style={{ flexShrink: 0, opacity: disabled ? 0.5 : 1 }}
    >
      <SwitchIndicator value={value} />
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
  multilineTile: { height: undefined, minHeight: 62, paddingVertical: 12 },
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
