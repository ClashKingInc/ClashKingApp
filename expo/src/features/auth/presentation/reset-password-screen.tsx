import { useState } from 'react';
import { CheckCircle2, LockKeyhole, Mail, ShieldCheck } from 'lucide-react-native';

import { useI18n } from '../../../i18n';
import { CKText, useCKTheme } from '../../../ui';
import type { AuthPresentationService } from './contracts';
import {
  AuthField,
  AuthPageShell,
  AuthPanel,
  InlineError,
  PasswordRequirements,
  PrimaryAction,
  TextAction,
  errorText,
} from './auth-components';
import { isSixDigitCode, isValidEmail, isValidResetPassword, passwordCriteria } from './validation';

export function ResetPasswordScreen({
  auth,
  initialEmail = '',
  onBackToLogin,
}: {
  auth: Pick<AuthPresentationService, 'resetPassword'>;
  initialEmail?: string;
  onBackToLogin: (success: boolean) => void;
}) {
  const { t } = useI18n();
  const theme = useCKTheme();
  const [email, setEmail] = useState(initialEmail);
  const [code, setCode] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [hidePassword, setHidePassword] = useState(true);
  const [hideConfirm, setHideConfirm] = useState(true);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [errors, setErrors] = useState<Record<string, string | undefined>>({});
  const submit = async () => {
    const trimmed = email.trim();
    const next = {
      email: !trimmed
        ? t('authEmailRequired')
        : !isValidEmail(trimmed)
          ? t('authEmailInvalid')
          : undefined,
      code: !code
        ? t('authPasswordResetCodeRequired')
        : !isSixDigitCode(code)
          ? t('authPasswordResetCodeInvalid')
          : undefined,
      password: !password
        ? t('authPasswordRequired')
        : !isValidResetPassword(password)
          ? t('authPasswordInvalid')
          : undefined,
      confirm: !confirm
        ? t('authPasswordConfirmRequired')
        : confirm !== password
          ? t('authPasswordMismatch')
          : undefined,
    };
    setErrors(next);
    if (Object.values(next).some(Boolean)) return;
    setLoading(true);
    try {
      await auth.resetPassword(trimmed, code, password);
      setSuccess(true);
    } catch (error) {
      setErrors({ action: errorText(error) });
    } finally {
      setLoading(false);
    }
  };
  if (success)
    return (
      <AuthPageShell center>
        <AuthPanel>
          <CheckCircle2 color={theme.secondary} size={64} style={{ alignSelf: 'center' }} />
          <CKText
            accessibilityLiveRegion="polite"
            role="sectionTitle"
            style={{ color: theme.secondary, textAlign: 'center' }}
          >
            {t('authPasswordResetSuccess')}
          </CKText>
          <PrimaryAction label={t('authBackToLogin')} onPress={() => onBackToLogin(true)} />
        </AuthPanel>
      </AuthPageShell>
    );
  return (
    <AuthPageShell title={t('authPasswordReset')} description={t('authPasswordResetDescription')}>
      <AuthPanel>
        <AuthField
          label={t('authEmail')}
          placeholder={t('authEmailHint')}
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
          label={t('authPasswordResetCode')}
          placeholder={t('authPasswordResetCodeHint')}
          value={code}
          keyboardType="number-pad"
          maxLength={6}
          editable={!loading}
          onChangeText={(value) => setCode(value.replace(/\D/g, ''))}
          error={errors.code}
          leading={<ShieldCheck color={theme.onSurfaceVariant} size={20} />}
        />
        <AuthField
          label={t('authPasswordNew')}
          value={password}
          autoComplete="new-password"
          editable={!loading}
          onChangeText={setPassword}
          error={errors.password}
          leading={<LockKeyhole color={theme.onSurfaceVariant} size={20} />}
          secure={hidePassword}
          onToggleSecure={() => setHidePassword((value) => !value)}
          toggleLabel={hidePassword ? t('tooltipShowPassword') : t('tooltipHidePassword')}
        />
        <PasswordRequirements criteria={passwordCriteria(password)} t={t} />
        <AuthField
          label={t('authPasswordConfirm')}
          placeholder={t('authPasswordConfirmHint')}
          value={confirm}
          autoComplete="new-password"
          editable={!loading}
          onChangeText={setConfirm}
          error={errors.confirm}
          leading={<LockKeyhole color={theme.onSurfaceVariant} size={20} />}
          secure={hideConfirm}
          onToggleSecure={() => setHideConfirm((value) => !value)}
          toggleLabel={hideConfirm ? t('tooltipShowPassword') : t('tooltipHidePassword')}
          onSubmitEditing={() => void submit()}
        />
        <InlineError message={errors.action} />
        <PrimaryAction
          label={t('authPasswordReset')}
          loading={loading}
          onPress={() => void submit()}
        />
        <TextAction label={t('authBackToLogin')} onPress={() => onBackToLogin(false)} />
      </AuthPanel>
    </AuthPageShell>
  );
}
