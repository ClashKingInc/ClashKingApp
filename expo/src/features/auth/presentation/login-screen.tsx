import { defaultIsMaintenanceError } from '../../../core/app/startup-coordinator';
import { useEffect, useState, type ComponentProps, type ReactNode } from 'react';
import { DestinationStack } from '../../../ui/destination-stack';
import { Image } from 'expo-image';
import { StatusBar } from 'expo-status-bar';
import {
  KeyboardAvoidingView,
  BackHandler,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  View,
} from 'react-native';
import { ArrowLeft, LockKeyhole, Mail } from 'lucide-react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import Svg, { Defs, G, LinearGradient, Mask, Path, Polygon, Rect, Stop } from 'react-native-svg';

import { ImageAssets } from '../../../core/assets/image-assets';
import { startupBrandPaths as brand } from '../../../core/assets/startup-brand-paths';
import { useI18n } from '../../../i18n';
import { DiscordMark } from '../../../ui/discord-mark';
import {
  CKText,
  CKThemeProvider,
  GlassSurface,
  MobileWebImage,
  ckColors,
  useCKTheme,
} from '../../../ui';
import type { AuthPresentationService, PostAuthPresentationProps } from './contracts';
import { AuthField, InlineError, PrimaryAction, TextAction, errorText } from './auth-components';
import { PostAuthGate } from './post-auth';
import { isValidEmail } from './validation';

export function LoginScreen(props: ComponentProps<typeof EmailLoginScreen>) {
  return (
    <View style={[styles.fill, { backgroundColor: '#18251C' }]}>
      <StatusBar style="light" />
      <LoginBackdrop />
      <SafeAreaView
        pointerEvents="none"
        edges={['top']}
        style={[StyleSheet.absoluteFill, { paddingTop: 24 }]}
      >
        <LoginBrand />
      </SafeAreaView>
      {/* SDK 58 owns the navigation container. The welcome/form navigator
          nests in that existing tree instead of creating a second root. */}
      <LoginContent {...props} />
    </View>
  );
}

function LoginContent(props: ComponentProps<typeof EmailLoginScreen>) {
  const { t } = useI18n();
  const [emailPage, setEmailPage] = useState(Boolean(props.prefillEmail));
  const [loading, setLoading] = useState(false);
  const [authenticated, setAuthenticated] = useState(false);
  const [error, setError] = useState<string>();
  const [emailBusy, setEmailBusy] = useState(false);
  if (authenticated) return <PostAuthGate {...props.postAuth} />;
  const signInDiscord = async () => {
    setLoading(true);
    setError(undefined);
    try {
      await props.auth.signInWithDiscord();
      setAuthenticated(true);
    } catch (cause) {
      if (defaultIsMaintenanceError(cause)) props.onMaintenance();
      else setError(errorText(cause));
    } finally {
      setLoading(false);
    }
  };
  return (
    <DestinationStack
      focused={emailPage}
      onCloseDetail={() => setEmailPage(false)}
      backgroundColor="transparent"
      gestureEnabled={!emailBusy}
      detail={
        <CKThemeProvider preference="dark">
          <EmailLoginScreen
            {...props}
            discordEnabled={false}
            onBusyChange={setEmailBusy}
            onBackToWelcome={() => setEmailPage(false)}
          />
        </CKThemeProvider>
      }
      grid={
        <View testID="login-welcome" style={styles.fill}>
          <SafeAreaView style={styles.fill} edges={['top', 'bottom']}>
            <ScrollView bounces={false} contentContainerStyle={styles.welcomePage}>
              <View style={{ height: 62 }} />
              <View style={styles.welcomeSpace} />
              <View style={styles.welcomeActions}>
                {props.discordEnabled !== false ? (
                  <PrimaryAction
                    label={t('authDiscordContinue')}
                    loading={loading}
                    onPress={() => void signInDiscord()}
                    color={ckColors.discordBlurple}
                    foregroundColor="#FFFFFF"
                    leading={<DiscordMark color="#FFFFFF" size={20} testID="discord-login-mark" />}
                  />
                ) : null}
                <PrimaryAction
                  label={t('authAccountEmailAndPassword')}
                  disabled={loading}
                  onPress={() => setEmailPage(true)}
                  color="#FFFFFF24"
                  foregroundColor="#FFFFFF"
                  leading={<Mail color="#FFFFFF" size={20} />}
                />
                {error ? (
                  <CKText
                    accessibilityLiveRegion="assertive"
                    style={{ color: '#FFFFFF', textAlign: 'center' }}
                  >
                    {error}
                  </CKText>
                ) : null}
                <View style={styles.helpLinks}>
                  <LoginHelpAction
                    icon={<DiscordMark color="#FFFFFF" size={16} testID="discord-support-mark" />}
                    label={t('helpJoinDiscord')}
                    onPress={props.onJoinDiscord}
                    color="#FFFFFF"
                  />
                  <LoginHelpAction
                    icon={<Mail color="#FFFFFF" size={16} />}
                    label={t('helpEmailUs')}
                    onPress={props.onEmailSupport}
                    color="#FFFFFF"
                  />
                </View>
              </View>
            </ScrollView>
          </SafeAreaView>
        </View>
      }
    />
  );
}

