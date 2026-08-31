import { fireEvent, render } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { PlayersPresentationActions, PlayersPresentationModel } from './contracts';
import { PlayersScreen } from './players-screen';

jest.mock('expo-glass-effect', () => {
  const { View } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    GlassView: View,
    isGlassEffectAPIAvailable: () => false,
    isLiquidGlassAvailable: () => false,
  };
});

const actions = (): PlayersPresentationActions => ({
  refresh: jest.fn(async () => undefined),
  showMessage: jest.fn(),
  openManageAccounts: jest.fn(),
  openPlayer: jest.fn(),
  hydrateBookmarkedPlayers: jest.fn(async () => undefined),
  loadBookmarkedPlayer: jest.fn(async () => {
    throw new Error('unused');
  }),
  verifyAccount: jest.fn(async () => ({ success: true, message: null })),
  refreshAccounts: jest.fn(async () => undefined),
  openGameSettings: jest.fn(),
  setAccountNotifications: jest.fn(async () => undefined),
  setAccountHidden: jest.fn(async () => undefined),
  setCardOption: jest.fn(async () => undefined),
});

const emptyModel: PlayersPresentationModel = {
  profiles: [],
  accountLinks: [],
  bookmarks: [],
  optionsByTag: {},
  notificationsEnabled: false,
  notificationAccountTags: new Set(),
  updatingNotificationTags: new Set(),
  featureFlags: { upgradeTracker: true, rankedLeague: true },
};

describe('PlayersScreen roster states', () => {
  it('switches exact empty states and delegates linked-account management', async () => {
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
            <PlayersScreen model={emptyModel} actions={callbacks} />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );
    expect(screen.getByText('No linked accounts')).toBeTruthy();
    expect(StyleSheet.flatten(screen.getByTestId('player-roster-control').props.style).height).toBe(
      32,
    );
    await fireEvent.press(screen.getByRole('button', { name: 'Manage Accounts' }));
    expect(callbacks.openManageAccounts).toHaveBeenCalledTimes(1);
    await fireEvent.press(screen.getByRole('tab', { name: 'Bookmarked' }));
    expect(screen.getByText('No bookmarked players yet')).toBeTruthy();
  });
});
