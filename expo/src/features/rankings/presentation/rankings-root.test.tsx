import { fireEvent, render, screen, waitFor } from '@testing-library/react-native';
import type { ReactNode } from 'react';

import { RankingsProvider } from '../data';
import {
  RankingBoard,
  RankingEntry,
  RankingLeagueOption,
  RankingLocation,
  type RankingQuery,
  RankingResult,
} from '../models';
import { RankingsRoot, rankingBoardAccentColor } from './rankings-root';
import { LinkParametersContext } from '../../../core/deep-links/link-parameters';
import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import { SafeAreaProvider } from 'react-native-safe-area-context';

const mockRuntime: {
  createRankingsProvider: () => RankingsProvider;
  players: { getPlayerAndClanData: jest.Mock };
  clans: { getClanAndWarData: jest.Mock };
  preferences: { getString: jest.Mock; setString: jest.Mock };
} = {
  createRankingsProvider: () => {
    throw new Error('Test runtime was not initialized.');
  },
  players: { getPlayerAndClanData: jest.fn() },
  clans: { getClanAndWarData: jest.fn() },
  preferences: { getString: jest.fn(async () => null), setString: jest.fn(async () => undefined) },
};

test('gives each ranking destination a restrained board accent', () => {
  const colors = Object.values(RankingBoard).map(rankingBoardAccentColor);
  expect(new Set(colors).size).toBe(colors.length);
  expect(colors.every((color) => /^#[0-9A-Fa-f]{6}$/.test(color))).toBe(true);
});

jest.mock('../../../core/app/runtime-context', () => ({
  useAppRuntime: () => mockRuntime,
}));

jest.mock('../../../ui/destination-stack', () => {
  const Native = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    DestinationStack: function MockDestinationStack({
      focused,
      onCloseDetail,
      grid,
      detail,
    }: {
      focused: boolean;
      onCloseDetail: () => void;
      grid: ReactNode;
      detail: ReactNode;
    }) {
      return (
        <Native.View>
          {focused ? detail : grid}
          {focused ? (
            <Native.Pressable
              accessibilityRole="button"
              accessibilityLabel="Native swipe back"
              onPress={onCloseDetail}
            >
              <Native.Text>Native swipe back</Native.Text>
            </Native.Pressable>
          ) : null}
        </Native.View>
      );
    },
  };
});

jest.mock('./rankings-screen', () => {
  const React = jest.requireActual<typeof import('react')>('react');
  const Native = jest.requireActual<typeof import('react-native')>('react-native');
  const actual = jest.requireActual<typeof import('./rankings-screen')>('./rankings-screen');
  return {
    boardLabel: actual.boardLabel,
    rankingBackground: actual.rankingBackground,
    RankingsScreen: React.memo(function MockRankingsScreen({
      provider,
      onBack,
      onToggleStar,
      locationPreferences,
    }: {
      provider: RankingsProvider;
      revision: number;
      onBack: () => void;
      onToggleStar: (location: RankingLocation) => void;
      locationPreferences: { starred: readonly string[] };
    }) {
      return (
        <Native.View>
          <Native.Text>{provider.result?.entries[0]?.tag ?? 'empty'}</Native.Text>
          <Native.Text testID="starred-locations">
            {locationPreferences.starred.join(',')}
          </Native.Text>
          <Native.Pressable
            accessibilityRole="button"
            accessibilityLabel="Back to rankings"
            onPress={onBack}
          >
            <Native.Text>Back to rankings</Native.Text>
          </Native.Pressable>
          <Native.Pressable
            accessibilityRole="button"
            accessibilityLabel="Toggle favorite twice"
            onPress={() => {
              const location = provider.locations.find((item) => item.id === 2);
              if (location) {
                onToggleStar(location);
                onToggleStar(location);
              }
            }}
          >
            <Native.Text>Toggle favorite twice</Native.Text>
          </Native.Pressable>
          <Native.Pressable
            accessibilityRole="button"
            accessibilityLabel="Toggle favorite"
            onPress={() => {
              const location = provider.locations.find((item) => item.id === 2);
              if (location) onToggleStar(location);
            }}
          >
            <Native.Text>Toggle favorite</Native.Text>
          </Native.Pressable>
        </Native.View>
      );
    }),
  };
});

test('publishes provider revisions to a memoized rankings screen without user interaction', async () => {
  let resolveRankings!: (result: RankingResult) => void;
  const provider = new RankingsProvider(
    {
      fetchLocations: async () => [RankingLocation.worldwide()],
      fetchRankings: () =>
        new Promise((resolve) => {
          resolveRankings = resolve;
        }),
    },
    { leagueOptions: [RankingLeagueOption.legendTwo] },
  );
  mockRuntime.createRankingsProvider = () => provider;

  await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <LinkParametersContext.Provider value={{ type: 'players', board: 'playerHome' }}>
            <RankingsRoot onBack={jest.fn()} openPlayer={jest.fn()} openClan={jest.fn()} />
          </LinkParametersContext.Provider>
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
  expect(screen.getByText('empty')).toBeTruthy();

  resolveRankings(
    new RankingResult(
      [
        new RankingEntry(
          'players',
          1,
          2,
          '#LOADED',
          'Loaded',
          '',
          6000,
          RankingBoard.playerHome.iconUrl,
          RankingBoard.playerHome.iconUrl,
          18,
        ),
      ],
      'official',
      200,
    ),
  );

  expect(await screen.findByText('#LOADED')).toBeTruthy();
});

test('opens a focused board from the Players and Clans grid and returns to the grid', async () => {
  const fetchRankings = jest.fn(
    async (_query: RankingQuery) => new RankingResult([], 'official', 200),
  );
  const provider = new RankingsProvider({
    fetchLocations: async () => [RankingLocation.worldwide()],
    fetchRankings,
  });
  mockRuntime.createRankingsProvider = () => provider;
  await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <RankingsRoot onBack={jest.fn()} openPlayer={jest.fn()} openClan={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
  expect(screen.getByText('Players')).toBeTruthy();
  expect(screen.getByText('Clans')).toBeTruthy();
  const firstTile = screen.getByTestId('destination-grid-players').children[0];
  if (!firstTile || typeof firstTile === 'string') throw new Error('Missing first tile');
  expect(firstTile.props.style.width).not.toBe('100%');
  expect(fetchRankings).not.toHaveBeenCalled();
  await fireEvent.press(screen.getByTestId('destination-clanCapital'));
  expect(provider.board).toBe(RankingBoard.clanCapital);
  expect(fetchRankings).toHaveBeenCalledTimes(1);
  expect(screen.queryByTestId('destination-playerHome')).toBeNull();
  await fireEvent.press(screen.getByRole('button', { name: 'Back to rankings' }));
  expect(screen.getByTestId('destination-playerHome')).toBeTruthy();
});

test('equivalent deep-link objects do not restart the rankings provider', async () => {
  const create = jest.fn(
    () =>
      new RankingsProvider({
        fetchLocations: async () => [RankingLocation.worldwide()],
        fetchRankings: async () => new RankingResult([], 'official', 200),
      }),
  );
  mockRuntime.createRankingsProvider = create;
  const view = (params: { type: string; board: string }) => (
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <LinkParametersContext.Provider value={params}>
            <RankingsRoot onBack={jest.fn()} openPlayer={jest.fn()} openClan={jest.fn()} />
          </LinkParametersContext.Provider>
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>
  );
  const rendered = await render(view({ type: 'players', board: 'playerHome' }));
  await rendered.rerender(view({ type: 'players', board: 'playerHome' }));
  expect(create).toHaveBeenCalledTimes(1);
});

test('a directly linked board returns to the Rankings grid', async () => {
  mockRuntime.createRankingsProvider = () =>
    new RankingsProvider({
      fetchLocations: async () => [RankingLocation.worldwide()],
      fetchRankings: async () => new RankingResult([], 'official', 200),
    });
  const outerBack = jest.fn();
  await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <LinkParametersContext.Provider value={{ type: 'clans', board: 'clanCapital' }}>
            <RankingsRoot onBack={outerBack} openPlayer={jest.fn()} openClan={jest.fn()} />
          </LinkParametersContext.Provider>
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
  await fireEvent.press(screen.getByRole('button', { name: 'Back to rankings' }));
  expect(outerBack).not.toHaveBeenCalled();
  expect(screen.getByTestId('destination-playerHome')).toBeTruthy();
});

test('a native detail pop from a deep link returns to the grid, not Home', async () => {
  mockRuntime.createRankingsProvider = () =>
    new RankingsProvider({
      fetchLocations: async () => [RankingLocation.worldwide()],
      fetchRankings: async () => new RankingResult([], 'official', 200),
    });
  const outerBack = jest.fn();
  await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <LinkParametersContext.Provider value={{ type: 'clans', board: 'clanCapital' }}>
            <RankingsRoot onBack={outerBack} openPlayer={jest.fn()} openClan={jest.fn()} />
          </LinkParametersContext.Provider>
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
  await fireEvent.press(screen.getByRole('button', { name: 'Native swipe back' }));
  expect(outerBack).not.toHaveBeenCalled();
  expect(screen.getByTestId('destination-playerHome')).toBeTruthy();
});

test('grid-to-board back preserves the provider and location favorites', async () => {
  const favorite = new RankingLocation(2, 'Favorite', true, 'US');
  const create = jest.fn(
    () =>
      new RankingsProvider({
        fetchLocations: async () => [RankingLocation.worldwide(), favorite],
        fetchRankings: async () => new RankingResult([], 'official', 200),
      }),
  );
  mockRuntime.createRankingsProvider = create;
  mockRuntime.preferences.getString.mockResolvedValue(null);
  await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <RankingsRoot onBack={jest.fn()} openPlayer={jest.fn()} openClan={jest.fn()} />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
  await fireEvent.press(screen.getByTestId('destination-playerHome'));
  await fireEvent.press(screen.getByRole('button', { name: 'Toggle favorite' }));
  expect(screen.getByTestId('starred-locations').props.children).toBe('2');
  await fireEvent.press(screen.getByRole('button', { name: 'Back to rankings' }));
  await fireEvent.press(screen.getByTestId('destination-clanCapital'));
  expect(screen.getByTestId('starred-locations').props.children).toBe('2');
  expect(create).toHaveBeenCalledTimes(1);
});

test('opens a deep-linked board at the first valid starred location by default', async () => {
  const favorite = new RankingLocation(2, 'Favorite', true, 'US');
  const fetchRankings = jest.fn(
    async (_query: RankingQuery) => new RankingResult([], 'official', 200),
  );
  mockRuntime.preferences.getString.mockResolvedValue(
    JSON.stringify({ starred: ['missing', '2'], recent: [] }),
  );
  mockRuntime.createRankingsProvider = () =>
    new RankingsProvider({
      fetchLocations: async () => [RankingLocation.worldwide(), favorite],
      fetchRankings,
    });
  await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <LinkParametersContext.Provider value={{ type: 'players', board: 'playerHome' }}>
            <RankingsRoot onBack={jest.fn()} openPlayer={jest.fn()} openClan={jest.fn()} />
          </LinkParametersContext.Provider>
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
  await waitFor(() => expect(fetchRankings).toHaveBeenCalledTimes(1));
  expect(fetchRankings.mock.calls[0]?.[0].location).toBe(favorite);
  mockRuntime.preferences.getString.mockResolvedValue(null);
});

test('rapid star toggles use current state and serialize persisted writes', async () => {
  const favorite = new RankingLocation(2, 'Favorite', true, 'US');
  mockRuntime.preferences.getString.mockResolvedValue(null);
  let finishFirstWrite!: () => void;
  const writes: string[] = [];
  mockRuntime.preferences.setString.mockImplementation(async (_key: string, value: string) => {
    writes.push(value);
    if (writes.length === 1)
      await new Promise<void>((resolve) => {
        finishFirstWrite = resolve;
      });
  });
  mockRuntime.createRankingsProvider = () =>
    new RankingsProvider({
      fetchLocations: async () => [RankingLocation.worldwide(), favorite],
      fetchRankings: async () => new RankingResult([], 'official', 200),
    });
  await render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale="en">
        <CKThemeProvider preference="light">
          <LinkParametersContext.Provider value={{ type: 'players', board: 'playerHome' }}>
            <RankingsRoot onBack={jest.fn()} openPlayer={jest.fn()} openClan={jest.fn()} />
          </LinkParametersContext.Provider>
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
  await waitFor(() =>
    expect(screen.getByRole('button', { name: 'Toggle favorite twice' })).toBeTruthy(),
  );
  await fireEvent.press(screen.getByRole('button', { name: 'Toggle favorite twice' }));
  await waitFor(() => expect(writes).toHaveLength(1));
  expect(JSON.parse(writes[0]!).starred).toEqual(['2']);
  finishFirstWrite();
  await waitFor(() => expect(writes).toHaveLength(2));
  expect(JSON.parse(writes[1]!).starred).toEqual([]);
  mockRuntime.preferences.setString.mockResolvedValue(undefined);
});
