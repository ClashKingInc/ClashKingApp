import type { ReactNode } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
  type TextInputProps,
} from 'react-native';
import { CheckCircle2, Circle, Eye, EyeOff, Shield } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n, type MessageKey } from '../../../i18n';
import {
  CKText,
  LoadingIndicator,
  MobileWebImage,
  Surface,
  ckControlHeight,
  ckRadius,
  ckSpacing,
  colorWithAlpha,
  useCKTheme,
  useCKThemeMode,
} from '../../../ui';
import type { PasswordCriteria } from './validation';

export type Translate = (key: MessageKey) => string;

export function AuthPageShell({
  children,
  title,
  description,
  maxWidth = 560,
  center = false,
}: {
  children: ReactNode;
  title?: string;
  description?: string;
  maxWidth?: number;
  center?: boolean;
}) {
  const theme = useCKTheme();
  const mode = useCKThemeMode();
  const { t } = useI18n();
  return (
    <SafeAreaView
      style={[styles.safe, { backgroundColor: theme.surface }]}
      edges={['top', 'bottom']}
    >
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        style={styles.flex}
      >
        <ScrollView
          keyboardDismissMode="on-drag"
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={[styles.page, center && styles.center]}
        >
          <View style={[styles.content, { maxWidth }]}>
            <View
              accessibilityLabel={t('appTitle')}
              accessibilityRole="image"
              style={styles.logoFrame}
            >
              <MobileWebImage
                imageUrl={mode === 'dark' ? ImageAssets.darkModeLogo : ImageAssets.lightModeLogo}
                contentFit="contain"
                errorFallback={<Shield color={theme.onSurfaceVariant} size={28} />}
                style={styles.logo}
              />
            </View>
            {title ? (
              <CKText role="screenTitle" style={styles.centerText}>
                {title}
              </CKText>
            ) : null}
            {description ? (
              <CKText muted style={styles.centerText}>
                {description}
              </CKText>
            ) : null}
            {children}
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

export function AuthPanel({ children }: { children: ReactNode }) {
  return (
    <Surface radius={20} style={styles.panel}>
      {children}
    </Surface>
  );
}

export function AuthField({
  label,
  error,
  leading,
  secure,
  onToggleSecure,
  toggleLabel,
  ...props
}: TextInputProps & {
  label: string;
  error?: string;
  leading?: ReactNode;
  secure?: boolean;
  onToggleSecure?: () => void;
  toggleLabel?: string;
}) {
  const theme = useCKTheme();
  return (
    <View style={styles.fieldGroup}>
      <CKText role="bodySmall" style={styles.fieldLabel}>
        {label}
      </CKText>
      <View
        style={[
          styles.fieldShell,
          {
            borderColor: colorWithAlpha(
              error ? theme.error : theme.outlineVariant,
              error ? 0.8 : 0.42,
            ),
            backgroundColor: theme.surface,
          },
        ]}
      >
        {leading ? <View style={styles.fieldLeading}>{leading}</View> : null}
        <TextInput
          accessibilityLabel={label}
          allowFontScaling
          placeholderTextColor={theme.onSurfaceVariant}
          secureTextEntry={secure}
          style={[styles.input, { color: theme.onSurface }]}
          {...props}
        />
        {onToggleSecure ? (
          <Pressable
            accessibilityLabel={toggleLabel}
            accessibilityRole="button"
            onPress={onToggleSecure}
            style={styles.fieldAction}
          >
            {secure ? (
              <Eye color={theme.onSurfaceVariant} size={20} />
            ) : (
              <EyeOff color={theme.onSurfaceVariant} size={20} />
            )}
          </Pressable>
        ) : null}
      </View>
      {error ? (
        <CKText accessibilityLiveRegion="polite" style={{ color: theme.error }} role="bodySmall">
          {error}
        </CKText>
      ) : null}
    </View>
  );
}

export function PrimaryAction({
  label,
  loading = false,
  disabled = false,
  onPress,
  color,
  leading,
}: {
  label: string;
  loading?: boolean;
  disabled?: boolean;
  onPress: () => void;
  color?: string;
  leading?: ReactNode;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      accessibilityState={{ disabled: disabled || loading, busy: loading }}
      disabled={disabled || loading}
      onPress={onPress}
      style={({ pressed }) => [
        styles.primaryAction,
        { backgroundColor: color ?? theme.primary },
        (disabled || loading) && styles.disabled,
        pressed && styles.pressed,
      ]}
    >
      {loading ? (
        <LoadingIndicator />
      ) : (
        <View style={styles.primaryActionContent}>
          {leading}
          <CKText role="bodyLarge" style={{ color: theme.onPrimary, fontWeight: '600' }}>
            {label}
          </CKText>
        </View>
      )}
    </Pressable>
  );
}

export function TextAction({
  label,
  onPress,
  disabled = false,
}: {
  label: string;
  onPress: () => void;
  disabled?: boolean;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      disabled={disabled}
      onPress={onPress}
      style={({ pressed }) => [
        styles.textAction,
        disabled && styles.disabled,
        pressed && styles.pressed,
      ]}
    >
      <CKText role="bodySmall" style={{ color: theme.primary }}>
        {label}
      </CKText>
    </Pressable>
  );
}

export function InlineError({ message }: { message?: string | null }) {
  const theme = useCKTheme();
  if (!message) return null;
  return (
    <CKText accessibilityLiveRegion="assertive" style={[styles.error, { color: theme.error }]}>
      {message}
    </CKText>
  );
}

export function PasswordRequirements({
  criteria,
  t,
}: {
  criteria: PasswordCriteria;
  t: Translate;
}) {
  const theme = useCKTheme();
  const rows: [keyof PasswordCriteria, MessageKey][] = [
    ['minLength', 'authPasswordTooShort'],
    ['uppercase', 'authPasswordUppercase'],
    ['lowercase', 'authPasswordLowercase'],
    ['number', 'authPasswordNumber'],
    ['special', 'authPasswordSpecial'],
  ];
  return (
    <View accessibilityRole="list" style={styles.requirements}>
      <CKText muted role="bodySmall" style={styles.strong}>
        {t('authPasswordHeader')}
      </CKText>
      {rows.map(([key, label]) => (
        <View key={key} style={styles.requirement}>
          {criteria[key] ? (
            <CheckCircle2 color={theme.secondary} size={16} />
          ) : (
            <Circle color={theme.onSurfaceVariant} size={16} />
          )}
          <CKText muted role="bodySmall">
            {t(label)}
          </CKText>
        </View>
      ))}
    </View>
  );
}

export function errorText(error: unknown): string {
  return String(error)
    .replace(/^\w*Exception:\s*/, '')
    .replace(/^Error:\s*/, '');
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  safe: { flex: 1 },
  page: {
    flexGrow: 1,
    alignItems: 'center',
    paddingHorizontal: ckSpacing.lg,
    paddingTop: ckSpacing.sm,
    paddingBottom: ckSpacing.xl,
  },
  center: { justifyContent: 'center' },
  content: { width: '100%', alignItems: 'stretch', gap: ckSpacing.sm },
  logoFrame: {
    width: 80,
    height: 80,
    alignSelf: 'center',
    alignItems: 'center',
    justifyContent: 'center',
  },
  logo: { width: 80, height: 80, zIndex: 1 },
  centerText: { textAlign: 'center' },
  panel: { padding: ckSpacing.lg, gap: ckSpacing.lg, marginTop: ckSpacing.lg },
  fieldGroup: { gap: ckSpacing.xs },
  fieldLabel: { fontWeight: '600' },
  fieldShell: {
    minHeight: ckControlHeight.standard,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: ckRadius.control,
    flexDirection: 'row',
    alignItems: 'center',
  },
  input: {
    flex: 1,
    minHeight: ckControlHeight.standard,
    paddingHorizontal: ckSpacing.md,
    fontSize: 16,
  },
  fieldAction: { width: 48, minHeight: 48, alignItems: 'center', justifyContent: 'center' },
  fieldLeading: { paddingLeft: ckSpacing.md },
  primaryAction: {
    minHeight: ckControlHeight.standard,
    borderRadius: ckRadius.control,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: ckSpacing.lg,
  },
  primaryActionContent: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm },
  textAction: { minHeight: 44, justifyContent: 'center', paddingHorizontal: ckSpacing.xs },
  disabled: { opacity: 0.4 },
  pressed: { opacity: 0.72 },
  error: { textAlign: 'center', fontWeight: '600' },
  requirements: { gap: ckSpacing.xs },
  requirement: { flexDirection: 'row', alignItems: 'center', gap: ckSpacing.sm },
  strong: { fontWeight: '600' },
});
