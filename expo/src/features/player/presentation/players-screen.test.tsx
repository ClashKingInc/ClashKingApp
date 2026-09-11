import { fireEvent, render, waitFor } from '@testing-library/react-native';
import { StyleSheet } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { Player } from '../models/player';
import { PlayerClanOverview } from '../models/player-support';
import { buildPlayerRosters } from './contracts';
import type { PlayersPresentationActions, PlayersPresentationModel } from './contracts';
import { PlayersScreen } from './players-screen';

jest.mock('../../../core/assets/local-asset-cache', () => ({
  localImageCache: { subscribe: () => () => {}, peek: () => undefined, resolve: jest.fn(), getRevision: () => 0 },
}));

const mockRosterDrag = jest.fn();

jest.mock('react-native-draggable-flatlist', () => {
  const ReactModule = jest.requireActual<typeof import('react')>('react');
  const { View: MockView } = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    __esModule: true,
    ScaleDecorator: ({ children }: { children: React.ReactNode }) => children,
    default: ({
      data,
      renderItem,
      ListHeaderComponent,
      ListEmptyComponent,
      onDragEnd,
    }: {
      data: readonly unknown[];
      renderItem: (parameters: Record<string, unknown>) => React.ReactNode;
      ListHeaderComponent?: React.ReactNode;
      ListEmptyComponent?: React.ReactNode;
      onDragEnd: (parameters: Record<string, unknown>) => void;
    }) =>
      ReactModule.createElement(
        MockView,
        { testID: 'player-roster-list', ...({ onDragEnd } as Record<string, unknown>) },
        ListHeaderComponent,
        data.length === 0 ? ListEmptyComponent : null,
        data.map((item, index) =>
          ReactModule.createElement(
            ReactModule.Fragment,
            { key: index },
            renderItem({
              item,
              index,
              drag: mockRosterDrag,
              isActive: false,
              getIndex: () => index,
            }),
          ),
        ),
      ),
  };
});

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
  reorderLinkedPlayers: jest.fn(async () => undefined),
  reorderBookmarkedPlayers: jest.fn(async () => undefined),
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

  it('reorders linked and bookmarked cards by holding the card body', async () => {
    const callbacks = actions();
    const players = [player('#ONE', 'One'), player('#TWO', 'Two')];
    const model: PlayersPresentationModel = {
      ...emptyModel,
      profiles: players,
      accountLinks: players.map((item) => ({
        playerTag: item.tag,
        isVerified: true,
        hidden: false,
        raw: {},
      })),
      bookmarks: [
        {
          tag: '#BOOKMARK-ONE',
          name: 'Bookmark One',
          townHallLevel: 17,
          townHallPic: 'town-hall.png',
          clanName: '',
          trophies: 0,
          league: '',
          leagueUrl: '',
        },
        {
          tag: '#BOOKMARK-TWO',
          name: 'Bookmark Two',
          townHallLevel: 17,
          townHallPic: 'town-hall.png',
          clanName: '',
          trophies: 0,
          league: '',
          leagueUrl: '',
        },
      ],
    };
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <PlayersScreen model={model} actions={callbacks} />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    await fireEvent(screen.getByTestId('player-roster-card-#ONE'), 'longPress');
    expect(mockRosterDrag).toHaveBeenCalledTimes(1);
    const linked = [...buildPlayerRosters(model).linked].reverse();
    await fireEvent(screen.getByTestId('player-roster-list'), 'dragEnd', {
      data: linked,
      from: 0,
      to: 1,
    });
    expect(callbacks.reorderLinkedPlayers).toHaveBeenCalledWith(['#TWO', '#ONE']);

    await fireEvent.press(screen.getByRole('tab', { name: 'Bookmarked' }));
    await waitFor(() =>
      expect(screen.getByTestId('player-roster-card-#BOOKMARK-ONE')).toBeTruthy(),
    );
    await fireEvent(screen.getByTestId('player-roster-card-#BOOKMARK-ONE'), 'longPress');
    expect(mockRosterDrag).toHaveBeenCalledTimes(2);
    const bookmarked = [...buildPlayerRosters(model).bookmarked].reverse();
    await fireEvent(screen.getByTestId('player-roster-list'), 'dragEnd', {
      data: bookmarked,
      from: 0,
      to: 1,
    });
    expect(callbacks.reorderBookmarkedPlayers).toHaveBeenCalledWith([
      '#BOOKMARK-TWO',
      '#BOOKMARK-ONE',
    ]);
  });
});

function player(tag: string, name: string): Player {
  return {
    tag,
    name,
    townHallLevel: 17,
    townHallPic: 'town-hall.png',
    trophies: 5500,
    league: 'Legend League',
    leagueUrl: 'league.png',
    lastOnline: new Date(0),
    clan: null,
    clanOverview: new PlayerClanOverview('', '', 0, { small: '', medium: '', large: '' }),
  } as Player;
}
