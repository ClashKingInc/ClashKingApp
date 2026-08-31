import { fireEvent, render, waitFor } from '@testing-library/react-native';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { LoginScreen } from './login-screen';

jest.mock('../../../ui/accessibility', () => ({
  currentPlatform: () => 'ios',
  useCKAccessibility: () => ({
    reduceMotion: false,
    reduceTransparency: false,
    highContrast: false,
  }),
}));

it('routes a Flutter-equivalent login server failure to maintenance', async () => {
  const onMaintenance = jest.fn();
  const screen = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="light">
        <LoginScreen
          auth={{
            signInWithDiscord: async () => undefined,
            signInWithEmail: async () => Promise.reject(new Error('503 unavailable')),
          }}
          discordEnabled={false}
          onEmailSupport={jest.fn()}
          onForgotPassword={jest.fn()}
          onJoinDiscord={jest.fn()}
          onMaintenance={onMaintenance}
          onRegister={jest.fn()}
          onVerificationRequired={jest.fn()}
          postAuth={{} as never}
        />
      </CKThemeProvider>
    </I18nProvider>,
  );

  await fireEvent.changeText(screen.getByLabelText('Email'), 'person@example.com');
  await fireEvent.changeText(screen.getByLabelText('Password'), 'password');
  await fireEvent.press(screen.getByRole('button', { name: 'Login' }));
  await waitFor(() => expect(onMaintenance).toHaveBeenCalledTimes(1));
});