function LoginBackdrop() {
  return (
    <View pointerEvents="none" accessible={false} style={StyleSheet.absoluteFill}>
      <Image
        testID="login-landscape"
        source={require('../../../../assets/clashking/login-village.png')}
        contentFit="cover"
        transition={0}
        style={StyleSheet.absoluteFill}
      />
      {/* The supplied artwork already defocuses the foreground grass. A gradual
            scrim keeps that softness without a hard panel or an expensive live blur. */}
      <Svg width="100%" height="100%" style={StyleSheet.absoluteFill}>
        <Defs>
          <LinearGradient id="welcome-shade" x1="0" y1="0" x2="0" y2="1">
            <Stop offset="0" stopColor="#10211C" stopOpacity={0.3} />
            <Stop offset="0.35" stopColor="#10211C" stopOpacity={0.05} />
            <Stop offset="0.58" stopColor="#17241C" stopOpacity={0.18} />
            <Stop offset="0.78" stopColor="#17241C" stopOpacity={0.78} />
            <Stop offset="1" stopColor="#111C16" stopOpacity={0.96} />
          </LinearGradient>
        </Defs>
        <Rect width="100%" height="100%" fill="url(#welcome-shade)" />
      </Svg>
    </View>
  );
}

function LoginBrand() {
  const { t } = useI18n();
  return (
    <View accessibilityLabel={t('appTitle')} accessibilityRole="image" style={styles.brandLockup}>
      <WelcomeCrown />
      <MobileWebImage
        imageUrl={ImageAssets.darkModeTextLogo}
        contentFit="contain"
        style={styles.textLogo}
        errorFallback={
          <CKText role="screenTitle" style={{ color: '#FFFFFF' }}>
            {t('appTitle')}
          </CKText>
        }
      />
    </View>
  );
}

function WelcomeCrown() {
  return (
    <Svg
      testID="welcome-crown"
      width={62}
      height={62}
      viewBox="0 0 84.5112 101.14"
      fillRule="evenodd"
    >
      <Defs>
        {/* Luminance is the native and SVG default. An explicit maskType leaks
            through react-native-svg on web as an invalid React DOM prop. */}
        <Mask
          id="welcome-crown-cutout"
          x="0"
          y="0"
          width="84.5112"
          height="101.14"
          maskUnits="userSpaceOnUse"
        >
          <Rect width="84.5112" height="101.14" fill="#FFFFFF" />
          <Polygon testID="welcome-crown-shaft-mask" points={brand.cut} fill="#000000" />
        </Mask>
      </Defs>
      <G mask="url(#welcome-crown-cutout)">
        <Path d={brand.crown[0]} fill="#BF0000" />
        <Path d={brand.crown[1]} fill="#D90709" />
      </G>
      <Path d={brand.crown[2]} fill="#FFFFFF" />
      <Path d={brand.crown[3]} fill="#FFFFFF" />
    </Svg>
  );
}

