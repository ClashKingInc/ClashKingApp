import { fireEvent, render } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { HomeDashboardActions } from './contracts';
import { DashboardScreen } from './dashboard-screen';

const actions = (): HomeDashboardActions => ({
  refresh: jest.fn(async () => undefined),
  showRefreshError: jest.fn(),
  openManageAccounts: jest.fn(),
  openAnnouncement: jest.fn(),
  openTodo: jest.fn(),
  openRanked: jest.fn(),
  openUpgradeTracker: jest.fn(),
});

describe('DashboardScreen states', () => {
  it('shows the exact no-linked-account action and delegates navigation', async () => {
    const callbacks = actions();
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <DashboardScreen
              platform="ios"
              model={{
                loading: false,
                linkedAccountCount: 0,
                announcements: [],
                upgradeTrackerEnabled: true,
              }}
              actions={callbacks}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    expect(screen.getByText('No linked accounts')).toBeTruthy();
    expect(
      screen.getByText('Link a Clash account to see attacks, events, and activity here.'),
    ).toBeTruthy();
    await fireEvent.press(screen.getByRole('button', { name: 'Manage Accounts' }));
    expect(callbacks.openManageAccounts).toHaveBeenCalledTimes(1);
  });

  it('renders Flutter upgrade placeholders when configured accounts have no snapshot', async () => {
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <DashboardScreen
              platform="ios"
              model={{
                loading: false,
                linkedAccountCount: 2,
                announcements: [],
                upgradeTrackerEnabled: true,
                upgrade: { state: 'empty', configuredCount: 2 },
              }}
              actions={actions()}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );
    expect(screen.getByText('Open the tracker to import or refresh upgrade data.')).toBeTruthy();
    expect(screen.getByText('2 accounts')).toBeTruthy();
    expect(screen.getAllByText('-')).toHaveLength(3);
  });
});
