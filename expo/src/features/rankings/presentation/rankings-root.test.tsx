import { render, screen } from '@testing-library/react-native';

import { RankingsProvider } from '../data';
import {
  RankingBoard,
  RankingEntry,
  RankingLeagueOption,
  RankingLocation,
  RankingResult,
} from '../models';
import { RankingsRoot } from './rankings-root';

const mockRuntime: {
  createRankingsProvider: () => RankingsProvider;
  players: { getPlayerAndClanData: jest.Mock };
  clans: { getClanAndWarData: jest.Mock };
} = {
  createRankingsProvider: () => {
    throw new Error('Test runtime was not initialized.');
  },
  players: { getPlayerAndClanData: jest.fn() },
  clans: { getClanAndWarData: jest.fn() },
};

jest.mock('../../../core/app/runtime-context', () => ({
  useAppRuntime: () => mockRuntime,
}));

jest.mock('./rankings-screen', () => {
  const React = jest.requireActual<typeof import('react')>('react');
  const Native = jest.requireActual<typeof import('react-native')>('react-native');
  return {
    RankingsScreen: React.memo(function MockRankingsScreen({
      provider,
    }: {
      provider: RankingsProvider;
      revision: number;
    }) {
      return <Native.Text>{provider.result?.entries[0]?.tag ?? 'empty'}</Native.Text>;
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

  await render(<RankingsRoot onBack={jest.fn()} openPlayer={jest.fn()} openClan={jest.fn()} />);
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
