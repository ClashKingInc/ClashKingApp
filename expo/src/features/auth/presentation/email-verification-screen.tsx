import { createRef, useMemo, useState } from 'react';
import { StyleSheet, TextInput, View } from 'react-native';

import { useI18n } from '../../../i18n';
import { CKText, LoadingIndicator, Surface, ckSpacing, statColors, useCKTheme } from '../../../ui';
import type { AuthPresentationService, PostAuthPresentationProps } from './contracts';
import {
  AuthPageShell,
  InlineError,
  PrimaryAction,
  TextAction,
  errorText,
} from './auth-components';
import { PostAuthGate } from './post-auth';
import { isSixDigitCode } from './validation';

export function EmailVerificationScreen({
  auth,
  email,
  postAuth,
  onBackToLogin,
  onMaintenance,
}: {
  auth: Pick<AuthPresentationService, 'verifyEmailWithCode' | 'resendVerificationEmail'>;
  email: string;
  postAuth: PostAuthPresentationProps;
  onBackToLogin: (prefillEmail?: string) => void;
  onMaintenance: () => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [digits, setDigits] = useState(['', '', '', '', '', '']);
  const refs = useMemo(() => Array.from({ length: 6 }, () => createRef<TextInput>()), []);
  const [loading, setLoading] = useState(false);
  const [authenticated, setAuthenticated] = useState(false);
  const [error, setError] = useState<string>();
  const [notice, setNotice] = useState<string>();
  const code = digits.join('');
  if (authenticated) return <PostAuthGate {...postAuth} />;
  const verify = async (candidate = code) => {
    if (!isSixDigitCode(candidate)) {
      setError(t('authEmailVerificationCodeRequired'));
      return;
    }
    setLoading(true);
    setError(undefined);
    try {
      await auth.verifyEmailWithCode(email, candidate);
      setAuthenticated(true);
    } catch (nextError) {
      const raw = String(nextError).toLowerCase();
      if (/\b(?:500|503)\b/.test(raw)) onMaintenance();
      else if (raw.includes('already verified') || raw.includes('try logging in instead'))
        onBackToLogin(email);
      else {
        setError(
          raw.includes('unauthorized') || raw.includes('expired') || raw.includes('invalid')
            ? t('authEmailVerificationCodeInvalid')
            : errorText(nextError),
        );
        setDigits(['', '', '', '', '', '']);
        refs[0]?.current?.focus();
      }
    } finally {
      setLoading(false);
    }
  };
  const resend = async () => {
    setLoading(true);
    setError(undefined);
    setNotice(undefined);
    try {
      await auth.resendVerificationEmail(email);
      setNotice(t('authEmailVerificationResendSuccess'));
    } catch (nextError) {
      const raw = String(nextError).toLowerCase();
      if (raw.includes('already verified')) onBackToLogin(email);
      else
        setError(
          raw.includes('no pending verification')
            ? t('authEmailVerificationExpiredResend')
            : raw.includes('expired')
              ? t('authEmailVerificationExpired')
              : errorText(nextError),
        );
    } finally {
      setLoading(false);
    }
  };
  const updateDigit = (value: string, index: number) => {
    const digit = value.replace(/\D/g, '').slice(-1);
    const next = [...digits];
    next[index] = digit;
    setDigits(next);
    if (digit && index < 5) refs[index + 1]?.current?.focus();
    if (!digit && index > 0) refs[index - 1]?.current?.focus();
    const nextCode = next.join('');
    if (nextCode.length === 6) void verify(nextCode);
  };
  return (
    <AuthPageShell title={t('authEmailVerificationTitle')}>
      <CKText role="screenTitle" style={styles.center}>
        {t('authEmailVerificationCheckEmail')}
      </CKText>
      <CKText style={styles.center}>{t('authEmailVerificationSentTo')}</CKText>
      <CKText style={[styles.center, styles.strong]}>{email}</CKText>
      <Surface style={styles.card}>
        <CKText style={styles.center}>{t('authEmailVerificationCodeInstructions')}</CKText>
        <View style={styles.codeRow}>
          {digits.map((digit, index) => (
            <TextInput
              key={index}
              ref={refs[index]}
              accessibilityLabel={`${t('authEmailVerificationTitle')} ${index + 1}`}
              value={digit}
              editable={!loading}
              keyboardType="number-pad"
              maxLength={1}
              onChangeText={(value) => updateDigit(value, index)}
              style={[styles.code, { color: theme.onSurface, borderColor: theme.outlineVariant }]}
            />
          ))}
        </View>
        {loading ? (
          <LoadingIndicator label={t('authEmailVerificationVerifying')} />
        ) : (
          <>
            <PrimaryAction
              label={t('authEmailVerificationVerify')}
              disabled={!isSixDigitCode(code)}
              onPress={() => void verify()}
            />
            <PrimaryAction label={t('authEmailVerificationResend')} onPress={() => void resend()} />
            <TextAction label={t('authBackToLogin')} onPress={() => onBackToLogin()} />
          </>
        )}
        {notice ? (
          <CKText
            accessibilityLiveRegion="polite"
            style={[styles.center, { color: statColors.win }]}
          >
            {notice}
          </CKText>
        ) : null}
        <InlineError message={error} />
      </Surface>
    </AuthPageShell>
  );
}

const styles = StyleSheet.create({
  center: { textAlign: 'center' },
  strong: { fontWeight: '700' },
  card: { padding: ckSpacing.lg, gap: ckSpacing.xl, marginTop: ckSpacing.lg, maxWidth: 560 },
  codeRow: { flexDirection: 'row', justifyContent: 'space-between', gap: 6 },
  code: {
    flex: 1,
    maxWidth: 48,
    minWidth: 36,
    height: 56,
    borderWidth: StyleSheet.hairlineWidth,
    borderRadius: 12,
    textAlign: 'center',
    fontSize: 22,
    fontWeight: '700',
  },
});
