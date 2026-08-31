import { fireEvent, render, waitFor } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { CKThemeProvider } from '../../../ui';
import type { RankingsProvider } from '../data';
import {
  RankingAudience,
  RankingBoard,
  RankingEntry,
  RankingLeagueOption,
  RankingLocation,
  RankingPeriod,
  RankingResult,
  RankingSource,
} from '../models';
import { RankingsScreen } from './rankings-screen';

function provider(overrides: Partial<RankingsProvider> = {}): RankingsProvider {
  const location = RankingLocation.worldwide();
  return {
    audience: RankingAudience.players,
    board: RankingBoard.playerHome,
    boards: [
      RankingBoard.playerHome,
      RankingBoard.playerBuilder,
      RankingBoard.playerTownHall,
      RankingBoard.playerRanked,
    ],
    period: RankingPeriod.current,
    location,
    locations: [location],
    selectedLeague: RankingLeagueOption.legendTwo,
    leagueOptions: [RankingLeagueOption.legendTwo, RankingLeagueOption.legendThree],
    historyDate: new Date(2026, 7, 29),
    townHallLevel: 18,
    result: new RankingResult(
      [
        new RankingEntry(
          RankingAudience.players,
          1,
          2,
          '#PLAYER',
          'Player One',
          'Clan One',
          6_500,
          RankingBoard.playerHome.iconUrl,
          RankingBoard.playerHome.iconUrl,
          18,
        ),
      ],
      RankingSource.official,
      200,
    ),
    error: null,
    locationError: null,
    isLoading: false,
    isLoadingLocations: false,
    selectAudience: jest.fn(async () => undefined),
    selectBoard: jest.fn(async () => undefined),
    selectLocation: jest.fn(async () => undefined),
    selectPeriod: jest.fn(async () => undefined),
    selectHistoryDate: jest.fn(async () => undefined),
    selectTownHall: jest.fn(async () => undefined),
    selectLeague: jest.fn(async () => undefined),
    reload: jest.fn(async () => undefined),
    ...overrides,
  } as unknown as RankingsProvider;
}

async function renderScreen(value: RankingsProvider, locale: 'en' | 'en_GB' = 'en') {
  return render(
    <SafeAreaProvider
      initialMetrics={{
        frame: { x: 0, y: 0, width: 390, height: 844 },
        insets: { top: 47, right: 0, bottom: 34, left: 0 },
      }}
    >
      <I18nProvider locale={locale}>
        <CKThemeProvider preference="light">
          <RankingsScreen
            provider={value}
            revision={0}
            onBack={jest.fn()}
            onOpenEntry={jest.fn(async () => undefined)}
            onMessage={jest.fn()}
          />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}

describe('RankingsScreen parity', () => {
  it('uses Flutter’s single destination picker and selects from its menu', async () => {
    const value = provider();
    const screen = await renderScreen(value);

    expect(screen.getAllByText('Home Village')).toHaveLength(1);
    expect(screen.queryByText('Builder Base')).toBeNull();
    await fireEvent.press(screen.getByRole('button', { name: 'Home Village' }));
    expect(screen.getByText('Builder Base')).toBeTruthy();
    await fireEvent.press(screen.getByText('Builder Base'));
    expect(value.selectBoard).toHaveBeenCalledWith(RankingBoard.playerBuilder);
  });

  it('keeps prior rows visible under Flutter’s linear loading indicator', async () => {
    const screen = await renderScreen(provider({ isLoading: true }));

    expect(screen.getByTestId('rankings-loading-progress')).toBeTruthy();
    expect(screen.getByText('Player One')).toBeTruthy();
  });

  it('opens Current and History as an anchored destination menu', async () => {
    const value = provider();
    const screen = await renderScreen(value);

    await fireEvent.press(screen.getByRole('button', { name: 'Current' }));
    expect(screen.getByRole('menuitem', { name: 'Current' })).toBeTruthy();
    await fireEvent.press(screen.getByRole('menuitem', { name: 'History' }));
    expect(value.selectPeriod).toHaveBeenCalledWith(RankingPeriod.history);
  });

  it('keeps current-only filter boards free of the history control', async () => {
    const screen = await renderScreen(
      provider({
        board: RankingBoard.playerTownHall,
        boards: [
          RankingBoard.playerHome,
          RankingBoard.playerBuilder,
          RankingBoard.playerTownHall,
          RankingBoard.playerRanked,
        ],
      }),
    );

    expect(screen.getByRole('button', { name: 'Filter: TH18' })).toBeTruthy();
    expect(screen.queryByRole('button', { name: 'Current' })).toBeNull();
  });

  it('shows only valid country locations without country-search UI', async () => {
    const worldwide = RankingLocation.worldwide();
    const value = provider({
      location: worldwide,
      locations: [
        worldwide,
        new RankingLocation(32000000, 'Europe', false),
        new RankingLocation(32000007, 'United States', true, 'US'),
      ],
    });
    const screen = await renderScreen(value);

    await fireEvent.press(screen.getByRole('button', { name: 'Location: Worldwide' }));
    expect(screen.queryByText('Europe')).toBeNull();
    expect(screen.queryByPlaceholderText('Search locations or country codes')).toBeNull();
    expect(screen.getAllByText('Worldwide')).toHaveLength(2);
    expect(screen.getByText('United States')).toBeTruthy();
  });

  it('reports the localized entry error after dismissing the loading dialog', async () => {
    const message = jest.fn();
    const screen = await render(
      <SafeAreaProvider
        initialMetrics={{
          frame: { x: 0, y: 0, width: 390, height: 844 },
          insets: { top: 47, right: 0, bottom: 34, left: 0 },
        }}
      >
        <I18nProvider locale="en">
          <CKThemeProvider preference="light">
            <RankingsScreen
              provider={provider()}
              revision={0}
              onBack={jest.fn()}
              onOpenEntry={jest.fn(async () => Promise.reject(new Error('failed')))}
              onMessage={message}
            />
          </CKThemeProvider>
        </I18nProvider>
      </SafeAreaProvider>,
    );

    await fireEvent.press(screen.getByRole('button', { name: '1. Player One, 6,500' }));
    await waitFor(() => expect(message).toHaveBeenCalledWith('Failed to load this player.'));
  });

  it('formats rows and accessibility labels with ARB region locales', async () => {
    const screen = await renderScreen(provider(), 'en_GB');

    expect(screen.getByText('6,500')).toBeTruthy();
    expect(screen.getByRole('button', { name: '1. Player One, 6,500' })).toBeTruthy();
  });
});
