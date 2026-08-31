import { useState } from 'react';
import { MailCheck } from 'lucide-react-native';

import { useI18n } from '../../../i18n';
import { CKText, useCKTheme } from '../../../ui';
import type { AuthPresentationService } from './contracts';
import {
  AuthField,
  AuthPageShell,
  AuthPanel,
  InlineError,
  PrimaryAction,
  TextAction,
  errorText,
} from './auth-components';
import { isValidEmail } from './validation';

export function ForgotPasswordScreen({
  auth,
  onBackToLogin,
  onContinue,
}: {
  auth: Pick<AuthPresentationService, 'forgotPassword'>;
  onBackToLogin: () => void;
  onContinue: (email: string) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [email, setEmail] = useState('');
  const [emailError, setEmailError] = useState<string>();
  const [actionError, setActionError] = useState<string>();
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const submit = async () => {
    const trimmed = email.trim();
    const nextError = !trimmed
      ? t('authEmailRequired')
      : !isValidEmail(trimmed)
        ? t('authEmailInvalid')
        : undefined;
    setEmailError(nextError);
    if (nextError) return;
    setLoading(true);
    setActionError(undefined);
    try {
      await auth.forgotPassword(trimmed);
      setSent(true);
    } catch (error) {
      setActionError(errorText(error));
    } finally {
      setLoading(false);
    }
  };
  return (
    <AuthPageShell
      center
      maxWidth={520}
      title={sent ? undefined : t('authPasswordForgot')}
      description={sent ? undefined : t('authPasswordForgotDescription')}
    >
      <AuthPanel>
        {sent ? (
          <>
            <MailCheck
              accessibilityLabel={t('authPasswordResetSent')}
              color={theme.secondary}
              size={48}
              style={{ alignSelf: 'center' }}
            />
            <CKText
              accessibilityLiveRegion="polite"
              role="sectionTitle"
              style={{ textAlign: 'center' }}
            >
              {t('authPasswordResetSent')}
            </CKText>
            <CKText muted style={{ textAlign: 'center' }}>
              {t('authPasswordResetSentDescription')}
            </CKText>
            <PrimaryAction
              label={t('authPasswordResetContinue')}
              onPress={() => onContinue(email.trim())}
            />
          </>
        ) : (
          <>
            <AuthField
              label={t('authEmail')}
              placeholder={t('authEmailHint')}
              value={email}
              autoCapitalize="none"
              autoComplete="email"
              keyboardType="email-address"
              editable={!loading}
              onChangeText={setEmail}
              error={emailError}
              onSubmitEditing={() => void submit()}
            />
            <InlineError message={actionError} />
            <PrimaryAction
              label={t('authPasswordResetSend')}
              loading={loading}
              onPress={() => void submit()}
            />
            <TextAction label={t('authBackToLogin')} onPress={onBackToLogin} />
          </>
        )}
      </AuthPanel>
    </AuthPageShell>
  );
}
