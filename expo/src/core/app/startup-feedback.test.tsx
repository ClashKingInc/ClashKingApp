import { fireEvent, render } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../i18n';
import { CKThemeProvider } from '../../ui';
import { StartupErrorScreen } from './startup-feedback';

test('keeps the Flutter account header and logout escape hatch on startup errors', async () => {
  const logout = jest.fn();
  const screen = await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <StartupErrorScreen
            avatarUrl={null}
            isNetworkError
            onJoinDiscord={jest.fn()}
            onLogout={logout}
            onRetry={jest.fn()}
            retrying={false}
            userName="Chief"
          />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );

  expect(screen.getByText('Chief')).toBeTruthy();
  await fireEvent.press(screen.getByRole('button', { name: 'Log out' }));
  expect(logout).toHaveBeenCalledTimes(1);
});
