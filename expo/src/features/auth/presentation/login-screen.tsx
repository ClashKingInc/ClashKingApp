import { useState, type ReactNode } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import { Gamepad2, LockKeyhole, Mail, Shield } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { ImageAssets } from '../../../core/assets/image-assets';
import { useI18n } from '../../../i18n';
import { CKText, MobileWebImage, ckColors, useCKTheme, useCKThemeMode } from '../../../ui';
import type { AuthPresentationService, PostAuthPresentationProps } from './contracts';
import { AuthField, InlineError, PrimaryAction, TextAction, errorText } from './auth-components';
import { PostAuthGate } from './post-auth';
import { isValidEmail } from './validation';

export function LoginScreen({
  auth,
  postAuth,
  discordEnabled = true,
  prefillEmail = '',
  onRegister,
  onForgotPassword,
  onVerificationRequired,
  onJoinDiscord,
  onEmailSupport,
  onMaintenance,
  isVerificationRequired = (error) => String(error).includes('EmailVerificationRequired'),
}: {
  auth: Pick<AuthPresentationService, 'signInWithDiscord' | 'signInWithEmail'>;
  postAuth: PostAuthPresentationProps;
  discordEnabled?: boolean;
  prefillEmail?: string;
  onRegister: () => void;
  onForgotPassword: () => void;
  onVerificationRequired: (email: string) => void;
  onJoinDiscord: () => void;
  onEmailSupport: () => void;
  onMaintenance: () => void;
  viewportWidth?: number;
  platform?: string;
  isVerificationRequired?: (error: unknown) => boolean;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const themeMode = useCKThemeMode();
  const [email, setEmail] = useState(prefillEmail);
  const [password, setPassword] = useState('');
  const [passwordHidden, setPasswordHidden] = useState(true);
  const [errors, setErrors] = useState<{ email?: string; password?: string; action?: string }>({
    action: prefillEmail ? t('authErrorEmailAlreadyRegistered') : undefined,
  });
  const [loading, setLoading] = useState(false);
  const [authenticated, setAuthenticated] = useState(false);

  if (authenticated) return <PostAuthGate {...postAuth} />;

  const signInEmail = async () => {
    const next = {
      email:
        email.trim().length === 0
          ? t('authEmailRequired')
          : !isValidEmail(email.trim())
            ? t('authEmailInvalid')
            : undefined,
      password: password.length === 0 ? t('authPasswordRequired') : undefined,
    };
    setErrors(next);
    if (next.email || next.password) return;
    setLoading(true);
    try {
      await auth.signInWithEmail(email.trim(), password);
      setAuthenticated(true);
    } catch (error) {
      if (isVerificationRequired(error)) onVerificationRequired(email.trim());
      else if (/\b(?:500|503)\b/.test(String(error))) onMaintenance();
      else setErrors({ action: errorText(error) });
    } finally {
      setLoading(false);
    }
  };
  const signInDiscord = async () => {
    setLoading(true);
    setErrors({});
    try {
      await auth.signInWithDiscord();
      setAuthenticated(true);
    } catch (error) {
      if (/\b(?:500|503)\b/.test(String(error))) onMaintenance();
      else setErrors({ action: errorText(error) });
    } finally {
      setLoading(false);
    }
  };

  return (
    <LoginSurface>
      <View style={styles.content}>
        <View
          accessibilityLabel={t('appTitle')}
          accessibilityRole="image"
          style={styles.brandLockup}
        >
          <MobileWebImage
            imageUrl={themeMode === 'dark' ? ImageAssets.darkModeLogo : ImageAssets.lightModeLogo}
            contentFit="contain"
            errorFallback={<Shield color={theme.onSurface} size={50} />}
            style={styles.logo}
          />
          <MobileWebImage
            imageUrl={
              themeMode === 'dark' ? ImageAssets.darkModeTextLogo : ImageAssets.lightModeTextLogo
            }
            contentFit="contain"
            errorFallback={<CKText role="screenTitle">{t('appTitle')}</CKText>}
            style={styles.textLogo}
          />
        </View>

        <View testID="login-auth-panel" style={styles.authPanel}>
          <View style={styles.tab}>
            <AuthField
              label={t('authEmail')}
              value={email}
              autoCapitalize="none"
              autoComplete="email"
              keyboardType="email-address"
              editable={!loading}
              onChangeText={setEmail}
              error={errors.email}
              leading={<Mail color={theme.onSurfaceVariant} size={20} />}
            />
            <AuthField
              label={t('authPasswordLabel')}
              value={password}
              autoComplete="current-password"
              editable={!loading}
              onChangeText={setPassword}
              error={errors.password}
              leading={<LockKeyhole color={theme.onSurfaceVariant} size={20} />}
              secure={passwordHidden}
              onToggleSecure={() => setPasswordHidden((value) => !value)}
              toggleLabel={passwordHidden ? t('tooltipShowPassword') : t('tooltipHidePassword')}
            />
            <View style={styles.links}>
              <TextAction label={t('authSignUp')} onPress={onRegister} />
              <TextAction label={t('authPasswordForgot')} onPress={onForgotPassword} />
            </View>
            <PrimaryAction
              label={t('authLogin')}
              loading={loading}
              onPress={() => void signInEmail()}
            />
            {discordEnabled ? (
              <>
                <View
                  accessibilityElementsHidden
                  importantForAccessibility="no-hide-descendants"
                  style={styles.divider}
                >
                  <View style={[styles.dividerLine, { backgroundColor: theme.outlineVariant }]} />
                  <View style={styles.dividerIcon}>
                    <Gamepad2 color={ckColors.discordBlurple} size={18} />
                  </View>
                  <View style={[styles.dividerLine, { backgroundColor: theme.outlineVariant }]} />
                </View>
                <PrimaryAction
                  label={t('authDiscordContinue')}
                  loading={loading}
                  onPress={() => void signInDiscord()}
                  color={ckColors.discordBlurple}
                  leading={<Gamepad2 color={theme.onPrimary} size={20} />}
                />
              </>
            ) : null}
          </View>
          <InlineError message={errors.action} />
        </View>

        <View style={styles.helpLinks}>
          <LoginHelpAction
            icon={<Gamepad2 color={theme.primary} size={16} />}
            label={t('helpJoinDiscord')}
            onPress={onJoinDiscord}
          />
          <LoginHelpAction
            icon={<Mail color={theme.primary} size={16} />}
            label={t('helpEmailUs')}
            onPress={onEmailSupport}
          />
        </View>
      </View>
    </LoginSurface>
  );
}

function LoginSurface({ children }: { children: ReactNode }) {
  const theme = useCKTheme();
  return (
    <View testID="login-background" style={[styles.fill, { backgroundColor: theme.background }]}>
      <SafeAreaView style={styles.fill} edges={['top', 'bottom']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
          style={styles.fill}
        >
          <ScrollView
            keyboardDismissMode="on-drag"
            keyboardShouldPersistTaps="handled"
            contentContainerStyle={styles.page}
          >
            {children}
          </ScrollView>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </View>
  );
}

function LoginHelpAction({
  icon,
  label,
  onPress,
}: {
  icon: ReactNode;
  label: string;
  onPress: () => void;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.helpAction, pressed && styles.pressed]}
    >
      {icon}
      <CKText role="bodySmall" style={{ color: theme.primary, fontWeight: '600' }}>
        {label}
      </CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  page: {
    flexGrow: 1,
    justifyContent: 'center',
    paddingHorizontal: 24,
    paddingTop: 32,
    paddingBottom: 28,
  },
  content: { width: '100%', maxWidth: 480, alignSelf: 'center', gap: 28 },
  authPanel: { gap: 16 },
  tab: { gap: 16 },
  divider: { flexDirection: 'row', alignItems: 'center', gap: 12, marginVertical: 2 },
  dividerLine: { flex: 1, height: StyleSheet.hairlineWidth, opacity: 0.55 },
  dividerIcon: {
    width: 34,
    height: 34,
    borderRadius: 17,
    alignItems: 'center',
    justifyContent: 'center',
  },
  links: { flexDirection: 'row', justifyContent: 'space-between', flexWrap: 'wrap' },
  helpLinks: { flexDirection: 'row', justifyContent: 'center', flexWrap: 'wrap', gap: 8 },
  helpAction: {
    minHeight: 44,
    paddingHorizontal: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  pressed: { opacity: 0.7, transform: [{ scale: 0.985 }] },
  brandLockup: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 10 },
  logo: { width: 62, height: 62 },
  textLogo: { width: 178, height: 50 },
});
