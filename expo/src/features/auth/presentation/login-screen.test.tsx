import { fireEvent, render } from '@testing-library/react-native';

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

async function renderLogin(overrides: Partial<React.ComponentProps<typeof LoginScreen>> = {}) {
  const onJoinDiscord = jest.fn();
  const onEmailSupport = jest.fn();
  const screen = await render(
    <I18nProvider locale="en">
      <CKThemeProvider preference="dark">
        <LoginScreen
          auth={{
            signInWithDiscord: async () => Promise.reject(new Error('cancelled')),
            signInWithEmail: async () => Promise.reject(new Error('invalid')),
          }}
          onEmailSupport={onEmailSupport}
          onForgotPassword={jest.fn()}
          onJoinDiscord={onJoinDiscord}
          onMaintenance={jest.fn()}
          onRegister={jest.fn()}
          onVerificationRequired={jest.fn()}
          postAuth={{} as never}
          {...overrides}
        />
      </CKThemeProvider>
    </I18nProvider>,
  );
  return { screen, onEmailSupport, onJoinDiscord };
}

describe('LoginScreen', () => {
  it('only scrolls when the form exceeds the available height, including keyboard resizing', async () => {
    const { screen } = await renderLogin();
    const scroll = () => screen.getByTestId('login-scroll');
    await fireEvent(scroll(), 'layout', { nativeEvent: { layout: { height: 800 } } });
    await fireEvent(scroll(), 'contentSizeChange', 390, 800);
    expect(scroll().props.scrollEnabled).toBe(false);
    expect(scroll().props.bounces).toBe(false);
    expect(scroll().props.alwaysBounceVertical).toBe(false);
    expect(scroll().props.overScrollMode).toBe('never');

    // KeyboardAvoidingView shrinks the viewport; short screens behave the same way.
    await fireEvent(scroll(), 'layout', { nativeEvent: { layout: { height: 400 } } });
    expect(scroll().props.scrollEnabled).toBe(true);
    await fireEvent(scroll(), 'layout', { nativeEvent: { layout: { height: 800 } } });
    expect(scroll().props.scrollEnabled).toBe(false);
    await fireEvent(scroll(), 'contentSizeChange', 390, 1000);
    expect(scroll().props.scrollEnabled).toBe(true);
  });

  it('uses a solid app surface and one minimal authentication form', async () => {
    const { screen } = await renderLogin();

    expect(screen.getByTestId('login-background').props.source).toBeUndefined();
    expect(screen.getByTestId('login-auth-panel')).toBeTruthy();
    expect(screen.queryAllByRole('tab')).toHaveLength(0);
    expect(
      screen.queryByText("Use email if you can't access Discord or prefer app-only features"),
    ).toBeNull();
    expect(screen.getAllByText('Login')).toHaveLength(1);
    expect(screen.getByLabelText('Email')).toBeTruthy();
    expect(screen.getByLabelText('Password')).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Login' })).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Continue with Discord' })).toBeTruthy();
    expect(screen.getByTestId('discord-login-mark')).toBeTruthy();
    expect(screen.getByTestId('discord-support-mark')).toBeTruthy();
  });

  it('omits only the Discord alternative when Discord sign-in is disabled', async () => {
    const { screen } = await renderLogin({ discordEnabled: false });

    expect(screen.getByLabelText('Email')).toBeTruthy();
    expect(screen.getByLabelText('Password')).toBeTruthy();
    expect(screen.queryByRole('button', { name: 'Continue with Discord' })).toBeNull();
  });

  it('keeps both support actions reachable from the compact footer', async () => {
    const { screen, onEmailSupport, onJoinDiscord } = await renderLogin();

    await fireEvent.press(screen.getByRole('button', { name: 'Join Discord' }));
    await fireEvent.press(screen.getByRole('button', { name: 'Email Us' }));

    expect(onJoinDiscord).toHaveBeenCalledTimes(1);
    expect(onEmailSupport).toHaveBeenCalledTimes(1);
  });
});
