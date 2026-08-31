import { useState, type ReactNode } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import { LockKeyhole, Mail, Shield } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import Svg, { Path } from 'react-native-svg';

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
                </View>
                <PrimaryAction
                  label={t('authDiscordContinue')}
                  loading={loading}
                  onPress={() => void signInDiscord()}
                  color={ckColors.discordBlurple}
                  leading={
                    <DiscordMark color={theme.onPrimary} size={20} testID="discord-login-mark" />
                  }
                />
              </>
            ) : null}
          </View>
          <InlineError message={errors.action} />
        </View>

        <View style={styles.helpLinks}>
          <LoginHelpAction
            icon={<DiscordMark color={theme.primary} size={16} testID="discord-support-mark" />}
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

function DiscordMark({ color, size, testID }: { color: string; size: number; testID?: string }) {
  // Official Discord symbol from https://discord.com/branding (viewBox 0 0 59 44).
  return (
    <Svg testID={testID} width={(size * 59) / 44} height={size} viewBox="0 0 59 44" fill="none">
      <Path
        d="M37.1937 0C36.6265 1.0071 36.1172 2.04893 35.6541 3.11392C31.2553 2.45409 26.7754 2.45409 22.365 3.11392C21.9136 2.04893 21.3926 1.0071 20.8254 0C16.6928 0.70613 12.6644 1.94475 8.84436 3.69271C1.27372 14.9098 -0.775214 25.8374 0.243466 36.6146C4.67704 39.8906 9.6431 42.391 14.9333 43.9884C16.1256 42.391 17.179 40.6893 18.0819 38.9182C16.3687 38.2815 14.7133 37.4828 13.1274 36.5567C13.5442 36.2557 13.9493 35.9432 14.3429 35.6422C23.6384 40.0179 34.4039 40.0179 43.711 35.6422C44.1046 35.9663 44.5097 36.2789 44.9264 36.5567C43.3405 37.4943 41.6852 38.2815 39.9604 38.9298C40.8633 40.7009 41.9167 42.4025 43.109 44C48.3992 42.4025 53.3653 39.9137 57.7988 36.6377C59.0027 24.1358 55.7383 13.3007 49.1748 3.70429C45.3663 1.95633 41.3379 0.717706 37.2053 0.0231518L37.1937 0ZM19.3784 29.9816C16.5192 29.9816 14.1461 27.3886 14.1461 24.1821C14.1461 20.9755 16.4266 18.371 19.3669 18.371C22.3071 18.371 24.6455 20.9871 24.5992 24.1821C24.5529 27.377 22.2956 29.9816 19.3784 29.9816ZM38.6639 29.9816C35.7931 29.9816 33.4431 27.3886 33.4431 24.1821C33.4431 20.9755 35.7236 18.371 38.6639 18.371C41.6042 18.371 43.9309 20.9871 43.8846 24.1821C43.8383 27.377 41.581 29.9816 38.6639 29.9816Z"
        fill={color}
      />
    </Svg>
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
  divider: { marginVertical: 2 },
  dividerLine: { width: '100%', height: StyleSheet.hairlineWidth, opacity: 0.55 },
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
