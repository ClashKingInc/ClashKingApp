import { act, fireEvent, render, waitFor } from '@testing-library/react-native';

import { SearchRoot } from './search-root';
import { SearchService } from './search-service';

const mockRuntime = {
  api: {},
  auth: {
    state: { currentUser: null },
    subscribe: jest.fn(() => jest.fn()),
  },
  players: {
    searchPlayers: jest.fn(async () => []),
    getPlayerAndClanData: jest.fn(),
  },
  clans: {
    getClanAndWarData: jest.fn(),
    loadJoinLeaveForClan: jest.fn(),
  },
};

jest.mock('../../core/app/runtime-context', () => ({
  useAppRuntime: () => mockRuntime,
}));

jest.mock('../../i18n', () => ({
  useI18n: () => ({ t: (key: string) => key }),
}));

jest.mock('../../ui', () => ({
  SkeletonLoadingDialog: () => null,
  Snackbar: () => null,
}));

jest.mock('./search-screen', () => {
  const { Pressable, Text, View } = jest.requireActual('react-native');
  return {
    SearchScreen: (props: {
      mode: 'players' | 'clans';
      filtersExpanded: boolean;
      onQueryChange: (value: string) => void;
      onPlayerFiltersChange: (value: {
        leagueIds: readonly number[];
        minTownHallLevel: number | null;
        maxTownHallLevel: number | null;
      }) => void;
      onFiltersExpandedChange: (value: boolean) => void;
      onModeChange: (value: 'players' | 'clans') => void;
    }) => (
      <View>
        <Text>{`mode:${props.mode}`}</Text>
        <Pressable onPress={() => props.onFiltersExpandedChange(!props.filtersExpanded)}>
          <Text>filters</Text>
        </Pressable>
        <Pressable onPress={() => props.onModeChange('clans')}>
          <Text>clans</Text>
        </Pressable>
        <Pressable onPress={() => props.onQueryChange('Hero')}>
          <Text>query</Text>
        </Pressable>
        <Pressable
          onPress={() =>
            props.onPlayerFiltersChange({
              leagueIds: [105000036],
              minTownHallLevel: 16,
              maxTownHallLevel: 16,
            })
          }
        >
          <Text>player-filter</Text>
        </Pressable>
      </View>
    ),
  };
});

test('loads only the visible filter metadata after filters are expanded', async () => {
  jest.useFakeTimers();
  const pending = new Promise<never>(() => undefined);
  jest.spyOn(SearchService.prototype, 'loadRecents').mockReturnValue(pending);
  const loadLeagues = jest.spyOn(SearchService.prototype, 'loadLeagues').mockReturnValue(pending);
  const loadLocations = jest
    .spyOn(SearchService.prototype, 'loadLocations')
    .mockReturnValue(pending);

  const view = await render(<SearchRoot onOpenPlayer={jest.fn()} onOpenClan={jest.fn()} />);
  await waitFor(() => expect(SearchService.prototype.loadRecents).toHaveBeenCalled());
  expect(loadLeagues).not.toHaveBeenCalled();
  expect(loadLocations).not.toHaveBeenCalled();

  await fireEvent.press(view.getByText('filters'));
  await waitFor(() => expect(loadLeagues).toHaveBeenCalledTimes(1));
  expect(loadLocations).not.toHaveBeenCalled();

  await fireEvent.press(view.getByText('clans'));
  await waitFor(() => expect(view.getByText('mode:clans')).toBeTruthy());
  await fireEvent.press(view.getByText('filters'));
  await waitFor(() => expect(loadLocations).toHaveBeenCalledTimes(1));
  expect(loadLeagues).toHaveBeenCalledTimes(1);
  jest.clearAllTimers();
  jest.useRealTimers();
});

test('reruns player search with the selected filters', async () => {
  jest.useFakeTimers();
  const pending = new Promise<never>(() => undefined);
  jest.spyOn(SearchService.prototype, 'loadRecents').mockReturnValue(pending);
  mockRuntime.players.searchPlayers.mockClear();
  mockRuntime.players.searchPlayers.mockResolvedValueOnce([]);

  const view = await render(<SearchRoot onOpenPlayer={jest.fn()} onOpenClan={jest.fn()} />);
  await fireEvent.press(view.getByText('query'));
  await fireEvent.press(view.getByText('player-filter'));
  await act(async () => jest.advanceTimersByTime(450));

  await waitFor(() =>
    expect(mockRuntime.players.searchPlayers).toHaveBeenCalledWith('Hero', {
      leagueIds: [105000036],
      townHallLevels: [16],
      extraHeaders: undefined,
    }),
  );
  jest.clearAllTimers();
  jest.useRealTimers();
});