function EmailLoginScreen({
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
  onBackToWelcome,
  onBusyChange,
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
  onBackToWelcome?: () => void;
  onBusyChange?: (busy: boolean) => void;
  viewportWidth?: number;
  platform?: string;
  isVerificationRequired?: (error: unknown) => boolean;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [email, setEmail] = useState(prefillEmail);
  const [password, setPassword] = useState('');
  const [passwordHidden, setPasswordHidden] = useState(true);
  const [errors, setErrors] = useState<{ email?: string; password?: string; action?: string }>({
    action: prefillEmail ? t('authErrorEmailAlreadyRegistered') : undefined,
  });
  const [loading, setLoading] = useState(false);
  const [authenticated, setAuthenticated] = useState(false);

  useEffect(() => {
    if (!onBackToWelcome) return;
    const subscription = BackHandler.addEventListener('hardwareBackPress', () => {
      // Never unmount the form while credentials or account bootstrap are in flight.
      if (!loading && !authenticated) onBackToWelcome();
      return true;
    });
    return () => subscription.remove();
  }, [onBackToWelcome, loading, authenticated]);

  useEffect(() => {
    onBusyChange?.(loading || authenticated);
  }, [loading, authenticated, onBusyChange]);

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
      else if (defaultIsMaintenanceError(error)) onMaintenance();
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
      if (defaultIsMaintenanceError(error)) onMaintenance();
      else setErrors({ action: errorText(error) });
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.fill}>
      <LoginSurface>
        <View style={styles.content}>
          {onBackToWelcome ? (
            <Pressable
              accessibilityRole="button"
              accessibilityLabel={t('authBackToLogin')}
              onPress={onBackToWelcome}
              disabled={loading}
              hitSlop={8}
              style={{
                width: 44,
                height: 44,
                alignItems: 'center',
                justifyContent: 'center',
                opacity: loading ? 0.5 : 1,
              }}
            >
              <ArrowLeft color="#FFFFFF" size={26} />
            </Pressable>
          ) : null}
          <View style={{ height: 62 }} />
          <View style={styles.emailSpace} />

          <GlassSurface
            testID="login-auth-panel"
            cornerRadius={28}
            tintColor="#17241C66"
            style={styles.authPanel}
          >
            <View style={styles.tab}>
              <AuthField
                appearance="glass"
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
                appearance="glass"
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
                <TextAction color="#FFFFFF" label={t('authSignUp')} onPress={onRegister} />
                <TextAction
                  color="#FFFFFF"
                  label={t('authPasswordForgot')}
                  onPress={onForgotPassword}
                />
              </View>
              <PrimaryAction
                label={t('authLogin')}
                color="#FFFFFF"
                foregroundColor="#17221C"
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
          </GlassSurface>

          <View style={styles.helpLinks}>
            <LoginHelpAction
              icon={<DiscordMark color="#FFFFFF" size={16} testID="discord-support-mark" />}
              color="#FFFFFF"
              label={t('helpJoinDiscord')}
              onPress={onJoinDiscord}
            />
            <LoginHelpAction
              icon={<Mail color="#FFFFFF" size={16} />}
              color="#FFFFFF"
              label={t('helpEmailUs')}
              onPress={onEmailSupport}
            />
          </View>
        </View>
      </LoginSurface>
    </View>
  );
}


function LoginSurface({ children }: { children: ReactNode }) {
  const [viewportHeight, setViewportHeight] = useState(0);
  const [contentHeight, setContentHeight] = useState(0);
  return (
    <View testID="login-background" style={styles.fill}>
      <SafeAreaView style={styles.fill} edges={['top', 'bottom']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
          style={styles.fill}
        >
          <ScrollView
            testID="login-scroll"
            onLayout={(event) => setViewportHeight(event.nativeEvent.layout.height)}
            onContentSizeChange={(_width, height) => setContentHeight(height)}
            scrollEnabled={viewportHeight > 0 && contentHeight > viewportHeight + 1}
            bounces={false}
            alwaysBounceVertical={false}
            overScrollMode="never"
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
  color,
}: {
  icon: ReactNode;
  label: string;
  onPress: () => void;
  color?: string;
}) {
  const theme = useCKTheme();
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={({ pressed }) => [styles.helpAction, pressed && styles.pressed]}
    >
      {icon}
      <CKText role="bodySmall" style={{ color: color ?? theme.primary, fontWeight: '600' }}>
        {label}
      </CKText>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  fill: { flex: 1 },
  welcomePage: { flexGrow: 1, paddingHorizontal: 24, paddingTop: 24, paddingBottom: 12 },
  welcomeSpace: { flex: 1, minHeight: 260 },
  welcomeActions: { width: '100%', maxWidth: 440, alignSelf: 'center', gap: 12 },
  page: {
    flexGrow: 1,
    paddingHorizontal: 24,
    paddingTop: 12,
    paddingBottom: 28,
  },
  content: { flexGrow: 1, width: '100%', maxWidth: 440, alignSelf: 'center', gap: 16 },
  emailSpace: { flexGrow: 1, minHeight: 80 },
  authPanel: { gap: 16, padding: 20 },
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
