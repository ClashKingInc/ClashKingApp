import { act, fireEvent, render, waitFor, within } from '@testing-library/react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { I18nProvider } from '../../../i18n';
import { bumpGameDataRevision, gameDataState } from '../../../core/game-data/game-data-state';
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
import { emptyLocationPreferences } from './location-preferences';

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
    today: new Date(2026, 8, 23),
    earliestHistoryDate: new Date(2023, 8, 23),
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
    selectDate: jest.fn(async () => undefined),
    selectTownHall: jest.fn(async () => undefined),
    selectLeague: jest.fn(async () => undefined),
    reload: jest.fn(async () => undefined),
    ...overrides,
  } as unknown as RankingsProvider;
}

async function renderScreen(
  value: RankingsProvider,
  locale: 'en' | 'en_GB' = 'en',
  preferences = emptyLocationPreferences,
  onToggleStar = jest.fn(),
  onSelectLocation = jest.fn(),
) {
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
            locationPreferences={preferences}
            onSelectLocation={onSelectLocation}
            onToggleStar={onToggleStar}
          />
        </CKThemeProvider>
      </I18nProvider>
    </SafeAreaProvider>,
  );
}

describe('RankingsScreen parity', () => {
  it('has no refresh button and reloads through pull-to-refresh', async () => {
    const value = provider();
    const screen = await renderScreen(value);

    expect(screen.queryByRole('button', { name: 'Refresh' })).toBeNull();
    await act(async () =>
      screen.getByTestId('rankings-list').props.refreshControl.props.onRefresh(),
    );
    expect(value.reload).toHaveBeenCalledTimes(1);
  });

  it('keeps pull-to-refresh available when the board has an error', async () => {
    const value = provider({ result: null, error: new Error('failed') });
    const screen = await renderScreen(value);

    expect(screen.getByTestId('rankings-list').props.refreshControl).toBeTruthy();
    await act(async () =>
      screen.getByTestId('rankings-list').props.refreshControl.props.onRefresh(),
    );
    expect(value.reload).toHaveBeenCalledTimes(1);
  });

  it('keeps pull-to-refresh available for an empty board', async () => {
    const value = provider({ result: new RankingResult([], RankingSource.official, 200) });
    const screen = await renderScreen(value);

    await act(async () =>
      screen.getByTestId('rankings-list').props.refreshControl.props.onRefresh(),
    );
    expect(value.reload).toHaveBeenCalledTimes(1);
  });

  it('uses the shared profile header with location inside and no board selector', async () => {
    const value = provider();
    const screen = await renderScreen(value);

    expect(screen.getAllByText('Home Village')).toHaveLength(1);
    const header = screen.getByTestId('rankings-profile-header');
    expect(within(header).getByTestId('profile-page-header-backdrop')).toBeTruthy();
    expect(within(header).getByRole('button', { name: 'Location: Worldwide' })).toBeTruthy();
    expect(screen.queryByText('Builder Base')).toBeNull();
    expect(screen.queryByRole('button', { name: 'Home Village' })).toBeNull();
  });

  it('keeps prior rows visible under Flutter’s linear loading indicator', async () => {
    const screen = await renderScreen(provider({ isLoading: true }));

    expect(screen.getByTestId('rankings-loading-progress')).toBeTruthy();
    expect(screen.getByText('Player One')).toBeTruthy();
  });

  it('refreshes a historical Builder Base badge when static league data arrives', async () => {
    const previous = gameDataState.bundleData.builder_leagues;
    try {
      delete gameDataState.bundleData.builder_leagues;
      const entry = RankingEntry.fromJson(
        {
          tag: '#PLAYER',
          name: 'Builder Player',
          rank: 1,
          builderBaseTrophies: 6462,
          builderBaseLeague: { id: 44000017 },
        },
        RankingBoard.playerBuilder,
      );
      const screen = await renderScreen(
        provider({
          board: RankingBoard.playerBuilder,
          result: new RankingResult([entry], RankingSource.clashKing, 200),
        }),
      );
      expect(JSON.stringify(screen.getByTestId('ranking-entry-image').props.source)).toContain(
        'Icon_BB_Star',
      );
      await act(async () => {
        gameDataState.bundleData.builder_leagues = [{ _id: 44000017, name: 'Copper League III' }];
        bumpGameDataRevision();
      });
      expect(JSON.stringify(screen.getByTestId('ranking-entry-image').props.source)).toContain(
        'copper_league_3',
      );
    } finally {
      if (previous === undefined) delete gameDataState.bundleData.builder_leagues;
      else gameDataState.bundleData.builder_leagues = previous;
    }
  });

  it('uses Legends day arrows and opens the calendar from Current', async () => {
    const value = provider();
    const screen = await renderScreen(value);

    expect(screen.queryByRole('radio', { name: 'History' })).toBeNull();
    await fireEvent.press(screen.getByRole('button', { name: 'Previous page' }));
    expect(value.selectDate).toHaveBeenCalledWith(new Date(2026, 8, 22));
    expect(
      screen.getByRole('button', { name: 'Next page' }).props.accessibilityState.disabled,
    ).toBe(true);
    await fireEvent.press(screen.getByRole('button', { name: 'Current' }));
    expect(screen.getByText('Snapshot date')).toBeTruthy();
    expect(screen.queryByText('History')).toBeNull();
  });

  it('steps a prior day forward to Current and opens its date calendar', async () => {
    const value = provider({ period: RankingPeriod.history, historyDate: new Date(2026, 8, 22) });
    const screen = await renderScreen(value);

    await fireEvent.press(screen.getByRole('button', { name: 'Next page' }));
    expect(value.selectDate).toHaveBeenCalledWith(new Date(2026, 8, 23));
    await fireEvent.press(screen.getByRole('button', { name: 'September 22, 2026' }));
    expect(screen.getByText('Snapshot date')).toBeTruthy();
  });

  it('selects today from the calendar through the same date transition', async () => {
    const current = provider();
    const currentScreen = await renderScreen(current);
    await fireEvent.press(currentScreen.getByRole('button', { name: 'Current' }));
    await fireEvent.press(currentScreen.getByText('23'));
    expect(current.selectDate).toHaveBeenCalledWith(new Date(2026, 8, 23));
  });

  it('selects a prior day from the historical calendar', async () => {
    const history = provider({ period: RankingPeriod.history, historyDate: new Date(2026, 8, 22) });
    const historyScreen = await renderScreen(history);
    await fireEvent.press(historyScreen.getByRole('button', { name: 'September 22, 2026' }));
    await fireEvent.press(historyScreen.getByText('21'));
    expect(history.selectDate).toHaveBeenCalledWith(new Date(2026, 8, 21));
  });

  it('keeps current-only filter boards free of the history control', async () => {
    const value = provider({
      board: RankingBoard.playerTownHall,
      boards: [
        RankingBoard.playerHome,
        RankingBoard.playerBuilder,
        RankingBoard.playerTownHall,
        RankingBoard.playerRanked,
      ],
    });
    const screen = await renderScreen(value);

    expect(screen.getByRole('button', { name: 'Town Hall: TH18' })).toBeTruthy();
    expect(screen.queryByRole('button', { name: 'Current' })).toBeNull();
    expect(screen.queryByRole('button', { name: 'Previous page' })).toBeNull();
    await fireEvent.press(screen.getByRole('button', { name: 'Town Hall: TH18' }));
    await fireEvent.press(screen.getByRole('radio', { name: 'TH17' }));
    expect(value.selectTownHall).toHaveBeenCalledWith(17);
  });

  it('uses the same selection picker for Ranked leagues', async () => {
    const value = provider({ board: RankingBoard.playerRanked });
    const screen = await renderScreen(value);

    expect(screen.queryByText('Filter')).toBeNull();
    await fireEvent.press(screen.getByRole('button', { name: 'Ranked League: Legend League 2' }));
    await fireEvent.press(screen.getByRole('radio', { name: 'Legend League 3' }));
    expect(value.selectLeague).toHaveBeenCalledWith(RankingLeagueOption.legendThree);
  });

  it('steps Capital through Monday snapshots instead of individual days', async () => {
    const value = provider({ board: RankingBoard.clanCapital });
    const screen = await renderScreen(value);
    await fireEvent.press(screen.getByRole('button', { name: 'Previous page' }));
    expect(value.selectDate).toHaveBeenCalledWith(new Date(2026, 8, 21));
    await fireEvent.press(screen.getByRole('button', { name: 'Current' }));
    expect(screen.getByRole('button', { name: '22' }).props.accessibilityState).toMatchObject({
      disabled: true,
    });
    await fireEvent.press(screen.getByRole('button', { name: '14' }));
    expect(value.selectDate).toHaveBeenCalledWith(new Date(2026, 8, 14));
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

  it('orders favorites and recents in the shared picker and stars without selecting', async () => {
    const worldwide = RankingLocation.worldwide();
    const first = new RankingLocation(1, 'First', true, 'US');
    const second = new RankingLocation(2, 'Second', true, 'GB');
    const onStar = jest.fn();
    const onSelect = jest.fn();
    const screen = await renderScreen(
      provider({ location: worldwide, locations: [worldwide, first, second] }),
      'en',
      { starred: ['2'], recent: ['1'] },
      onStar,
      onSelect,
    );

    await fireEvent.press(screen.getByRole('button', { name: 'Location: Worldwide' }));
    const radios = screen.getAllByRole('radio');
    expect(radios.map((radio) => radio.props.accessibilityLabel)).toEqual([
      'Second',
      'First',
      'Worldwide',
    ]);
    await fireEvent.press(screen.getByRole('button', { name: 'Remove bookmark Second' }));
    expect(onStar).toHaveBeenCalledWith(second);
    expect(onSelect).not.toHaveBeenCalled();
    await fireEvent.press(screen.getByRole('radio', { name: 'First' }));
    expect(onSelect).toHaveBeenCalledWith(first);
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
              locationPreferences={emptyLocationPreferences}
              onSelectLocation={jest.fn()}
              onToggleStar={jest.fn()}
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
