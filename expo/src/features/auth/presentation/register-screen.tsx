import { useState } from 'react';
import { View } from 'react-native';

import { useI18n, type MessageKey } from '../../../i18n';
import type { AuthPresentationService } from './contracts';
import {
  AuthField,
  AuthPageShell,
  AuthPanel,
  InlineError,
  PasswordRequirements,
  PrimaryAction,
  TextAction,
} from './auth-components';
import { isValidEmail, isValidPassword, passwordCriteria } from './validation';

export type RegistrationRedirect = 'verification' | 'login' | 'maintenance';

export function classifyRegistrationError(error: unknown): RegistrationRedirect | null {
  const value = String(error).toLowerCase();
  if (value.includes('503') || value.includes('500')) return 'maintenance';
  if (value.includes('already registered') || value.includes('please try logging in'))
    return 'login';
  if (
    value.includes('verification email was already sent') ||
    value.includes('already sent to this address')
  )
    return 'verification';
  return null;
}

export function localizedRegistrationError(error: unknown, t: (key: MessageKey) => string): string {
  const raw = String(error);
  const detail = /"detail"\s*:\s*"([^"]*)"/i.exec(raw)?.[1]?.toLowerCase() ?? raw.toLowerCase();
  if (detail.includes('already registered')) return t('authErrorEmailAlreadyRegistered');
  if (detail.includes('verification email was already sent'))
    return t('authErrorEmailAlreadyPending');
  if (detail.includes('invalid email format')) return t('authErrorEmailInvalidFormat');
  if (detail.includes('failed to send verification email')) return t('authErrorEmailSendFailed');
  if (detail.includes('password must contain') || detail.includes('weak patterns'))
    return t('authErrorPasswordWeak');
  if (detail.includes('password must be at least')) return t('authPasswordTooShort');
  if (detail.includes('username is required')) return t('authUsernameRequired');
  if (detail.includes('username must be at least')) return t('authUsernameTooShort');
  if (detail.includes('username must be no more than')) return t('authUsernameTooLong');
  if (detail.includes('username can only contain')) return t('authErrorUsernameInvalid');
  if (detail.includes('rate limit') || detail.includes('too many'))
    return t('authErrorRateLimited');
  if (detail.includes('network') || detail.includes('connection')) return t('authErrorConnection');
  if (detail.includes('server') || detail.includes('500') || detail.includes('503'))
    return t('authErrorServerUnavailable');
  return t('authErrorRegistrationFailed');
}

export function RegisterScreen({
  auth,
  onBackToLogin,
  onRedirect,
}: {
  auth: Pick<AuthPresentationService, 'registerWithEmail'>;
  onBackToLogin: () => void;
  onRedirect: (destination: RegistrationRedirect, email: string) => void;
}) {
  const { t } = useI18n();
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [hidePassword, setHidePassword] = useState(true);
  const [hideConfirm, setHideConfirm] = useState(true);
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Record<string, string | undefined>>({});
  const submit = async () => {
    const trimmedUsername = username.trim();
    const trimmedEmail = email.trim();
    const next = {
      username: !trimmedUsername
        ? t('authUsernameRequired')
        : trimmedUsername.length < 3
          ? t('authUsernameTooShort')
          : undefined,
      email: !trimmedEmail
        ? t('authEmailRequired')
        : !isValidEmail(trimmedEmail)
          ? t('authEmailInvalid')
          : undefined,
      password: !password
        ? t('authPasswordRequired')
        : !isValidPassword(password)
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
      await auth.registerWithEmail(trimmedEmail, password, trimmedUsername);
      onRedirect('verification', trimmedEmail);
    } catch (error) {
      const redirect = classifyRegistrationError(error);
      if (redirect) onRedirect(redirect, trimmedEmail);
      else setErrors({ action: localizedRegistrationError(error, t) });
    } finally {
      setLoading(false);
    }
  };
  return (
    <AuthPageShell title={t('authJoinClashKing')} description={t('authCreateAccountToGetStarted')}>
      <AuthPanel>
        <AuthField
          label={t('authUsernameLabel')}
          value={username}
          autoComplete="username-new"
          editable={!loading}
          onChangeText={setUsername}
          error={errors.username}
        />
        <AuthField
          label={t('authEmail')}
          value={email}
          autoCapitalize="none"
          autoComplete="email"
          keyboardType="email-address"
          editable={!loading}
          onChangeText={setEmail}
          error={errors.email}
        />
        <AuthField
          label={t('authPasswordLabel')}
          value={password}
          autoComplete="new-password"
          editable={!loading}
          onChangeText={setPassword}
          error={errors.password}
          secure={hidePassword}
          onToggleSecure={() => setHidePassword((value) => !value)}
          toggleLabel={hidePassword ? t('tooltipShowPassword') : t('tooltipHidePassword')}
        />
        <PasswordRequirements criteria={passwordCriteria(password)} t={t} />
        <AuthField
          label={t('authPasswordConfirm')}
          value={confirm}
          autoComplete="new-password"
          editable={!loading}
          onChangeText={setConfirm}
          error={errors.confirm}
          secure={hideConfirm}
          onToggleSecure={() => setHideConfirm((value) => !value)}
          toggleLabel={hideConfirm ? t('tooltipShowPassword') : t('tooltipHidePassword')}
          onSubmitEditing={() => void submit()}
        />
        <InlineError message={errors.action} />
        <PrimaryAction
          label={t('authCreateAccount')}
          loading={loading}
          onPress={() => void submit()}
        />
        <View style={{ alignItems: 'center' }}>
          <TextAction label={t('authAlreadyHaveAccount')} onPress={onBackToLogin} />
        </View>
      </AuthPanel>
    </AuthPageShell>
  );
}
